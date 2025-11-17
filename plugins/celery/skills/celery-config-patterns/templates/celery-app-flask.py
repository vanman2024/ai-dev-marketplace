"""
Flask Celery Application Configuration

This configuration supports Flask's application factory pattern.

Usage:
    1. Copy this file to your project as celery_app.py
    2. Import and initialize with Flask app
    3. Run: celery -A celery_app worker --loglevel=info

For Flask application factory pattern, see example below.
"""

import os
from celery import Celery


def make_celery(app=None):
    """
    Create Celery instance and integrate with Flask app.

    Supports both direct app creation and app factory pattern.

    Args:
        app: Flask application instance (optional)

    Returns:
        Celery application instance
    """
    celery = Celery(
        app.import_name if app else 'flask_app',
        broker=os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0'),
        backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0'),
    )

    if app:
        # Update Celery config from Flask config
        celery.conf.update(app.config)

        # Ensure tasks have access to Flask app context
        class ContextTask(celery.Task):
            """Make celery tasks work with Flask app context"""
            def __call__(self, *args, **kwargs):
                with app.app_context():
                    return self.run(*args, **kwargs)

        celery.Task = ContextTask
    else:
        # Configure directly when no Flask app provided
        celery.conf.update(
            task_serializer='json',
            accept_content=['json'],
            result_serializer='json',
            timezone='UTC',
            enable_utc=True,
            task_acks_late=True,
            task_reject_on_worker_lost=True,
            task_time_limit=300,
            task_soft_time_limit=240,
            worker_prefetch_multiplier=4,
            worker_max_tasks_per_child=1000,
            result_expires=3600,
        )

    return celery


# For standalone usage (not recommended)
celery = make_celery()


# ============================================================================
# Flask Application Factory Pattern Example
# ============================================================================

"""
# app/__init__.py

from flask import Flask
from celery_app import make_celery

celery = None

def create_app(config_name='development'):
    app = Flask(__name__)

    # Load configuration
    app.config.from_object(f'config.{config_name}')

    # Initialize Celery with Flask app
    global celery
    celery = make_celery(app)

    # Register blueprints
    from .main import main as main_blueprint
    app.register_blueprint(main_blueprint)

    return app


# config.py

import os

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')

    # Celery configuration
    CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')
    CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')
    CELERY_TASK_SERIALIZER = 'json'
    CELERY_RESULT_SERIALIZER = 'json'
    CELERY_ACCEPT_CONTENT = ['json']
    CELERY_TIMEZONE = 'UTC'
    CELERY_ENABLE_UTC = True


# app/tasks.py

from app import celery

@celery.task(name='app.tasks.send_email')
def send_email(to, subject, body):
    # Task implementation
    pass

@celery.task(bind=True, name='app.tasks.process_data')
def process_data(self, data):
    try:
        # Process data
        result = perform_processing(data)
        return result
    except Exception as exc:
        # Retry with exponential backoff
        raise self.retry(exc=exc, countdown=2 ** self.request.retries)


# wsgi.py (for running Flask)

from app import create_app

app = create_app('production')

if __name__ == '__main__':
    app.run()


# celery_worker.py (for running Celery worker)

from app import create_app, celery

app = create_app('production')
app.app_context().push()

if __name__ == '__main__':
    celery.worker_main(['worker', '--loglevel=info'])


# Run commands:
# Flask: flask run
# Celery: celery -A celery_worker:celery worker --loglevel=info
"""


# ============================================================================
# Simple Flask App Example (No Factory Pattern)
# ============================================================================

"""
# app.py

from flask import Flask
from celery_app import make_celery

app = Flask(__name__)
app.config['CELERY_BROKER_URL'] = 'redis://localhost:6379/0'
app.config['CELERY_RESULT_BACKEND'] = 'redis://localhost:6379/0'

celery = make_celery(app)

@celery.task
def add_together(a, b):
    return a + b

@app.route('/')
def index():
    result = add_together.delay(5, 3)
    return f'Task ID: {result.id}'

if __name__ == '__main__':
    app.run(debug=True)


# Run commands:
# Flask: python app.py
# Celery: celery -A app:celery worker --loglevel=info
"""
