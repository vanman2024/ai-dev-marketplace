"""
Django Celery Beat Integration

Database-backed dynamic schedule management for Django projects.
Enables runtime schedule editing via Django Admin interface.

Security: No hardcoded credentials - all configuration from environment.
"""

# ============================================================================
# Django Settings Configuration (settings.py)
# ============================================================================

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

# Celery Configuration
CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')
CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Use Django Celery Beat scheduler (database-backed)
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Timezone configuration
CELERY_TIMEZONE = 'UTC'
CELERY_ENABLE_UTC = True

# Additional Celery settings
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'


# ============================================================================
# Celery App Configuration (celery.py)
# ============================================================================

"""
Create celery.py in your Django project directory:
"""

import os
from celery import Celery

# Set default Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')

# Create Celery app
app = Celery('myproject')

# Load configuration from Django settings
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks in Django apps
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    """Debug task for testing"""
    print(f'Request: {self.request!r}')


# ============================================================================
# Django __init__.py Configuration
# ============================================================================

"""
Add to myproject/__init__.py to ensure Celery loads with Django:
"""

from .celery import app as celery_app

__all__ = ('celery_app',)


# ============================================================================
# Database Migration
# ============================================================================

"""
After installing django-celery-beat, run migrations:

python manage.py migrate django_celery_beat

This creates tables:
- django_celery_beat_periodictask
- django_celery_beat_intervalschedule
- django_celery_beat_crontabschedule
- django_celery_beat_solarschedule
- django_celery_beat_clockedschedule
- django_celery_beat_periodictasks
"""


# ============================================================================
# Creating Schedules via Django Admin
# ============================================================================

"""
1. Start Django development server:
   python manage.py runserver

2. Navigate to admin interface:
   http://localhost:8000/admin/

3. Create schedules under "Periodic Tasks":
   - Click "Add Periodic Task"
   - Select task from dropdown
   - Choose schedule type (interval/crontab/solar/clocked)
   - Configure schedule parameters
   - Set arguments if needed
   - Save

Schedule Types in Admin:
- Interval: Fixed frequency (every N seconds/minutes/hours)
- Crontab: Time-of-day specific (daily at 3am, weekdays at 9am)
- Solar: Sun-based events (sunrise, sunset, solar noon)
- Clocked: One-time execution at specific datetime
"""


# ============================================================================
# Programmatic Schedule Management
# ============================================================================

from django_celery_beat.models import (
    PeriodicTask,
    IntervalSchedule,
    CrontabSchedule,
    SolarSchedule,
)
import json


def create_interval_task(name, task_name, seconds):
    """Create periodic task with interval schedule"""
    # Create interval schedule
    schedule, created = IntervalSchedule.objects.get_or_create(
        every=seconds,
        period=IntervalSchedule.SECONDS,
    )

    # Create periodic task
    task, created = PeriodicTask.objects.get_or_create(
        name=name,
        defaults={
            'interval': schedule,
            'task': task_name,
        }
    )

    return task


def create_crontab_task(name, task_name, hour, minute, day_of_week='*'):
    """Create periodic task with crontab schedule"""
    # Create crontab schedule
    schedule, created = CrontabSchedule.objects.get_or_create(
        minute=minute,
        hour=hour,
        day_of_week=day_of_week,
        day_of_month='*',
        month_of_year='*',
    )

    # Create periodic task
    task, created = PeriodicTask.objects.get_or_create(
        name=name,
        defaults={
            'crontab': schedule,
            'task': task_name,
        }
    )

    return task


def create_solar_task(name, task_name, event, latitude, longitude):
    """Create periodic task with solar schedule"""
    # Create solar schedule
    schedule, created = SolarSchedule.objects.get_or_create(
        event=event,
        latitude=latitude,
        longitude=longitude,
    )

    # Create periodic task
    task, created = PeriodicTask.objects.get_or_create(
        name=name,
        defaults={
            'solar': schedule,
            'task': task_name,
        }
    )

    return task


def create_task_with_args(name, task_name, schedule, args=None, kwargs=None):
    """Create periodic task with arguments"""
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


def enable_task(task_name):
    """Enable a periodic task"""
    task = PeriodicTask.objects.get(name=task_name)
    task.enabled = True
    task.save()


def disable_task(task_name):
    """Disable a periodic task"""
    task = PeriodicTask.objects.get(name=task_name)
    task.enabled = False
    task.save()


def delete_task(task_name):
    """Delete a periodic task"""
    task = PeriodicTask.objects.get(name=task_name)
    task.delete()


def update_task_schedule(task_name, new_schedule):
    """Update task schedule"""
    task = PeriodicTask.objects.get(name=task_name)
    task.interval = new_schedule
    task.save()


# ============================================================================
# Django Management Command for Schedule Setup
# ============================================================================

"""
Create management/commands/setup_beat_schedules.py:
"""

from django.core.management.base import BaseCommand
from django_celery_beat.models import PeriodicTask, IntervalSchedule, CrontabSchedule


class Command(BaseCommand):
    help = 'Setup initial Celery Beat schedules'

    def handle(self, *args, **options):
        self.stdout.write('Setting up Celery Beat schedules...')

        # Create interval schedule (every 30 seconds)
        interval_30s, _ = IntervalSchedule.objects.get_or_create(
            every=30,
            period=IntervalSchedule.SECONDS,
        )

        # Create periodic task
        PeriodicTask.objects.get_or_create(
            name='Health Check Every 30s',
            defaults={
                'interval': interval_30s,
                'task': 'myapp.tasks.health_check',
            }
        )

        # Create crontab schedule (daily at midnight)
        crontab_midnight, _ = CrontabSchedule.objects.get_or_create(
            minute='0',
            hour='0',
            day_of_week='*',
            day_of_month='*',
            month_of_year='*',
        )

        PeriodicTask.objects.get_or_create(
            name='Daily Report at Midnight',
            defaults={
                'crontab': crontab_midnight,
                'task': 'myapp.tasks.daily_report',
            }
        )

        self.stdout.write(self.style.SUCCESS('Successfully setup schedules'))


"""
Run with: python manage.py setup_beat_schedules
"""


# ============================================================================
# Multi-Tenant Schedule Management
# ============================================================================

def create_tenant_schedule(tenant_id, task_name, interval_seconds):
    """Create per-tenant periodic task"""
    schedule, _ = IntervalSchedule.objects.get_or_create(
        every=interval_seconds,
        period=IntervalSchedule.SECONDS,
    )

    task, created = PeriodicTask.objects.get_or_create(
        name=f'tenant-{tenant_id}-{task_name}',
        defaults={
            'interval': schedule,
            'task': 'myapp.tasks.process_tenant_data',
            'kwargs': json.dumps({'tenant_id': tenant_id}),
        }
    )

    return task


def get_tenant_tasks(tenant_id):
    """Get all periodic tasks for a tenant"""
    return PeriodicTask.objects.filter(name__startswith=f'tenant-{tenant_id}-')


def delete_tenant_tasks(tenant_id):
    """Delete all periodic tasks for a tenant"""
    PeriodicTask.objects.filter(name__startswith=f'tenant-{tenant_id}-').delete()


# ============================================================================
# Django Signals for Schedule Synchronization
# ============================================================================

from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django_celery_beat.models import PeriodicTask


@receiver(post_save, sender=PeriodicTask)
def periodic_task_saved(sender, instance, **kwargs):
    """Signal handler for when periodic task is saved"""
    print(f"Periodic task '{instance.name}' was saved")
    # Trigger beat scheduler refresh if needed


@receiver(post_delete, sender=PeriodicTask)
def periodic_task_deleted(sender, instance, **kwargs):
    """Signal handler for when periodic task is deleted"""
    print(f"Periodic task '{instance.name}' was deleted")
    # Trigger beat scheduler refresh if needed


# ============================================================================
# Running Celery Beat with Django
# ============================================================================

"""
Production Deployment:

1. Run Celery Worker:
   celery -A myproject worker --loglevel=info

2. Run Celery Beat (separate process):
   celery -A myproject beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler

3. Optional - Run Flower for monitoring:
   celery -A myproject flower

Process Management with Supervisor:

[program:celery-worker]
command=/path/to/venv/bin/celery -A myproject worker --loglevel=info
directory=/path/to/project
user=www-data
autostart=true
autorestart=true
redirect_stderr=true

[program:celery-beat]
command=/path/to/venv/bin/celery -A myproject beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
directory=/path/to/project
user=www-data
autostart=true
autorestart=true
redirect_stderr=true
"""


# ============================================================================
# Best Practices
# ============================================================================

"""
1. Database Scheduler Benefits:
   - Edit schedules without code changes
   - Runtime schedule management
   - Django Admin interface
   - Multi-instance coordination

2. Performance Considerations:
   - Beat scheduler queries database periodically
   - Use database indexing for large schedule counts
   - Consider caching for read-heavy workloads
   - Monitor database connection pool

3. High Availability:
   - Run single beat scheduler instance (database prevents duplicates)
   - Use process manager (supervisor, systemd) for auto-restart
   - Monitor beat scheduler health
   - Set up alerting for beat failures

4. Security:
   - Restrict Django Admin access
   - Validate task names (prevent arbitrary task execution)
   - Sanitize task arguments
   - Use permissions for schedule management

5. Testing:
   - Use separate test database
   - Create test schedules programmatically
   - Test schedule CRUD operations
   - Verify task execution with test celery worker
"""


# ============================================================================
# Troubleshooting
# ============================================================================

"""
Common Issues:

1. Tasks Not Executing:
   - Verify beat scheduler is running
   - Check task enabled status in database
   - Review beat logs for errors
   - Confirm task name matches registered task

2. Schedule Not Updating:
   - Restart beat scheduler
   - Check database for schedule changes
   - Verify beat_scheduler setting

3. Multiple Executions:
   - Ensure only one beat scheduler running
   - Check for duplicate PeriodicTask entries
   - Verify task locking if needed

4. Database Errors:
   - Run migrations: python manage.py migrate django_celery_beat
   - Check database permissions
   - Verify connection settings
"""
