# Standalone Python + Celery Setup Guide

Guide for using Celery without a web framework.

## Quick Start

```bash
# Install Celery
pip install celery[redis]

# Create celery_app.py
# Create celeryconfig.py
# Create tasks.py
# Start Redis
# Run: celery -A celery_app worker --loglevel=info
```

## Complete Setup

```python
# celery_app.py
from celery import Celery

app = Celery('myapp')
app.config_from_object('celeryconfig')

# celeryconfig.py
broker_url = 'redis://localhost:6379/0'
result_backend = 'redis://localhost:6379/0'
imports = ['tasks']

# tasks.py
from celery_app import app

@app.task
def add(x, y):
    return x + y

# usage.py
from tasks import add
result = add.delay(4, 6)
print(result.get())
```

For complete patterns, refer to templates/celery-app-standalone.py
