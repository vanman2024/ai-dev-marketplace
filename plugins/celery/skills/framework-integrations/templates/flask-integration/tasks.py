"""
Flask Celery tasks
"""

from celery_app import celery, app
from flask_mail import Message, Mail

mail = Mail(app)


@celery.task
def send_email(recipient, subject, body):
    """
    Send email using Flask-Mail
    App context is automatically available
    """
    msg = Message(
        subject=subject,
        recipients=[recipient],
        body=body
    )
    mail.send(msg)
    return f"Email sent to {recipient}"


@celery.task
def process_data(data):
    """
    Process data with database access
    """
    # Access Flask extensions within task
    from models import DataRecord
    from extensions import db

    record = DataRecord(data=data)
    db.session.add(record)
    db.session.commit()

    return f"Processed data: {data}"
