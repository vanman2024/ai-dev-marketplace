"""
Celery configuration for Django project

This file should be placed in the same directory as settings.py
(your project root directory alongside __init__.py)

Example structure:
myproject/
├── myproject/
│   ├── __init__.py       # Import celery app
│   ├── celery.py         # This file
│   ├── settings.py
│   └── urls.py
└── manage.py
"""

import os
from celery import Celery

# Set default Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')

# Create Celery app
app = Celery('myproject')

# Load configuration from Django settings with CELERY_ namespace
# This means all Celery config keys in settings.py should start with CELERY_
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks from all installed Django apps
# Looks for tasks.py in each app directory
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    """Debug task for testing Celery setup"""
    print(f'Request: {self.request!r}')
