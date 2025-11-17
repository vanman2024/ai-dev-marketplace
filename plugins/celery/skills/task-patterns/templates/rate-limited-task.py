"""Rate Limited Celery Tasks

Demonstrates various rate limiting patterns to control task execution speed.
"""
from celery import Celery, group
from celery.utils.log import get_task_logger
from time import sleep

logger = get_task_logger(__name__)

app = Celery('tasks', broker='redis://localhost:6379/0')


@app.task(rate_limit='10/m')
def api_call_rate_limited(endpoint: str) -> dict:
    """
    Task with rate limit: 10 tasks per minute per worker.

    Rate limiting ensures one task every 6 seconds per worker instance.
    NOTE: This is per-worker, not global across all workers.

    Args:
        endpoint: API endpoint to call

    Returns:
        dict: API response

    Example:
        # These will execute at controlled rate
        for i in range(20):
            api_call_rate_limited.delay(f'/endpoint/{i}')
    """
    logger.info(f"Making rate-limited API call to {endpoint}")

    # Your API call logic here
    return {
        'status': 'success',
        'endpoint': endpoint,
        'rate_limit': '10/m'
    }


@app.task(rate_limit='100/h')
def hourly_rate_limited_task(user_id: int) -> dict:
    """
    Task with hourly rate limit: 100 tasks per hour per worker.

    Ensures one task every 36 seconds per worker instance.

    Args:
        user_id: User ID to process

    Returns:
        dict: Processing result
    """
    logger.info(f"Processing user {user_id} with hourly rate limit")

    return {
        'status': 'processed',
        'user_id': user_id,
        'rate_limit': '100/h'
    }


@app.task(rate_limit='1/s')
def per_second_rate_limited(item_id: int) -> dict:
    """
    Task with per-second rate limit: 1 task per second per worker.

    Args:
        item_id: Item ID to process

    Returns:
        dict: Processing result

    Example:
        # These will execute one per second
        for i in range(10):
            per_second_rate_limited.delay(i)
    """
    logger.info(f"Processing item {item_id} (1 per second)")

    return {
        'status': 'processed',
        'item_id': item_id,
        'rate_limit': '1/s'
    }


@app.task
def batch_with_delay(items: list, delay_seconds: int = 1) -> list:
    """
    Process items in batch with manual delay between each.

    Use this when you need more control than rate_limit provides.

    Args:
        items: List of items to process
        delay_seconds: Delay between processing each item

    Returns:
        list: Processing results for all items

    Example:
        result = batch_with_delay.delay([1, 2, 3, 4, 5], delay_seconds=2)
    """
    results = []

    for i, item in enumerate(items):
        logger.info(f"Processing item {item} ({i+1}/{len(items)})")

        # Your processing logic here
        results.append({
            'item': item,
            'status': 'processed'
        })

        # Manual delay between items (except last one)
        if i < len(items) - 1:
            sleep(delay_seconds)

    return results


@app.task(rate_limit='5/m')
def third_party_api_call(service: str, data: dict) -> dict:
    """
    Call third-party API with rate limit to respect their limits.

    Common use case: External APIs with rate limits.
    Example: Twitter API (5 requests per minute)

    Args:
        service: Service name
        data: Data to send to API

    Returns:
        dict: API response
    """
    logger.info(f"Calling {service} API with rate limit 5/m")

    # Your API call logic here
    return {
        'service': service,
        'status': 'success',
        'data_sent': data
    }


def process_large_dataset_with_rate_limit(dataset: list, rate: str = '10/m'):
    """
    Helper function to process large dataset with rate limiting.

    Args:
        dataset: Large list of items to process
        rate: Rate limit string (e.g., '10/m', '100/h')

    Returns:
        group: Celery group result

    Example:
        dataset = list(range(1000))
        result = process_large_dataset_with_rate_limit(dataset, rate='50/m')
        # Wait for completion
        result.get()
    """
    # Create rate-limited task dynamically
    @app.task(rate_limit=rate)
    def process_item(item):
        logger.info(f"Processing item {item} with rate {rate}")
        return {'item': item, 'status': 'processed'}

    # Create group of tasks (all respect rate limit)
    job = group(process_item.s(item) for item in dataset)
    return job.apply_async()


# Example usage
if __name__ == '__main__':
    # Rate limited API calls
    print("Sending 20 rate-limited API calls (10/m)...")
    results = []
    for i in range(20):
        result = api_call_rate_limited.delay(f'/endpoint/{i}')
        results.append(result)

    # Batch processing with manual delay
    print("\nProcessing batch with 2-second delays...")
    batch_result = batch_with_delay.delay([1, 2, 3, 4, 5], delay_seconds=2)

    # Large dataset with rate limiting
    print("\nProcessing large dataset with rate limiting...")
    large_dataset = list(range(100))
    dataset_result = process_large_dataset_with_rate_limit(
        large_dataset,
        rate='50/m'
    )

    print(f"\nAll tasks queued. Monitor with: celery -A tasks inspect active")
