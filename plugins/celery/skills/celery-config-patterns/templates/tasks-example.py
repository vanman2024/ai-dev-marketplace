"""
Celery Task Examples

This file demonstrates common Celery task patterns and best practices.
Use these examples as templates for your own tasks.
"""

from celery import Task, shared_task, group, chain, chord
from celery.exceptions import SoftTimeLimitExceeded
import time
import logging

# Assume celery_app is imported from your app configuration
# from celery_app import celery_app

logger = logging.getLogger(__name__)


# ============================================================================
# Basic Task
# ============================================================================

@shared_task
def add(x, y):
    """Simple addition task"""
    return x + y


@shared_task
def multiply(x, y):
    """Simple multiplication task"""
    return x * y


# ============================================================================
# Task with Retry Logic
# ============================================================================

@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def fetch_data_with_retry(self, url):
    """
    Fetch data from URL with automatic retry on failure.

    Args:
        url: URL to fetch data from

    Raises:
        self.retry: Retries the task with exponential backoff
    """
    try:
        # Simulate API call
        import requests
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return response.json()

    except requests.RequestException as exc:
        # Retry with exponential backoff
        countdown = 2 ** self.request.retries  # 1, 2, 4, 8...
        logger.warning(f"Fetch failed, retrying in {countdown}s: {exc}")
        raise self.retry(exc=exc, countdown=countdown)

    except Exception as exc:
        # Don't retry for unexpected errors
        logger.error(f"Unexpected error fetching data: {exc}")
        raise


# ============================================================================
# Task with Rate Limiting
# ============================================================================

@shared_task(rate_limit='10/m')
def send_email(to, subject, body):
    """
    Send email with rate limiting.

    Rate limited to 10 emails per minute to avoid overwhelming email server.

    Args:
        to: Recipient email address
        subject: Email subject
        body: Email body
    """
    logger.info(f"Sending email to {to}")
    # Email sending logic here
    time.sleep(1)  # Simulate email sending
    return f"Email sent to {to}"


@shared_task(rate_limit='100/h')
def api_call(endpoint, data):
    """API call with hourly rate limit"""
    logger.info(f"Making API call to {endpoint}")
    # API call logic here
    return {"status": "success"}


# ============================================================================
# Task with Time Limits
# ============================================================================

@shared_task(time_limit=30, soft_time_limit=25)
def process_with_timeout(data):
    """
    Process data with time limits.

    - Hard limit: 30 seconds (task is killed)
    - Soft limit: 25 seconds (SoftTimeLimitExceeded raised)

    Args:
        data: Data to process
    """
    try:
        # Long-running processing
        for i in range(100):
            time.sleep(0.3)  # Simulate work
            # Process data...

        return {"status": "completed"}

    except SoftTimeLimitExceeded:
        # Graceful cleanup before hard limit
        logger.warning("Soft time limit reached, cleaning up...")
        return {"status": "timeout", "partial": True}


# ============================================================================
# Task with Custom Routing
# ============================================================================

@shared_task(queue='critical', routing_key='critical.tasks', priority=10)
def critical_task(data):
    """Critical task routed to high-priority queue"""
    logger.info("Processing critical task")
    return process_critical_data(data)


@shared_task(queue='long_running', routing_key='long.tasks')
def long_running_task(data):
    """Long-running task routed to dedicated queue"""
    logger.info("Starting long-running task")
    time.sleep(60)  # Simulate long process
    return {"status": "completed"}


# ============================================================================
# Task with Progress Tracking
# ============================================================================

@shared_task(bind=True)
def process_with_progress(self, total_items):
    """
    Task that reports progress updates.

    Use case: Long-running tasks where you want to show progress in UI.

    Args:
        total_items: Number of items to process
    """
    for i in range(total_items):
        # Process item
        time.sleep(0.5)

        # Update progress
        self.update_state(
            state='PROGRESS',
            meta={
                'current': i + 1,
                'total': total_items,
                'percent': int((i + 1) / total_items * 100),
                'status': f'Processing item {i + 1} of {total_items}'
            }
        )

    return {
        'status': 'completed',
        'total': total_items
    }


# ============================================================================
# Task with Result Expiration
# ============================================================================

@shared_task(expires=300)  # Expire after 5 minutes
def temporary_task(data):
    """
    Task result expires after 5 minutes.

    Use case: Results that are only needed temporarily.
    """
    return process_temporary_data(data)


# ============================================================================
# Task with Custom Error Handling
# ============================================================================

class CustomTask(Task):
    """Custom task base class with error handling"""

    def on_failure(self, exc, task_id, args, kwargs, einfo):
        """Called when task fails"""
        logger.error(f'Task {task_id} failed: {exc}')
        # Send notification, log to monitoring system, etc.

    def on_success(self, retval, task_id, args, kwargs):
        """Called when task succeeds"""
        logger.info(f'Task {task_id} succeeded')

    def on_retry(self, exc, task_id, args, kwargs, einfo):
        """Called when task is retried"""
        logger.warning(f'Task {task_id} retrying due to: {exc}')


@shared_task(base=CustomTask, bind=True, max_retries=3)
def task_with_custom_handling(self, data):
    """Task using custom error handling"""
    try:
        return process_data(data)
    except Exception as exc:
        raise self.retry(exc=exc)


# ============================================================================
# Task Chains
# ============================================================================

@shared_task
def process_step_1(data):
    """First step in processing chain"""
    logger.info("Step 1: Preprocessing")
    return {"data": data, "step": 1}


@shared_task
def process_step_2(result):
    """Second step in processing chain"""
    logger.info("Step 2: Main processing")
    result["step"] = 2
    return result


@shared_task
def process_step_3(result):
    """Third step in processing chain"""
    logger.info("Step 3: Post-processing")
    result["step"] = 3
    return result


def run_processing_chain(data):
    """Execute tasks in sequence"""
    # Chain: output of each task is input to next
    workflow = chain(
        process_step_1.s(data),
        process_step_2.s(),
        process_step_3.s()
    )
    return workflow.apply_async()


# ============================================================================
# Parallel Tasks with Group
# ============================================================================

@shared_task
def process_item(item_id):
    """Process a single item"""
    logger.info(f"Processing item {item_id}")
    time.sleep(1)
    return {"item_id": item_id, "status": "processed"}


def process_items_parallel(item_ids):
    """Process multiple items in parallel"""
    job = group(process_item.s(item_id) for item_id in item_ids)
    result = job.apply_async()
    return result


# ============================================================================
# Chord Pattern (Parallel + Callback)
# ============================================================================

@shared_task
def aggregate_results(results):
    """Callback that runs after all parallel tasks complete"""
    logger.info(f"Aggregating {len(results)} results")
    return {
        "total": len(results),
        "summary": "All items processed",
        "results": results
    }


def process_with_aggregation(item_ids):
    """Process items in parallel, then aggregate results"""
    callback = aggregate_results.s()
    header = group(process_item.s(item_id) for item_id in item_ids)
    result = chord(header)(callback)
    return result


# ============================================================================
# Periodic Task Example (for Celery Beat)
# ============================================================================

@shared_task
def cleanup_old_records():
    """
    Periodic task to clean up old records.

    Schedule in celeryconfig.py:
        CELERY_BEAT_SCHEDULE = {
            'cleanup-every-night': {
                'task': 'tasks.cleanup_old_records',
                'schedule': crontab(hour=2, minute=0),
            },
        }
    """
    logger.info("Running cleanup task")
    # Cleanup logic here
    deleted_count = 42  # Simulated
    return {"deleted": deleted_count}


@shared_task
def send_weekly_report():
    """
    Weekly report task.

    Schedule:
        'schedule': crontab(day_of_week=1, hour=9, minute=0)
    """
    logger.info("Generating weekly report")
    # Report generation logic
    return {"status": "report sent"}


# ============================================================================
# Task with Database Transaction
# ============================================================================

@shared_task(bind=True)
def update_database(self, record_id, data):
    """
    Task that updates database with transaction handling.

    For Django:
        from django.db import transaction

    For SQLAlchemy:
        from sqlalchemy.orm import sessionmaker
    """
    try:
        # Django example
        from django.db import transaction
        with transaction.atomic():
            # Update record
            # MyModel.objects.filter(id=record_id).update(**data)
            pass

        return {"status": "updated", "record_id": record_id}

    except Exception as exc:
        logger.error(f"Database update failed: {exc}")
        raise self.retry(exc=exc, countdown=60)


# ============================================================================
# Task with File Processing
# ============================================================================

@shared_task(bind=True)
def process_file(self, file_path):
    """
    Process a file with progress tracking.

    Args:
        file_path: Path to file to process
    """
    import os

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    file_size = os.path.getsize(file_path)
    processed = 0

    with open(file_path, 'r') as f:
        for line in f:
            # Process line
            processed += len(line)

            # Update progress
            self.update_state(
                state='PROGRESS',
                meta={
                    'percent': int(processed / file_size * 100),
                    'current': processed,
                    'total': file_size
                }
            )

    return {"status": "completed", "file": file_path}


# ============================================================================
# Task Grouping by Priority
# ============================================================================

@shared_task(queue='critical', priority=10)
def high_priority_task(data):
    """Highest priority task"""
    return process_urgent_data(data)


@shared_task(queue='default', priority=5)
def medium_priority_task(data):
    """Medium priority task"""
    return process_normal_data(data)


@shared_task(queue='default', priority=1)
def low_priority_task(data):
    """Low priority background task"""
    return process_background_data(data)


# ============================================================================
# Helper Functions (Placeholders)
# ============================================================================

def process_critical_data(data):
    """Placeholder for critical data processing"""
    return {"status": "processed", "data": data}


def process_temporary_data(data):
    """Placeholder for temporary data processing"""
    return {"status": "processed", "data": data}


def process_data(data):
    """Placeholder for data processing"""
    return {"status": "processed", "data": data}


def process_urgent_data(data):
    """Placeholder for urgent data processing"""
    return {"status": "processed", "data": data}


def process_normal_data(data):
    """Placeholder for normal data processing"""
    return {"status": "processed", "data": data}


def process_background_data(data):
    """Placeholder for background data processing"""
    return {"status": "processed", "data": data}


# ============================================================================
# Usage Examples
# ============================================================================

"""
# Submit tasks
result = add.delay(4, 6)
print(f"Task ID: {result.id}")
print(f"Result: {result.get(timeout=10)}")

# Check task status
result = fetch_data_with_retry.delay('https://api.example.com/data')
print(f"Status: {result.status}")
print(f"Ready: {result.ready()}")

# Get result with timeout
try:
    data = result.get(timeout=30)
except TimeoutError:
    print("Task timed out")

# Chain tasks
workflow = chain(
    process_step_1.s({"value": 100}),
    process_step_2.s(),
    process_step_3.s()
)
result = workflow.apply_async()

# Parallel processing
job = group(
    process_item.s(1),
    process_item.s(2),
    process_item.s(3)
)
result = job.apply_async()
results = result.get()  # Wait for all to complete

# Chord (parallel + callback)
callback = aggregate_results.s()
header = group(process_item.s(i) for i in range(10))
result = chord(header)(callback)
aggregated = result.get()

# Cancel task
result = long_running_task.delay({"data": "value"})
result.revoke(terminate=True)
"""
