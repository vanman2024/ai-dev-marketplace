# Django + Celery Complete Setup Guide

Complete walkthrough for integrating Celery with Django.

## Prerequisites

- Python 3.9+
- Django 4.0+
- Redis or RabbitMQ running
- Existing Django project

## Step 1: Install Dependencies

```bash
pip install celery redis django-celery-results django-celery-beat
```

**Packages:**
- `celery` - Celery task queue
- `redis` - Redis client for Python
- `django-celery-results` - Store task results in Django DB
- `django-celery-beat` - Periodic task scheduler with Django admin

## Step 2: Project Structure

```
myproject/
├── myproject/
│   ├── __init__.py       # Import Celery app here
│   ├── celery.py         # Celery configuration
│   ├── settings.py       # Django + Celery settings
│   └── urls.py
├── myapp/
│   ├── tasks.py          # Task definitions
│   ├── views.py          # Views that call tasks
│   └── models.py
└── manage.py
```

## Step 3: Create celery.py

**File:** `myproject/celery.py`

```python
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')

app = Celery('myproject')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()
```

## Step 4: Update __init__.py

**File:** `myproject/__init__.py`

```python
from .celery import app as celery_app

__all__ = ('celery_app',)
```

## Step 5: Configure settings.py

**Add to:** `myproject/settings.py`

```python
# Celery Configuration
CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')
CELERY_RESULT_BACKEND = 'django-db'  # Store in Django database
CELERY_CACHE_BACKEND = 'django-cache'

CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TIMEZONE = TIME_ZONE
CELERY_ENABLE_UTC = True

CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True

# Add to INSTALLED_APPS
INSTALLED_APPS = [
    # ...
    'django_celery_results',
    'django_celery_beat',
]
```

## Step 6: Run Migrations

```bash
python manage.py migrate django_celery_results
python manage.py migrate django_celery_beat
```

## Step 7: Create Tasks

**File:** `myapp/tasks.py`

```python
from celery import shared_task
from django.core.mail import send_mail
from django.conf import settings

@shared_task
def send_email_task(subject, message, recipient_list):
    send_mail(
        subject=subject,
        message=message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=recipient_list,
    )
    return f"Email sent to {len(recipient_list)} recipients"

@shared_task
def add(x, y):
    return x + y
```

## Step 8: Use Tasks in Views

**File:** `myapp/views.py`

```python
from django.http import JsonResponse
from django.db import transaction
from .tasks import send_email_task
from .models import Order

def create_order(request):
    # Create order
    order = Order.objects.create(
        user=request.user,
        total=100.00
    )

    # Send email AFTER database commit
    transaction.on_commit(
        lambda: send_email_task.delay(
            subject=f'Order #{order.id} Confirmed',
            message='Thank you for your order!',
            recipient_list=[request.user.email]
        )
    )

    return JsonResponse({'order_id': order.id, 'status': 'created'})
```

## Step 9: Start Celery Worker

```bash
# Development
celery -A myproject worker -l info

# Production (with concurrency)
celery -A myproject worker -l info --concurrency=4

# With specific queues
celery -A myproject worker -Q celery,emails,processing -l info
```

## Step 10: Start Celery Beat (Optional)

For periodic tasks:

```bash
celery -A myproject beat -l info
```

## Step 11: Monitor with Flower (Optional)

```bash
pip install flower
celery -A myproject flower
```

Open http://localhost:5555 to view dashboard.

## Common Patterns

### Transaction-Safe Tasks

```python
from django.db import transaction

def my_view(request):
    obj = MyModel.objects.create(name="test")

    # Wait for commit before task
    transaction.on_commit(lambda: process_object.delay(obj.id))

    return HttpResponse("OK")
```

### Periodic Tasks (Admin UI)

1. Go to Django admin: `/admin/`
2. Navigate to "Periodic Tasks"
3. Click "Add Periodic Task"
4. Select task, set schedule
5. Save

### Task with Retry

```python
@shared_task(bind=True, max_retries=3)
def risky_task(self, data):
    try:
        # Operation
        return result
    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)
```

## Testing

```python
# Test in Django shell
python manage.py shell

>>> from myapp.tasks import add
>>> result = add.delay(4, 4)
>>> result.ready()
True
>>> result.result
8
```

## Production Deployment

### Systemd Service

**File:** `/etc/systemd/system/celery.service`

```ini
[Unit]
Description=Celery Service
After=network.target

[Service]
Type=forking
User=www-data
Group=www-data
WorkingDirectory=/path/to/project
ExecStart=/path/to/venv/bin/celery -A myproject worker --detach
Restart=always

[Install]
WantedBy=multi-user.target
```

### Environment Variables

**File:** `.env`

```bash
CELERY_BROKER_URL=redis://your_redis_url_here
DJANGO_SECRET_KEY=your_django_secret_key_here
DATABASE_URL=postgresql://your_database_url_here
```

## Troubleshooting

### Task not running

1. Check worker is running: `celery -A myproject inspect active`
2. Check broker connection: Redis/RabbitMQ running?
3. Check task registered: `celery -A myproject inspect registered`

### "Order does not exist"

Use `transaction.on_commit()` to delay task until DB commit.

### Connection errors

Set `CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True` in settings.

## Resources

- See: `templates/django-integration/` for complete files
- See: `templates/transaction-safe-django.py` for patterns
- Celery docs: https://docs.celeryproject.org/
