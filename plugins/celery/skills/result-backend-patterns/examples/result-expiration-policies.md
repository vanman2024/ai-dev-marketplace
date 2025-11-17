# Result Expiration Policies and Cleanup Strategies

Complete guide for managing result expiration, implementing cleanup strategies, and maintaining optimal backend performance.

## Understanding Result Expiration

Result expiration is critical for:
- **Preventing unbounded storage growth**
- **Maintaining backend performance**
- **Reducing memory/disk usage**
- **Automating cleanup operations**

## Expiration Strategy Matrix

| Use Case | Retention Period | Strategy | Cleanup Method |
|----------|-----------------|----------|----------------|
| Real-time dashboards | 5-30 minutes | Short TTL | Auto-expire (Redis) |
| API responses | 1-6 hours | Medium TTL | Auto-expire |
| Background jobs | 24 hours | Standard TTL | Celery beat cleanup |
| Audit logs | 7-30 days | Long TTL | Manual archival |
| Compliance data | 90+ days | Database | External archival |
| Critical records | Permanent | Database | No expiration |

## Expiration Patterns

### Pattern 1: Global Expiration (Simplest)

**When to use:**
- All tasks have similar retention needs
- Simple setup required
- Most common use case

**Configuration:**
```python
from celery import Celery

app = Celery('myapp')

app.conf.update(
    # All results expire after 24 hours
    result_expires=86400,
)

@app.task
def standard_task(data):
    """Uses global 24-hour expiration"""
    return {'processed': data}
```

**Pros:**
- Simple configuration
- Consistent behavior
- Easy to understand

**Cons:**
- No flexibility for different task types
- May waste storage for short-lived results
- May expire critical results too soon

### Pattern 2: Per-Task Expiration (Flexible)

**When to use:**
- Different tasks have different retention needs
- Fine-grained control required
- Mix of short and long-lived results

**Configuration:**
```python
from celery import Celery
from datetime import timedelta

app = Celery('myapp')

# Global default
app.conf.update(
    result_expires=86400,  # 24 hours default
)

@app.task(expires=300)  # 5 minutes
def realtime_task(data):
    """Short-lived result for dashboard"""
    return {'current_value': data}

@app.task(expires=3600)  # 1 hour
def api_cache_task(query):
    """Medium-lived cached API response"""
    return {'cached_result': query}

@app.task(expires=7 * 86400)  # 7 days
def report_task(report_data):
    """Long-lived report for compliance"""
    return {'report': report_data}

@app.task(expires=None)  # Never expires
def critical_task(audit_data):
    """Critical data, never expires automatically"""
    return {'audit_log': audit_data}

# Using timedelta for clarity
@app.task(expires=timedelta(hours=2))
def two_hour_task(data):
    """Expires after 2 hours"""
    return data
```

**Pros:**
- Optimal storage usage
- Flexible per-task control
- Can mix retention policies

**Cons:**
- More complex configuration
- Must remember to set expiration
- Harder to audit expiration policies

### Pattern 3: Dynamic Expiration (Advanced)

**When to use:**
- Expiration depends on result content
- Business logic determines retention
- Complex compliance requirements

**Configuration:**
```python
from celery import Celery
from datetime import timedelta

app = Celery('myapp')

@app.task(bind=True)
def smart_expiration_task(self, data):
    """Dynamically set expiration based on result"""

    # Process data
    result = process_data(data)

    # Determine expiration based on result
    if result['priority'] == 'critical':
        # Critical results kept for 30 days
        expiration = timedelta(days=30)
    elif result['size'] > 1000000:  # > 1MB
        # Large results expire quickly
        expiration = timedelta(hours=1)
    elif result['type'] == 'temporary':
        # Temporary results expire in 5 minutes
        expiration = timedelta(minutes=5)
    else:
        # Standard expiration
        expiration = timedelta(days=1)

    # Store with custom expiration
    # Note: This requires custom backend manipulation
    backend = self.app.backend
    backend.store_result(
        self.request.id,
        result,
        'SUCCESS',
        expires=expiration
    )

    return result

def process_data(data):
    """Business logic to process data"""
    return {
        'processed': data,
        'priority': 'critical' if 'important' in data else 'normal',
        'size': len(str(data)),
        'type': 'temporary' if 'temp' in data else 'permanent'
    }
```

**Pros:**
- Maximum flexibility
- Business logic integration
- Optimal storage efficiency

**Cons:**
- Complex implementation
- Harder to debug
- Requires backend knowledge

### Pattern 4: No Results (Most Efficient)

**When to use:**
- Results not needed
- Fire-and-forget tasks
- Logging, notifications, cleanup

**Configuration:**
```python
from celery import Celery

app = Celery('myapp')

# Global setting to disable all results
app.conf.update(
    task_ignore_result=True,
)

# Per-task override
@app.task(ignore_result=True)
def notification_task(email, message):
    """Send notification, no result needed"""
    send_email(email, message)
    # No return value stored

@app.task(ignore_result=True)
def cleanup_task(directory):
    """Cleanup old files, no result needed"""
    clean_directory(directory)

@app.task(ignore_result=False)  # Override global setting
def important_task(data):
    """This task needs results despite global ignore_result"""
    return {'status': 'completed', 'data': data}
```

**Pros:**
- Zero storage overhead
- Best performance
- Simplest cleanup

**Cons:**
- Cannot retrieve results
- Cannot check task status
- No retry visibility

## Cleanup Strategies

### Strategy 1: Automatic Cleanup with Celery Beat

**Best for: All production systems**

**Setup:**
```python
from celery import Celery
from celery.schedules import crontab

app = Celery('myapp')

app.conf.update(
    # Enable automatic cleanup
    beat_schedule={
        # Standard cleanup at 4 AM daily
        'cleanup-results': {
            'task': 'celery.backend_cleanup',
            'schedule': crontab(hour=4, minute=0),
            'options': {
                'expires': 3600,  # Cleanup task itself expires
            }
        },

        # Aggressive cleanup for high-volume systems
        'frequent-cleanup': {
            'task': 'celery.backend_cleanup',
            'schedule': crontab(minute='*/15'),  # Every 15 minutes
        },
    },

    # Timezone for beat schedule
    timezone='UTC',
    enable_utc=True,
)
```

**Start Celery Beat:**
```bash
# Start beat scheduler
celery -A myapp beat --loglevel=info

# Or combine with worker
celery -A myapp worker --beat --loglevel=info
```

**Monitor Cleanup:**
```python
from celery import Celery

app = Celery('myapp')

@app.task
def monitor_cleanup():
    """Monitor cleanup task execution"""
    from celery.result import AsyncResult

    # Check last cleanup execution
    inspect = app.control.inspect()
    scheduled = inspect.scheduled()

    for worker, tasks in scheduled.items():
        for task in tasks:
            if task['name'] == 'celery.backend_cleanup':
                print(f"Cleanup scheduled on {worker}: {task}")
```

### Strategy 2: Manual Cleanup Script

**Best for: On-demand cleanup, custom logic**

**Cleanup Script (cleanup_results.py):**
```python
#!/usr/bin/env python3
"""
Manual result cleanup script
Run with: python cleanup_results.py [--days 7] [--dry-run]
"""

import argparse
from datetime import datetime, timedelta
from celery import Celery

app = Celery('myapp')

def cleanup_old_results(days=7, dry_run=False):
    """Cleanup results older than N days"""

    cutoff = datetime.utcnow() - timedelta(days=days)
    print(f"Cleaning up results older than {cutoff}")

    backend = app.backend

    if hasattr(backend, 'cleanup'):
        # Backend supports cleanup
        if not dry_run:
            backend.cleanup()
            print("✓ Backend cleanup completed")
        else:
            print("✓ Dry run: would clean backend")
    else:
        print("✗ Backend doesn't support automatic cleanup")

    # Database-specific cleanup
    if 'db+' in app.conf.result_backend:
        cleanup_database(cutoff, dry_run)
    elif 'redis://' in app.conf.result_backend:
        cleanup_redis(cutoff, dry_run)

def cleanup_database(cutoff, dry_run=False):
    """Cleanup database backend"""
    from celery.backends.database import SessionManager, models

    session = SessionManager()
    engine = session.get_engine(app.backend.url)

    with session(engine=engine) as sess:
        # Count old results
        count = sess.query(models.Task).filter(
            models.Task.date_done < cutoff
        ).count()

        print(f"Found {count} expired results")

        if not dry_run and count > 0:
            # Delete old results
            deleted = sess.query(models.Task).filter(
                models.Task.date_done < cutoff
            ).delete()

            sess.commit()
            print(f"✓ Deleted {deleted} expired results")
        else:
            print(f"✓ Dry run: would delete {count} results")

def cleanup_redis(cutoff, dry_run=False):
    """Cleanup Redis backend"""
    import redis

    r = redis.from_url(app.conf.result_backend)

    # Find celery result keys
    keys = r.keys('celery-task-meta-*')
    expired = 0

    for key in keys:
        ttl = r.ttl(key)

        if ttl == -1:  # No expiration set
            if not dry_run:
                r.delete(key)
            expired += 1
        elif ttl == -2:  # Key doesn't exist
            expired += 1

    if not dry_run:
        print(f"✓ Deleted {expired} expired results")
    else:
        print(f"✓ Dry run: would delete {expired} results")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Cleanup old Celery results')
    parser.add_argument('--days', type=int, default=7,
                        help='Delete results older than N days')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show what would be deleted without deleting')

    args = parser.parse_args()

    cleanup_old_results(args.days, args.dry_run)
```

**Usage:**
```bash
# Dry run first
python cleanup_results.py --days 7 --dry-run

# Actually cleanup
python cleanup_results.py --days 7

# Cleanup very old results
python cleanup_results.py --days 30
```

### Strategy 3: Archival Before Cleanup

**Best for: Audit requirements, compliance**

**Archival Script (archive_results.py):**
```python
#!/usr/bin/env python3
"""
Archive old results before cleanup
"""

import json
from datetime import datetime, timedelta
from celery import Celery
from celery.backends.database import SessionManager, models

app = Celery('myapp')

def archive_old_results(days=30, archive_file='results_archive.jsonl'):
    """Archive results to file before deletion"""

    cutoff = datetime.utcnow() - timedelta(days=days)
    print(f"Archiving results older than {cutoff}")

    session = SessionManager()
    engine = session.get_engine(app.backend.url)

    archived_count = 0

    with session(engine=engine) as sess:
        # Query old results
        old_tasks = sess.query(models.Task).filter(
            models.Task.date_done < cutoff
        ).all()

        # Archive to JSONL file
        with open(archive_file, 'a') as f:
            for task in old_tasks:
                archive_entry = {
                    'task_id': task.task_id,
                    'name': task.name,
                    'status': task.status,
                    'result': str(task.result),
                    'date_done': task.date_done.isoformat(),
                    'worker': task.worker,
                    'retries': task.retries,
                }

                # Write as JSON line
                f.write(json.dumps(archive_entry) + '\n')
                archived_count += 1

        print(f"✓ Archived {archived_count} results to {archive_file}")

        # Now delete from database
        if archived_count > 0:
            deleted = sess.query(models.Task).filter(
                models.Task.date_done < cutoff
            ).delete()

            sess.commit()
            print(f"✓ Deleted {deleted} archived results from database")

if __name__ == '__main__':
    archive_old_results(days=30)
```

**Restore from Archive:**
```python
def restore_from_archive(archive_file='results_archive.jsonl', task_id=None):
    """Restore specific result from archive"""
    import json

    with open(archive_file, 'r') as f:
        for line in f:
            entry = json.loads(line)

            if task_id is None or entry['task_id'] == task_id:
                print(f"Task {entry['task_id']}:")
                print(f"  Status: {entry['status']}")
                print(f"  Result: {entry['result']}")
                print(f"  Date: {entry['date_done']}")

                if task_id:
                    return entry

    if task_id:
        print(f"Task {task_id} not found in archive")
```

### Strategy 4: Tiered Retention

**Best for: Complex compliance requirements**

```python
from celery import Celery
from celery.schedules import crontab

app = Celery('myapp')

app.conf.update(
    beat_schedule={
        # Tier 1: Cleanup temporary results (daily)
        'cleanup-temporary': {
            'task': 'cleanup_tier1',
            'schedule': crontab(hour=2, minute=0),
        },

        # Tier 2: Cleanup standard results (weekly)
        'cleanup-standard': {
            'task': 'cleanup_tier2',
            'schedule': crontab(hour=3, minute=0, day_of_week=0),
        },

        # Tier 3: Archive old audit logs (monthly)
        'archive-audit-logs': {
            'task': 'archive_tier3',
            'schedule': crontab(hour=4, minute=0, day_of_month=1),
        },
    },
)

@app.task
def cleanup_tier1():
    """Cleanup results < 1 day old"""
    from datetime import timedelta
    cleanup_by_age(timedelta(days=1))

@app.task
def cleanup_tier2():
    """Cleanup results < 7 days old"""
    from datetime import timedelta
    cleanup_by_age(timedelta(days=7))

@app.task
def archive_tier3():
    """Archive results < 30 days old"""
    from datetime import timedelta
    archive_old_results(days=30)
```

## Monitoring Expiration

### Monitor Result Count

```python
def monitor_result_count():
    """Monitor result backend storage"""

    backend_url = app.conf.result_backend

    if 'redis://' in backend_url:
        # Redis monitoring
        import redis
        r = redis.from_url(backend_url)

        keys = r.keys('celery-task-meta-*')
        print(f"Active results in Redis: {len(keys)}")

        # Memory usage
        info = r.info('memory')
        print(f"Memory used: {info['used_memory_human']}")

    elif 'db+' in backend_url:
        # Database monitoring
        from celery.backends.database import SessionManager, models

        session = SessionManager()
        engine = session.get_engine(app.backend.url)

        with session(engine=engine) as sess:
            total = sess.query(models.Task).count()
            pending = sess.query(models.Task).filter(
                models.Task.status == 'PENDING'
            ).count()
            success = sess.query(models.Task).filter(
                models.Task.status == 'SUCCESS'
            ).count()

            print(f"Total results: {total}")
            print(f"  Pending: {pending}")
            print(f"  Success: {success}")
```

### Alert on Storage Growth

```python
def check_storage_growth(threshold=10000):
    """Alert if result count exceeds threshold"""

    backend = app.backend

    if 'redis://' in app.conf.result_backend:
        import redis
        r = redis.from_url(app.conf.result_backend)
        count = len(r.keys('celery-task-meta-*'))

    elif 'db+' in app.conf.result_backend:
        from celery.backends.database import SessionManager, models

        session = SessionManager()
        engine = session.get_engine(app.backend.url)

        with session(engine=engine) as sess:
            count = sess.query(models.Task).count()

    if count > threshold:
        print(f"⚠ WARNING: Result count ({count}) exceeds threshold ({threshold})")
        print("  Consider:")
        print("  - Reducing result_expires")
        print("  - Running cleanup more frequently")
        print("  - Using ignore_result for more tasks")
        return False

    print(f"✓ Result count ({count}) is within threshold")
    return True
```

## Best Practices

### 1. Choose Appropriate Retention

```python
# Real-time data
result_expires=300  # 5 minutes

# Cached API responses
result_expires=3600  # 1 hour

# Standard background jobs
result_expires=86400  # 24 hours

# Audit logs
result_expires=30 * 86400  # 30 days

# Compliance data
result_expires=None  # Manual archival
```

### 2. Use ignore_result When Possible

```python
@app.task(ignore_result=True)
def fire_and_forget():
    """Most efficient - no storage"""
    pass
```

### 3. Enable Automatic Cleanup

```python
# Always run celery beat in production
beat_schedule={
    'cleanup-results': {
        'task': 'celery.backend_cleanup',
        'schedule': crontab(hour=4, minute=0),
    }
}
```

### 4. Monitor Storage Growth

```bash
# Add to cron or monitoring system
0 * * * * python monitor_results.py
```

### 5. Test Expiration Policies

```python
# Test expiration in development
@app.task(expires=10)  # 10 seconds for testing
def test_task():
    return "test"

result = test_task.delay()
time.sleep(15)
try:
    result.get()  # Should fail
except Exception as e:
    print(f"✓ Expiration working: {e}")
```

## Resources

- [Celery Result Expiration](https://docs.celeryq.dev/en/stable/userguide/configuration.html#std-setting-result_expires)
- [Backend Cleanup Task](https://docs.celeryq.dev/en/stable/userguide/periodic-tasks.html)

---

**Last Updated:** 2025-11-16
**Celery Version:** 5.0+
