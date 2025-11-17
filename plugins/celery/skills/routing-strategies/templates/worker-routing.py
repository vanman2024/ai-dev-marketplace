"""
Worker-Specific Routing Configuration Template

This template demonstrates how to route tasks to specific worker pools
based on resource requirements (CPU, I/O, memory).

Worker Pool Types:
- CPU Workers: Compute-intensive tasks (ML, video processing, data analysis)
- I/O Workers: Network/disk-intensive tasks (API calls, file uploads, emails)
- Memory Workers: Large dataset processing (aggregations, joins)
- General Workers: Standard background tasks

Usage:
    from celery import Celery
    from worker_routing import configure_worker_routing

    app = Celery('myapp')
    configure_worker_routing(app)
"""

import os
from kombu import Exchange, Queue

# Broker configuration
BROKER_URL = os.environ.get('CELERY_BROKER_URL', 'amqp://guest:guest@localhost:5672//')
RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Worker exchange
WORKER_EXCHANGE = Exchange('worker_tasks', type='direct', durable=True)

# Worker-specific queue configurations
WORKER_QUEUES = (
    # CPU-intensive worker queues (low concurrency, high compute)
    Queue(
        'cpu_ml_training',
        exchange=WORKER_EXCHANGE,
        routing_key='cpu.ml',
        queue_arguments={
            'x-max-length': 100,  # Limited queue size for expensive tasks
        }
    ),

    Queue(
        'cpu_video_processing',
        exchange=WORKER_EXCHANGE,
        routing_key='cpu.video',
        queue_arguments={
            'x-max-length': 50,
        }
    ),

    Queue(
        'cpu_data_analysis',
        exchange=WORKER_EXCHANGE,
        routing_key='cpu.analysis',
        queue_arguments={
            'x-max-length': 200,
        }
    ),

    # I/O-intensive worker queues (high concurrency, network/disk bound)
    Queue(
        'io_api_calls',
        exchange=WORKER_EXCHANGE,
        routing_key='io.api',
        queue_arguments={
            'x-max-length': 10000,  # Large queue for many concurrent I/O tasks
        }
    ),

    Queue(
        'io_file_operations',
        exchange=WORKER_EXCHANGE,
        routing_key='io.file',
        queue_arguments={
            'x-max-length': 5000,
        }
    ),

    Queue(
        'io_email_sending',
        exchange=WORKER_EXCHANGE,
        routing_key='io.email',
        queue_arguments={
            'x-max-length': 10000,
        }
    ),

    Queue(
        'io_web_scraping',
        exchange=WORKER_EXCHANGE,
        routing_key='io.scrape',
        queue_arguments={
            'x-max-length': 2000,
        }
    ),

    # Memory-intensive worker queues (large datasets)
    Queue(
        'memory_aggregations',
        exchange=WORKER_EXCHANGE,
        routing_key='memory.aggregate',
        queue_arguments={
            'x-max-length': 100,
        }
    ),

    Queue(
        'memory_large_imports',
        exchange=WORKER_EXCHANGE,
        routing_key='memory.import',
        queue_arguments={
            'x-max-length': 50,
        }
    ),

    # General worker queues
    Queue(
        'general_background',
        exchange=WORKER_EXCHANGE,
        routing_key='general.background',
        queue_arguments={
            'x-max-length': 5000,
        }
    ),

    Queue(
        'general_scheduled',
        exchange=WORKER_EXCHANGE,
        routing_key='general.scheduled',
        queue_arguments={
            'x-max-length': 1000,
        }
    ),
)

# Task-to-worker routing
WORKER_TASK_ROUTES = {
    # CPU-intensive tasks
    'myapp.tasks.train_model': {
        'queue': 'cpu_ml_training',
        'routing_key': 'cpu.ml'
    },
    'myapp.tasks.process_video': {
        'queue': 'cpu_video_processing',
        'routing_key': 'cpu.video'
    },
    'myapp.tasks.analyze_large_dataset': {
        'queue': 'cpu_data_analysis',
        'routing_key': 'cpu.analysis'
    },
    'myapp.tasks.compute_statistics': {
        'queue': 'cpu_data_analysis',
        'routing_key': 'cpu.analysis'
    },

    # I/O-intensive tasks
    'myapp.tasks.call_external_api': {
        'queue': 'io_api_calls',
        'routing_key': 'io.api'
    },
    'myapp.tasks.fetch_remote_data': {
        'queue': 'io_api_calls',
        'routing_key': 'io.api'
    },
    'myapp.tasks.upload_file': {
        'queue': 'io_file_operations',
        'routing_key': 'io.file'
    },
    'myapp.tasks.download_file': {
        'queue': 'io_file_operations',
        'routing_key': 'io.file'
    },
    'myapp.tasks.send_email': {
        'queue': 'io_email_sending',
        'routing_key': 'io.email'
    },
    'myapp.tasks.scrape_website': {
        'queue': 'io_web_scraping',
        'routing_key': 'io.scrape'
    },

    # Memory-intensive tasks
    'myapp.tasks.aggregate_user_data': {
        'queue': 'memory_aggregations',
        'routing_key': 'memory.aggregate'
    },
    'myapp.tasks.import_large_csv': {
        'queue': 'memory_large_imports',
        'routing_key': 'memory.import'
    },

    # General tasks
    'myapp.tasks.cleanup_old_data': {
        'queue': 'general_background',
        'routing_key': 'general.background'
    },
    'myapp.tasks.generate_daily_report': {
        'queue': 'general_scheduled',
        'routing_key': 'general.scheduled'
    },
}


def route_by_resource_type(name, args, kwargs, options, task=None, **kw):
    """
    Dynamic routing based on resource requirements

    Analyzes task characteristics to determine optimal worker pool
    """
    name_lower = name.lower()

    # CPU-intensive task patterns
    cpu_patterns = ['train', 'model', 'process', 'analyze', 'compute', 'calculate', 'transform', 'encode']
    if any(pattern in name_lower for pattern in cpu_patterns):
        if 'ml' in name_lower or 'model' in name_lower:
            return {'queue': 'cpu_ml_training', 'routing_key': 'cpu.ml'}
        elif 'video' in name_lower or 'image' in name_lower:
            return {'queue': 'cpu_video_processing', 'routing_key': 'cpu.video'}
        else:
            return {'queue': 'cpu_data_analysis', 'routing_key': 'cpu.analysis'}

    # I/O-intensive task patterns
    io_patterns = ['api', 'fetch', 'download', 'upload', 'request', 'scrape', 'email', 'send', 'notify']
    if any(pattern in name_lower for pattern in io_patterns):
        if 'api' in name_lower or 'fetch' in name_lower or 'request' in name_lower:
            return {'queue': 'io_api_calls', 'routing_key': 'io.api'}
        elif 'file' in name_lower or 'upload' in name_lower or 'download' in name_lower:
            return {'queue': 'io_file_operations', 'routing_key': 'io.file'}
        elif 'email' in name_lower or 'send' in name_lower:
            return {'queue': 'io_email_sending', 'routing_key': 'io.email'}
        elif 'scrape' in name_lower or 'crawl' in name_lower:
            return {'queue': 'io_web_scraping', 'routing_key': 'io.scrape'}

    # Memory-intensive task patterns
    memory_patterns = ['aggregate', 'join', 'merge', 'import', 'large', 'bulk']
    if any(pattern in name_lower for pattern in memory_patterns):
        if 'aggregate' in name_lower or 'join' in name_lower:
            return {'queue': 'memory_aggregations', 'routing_key': 'memory.aggregate'}
        elif 'import' in name_lower or 'bulk' in name_lower:
            return {'queue': 'memory_large_imports', 'routing_key': 'memory.import'}

    # Check for resource hints in kwargs
    if 'resource_type' in kwargs:
        resource_type = kwargs['resource_type']
        if resource_type == 'cpu':
            return {'queue': 'cpu_data_analysis', 'routing_key': 'cpu.analysis'}
        elif resource_type == 'io':
            return {'queue': 'io_api_calls', 'routing_key': 'io.api'}
        elif resource_type == 'memory':
            return {'queue': 'memory_aggregations', 'routing_key': 'memory.aggregate'}

    # Default to general workers
    return {'queue': 'general_background', 'routing_key': 'general.background'}


def configure_worker_routing(app, use_dynamic_routing=False):
    """
    Configure Celery app with worker-specific routing

    Args:
        app: Celery application instance
        use_dynamic_routing: If True, use dynamic routing function
    """
    app.conf.update(
        broker_url=BROKER_URL,
        result_backend=RESULT_BACKEND,
        task_queues=WORKER_QUEUES,
        task_routes=route_by_resource_type if use_dynamic_routing else WORKER_TASK_ROUTES,

        # Default to general queue
        task_default_queue='general_background',
        task_default_routing_key='general.background',

        # Serialization
        task_serializer='json',
        result_serializer='json',
        accept_content=['json'],
    )

    return app


# Worker pool configurations
WORKER_POOL_CONFIGS = {
    'cpu_workers': {
        'description': 'CPU-intensive tasks (ML, video, analysis)',
        'queues': ['cpu_ml_training', 'cpu_video_processing', 'cpu_data_analysis'],
        'concurrency': 4,  # Low concurrency (number of CPU cores)
        'prefetch_multiplier': 1,  # Prefetch only 1 task at a time
        'max_tasks_per_child': 100,  # Restart after 100 tasks to free memory
        'time_limit': 3600,  # 1 hour hard limit
        'soft_time_limit': 3000,  # 50 minute soft limit
        'start_command': 'celery -A myapp worker -Q cpu_ml_training,cpu_video_processing,cpu_data_analysis -c 4 --prefetch-multiplier=1 --max-tasks-per-child=100 -n cpu@%h'
    },

    'io_workers': {
        'description': 'I/O-intensive tasks (API calls, files, emails)',
        'queues': ['io_api_calls', 'io_file_operations', 'io_email_sending', 'io_web_scraping'],
        'concurrency': 50,  # High concurrency for I/O waiting
        'prefetch_multiplier': 10,  # Prefetch many tasks
        'max_tasks_per_child': 1000,
        'time_limit': 300,  # 5 minute hard limit
        'soft_time_limit': 240,  # 4 minute soft limit
        'start_command': 'celery -A myapp worker -Q io_api_calls,io_file_operations,io_email_sending,io_web_scraping -c 50 --prefetch-multiplier=10 --max-tasks-per-child=1000 -n io@%h'
    },

    'memory_workers': {
        'description': 'Memory-intensive tasks (aggregations, large imports)',
        'queues': ['memory_aggregations', 'memory_large_imports'],
        'concurrency': 2,  # Very low concurrency for memory-heavy tasks
        'prefetch_multiplier': 1,
        'max_tasks_per_child': 50,  # Restart frequently to free memory
        'time_limit': 7200,  # 2 hour hard limit
        'soft_time_limit': 6600,  # 1h 50m soft limit
        'start_command': 'celery -A myapp worker -Q memory_aggregations,memory_large_imports -c 2 --prefetch-multiplier=1 --max-tasks-per-child=50 -n memory@%h'
    },

    'general_workers': {
        'description': 'General purpose tasks',
        'queues': ['general_background', 'general_scheduled'],
        'concurrency': 10,  # Moderate concurrency
        'prefetch_multiplier': 4,
        'max_tasks_per_child': 500,
        'time_limit': 600,  # 10 minute hard limit
        'soft_time_limit': 540,  # 9 minute soft limit
        'start_command': 'celery -A myapp worker -Q general_background,general_scheduled -c 10 --prefetch-multiplier=4 --max-tasks-per-child=500 -n general@%h'
    },
}


# Autoscaling configurations (min/max workers)
AUTOSCALING_CONFIGS = {
    'cpu_workers': {
        'min': 2,
        'max': 8,
        'command': 'celery -A myapp worker -Q cpu_ml_training,cpu_video_processing,cpu_data_analysis --autoscale=8,2 -n cpu@%h'
    },
    'io_workers': {
        'min': 20,
        'max': 100,
        'command': 'celery -A myapp worker -Q io_api_calls,io_file_operations,io_email_sending,io_web_scraping --autoscale=100,20 -n io@%h'
    },
    'memory_workers': {
        'min': 1,
        'max': 4,
        'command': 'celery -A myapp worker -Q memory_aggregations,memory_large_imports --autoscale=4,1 -n memory@%h'
    },
    'general_workers': {
        'min': 5,
        'max': 20,
        'command': 'celery -A myapp worker -Q general_background,general_scheduled --autoscale=20,5 -n general@%h'
    },
}


# Example usage
if __name__ == '__main__':
    from celery import Celery

    app = Celery('myapp')
    configure_worker_routing(app, use_dynamic_routing=True)

    print("Worker-specific routing configured")
    print("\nWorker Pool Configurations:\n")

    for pool_name, config in WORKER_POOL_CONFIGS.items():
        print(f"{pool_name.upper()}:")
        print(f"  Description: {config['description']}")
        print(f"  Queues: {', '.join(config['queues'])}")
        print(f"  Concurrency: {config['concurrency']}")
        print(f"  Prefetch: {config['prefetch_multiplier']}")
        print(f"  Start Command:")
        print(f"    {config['start_command']}\n")

    print("\nAutoscaling Configurations:\n")
    for pool_name, config in AUTOSCALING_CONFIGS.items():
        print(f"{pool_name.upper()}:")
        print(f"  Min Workers: {config['min']}, Max Workers: {config['max']}")
        print(f"  Command: {config['command']}\n")
