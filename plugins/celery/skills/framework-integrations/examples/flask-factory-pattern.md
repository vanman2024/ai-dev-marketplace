# Flask + Celery Factory Pattern Guide

Complete guide for integrating Celery with Flask using the factory pattern.

## Why Factory Pattern?

- Supports multiple Flask instances (testing, production)
- Proper application context handling
- Modular and testable
- Flask extensions work correctly in tasks

## Project Structure

```
myapp/
├── __init__.py          # Flask app factory
├── celery_app.py        # Celery factory
├── tasks.py             # Task definitions
├── views.py             # Routes
├── models.py            # Database models
├── extensions.py        # Flask extensions
├── config.py            # Configuration
└── run.py               # Application entry point
```

## Step 1: Install Dependencies

```bash
pip install celery flask flask-sqlalchemy flask-mail redis
```

## Step 2: Create Extensions

**File:** `myapp/extensions.py`

```python
from flask_sqlalchemy import SQLAlchemy
from flask_mail import Mail

db = SQLAlchemy()
mail = Mail()
```

## Step 3: Create Configuration

**File:** `myapp/config.py`

```python
import os

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'your_secret_key_here')

    # Database
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        'postgresql://your_database_url_here'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Celery
    CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')
    CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

    # Mail
    MAIL_SERVER = os.getenv('MAIL_SERVER', 'smtp.example.com')
    MAIL_PORT = int(os.getenv('MAIL_PORT', 587))
    MAIL_USE_TLS = True
    MAIL_USERNAME = os.getenv('MAIL_USERNAME', 'your_email_username_here')
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD', 'your_email_password_here')
```

## Step 4: Create Flask Factory

**File:** `myapp/__init__.py`

```python
from flask import Flask
from .extensions import db, mail
from .config import Config

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize extensions
    db.init_app(app)
    mail.init_app(app)

    # Register blueprints
    from .views import main_bp
    app.register_blueprint(main_bp)

    return app
```

## Step 5: Create Celery Factory

**File:** `myapp/celery_app.py`

```python
from celery import Celery, Task
from flask import Flask

def create_celery_app(app: Flask) -> Celery:
    """
    Create Celery app with Flask context
    """

    class ContextTask(Task):
        """Task that runs within Flask app context"""

        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery = Celery(
        app.import_name,
        task_cls=ContextTask,
    )

    celery.config_from_object(app.config, namespace='CELERY')
    celery.set_default()

    return celery
```

## Step 6: Initialize Both Apps

**File:** `myapp/worker.py`

```python
from myapp import create_app
from myapp.celery_app import create_celery_app

# Create Flask app
flask_app = create_app()

# Create Celery app with Flask context
celery = create_celery_app(flask_app)
```

## Step 7: Define Tasks

**File:** `myapp/tasks.py`

```python
from myapp.worker import celery
from myapp.extensions import db, mail
from flask_mail import Message

@celery.task
def send_email(recipient, subject, body):
    """
    Send email - app context automatically available
    """
    msg = Message(
        subject=subject,
        recipients=[recipient],
        body=body
    )
    mail.send(msg)
    return f"Email sent to {recipient}"

@celery.task
def process_user_data(user_id):
    """
    Process user data with database access
    """
    from myapp.models import User

    user = User.query.get(user_id)
    if not user:
        return f"User {user_id} not found"

    # Process user
    user.processed = True
    db.session.commit()

    return f"Processed user {user_id}"
```

## Step 8: Create Views

**File:** `myapp/views.py`

```python
from flask import Blueprint, request, jsonify
from .tasks import send_email, process_user_data
from .extensions import db
from .models import User

main_bp = Blueprint('main', __name__)

@main_bp.route('/send-email', methods=['POST'])
def send_email_route():
    data = request.json
    task = send_email.delay(
        recipient=data['email'],
        subject=data['subject'],
        body=data['body']
    )
    return jsonify({'task_id': task.id})

@main_bp.route('/process-user/<int:user_id>', methods=['POST'])
def process_user_route(user_id):
    task = process_user_data.delay(user_id)
    return jsonify({'task_id': task.id, 'status': 'queued'})
```

## Step 9: Application Entry Point

**File:** `run.py`

```python
from myapp import create_app

app = create_app()

if __name__ == '__main__':
    app.run(debug=True)
```

## Step 10: Run Application

### Terminal 1: Flask App
```bash
python run.py
```

### Terminal 2: Celery Worker
```bash
celery -A myapp.worker.celery worker -l info
```

## Testing

```python
# test_tasks.py
import pytest
from myapp import create_app
from myapp.celery_app import create_celery_app
from myapp.tasks import send_email

@pytest.fixture
def app():
    app = create_app()
    app.config['TESTING'] = True
    return app

@pytest.fixture
def celery_app(app):
    return create_celery_app(app)

def test_send_email(celery_app):
    result = send_email.apply(args=['test@example.com', 'Test', 'Body'])
    assert 'Email sent' in result.get()
```

## Advanced: Multiple Instances

```python
# Different configs for different environments
from myapp.config import DevelopmentConfig, ProductionConfig

# Development
dev_app = create_app(DevelopmentConfig)
dev_celery = create_celery_app(dev_app)

# Production
prod_app = create_app(ProductionConfig)
prod_celery = create_celery_app(prod_app)
```

## Common Issues

### "Working outside of application context"

**Solution:** Make sure you're using the ContextTask pattern:

```python
class ContextTask(Task):
    def __call__(self, *args, **kwargs):
        with app.app_context():
            return self.run(*args, **kwargs)
```

### Import Errors

**Solution:** Import models inside tasks, not at module level:

```python
@celery.task
def process_data():
    from myapp.models import Data  # Import here
    # Use Data model
```

### Extensions Not Initialized

**Solution:** Make sure `create_celery_app()` is called with initialized Flask app.

## Production Deployment

### Gunicorn + Celery

```bash
# Terminal 1: Flask with Gunicorn
gunicorn -w 4 -b 0.0.0.0:8000 run:app

# Terminal 2: Celery worker
celery -A myapp.worker.celery worker -l info --concurrency=4
```

### Docker Compose

```yaml
version: '3.8'
services:
  redis:
    image: redis:alpine

  flask:
    build: .
    command: gunicorn -w 4 -b 0.0.0.0:8000 run:app
    ports:
      - "8000:8000"
    depends_on:
      - redis

  celery:
    build: .
    command: celery -A myapp.worker.celery worker -l info
    depends_on:
      - redis
```

## Resources

- See: `templates/flask-integration/` for complete files
- See: `templates/flask-context.py` for context patterns
- Flask docs: https://flask.palletsprojects.com/
- Celery docs: https://docs.celeryproject.org/
