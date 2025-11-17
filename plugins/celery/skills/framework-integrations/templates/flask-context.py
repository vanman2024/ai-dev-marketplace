"""
Flask + Celery application context patterns
Ensures Celery tasks can access Flask extensions (DB, Mail, etc.)

Problem: Celery workers run in separate processes without Flask app context,
causing "RuntimeError: Working outside of application context" errors.

Solution: Create Celery app that automatically pushes Flask app context.
"""

from celery import Celery, Task
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_mail import Mail, Message


# ═══════════════════════════════════════════════════════════════
# Method 1: Factory Pattern with Context-Aware Tasks (RECOMMENDED)
# ═══════════════════════════════════════════════════════════════

def create_app():
    """Flask application factory"""
    app = Flask(__name__)

    # Configuration
    app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://your_database_url_here'
    app.config['CELERY_BROKER_URL'] = 'redis://your_redis_url_here'
    app.config['CELERY_RESULT_BACKEND'] = 'redis://your_redis_url_here'
    app.config['MAIL_SERVER'] = 'smtp.example.com'
    app.config['MAIL_PORT'] = 587

    # Initialize extensions
    db = SQLAlchemy(app)
    mail = Mail(app)

    return app, db, mail


def make_celery(app):
    """
    Create Celery app with Flask context
    Tasks automatically run within Flask app context
    """

    class ContextTask(Task):
        """Base task that pushes app context"""

        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery = Celery(
        app.import_name,
        task_cls=ContextTask,
    )
    celery.config_from_object(app.config, namespace='CELERY')
    return celery


# Create app and Celery instance
app, db, mail = create_app()
celery = make_celery(app)


# ✅ CORRECT: Tasks automatically have Flask context
@celery.task
def send_email_task(recipient, subject, body):
    """
    Send email using Flask-Mail
    Context is automatically available
    """
    msg = Message(
        subject=subject,
        recipients=[recipient],
        body=body
    )
    mail.send(msg)
    return f"Email sent to {recipient}"


@celery.task
def update_user_task(user_id, data):
    """
    Update user in database
    Database session is automatically available
    """
    from models import User  # Import inside task

    user = User.query.get(user_id)
    if user:
        user.name = data.get('name', user.name)
        user.email = data.get('email', user.email)
        db.session.commit()
        return f"User {user_id} updated"
    return f"User {user_id} not found"


# ═══════════════════════════════════════════════════════════════
# Method 2: Manual Context Management
# ═══════════════════════════════════════════════════════════════

def create_simple_celery(app_name):
    """Create Celery without automatic context"""
    return Celery(app_name)


simple_celery = create_simple_celery('myapp')
simple_celery.config_from_object(app.config, namespace='CELERY')


@simple_celery.task
def send_email_manual_context(recipient, subject, body):
    """
    ✅ CORRECT: Manually push context when needed
    """
    with app.app_context():
        msg = Message(
            subject=subject,
            recipients=[recipient],
            body=body
        )
        mail.send(msg)
    return f"Email sent to {recipient}"


@simple_celery.task
def process_data_manual(data):
    """
    ✅ CORRECT: Use context only when accessing Flask extensions
    """
    # Processing that doesn't need context
    processed = data.upper()

    # Only push context when needed
    with app.app_context():
        # Access database
        result = save_to_database(processed)

    return result


# ❌ WRONG: No context pushed
@simple_celery.task
def broken_task(user_id):
    """This will fail with "Working outside of application context" """
    from models import User
    user = User.query.get(user_id)  # ERROR: No app context!
    return user.name


# ═══════════════════════════════════════════════════════════════
# Method 3: Context for Specific Operations
# ═══════════════════════════════════════════════════════════════

@celery.task
def mixed_context_task(user_id, external_api_url):
    """
    Task with both context-dependent and context-free operations
    """
    # Part 1: No context needed
    import requests
    response = requests.get(external_api_url)
    data = response.json()

    # Part 2: Need context for database
    with app.app_context():
        from models import User
        user = User.query.get(user_id)
        user.external_data = data
        db.session.commit()

    # Part 3: No context needed
    return f"Updated user {user_id} with external data"


# ═══════════════════════════════════════════════════════════════
# Real-World Examples
# ═══════════════════════════════════════════════════════════════

@celery.task
def generate_report_task(report_id):
    """
    Generate PDF report with database data
    """
    from models import Report, User
    from reportlab.pdfgen import canvas
    import io

    # Fetch data (needs context)
    report = Report.query.get(report_id)
    users = User.query.filter_by(active=True).all()

    # Generate PDF (no context needed)
    buffer = io.BytesIO()
    pdf = canvas.Canvas(buffer)
    pdf.drawString(100, 750, f"Report: {report.title}")

    for i, user in enumerate(users):
        pdf.drawString(100, 700 - (i * 20), f"{user.name} - {user.email}")

    pdf.save()

    # Save PDF (needs context)
    report.pdf_data = buffer.getvalue()
    db.session.commit()

    return f"Report {report_id} generated"


@celery.task
def cleanup_old_records_task():
    """
    Clean up old records from database
    """
    from datetime import datetime, timedelta
    from models import Session

    cutoff_date = datetime.utcnow() - timedelta(days=30)

    # Delete old sessions
    deleted = Session.query.filter(
        Session.created_at < cutoff_date
    ).delete()

    db.session.commit()

    return f"Deleted {deleted} old sessions"


@celery.task
def send_bulk_emails_task(user_ids, subject, template):
    """
    Send bulk emails to multiple users
    """
    from models import User

    users = User.query.filter(User.id.in_(user_ids)).all()

    results = []
    for user in users:
        try:
            body = template.format(name=user.name)
            msg = Message(
                subject=subject,
                recipients=[user.email],
                body=body
            )
            mail.send(msg)
            results.append(f"Sent to {user.email}")
        except Exception as e:
            results.append(f"Failed for {user.email}: {str(e)}")

    return results


# ═══════════════════════════════════════════════════════════════
# Configuration Example (config.py)
# ═══════════════════════════════════════════════════════════════

"""
# config.py

import os

class Config:
    # Flask
    SECRET_KEY = os.getenv('SECRET_KEY', 'your_secret_key_here')

    # Database
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        'postgresql://your_database_url_here'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Celery
    CELERY_BROKER_URL = os.getenv(
        'CELERY_BROKER_URL',
        'redis://your_redis_url_here'
    )
    CELERY_RESULT_BACKEND = os.getenv(
        'CELERY_RESULT_BACKEND',
        'redis://your_redis_url_here'
    )

    # Mail
    MAIL_SERVER = os.getenv('MAIL_SERVER', 'smtp.example.com')
    MAIL_PORT = int(os.getenv('MAIL_PORT', 587))
    MAIL_USE_TLS = True
    MAIL_USERNAME = os.getenv('MAIL_USERNAME', 'your_email_username_here')
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD', 'your_email_password_here')

class DevelopmentConfig(Config):
    DEBUG = True

class ProductionConfig(Config):
    DEBUG = False
"""


# ═══════════════════════════════════════════════════════════════
# Project Structure
# ═══════════════════════════════════════════════════════════════

"""
myapp/
├── __init__.py          # Flask app factory
├── celery.py            # Celery app with make_celery()
├── tasks.py             # Task definitions
├── models.py            # SQLAlchemy models
├── views.py             # Flask routes
├── config.py            # Configuration classes
└── requirements.txt     # Dependencies

# __init__.py
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from .celery import make_celery

db = SQLAlchemy()

def create_app(config_name='development'):
    app = Flask(__name__)
    app.config.from_object(f'config.{config_name.capitalize()}Config')

    db.init_app(app)

    with app.app_context():
        from . import views
        app.register_blueprint(views.bp)

    return app

# celery.py
from . import create_app
from .celery_utils import make_celery

app = create_app()
celery = make_celery(app)
"""


# Best Practices Summary
"""
1. Use factory pattern with ContextTask for automatic context
2. Only push context when accessing Flask extensions
3. Import models inside tasks, not at module level
4. Use make_celery() helper for cleaner setup
5. Share configuration between Flask and Celery
6. Test tasks both in sync and async modes

Common Issues:
- "Working outside of application context" → Add with app.app_context()
- "No application found" → Use factory pattern with make_celery()
- Import errors → Import models inside tasks
- Config not loaded → Use config_from_object with namespace
"""


def save_to_database(data):
    """Helper function for examples"""
    from models import ProcessedData
    record = ProcessedData(data=data)
    db.session.add(record)
    db.session.commit()
    return record.id
