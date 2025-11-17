"""
Celery Beat Interval Schedule Configuration

Provides interval-based periodic task scheduling patterns.
Use for fixed-frequency task execution (every N seconds/minutes/hours).

Security: No hardcoded credentials - all configuration from environment.
"""

from celery import Celery
from celery.schedules import schedule
from datetime import timedelta
import os

# Initialize Celery app
app = Celery('tasks')

# Load configuration from environment
app.config_from_object('celeryconfig')

# Alternative: Direct configuration
app.conf.update(
    broker_url=os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0'),
    result_backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0'),
    timezone='UTC',
)

# Interval Schedule Configuration
app.conf.beat_schedule = {
    # Simple interval (seconds as float)
    'every-30-seconds': {
        'task': 'tasks.quick_check',
        'schedule': 30.0,
        'args': (),
    },

    # Using timedelta for clarity
    'every-minute': {
        'task': 'tasks.minute_task',
        'schedule': timedelta(seconds=60),
        'args': (),
    },

    # Hourly task
    'every-hour': {
        'task': 'tasks.hourly_cleanup',
        'schedule': timedelta(hours=1),
        'args': (),
    },

    # Every 5 minutes
    'every-5-minutes': {
        'task': 'tasks.status_check',
        'schedule': timedelta(minutes=5),
        'args': (),
    },

    # Daily interval
    'every-24-hours': {
        'task': 'tasks.daily_backup',
        'schedule': timedelta(days=1),
        'args': (),
    },

    # Complex interval
    'every-90-minutes': {
        'task': 'tasks.periodic_sync',
        'schedule': timedelta(minutes=90),
        'args': (),
    },

    # Very frequent task (5 seconds)
    'rapid-polling': {
        'task': 'tasks.poll_external_api',
        'schedule': 5.0,
        'args': (),
    },
}

# Advanced Interval Patterns with schedule() object
app.conf.beat_schedule.update({
    # Relative schedule (runs on rounded intervals)
    'relative-hour': {
        'task': 'tasks.hourly_report',
        'schedule': schedule(run_every=timedelta(hours=1), relative=True),
        'args': (),
    },

    # Non-relative schedule (exact intervals from start)
    'exact-interval': {
        'task': 'tasks.precise_timing',
        'schedule': schedule(run_every=timedelta(minutes=30), relative=False),
        'args': (),
    },
})

# Task Configuration with Options
app.conf.beat_schedule.update({
    # Task with arguments
    'task-with-args': {
        'task': 'tasks.process_batch',
        'schedule': timedelta(minutes=10),
        'args': (100,),  # batch_size
        'kwargs': {'priority': 'normal'},
    },

    # Task with expiration
    'task-with-expiry': {
        'task': 'tasks.time_sensitive',
        'schedule': timedelta(seconds=30),
        'options': {
            'expires': 25,  # Must execute within 25 seconds
            'queue': 'high-priority',
        }
    },

    # Task with retry policy
    'task-with-retry': {
        'task': 'tasks.unreliable_operation',
        'schedule': timedelta(minutes=5),
        'options': {
            'max_retries': 3,
            'retry_backoff': True,
        }
    },
})


# Interval Best Practices
"""
1. Relative vs Absolute Timing:
   - relative=True: Rounds to nearest time unit (e.g., on the hour)
   - relative=False: Exact intervals from beat startup

2. Preventing Task Overlap:
   - Use task_acks_late=True
   - Implement locking mechanism (Redis/database)
   - Set expires option shorter than schedule interval

3. Performance Considerations:
   - Avoid very frequent tasks (< 5 seconds) when possible
   - Use rate limiting for external API calls
   - Monitor queue depth and worker capacity
"""


# Dynamic Interval Registration
@app.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    """
    Register periodic tasks programmatically.
    Useful for environment-based configuration or plugin systems.
    """

    # Simple interval task
    sender.add_periodic_task(30.0, check_status.s(), name='status-check')

    # Task with arguments
    sender.add_periodic_task(
        timedelta(minutes=5),
        cleanup_old_data.s(days=30),
        name='cleanup-old-data'
    )

    # Conditional task registration
    if os.getenv('ENABLE_MONITORING') == 'true':
        sender.add_periodic_task(
            60.0,
            monitor_system.s(),
            name='system-monitor'
        )

    # Task with expiration
    sender.add_periodic_task(
        timedelta(seconds=10),
        time_critical_task.s(),
        name='time-critical',
        expires=5  # Must run within 5 seconds
    )


# Example Tasks
@app.task
def check_status():
    """Example status check task"""
    print("Checking system status...")
    return "OK"

@app.task
def cleanup_old_data(days):
    """Example cleanup task with parameters"""
    print(f"Cleaning up data older than {days} days...")
    return f"Cleaned data older than {days} days"

@app.task
def monitor_system():
    """Example monitoring task"""
    print("Monitoring system metrics...")
    return "Monitoring complete"

@app.task
def time_critical_task():
    """Example time-sensitive task"""
    print("Executing time-critical operation...")
    return "Complete"


# Interval Scheduling Patterns
"""
Common Use Cases:

1. Health Checks (5-30 seconds)
   - System availability monitoring
   - Service health checks
   - Queue depth monitoring

2. Data Synchronization (1-15 minutes)
   - External API polling
   - Database sync operations
   - Cache refresh

3. Cleanup Operations (1-24 hours)
   - Temporary file cleanup
   - Old data archival
   - Log rotation

4. Batch Processing (15 minutes - 6 hours)
   - Report generation
   - Data aggregation
   - Email dispatch

5. Maintenance Tasks (daily)
   - Database optimization
   - Backup operations
   - System updates
"""


# Testing Intervals
"""
Development Testing:
1. Use shorter intervals for testing (5-10 seconds)
2. Run beat with debug logging:
   celery -A tasks beat --loglevel=debug

3. Monitor task execution:
   celery -A tasks flower

4. Check beat schedule registration:
   celery -A tasks beat inspect scheduled

Production Deployment:
1. Run beat as separate process (not embedded in worker)
2. Use persistent beat schedule database
3. Monitor beat scheduler uptime
4. Set up alerting for schedule failures
"""


# Task Locking Example (Preventing Overlap)
"""
Using Redis for distributed locking:

from redis import Redis
from contextlib import contextmanager

redis_client = Redis.from_url(os.getenv('REDIS_URL'))

@contextmanager
def task_lock(lock_name, timeout=300):
    lock = redis_client.lock(lock_name, timeout=timeout)
    acquired = lock.acquire(blocking=False)
    try:
        if acquired:
            yield True
        else:
            yield False
    finally:
        if acquired:
            lock.release()

@app.task
def exclusive_task():
    with task_lock('exclusive_task_lock') as locked:
        if locked:
            # Task logic here
            print("Executing exclusive task...")
        else:
            print("Task already running, skipping...")
"""


if __name__ == '__main__':
    # Start Celery Beat scheduler
    # In production, run as separate process:
    #   celery -A tasks beat --loglevel=info

    from celery.bin import beat
    beat.beat(app=app).run()
