"""
Standalone Celery Application Configuration

This is a basic Celery app configuration for standalone Python applications
without web framework integration.

Usage:
    1. Copy this file to your project as celery_app.py
    2. Create celeryconfig.py with broker and backend settings
    3. Create tasks.py with your task definitions
    4. Run: celery -A celery_app worker --loglevel=info
"""

import os
from celery import Celery

# Get configuration from environment or use defaults
BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')
RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Create Celery application
app = Celery('standalone_app')

# Load configuration from celeryconfig.py module
app.config_from_object('celeryconfig')

# Or configure directly (for simple cases)
app.conf.update(
    broker_url=BROKER_URL,
    result_backend=RESULT_BACKEND,
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,

    # Task execution settings
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    task_time_limit=300,  # 5 minutes hard limit
    task_soft_time_limit=240,  # 4 minutes soft limit

    # Worker settings
    worker_prefetch_multiplier=4,
    worker_max_tasks_per_child=1000,

    # Broker settings
    broker_connection_retry_on_startup=True,
    broker_pool_limit=10,

    # Result backend settings
    result_expires=3600,  # Results expire after 1 hour
    result_persistent=False,

    # Task discovery
    imports=['tasks'],  # Import tasks from tasks.py
)

# Optional: Auto-discover tasks from multiple modules
# app.autodiscover_tasks(['myapp', 'myapp.module1', 'myapp.module2'])

# Optional: Add task for testing
@app.task(bind=True)
def debug_task(self):
    """Debug task that prints request information"""
    print(f'Request: {self.request!r}')
    return 'Debug task executed successfully'


if __name__ == '__main__':
    # Start worker programmatically (not recommended for production)
    app.worker_main(['worker', '--loglevel=info'])
