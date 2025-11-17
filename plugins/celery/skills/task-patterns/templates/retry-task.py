"""Celery Task with Retry Mechanisms

Demonstrates automatic retries with exponential backoff.
"""
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
    retry_backoff_max=600,  # 10 minutes max
    retry_jitter=True,
    max_retries=5
)
def fetch_api_data(self, url: str) -> dict:
    """
    Fetch data from API with automatic retries on failure.

    Retry behavior:
    - Retries on RequestException and Timeout
    - Exponential backoff: 1s, 2s, 4s, 8s, 16s...
    - Maximum backoff: 10 minutes
    - Jitter added to prevent thundering herd
    - Maximum 5 retry attempts

    Args:
        url: API endpoint URL

    Returns:
        dict: API response data

    Example:
        result = fetch_api_data.delay('https://api.example.com/data')
    """
    try:
        logger.info(f"Fetching data from {url} (attempt {self.request.retries + 1})")

        response = requests.get(url, timeout=10)
        response.raise_for_status()

        data = response.json()
        logger.info(f"Successfully fetched data from {url}")
        return data

    except (RequestException, Timeout) as exc:
        logger.warning(
            f"Request failed (attempt {self.request.retries + 1}): {exc}. "
            f"Will retry with backoff."
        )
        raise  # Let autoretry_for handle the retry


@app.task(bind=True, max_retries=3)
def manual_retry_task(self, data_id: int):
    """
    Task with manual retry control.

    Use this when you need custom retry logic based on error type.

    Args:
        data_id: ID of data to process

    Example:
        result = manual_retry_task.delay(123)
    """
    try:
        logger.info(f"Processing data ID: {data_id}")

        # Your processing logic here
        # Simulate conditional failure
        if data_id % 2 == 0:
            raise ValueError("Even IDs not supported")

        return {'status': 'success', 'data_id': data_id}

    except ValueError as exc:
        # Retry with custom countdown
        logger.warning(f"Retrying task for data_id {data_id}: {exc}")
        raise self.retry(exc=exc, countdown=60)  # Retry after 60 seconds

    except Exception as exc:
        # Don't retry on unexpected errors
        logger.error(f"Fatal error processing data_id {data_id}: {exc}")
        raise


@app.task(
    bind=True,
    autoretry_for=(ConnectionError,),
    retry_kwargs={'max_retries': 10},
    default_retry_delay=30  # Fixed delay instead of exponential
)
def connect_database(self, db_host: str) -> dict:
    """
    Connect to database with fixed retry delay.

    Retry behavior:
    - Retries on ConnectionError
    - Fixed 30 second delay between retries
    - Maximum 10 retry attempts

    Args:
        db_host: Database host to connect to

    Returns:
        dict: Connection status
    """
    logger.info(f"Connecting to database at {db_host}")

    # Your connection logic here
    # Placeholder for actual database connection
    return {
        'status': 'connected',
        'host': db_host,
        'attempt': self.request.retries + 1
    }


# Example usage
if __name__ == '__main__':
    # API fetch with automatic retries
    result1 = fetch_api_data.delay('https://api.example.com/data')
    print(f"API Task ID: {result1.id}")

    # Manual retry control
    result2 = manual_retry_task.delay(123)
    print(f"Manual Retry Task ID: {result2.id}")

    # Database connection with retries
    result3 = connect_database.delay('localhost')
    print(f"DB Connection Task ID: {result3.id}")
