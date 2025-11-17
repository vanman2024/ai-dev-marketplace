# Django Celery Beat Complete Setup Guide

Comprehensive guide for setting up database-backed periodic task scheduling with Django Celery Beat.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Configuration](#configuration)
- [Django Admin Usage](#django-admin-usage)
- [Programmatic Management](#programmatic-management)
- [Multi-Tenant Patterns](#multi-tenant-patterns)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

## Overview

Django Celery Beat provides:
- **Database-backed schedules** - Store schedules in Django database
- **Django Admin interface** - Manage schedules without code changes
- **Runtime editing** - Update schedules without restart
- **Multi-instance coordination** - Prevent duplicate executions
- **Audit trail** - Track schedule changes

**When to use:**
- Need to modify schedules without deployment
- Multi-tenant applications with per-tenant schedules
- Non-technical users managing schedules
- Dynamic schedule requirements

## Installation

### 1. Install Package

```bash
pip install django-celery-beat
```

### 2. Add to INSTALLED_APPS

**File:** `myproject/settings.py`

```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Add django-celery-beat
    'django_celery_beat',

    # Your apps
    'myapp',
]
```

### 3. Run Migrations

```bash
python manage.py migrate django_celery_beat
```

This creates tables:
- `django_celery_beat_periodictask` - Periodic tasks
- `django_celery_beat_intervalschedule` - Interval schedules
- `django_celery_beat_crontabschedule` - Crontab schedules
- `django_celery_beat_solarschedule` - Solar schedules
- `django_celery_beat_clockedschedule` - One-time schedules
- `django_celery_beat_periodictasks` - Change tracking

## Configuration

### Celery Configuration

**File:** `myproject/settings.py`

```python
import os

# Celery Broker
CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')

# Celery Result Backend
CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Use Django Celery Beat scheduler
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Timezone
CELERY_TIMEZONE = 'UTC'
CELERY_ENABLE_UTC = True

# Additional settings
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_BEAT_SCHEDULE = {}  # Empty - schedules in database
```

### Celery App Setup

**File:** `myproject/celery.py`

```python
import os
from celery import Celery

# Set Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')

# Create Celery app
app = Celery('myproject')

# Load config from Django settings
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
```

### Django Init

**File:** `myproject/__init__.py`

```python
from .celery import app as celery_app

__all__ = ('celery_app',)
```

## Django Admin Usage

### Access Admin Interface

1. Create superuser if needed:
```bash
python manage.py createsuperuser
```

2. Start Django dev server:
```bash
python manage.py runserver
```

3. Navigate to: `http://localhost:8000/admin/`

### Creating Schedules via Admin

#### Interval Schedule

1. Go to **Periodic Tasks** → **Add Periodic Task**
2. Fill in fields:
   - **Name:** `health-check-every-30s`
   - **Task (registered):** Select `myapp.tasks.health_check`
   - **Interval Schedule:** Click "+" to create new
     - **Every:** `30`
     - **Period:** `Seconds`
   - **Enabled:** Check
3. Save

#### Crontab Schedule

1. Go to **Periodic Tasks** → **Add Periodic Task**
2. Fill in fields:
   - **Name:** `daily-report-midnight`
   - **Task (registered):** Select `myapp.tasks.daily_report`
   - **Crontab Schedule:** Click "+" to create new
     - **Minute:** `0`
     - **Hour:** `0`
     - **Day of week:** `*`
     - **Day of month:** `*`
     - **Month of year:** `*`
     - **Timezone:** Select `UTC`
   - **Enabled:** Check
3. Save

#### Solar Schedule

1. Go to **Periodic Tasks** → **Add Periodic Task**
2. Fill in fields:
   - **Name:** `sunrise-task`
   - **Task (registered):** Select `myapp.tasks.sunrise_routine`
   - **Solar Schedule:** Click "+" to create new
     - **Event:** `sunrise`
     - **Latitude:** `40.7128`
     - **Longitude:** `-74.0060`
   - **Enabled:** Check
3. Save

#### Clocked Schedule (One-Time)

1. Go to **Periodic Tasks** → **Add Periodic Task**
2. Fill in fields:
   - **Name:** `scheduled-maintenance`
   - **Task (registered):** Select `myapp.tasks.maintenance`
   - **Clocked Schedule:** Click "+" to create new
     - **Clock time:** Select date/time
   - **One-off task:** Check
   - **Enabled:** Check
3. Save

### Task Arguments in Admin

**Arguments (JSON):**
```json
[100, "parameter2"]
```

**Keyword arguments (JSON):**
```json
{"priority": "high", "full_sync": true}
```

### Task Options in Admin

**Expires:** Datetime or seconds until expiration

**Queue:** Custom queue name (`high-priority`, `background`)

## Programmatic Management

### Creating Schedules

```python
from django_celery_beat.models import (
    PeriodicTask,
    IntervalSchedule,
    CrontabSchedule,
    SolarSchedule,
)
import json


def create_interval_task(name, task_name, every, period='seconds'):
    """Create task with interval schedule"""
    # Create or get schedule
    schedule, created = IntervalSchedule.objects.get_or_create(
        every=every,
        period=period,  # seconds, minutes, hours, days, weeks
    )

    # Create or update task
    task, created = PeriodicTask.objects.get_or_create(
        name=name,
        defaults={
            'interval': schedule,
            'task': task_name,
        }
    )

    if not created:
        task.interval = schedule
        task.save()

    return task


def create_crontab_task(name, task_name, minute='*', hour='*',
                        day_of_week='*', day_of_month='*', month_of_year='*'):
    """Create task with crontab schedule"""
    schedule, created = CrontabSchedule.objects.get_or_create(
        minute=minute,
        hour=hour,
        day_of_week=day_of_week,
        day_of_month=day_of_month,
        month_of_year=month_of_year,
        timezone='UTC',
    )

    task, created = PeriodicTask.objects.get_or_create(
        name=name,
        defaults={
            'crontab': schedule,
            'task': task_name,
        }
    )

    if not created:
        task.crontab = schedule
        task.save()

    return task


def create_task_with_args(name, task_name, schedule, args=None, kwargs=None):
    """Create task with arguments"""
    task, created = PeriodicTask.objects.get_or_create(
        name=name,
        defaults={
            'interval': schedule,
            'task': task_name,
            'args': json.dumps(args or []),
            'kwargs': json.dumps(kwargs or {}),
        }
    )

    return task
```

### Managing Schedules

```python
def enable_task(task_name):
    """Enable periodic task"""
    task = PeriodicTask.objects.get(name=task_name)
    task.enabled = True
    task.save()


def disable_task(task_name):
    """Disable periodic task"""
    task = PeriodicTask.objects.get(name=task_name)
    task.enabled = False
    task.save()


def update_task_schedule(task_name, new_schedule):
    """Update task schedule"""
    task = PeriodicTask.objects.get(name=task_name)
    task.interval = new_schedule
    task.save()


def delete_task(task_name):
    """Delete periodic task"""
    PeriodicTask.objects.filter(name=task_name).delete()


def get_task_status(task_name):
    """Get task execution status"""
    task = PeriodicTask.objects.get(name=task_name)
    return {
        'name': task.name,
        'enabled': task.enabled,
        'last_run': task.last_run_at,
        'total_runs': task.total_run_count,
    }
```

### Management Command

**File:** `myapp/management/commands/setup_schedules.py`

```python
from django.core.management.base import BaseCommand
from django_celery_beat.models import PeriodicTask, IntervalSchedule, CrontabSchedule


class Command(BaseCommand):
    help = 'Setup initial Celery Beat schedules'

    def handle(self, *args, **options):
        self.stdout.write('Setting up schedules...')

        # Health check every 30 seconds
        interval_30s, _ = IntervalSchedule.objects.get_or_create(
            every=30,
            period=IntervalSchedule.SECONDS,
        )

        PeriodicTask.objects.get_or_create(
            name='health-check',
            defaults={
                'interval': interval_30s,
                'task': 'myapp.tasks.health_check',
            }
        )

        # Daily report at midnight
        crontab_midnight, _ = CrontabSchedule.objects.get_or_create(
            minute='0',
            hour='0',
            day_of_week='*',
            day_of_month='*',
            month_of_year='*',
            timezone='UTC',
        )

        PeriodicTask.objects.get_or_create(
            name='daily-report',
            defaults={
                'crontab': crontab_midnight,
                'task': 'myapp.tasks.daily_report',
            }
        )

        self.stdout.write(self.style.SUCCESS('Successfully setup schedules'))
```

**Run with:**
```bash
python manage.py setup_schedules
```

## Multi-Tenant Patterns

### Per-Tenant Schedules

```python
from django.db import models
from django_celery_beat.models import PeriodicTask, IntervalSchedule
import json


class Tenant(models.Model):
    name = models.CharField(max_length=100)
    sync_interval = models.IntegerField(default=300)  # seconds


def create_tenant_schedule(tenant):
    """Create periodic task for tenant"""
    # Create schedule
    schedule, _ = IntervalSchedule.objects.get_or_create(
        every=tenant.sync_interval,
        period=IntervalSchedule.SECONDS,
    )

    # Create task
    task_name = f'tenant-{tenant.id}-sync'
    task, created = PeriodicTask.objects.get_or_create(
        name=task_name,
        defaults={
            'interval': schedule,
            'task': 'myapp.tasks.sync_tenant_data',
            'kwargs': json.dumps({'tenant_id': tenant.id}),
        }
    )

    return task


def update_tenant_schedule(tenant):
    """Update tenant schedule interval"""
    task_name = f'tenant-{tenant.id}-sync'
    task = PeriodicTask.objects.get(name=task_name)

    schedule, _ = IntervalSchedule.objects.get_or_create(
        every=tenant.sync_interval,
        period=IntervalSchedule.SECONDS,
    )

    task.interval = schedule
    task.save()


def delete_tenant_schedule(tenant):
    """Delete tenant schedule"""
    task_name = f'tenant-{tenant.id}-sync'
    PeriodicTask.objects.filter(name=task_name).delete()
```

### Tenant Signals

```python
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver


@receiver(post_save, sender=Tenant)
def tenant_saved(sender, instance, created, **kwargs):
    """Create/update schedule when tenant saved"""
    if created:
        create_tenant_schedule(instance)
    else:
        update_tenant_schedule(instance)


@receiver(post_delete, sender=Tenant)
def tenant_deleted(sender, instance, **kwargs):
    """Delete schedule when tenant deleted"""
    delete_tenant_schedule(instance)
```

### User-Configurable Schedules

```python
class UserSchedule(models.Model):
    """User-defined schedule preferences"""
    user = models.ForeignKey('auth.User', on_delete=models.CASCADE)
    task_type = models.CharField(max_length=50)
    interval_minutes = models.IntegerField(default=60)
    enabled = models.BooleanField(default=True)


def create_user_schedule(user_schedule):
    """Create schedule from user preferences"""
    schedule, _ = IntervalSchedule.objects.get_or_create(
        every=user_schedule.interval_minutes,
        period=IntervalSchedule.MINUTES,
    )

    task_name = f'user-{user_schedule.user_id}-{user_schedule.task_type}'

    PeriodicTask.objects.get_or_create(
        name=task_name,
        defaults={
            'interval': schedule,
            'task': f'myapp.tasks.{user_schedule.task_type}',
            'kwargs': json.dumps({'user_id': user_schedule.user_id}),
            'enabled': user_schedule.enabled,
        }
    )
```

## Production Deployment

### Process Management (Supervisor)

**File:** `/etc/supervisor/conf.d/celery.conf`

```ini
[program:celery-worker]
command=/path/to/venv/bin/celery -A myproject worker --loglevel=info
directory=/path/to/project
user=www-data
numprocs=1
stdout_logfile=/var/log/celery/worker.log
stderr_logfile=/var/log/celery/worker_err.log
autostart=true
autorestart=true
startsecs=10
stopwaitsecs=600
stopasgroup=true

[program:celery-beat]
command=/path/to/venv/bin/celery -A myproject beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
directory=/path/to/project
user=www-data
numprocs=1
stdout_logfile=/var/log/celery/beat.log
stderr_logfile=/var/log/celery/beat_err.log
autostart=true
autorestart=true
startsecs=10
priority=999
```

**Reload Supervisor:**
```bash
supervisorctl reread
supervisorctl update
supervisorctl start celery-worker
supervisorctl start celery-beat
```

### Systemd Service Files

**File:** `/etc/systemd/system/celery-worker.service`

```ini
[Unit]
Description=Celery Worker
After=network.target

[Service]
Type=forking
User=www-data
Group=www-data
WorkingDirectory=/path/to/project
Environment="PATH=/path/to/venv/bin"
ExecStart=/path/to/venv/bin/celery -A myproject worker --loglevel=info --pidfile=/var/run/celery/worker.pid
Restart=always

[Install]
WantedBy=multi-user.target
```

**File:** `/etc/systemd/system/celery-beat.service`

```ini
[Unit]
Description=Celery Beat
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/path/to/project
Environment="PATH=/path/to/venv/bin"
ExecStart=/path/to/venv/bin/celery -A myproject beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
Restart=always

[Install]
WantedBy=multi-user.target
```

**Enable and start:**
```bash
systemctl daemon-reload
systemctl enable celery-worker celery-beat
systemctl start celery-worker celery-beat
```

### Docker Compose

**File:** `docker-compose.yml`

```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: myproject
      POSTGRES_USER: your_db_user_here
      POSTGRES_PASSWORD: your_db_password_here
    volumes:
      - postgres_data:/var/lib/postgresql/data

  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/code
    ports:
      - "8000:8000"
    depends_on:
      - db
      - redis
    environment:
      - DATABASE_URL=postgres://your_db_user_here:your_db_password_here@db:5432/myproject
      - CELERY_BROKER_URL=redis://redis:6379/0

  celery-worker:
    build: .
    command: celery -A myproject worker --loglevel=info
    volumes:
      - .:/code
    depends_on:
      - db
      - redis
    environment:
      - DATABASE_URL=postgres://your_db_user_here:your_db_password_here@db:5432/myproject
      - CELERY_BROKER_URL=redis://redis:6379/0

  celery-beat:
    build: .
    command: celery -A myproject beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
    volumes:
      - .:/code
    depends_on:
      - db
      - redis
    environment:
      - DATABASE_URL=postgres://your_db_user_here:your_db_password_here@db:5432/myproject
      - CELERY_BROKER_URL=redis://redis:6379/0

volumes:
  postgres_data:
```

## Monitoring & Health Checks

### Admin Interface Customization

**File:** `myapp/admin.py`

```python
from django.contrib import admin
from django_celery_beat.models import PeriodicTask, IntervalSchedule, CrontabSchedule


class PeriodicTaskAdmin(admin.ModelAdmin):
    list_display = ('name', 'task', 'enabled', 'last_run_at', 'total_run_count')
    list_filter = ('enabled', 'task')
    search_fields = ('name', 'task')
    readonly_fields = ('last_run_at', 'total_run_count')


# Unregister default and register custom
admin.site.unregister(PeriodicTask)
admin.site.register(PeriodicTask, PeriodicTaskAdmin)
```

### Monitoring View

```python
from django.http import JsonResponse
from django_celery_beat.models import PeriodicTask


def schedule_status(request):
    """API endpoint for schedule monitoring"""
    tasks = PeriodicTask.objects.filter(enabled=True)

    status = []
    for task in tasks:
        status.append({
            'name': task.name,
            'task': task.task,
            'last_run': task.last_run_at.isoformat() if task.last_run_at else None,
            'total_runs': task.total_run_count,
            'enabled': task.enabled,
        })

    return JsonResponse({'schedules': status})
```

## Troubleshooting

### Schedules Not Executing

**1. Check beat is running:**
```bash
ps aux | grep "celery.*beat"
```

**2. Check beat logs:**
```bash
tail -f /var/log/celery/beat.log
```

**3. Verify database schedules:**
```python
from django_celery_beat.models import PeriodicTask
print(PeriodicTask.objects.filter(enabled=True).count())
```

**4. Check for errors:**
```bash
celery -A myproject beat --loglevel=debug
```

### Tasks Not Registered

**Ensure tasks are discovered:**
```python
# In celery.py
app.autodiscover_tasks()

# Or explicitly
app.autodiscover_tasks(['myapp', 'otherapp'])
```

**List registered tasks:**
```bash
celery -A myproject inspect registered
```

### Multiple Beat Instances

**Symptom:** Duplicate task executions

**Solution:** Ensure only ONE beat scheduler running
```bash
# Kill all beat processes
pkill -f "celery.*beat"

# Start single instance
celery -A myproject beat
```

### Database Lock Issues

**If using SQLite (not recommended for production):**
- Switch to PostgreSQL or MySQL
- SQLite doesn't handle concurrent writes well

**Migration:**
```bash
# Export schedules
python manage.py dumpdata django_celery_beat > schedules.json

# Switch database, migrate
python manage.py migrate

# Import schedules
python manage.py loaddata schedules.json
```

## Best Practices

1. **Single beat instance** - Only run one beat scheduler
2. **Use PostgreSQL** - Better concurrency than SQLite
3. **Monitor schedules** - Track execution success/failures
4. **Audit changes** - Log schedule modifications
5. **Test schedules** - Verify in staging before production
6. **Backup schedules** - Export periodically
7. **Set permissions** - Restrict admin access
8. **Document schedules** - Explain purpose and requirements
9. **Version control** - Store setup scripts in git
10. **Health checks** - Monitor beat scheduler uptime

## Security Note

Never hardcode credentials. Use environment variables:

```python
import os

CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL')
DATABASE_URL = os.getenv('DATABASE_URL')
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')
```
