"""
RabbitMQ Broker Configuration

RabbitMQ is recommended for production deployments requiring:
- Advanced routing and message patterns
- High reliability and message persistence
- Complex queue topologies
- Built-in management UI and monitoring

Environment Variables Required:
    CELERY_BROKER_URL - RabbitMQ connection URL
    RABBITMQ_USER - RabbitMQ username
    RABBITMQ_PASSWORD - RabbitMQ password

Security Note:
    NEVER hardcode RabbitMQ credentials. Always use environment variables
    or a secrets management system.
"""

import os

# ============================================================================
# Basic RabbitMQ Configuration
# ============================================================================

# Broker URL format: amqp://user:password@host:port/vhost
CELERY_BROKER_URL = os.getenv(
    'CELERY_BROKER_URL',
    'amqp://guest:guest@localhost:5672//'
)

# Result backend options for RabbitMQ
# Option 1: RPC backend (recommended for RabbitMQ)
CELERY_RESULT_BACKEND = 'rpc://'

# Option 2: Use Redis for results (common pattern)
# CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Option 3: Use AMQP for results (not recommended for most cases)
# CELERY_RESULT_BACKEND = 'amqp://guest:guest@localhost:5672//'

# ============================================================================
# RabbitMQ Connection Settings
# ============================================================================

# Connection retry on startup
CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True

# Connection retry settings
CELERY_BROKER_CONNECTION_RETRY = True
CELERY_BROKER_CONNECTION_MAX_RETRIES = 10

# Heartbeat interval (seconds) - keeps connection alive
CELERY_BROKER_HEARTBEAT = 60

# Connection pool settings
CELERY_BROKER_POOL_LIMIT = 10

# ============================================================================
# Queue and Exchange Configuration
# ============================================================================

# Task routing to different queues
CELERY_TASK_ROUTES = {
    # Critical tasks go to high-priority queue
    'app.tasks.critical': {
        'queue': 'critical',
        'routing_key': 'critical.tasks',
    },
    # Normal tasks
    'app.tasks.normal': {
        'queue': 'default',
        'routing_key': 'default.tasks',
    },
    # Email tasks
    'app.tasks.email': {
        'queue': 'emails',
        'routing_key': 'email.send',
    },
    # Long-running tasks
    'app.tasks.long': {
        'queue': 'long_running',
        'routing_key': 'long.tasks',
    },
}

# Default queue settings
CELERY_TASK_DEFAULT_QUEUE = 'default'
CELERY_TASK_DEFAULT_EXCHANGE = 'tasks'
CELERY_TASK_DEFAULT_EXCHANGE_TYPE = 'topic'
CELERY_TASK_DEFAULT_ROUTING_KEY = 'task.default'

# ============================================================================
# Queue Declarations
# ============================================================================

from kombu import Exchange, Queue

# Define exchanges
default_exchange = Exchange('tasks', type='topic', durable=True)
critical_exchange = Exchange('critical', type='direct', durable=True)

# Define queues
CELERY_TASK_QUEUES = (
    # Default queue
    Queue(
        'default',
        exchange=default_exchange,
        routing_key='default.#',
        queue_arguments={'x-max-priority': 10}
    ),
    # Critical queue with higher priority
    Queue(
        'critical',
        exchange=critical_exchange,
        routing_key='critical',
        queue_arguments={
            'x-max-priority': 10,
            'x-message-ttl': 300000,  # 5 minutes
        }
    ),
    # Email queue
    Queue(
        'emails',
        exchange=default_exchange,
        routing_key='email.#',
        queue_arguments={'x-max-priority': 5}
    ),
    # Long-running tasks queue
    Queue(
        'long_running',
        exchange=default_exchange,
        routing_key='long.#',
        queue_arguments={
            'x-max-priority': 3,
            'x-message-ttl': 3600000,  # 1 hour
        }
    ),
)

# ============================================================================
# Dead Letter Queue Configuration
# ============================================================================

# Dead letter exchange for failed messages
dead_letter_exchange = Exchange('dead_letters', type='topic', durable=True)

# Add dead letter queue to handle failed tasks
CELERY_TASK_QUEUES += (
    Queue(
        'failed_tasks',
        exchange=dead_letter_exchange,
        routing_key='#',
        durable=True
    ),
)

# Configure queues with dead letter exchange
"""
CELERY_TASK_QUEUES = (
    Queue(
        'default',
        exchange=default_exchange,
        routing_key='default.#',
        queue_arguments={
            'x-dead-letter-exchange': 'dead_letters',
            'x-dead-letter-routing-key': 'failed.default',
        }
    ),
)
"""

# ============================================================================
# Priority Queues
# ============================================================================

# Enable task priority support
CELERY_TASK_ACKS_LATE = True
CELERY_WORKER_PREFETCH_MULTIPLIER = 1

# Priority queue configuration
"""
# In tasks.py:
@app.task(priority=10)  # Highest priority
def critical_task():
    pass

@app.task(priority=5)   # Medium priority
def normal_task():
    pass

@app.task(priority=1)   # Low priority
def background_task():
    pass
"""

# ============================================================================
# Message TTL and Expiration
# ============================================================================

# Task result expiration
CELERY_RESULT_EXPIRES = 3600  # 1 hour

# Task hard time limit (seconds)
CELERY_TASK_TIME_LIMIT = 300  # 5 minutes

# Task soft time limit (seconds)
CELERY_TASK_SOFT_TIME_LIMIT = 240  # 4 minutes

# ============================================================================
# SSL/TLS Configuration
# ============================================================================

"""
# For RabbitMQ with SSL/TLS encryption
import ssl

CELERY_BROKER_URL = 'amqps://user:password@host:5671/vhost'  # Note: amqps:// and port 5671
CELERY_BROKER_USE_SSL = {
    'keyfile': '/path/to/client-key.pem',
    'certfile': '/path/to/client-cert.pem',
    'ca_certs': '/path/to/ca-cert.pem',
    'cert_reqs': ssl.CERT_REQUIRED,
}
"""

# ============================================================================
# Virtual Hosts Configuration
# ============================================================================

"""
# Use virtual hosts to isolate environments
# Development
CELERY_BROKER_URL = 'amqp://user:pass@localhost:5672/dev'

# Staging
CELERY_BROKER_URL = 'amqp://user:pass@localhost:5672/staging'

# Production
CELERY_BROKER_URL = 'amqp://user:pass@localhost:5672/prod'
"""

# ============================================================================
# High Availability Configuration
# ============================================================================

"""
# Multiple RabbitMQ nodes (cluster)
CELERY_BROKER_URL = [
    'amqp://user:pass@rabbit1:5672//',
    'amqp://user:pass@rabbit2:5672//',
    'amqp://user:pass@rabbit3:5672//',
]

# Broker transport options for HA
CELERY_BROKER_TRANSPORT_OPTIONS = {
    'confirm_publish': True,  # Ensure messages are confirmed
    'max_retries': 3,
    'interval_start': 0,
    'interval_step': 0.2,
    'interval_max': 0.5,
}
"""

# ============================================================================
# Development vs Production Settings
# ============================================================================

# Environment-specific configuration
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development')

if ENVIRONMENT == 'development':
    CELERY_BROKER_URL = 'amqp://guest:guest@localhost:5672//'
    CELERY_RESULT_BACKEND = 'rpc://'
    CELERY_TASK_ALWAYS_EAGER = False  # Set True to run tasks synchronously

elif ENVIRONMENT == 'production':
    CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL')
    CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND')
    CELERY_BROKER_POOL_LIMIT = 50
    CELERY_BROKER_HEARTBEAT = 30

# ============================================================================
# Worker Configuration for RabbitMQ
# ============================================================================

# Prefetch settings
CELERY_WORKER_PREFETCH_MULTIPLIER = 4  # How many tasks to prefetch per worker

# Task acknowledgment
CELERY_TASK_ACKS_LATE = True  # Acknowledge after task completes
CELERY_TASK_REJECT_ON_WORKER_LOST = True  # Requeue if worker dies

# ============================================================================
# Example: Complete Production Configuration
# ============================================================================

"""
# Production celeryconfig.py with RabbitMQ

import os
from kombu import Exchange, Queue

# RabbitMQ connection
broker_url = os.getenv('CELERY_BROKER_URL')
result_backend = 'rpc://'

# Connection settings
broker_connection_retry_on_startup = True
broker_connection_retry = True
broker_connection_max_retries = 10
broker_heartbeat = 60
broker_pool_limit = 50

# Queue configuration
task_default_queue = 'default'
task_default_exchange = 'tasks'
task_default_exchange_type = 'topic'
task_default_routing_key = 'task.default'

# Define queues
task_queues = (
    Queue('default', Exchange('tasks', type='topic'), routing_key='default.#'),
    Queue('critical', Exchange('critical', type='direct'), routing_key='critical'),
    Queue('emails', Exchange('tasks', type='topic'), routing_key='email.#'),
)

# Task routing
task_routes = {
    'app.tasks.critical': {'queue': 'critical', 'routing_key': 'critical'},
    'app.tasks.send_email': {'queue': 'emails', 'routing_key': 'email.send'},
}

# Worker settings
worker_prefetch_multiplier = 4
task_acks_late = True
task_reject_on_worker_lost = True

# Time limits
task_time_limit = 300
task_soft_time_limit = 240

# Result expiration
result_expires = 3600

# High availability
broker_transport_options = {
    'confirm_publish': True,
    'max_retries': 3,
}
"""

# ============================================================================
# Docker Compose Example
# ============================================================================

"""
# docker-compose.yml

version: '3.8'

services:
  rabbitmq:
    image: rabbitmq:3-management-alpine
    ports:
      - "5672:5672"    # AMQP port
      - "15672:15672"  # Management UI
    environment:
      - RABBITMQ_DEFAULT_USER=${RABBITMQ_USER}
      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD}
      - RABBITMQ_DEFAULT_VHOST=/
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  celery_worker:
    build: .
    command: celery -A myapp worker --loglevel=info
    environment:
      - CELERY_BROKER_URL=amqp://${RABBITMQ_USER}:${RABBITMQ_PASSWORD}@rabbitmq:5672//
      - CELERY_RESULT_BACKEND=rpc://
    depends_on:
      - rabbitmq

volumes:
  rabbitmq_data:
"""

# ============================================================================
# RabbitMQ Management Commands
# ============================================================================

"""
# Create vhost
rabbitmqctl add_vhost myapp_prod

# Create user
rabbitmqctl add_user myapp_user secure_password_here

# Set permissions
rabbitmqctl set_permissions -p myapp_prod myapp_user ".*" ".*" ".*"

# Enable management plugin
rabbitmq-plugins enable rabbitmq_management

# Check queues
celery -A myapp inspect active_queues

# Purge queue
celery -A myapp purge
"""
