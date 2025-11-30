# Python Resend Client Setup

Complete Python client setup with authentication, rate limiting, and error handling.

## Installation

```bash
pip install resend python-dotenv
```

## Environment Setup

Create `.env` file in your project root:

```bash
# .env
RESEND_API_KEY=your_resend_api_key_here
```

Add `.env` to `.gitignore`:

```bash
# .gitignore
.env
.env.local
*.pyc
__pycache__/
venv/
.venv/
```

## Basic Client Initialization

```python
import os
from dotenv import load_dotenv
from resend import Resend

# Load environment variables
load_dotenv()

# Initialize client
api_key = os.getenv("RESEND_API_KEY")
if not api_key:
    raise ValueError("RESEND_API_KEY environment variable is required")

client = Resend(api_key=api_key)
```

## Complete Client with Error Handling

```python
import os
import asyncio
import logging
from typing import TypeVar, Callable, Coroutine, Optional, List, Dict, Any
from dataclasses import dataclass
from enum import Enum
from dotenv import load_dotenv
from resend import Resend

logger = logging.getLogger(__name__)

T = TypeVar('T')

class APIErrorCode(Enum):
    """HTTP status codes for API errors"""
    UNAUTHORIZED = 401
    NOT_FOUND = 404
    RATE_LIMITED = 429
    SERVER_ERROR = 500
    BAD_GATEWAY = 502
    SERVICE_UNAVAILABLE = 503

@dataclass
class APIResponse:
    """Standard API response wrapper"""
    success: bool
    data: Optional[Any] = None
    error: Optional[str] = None
    code: Optional[int] = None

class ResendClient:
    """
    Resend API client with error handling and retry logic
    """

    def __init__(self, api_key: str):
        """
        Initialize Resend client

        Args:
            api_key: Resend API key

        Raises:
            ValueError: If API key is empty
        """
        if not api_key:
            raise ValueError("API key is required")

        self.client = Resend(api_key=api_key)
        self.max_retries = 3
        self.initial_delay = 0.1  # seconds
        self.max_delay = 30  # seconds

    async def send_email(self, payload: Dict[str, Any]) -> APIResponse:
        """
        Send email with automatic retry on transient failures

        Args:
            payload: Email payload

        Returns:
            APIResponse with result or error
        """
        return await self._with_retry(
            lambda: self.client.emails.send(payload),
            "send email"
        )

    async def send_batch(self, emails: List[Dict[str, Any]]) -> APIResponse:
        """
        Send batch of emails

        Args:
            emails: List of email payloads

        Returns:
            APIResponse with result or error
        """
        return await self._with_retry(
            lambda: self.client.batch.send(emails),
            "send batch emails"
        )

    async def _with_retry(
        self,
        fn: Callable[[], Coroutine[Any, Any, T]],
        operation_name: str
    ) -> APIResponse:
        """
        Retry logic with exponential backoff

        Args:
            fn: Async function to retry
            operation_name: Name of operation for logging

        Returns:
            APIResponse with result or error
        """
        last_error = None
        delay = self.initial_delay

        for attempt in range(1, self.max_retries + 1):
            try:
                result = await fn()
                return APIResponse(success=True, data=result)

            except Exception as error:
                last_error = error
                status_code = getattr(error, 'status_code', None)
                is_retryable = self._is_retryable_error(status_code, error)

                if not is_retryable or attempt == self.max_retries:
                    return APIResponse(
                        success=False,
                        error=str(error),
                        code=status_code
                    )

                logger.warning(
                    f"[Attempt {attempt}/{self.max_retries}] {operation_name} failed: "
                    f"{str(error)}. Retrying in {delay:.1f}s..."
                )

                await asyncio.sleep(delay)
                delay = min(delay * 2, self.max_delay)  # Exponential backoff

        return APIResponse(
            success=False,
            error=f"Failed to {operation_name} after {self.max_retries} attempts",
            code=getattr(last_error, 'status_code', None)
        )

    @staticmethod
    def _is_retryable_error(
        status_code: Optional[int],
        error: Exception
    ) -> bool:
        """
        Determine if error is retryable (transient)

        Args:
            status_code: HTTP status code
            error: Exception object

        Returns:
            True if error is retryable
        """
        # Retry on rate limit, server errors, and timeouts
        retryable_codes = [408, 429, 500, 502, 503, 504]

        if status_code and status_code in retryable_codes:
            return True

        # Check for timeout or connection errors
        error_str = str(error).lower()
        return any(keyword in error_str for keyword in [
            'timeout',
            'connection',
            'econnrefused',
            'enotfound'
        ])
```

## Usage Examples

### Send Single Email

```python
import asyncio
import os
from dotenv import load_dotenv
from resend_client import ResendClient

load_dotenv()

async def main():
    client = ResendClient(os.getenv("RESEND_API_KEY"))

    response = await client.send_email({
        "from": "notifications@example.com",
        "to": "user@example.com",
        "subject": "Welcome!",
        "html": "<h1>Welcome</h1><p>Thanks for signing up!</p>",
    })

    if not response.success:
        print(f"Error: {response.error}")
        return

    print(f"Email sent! ID: {response.data.get('id')}")

if __name__ == "__main__":
    asyncio.run(main())
```

### Send Batch Emails

```python
import asyncio
import os
from dotenv import load_dotenv
from resend_client import ResendClient

load_dotenv()

async def send_newsletter_batch():
    client = ResendClient(os.getenv("RESEND_API_KEY"))

    subscribers = [
        {"email": "user1@example.com", "name": "User 1"},
        {"email": "user2@example.com", "name": "User 2"},
        {"email": "user3@example.com", "name": "User 3"},
    ]

    emails = [
        {
            "from": "newsletter@example.com",
            "to": sub["email"],
            "subject": "Monthly Newsletter",
            "html": f"<h1>Hello {sub['name']}</h1><p>Here's this month's news...</p>",
        }
        for sub in subscribers
    ]

    response = await client.send_batch(emails)

    if not response.success:
        print(f"Error: {response.error}")
        return

    print(f"Batch sent! Total emails: {len(response.data)}")

if __name__ == "__main__":
    asyncio.run(send_newsletter_batch())
```

### Send Email with Attachment

```python
import asyncio
import os
from pathlib import Path
from dotenv import load_dotenv
from resend_client import ResendClient

load_dotenv()

async def send_email_with_attachment():
    client = ResendClient(os.getenv("RESEND_API_KEY"))

    file_path = Path("documents/report.pdf")

    if not file_path.exists():
        print(f"Error: File not found: {file_path}")
        return

    with open(file_path, "rb") as f:
        file_content = f.read()

    response = await client.send_email({
        "from": "reports@example.com",
        "to": "manager@example.com",
        "subject": "Monthly Report",
        "html": "<p>Please find the attached report.</p>",
        "attachments": [
            {
                "filename": "report.pdf",
                "content": file_content,
            }
        ],
    })

    if not response.success:
        print(f"Error: {response.error}")
        return

    print(f"Email with attachment sent! ID: {response.data.get('id')}")

if __name__ == "__main__":
    asyncio.run(send_email_with_attachment())
```

### Advanced Client with Rate Limiting

```python
import asyncio
import time
from typing import Callable, Coroutine, Any, TypeVar
from resend import Resend

T = TypeVar('T')

class RateLimitedResendClient:
    """
    Resend client with rate limiting (2 requests per second)
    """

    def __init__(self, api_key: str, requests_per_second: int = 2):
        """
        Initialize rate-limited client

        Args:
            api_key: Resend API key
            requests_per_second: Rate limit (default: 2)
        """
        self.client = Resend(api_key=api_key)
        self.requests_per_second = requests_per_second
        self.queue: asyncio.Queue = asyncio.Queue()
        self.is_processing = False
        self.last_request_time = 0

    async def send_email_queued(self, payload: dict) -> Any:
        """
        Queue email send with rate limiting

        Args:
            payload: Email payload

        Returns:
            Send result
        """
        result_future = asyncio.Future()

        async def send():
            try:
                result = self.client.emails.send(payload)
                result_future.set_result(result)
            except Exception as error:
                result_future.set_exception(error)

        await self.queue.put(send)
        asyncio.create_task(self.process_queue())

        return await result_future

    async def process_queue(self):
        """
        Process queue with rate limiting
        """
        if self.is_processing or self.queue.empty():
            return

        self.is_processing = True

        while not self.queue.empty():
            now = time.time()
            time_since_last = now - self.last_request_time
            delay_needed = (1.0 / self.requests_per_second) - time_since_last

            if delay_needed > 0:
                await asyncio.sleep(delay_needed)

            try:
                send_fn = self.queue.get_nowait()
                await send_fn()
                self.last_request_time = time.time()
            except asyncio.QueueEmpty:
                break

        self.is_processing = False
```

## Error Handling Patterns

### Handle Specific Errors

```python
import asyncio
import os
from dotenv import load_dotenv
from resend_client import ResendClient

load_dotenv()

async def send_with_error_handling():
    client = ResendClient(os.getenv("RESEND_API_KEY"))

    response = await client.send_email({
        "from": "noreply@example.com",
        "to": "user@example.com",
        "subject": "Test",
        "html": "<p>Test email</p>",
    })

    if not response.success:
        if response.code == 401:
            print("Error: Invalid API key")
        elif response.code == 429:
            print("Error: Rate limit exceeded")
        elif response.code == 500:
            print("Error: Server error - will retry")
        else:
            print(f"Error: {response.error}")
        return

    print(f"Email sent: {response.data.get('id')}")

if __name__ == "__main__":
    asyncio.run(send_with_error_handling())
```

## Sync vs Async

### Synchronous Usage (Without Asyncio)

```python
import os
from dotenv import load_dotenv
from resend import Resend

load_dotenv()

api_key = os.getenv("RESEND_API_KEY")
client = Resend(api_key=api_key)

# Synchronous send
response = client.emails.send({
    "from": "notifications@example.com",
    "to": "user@example.com",
    "subject": "Welcome",
    "html": "<h1>Welcome!</h1>",
})

if response.get("error"):
    print(f"Error: {response['error']}")
else:
    print(f"Email sent! ID: {response.get('id')}")
```

### Asynchronous Usage (With Asyncio)

```python
import asyncio
import os
from dotenv import load_dotenv
from resend import Resend

load_dotenv()

async def send_async():
    api_key = os.getenv("RESEND_API_KEY")
    client = Resend(api_key=api_key)

    # Async send
    response = await client.emails.send({
        "from": "notifications@example.com",
        "to": "user@example.com",
        "subject": "Welcome",
        "html": "<h1>Welcome!</h1>",
    })

    if response.get("error"):
        print(f"Error: {response['error']}")
    else:
        print(f"Email sent! ID: {response.get('id')}")

if __name__ == "__main__":
    asyncio.run(send_async())
```

## Testing Client

### Unit Test Example (pytest)

```python
import pytest
import asyncio
from resend_client import ResendClient, APIResponse

@pytest.mark.asyncio
async def test_resend_client_init():
    """Test client initialization"""
    client = ResendClient("test_key_12345")
    assert client is not None

def test_resend_client_missing_key():
    """Test that missing API key raises error"""
    with pytest.raises(ValueError):
        ResendClient("")

@pytest.mark.asyncio
async def test_send_email_validation():
    """Test email payload validation"""
    client = ResendClient("test_key_12345")

    # This will fail validation in real API
    response = await client.send_email({
        "from": "invalid-email",
        "to": "user@example.com",
        "subject": "Test",
        "html": "<p>Test</p>",
    })

    assert not response.success
```

## Deployment Considerations

### Environment Variables for Production

```bash
# .env.production
RESEND_API_KEY=prod_your_resend_api_key_here
RESEND_REQUEST_TIMEOUT=30
RESEND_MAX_RETRIES=5
```

### Logging Configuration

```python
import logging
from logging.handlers import RotatingFileHandler

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# File handler with rotation
file_handler = RotatingFileHandler(
    'resend_api.log',
    maxBytes=10485760,  # 10MB
    backupCount=5
)

# Formatter
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

# Use in client
logger.info(f"Email sent to {payload['to']}: {response.data.get('id')}")
logger.error(f"Failed to send email: {response.error}")
```

### Production Monitoring

```python
import asyncio
import time
from datetime import datetime
from resend_client import ResendClient

class MonitoredResendClient(ResendClient):
    """Resend client with monitoring and metrics"""

    def __init__(self, api_key: str):
        super().__init__(api_key)
        self.metrics = {
            "total_requests": 0,
            "successful_sends": 0,
            "failed_sends": 0,
            "rate_limit_hits": 0,
            "total_time_ms": 0,
        }

    async def send_email(self, payload):
        """Send email with metrics tracking"""
        start_time = time.time()
        self.metrics["total_requests"] += 1

        response = await super().send_email(payload)
        duration_ms = (time.time() - start_time) * 1000

        if response.success:
            self.metrics["successful_sends"] += 1
        else:
            self.metrics["failed_sends"] += 1
            if response.code == 429:
                self.metrics["rate_limit_hits"] += 1

        self.metrics["total_time_ms"] += duration_ms

        return response

    def get_metrics(self) -> dict:
        """Get current metrics"""
        return {
            **self.metrics,
            "success_rate": (
                self.metrics["successful_sends"] /
                max(self.metrics["total_requests"], 1)
            ),
            "average_time_ms": (
                self.metrics["total_time_ms"] /
                max(self.metrics["total_requests"], 1)
            ),
        }
```

## Python Version Requirements

- Python 3.8+
- Recommended: Python 3.10+

## Dependencies

```txt
resend>=1.0.0
python-dotenv>=1.0.0
aiohttp>=3.8.0
```

## Resources

- [Resend Python SDK](https://resend.com/docs/sdks/python)
- [API Reference](https://resend.com/docs/api-reference)
- [Authentication](https://resend.com/docs/knowledge-base/authentication)
- [Python Asyncio Documentation](https://docs.python.org/3/library/asyncio.html)
