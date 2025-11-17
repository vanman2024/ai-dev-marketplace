"""
Dynamic Routing Rules Template

This template demonstrates advanced routing patterns including:
- Pattern-based routing
- Conditional routing logic
- Dynamic queue selection
- Argument-based routing

Usage:
    from celery import Celery
    from routing_rules import setup_dynamic_routing

    app = Celery('myapp')
    setup_dynamic_routing(app)
"""

import os
from kombu import Exchange, Queue


def route_by_task_name(name, args, kwargs, options, task=None, **kw):
    """
    Route tasks based on task name patterns

    Args:
        name: Task name (e.g., 'myapp.tasks.send_email')
        args: Task positional arguments
        kwargs: Task keyword arguments
        options: Task options
        task: Task instance
        **kw: Additional routing info

    Returns:
        dict: Routing configuration {'queue': str, 'routing_key': str, 'priority': int}
    """
    # Route urgent tasks to high priority queue
    if name.startswith('urgent.') or 'urgent' in name:
        return {
            'queue': 'high_priority',
            'routing_key': 'high',
            'priority': 9
        }

    # Route email-related tasks
    if 'email' in name.lower():
        return {
            'queue': 'emails',
            'routing_key': f'email.{name.split(".")[-1]}',
            'priority': 5
        }

    # Route report generation tasks
    if 'report' in name.lower() or 'export' in name.lower():
        return {
            'queue': 'reports',
            'routing_key': f'report.{name.split(".")[-1]}',
            'priority': 4
        }

    # Route data processing tasks
    if any(word in name.lower() for word in ['process', 'analyze', 'compute']):
        return {
            'queue': 'processing',
            'routing_key': f'process.{name.split(".")[-1]}',
            'priority': 5
        }

    # Route cleanup/maintenance tasks to low priority
    if any(word in name.lower() for word in ['cleanup', 'maintenance', 'archive']):
        return {
            'queue': 'low_priority',
            'routing_key': 'low',
            'priority': 2
        }

    # Default routing
    return {
        'queue': 'default',
        'routing_key': 'default',
        'priority': 5
    }


def route_by_arguments(name, args, kwargs, options, task=None, **kw):
    """
    Route tasks based on their arguments

    This allows runtime routing decisions based on task parameters
    """
    # Check for priority in kwargs
    if kwargs.get('priority') == 'high':
        return {
            'queue': 'high_priority',
            'routing_key': 'high',
            'priority': 9
        }
    elif kwargs.get('priority') == 'low':
        return {
            'queue': 'low_priority',
            'routing_key': 'low',
            'priority': 2
        }

    # Route based on user type
    if kwargs.get('user_type') == 'premium':
        return {
            'queue': 'premium_users',
            'routing_key': 'premium',
            'priority': 7
        }

    # Route based on data size
    if kwargs.get('data_size', 0) > 1000000:  # Large dataset
        return {
            'queue': 'large_processing',
            'routing_key': 'process.large',
            'priority': 4
        }

    # Route based on geographic region
    region = kwargs.get('region', 'us-east')
    if region in ['eu-west', 'eu-central']:
        return {
            'queue': f'tasks_eu',
            'routing_key': f'tasks.{region}',
            'priority': 5
        }

    # Fallback to name-based routing
    return route_by_task_name(name, args, kwargs, options, task, **kw)


def route_by_load_balancing(name, args, kwargs, options, task=None, **kw):
    """
    Route tasks to balance load across multiple queues

    Useful for distributing work across worker pools
    """
    import hashlib

    # Use task name hash to distribute evenly
    task_hash = int(hashlib.md5(name.encode()).hexdigest(), 16)
    worker_count = 4  # Number of worker pools

    worker_id = task_hash % worker_count

    return {
        'queue': f'worker_pool_{worker_id}',
        'routing_key': f'pool.{worker_id}',
        'priority': 5
    }


def route_by_time_of_day(name, args, kwargs, options, task=None, **kw):
    """
    Route tasks based on time of day

    Useful for separating peak-hour traffic from off-peak tasks
    """
    from datetime import datetime

    current_hour = datetime.now().hour

    # Peak hours (9 AM - 5 PM)
    if 9 <= current_hour < 17:
        return {
            'queue': 'peak_hours',
            'routing_key': 'peak',
            'priority': 6
        }
    # Off-peak hours
    else:
        return {
            'queue': 'off_peak',
            'routing_key': 'off_peak',
            'priority': 4
        }


def route_by_resource_requirements(name, args, kwargs, options, task=None, **kw):
    """
    Route tasks based on resource requirements

    CPU-intensive tasks go to CPU worker pools
    I/O-intensive tasks go to I/O worker pools
    """
    # Define resource-intensive task patterns
    cpu_intensive_keywords = ['compute', 'calculate', 'process', 'analyze', 'train']
    io_intensive_keywords = ['download', 'upload', 'fetch', 'api', 'network']
    memory_intensive_keywords = ['aggregate', 'merge', 'join', 'large']

    name_lower = name.lower()

    if any(keyword in name_lower for keyword in cpu_intensive_keywords):
        return {
            'queue': 'cpu_workers',
            'routing_key': 'cpu',
            'priority': 5
        }

    if any(keyword in name_lower for keyword in io_intensive_keywords):
        return {
            'queue': 'io_workers',
            'routing_key': 'io',
            'priority': 5
        }

    if any(keyword in name_lower for keyword in memory_intensive_keywords):
        return {
            'queue': 'memory_workers',
            'routing_key': 'memory',
            'priority': 5
        }

    # Default to general workers
    return {
        'queue': 'general_workers',
        'routing_key': 'general',
        'priority': 5
    }


def composite_router(name, args, kwargs, options, task=None, **kw):
    """
    Composite router that combines multiple routing strategies

    Order of precedence:
    1. Explicit priority in kwargs
    2. Resource requirements
    3. Task name patterns
    4. Default routing
    """
    # Check for explicit routing override
    if 'queue' in kwargs:
        return {
            'queue': kwargs['queue'],
            'routing_key': kwargs.get('routing_key', kwargs['queue']),
            'priority': kwargs.get('priority', 5)
        }

    # Try argument-based routing first (highest precedence)
    if 'priority' in kwargs or 'user_type' in kwargs:
        return route_by_arguments(name, args, kwargs, options, task, **kw)

    # Then resource-based routing
    resource_route = route_by_resource_requirements(name, args, kwargs, options, task, **kw)
    if resource_route['queue'] != 'general_workers':
        return resource_route

    # Finally, name-based routing
    return route_by_task_name(name, args, kwargs, options, task, **kw)


def setup_dynamic_routing(app, strategy='composite'):
    """
    Setup dynamic routing for Celery app

    Args:
        app: Celery application instance
        strategy: Routing strategy to use
                  ('name', 'arguments', 'load_balance', 'time', 'resource', 'composite')
    """
    routing_strategies = {
        'name': route_by_task_name,
        'arguments': route_by_arguments,
        'load_balance': route_by_load_balancing,
        'time': route_by_time_of_day,
        'resource': route_by_resource_requirements,
        'composite': composite_router,
    }

    router = routing_strategies.get(strategy, composite_router)

    app.conf.task_routes = (router,)

    return app


# Example usage
if __name__ == '__main__':
    from celery import Celery

    app = Celery('myapp')
    app.conf.broker_url = os.environ.get('CELERY_BROKER_URL', 'amqp://guest:guest@localhost:5672//')

    # Setup composite routing
    setup_dynamic_routing(app, strategy='composite')

    print("Dynamic routing configured with composite strategy")
    print("\nExample routes:")

    # Test routing with different task names
    test_tasks = [
        'myapp.tasks.send_email',
        'urgent.tasks.notify_admin',
        'myapp.tasks.process_large_dataset',
        'myapp.tasks.cleanup_old_files',
        'myapp.tasks.compute_statistics',
    ]

    for task_name in test_tasks:
        route = composite_router(task_name, [], {}, {})
        print(f"  {task_name} -> {route['queue']} (priority: {route['priority']})")
