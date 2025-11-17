"""
Priority Queue Configuration Template

This template demonstrates how to implement priority-based task routing
with support for multiple priority levels.

Priority Levels (0-255):
- 10: Critical (system alerts, security events)
- 7-9: High (user-facing operations, time-sensitive tasks)
- 4-6: Normal (standard background tasks)
- 1-3: Low (cleanup, maintenance, non-urgent tasks)

Usage:
    from celery import Celery
    from priority_queues import configure_priority_queues, PRIORITY_LEVELS

    app = Celery('myapp')
    configure_priority_queues(app)

    # Define task with priority
    @app.task(priority=PRIORITY_LEVELS['high'])
    def urgent_task():
        pass
"""

import os
from kombu import Exchange, Queue

# Priority level definitions
PRIORITY_LEVELS = {
    'critical': 10,   # Maximum priority
    'high': 7,        # High priority
    'normal': 5,      # Default priority
    'low': 2,         # Low priority
    'minimal': 0,     # Minimum priority
}

# Broker configuration
BROKER_URL = os.environ.get('CELERY_BROKER_URL', 'amqp://guest:guest@localhost:5672//')
RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Priority exchange
PRIORITY_EXCHANGE = Exchange('priority_tasks', type='direct', durable=True)

# Priority queue configuration
# Note: x-max-priority is RabbitMQ-specific
# For Redis, implement separate queues per priority level
CELERY_PRIORITY_QUEUES = (
    # Single queue with priority support (RabbitMQ)
    Queue(
        'priority_tasks',
        exchange=PRIORITY_EXCHANGE,
        routing_key='priority',
        queue_arguments={
            'x-max-priority': 10,  # Max priority value (RabbitMQ)
            'x-message-ttl': 3600000,  # 1 hour TTL
        }
    ),

    # Alternative: Separate queues per priority level (Redis/RabbitMQ)
    Queue(
        'critical_priority',
        exchange=PRIORITY_EXCHANGE,
        routing_key='critical',
        queue_arguments={
            'x-max-priority': 10,
        }
    ),

    Queue(
        'high_priority',
        exchange=PRIORITY_EXCHANGE,
        routing_key='high',
        queue_arguments={
            'x-max-priority': 10,
        }
    ),

    Queue(
        'normal_priority',
        exchange=PRIORITY_EXCHANGE,
        routing_key='normal',
        queue_arguments={
            'x-max-priority': 10,
        }
    ),

    Queue(
        'low_priority',
        exchange=PRIORITY_EXCHANGE,
        routing_key='low',
        queue_arguments={
            'x-max-priority': 10,
        }
    ),
)


def get_priority_queue(priority_level):
    """
    Map priority level to queue name

    Args:
        priority_level: String ('critical', 'high', 'normal', 'low') or int (0-10)

    Returns:
        tuple: (queue_name, routing_key, priority_value)
    """
    if isinstance(priority_level, str):
        priority_level = priority_level.lower()

        if priority_level == 'critical':
            return 'critical_priority', 'critical', PRIORITY_LEVELS['critical']
        elif priority_level == 'high':
            return 'high_priority', 'high', PRIORITY_LEVELS['high']
        elif priority_level == 'low':
            return 'low_priority', 'low', PRIORITY_LEVELS['low']
        else:  # normal
            return 'normal_priority', 'normal', PRIORITY_LEVELS['normal']

    # Numeric priority
    if priority_level >= 8:
        return 'critical_priority', 'critical', priority_level
    elif priority_level >= 6:
        return 'high_priority', 'high', priority_level
    elif priority_level >= 4:
        return 'normal_priority', 'normal', priority_level
    else:
        return 'low_priority', 'low', priority_level


def route_by_priority(name, args, kwargs, options, task=None, **kw):
    """
    Dynamic routing based on priority

    Priority can be set in:
    1. Task decorator: @app.task(priority=7)
    2. Task call: task.apply_async(priority=9)
    3. Task kwargs: task.apply_async(kwargs={'priority': 'high'})
    """
    # Check explicit priority in options (from apply_async)
    if 'priority' in options:
        priority = options['priority']
    # Check priority in kwargs
    elif 'priority' in kwargs:
        priority = kwargs['priority']
    # Check priority in task metadata
    elif task and hasattr(task, 'priority'):
        priority = task.priority
    else:
        priority = 'normal'

    queue_name, routing_key, priority_value = get_priority_queue(priority)

    return {
        'queue': queue_name,
        'routing_key': routing_key,
        'priority': priority_value
    }


# Task routing with priority
CELERY_PRIORITY_ROUTES = {
    # Critical priority tasks
    'myapp.tasks.security_alert': {
        'queue': 'critical_priority',
        'routing_key': 'critical',
        'priority': PRIORITY_LEVELS['critical']
    },
    'myapp.tasks.system_failure_notification': {
        'queue': 'critical_priority',
        'routing_key': 'critical',
        'priority': PRIORITY_LEVELS['critical']
    },

    # High priority tasks
    'myapp.tasks.user_notification': {
        'queue': 'high_priority',
        'routing_key': 'high',
        'priority': PRIORITY_LEVELS['high']
    },
    'myapp.tasks.payment_processing': {
        'queue': 'high_priority',
        'routing_key': 'high',
        'priority': PRIORITY_LEVELS['high']
    },

    # Normal priority tasks
    'myapp.tasks.send_email': {
        'queue': 'normal_priority',
        'routing_key': 'normal',
        'priority': PRIORITY_LEVELS['normal']
    },
    'myapp.tasks.generate_report': {
        'queue': 'normal_priority',
        'routing_key': 'normal',
        'priority': PRIORITY_LEVELS['normal']
    },

    # Low priority tasks
    'myapp.tasks.cleanup_old_data': {
        'queue': 'low_priority',
        'routing_key': 'low',
        'priority': PRIORITY_LEVELS['low']
    },
    'myapp.tasks.archive_logs': {
        'queue': 'low_priority',
        'routing_key': 'low',
        'priority': PRIORITY_LEVELS['low']
    },
}


def configure_priority_queues(app, use_separate_queues=True):
    """
    Configure Celery app with priority queue support

    Args:
        app: Celery application instance
        use_separate_queues: If True, use separate queues per priority level
                           If False, use single queue with priority (RabbitMQ only)
    """
    if use_separate_queues:
        # Use separate queues (works with both RabbitMQ and Redis)
        task_queues = CELERY_PRIORITY_QUEUES
        task_routes = CELERY_PRIORITY_ROUTES
    else:
        # Use single queue with priority (RabbitMQ only)
        task_queues = (CELERY_PRIORITY_QUEUES[0],)  # Only first queue
        task_routes = (route_by_priority,)  # Dynamic routing

    app.conf.update(
        broker_url=BROKER_URL,
        result_backend=RESULT_BACKEND,
        task_queues=task_queues,
        task_routes=task_routes,

        # Priority-related settings
        task_inherit_parent_priority=True,  # Child tasks inherit priority
        task_default_priority=PRIORITY_LEVELS['normal'],  # Default priority

        # Performance settings for priority queues
        worker_prefetch_multiplier=1,  # Low prefetch for better priority handling
        task_acks_late=True,  # Acknowledge after task completion
        worker_max_tasks_per_child=500,

        # Serialization
        task_serializer='json',
        result_serializer='json',
        accept_content=['json'],
    )

    return app


# Example task definitions with priority
def create_priority_tasks(app):
    """
    Example task definitions using priority

    Args:
        app: Celery application instance
    """

    @app.task(name='myapp.tasks.critical_task', priority=PRIORITY_LEVELS['critical'])
    def critical_task():
        """Critical priority task - executes first"""
        pass

    @app.task(name='myapp.tasks.high_priority_task', priority=PRIORITY_LEVELS['high'])
    def high_priority_task():
        """High priority task"""
        pass

    @app.task(name='myapp.tasks.normal_task', priority=PRIORITY_LEVELS['normal'])
    def normal_task():
        """Normal priority task (default)"""
        pass

    @app.task(name='myapp.tasks.low_priority_task', priority=PRIORITY_LEVELS['low'])
    def low_priority_task():
        """Low priority task - executes last"""
        pass

    return {
        'critical': critical_task,
        'high': high_priority_task,
        'normal': normal_task,
        'low': low_priority_task,
    }


# Example usage
if __name__ == '__main__':
    from celery import Celery

    app = Celery('myapp')

    # Configure with separate queues
    configure_priority_queues(app, use_separate_queues=True)

    # Create example tasks
    tasks = create_priority_tasks(app)

    print("Priority queues configured")
    print(f"\nPriority Levels:")
    for level, priority in PRIORITY_LEVELS.items():
        print(f"  {level}: {priority}")

    print(f"\nConfigured Priority Queues:")
    for queue in CELERY_PRIORITY_QUEUES:
        print(f"  - {queue.name} (routing_key: {queue.routing_key})")

    print(f"\nExample: Calling tasks with different priorities:")
    print(f"  tasks['critical'].apply_async()  # Priority: {PRIORITY_LEVELS['critical']}")
    print(f"  tasks['high'].apply_async()      # Priority: {PRIORITY_LEVELS['high']}")
    print(f"  tasks['normal'].apply_async()    # Priority: {PRIORITY_LEVELS['normal']}")
    print(f"  tasks['low'].apply_async()       # Priority: {PRIORITY_LEVELS['low']}")
