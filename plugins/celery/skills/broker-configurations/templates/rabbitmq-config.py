"""
RabbitMQ Broker Configuration for Celery

Production-ready RabbitMQ configuration with quorum queues,
SSL support, and high availability features.

SECURITY: This file uses environment variables for credentials.
Never hardcode passwords or API keys.
"""

import os
from celery import Celery
from kombu import Queue, Exchange

# Environment variables (set these in your .env file)
RABBITMQ_HOST = os.getenv('RABBITMQ_HOST', 'localhost')
RABBITMQ_PORT = int(os.getenv('RABBITMQ_PORT', 5672))
RABBITMQ_USER = os.getenv('RABBITMQ_USER', 'guest')
RABBITMQ_PASSWORD = os.getenv('RABBITMQ_PASSWORD', 'guest')
RABBITMQ_VHOST = os.getenv('RABBITMQ_VHOST', '/')
RABBITMQ_USE_SSL = os.getenv('RABBITMQ_USE_SSL', 'false').lower() == 'true'

# Build broker URL
protocol = 'amqps' if RABBITMQ_USE_SSL else 'amqp'
broker_url = f'{protocol}://{RABBITMQ_USER}:{RABBITMQ_PASSWORD}@{RABBITMQ_HOST}:{RABBITMQ_PORT}/{RABBITMQ_VHOST}'

# Initialize Celery app
app = Celery('myapp', broker=broker_url)

# RabbitMQ broker transport options
app.conf.broker_transport_options = {
    'confirm_publish': True,  # Enable publisher confirms (required for quorum queues)
    'max_retries': 3,
    'interval_start': 0,
    'interval_step': 0.2,
    'interval_max': 0.5,
}

# SSL configuration (if enabled)
if RABBITMQ_USE_SSL:
    import ssl

    ssl_cert = os.getenv('RABBITMQ_SSL_CERT')
    ssl_key = os.getenv('RABBITMQ_SSL_KEY')
    ssl_ca = os.getenv('RABBITMQ_SSL_CA')

    app.conf.broker_use_ssl = {
        'ssl_cert_reqs': ssl.CERT_REQUIRED,
        'ssl_ca_certs': ssl_ca,
        'ssl_certfile': ssl_cert,
        'ssl_keyfile': ssl_key,
    }

# Define exchanges
default_exchange = Exchange('default', type='direct', durable=True)
high_priority_exchange = Exchange('high_priority', type='direct', durable=True)
low_priority_exchange = Exchange('low_priority', type='direct', durable=True)

# Queue configuration with quorum queues for high availability
app.conf.task_queues = (
    # Default queue - quorum queue for reliability
    Queue(
        'default',
        exchange=default_exchange,
        routing_key='default',
        queue_arguments={
            'x-queue-type': 'quorum',  # Quorum queue for HA
            'x-delivery-limit': 3,  # Max redelivery attempts
        }
    ),
    # High priority queue
    Queue(
        'high_priority',
        exchange=high_priority_exchange,
        routing_key='high',
        queue_arguments={
            'x-queue-type': 'quorum',
            'x-max-priority': 10,  # Enable priority levels 0-10
        }
    ),
    # Low priority queue
    Queue(
        'low_priority',
        exchange=low_priority_exchange,
        routing_key='low',
        queue_arguments={
            'x-queue-type': 'quorum',
        }
    ),
)

# Celery configuration
app.conf.update(
    # Task routing
    task_default_queue='default',
    task_default_exchange='default',
    task_default_routing_key='default',

    # Task serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',

    # Result backend (optional - use Redis or database)
    result_backend=os.getenv('CELERY_RESULT_BACKEND'),
    result_expires=3600,

    # Worker settings
    worker_prefetch_multiplier=4,  # Prefetch 4x number of worker concurrency
    worker_max_tasks_per_child=1000,
    worker_disable_rate_limits=False,

    # Task execution
    task_acks_late=True,  # Acknowledge after completion (safer)
    task_reject_on_worker_lost=True,

    # Time limits
    task_time_limit=3600,  # Hard limit: 1 hour
    task_soft_time_limit=3000,  # Soft limit: 50 minutes

    # Timezone
    timezone='UTC',
    enable_utc=True,

    # Event monitoring
    worker_send_task_events=True,
    task_send_sent_event=True,
)

# Task routing rules (optional)
app.conf.task_routes = {
    'myapp.tasks.high_priority_*': {
        'queue': 'high_priority',
        'routing_key': 'high',
    },
    'myapp.tasks.low_priority_*': {
        'queue': 'low_priority',
        'routing_key': 'low',
    },
}

if __name__ == '__main__':
    # Test connection
    try:
        with app.connection() as conn:
            conn.ensure_connection(max_retries=3)
            print("✅ Successfully connected to RabbitMQ broker")
            print(f"Host: {RABBITMQ_HOST}:{RABBITMQ_PORT}")
            print(f"VHost: {RABBITMQ_VHOST}")
            print(f"SSL: {'Enabled' if RABBITMQ_USE_SSL else 'Disabled'}")
    except Exception as e:
        print(f"❌ Failed to connect to RabbitMQ: {e}")
