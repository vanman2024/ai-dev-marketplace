# Celery Beat Interval Schedule Examples

Comprehensive examples of interval-based periodic task scheduling with Celery Beat.

## Table of Contents

- [Basic Intervals](#basic-intervals)
- [Common Frequencies](#common-frequencies)
- [Relative vs Absolute Timing](#relative-vs-absolute-timing)
- [Task Configuration](#task-configuration)
- [Production Patterns](#production-patterns)
- [Performance Optimization](#performance-optimization)
- [Preventing Task Overlap](#preventing-task-overlap)

## Basic Intervals

### Seconds-Based Intervals

```python
from celery import Celery

app = Celery('tasks')

app.conf.beat_schedule = {
    # Every 30 seconds (float)
    'every-30-seconds': {
        'task': 'tasks.quick_check',
        'schedule': 30.0,
    },

    # Every 5 seconds
    'rapid-check': {
        'task': 'tasks.rapid_check',
        'schedule': 5.0,
    },

    # Every 2 minutes (120 seconds)
    'every-2-minutes': {
        'task': 'tasks.frequent_task',
        'schedule': 120.0,
    },
}
```

**Use cases:** Health checks, frequent monitoring, real-time updates

### Timedelta-Based Intervals (Recommended)

```python
from datetime import timedelta

app.conf.beat_schedule = {
    # Every minute
    'every-minute': {
        'task': 'tasks.minute_task',
        'schedule': timedelta(seconds=60),
    },

    # Every 5 minutes
    'every-5-minutes': {
        'task': 'tasks.status_check',
        'schedule': timedelta(minutes=5),
    },

    # Every hour
    'every-hour': {
        'task': 'tasks.hourly_cleanup',
        'schedule': timedelta(hours=1),
    },

    # Every 6 hours
    'every-6-hours': {
        'task': 'tasks.quarterly_sync',
        'schedule': timedelta(hours=6),
    },

    # Every day (24 hours)
    'daily-task': {
        'task': 'tasks.daily_backup',
        'schedule': timedelta(days=1),
    },
}
```

**Benefits:** More readable, self-documenting code

## Common Frequencies

### High-Frequency Tasks (< 1 minute)

```python
'every-5-seconds': {
    'task': 'tasks.critical_monitor',
    'schedule': 5.0,
    'options': {
        'expires': 3,  # Must execute within 3 seconds
    }
}

'every-10-seconds': {
    'task': 'tasks.system_check',
    'schedule': 10.0,
}

'every-30-seconds': {
    'task': 'tasks.queue_monitor',
    'schedule': 30.0,
}
```

**Use cases:**
- Critical system monitoring
- Queue depth checks
- Service availability checks
- Real-time metrics collection

**Warning:** Very frequent tasks can impact performance. Monitor carefully.

### Medium-Frequency Tasks (1-60 minutes)

```python
'every-minute': {
    'task': 'tasks.log_processor',
    'schedule': timedelta(minutes=1),
}

'every-5-minutes': {
    'task': 'tasks.cache_refresh',
    'schedule': timedelta(minutes=5),
}

'every-15-minutes': {
    'task': 'tasks.data_sync',
    'schedule': timedelta(minutes=15),
}

'every-30-minutes': {
    'task': 'tasks.report_generation',
    'schedule': timedelta(minutes=30),
}

'every-hour': {
    'task': 'tasks.cleanup_temp_files',
    'schedule': timedelta(hours=1),
}
```

**Use cases:**
- Data synchronization
- Cache updates
- Temporary file cleanup
- Regular batch processing

### Low-Frequency Tasks (> 1 hour)

```python
'every-2-hours': {
    'task': 'tasks.database_optimization',
    'schedule': timedelta(hours=2),
}

'every-6-hours': {
    'task': 'tasks.backup_incremental',
    'schedule': timedelta(hours=6),
}

'every-12-hours': {
    'task': 'tasks.external_api_sync',
    'schedule': timedelta(hours=12),
}

'daily': {
    'task': 'tasks.daily_report',
    'schedule': timedelta(days=1),
}
```

**Use cases:**
- Database maintenance
- Incremental backups
- Long-running aggregations
- Daily reports

## Relative vs Absolute Timing

### Relative Schedule (Default)

```python
from celery.schedules import schedule

# Runs on rounded intervals (e.g., on the hour for 1-hour interval)
'relative-hourly': {
    'task': 'tasks.hourly_report',
    'schedule': schedule(run_every=timedelta(hours=1), relative=True),
}
```

**Behavior:** First run happens at next hour boundary (e.g., if started at 10:15, runs at 11:00)

**Use when:** You want tasks aligned to clock boundaries

### Absolute Schedule

```python
# Runs exactly N seconds after beat starts
'absolute-hourly': {
    'task': 'tasks.precise_timing',
    'schedule': schedule(run_every=timedelta(hours=1), relative=False),
}
```

**Behavior:** First run happens exactly 1 hour after beat starts (e.g., if started at 10:15, runs at 11:15)

**Use when:** You want exact intervals regardless of clock time

### Comparison Example

```python
from celery.schedules import schedule

app.conf.beat_schedule = {
    # Beat starts at 10:15 AM

    # Relative: Runs at 11:00, 12:00, 13:00...
    'relative-task': {
        'task': 'tasks.on_the_hour',
        'schedule': schedule(run_every=timedelta(hours=1), relative=True),
    },

    # Absolute: Runs at 11:15, 12:15, 13:15...
    'absolute-task': {
        'task': 'tasks.exact_interval',
        'schedule': schedule(run_every=timedelta(hours=1), relative=False),
    },
}
```

## Task Configuration

### With Arguments

```python
'task-with-args': {
    'task': 'tasks.process_batch',
    'schedule': timedelta(minutes=10),
    'args': (100,),  # batch_size positional argument
}

'task-with-kwargs': {
    'task': 'tasks.sync_data',
    'schedule': timedelta(minutes=15),
    'kwargs': {
        'full_sync': False,
        'priority': 'high',
    }
}
```

### With Expiration

```python
'time-sensitive-task': {
    'task': 'tasks.process_realtime_data',
    'schedule': 30.0,
    'options': {
        'expires': 25,  # Must execute within 25 seconds
    }
}
```

**Purpose:** Prevent old task executions if worker is behind

### With Custom Queue

```python
'priority-task': {
    'task': 'tasks.urgent_processing',
    'schedule': timedelta(minutes=5),
    'options': {
        'queue': 'high-priority',
        'priority': 9,
    }
}

'background-task': {
    'task': 'tasks.low_priority_cleanup',
    'schedule': timedelta(hours=1),
    'options': {
        'queue': 'background',
        'priority': 1,
    }
}
```

### With Retry Policy

```python
'unreliable-external-call': {
    'task': 'tasks.call_external_api',
    'schedule': timedelta(minutes=15),
    'options': {
        'max_retries': 3,
        'retry_backoff': True,
        'retry_backoff_max': 600,  # 10 minutes max
        'retry_jitter': True,
    }
}
```

## Production Patterns

### Health Monitoring

```python
'service-health-check': {
    'task': 'tasks.check_all_services',
    'schedule': 30.0,
    'options': {
        'expires': 20,
        'queue': 'monitoring',
    }
}

'database-health': {
    'task': 'tasks.check_database_health',
    'schedule': timedelta(minutes=2),
}

'api-health': {
    'task': 'tasks.check_api_endpoints',
    'schedule': timedelta(minutes=1),
}
```

### Cache Management

```python
'cache-warm-up': {
    'task': 'tasks.warm_cache',
    'schedule': timedelta(minutes=30),
    'kwargs': {'cache_keys': ['popular_items', 'featured_content']}
}

'cache-invalidation': {
    'task': 'tasks.invalidate_stale_cache',
    'schedule': timedelta(hours=1),
}
```

### Data Synchronization

```python
'incremental-sync': {
    'task': 'tasks.sync_data',
    'schedule': timedelta(minutes=5),
    'kwargs': {'full_sync': False}
}

'full-sync': {
    'task': 'tasks.sync_data',
    'schedule': timedelta(hours=6),
    'kwargs': {'full_sync': True}
}
```

### Cleanup Operations

```python
'cleanup-temp-files': {
    'task': 'tasks.cleanup_temp',
    'schedule': timedelta(hours=1),
    'kwargs': {'max_age_hours': 24}
}

'cleanup-expired-sessions': {
    'task': 'tasks.cleanup_sessions',
    'schedule': timedelta(minutes=15),
}

'cleanup-old-logs': {
    'task': 'tasks.cleanup_logs',
    'schedule': timedelta(days=1),
    'kwargs': {'retention_days': 30}
}
```

### Queue Management

```python
'queue-length-monitor': {
    'task': 'tasks.monitor_queue_depth',
    'schedule': 30.0,
}

'dead-letter-processor': {
    'task': 'tasks.process_dead_letters',
    'schedule': timedelta(minutes=5),
}
```

## Performance Optimization

### Adjusting Intervals Based on Load

```python
import os

# More frequent in production, less in development
environment = os.getenv('ENVIRONMENT', 'development')

if environment == 'production':
    check_interval = timedelta(seconds=30)
else:
    check_interval = timedelta(minutes=5)

app.conf.beat_schedule = {
    'load-based-check': {
        'task': 'tasks.system_check',
        'schedule': check_interval,
    }
}
```

### Rate Limiting External APIs

```python
'api-call-rate-limited': {
    'task': 'tasks.call_rate_limited_api',
    'schedule': 2.0,  # Maximum 30 calls per minute (2 sec interval)
    'options': {
        'rate_limit': '30/m',  # Enforce rate limit
    }
}
```

### Batch Processing

```python
# Instead of processing every second
'inefficient': {
    'task': 'tasks.process_item',
    'schedule': 1.0,  # Every second, one item
}

# Better: Batch every 10 seconds
'efficient': {
    'task': 'tasks.process_batch',
    'schedule': 10.0,  # Every 10 seconds, multiple items
    'kwargs': {'batch_size': 10}
}
```

## Preventing Task Overlap

### Using Task Expiration

```python
'non-overlapping-task': {
    'task': 'tasks.long_running_task',
    'schedule': timedelta(minutes=5),
    'options': {
        'expires': 240,  # 4 minutes - less than interval
    }
}
```

### Redis-Based Locking

```python
from redis import Redis
from contextlib import contextmanager

redis_client = Redis.from_url(os.getenv('REDIS_URL'))

@contextmanager
def task_lock(lock_name, timeout=300):
    """Context manager for distributed task locking"""
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
    """Task that should never overlap"""
    with task_lock('exclusive_task_lock') as locked:
        if locked:
            # Task logic
            print("Executing exclusive task...")
        else:
            print("Task already running, skipping...")
```

### Database-Based Locking

```python
from django.db import transaction
from django.db.models import F

@app.task
def database_locked_task():
    """Task with database lock"""
    from myapp.models import TaskLock

    with transaction.atomic():
        # Try to acquire lock
        lock = TaskLock.objects.select_for_update(nowait=True).get(name='my_task')

        if lock.locked:
            print("Task already running")
            return

        lock.locked = True
        lock.save()

    try:
        # Task logic
        process_data()
    finally:
        lock.locked = False
        lock.save()
```

### Task State Checking

```python
@app.task(bind=True)
def self_monitoring_task(self):
    """Task that checks if previous execution completed"""
    from celery.result import AsyncResult

    # Get previous task ID from cache/database
    previous_task_id = get_previous_task_id()

    if previous_task_id:
        result = AsyncResult(previous_task_id)
        if not result.ready():
            print("Previous task still running")
            return

    # Store current task ID
    store_task_id(self.request.id)

    # Task logic
    process_data()
```

## Dynamic Interval Registration

### Environment-Based Configuration

```python
@app.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    """Register tasks based on environment"""

    interval = int(os.getenv('CHECK_INTERVAL', '30'))

    sender.add_periodic_task(
        float(interval),
        check_status.s(),
        name='dynamic-check'
    )
```

### Feature-Flag Controlled

```python
@app.on_after_configure.connect
def setup_feature_tasks(sender, **kwargs):
    """Register tasks based on feature flags"""

    if os.getenv('ENABLE_MONITORING') == 'true':
        sender.add_periodic_task(
            30.0,
            monitor_system.s(),
            name='system-monitor'
        )

    if os.getenv('ENABLE_ANALYTICS') == 'true':
        sender.add_periodic_task(
            timedelta(hours=1),
            generate_analytics.s(),
            name='analytics'
        )
```

## Testing Interval Schedules

### Short Intervals for Development

```python
import os

environment = os.getenv('ENVIRONMENT', 'development')

if environment == 'development':
    # Test with 10-second interval
    'dev-task': {
        'task': 'tasks.my_task',
        'schedule': 10.0,
    }
else:
    # Production uses 1-hour interval
    'prod-task': {
        'task': 'tasks.my_task',
        'schedule': timedelta(hours=1),
    }
```

### Verify Timing

```python
from datetime import datetime, timedelta

@app.task
def timed_task():
    """Task that logs execution time"""
    now = datetime.utcnow()
    print(f"Task executed at {now}")

    # Check against expected interval
    last_run = get_last_run_time()
    if last_run:
        actual_interval = (now - last_run).total_seconds()
        print(f"Actual interval: {actual_interval} seconds")

    store_last_run_time(now)
```

## Best Practices

1. **Use timedelta for readability** - More self-documenting than raw seconds
2. **Set appropriate intervals** - Balance freshness vs performance
3. **Implement task locking** - Prevent overlapping executions
4. **Use expiration** - Prevent stale task execution
5. **Monitor queue depth** - Ensure tasks complete before next execution
6. **Test with short intervals** - Speed up development testing
7. **Consider relative timing** - For clock-aligned execution
8. **Rate limit external calls** - Respect API limits
9. **Batch when possible** - Reduce overhead
10. **Log execution times** - Monitor task performance

## Troubleshooting

### Tasks Not Executing at Expected Interval

**Check beat logs:**
```bash
celery -A myapp beat --loglevel=debug
```

**Verify schedule:**
```python
from myapp import app
print(app.conf.beat_schedule)
```

### Tasks Piling Up in Queue

**Symptoms:** Queue depth grows, tasks delayed

**Solutions:**
- Increase worker count
- Reduce task frequency
- Optimize task execution time
- Implement task locking

### Inconsistent Execution Times

**Check for:**
- Worker resource constraints
- Database connection issues
- Network latency
- Task complexity variations

## Security Note

Never hardcode credentials:

```python
import os

app.conf.update(
    broker_url=os.getenv('CELERY_BROKER_URL'),
    result_backend=os.getenv('CELERY_RESULT_BACKEND'),
)
```
