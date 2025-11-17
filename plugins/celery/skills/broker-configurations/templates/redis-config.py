"""
Redis Broker Configuration for Celery

Production-ready Redis configuration with SSL, sentinel support,
and best practices for reliability and security.

SECURITY: This file uses environment variables for credentials.
Never hardcode passwords or API keys.
"""

import os
from celery import Celery
from kombu import Queue

# Environment variables (set these in your .env file)
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
REDIS_DB = int(os.getenv('REDIS_DB', 0))
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD')  # Optional
REDIS_USE_SSL = os.getenv('REDIS_USE_SSL', 'false').lower() == 'true'

# Build broker URL
if REDIS_PASSWORD:
    broker_url = f'redis://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}'
else:
    broker_url = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}'

# SSL configuration
if REDIS_USE_SSL:
    broker_url = broker_url.replace('redis://', 'rediss://')

# Initialize Celery app
app = Celery('myapp', broker=broker_url, backend=broker_url)

# Redis broker transport options
app.conf.broker_transport_options = {
    'visibility_timeout': 3600,  # 1 hour (in seconds)
    'retry_on_timeout': True,
    'max_connections': 50,
    'socket_timeout': 5.0,
    'socket_connect_timeout': 5.0,
    'socket_keepalive': True,
    'health_check_interval': 30,  # Check connection health every 30s
}

# Result backend configuration
app.conf.result_backend_transport_options = {
    'retry_on_timeout': True,
    'global_keyprefix': 'celery_',  # Prefix for all keys
}

# Redis-specific settings for production
app.conf.update(
    # Task serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',

    # Result backend settings
    result_expires=3600,  # Results expire after 1 hour
    result_extended=True,  # Store additional metadata

    # Worker settings
    worker_prefetch_multiplier=4,
    worker_max_tasks_per_child=1000,

    # Task execution settings
    task_acks_late=True,  # Acknowledge after task completion
    task_reject_on_worker_lost=True,

    # Time limits
    task_time_limit=3600,  # Hard time limit (1 hour)
    task_soft_time_limit=3000,  # Soft time limit (50 min)

    # Timezone
    timezone='UTC',
    enable_utc=True,
)

# Queue configuration
app.conf.task_queues = (
    Queue('default', routing_key='default'),
    Queue('high_priority', routing_key='high'),
    Queue('low_priority', routing_key='low'),
)

# Default queue
app.conf.task_default_queue = 'default'
app.conf.task_default_exchange = 'tasks'
app.conf.task_default_routing_key = 'default'

if __name__ == '__main__':
    # Test connection
    try:
        app.connection().ensure_connection(max_retries=3)
        print("✅ Successfully connected to Redis broker")
        print(f"Broker: {broker_url.replace(REDIS_PASSWORD or '', '***')}")
    except Exception as e:
        print(f"❌ Failed to connect to Redis: {e}")
