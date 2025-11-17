# Custom Task Classes Example

Complete guide to creating custom Celery task base classes for specialized behavior.

## Why Custom Task Classes?

Custom task classes provide:
- **Resource pooling**: Share database connections, API clients
- **Lifecycle hooks**: Execute code before/after tasks
- **Shared logic**: Reuse common patterns across tasks
- **Centralized configuration**: One place for task behavior

## Basic Custom Task Class

### Simple Custom Task

```python
from celery import Celery, Task
from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)
app = Celery('tasks', broker='redis://localhost:6379/0')


class CustomTask(Task):
    """
    Custom task base class with lifecycle hooks.
    """

    def before_start(self, task_id, args, kwargs):
        """Execute before task starts."""
        logger.info(f"Task {task_id} starting with args={args}")

    def on_success(self, retval, task_id, args, kwargs):
        """Execute on successful completion."""
        logger.info(f"Task {task_id} succeeded: {retval}")

    def on_failure(self, exc, task_id, args, kwargs, einfo):
        """Execute on task failure."""
        logger.error(f"Task {task_id} failed: {exc}")

    def on_retry(self, exc, task_id, args, kwargs, einfo):
        """Execute when task is retried."""
        logger.warning(f"Task {task_id} retrying: {exc}")

    def after_return(self, status, retval, task_id, args, kwargs, einfo):
        """Execute after task returns (always runs)."""
        logger.info(f"Task {task_id} completed with status: {status}")


@app.task(base=CustomTask, bind=True)
def my_task(self, value: int) -> int:
    """Task using custom base class."""
    logger.info(f"Processing value: {value}")
    return value * 2


# Usage
result = my_task.delay(10)
print(f"Result: {result.get()}")
```

## Database Connection Pooling

### Database Task with Connection Reuse

```python
from celery import Task
from contextlib import contextmanager


class DatabaseTask(Task):
    """
    Task that manages database connections.

    Connection is created once per worker process and reused.
    """
    _db = None

    def __init__(self):
        """Initialize once per worker process."""
        super().__init__()
        logger.info("DatabaseTask initialized")

    @property
    def db(self):
        """Lazy database connection."""
        if self._db is None:
            logger.info("Creating database connection")
            # Replace with actual database connection
            from sqlalchemy import create_engine
            self._db = create_engine(
                'postgresql://user:pass@localhost/db',
                pool_size=10,
                max_overflow=20
            )
        return self._db

    def before_start(self, task_id, args, kwargs):
        """Log task start."""
        logger.info(f"Database task {task_id} starting")

    def on_failure(self, exc, task_id, args, kwargs, einfo):
        """Handle database errors."""
        logger.error(f"Database task {task_id} failed: {exc}")

        # Optionally reset connection on certain errors
        if "connection" in str(exc).lower():
            logger.warning("Resetting database connection")
            self._db = None


@app.task(base=DatabaseTask, bind=True)
def query_users(self, min_age: int):
    """Query database using connection pool."""
    db = self.db

    # Your query logic
    query = f"SELECT * FROM users WHERE age >= {min_age}"
    result = db.execute(query)

    return {'users': list(result), 'count': result.rowcount}


@app.task(base=DatabaseTask, bind=True)
def insert_user(self, name: str, email: str):
    """Insert user using connection pool."""
    db = self.db

    # Your insert logic
    query = "INSERT INTO users (name, email) VALUES (%s, %s)"
    db.execute(query, (name, email))

    return {'status': 'inserted', 'name': name}
```

## Caching Task Results

### Cached Task Class

```python
import hashlib
import json


class CachedTask(Task):
    """
    Task with automatic result caching.

    Caches results based on arguments to avoid redundant work.
    """
    _cache = {}

    def run(self, *args, **kwargs):
        """Override run to add caching."""
        # Create cache key from arguments
        cache_key = self._make_cache_key(args, kwargs)

        # Check cache
        if cache_key in self._cache:
            logger.info(f"Cache hit: {cache_key}")
            return self._cache[cache_key]

        # Execute task
        logger.info(f"Cache miss: {cache_key}")
        result = super().run(*args, **kwargs)

        # Store in cache
        self._cache[cache_key] = result
        logger.info(f"Cached result: {cache_key}")

        return result

    def _make_cache_key(self, args, kwargs):
        """Create cache key from arguments."""
        # Serialize arguments
        data = json.dumps({
            'args': args,
            'kwargs': kwargs,
            'task': self.name
        }, sort_keys=True)

        # Hash for consistent key
        return hashlib.md5(data.encode()).hexdigest()


@app.task(base=CachedTask, bind=True)
def expensive_computation(self, x: int, y: int) -> int:
    """Expensive computation with caching."""
    import time

    logger.info(f"Computing {x} * {y} (slow operation)")
    time.sleep(2)  # Simulate expensive work

    return x * y


# First call: slow (cache miss)
result1 = expensive_computation.delay(10, 20)
print(result1.get())  # Takes 2 seconds

# Second call with same args: fast (cache hit)
result2 = expensive_computation.delay(10, 20)
print(result2.get())  # Instant

# Different args: slow again (cache miss)
result3 = expensive_computation.delay(5, 5)
print(result3.get())  # Takes 2 seconds
```

## Metrics and Monitoring

### Metrics Task Class

```python
import time
from datetime import datetime


class MetricsTask(Task):
    """
    Task that automatically tracks execution metrics.
    """

    def before_start(self, task_id, args, kwargs):
        """Record start time and task info."""
        self.start_time = time.time()
        self.start_datetime = datetime.utcnow()

        logger.info(
            f"Task {task_id} ({self.name}) started at {self.start_datetime}"
        )

    def after_return(self, status, retval, task_id, args, kwargs, einfo):
        """Calculate and report metrics."""
        duration = time.time() - self.start_time

        metrics = {
            'task_id': task_id,
            'task_name': self.name,
            'status': status,
            'duration_seconds': duration,
            'started_at': self.start_datetime.isoformat(),
            'completed_at': datetime.utcnow().isoformat(),
            'args': str(args)[:100],  # Truncate for logging
            'kwargs': str(kwargs)[:100]
        }

        logger.info(f"Task metrics: {json.dumps(metrics)}")

        # Send to monitoring system
        self._send_to_monitoring(metrics)

    def _send_to_monitoring(self, metrics: dict):
        """Send metrics to monitoring system."""
        # Example: Send to Prometheus, DataDog, CloudWatch, etc.
        # This is a placeholder
        logger.info(f"Sending metrics: {metrics['task_name']} took {metrics['duration_seconds']:.2f}s")


@app.task(base=MetricsTask, bind=True)
def monitored_operation(self, item_id: int) -> dict:
    """Operation with automatic metrics tracking."""
    import time

    logger.info(f"Processing item {item_id}")
    time.sleep(1)  # Simulate work

    return {
        'item_id': item_id,
        'status': 'processed'
    }
```

## Resource Pool Management

### Resource Pool Task

```python
from contextlib import contextmanager
import queue


class ResourcePoolTask(Task):
    """
    Task with connection pooling.

    Manages a pool of reusable resources (connections, clients, etc.).
    """
    _pool = None
    _pool_size = 10

    def __init__(self):
        """Initialize resource pool."""
        super().__init__()
        if self._pool is None:
            self._pool = queue.Queue(maxsize=self._pool_size)
            logger.info(f"Initialized resource pool (size={self._pool_size})")

    @contextmanager
    def acquire_resource(self):
        """Context manager for resource acquisition."""
        try:
            # Try to get from pool
            resource = self._pool.get(block=False)
            logger.info("Acquired resource from pool")
        except queue.Empty:
            # Pool empty, create new resource
            resource = self._create_resource()
            logger.info("Created new resource")

        try:
            yield resource
        finally:
            try:
                # Return to pool if not full
                self._pool.put(resource, block=False)
                logger.info("Returned resource to pool")
            except queue.Full:
                # Pool full, clean up resource
                self._cleanup_resource(resource)
                logger.info("Pool full, cleaned up resource")

    def _create_resource(self):
        """Create new resource (override in subclass)."""
        return {'id': time.time(), 'type': 'resource'}

    def _cleanup_resource(self, resource):
        """Clean up resource (override in subclass)."""
        logger.info(f"Cleaning up resource: {resource}")


@app.task(base=ResourcePoolTask, bind=True)
def task_with_pooled_resource(self, data: str) -> dict:
    """Task using pooled resource."""
    with self.acquire_resource() as resource:
        logger.info(f"Using resource {resource['id']} to process: {data}")

        # Your logic using the resource
        result = {
            'data': data,
            'resource_id': resource['id'],
            'status': 'processed'
        }

        return result
```

## Authentication and API Clients

### API Client Task

```python
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry


class APIClientTask(Task):
    """
    Task with configured HTTP client.

    Reuses session with connection pooling and retry logic.
    """
    _session = None

    @property
    def session(self):
        """Get or create HTTP session with retry logic."""
        if self._session is None:
            logger.info("Creating HTTP session")

            self._session = requests.Session()

            # Configure retry strategy
            retry_strategy = Retry(
                total=3,
                backoff_factor=1,
                status_forcelist=[429, 500, 502, 503, 504]
            )

            adapter = HTTPAdapter(
                max_retries=retry_strategy,
                pool_connections=10,
                pool_maxsize=20
            )

            self._session.mount("http://", adapter)
            self._session.mount("https://", adapter)

        return self._session

    def make_api_call(self, url: str, method: str = 'GET', **kwargs):
        """Make API call with session."""
        response = self.session.request(method, url, timeout=30, **kwargs)
        response.raise_for_status()
        return response.json()


@app.task(base=APIClientTask, bind=True)
def fetch_user_data(self, user_id: int):
    """Fetch user data using configured HTTP client."""
    url = f"https://api.example.com/users/{user_id}"

    data = self.make_api_call(url)

    return {
        'user_id': user_id,
        'data': data
    }


@app.task(base=APIClientTask, bind=True)
def update_user(self, user_id: int, updates: dict):
    """Update user using configured HTTP client."""
    url = f"https://api.example.com/users/{user_id}"

    data = self.make_api_call(url, method='PATCH', json=updates)

    return {
        'user_id': user_id,
        'updated': True,
        'data': data
    }
```

## Combining Multiple Patterns

### Full-Featured Task Class

```python
class ProductionTask(Task):
    """
    Production-ready task with all features.

    Features:
    - Database connection pooling
    - Metrics tracking
    - Error handling
    - Resource cleanup
    """
    _db = None
    _start_time = None

    @property
    def db(self):
        """Lazy database connection."""
        if self._db is None:
            from sqlalchemy import create_engine
            self._db = create_engine('postgresql://localhost/db')
        return self._db

    def before_start(self, task_id, args, kwargs):
        """Setup before task execution."""
        self._start_time = time.time()
        logger.info(
            f"[{task_id}] Starting {self.name} "
            f"with args={args}, kwargs={kwargs}"
        )

    def on_success(self, retval, task_id, args, kwargs):
        """Handle successful completion."""
        duration = time.time() - self._start_time
        logger.info(
            f"[{task_id}] Succeeded in {duration:.2f}s: {retval}"
        )
        self._send_metrics('success', duration)

    def on_failure(self, exc, task_id, args, kwargs, einfo):
        """Handle task failure."""
        duration = time.time() - self._start_time
        logger.error(
            f"[{task_id}] Failed after {duration:.2f}s: {exc}"
        )
        self._send_metrics('failure', duration, error=str(exc))

        # Reset database connection on connection errors
        if 'connection' in str(exc).lower():
            self._db = None

    def on_retry(self, exc, task_id, args, kwargs, einfo):
        """Handle task retry."""
        logger.warning(
            f"[{task_id}] Retrying due to: {exc}"
        )

    def after_return(self, status, retval, task_id, args, kwargs, einfo):
        """Cleanup after task completion."""
        logger.info(f"[{task_id}] Completed with status: {status}")

    def _send_metrics(self, status: str, duration: float, error: str = None):
        """Send metrics to monitoring system."""
        metrics = {
            'task': self.name,
            'status': status,
            'duration': duration
        }
        if error:
            metrics['error'] = error

        logger.info(f"Metrics: {json.dumps(metrics)}")


@app.task(base=ProductionTask, bind=True, autoretry_for=(Exception,), max_retries=3)
def production_task(self, data_id: int):
    """Production-ready task with all features."""
    db = self.db

    # Your logic here
    logger.info(f"Processing data {data_id}")

    return {
        'data_id': data_id,
        'status': 'processed'
    }
```

## Best Practices

### 1. Initialize Once Per Worker

```python
# ✅ GOOD - Initialize in __init__
class MyTask(Task):
    def __init__(self):
        super().__init__()
        self._connection = create_connection()

# ❌ BAD - Initialize per task execution
class MyTask(Task):
    def run(self, *args, **kwargs):
        self._connection = create_connection()
```

### 2. Clean Up Resources

```python
class CleanupTask(Task):
    def on_failure(self, exc, task_id, args, kwargs, einfo):
        """Clean up on failure."""
        if hasattr(self, '_resource'):
            self._resource.close()

    def after_return(self, status, retval, task_id, args, kwargs, einfo):
        """Always clean up."""
        if hasattr(self, '_temp_file'):
            os.remove(self._temp_file)
```

### 3. Use Properties for Lazy Loading

```python
class LazyTask(Task):
    _client = None

    @property
    def client(self):
        """Create client only when needed."""
        if self._client is None:
            self._client = create_expensive_client()
        return self._client
```

### 4. Combine with Task Decorators

```python
@app.task(
    base=CustomTask,
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=True,
    max_retries=3,
    rate_limit='10/m'
)
def advanced_task(self, item_id: int):
    """Task with custom class and decorators."""
    pass
```

## Summary

Custom task classes enable:
- **Resource pooling**: Reuse connections across tasks
- **Lifecycle hooks**: Execute code at specific points
- **Shared behavior**: Common logic in one place
- **Metrics**: Automatic performance tracking
- **Error handling**: Centralized error management

Key lifecycle hooks:
- `before_start`: Pre-execution setup
- `on_success`: Handle success
- `on_failure`: Handle errors
- `on_retry`: Handle retries
- `after_return`: Post-execution cleanup
