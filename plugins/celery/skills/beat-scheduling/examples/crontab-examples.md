# Celery Beat Crontab Schedule Examples

Comprehensive examples of crontab-based periodic task scheduling patterns with Celery Beat.

## Table of Contents

- [Basic Patterns](#basic-patterns)
- [Business Hours Scheduling](#business-hours-scheduling)
- [Complex Patterns](#complex-patterns)
- [Multi-Timezone Scheduling](#multi-timezone-scheduling)
- [Production Use Cases](#production-use-cases)
- [Troubleshooting](#troubleshooting)

## Basic Patterns

### Every Minute

```python
from celery.schedules import crontab

app.conf.beat_schedule = {
    'every-minute': {
        'task': 'tasks.quick_check',
        'schedule': crontab(),  # Every minute
    }
}
```

**Use case:** Frequent monitoring, health checks

### Hourly on the Hour

```python
'every-hour': {
    'task': 'tasks.hourly_sync',
    'schedule': crontab(minute=0),  # XX:00
}
```

**Use case:** Regular data synchronization, cache updates

### Daily at Specific Time

```python
'daily-midnight': {
    'task': 'tasks.daily_report',
    'schedule': crontab(hour=0, minute=0),  # 00:00 daily
}

'daily-3am': {
    'task': 'tasks.maintenance',
    'schedule': crontab(hour=3, minute=30),  # 03:30 daily
}
```

**Use case:** Daily reports, backups, maintenance windows

### Weekly Tasks

```python
'monday-morning': {
    'task': 'tasks.weekly_summary',
    'schedule': crontab(hour=9, minute=0, day_of_week=1),  # Monday 09:00
}

'friday-afternoon': {
    'task': 'tasks.week_closing',
    'schedule': crontab(hour=17, minute=0, day_of_week=5),  # Friday 17:00
}
```

**Use case:** Weekly summaries, reports, cleanups

### Monthly Tasks

```python
'first-of-month': {
    'task': 'tasks.monthly_billing',
    'schedule': crontab(hour=0, minute=0, day_of_month=1),  # 1st at midnight
}

'mid-month': {
    'task': 'tasks.mid_month_check',
    'schedule': crontab(hour=12, minute=0, day_of_month=15),  # 15th at noon
}
```

**Use case:** Billing cycles, monthly reports, subscription renewals

## Business Hours Scheduling

### Every 15 Minutes During Business Hours

```python
'business-hours-check': {
    'task': 'tasks.process_orders',
    'schedule': crontab(
        minute='*/15',           # Every 15 minutes
        hour='9-17',             # 9 AM to 5 PM
        day_of_week='mon-fri'    # Monday through Friday
    ),
}
```

**Use case:** Order processing, customer service automation

### Lunch Break Excluded

```python
'morning-processing': {
    'task': 'tasks.morning_batch',
    'schedule': crontab(
        minute='*/10',
        hour='9-11',
        day_of_week='mon-fri'
    ),
}

'afternoon-processing': {
    'task': 'tasks.afternoon_batch',
    'schedule': crontab(
        minute='*/10',
        hour='13-17',
        day_of_week='mon-fri'
    ),
}
```

**Use case:** Avoiding peak load times, scheduled maintenance windows

### Start and End of Day

```python
'start-of-day': {
    'task': 'tasks.morning_setup',
    'schedule': crontab(hour=8, minute=0, day_of_week='mon-fri'),
}

'end-of-day': {
    'task': 'tasks.eod_report',
    'schedule': crontab(hour=18, minute=0, day_of_week='mon-fri'),
}
```

**Use case:** Daily initialization, end-of-day reporting

## Complex Patterns

### Multiple Specific Hours

```python
'peak-hours-processing': {
    'task': 'tasks.peak_load',
    'schedule': crontab(
        hour='8,12,18',  # 8 AM, 12 PM, 6 PM
        minute=0
    ),
}
```

**Use case:** Processing during peak traffic times

### Every 10 Minutes on Specific Days/Hours

```python
'complex-schedule': {
    'task': 'tasks.complex_job',
    'schedule': crontab(
        minute='*/10',            # Every 10 minutes
        hour='3-4,17-18,22-23',   # Multiple hour ranges
        day_of_week='thu,fri'     # Thursday and Friday
    ),
}
```

**Use case:** Specialized processing windows, compliance requirements

### Quarter-Hour Intervals

```python
'quarter-hour': {
    'task': 'tasks.frequent_check',
    'schedule': crontab(minute='0,15,30,45'),  # XX:00, XX:15, XX:30, XX:45
}
```

**Use case:** Regular monitoring, data collection

### First Weekday of Month

```python
'first-weekday': {
    'task': 'tasks.monthly_report',
    'schedule': crontab(
        hour=9,
        minute=0,
        day_of_month='1-7',  # First week
        day_of_week=1         # Monday
    ),
}
```

**Use case:** Monthly reports on first business day

### Last Day of Month (Approximate)

```python
'end-of-month': {
    'task': 'tasks.month_end_close',
    'schedule': crontab(
        hour=23,
        minute=0,
        day_of_month='28-31'  # Last few days
    ),
}
```

**Note:** For exact last day, use custom logic in task.

## Multi-Timezone Scheduling

### UTC-Based Scheduling (Recommended)

```python
from celery import Celery

app = Celery('tasks')
app.conf.timezone = 'UTC'
app.conf.enable_utc = True

app.conf.beat_schedule = {
    # All times in UTC
    'global-sync': {
        'task': 'tasks.global_sync',
        'schedule': crontab(hour=0, minute=0),  # Midnight UTC
    }
}
```

**Benefits:** Consistent across all deployments, no DST issues

### Local Timezone Scheduling

```python
app.conf.timezone = 'America/New_York'

app.conf.beat_schedule = {
    'local-business-hours': {
        'task': 'tasks.local_processing',
        'schedule': crontab(
            hour='9-17',
            day_of_week='mon-fri'
        ),  # 9 AM - 5 PM Eastern Time
    }
}
```

**Use case:** Region-specific business logic

### Multi-Region Scheduling

```python
# UTC configuration for all schedules
app.conf.timezone = 'UTC'

app.conf.beat_schedule = {
    'us-east-morning': {
        'task': 'tasks.regional_process',
        'schedule': crontab(hour=13, minute=0),  # 9 AM ET = 13:00 UTC
        'kwargs': {'region': 'us-east'}
    },
    'europe-morning': {
        'task': 'tasks.regional_process',
        'schedule': crontab(hour=8, minute=0),   # 9 AM CET = 08:00 UTC
        'kwargs': {'region': 'europe'}
    },
    'asia-morning': {
        'task': 'tasks.regional_process',
        'schedule': crontab(hour=1, minute=0),   # 9 AM JST = 01:00 UTC
        'kwargs': {'region': 'asia'}
    }
}
```

**Use case:** Multi-region business operations

## Production Use Cases

### Daily Backup

```python
'daily-backup': {
    'task': 'tasks.backup_database',
    'schedule': crontab(hour=2, minute=0),  # 2 AM daily
    'options': {
        'expires': 3600,  # Must complete within 1 hour
    }
}
```

### Weekly Report Generation

```python
'weekly-report': {
    'task': 'tasks.generate_weekly_report',
    'schedule': crontab(
        hour=6,
        minute=0,
        day_of_week=1  # Monday 6 AM
    ),
    'kwargs': {'report_type': 'weekly'},
}
```

### Real-Time Monitoring

```python
'high-frequency-monitor': {
    'task': 'tasks.monitor_critical_services',
    'schedule': crontab(minute='*/2'),  # Every 2 minutes
    'options': {
        'expires': 60,  # Must execute within 60 seconds
        'queue': 'high-priority',
    }
}
```

### Cache Warming

```python
'warm-cache-morning': {
    'task': 'tasks.warm_cache',
    'schedule': crontab(hour=7, minute=0, day_of_week='mon-fri'),
}

'warm-cache-afternoon': {
    'task': 'tasks.warm_cache',
    'schedule': crontab(hour=13, minute=0, day_of_week='mon-fri'),
}
```

### Log Rotation

```python
'daily-log-rotation': {
    'task': 'tasks.rotate_logs',
    'schedule': crontab(hour=23, minute=55),  # Just before midnight
}
```

### Email Digest

```python
'morning-digest': {
    'task': 'tasks.send_email_digest',
    'schedule': crontab(hour=8, minute=0, day_of_week='mon-fri'),
    'kwargs': {'digest_type': 'daily'},
}

'weekly-digest': {
    'task': 'tasks.send_email_digest',
    'schedule': crontab(hour=9, minute=0, day_of_week=1),
    'kwargs': {'digest_type': 'weekly'},
}
```

## Advanced Task Configuration

### With Task Arguments

```python
'task-with-args': {
    'task': 'tasks.process_data',
    'schedule': crontab(hour=0, minute=0),
    'args': (100,),  # batch_size
    'kwargs': {'priority': 'high', 'full_scan': True},
}
```

### With Custom Queue

```python
'priority-task': {
    'task': 'tasks.urgent_processing',
    'schedule': crontab(minute='*/5'),
    'options': {
        'queue': 'high-priority',
        'priority': 9,
    }
}
```

### With Retry Configuration

```python
'unreliable-task': {
    'task': 'tasks.external_api_call',
    'schedule': crontab(hour='*/2', minute=0),
    'options': {
        'max_retries': 3,
        'retry_backoff': True,
        'retry_backoff_max': 600,
    }
}
```

## Crontab Expression Reference

### Minute (0-59)

```python
minute=0          # Hour start (XX:00)
minute=30         # Half hour (XX:30)
minute='*/15'     # Every 15 minutes
minute='0,30'     # On the hour and half hour
minute='15-45'    # Minutes 15 through 45
```

### Hour (0-23)

```python
hour=0            # Midnight
hour=12           # Noon
hour='9-17'       # 9 AM to 5 PM
hour='*/2'        # Every 2 hours
hour='8,12,18'    # 8 AM, noon, 6 PM
```

### Day of Week (0-6, 0=Sunday or mon-sun)

```python
day_of_week=1         # Monday
day_of_week='mon'     # Monday (named)
day_of_week='mon-fri' # Weekdays
day_of_week='sat,sun' # Weekends
day_of_week='1-5'     # Monday through Friday
```

### Day of Month (1-31)

```python
day_of_month=1        # First day of month
day_of_month=15       # 15th of month
day_of_month='1,15'   # 1st and 15th
day_of_month='1-7'    # First week
day_of_month='*/2'    # Every other day
```

### Month of Year (1-12)

```python
month_of_year=1       # January
month_of_year='1-3'   # Q1 (Jan-Mar)
month_of_year='*/3'   # Quarterly
```

## Troubleshooting

### Schedule Not Executing

**Check beat logs:**
```bash
celery -A myapp beat --loglevel=debug
```

**Verify schedule registration:**
```python
# In Python shell
from myapp import app
print(app.conf.beat_schedule)
```

### Timezone Confusion

**Always log timezone:**
```python
import datetime
import pytz

@app.task
def my_task():
    utc_now = datetime.datetime.now(pytz.UTC)
    print(f"Task executing at {utc_now} UTC")
```

### Task Overlap

**Implement locking:**
```python
from redis import Redis
redis = Redis()

@app.task
def exclusive_task():
    lock = redis.lock('task_lock', timeout=300)
    if lock.acquire(blocking=False):
        try:
            # Task logic
            pass
        finally:
            lock.release()
    else:
        print("Task already running")
```

## Testing Crontab Schedules

### Validate Expression Online

Use https://crontab.guru/ to validate crontab expressions

### Test with Shorter Intervals

```python
# Development
'test-task': {
    'task': 'tasks.my_task',
    'schedule': crontab(minute='*/1'),  # Every minute for testing
}

# Production
'test-task': {
    'task': 'tasks.my_task',
    'schedule': crontab(hour=0, minute=0),  # Daily
}
```

### Verify Next Execution Time

```python
from celery.schedules import crontab
import datetime

schedule = crontab(hour=9, minute=0, day_of_week='mon-fri')
now = datetime.datetime.now()

# Check if schedule would run now
print(schedule.is_due(now))

# Get next run time
print(schedule.remaining_estimate(now))
```

## Best Practices

1. **Use UTC timezone** for consistency across deployments
2. **Name schedules descriptively** for easy identification
3. **Set task expiration** to prevent stale task execution
4. **Monitor beat scheduler** uptime and health
5. **Test schedules** with shorter intervals in development
6. **Document schedule purpose** in task docstrings
7. **Implement locking** for tasks that shouldn't overlap
8. **Use separate beat process** (not embedded in worker)

## Security Note

Never hardcode credentials in schedule configuration. Always use environment variables:

```python
import os

app.conf.update(
    broker_url=os.getenv('CELERY_BROKER_URL'),
    result_backend=os.getenv('CELERY_RESULT_BACKEND'),
)
```
