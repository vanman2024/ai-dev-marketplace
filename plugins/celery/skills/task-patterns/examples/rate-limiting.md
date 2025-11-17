# Rate Limiting Example

Complete guide to implementing rate limiting in Celery tasks to control execution speed and respect API quotas.

## Why Rate Limiting?

Rate limiting is crucial when:
- **External API quotas**: APIs limit requests per minute/hour
- **Resource protection**: Prevent overwhelming databases or services
- **Cost control**: Reduce expenses from high-volume operations
- **Compliance**: Meet SLA or terms of service requirements

## Basic Rate Limiting

### Per-Minute Rate Limit

```python
from celery import Celery
from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)
app = Celery('tasks', broker='redis://localhost:6379/0')


@app.task(rate_limit='10/m')
def api_call(endpoint: str) -> dict:
    """
    Task with 10 calls per minute per worker.

    This ensures one call every 6 seconds per worker instance.
    """
    logger.info(f"Calling API endpoint: {endpoint}")

    # Your API call logic
    return {'status': 'success', 'endpoint': endpoint}
```

### Per-Second Rate Limit

```python
@app.task(rate_limit='1/s')
def one_per_second(item_id: int) -> dict:
    """Process one item per second per worker."""
    logger.info(f"Processing item {item_id}")
    return {'item_id': item_id, 'status': 'processed'}
```

### Per-Hour Rate Limit

```python
@app.task(rate_limit='100/h')
def hourly_limited_task(data_id: int) -> dict:
    """
    Process 100 items per hour per worker.

    One task every 36 seconds.
    """
    logger.info(f"Processing data {data_id}")
    return {'data_id': data_id, 'status': 'processed'}
```

## Advanced Rate Limiting Patterns

### Multiple Rate Limits by Task Type

```python
# Fast tasks - high rate limit
@app.task(rate_limit='100/m')
def fast_operation(item_id: int):
    """Quick operations can run frequently."""
    return process_fast(item_id)


# Slow tasks - low rate limit
@app.task(rate_limit='10/m')
def slow_operation(item_id: int):
    """Slow operations need throttling."""
    return process_slow(item_id)


# External API - match their limits
@app.task(rate_limit='5/m')
def third_party_api_call(endpoint: str):
    """
    Match third-party API rate limit.

    Example: Twitter API allows 5 requests per minute.
    """
    return call_external_api(endpoint)
```

### Dynamic Rate Limiting

```python
from celery import current_app

def set_rate_limit(task_name: str, rate: str):
    """
    Dynamically change task rate limit.

    Args:
        task_name: Name of the task
        rate: Rate limit string (e.g., '10/m')
    """
    current_app.control.rate_limit(task_name, rate)


# Usage
set_rate_limit('tasks.api_call', '20/m')  # Increase to 20/min
set_rate_limit('tasks.api_call', '5/m')   # Decrease to 5/min
```

### Rate Limiting by Priority

```python
@app.task(rate_limit='50/m', priority=9)
def high_priority_task(item_id: int):
    """High priority with higher rate limit."""
    return process_priority(item_id)


@app.task(rate_limit='10/m', priority=1)
def low_priority_task(item_id: int):
    """Low priority with lower rate limit."""
    return process_background(item_id)
```

## Rate Limiting Large Batches

### Process Large Dataset with Rate Control

```python
from celery import group
from time import sleep


@app.task(rate_limit='10/m')
def process_single_item(item_id: int) -> dict:
    """Process individual item with rate limit."""
    logger.info(f"Processing item {item_id}")
    return {'item_id': item_id, 'status': 'processed'}


def process_large_batch(items: list) -> dict:
    """
    Process large batch respecting rate limits.

    Args:
        items: List of items to process

    Returns:
        dict: Processing results
    """
    # Create group of rate-limited tasks
    job = group(process_single_item.s(item) for item in items)

    # Execute (rate limit applies to each task)
    result = job.apply_async()

    logger.info(f"Queued {len(items)} items with rate limiting")

    return {
        'total_items': len(items),
        'group_id': result.id,
        'rate_limit': '10/m'
    }


# Usage
items = list(range(1000))  # 1000 items
result = process_large_batch(items)

# Tasks will execute at 10/minute automatically
```

### Chunked Processing with Delays

```python
@app.task
def process_batch_with_manual_delay(items: list, delay_seconds: int = 6) -> list:
    """
    Process batch with manual delays between items.

    Use this when you need more control than rate_limit provides.

    Args:
        items: Items to process
        delay_seconds: Delay between each item

    Returns:
        list: Processing results
    """
    results = []

    for i, item in enumerate(items):
        logger.info(f"Processing item {i+1}/{len(items)}: {item}")

        # Your processing logic
        result = {'item': item, 'status': 'processed'}
        results.append(result)

        # Manual delay (except after last item)
        if i < len(items) - 1:
            sleep(delay_seconds)

    return results


# Process 100 items with 6-second delays (10/minute)
result = process_batch_with_manual_delay.delay(items, delay_seconds=6)
```

## Real-World Examples

### Example 1: Twitter API Integration

```python
@app.task(
    rate_limit='5/m',  # Twitter API: 5 requests per minute
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=True,
    max_retries=3
)
def fetch_tweets(self, query: str, count: int = 10) -> dict:
    """
    Fetch tweets respecting Twitter's rate limit.

    Args:
        query: Search query
        count: Number of tweets to fetch

    Returns:
        dict: Tweet data
    """
    import requests

    logger.info(f"Fetching tweets for query: {query}")

    # IMPORTANT: Use environment variable for API key
    import os
    api_key = os.getenv('TWITTER_API_KEY', 'your_twitter_api_key_here')

    headers = {'Authorization': f'Bearer {api_key}'}

    response = requests.get(
        'https://api.twitter.com/2/tweets/search/recent',
        params={'query': query, 'max_results': count},
        headers=headers,
        timeout=30
    )

    response.raise_for_status()

    return {
        'query': query,
        'tweets': response.json(),
        'rate_limit_remaining': response.headers.get('x-rate-limit-remaining')
    }
```

### Example 2: Database Backup with Rate Control

```python
@app.task(rate_limit='1/s')  # One backup per second
def backup_table_row(table: str, row_id: int) -> dict:
    """
    Backup individual table row.

    Rate limited to prevent overwhelming database.
    """
    logger.info(f"Backing up {table} row {row_id}")

    # Your backup logic
    return {'table': table, 'row_id': row_id, 'backed_up': True}


@app.task
def backup_entire_table(table: str, row_ids: list) -> dict:
    """
    Backup entire table with rate limiting.

    Args:
        table: Table name
        row_ids: List of row IDs to backup

    Returns:
        dict: Backup status
    """
    from celery import group

    # Create rate-limited backup tasks
    job = group(backup_table_row.s(table, row_id) for row_id in row_ids)

    result = job.apply_async()

    return {
        'table': table,
        'total_rows': len(row_ids),
        'group_id': result.id,
        'rate': '1/s'
    }
```

### Example 3: Email Sending with Provider Limits

```python
@app.task(
    rate_limit='100/h',  # Email provider: 100 emails per hour
    bind=True,
    autoretry_for=(Exception,),
    max_retries=3
)
def send_email(self, to: str, subject: str, body: str) -> dict:
    """
    Send email respecting provider rate limits.

    Args:
        to: Recipient email
        subject: Email subject
        body: Email body

    Returns:
        dict: Send status
    """
    logger.info(f"Sending email to {to}")

    # Your email sending logic
    # (using placeholder - integrate with actual provider)

    return {
        'to': to,
        'subject': subject,
        'status': 'sent',
        'attempt': self.request.retries + 1
    }


@app.task
def send_bulk_emails(recipients: list, subject: str, body: str) -> dict:
    """
    Send bulk emails with rate limiting.

    Args:
        recipients: List of email addresses
        subject: Email subject
        body: Email body

    Returns:
        dict: Bulk send status
    """
    from celery import group

    job = group(
        send_email.s(recipient, subject, body)
        for recipient in recipients
    )

    result = job.apply_async()

    return {
        'total_recipients': len(recipients),
        'group_id': result.id,
        'rate_limit': '100/h'
    }
```

## Configuration

### Global Rate Limits (celeryconfig.py)

```python
# Set default rate limits for all tasks
task_default_rate_limit = '100/m'

# Set per-task rate limits
task_annotations = {
    'tasks.api_call': {'rate_limit': '10/m'},
    'tasks.send_email': {'rate_limit': '100/h'},
    'tasks.backup_row': {'rate_limit': '1/s'},
}
```

### Worker-Level Rate Limiting

```bash
# Start worker with global rate limit
celery -A tasks worker --max-tasks-per-child=100 --rate-limit=100/m

# Start multiple workers with different limits
celery -A tasks worker -Q high-priority --rate-limit=50/m &
celery -A tasks worker -Q low-priority --rate-limit=10/m &
```

## Monitoring Rate Limits

### Check Current Rate Limits

```python
from celery import current_app

# Get task info including rate limit
task_info = current_app.tasks['tasks.api_call']
print(f"Rate limit: {task_info.rate_limit}")
```

### Monitor Task Execution Rate

```bash
# View active tasks
celery -A tasks inspect active

# View task statistics
celery -A tasks inspect stats

# View rate limit info
celery -A tasks inspect active_queues
```

### Log Rate Limit Information

```python
@app.task(bind=True, rate_limit='10/m')
def monitored_task(self, item_id: int):
    """Task with rate limit monitoring."""

    # Log rate limit info
    logger.info(
        f"Task: {self.name}, "
        f"Rate limit: {self.rate_limit}, "
        f"Item: {item_id}"
    )

    return {'item_id': item_id, 'status': 'processed'}
```

## Best Practices

### 1. Match External API Limits

```python
# If API allows 60 requests per minute
@app.task(rate_limit='60/m')

# If API allows 1000 requests per hour
@app.task(rate_limit='1000/h')
```

### 2. Account for Multiple Workers

```python
# If you have 4 workers and API limit is 100/min
# Set each worker to 25/min
@app.task(rate_limit='25/m')
```

### 3. Use Buffer for Safety

```python
# If API limit is 100/min, use 80/min for safety
@app.task(rate_limit='80/m')
```

### 4. Combine with Retries

```python
@app.task(
    rate_limit='10/m',
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=True,
    max_retries=5
)
def resilient_rate_limited_task(self, data_id: int):
    """Rate limited with automatic retries."""
    # Your logic
    pass
```

### 5. Different Limits for Different Operations

```python
# Read operations - higher limit
@app.task(rate_limit='100/m')
def read_api():
    pass

# Write operations - lower limit
@app.task(rate_limit='10/m')
def write_api():
    pass
```

## Common Pitfalls

### ❌ Wrong: Rate Limit Per Worker Not Global

```python
# This limits EACH worker to 10/min
# With 5 workers, actual rate is 50/min!
@app.task(rate_limit='10/m')
```

### ✅ Correct: Account for All Workers

```python
# If you have 5 workers and want 50/min total
# Set each worker to 10/min
@app.task(rate_limit='10/m')
```

### ❌ Wrong: No Rate Limit on External APIs

```python
# This could exceed API limits and get blocked
@app.task
def uncontrolled_api_call():
    pass
```

### ✅ Correct: Always Rate Limit External APIs

```python
@app.task(rate_limit='10/m')
def controlled_api_call():
    pass
```

## Testing Rate Limits

```python
import time

@app.task(rate_limit='6/m')  # One every 10 seconds
def test_rate_limit(item_id: int):
    logger.info(f"Processing {item_id} at {time.time()}")
    return item_id


# Test: Queue 12 tasks
if __name__ == '__main__':
    start_time = time.time()

    results = []
    for i in range(12):
        result = test_rate_limit.delay(i)
        results.append(result)

    # Should take ~20 seconds (12 tasks at 6/min rate)
    for result in results:
        result.get()

    elapsed = time.time() - start_time
    print(f"Elapsed time: {elapsed:.2f} seconds")
    print(f"Expected: ~20 seconds")
```

## Summary

Rate limiting best practices:
- Always rate limit external API calls
- Account for number of workers in calculations
- Use buffer below actual API limits
- Combine with retry logic
- Monitor execution rates in production
- Test rate limits before deploying
- Document rate limit reasoning

Rate limit syntax:
- `'10/s'` = 10 per second
- `'100/m'` = 100 per minute
- `'1000/h'` = 1000 per hour
