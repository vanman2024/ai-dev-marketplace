"""
Celery Result Expiration and Cleanup Patterns
==============================================

Configure result expiration policies and automatic cleanup to prevent
unbounded storage growth and maintain backend performance.

SECURITY: Ensure expired results don't contain sensitive data that
          could be accessed before cleanup runs.
"""

import os
from celery import Celery
from celery.schedules import crontab
from datetime import timedelta

# Security: Load backend configuration from environment
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
result_backend = f'redis://:{REDIS_PASSWORD}@{REDIS_HOST}:6379/0'

app = Celery('myapp', backend=result_backend)

# ========================================
# Strategy 1: Global Expiration Policy
# ========================================

app.conf.update(
    # Default expiration for all tasks (24 hours)
    result_expires=86400,  # seconds

    # Common expiration values:
    # result_expires=300,        # 5 minutes (short-lived)
    # result_expires=3600,       # 1 hour
    # result_expires=86400,      # 1 day (default)
    # result_expires=7 * 86400,  # 1 week
    # result_expires=None,       # Never expire (requires manual cleanup)
)

# ========================================
# Strategy 2: Per-Task Expiration
# ========================================

@app.task(expires=300)  # Expire after 5 minutes
def short_lived_task(data):
    """Results only needed briefly"""
    return {'processed': data}

@app.task(expires=7 * 86400)  # Expire after 1 week
def audit_task(data):
    """Results needed for compliance, kept longer"""
    return {'audit_log': data, 'timestamp': str(data)}

@app.task(expires=None)  # Never expire
def permanent_record_task(data):
    """Critical results, never expire automatically"""
    return {'permanent_record': data}

@app.task(ignore_result=True)
def no_result_task(data):
    """Results not needed at all - most efficient"""
    print(f"Processing {data}")
    # No result stored

# ========================================
# Strategy 3: Automatic Cleanup with Celery Beat
# ========================================

app.conf.update(
    # Enable Celery Beat for periodic tasks
    beat_schedule={
        # Built-in cleanup task (runs daily at 4 AM)
        'cleanup-expired-results': {
            'task': 'celery.backend_cleanup',
            'schedule': crontab(hour=4, minute=0),
            'options': {
                'expires': 3600,  # Cleanup task expires after 1 hour
            }
        },

        # Custom cleanup with different schedule
        'cleanup-old-results-frequently': {
            'task': 'celery.backend_cleanup',
            'schedule': crontab(minute=0),  # Every hour
        },

        # Aggressive cleanup for high-volume systems
        'aggressive-cleanup': {
            'task': 'celery.backend_cleanup',
            'schedule': crontab(minute='*/15'),  # Every 15 minutes
        },
    },

    # Timezone for beat schedule
    timezone='UTC',
    enable_utc=True,
)

# ========================================
# Strategy 4: Manual Cleanup
# ========================================

def manual_cleanup():
    """Manually trigger result cleanup"""
    from celery.backends.base import Backend

    backend = app.backend
    if hasattr(backend, 'cleanup'):
        # Call backend's cleanup method
        backend.cleanup()
        print("Backend cleanup completed")
    else:
        print("Backend doesn't support cleanup")

# ========================================
# Strategy 5: Expiration with Timedelta
# ========================================

app.conf.update(
    # Use timedelta for clarity
    result_expires=timedelta(days=1, hours=12),  # 1.5 days
)

@app.task(expires=timedelta(minutes=30))
def thirty_minute_task(data):
    """Expires in 30 minutes using timedelta"""
    return data

# ========================================
# Strategy 6: Conditional Expiration
# ========================================

@app.task(bind=True)
def conditional_expiration_task(self, data, keep_forever=False):
    """Dynamically set expiration based on result importance"""
    result = {'processed': data}

    if keep_forever:
        # Set result to never expire for this specific execution
        # Note: This requires manual backend manipulation
        pass
    else:
        # Use default expiration
        pass

    return result

# ========================================
# Strategy 7: Redis-Specific Expiration
# ========================================

# Redis automatically handles expiration using TTL
# No additional cleanup needed beyond setting result_expires

app.conf.update(
    result_expires=3600,  # Redis sets TTL to 1 hour
    # Redis will automatically delete expired keys
)

# ========================================
# Strategy 8: Database-Specific Cleanup
# ========================================

def database_cleanup_advanced():
    """Advanced cleanup for database backends"""
    from celery.backends.database import SessionManager
    from celery.backends.database.models import Task
    from datetime import datetime, timedelta

    session = SessionManager()
    engine = session.get_engine(app.backend.url)
    cutoff = datetime.utcnow() - timedelta(days=7)

    with session(engine=engine) as sess:
        # Delete old completed tasks
        deleted = sess.query(Task).filter(
            Task.date_done < cutoff,
            Task.status == 'SUCCESS'
        ).delete()

        sess.commit()
        print(f"Deleted {deleted} expired results")

def archive_before_cleanup():
    """Archive results before deleting"""
    from celery.backends.database import SessionManager
    from celery.backends.database.models import Task
    from datetime import datetime, timedelta
    import json

    session = SessionManager()
    engine = session.get_engine(app.backend.url)
    cutoff = datetime.utcnow() - timedelta(days=30)

    with session(engine=engine) as sess:
        old_tasks = sess.query(Task).filter(
            Task.date_done < cutoff
        ).all()

        # Archive to file before cleanup
        archive_data = [
            {
                'task_id': task.task_id,
                'status': task.status,
                'result': task.result,
                'date_done': task.date_done.isoformat()
            }
            for task in old_tasks
        ]

        # Save archive
        with open('results_archive.json', 'w') as f:
            json.dump(archive_data, f)

        # Now cleanup
        for task in old_tasks:
            sess.delete(task)

        sess.commit()
        print(f"Archived and deleted {len(old_tasks)} results")

# ========================================
# Strategy 9: Forget Results Programmatically
# ========================================

def forget_results_pattern():
    """Explicitly forget results when done"""
    # Send task
    result = short_lived_task.delay("data")

    # Get result
    value = result.get(timeout=10)
    print(f"Got result: {value}")

    # Explicitly forget (delete from backend)
    result.forget()
    print("Result deleted from backend")

# ========================================
# Strategy 10: Monitoring Expiration
# ========================================

def monitor_result_retention():
    """Monitor how many results are stored"""
    from celery.backends.database import SessionManager
    from celery.backends.database.models import Task

    session = SessionManager()
    engine = session.get_engine(app.backend.url)

    with session(engine=engine) as sess:
        total = sess.query(Task).count()
        pending = sess.query(Task).filter(Task.status == 'PENDING').count()
        success = sess.query(Task).filter(Task.status == 'SUCCESS').count()
        failure = sess.query(Task).filter(Task.status == 'FAILURE').count()

        print(f"Total results: {total}")
        print(f"Pending: {pending}")
        print(f"Success: {success}")
        print(f"Failure: {failure}")

# ========================================
# Best Practices
# ========================================

"""
1. Choose Appropriate Expiration Times:
   - Short-lived results (5-30 minutes): Real-time dashboards, status checks
   - Medium-lived results (1-24 hours): Most tasks, temporary data
   - Long-lived results (days-weeks): Audit logs, reports
   - Permanent results: Use database, not result backend

2. Use ignore_result=True When Possible:
   - Fastest option, no storage overhead
   - Ideal for fire-and-forget tasks
   - Notifications, logging, cleanup tasks

3. Enable Automatic Cleanup:
   - Run celery beat for automatic cleanup
   - Adjust schedule based on task volume
   - High volume = more frequent cleanup

4. Redis vs Database Expiration:
   - Redis: Automatic TTL-based cleanup (efficient)
   - Database: Requires celery.backend_cleanup task (manual)

5. Monitor Storage Growth:
   - Track result backend size
   - Alert on unbounded growth
   - Adjust expiration policies as needed

6. Forget Results Explicitly:
   - Call result.forget() after get()
   - Releases resources immediately
   - Prevents memory leaks

7. Archive Before Cleanup:
   - Save important results before expiration
   - Use external storage for long-term retention
   - Database backend allows SQL queries for archival

8. Per-Task Expiration:
   - Override global setting for specific tasks
   - Use expires parameter in @app.task decorator
   - More granular control

9. Security Considerations:
   - Expired results may still be accessible before cleanup
   - Don't store sensitive data in results if possible
   - Use encryption for sensitive result data

10. Performance Impact:
    - Aggressive expiration improves performance
    - Less backend storage = faster queries
    - Cleanup during off-peak hours
"""

if __name__ == '__main__':
    # Test expiration patterns
    print("Testing expiration patterns...")

    # Short-lived task
    result1 = short_lived_task.delay("test_data")
    print(f"Short-lived task: {result1.id}")

    # Audit task (longer retention)
    result2 = audit_task.delay("audit_data")
    print(f"Audit task: {result2.id}")

    # No result task (most efficient)
    no_result_task.delay("fire_and_forget")

    # Get and forget pattern
    value = result1.get(timeout=10)
    result1.forget()
    print(f"Got and forgot result: {value}")
