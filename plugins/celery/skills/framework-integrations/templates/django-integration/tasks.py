"""
Example tasks for Django app
Place this file in your Django app directory (e.g., myapp/tasks.py)
"""

from celery import shared_task
from django.core.mail import send_mail
from django.conf import settings
from django.db import transaction
from .models import Order, User, Report
import time


# ════════════════════════════════════════════════════════════════
# Basic Tasks
# ════════════════════════════════════════════════════════════════

@shared_task
def add(x, y):
    """Simple test task"""
    return x + y


@shared_task
def send_email(subject, message, recipient_list):
    """
    Send email using Django's email backend
    """
    send_mail(
        subject=subject,
        message=message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=recipient_list,
        fail_silently=False,
    )
    return f"Email sent to {len(recipient_list)} recipients"


# ════════════════════════════════════════════════════════════════
# Transaction-Safe Tasks (IMPORTANT!)
# ════════════════════════════════════════════════════════════════

@shared_task
def process_order(order_id):
    """
    Process order after it's been committed to database
    This task should be called with transaction.on_commit()

    Example usage in views.py:
        order = Order.objects.create(...)
        transaction.on_commit(lambda: process_order.delay(order.id))
    """
    try:
        order = Order.objects.get(id=order_id)
        order.status = 'processing'
        order.save()

        # Simulate processing
        time.sleep(2)

        order.status = 'completed'
        order.save()

        # Send confirmation email
        send_email.delay(
            subject=f'Order #{order.id} Confirmed',
            message=f'Your order has been processed successfully.',
            recipient_list=[order.user.email]
        )

        return f"Order {order_id} processed successfully"

    except Order.DoesNotExist:
        raise Exception(f"Order {order_id} not found")


@shared_task
def send_order_confirmation(order_id):
    """
    Send order confirmation email
    Must be called after database commit
    """
    order = Order.objects.select_related('user').get(id=order_id)

    send_mail(
        subject=f'Order Confirmation - #{order.id}',
        message=f'Thank you for your order!\n\nOrder ID: {order.id}\nTotal: ${order.total}',
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[order.user.email],
    )

    return f"Confirmation sent for order {order_id}"


# ════════════════════════════════════════════════════════════════
# Tasks with Retry Logic
# ════════════════════════════════════════════════════════════════

@shared_task(bind=True, max_retries=3)
def send_notification(self, user_id, message):
    """
    Send notification with automatic retry
    """
    try:
        user = User.objects.get(id=user_id)

        # Simulate sending notification
        time.sleep(1)

        # Send email notification
        send_mail(
            subject='Notification',
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
        )

        return f"Notification sent to user {user_id}"

    except Exception as exc:
        # Retry with exponential backoff
        countdown = 60 * (2 ** self.request.retries)  # 60s, 120s, 240s
        raise self.retry(exc=exc, countdown=countdown)


@shared_task(bind=True, autoretry_for=(Exception,), retry_kwargs={'max_retries': 5, 'countdown': 60})
def fetch_external_data(self, api_url):
    """
    Fetch data from external API with automatic retry
    """
    import requests

    response = requests.get(api_url, timeout=30)
    response.raise_for_status()

    return response.json()


# ════════════════════════════════════════════════════════════════
# Progress Tracking
# ════════════════════════════════════════════════════════════════

@shared_task(bind=True)
def generate_report(self, user_id):
    """
    Generate report with progress updates
    """
    total_steps = 100

    for i in range(total_steps):
        time.sleep(0.1)  # Simulate work

        # Update progress
        self.update_state(
            state='PROGRESS',
            meta={
                'current': i + 1,
                'total': total_steps,
                'status': f'Processing step {i + 1} of {total_steps}'
            }
        )

    # Create report record
    report = Report.objects.create(
        user_id=user_id,
        status='completed',
        data={'total_steps': total_steps}
    )

    return {
        'current': total_steps,
        'total': total_steps,
        'status': 'complete',
        'report_id': report.id
    }


# ════════════════════════════════════════════════════════════════
# Bulk Operations
# ════════════════════════════════════════════════════════════════

@shared_task
def send_bulk_emails(user_ids, subject, message):
    """
    Send emails to multiple users
    """
    users = User.objects.filter(id__in=user_ids)
    recipient_list = [user.email for user in users]

    send_mail(
        subject=subject,
        message=message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=recipient_list,
    )

    return f"Sent email to {len(recipient_list)} users"


@shared_task
def cleanup_old_sessions():
    """
    Clean up old session data
    Suitable for periodic task (Celery Beat)
    """
    from django.contrib.sessions.models import Session
    from django.utils import timezone

    expired_sessions = Session.objects.filter(expire_date__lt=timezone.now())
    count = expired_sessions.count()
    expired_sessions.delete()

    return f"Deleted {count} expired sessions"


@shared_task
def process_pending_orders():
    """
    Process all pending orders
    Suitable for periodic task (Celery Beat)
    """
    pending_orders = Order.objects.filter(status='pending')
    count = pending_orders.count()

    for order in pending_orders:
        order.status = 'processing'
        order.save()

        # Process each order
        process_order.delay(order.id)

    return f"Queued {count} pending orders for processing"


# ════════════════════════════════════════════════════════════════
# Chained Tasks
# ════════════════════════════════════════════════════════════════

@shared_task
def step_one(data):
    """First step of processing"""
    time.sleep(1)
    return {'data': data, 'step': 1}


@shared_task
def step_two(result):
    """Second step of processing"""
    time.sleep(1)
    result['step'] = 2
    return result


@shared_task
def step_three(result):
    """Third step of processing"""
    time.sleep(1)
    result['step'] = 3
    return result


# Usage in views:
# from celery import chain
# workflow = chain(step_one.s('initial data'), step_two.s(), step_three.s())
# result = workflow.apply_async()


# ════════════════════════════════════════════════════════════════
# Group Tasks (Parallel Execution)
# ════════════════════════════════════════════════════════════════

@shared_task
def process_image(image_id):
    """Process a single image"""
    time.sleep(2)
    return f"Processed image {image_id}"


# Usage in views:
# from celery import group
# job = group([process_image.s(i) for i in range(10)])
# result = job.apply_async()


# ════════════════════════════════════════════════════════════════
# Error Handling
# ════════════════════════════════════════════════════════════════

@shared_task(bind=True)
def risky_task(self, data):
    """
    Task with comprehensive error handling
    """
    try:
        # Risky operation
        result = perform_operation(data)
        return result

    except ValueError as e:
        # Don't retry on validation errors
        return {'error': str(e), 'status': 'failed'}

    except Exception as e:
        # Retry on other errors
        if self.request.retries < self.max_retries:
            raise self.retry(exc=e, countdown=60)
        else:
            # Max retries reached
            return {'error': str(e), 'status': 'failed', 'retries': self.request.retries}


def perform_operation(data):
    """Helper function"""
    if not data:
        raise ValueError("Data cannot be empty")
    return {'status': 'success', 'data': data}
