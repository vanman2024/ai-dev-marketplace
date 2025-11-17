# Django + Celery Complete Setup Guide

This guide walks through setting up Celery with Django, from installation to production deployment.

## Prerequisites

- Django project already initialized
- Python 3.8+
- Redis or RabbitMQ running (this guide uses Redis)

## Step 1: Install Dependencies

```bash
# Install Celery with Redis support
pip install celery[redis]

# Optional: For database-backed periodic tasks
pip install django-celery-beat

# Optional: For database-backed results
pip install django-celery-results

# Update requirements.txt
pip freeze > requirements.txt
```

## Step 2: Create Celery Application

Create `myproject/celery.py` (where `myproject` is your Django project directory with `settings.py`):

```python
# myproject/celery.py

import os
from celery import Celery

# Set default Django settings module for Celery
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')

# Create Celery application
app = Celery('myproject')

# Load configuration from Django settings (namespace='CELERY')
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks from all installed Django apps
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
```

## Step 3: Update Project __init__.py

Ensure Celery app is loaded when Django starts.

```python
# myproject/__init__.py

# This will make sure the app is always imported when Django starts
from .celery import app as celery_app

__all__ = ('celery_app',)
```

## Step 4: Add Celery Configuration to settings.py

```python
# myproject/settings.py

import os

# ============================================================================
# Celery Configuration
# ============================================================================

# Broker settings
CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')
CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Serialization
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TIMEZONE = 'UTC'
CELERY_ENABLE_UTC = True

# Task execution settings
CELERY_TASK_ACKS_LATE = True
CELERY_TASK_REJECT_ON_WORKER_LOST = True
CELERY_TASK_TIME_LIMIT = 5 * 60  # 5 minutes hard limit
CELERY_TASK_SOFT_TIME_LIMIT = 4 * 60  # 4 minutes soft limit

# Worker settings
CELERY_WORKER_PREFETCH_MULTIPLIER = 4
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000

# Result backend settings
CELERY_RESULT_EXPIRES = 3600  # 1 hour

# Optional: Use Django database for results
# INSTALLED_APPS += ['django_celery_results']
# CELERY_RESULT_BACKEND = 'django-db'
# CELERY_CACHE_BACKEND = 'django-cache'

# Optional: Use Django database for periodic tasks
# INSTALLED_APPS += ['django_celery_beat']
# CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Task routing (optional)
CELERY_TASK_ROUTES = {
    'myapp.tasks.send_email': {'queue': 'emails'},
    'myapp.tasks.process_data': {'queue': 'processing'},
}

# Beat schedule (if not using django-celery-beat)
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    'cleanup-every-night': {
        'task': 'myapp.tasks.cleanup_old_records',
        'schedule': crontab(hour=2, minute=0),
        'args': (),
    },
}
```

## Step 5: Create Environment File

```bash
# .env.example (safe to commit)
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0
SECRET_KEY=your_django_secret_key_here
```

```bash
# .env (DO NOT commit - add to .gitignore)
CELERY_BROKER_URL=redis://:your_redis_password_here@localhost:6379/0
CELERY_RESULT_BACKEND=redis://:your_redis_password_here@localhost:6379/0
SECRET_KEY=actual_secret_key_here
```

## Step 6: Create Tasks in Django Apps

```python
# myapp/tasks.py

from celery import shared_task
from django.core.mail import send_mail
from .models import MyModel
import logging

logger = logging.getLogger(__name__)


@shared_task
def send_welcome_email(user_email):
    """Send welcome email to new user"""
    send_mail(
        'Welcome!',
        'Thank you for signing up.',
        'noreply@example.com',
        [user_email],
        fail_silently=False,
    )
    return f"Email sent to {user_email}"


@shared_task(bind=True, max_retries=3)
def process_uploaded_file(self, file_id):
    """Process uploaded file with retry logic"""
    try:
        # Get file from database
        from .models import UploadedFile
        file_obj = UploadedFile.objects.get(id=file_id)

        # Process file
        # ... processing logic ...

        file_obj.status = 'processed'
        file_obj.save()

        return f"File {file_id} processed successfully"

    except UploadedFile.DoesNotExist:
        logger.error(f"File {file_id} not found")
        raise

    except Exception as exc:
        logger.error(f"Error processing file {file_id}: {exc}")
        raise self.retry(exc=exc, countdown=60)


@shared_task
def cleanup_old_records():
    """Periodic task to clean up old records"""
    from datetime import timedelta
    from django.utils import timezone

    cutoff_date = timezone.now() - timedelta(days=30)
    deleted_count = MyModel.objects.filter(created_at__lt=cutoff_date).delete()[0]

    logger.info(f"Deleted {deleted_count} old records")
    return deleted_count
```

## Step 7: Use Tasks in Views

```python
# myapp/views.py

from django.http import JsonResponse
from django.views import View
from .tasks import send_welcome_email, process_uploaded_file


class SignupView(View):
    def post(self, request):
        # ... user signup logic ...

        # Send welcome email asynchronously
        send_welcome_email.delay(user.email)

        return JsonResponse({'status': 'success'})


class FileUploadView(View):
    def post(self, request):
        # ... file upload logic ...

        # Process file asynchronously
        task = process_uploaded_file.delay(uploaded_file.id)

        return JsonResponse({
            'status': 'processing',
            'task_id': task.id
        })


class TaskStatusView(View):
    def get(self, request, task_id):
        from celery.result import AsyncResult

        task = AsyncResult(task_id)

        return JsonResponse({
            'task_id': task_id,
            'status': task.status,
            'result': task.result if task.ready() else None
        })
```

## Step 8: Run Migrations (if using django-celery-beat or django-celery-results)

```bash
# Apply migrations for django-celery-beat
python manage.py migrate django_celery_beat

# Apply migrations for django-celery-results
python manage.py migrate django_celery_results
```

## Step 9: Start Celery Worker

```bash
# Development
celery -A myproject worker --loglevel=info

# Production (with concurrency)
celery -A myproject worker --loglevel=info --concurrency=4

# Multiple queues
celery -A myproject worker -Q default,emails,processing --loglevel=info
```

## Step 10: Start Celery Beat (for periodic tasks)

```bash
# Development
celery -A myproject beat --loglevel=info

# Production (with persistent schedule)
celery -A myproject beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

## Production Deployment

### Using Supervisor

```ini
; /etc/supervisor/conf.d/celery.conf

[program:celery-worker]
command=/path/to/venv/bin/celery -A myproject worker --loglevel=info
directory=/path/to/project
user=www-data
numprocs=1
autostart=true
autorestart=true
startsecs=10
stopwaitsecs=600
killasgroup=true
priority=999

[program:celery-beat]
command=/path/to/venv/bin/celery -A myproject beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
directory=/path/to/project
user=www-data
numprocs=1
autostart=true
autorestart=true
startsecs=10
stopwaitsecs=600
killasgroup=true
priority=998
```

### Using Systemd

```ini
# /etc/systemd/system/celery.service

[Unit]
Description=Celery Worker Service
After=network.target redis.target

[Service]
Type=forking
User=www-data
Group=www-data
WorkingDirectory=/path/to/project
Environment="DJANGO_SETTINGS_MODULE=myproject.settings"
Environment="CELERY_BROKER_URL=redis://localhost:6379/0"
ExecStart=/path/to/venv/bin/celery -A myproject worker --loglevel=info --logfile=/var/log/celery/worker.log --pidfile=/var/run/celery/worker.pid
ExecStop=/path/to/venv/bin/celery multi stopwait worker --pidfile=/var/run/celery/worker.pid
Restart=always

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/celery-beat.service

[Unit]
Description=Celery Beat Service
After=network.target redis.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/path/to/project
Environment="DJANGO_SETTINGS_MODULE=myproject.settings"
Environment="CELERY_BROKER_URL=redis://localhost:6379/0"
ExecStart=/path/to/venv/bin/celery -A myproject beat --loglevel=info --logfile=/var/log/celery/beat.log --pidfile=/var/run/celery/beat.pid
Restart=always

[Install]
WantedBy=multi-user.target
```

### Docker Compose

```yaml
# docker-compose.yml

version: '3.8'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_DB: myproject
      POSTGRES_USER: myproject
      POSTGRES_PASSWORD: your_db_password_here
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass your_redis_password_here

  web:
    build: .
    command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://myproject:your_db_password_here@db:5432/myproject
      - CELERY_BROKER_URL=redis://:your_redis_password_here@redis:6379/0
      - CELERY_RESULT_BACKEND=redis://:your_redis_password_here@redis:6379/0
    depends_on:
      - db
      - redis

  celery_worker:
    build: .
    command: celery -A myproject worker --loglevel=info
    volumes:
      - .:/app
    environment:
      - DATABASE_URL=postgresql://myproject:your_db_password_here@db:5432/myproject
      - CELERY_BROKER_URL=redis://:your_redis_password_here@redis:6379/0
      - CELERY_RESULT_BACKEND=redis://:your_redis_password_here@redis:6379/0
    depends_on:
      - db
      - redis

  celery_beat:
    build: .
    command: celery -A myproject beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler
    volumes:
      - .:/app
    environment:
      - DATABASE_URL=postgresql://myproject:your_db_password_here@db:5432/myproject
      - CELERY_BROKER_URL=redis://:your_redis_password_here@redis:6379/0
      - CELERY_RESULT_BACKEND=redis://:your_redis_password_here@redis:6379/0
    depends_on:
      - db
      - redis

volumes:
  postgres_data:
```

## Monitoring with Flower

```bash
# Install Flower
pip install flower

# Start Flower
celery -A myproject flower

# Access dashboard at: http://localhost:5555
```

## Testing

```python
# myapp/tests/test_tasks.py

from django.test import TestCase
from myapp.tasks import send_welcome_email, cleanup_old_records


class TaskTests(TestCase):
    def test_send_welcome_email(self):
        """Test email sending task"""
        result = send_welcome_email.delay('test@example.com')
        result.get(timeout=10)
        self.assertEqual(result.status, 'SUCCESS')

    def test_cleanup_old_records(self):
        """Test cleanup task"""
        # Create test data
        # ...

        result = cleanup_old_records.delay()
        deleted_count = result.get(timeout=10)
        self.assertGreater(deleted_count, 0)
```

## Troubleshooting

### Worker not discovering tasks

```bash
# Check registered tasks
celery -A myproject inspect registered

# Force task discovery
celery -A myproject worker --loglevel=debug
```

### Connection issues

```bash
# Test Redis connection
redis-cli ping

# Check Celery can connect
celery -A myproject inspect ping
```

### Tasks not executing

```bash
# Check active tasks
celery -A myproject inspect active

# Check scheduled tasks
celery -A myproject inspect scheduled

# Purge all tasks
celery -A myproject purge
```

## Best Practices

1. **Use `shared_task` decorator** for reusable tasks
2. **Always use `delay()` or `apply_async()`** to run tasks asynchronously
3. **Set time limits** to prevent runaway tasks
4. **Use retry logic** for unreliable operations
5. **Monitor with Flower** in production
6. **Use database scheduler** for dynamic periodic tasks
7. **Route tasks to different queues** based on priority
8. **Use `bind=True`** when you need task metadata
9. **Log task execution** for debugging
10. **Test tasks independently** of your web application

## Complete Example

See the full example project structure in the Django Celery cookbook.
