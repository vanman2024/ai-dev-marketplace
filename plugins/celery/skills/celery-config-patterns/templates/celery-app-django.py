"""
Django Celery Application Configuration

Place this file at: myproject/celery.py
(where myproject is your Django project directory with settings.py)

Then add to myproject/__init__.py:
    from .celery import app as celery_app
    __all__ = ('celery_app',)

Usage:
    celery -A myproject worker --loglevel=info
    celery -A myproject beat --loglevel=info
"""

import os
from celery import Celery

# Set default Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')

# Create Celery application
app = Celery('myproject')

# Load configuration from Django settings
# - namespace='CELERY' means all Celery config keys should be prefixed with CELERY_
# - Example: CELERY_BROKER_URL in settings.py
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks from all installed Django apps
# Looks for tasks.py in each app directory
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    """Debug task for testing Celery configuration"""
    print(f'Request: {self.request!r}')


# Optional: Additional configuration
app.conf.update(
    # Task execution settings
    task_acks_late=True,
    task_reject_on_worker_lost=True,

    # Django-specific: Use Django database for result backend (optional)
    # result_backend='django-db',  # Requires django-celery-results
    # result_extended=True,

    # Beat schedule (requires django-celery-beat)
    # beat_scheduler='django_celery_beat.schedulers:DatabaseScheduler',
)


# ============================================================================
# Add to Django settings.py:
# ============================================================================

"""
# Celery Configuration
# https://docs.celeryq.dev/en/stable/django/first-steps-with-django.html

import os

# Broker settings
CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')
CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Serialization
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TIMEZONE = 'UTC'
CELERY_ENABLE_UTC = True

# Task execution
CELERY_TASK_ACKS_LATE = True
CELERY_TASK_REJECT_ON_WORKER_LOST = True
CELERY_TASK_TIME_LIMIT = 5 * 60  # 5 minutes
CELERY_TASK_SOFT_TIME_LIMIT = 4 * 60  # 4 minutes

# Worker settings
CELERY_WORKER_PREFETCH_MULTIPLIER = 4
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000

# Result backend
CELERY_RESULT_EXPIRES = 3600  # 1 hour

# Django Celery Results (optional)
# INSTALLED_APPS += ['django_celery_results']
# CELERY_RESULT_BACKEND = 'django-db'
# CELERY_CACHE_BACKEND = 'django-cache'

# Django Celery Beat (optional)
# INSTALLED_APPS += ['django_celery_beat']
# CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Task routing (optional)
CELERY_TASK_ROUTES = {
    'myapp.tasks.critical_task': {'queue': 'critical'},
    'myapp.tasks.email_task': {'queue': 'emails'},
}

# Beat schedule (if not using django-celery-beat)
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    'cleanup-every-night': {
        'task': 'myapp.tasks.cleanup_old_records',
        'schedule': crontab(hour=2, minute=0),
    },
    'send-reports-monday': {
        'task': 'myapp.tasks.send_weekly_report',
        'schedule': crontab(day_of_week=1, hour=9, minute=0),
    },
}
"""
