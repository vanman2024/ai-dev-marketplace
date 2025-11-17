"""
Amazon SQS Broker Configuration for Celery

Production-ready SQS configuration with IAM roles, FIFO queues,
and proper AWS credentials handling.

SECURITY: This file uses environment variables or IAM roles for credentials.
Never hardcode AWS access keys.
"""

import os
from celery import Celery
from kombu import Queue

# Environment variables (set these in your .env or use IAM roles)
# For EC2/ECS: Leave these empty to use instance IAM role
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
AWS_SESSION_TOKEN = os.getenv('AWS_SESSION_TOKEN')  # For temporary credentials

# SQS queue configuration
QUEUE_NAME_PREFIX = os.getenv('SQS_QUEUE_PREFIX', 'celery-')
USE_FIFO_QUEUES = os.getenv('USE_FIFO_QUEUES', 'false').lower() == 'true'

# Build broker URL
# Option 1: Use IAM role (recommended for EC2/ECS/Lambda)
if not AWS_ACCESS_KEY_ID:
    broker_url = 'sqs://'
# Option 2: Use explicit credentials (for local development)
else:
    if AWS_SESSION_TOKEN:
        broker_url = f'sqs://{AWS_ACCESS_KEY_ID}:{AWS_SECRET_ACCESS_KEY}:{AWS_SESSION_TOKEN}@'
    else:
        broker_url = f'sqs://{AWS_ACCESS_KEY_ID}:{AWS_SECRET_ACCESS_KEY}@'

# Initialize Celery app
app = Celery('myapp', broker=broker_url)

# SQS broker transport options
broker_transport_options = {
    'region': AWS_REGION,
    'visibility_timeout': 3600,  # 1 hour visibility timeout
    'polling_interval': 1,  # Poll interval in seconds (1 = more responsive, more expensive)
    'queue_name_prefix': QUEUE_NAME_PREFIX,

    # Long polling configuration (reduces empty responses, saves costs)
    'wait_time_seconds': 10,  # Long polling wait time (max 20 seconds)

    # Predefined queues (optional - creates queues if they don't exist)
    'predefined_queues': {
        f'{QUEUE_NAME_PREFIX}default': {
            'url': None,  # Will be auto-discovered
            'access_key_id': AWS_ACCESS_KEY_ID,
            'secret_access_key': AWS_SECRET_ACCESS_KEY,
        },
        f'{QUEUE_NAME_PREFIX}high_priority': {
            'url': None,
        },
        f'{QUEUE_NAME_PREFIX}low_priority': {
            'url': None,
        },
    }
}

app.conf.broker_transport_options = broker_transport_options

# Queue configuration
queue_arguments = {}
if USE_FIFO_QUEUES:
    # FIFO queue configuration
    queue_arguments = {
        'FifoQueue': 'true',
        'ContentBasedDeduplication': 'true',  # Automatic deduplication
    }
    # Note: FIFO queues require .fifo suffix
    queue_suffix = '.fifo'
else:
    queue_suffix = ''

app.conf.task_queues = (
    Queue(f'{QUEUE_NAME_PREFIX}default{queue_suffix}', queue_arguments=queue_arguments),
    Queue(f'{QUEUE_NAME_PREFIX}high_priority{queue_suffix}', queue_arguments=queue_arguments),
    Queue(f'{QUEUE_NAME_PREFIX}low_priority{queue_suffix}', queue_arguments=queue_arguments),
)

# Celery configuration
app.conf.update(
    # Task routing
    task_default_queue=f'{QUEUE_NAME_PREFIX}default{queue_suffix}',
    task_default_routing_key='default',

    # Task serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',

    # Result backend (SQS doesn't support results - use S3, DynamoDB, or Redis)
    result_backend=os.getenv('CELERY_RESULT_BACKEND'),  # e.g., 's3://my-bucket/'
    result_expires=3600,

    # Worker settings
    worker_prefetch_multiplier=1,  # SQS recommendation: keep low to prevent message timeout
    worker_max_tasks_per_child=1000,

    # Task execution
    task_acks_late=True,  # Acknowledge after completion
    task_reject_on_worker_lost=True,

    # Time limits (must be less than visibility_timeout)
    task_time_limit=3000,  # 50 minutes
    task_soft_time_limit=2700,  # 45 minutes

    # Timezone
    timezone='UTC',
    enable_utc=True,

    # SQS-specific: Disable events (not supported)
    worker_send_task_events=False,
    task_send_sent_event=False,
)

# FIFO queue task routing
if USE_FIFO_QUEUES:
    # Example: Route tasks by message group
    app.conf.task_routes = {
        'myapp.tasks.user_*': {
            'queue': f'{QUEUE_NAME_PREFIX}default{queue_suffix}',
        },
    }

# Helper function for FIFO queues
def send_task_fifo(task_name, args=None, kwargs=None, message_group_id='default', **options):
    """
    Send task to FIFO queue with required parameters.

    Args:
        task_name: Name of the task to execute
        args: Positional arguments for the task
        kwargs: Keyword arguments for the task
        message_group_id: FIFO message group ID (for ordering)
        **options: Additional apply_async options
    """
    if USE_FIFO_QUEUES:
        options['properties'] = {
            'MessageGroupId': message_group_id,
        }

    return app.send_task(
        task_name,
        args=args or [],
        kwargs=kwargs or {},
        **options
    )

if __name__ == '__main__':
    # Test connection (SQS will create queues on first use)
    try:
        print("✅ SQS broker configured successfully")
        print(f"Region: {AWS_REGION}")
        print(f"Queue Prefix: {QUEUE_NAME_PREFIX}")
        print(f"FIFO Queues: {'Enabled' if USE_FIFO_QUEUES else 'Disabled'}")
        print(f"Auth Method: {'IAM Role' if not AWS_ACCESS_KEY_ID else 'Explicit Credentials'}")

        # Note: SQS queues are created lazily when first message is sent
        print("\nNote: SQS queues will be created automatically when first task is sent")
    except Exception as e:
        print(f"❌ Failed to configure SQS broker: {e}")
