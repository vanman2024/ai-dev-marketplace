# Error Handling Patterns - Python

## Exception Hierarchy

```python
A2AError (base exception)
├── A2AConnectionError (network/connectivity issues)
├── A2AAuthenticationError (invalid credentials)
├── A2ARateLimitError (rate limit exceeded)
├── A2AValidationError (invalid request data)
└── A2AServerError (server-side errors)
```

## Basic Error Handling

```python
from a2a_protocol import A2AClient, A2AError, A2AAuthenticationError, A2ARateLimitError
import time

client = A2AClient(api_key=os.getenv("A2A_API_KEY"))

try:
    response = client.send_message(
        recipient_id="agent-123",
        message={"type": "request"}
    )
except A2AAuthenticationError as e:
    print(f"Authentication failed: {e}")
    print("Please check your API key")
except A2ARateLimitError as e:
    print(f"Rate limit exceeded: {e}")
    print(f"Retry after: {e.retry_after} seconds")
    time.sleep(e.retry_after)
    # Retry the request
except A2AError as e:
    print(f"A2A error: {e}")
    print(f"Error code: {e.code}")
    print(f"Status code: {e.status_code}")
```

## Retry with Exponential Backoff

```python
import time
from typing import Optional

def send_with_retry(
    client: A2AClient,
    recipient_id: str,
    message: dict,
    max_retries: int = 3,
    initial_delay: float = 1.0
) -> Optional[dict]:
    """Send message with exponential backoff retry"""
    delay = initial_delay

    for attempt in range(max_retries):
        try:
            return client.send_message(recipient_id, message)
        except A2ARateLimitError as e:
            if attempt == max_retries - 1:
                raise
            wait_time = e.retry_after if hasattr(e, 'retry_after') else delay
            print(f"Rate limited. Waiting {wait_time}s before retry...")
            time.sleep(wait_time)
            delay *= 2  # Exponential backoff
        except A2AConnectionError as e:
            if attempt == max_retries - 1:
                raise
            print(f"Connection error. Retrying in {delay}s...")
            time.sleep(delay)
            delay *= 2

    return None
```

## Context Manager for Resource Cleanup

```python
from contextlib import contextmanager

@contextmanager
def a2a_client(api_key: str):
    """Context manager for A2A client with automatic cleanup"""
    client = A2AClient(api_key=api_key)
    try:
        yield client
    finally:
        client.close()

# Usage
with a2a_client(os.getenv("A2A_API_KEY")) as client:
    response = client.send_message(
        recipient_id="agent-123",
        message={"type": "request"}
    )
```

## Async Error Handling

```python
import asyncio
from a2a_protocol import AsyncA2AClient, A2AError

async def send_with_timeout(client, recipient_id, message, timeout=10):
    """Send message with timeout"""
    try:
        return await asyncio.wait_for(
            client.send_message(recipient_id, message),
            timeout=timeout
        )
    except asyncio.TimeoutError:
        print(f"Request timed out after {timeout}s")
        raise
    except A2AError as e:
        print(f"A2A error: {e}")
        raise
```

## Logging Errors

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

try:
    response = client.send_message(
        recipient_id="agent-123",
        message={"type": "request"}
    )
except A2AError as e:
    logger.error(
        "Failed to send message",
        extra={
            "error_code": e.code,
            "status_code": e.status_code,
            "recipient_id": "agent-123",
            "error_message": str(e)
        }
    )
    raise
```

## Graceful Degradation

```python
def get_agent_status_safe(client, agent_id):
    """Get agent status with fallback"""
    try:
        return client.get_agent_status(agent_id)
    except A2AConnectionError:
        logger.warning(f"Could not fetch status for {agent_id}")
        return {"id": agent_id, "status": "unknown"}
    except A2AError as e:
        logger.error(f"Error fetching status: {e}")
        return {"id": agent_id, "status": "error"}
```
