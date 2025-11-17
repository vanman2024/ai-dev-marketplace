"""Time Limited Celery Tasks

Demonstrates soft and hard time limits to prevent runaway tasks.
"""
from celery import Celery
from celery.exceptions import SoftTimeLimitExceeded
from celery.utils.log import get_task_logger
from time import sleep

logger = get_task_logger(__name__)

app = Celery('tasks', broker='redis://localhost:6379/0')


@app.task(soft_time_limit=30, time_limit=60)
def processing_with_timeout(data_size: int) -> dict:
    """
    Task with both soft and hard time limits.

    Time limits:
    - Soft limit (30s): Raises SoftTimeLimitExceeded (can be caught)
    - Hard limit (60s): Forces SIGKILL (cannot be caught)

    Args:
        data_size: Amount of data to process

    Returns:
        dict: Processing results

    Example:
        result = processing_with_timeout.delay(1000)
    """
    try:
        logger.info(f"Processing {data_size} items with 30s soft / 60s hard limit")

        # Simulate long-running task
        for i in range(data_size):
            # Your processing logic here
            sleep(0.1)  # Simulate work

            if i % 100 == 0:
                logger.info(f"Processed {i}/{data_size} items")

        return {
            'status': 'completed',
            'items_processed': data_size
        }

    except SoftTimeLimitExceeded:
        # Soft limit exceeded - graceful cleanup
        logger.warning(
            f"Soft time limit exceeded. Processed {i}/{data_size} items. "
            "Saving progress..."
        )

        # Save partial results
        return {
            'status': 'partial',
            'items_processed': i,
            'total_items': data_size,
            'reason': 'soft_timeout'
        }


@app.task(bind=True, soft_time_limit=10)
def graceful_timeout_task(self, job_id: int) -> dict:
    """
    Task that handles soft timeout gracefully with progress saving.

    Best practice for long-running tasks that can be resumed.

    Args:
        job_id: Job identifier

    Returns:
        dict: Job status and progress
    """
    try:
        logger.info(f"Starting job {job_id} with 10s soft limit")

        progress = 0
        total_steps = 100

        for step in range(total_steps):
            # Your work here
            sleep(0.2)  # Simulate work
            progress = step + 1

            # Periodic progress logging
            if progress % 10 == 0:
                logger.info(f"Job {job_id}: {progress}/{total_steps} steps")

        return {
            'status': 'completed',
            'job_id': job_id,
            'progress': progress,
            'total': total_steps
        }

    except SoftTimeLimitExceeded:
        logger.warning(f"Job {job_id} timed out at step {progress}/{total_steps}")

        # Save progress to resume later
        save_job_progress(job_id, progress)

        # Retry from where we left off
        raise self.retry(
            countdown=5,
            kwargs={'job_id': job_id, 'resume_from': progress}
        )


@app.task(time_limit=120)  # Hard limit only
def critical_task_with_hard_limit(task_id: int) -> dict:
    """
    Task with only hard time limit (no soft limit).

    Use when task MUST complete or be killed - no graceful handling.

    WARNING: Hard limit uses SIGKILL - cannot be caught or handled.
    Task will be terminated and marked as failed.

    Args:
        task_id: Task identifier

    Returns:
        dict: Task results
    """
    logger.info(f"Running critical task {task_id} with 120s hard limit")

    # Your time-critical logic here
    # If this exceeds 120s, it will be killed with SIGKILL

    return {
        'status': 'completed',
        'task_id': task_id
    }


@app.task(bind=True, soft_time_limit=60)
def api_call_with_timeout(self, url: str, max_retries: int = 3) -> dict:
    """
    API call with timeout and retry logic.

    Combines time limits with retry mechanism for reliability.

    Args:
        url: API endpoint URL
        max_retries: Maximum retry attempts

    Returns:
        dict: API response
    """
    import requests

    try:
        logger.info(f"Calling API: {url} (attempt {self.request.retries + 1})")

        # API call with requests timeout
        response = requests.get(url, timeout=30)
        response.raise_for_status()

        return {
            'status': 'success',
            'url': url,
            'data': response.json()
        }

    except SoftTimeLimitExceeded:
        logger.warning(f"API call to {url} exceeded soft time limit")

        if self.request.retries < max_retries:
            logger.info(f"Retrying API call to {url}")
            raise self.retry(countdown=10, max_retries=max_retries)
        else:
            return {
                'status': 'failed',
                'url': url,
                'reason': 'timeout_max_retries'
            }

    except requests.RequestException as exc:
        logger.error(f"API call failed: {exc}")
        raise


def save_job_progress(job_id: int, progress: int):
    """Helper function to save job progress."""
    logger.info(f"Saving progress for job {job_id}: {progress}")
    # Your progress saving logic here (database, cache, etc.)


# Configuration examples for celeryconfig.py
CELERY_CONFIG_EXAMPLES = """
# Global time limit settings (apply to all tasks)
task_soft_time_limit = 300  # 5 minutes
task_time_limit = 600       # 10 minutes

# Per-task override using task_annotations
task_annotations = {
    'tasks.long_running_task': {
        'soft_time_limit': 3600,  # 1 hour
        'time_limit': 7200,       # 2 hours
    },
    'tasks.quick_task': {
        'soft_time_limit': 10,    # 10 seconds
        'time_limit': 30,         # 30 seconds
    }
}
"""


# Example usage
if __name__ == '__main__':
    # Task with both limits
    result1 = processing_with_timeout.delay(1000)
    print(f"Processing Task ID: {result1.id}")

    # Task with graceful timeout handling
    result2 = graceful_timeout_task.delay(123)
    print(f"Graceful Timeout Task ID: {result2.id}")

    # Task with hard limit only
    result3 = critical_task_with_hard_limit.delay(456)
    print(f"Critical Task ID: {result3.id}")

    # API call with timeout
    result4 = api_call_with_timeout.delay('https://api.example.com/data')
    print(f"API Call Task ID: {result4.id}")

    print("\nMonitor tasks with: celery -A tasks inspect active")
    print("Time limits visible in: celery -A tasks inspect stats")
