# Task with Retries Example

Complete example of implementing a Celery task with automatic retry mechanisms.

## Scenario

You need to fetch data from an external API that occasionally fails due to network issues or rate limiting. The task should automatically retry with exponential backoff.

## Implementation

```python
from celery import Celery
from celery.utils.log import get_task_logger
from requests.exceptions import RequestException, Timeout
import requests

logger = get_task_logger(__name__)

app = Celery('tasks', broker='redis://localhost:6379/0')


@app.task(
    bind=True,
    autoretry_for=(RequestException, Timeout),
    retry_backoff=True,
    retry_backoff_max=600,  # 10 minutes max delay
    retry_jitter=True,
    max_retries=5
)
def fetch_api_data(self, url: str, timeout: int = 30) -> dict:
    """
    Fetch data from API with automatic retries.

    Retry Strategy:
    - Retries on RequestException and Timeout
    - Exponential backoff: 1s, 2s, 4s, 8s, 16s...
    - Jitter added to prevent thundering herd
    - Maximum 5 attempts
    - Maximum 10 minute delay between retries

    Args:
        url: API endpoint URL
        timeout: Request timeout in seconds

    Returns:
        dict: API response data
    """
    try:
        logger.info(
            f"Fetching {url} (attempt {self.request.retries + 1}/{self.max_retries})"
        )

        response = requests.get(url, timeout=timeout)
        response.raise_for_status()

        data = response.json()

        logger.info(f"Successfully fetched data from {url}")
        return {
            'status': 'success',
            'url': url,
            'data': data,
            'attempts': self.request.retries + 1
        }

    except (RequestException, Timeout) as exc:
        logger.warning(
            f"Attempt {self.request.retries + 1} failed: {exc}. "
            "Retrying with exponential backoff..."
        )
        raise  # autoretry_for will handle the retry
```

## Usage

### Basic Usage

```python
# Queue the task
result = fetch_api_data.delay('https://api.example.com/data')

# Get task ID
print(f"Task ID: {result.id}")

# Wait for result (blocking)
data = result.get(timeout=60)
print(f"Data: {data}")
```

### Check Task Status

```python
# Queue the task
result = fetch_api_data.delay('https://api.example.com/data')

# Check status without blocking
if result.ready():
    print("Task completed!")
    print(f"Result: {result.result}")
else:
    print("Task still running...")
    print(f"State: {result.state}")
```

### Handle Failures

```python
from celery.exceptions import MaxRetriesExceededError

result = fetch_api_data.delay('https://api.example.com/data')

try:
    data = result.get(timeout=120)
    print(f"Success: {data}")
except MaxRetriesExceededError:
    print("Task failed after all retries")
except Exception as exc:
    print(f"Task failed: {exc}")
```

## Monitoring Retries

### View Active Tasks

```bash
celery -A tasks inspect active
```

### View Retry Statistics

```bash
celery -A tasks inspect stats
```

### Check Task State

```python
result = fetch_api_data.delay('https://api.example.com/data')

# Check if task is retrying
if result.state == 'RETRY':
    print("Task is being retried")
    print(f"Info: {result.info}")
```

## Retry Strategy Examples

### Fast Retries (Short-Lived Failures)

```python
@app.task(
    bind=True,
    autoretry_for=(ConnectionError,),
    retry_backoff=2,  # Start with 2 seconds
    max_retries=3
)
def quick_retry_task(self, data_id: int):
    """Retry quickly for transient failures."""
    # Your logic here
    pass
```

### Slow Retries (Rate-Limited APIs)

```python
@app.task(
    bind=True,
    autoretry_for=(RequestException,),
    default_retry_delay=300,  # Fixed 5 minute delay
    max_retries=10
)
def rate_limited_task(self, endpoint: str):
    """Retry slowly for rate-limited APIs."""
    # Your logic here
    pass
```

### Manual Retry Control

```python
@app.task(bind=True, max_retries=3)
def custom_retry_task(self, item_id: int):
    """Manual retry with custom logic."""
    try:
        # Your logic here
        result = process_item(item_id)
        return result

    except TemporaryError as exc:
        # Retry after 60 seconds
        raise self.retry(exc=exc, countdown=60)

    except PermanentError:
        # Don't retry permanent errors
        logger.error("Permanent error, not retrying")
        raise
```

## Configuration Options

### In Task Decorator

```python
@app.task(
    bind=True,                          # Required for retry
    autoretry_for=(Exception,),         # Exceptions to retry
    retry_backoff=True,                 # Enable exponential backoff
    retry_backoff_max=600,              # Max backoff (seconds)
    retry_jitter=True,                  # Add randomness
    max_retries=5,                      # Max retry attempts
    default_retry_delay=10              # Default delay (seconds)
)
```

### In Celery Config (celeryconfig.py)

```python
# Global retry settings
task_annotations = {
    'tasks.fetch_api_data': {
        'autoretry_for': (RequestException,),
        'retry_backoff': True,
        'max_retries': 5,
    }
}

# Or apply to all tasks
task_autoretry_for = (Exception,)
task_retry_backoff = True
task_max_retries = 3
```

## Best Practices

### 1. Choose Appropriate Exceptions

```python
# ✅ GOOD - Specific exceptions
autoretry_for=(RequestException, Timeout, ConnectionError)

# ❌ BAD - Too broad
autoretry_for=(Exception,)
```

### 2. Set Reasonable Max Retries

```python
# API calls: 3-5 retries
max_retries=5

# Database operations: 2-3 retries
max_retries=3

# Critical operations: More retries
max_retries=10
```

### 3. Use Exponential Backoff

```python
# ✅ GOOD - Exponential with jitter
retry_backoff=True
retry_jitter=True

# ❌ BAD - Fixed delay can cause thundering herd
default_retry_delay=60
```

### 4. Log Retry Attempts

```python
@app.task(bind=True, autoretry_for=(Exception,))
def monitored_task(self, data_id: int):
    logger.info(
        f"Attempt {self.request.retries + 1}/{self.max_retries}"
    )
    # Your logic
```

### 5. Set Timeout Less Than Time Limit

```python
@app.task(
    bind=True,
    soft_time_limit=60,
    autoretry_for=(Timeout,)
)
def safe_api_call(self, url: str):
    # Timeout should be less than soft_time_limit
    response = requests.get(url, timeout=55)
    return response.json()
```

## Testing

### Test Retry Behavior

```python
# Create a failing task
@app.task(bind=True, autoretry_for=(ValueError,), max_retries=3)
def failing_task(self, should_fail: bool = True):
    logger.info(f"Attempt {self.request.retries + 1}")
    if should_fail:
        raise ValueError("Intentional failure")
    return "success"

# Run and observe retries
result = failing_task.delay(should_fail=True)

# Watch logs to see retry attempts
```

### Simulate Network Failures

```python
import random

@app.task(bind=True, autoretry_for=(ConnectionError,), max_retries=5)
def unreliable_task(self, data_id: int):
    # Simulate 50% failure rate
    if random.random() < 0.5:
        raise ConnectionError("Simulated network failure")
    return f"Processed {data_id}"
```

## Common Issues

### Issue: Task Not Retrying

**Solution**: Ensure `bind=True` is set and exception is in `autoretry_for`

```python
# ✅ CORRECT
@app.task(bind=True, autoretry_for=(RequestException,))
def my_task(self):
    pass

# ❌ WRONG - Missing bind=True
@app.task(autoretry_for=(RequestException,))
def my_task():
    pass
```

### Issue: Too Many Retries

**Solution**: Set appropriate `max_retries` and handle permanent errors

```python
@app.task(bind=True, max_retries=3)
def smart_retry_task(self, data_id: int):
    try:
        result = process_data(data_id)
        return result
    except TemporaryError as exc:
        # Retry temporary errors
        raise self.retry(exc=exc)
    except PermanentError:
        # Don't retry permanent errors
        logger.error("Permanent error, not retrying")
        return {'status': 'failed', 'error': 'permanent'}
```

## Performance Considerations

- **Exponential backoff** reduces load on failing services
- **Jitter** prevents thundering herd problem
- **Max retries** prevents infinite retry loops
- **Retry backoff max** caps delay for long-running retries
- **Monitor retry rates** in production to detect systemic issues

## Summary

Key takeaways:
- Use `autoretry_for` for automatic retries
- Enable `retry_backoff` and `retry_jitter`
- Set appropriate `max_retries` for your use case
- Log retry attempts for monitoring
- Handle permanent errors separately from temporary ones
