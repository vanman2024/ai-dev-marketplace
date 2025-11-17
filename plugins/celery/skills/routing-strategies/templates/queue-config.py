"""
Basic Celery Queue Configuration Template

This template provides a foundation for configuring multiple queues
with different priorities, exchanges, and routing keys.

Usage:
    from celery import Celery
    from queue_config import configure_queues

    app = Celery('myapp')
    configure_queues(app)
"""

import os
from kombu import Exchange, Queue

# Broker configuration from environment
BROKER_URL = os.environ.get('CELERY_BROKER_URL', 'amqp://guest:guest@localhost:5672//')
RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Define exchanges
DEFAULT_EXCHANGE = Exchange('default', type='direct', durable=True)
TASKS_EXCHANGE = Exchange('tasks', type='topic', durable=True)
PRIORITY_EXCHANGE = Exchange('priority', type='direct', durable=True)

# Define queues with different configurations
CELERY_QUEUES = (
    # Default queue for general tasks
    Queue(
        'default',
        exchange=DEFAULT_EXCHANGE,
        routing_key='default',
        queue_arguments={
            'x-max-length': 10000,  # Limit queue size
            'x-message-ttl': 86400000,  # 24 hour TTL
        }
    ),

    # High priority queue for urgent tasks
    Queue(
        'high_priority',
        exchange=PRIORITY_EXCHANGE,
        routing_key='high',
        queue_arguments={
            'x-max-priority': 10,  # Enable priority support (RabbitMQ)
        }
    ),

    # Low priority queue for background tasks
    Queue(
        'low_priority',
        exchange=PRIORITY_EXCHANGE,
        routing_key='low',
        queue_arguments={
            'x-max-priority': 10,
        }
    ),

    # Email queue for email-related tasks
    Queue(
        'emails',
        exchange=TASKS_EXCHANGE,
        routing_key='email.#',  # Match all email routing keys
        queue_arguments={
            'x-max-length': 5000,
        }
    ),

    # Reports queue for report generation
    Queue(
        'reports',
        exchange=TASKS_EXCHANGE,
        routing_key='report.#',  # Match all report routing keys
        queue_arguments={
            'x-max-length': 1000,
        }
    ),

    # Processing queue for compute-intensive tasks
    Queue(
        'processing',
        exchange=TASKS_EXCHANGE,
        routing_key='process.#',
        queue_arguments={
            'x-max-length': 500,
        }
    ),
)

# Task routing configuration
CELERY_ROUTES = {
    # Email tasks
    'myapp.tasks.send_email': {
        'queue': 'emails',
        'routing_key': 'email.send',
        'priority': 5
    },
    'myapp.tasks.send_bulk_email': {
        'queue': 'emails',
        'routing_key': 'email.bulk',
        'priority': 3
    },

    # Report tasks
    'myapp.tasks.generate_report': {
        'queue': 'reports',
        'routing_key': 'report.generate',
        'priority': 5
    },
    'myapp.tasks.export_data': {
        'queue': 'reports',
        'routing_key': 'report.export',
        'priority': 4
    },

    # Processing tasks
    'myapp.tasks.process_data': {
        'queue': 'processing',
        'routing_key': 'process.data',
        'priority': 5
    },
    'myapp.tasks.analyze_data': {
        'queue': 'processing',
        'routing_key': 'process.analyze',
        'priority': 6
    },

    # High priority tasks
    'myapp.tasks.urgent_notification': {
        'queue': 'high_priority',
        'routing_key': 'high',
        'priority': 9
    },

    # Low priority tasks
    'myapp.tasks.cleanup_task': {
        'queue': 'low_priority',
        'routing_key': 'low',
        'priority': 2
    },
}

# Default queue for tasks without explicit routing
CELERY_DEFAULT_QUEUE = 'default'
CELERY_DEFAULT_EXCHANGE = 'default'
CELERY_DEFAULT_ROUTING_KEY = 'default'


def configure_queues(app):
    """
    Configure Celery app with queue settings

    Args:
        app: Celery application instance
    """
    app.conf.update(
        broker_url=BROKER_URL,
        result_backend=RESULT_BACKEND,
        task_queues=CELERY_QUEUES,
        task_routes=CELERY_ROUTES,
        task_default_queue=CELERY_DEFAULT_QUEUE,
        task_default_exchange=CELERY_DEFAULT_EXCHANGE,
        task_default_routing_key=CELERY_DEFAULT_ROUTING_KEY,

        # Performance settings
        worker_prefetch_multiplier=4,
        task_acks_late=True,
        worker_max_tasks_per_child=1000,

        # Serialization
        task_serializer='json',
        result_serializer='json',
        accept_content=['json'],
    )

    return app


# Example usage
if __name__ == '__main__':
    from celery import Celery

    app = Celery('myapp')
    configure_queues(app)

    # Print configuration
    print("Configured Queues:")
    for queue in CELERY_QUEUES:
        print(f"  - {queue.name} (exchange: {queue.exchange.name}, routing_key: {queue.routing_key})")

    print("\nTask Routes:")
    for task, route in CELERY_ROUTES.items():
        print(f"  - {task} -> {route['queue']}")
