"""
Transaction-safe Django + Celery task patterns
Ensures tasks only run AFTER database commits

Problem: Tasks may execute before database transaction commits,
causing tasks to fail when they query for objects that don't exist yet.

Solution: Use transaction.on_commit() to delay task execution.
"""

from django.db import transaction
from celery import shared_task
from .models import Order, EmailLog


# ❌ WRONG: Task may run before commit
def create_order_wrong(request):
    order = Order.objects.create(
        user=request.user,
        total=100.00
    )
    # Task starts immediately, but DB transaction may not be committed yet!
    send_order_email.delay(order.id)  # May fail with "Order not found"
    return order


# ✅ CORRECT: Task runs after commit
def create_order_correct(request):
    order = Order.objects.create(
        user=request.user,
        total=100.00
    )
    # Wait until transaction commits before starting task
    transaction.on_commit(lambda: send_order_email.delay(order.id))
    return order


# ✅ CORRECT: Using decorator (Django 3.2+)
def create_order_decorator(request):
    order = Order.objects.create(
        user=request.user,
        total=100.00
    )

    # Use on_commit decorator for cleaner code
    @transaction.on_commit
    def trigger_email():
        send_order_email.delay(order.id)

    return order


@shared_task
def send_order_email(order_id):
    """
    Send order confirmation email.
    Runs AFTER database commit ensures order exists.
    """
    try:
        order = Order.objects.get(id=order_id)
        # Send email logic here
        print(f"Sending email for order {order.id}")

        # Log the email
        EmailLog.objects.create(
            order=order,
            email_type='order_confirmation',
            status='sent'
        )
        return f"Email sent for order {order_id}"

    except Order.DoesNotExist:
        print(f"Order {order_id} not found!")
        raise


# ✅ CORRECT: Multiple tasks with commit
def create_order_with_notifications(request):
    order = Order.objects.create(
        user=request.user,
        total=100.00
    )

    # Queue multiple tasks after commit
    transaction.on_commit(
        lambda: (
            send_order_email.delay(order.id),
            notify_warehouse.delay(order.id),
            update_inventory.delay(order.id)
        )
    )
    return order


@shared_task
def notify_warehouse(order_id):
    """Notify warehouse system of new order"""
    order = Order.objects.get(id=order_id)
    print(f"Notifying warehouse about order {order.id}")
    return f"Warehouse notified for order {order_id}"


@shared_task
def update_inventory(order_id):
    """Update inventory counts"""
    order = Order.objects.get(id=order_id)
    print(f"Updating inventory for order {order.id}")
    return f"Inventory updated for order {order_id}"


# ✅ CORRECT: Nested transactions
def process_order_with_nested_transactions(request):
    """
    Handle complex order processing with nested transactions
    """
    with transaction.atomic():
        order = Order.objects.create(
            user=request.user,
            total=100.00
        )

        # Inner transaction for payment
        with transaction.atomic():
            payment = process_payment(order)

            # Only send email if payment succeeds
            transaction.on_commit(
                lambda: send_payment_confirmation.delay(order.id, payment.id)
            )

        # Send order email after entire outer transaction
        transaction.on_commit(lambda: send_order_email.delay(order.id))

    return order


@shared_task
def send_payment_confirmation(order_id, payment_id):
    """Send payment confirmation email"""
    print(f"Payment confirmed for order {order_id}, payment {payment_id}")
    return f"Payment confirmation sent"


# ✅ CORRECT: Handling rollback
def create_order_with_rollback_handling(request):
    """
    Ensure tasks don't run if transaction rolls back
    """
    try:
        with transaction.atomic():
            order = Order.objects.create(
                user=request.user,
                total=100.00
            )

            # Validate order
            if not validate_order(order):
                raise ValueError("Invalid order")

            # Only runs if no exception raised
            transaction.on_commit(lambda: send_order_email.delay(order.id))

    except ValueError as e:
        # Transaction rolled back, task never queued
        print(f"Order creation failed: {e}")
        return None

    return order


def validate_order(order):
    """Validate order data"""
    return order.total > 0


# Configuration for Django settings.py
"""
# Add to settings.py for optimal Celery + Django integration

# Celery Configuration
CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://your_redis_url_here')
CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://your_redis_url_here')

# Task serialization
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_ACCEPT_CONTENT = ['json']

# Timezone
CELERY_TIMEZONE = TIME_ZONE
CELERY_ENABLE_UTC = True

# Database connection handling
CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True

# For Django ORM
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'your_database_name_here'),
        'USER': os.getenv('DB_USER', 'your_database_user_here'),
        'PASSWORD': os.getenv('DB_PASSWORD', 'your_database_password_here'),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
        'CONN_MAX_AGE': 0,  # Close connections after each request
    }
}

# Task result backend using Django DB (optional)
# pip install django-celery-results
CELERY_RESULT_BACKEND = 'django-db'
INSTALLED_APPS += ['django_celery_results']
"""


# Best Practices Summary
"""
1. ALWAYS use transaction.on_commit() for tasks that query created objects
2. NEVER pass model instances to tasks (pass IDs instead)
3. Close database connections in long-running tasks
4. Use atomic transactions for data integrity
5. Handle rollback scenarios properly
6. Test with actual database, not in-memory SQLite

Common Issues:
- Task queries for object before commit → Use on_commit()
- "Lost connection to MySQL" → Set CONN_MAX_AGE = 0
- Tasks see stale data → Use select_for_update() or refresh_from_db()
- Race conditions → Use database-level locking
"""
