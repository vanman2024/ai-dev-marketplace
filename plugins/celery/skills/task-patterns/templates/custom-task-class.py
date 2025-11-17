"""Custom Celery Task Classes

Demonstrates creating custom task base classes with specialized behavior.
"""
from celery import Celery, Task
from celery.utils.log import get_task_logger
from contextlib import contextmanager
from typing import Any
import time

logger = get_task_logger(__name__)

app = Celery('tasks', broker='redis://localhost:6379/0')


class DatabaseTask(Task):
    """
    Custom task that manages database connection lifecycle.

    Connection is created once per worker process and reused.
    """
    _db = None

    def __init__(self):
        """Initialize once per worker process."""
        super().__init__()
        logger.info("DatabaseTask initialized")

    @property
    def db(self):
        """Lazy database connection (created on first access)."""
        if self._db is None:
            logger.info("Creating database connection")
            # Replace with actual database connection
            self._db = self._create_connection()
        return self._db

    def _create_connection(self):
        """Create database connection."""
        # Placeholder for actual database connection
        return {"connection": "active", "created_at": time.time()}

    def before_start(self, task_id, args, kwargs):
        """Execute before task starts."""
        logger.info(f"Task {task_id} starting with args={args}, kwargs={kwargs}")

    def on_success(self, retval, task_id, args, kwargs):
        """Execute on successful task completion."""
        logger.info(f"Task {task_id} succeeded with result: {retval}")

    def on_failure(self, exc, task_id, args, kwargs, einfo):
        """Execute on task failure."""
        logger.error(f"Task {task_id} failed: {exc}")

    def on_retry(self, exc, task_id, args, kwargs, einfo):
        """Execute when task is retried."""
        logger.warning(f"Task {task_id} retrying due to: {exc}")

    def after_return(self, status, retval, task_id, args, kwargs, einfo):
        """Execute after task returns (success or failure)."""
        logger.info(f"Task {task_id} returned with status: {status}")


@app.task(base=DatabaseTask, bind=True)
def query_database(self, query: str) -> dict:
    """
    Execute database query using custom task class.

    Args:
        query: SQL query to execute

    Returns:
        dict: Query results

    Example:
        result = query_database.delay("SELECT * FROM users")
    """
    logger.info(f"Executing query: {query}")

    # Access database connection from custom task class
    db = self.db
    logger.info(f"Using database connection: {db}")

    # Your query logic here
    return {
        'status': 'success',
        'query': query,
        'rows': 42
    }


class CachedTask(Task):
    """
    Custom task with caching capability.

    Caches results to avoid redundant processing.
    """
    _cache = {}

    def run(self, *args, **kwargs):
        """Override run to add caching logic."""
        # Create cache key from arguments
        cache_key = self._make_cache_key(args, kwargs)

        # Check cache
        if cache_key in self._cache:
            logger.info(f"Cache hit for key: {cache_key}")
            return self._cache[cache_key]

        # Execute task
        logger.info(f"Cache miss for key: {cache_key}")
        result = super().run(*args, **kwargs)

        # Store in cache
        self._cache[cache_key] = result
        return result

    def _make_cache_key(self, args, kwargs):
        """Create cache key from arguments."""
        return f"{self.name}:{args}:{kwargs}"


@app.task(base=CachedTask, bind=True)
def expensive_computation(self, x: int, y: int) -> int:
    """
    Expensive computation with automatic caching.

    Args:
        x: First number
        y: Second number

    Returns:
        int: Computation result
    """
    logger.info(f"Computing {x} * {y} (expensive operation)")
    time.sleep(2)  # Simulate expensive computation
    return x * y


class MetricsTask(Task):
    """
    Custom task that tracks execution metrics.
    """

    def before_start(self, task_id, args, kwargs):
        """Record start time."""
        self.start_time = time.time()
        logger.info(f"Task {task_id} started at {self.start_time}")

    def after_return(self, status, retval, task_id, args, kwargs, einfo):
        """Record metrics after task completion."""
        duration = time.time() - self.start_time

        metrics = {
            'task_id': task_id,
            'task_name': self.name,
            'status': status,
            'duration': duration,
            'args': args,
            'kwargs': kwargs
        }

        logger.info(f"Task {task_id} metrics: {metrics}")
        # Send metrics to monitoring system (Prometheus, DataDog, etc.)
        self._send_metrics(metrics)

    def _send_metrics(self, metrics: dict):
        """Send metrics to monitoring system."""
        # Placeholder for metrics reporting
        logger.info(f"Sending metrics: {metrics}")


@app.task(base=MetricsTask, bind=True)
def monitored_task(self, item_id: int) -> dict:
    """
    Task with automatic metrics tracking.

    Args:
        item_id: Item to process

    Returns:
        dict: Processing result
    """
    logger.info(f"Processing item {item_id}")
    time.sleep(1)  # Simulate work
    return {'status': 'processed', 'item_id': item_id}


class RetryableTask(Task):
    """
    Custom task with intelligent retry logic.
    """
    autoretry_for = (Exception,)
    retry_kwargs = {'max_retries': 5}
    retry_backoff = True
    retry_backoff_max = 600
    retry_jitter = True

    def on_retry(self, exc, task_id, args, kwargs, einfo):
        """Custom retry handling."""
        retry_count = self.request.retries
        logger.warning(
            f"Task {task_id} retry {retry_count}/{self.max_retries}: {exc}"
        )

        # Custom logic based on retry count
        if retry_count > 3:
            logger.error(f"Task {task_id} failing repeatedly, alerting team")
            self._send_alert(task_id, exc)

    def _send_alert(self, task_id: str, exc: Exception):
        """Send alert on repeated failures."""
        logger.error(f"ALERT: Task {task_id} failed multiple times: {exc}")


@app.task(base=RetryableTask, bind=True)
def reliable_api_call(self, url: str) -> dict:
    """
    API call with intelligent retry handling.

    Args:
        url: API endpoint

    Returns:
        dict: API response
    """
    import requests

    logger.info(f"Calling API: {url}")
    response = requests.get(url, timeout=10)
    response.raise_for_status()

    return response.json()


class ResourcePoolTask(Task):
    """
    Custom task that manages a pool of reusable resources.
    """
    _pool = []
    _pool_size = 5

    @contextmanager
    def acquire_resource(self):
        """Context manager for resource acquisition."""
        if not self._pool:
            resource = self._create_resource()
            logger.info("Created new resource")
        else:
            resource = self._pool.pop()
            logger.info("Acquired resource from pool")

        try:
            yield resource
        finally:
            if len(self._pool) < self._pool_size:
                self._pool.append(resource)
                logger.info("Returned resource to pool")
            else:
                self._cleanup_resource(resource)
                logger.info("Pool full, cleaned up resource")

    def _create_resource(self):
        """Create new resource."""
        return {"id": time.time(), "type": "resource"}

    def _cleanup_resource(self, resource):
        """Clean up resource."""
        logger.info(f"Cleaning up resource: {resource}")


@app.task(base=ResourcePoolTask, bind=True)
def task_with_pooled_resource(self, data: str) -> dict:
    """
    Task that uses pooled resource.

    Args:
        data: Data to process

    Returns:
        dict: Processing result
    """
    with self.acquire_resource() as resource:
        logger.info(f"Processing data with resource {resource['id']}")
        return {
            'status': 'processed',
            'data': data,
            'resource_id': resource['id']
        }


# Example usage
if __name__ == '__main__':
    # Database task
    result1 = query_database.delay("SELECT * FROM users")
    print(f"Database Task ID: {result1.id}")

    # Cached task (first call)
    result2 = expensive_computation.delay(5, 10)
    print(f"Cached Task ID: {result2.id}")

    # Cached task (second call - should hit cache)
    result3 = expensive_computation.delay(5, 10)
    print(f"Cached Task ID (should be fast): {result3.id}")

    # Monitored task
    result4 = monitored_task.delay(123)
    print(f"Monitored Task ID: {result4.id}")

    # Reliable API call
    result5 = reliable_api_call.delay('https://api.example.com/data')
    print(f"API Call Task ID: {result5.id}")

    # Pooled resource task
    result6 = task_with_pooled_resource.delay("test data")
    print(f"Resource Pool Task ID: {result6.id}")
