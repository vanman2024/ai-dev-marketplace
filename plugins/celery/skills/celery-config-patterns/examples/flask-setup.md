# Flask + Celery Complete Setup Guide

Comprehensive guide for integrating Celery with Flask applications using the factory pattern.

## Quick Start

```bash
# Install dependencies
pip install celery[redis] flask

# Create celery_app.py
# Create app.py with Flask app
# Start Redis
# Run: celery -A celery_app worker --loglevel=info
# Run: flask run
```

## Complete Setup

See Django setup guide for detailed explanations. Flask follows similar patterns with application factory support.

## Key Differences from Django

1. Use `make_celery()` factory function
2. Configure via Flask config object
3. Manual task discovery (no auto-discovery)
4. Flask app context handling in tasks

## Factory Pattern Example

```python
# celery_app.py
from celery import Celery

def make_celery(app):
    celery = Celery(app.import_name)
    celery.conf.update(app.config)

    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask
    return celery

# app.py
from flask import Flask
from celery_app import make_celery

app = Flask(__name__)
app.config['CELERY_BROKER_URL'] = 'redis://localhost:6379/0'
celery = make_celery(app)
```

For complete patterns, refer to templates/celery-app-flask.py
