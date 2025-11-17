"""
Redis Broker and Result Backend Configuration

Redis is the recommended broker for most use cases due to simplicity
and performance. This template provides production-ready Redis configuration.

Environment Variables Required:
    CELERY_BROKER_URL - Redis connection URL
    CELERY_RESULT_BACKEND - Redis connection URL (can be same as broker)
    REDIS_PASSWORD - Redis password (if authentication enabled)

Security Note:
    NEVER hardcode Redis passwords. Always use environment variables
    or a secrets management system (Doppler, AWS Secrets Manager, etc.)
"""

import os

# ============================================================================
# Basic Redis Configuration
# ============================================================================

# Broker URL format: redis://[:password@]host:port/db
CELERY_BROKER_URL = os.getenv(
    'CELERY_BROKER_URL',
    'redis://localhost:6379/0'
)

# Result backend (can use same Redis instance or different one)
CELERY_RESULT_BACKEND = os.getenv(
    'CELERY_RESULT_BACKEND',
    'redis://localhost:6379/0'
)

# ============================================================================
# Redis Connection Settings
# ============================================================================

# Connection retry on startup
CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True

# Maximum number of connections in the connection pool
CELERY_REDIS_MAX_CONNECTIONS = 50

# Socket timeout (seconds)
CELERY_REDIS_SOCKET_TIMEOUT = 5.0

# Socket connect timeout (seconds)
CELERY_REDIS_SOCKET_CONNECT_TIMEOUT = 5.0

# Connection retry settings
CELERY_BROKER_CONNECTION_RETRY = True
CELERY_BROKER_CONNECTION_MAX_RETRIES = 10

# ============================================================================
# Redis Result Backend Settings
# ============================================================================

# Result expiration time (seconds) - results older than this are deleted
CELERY_RESULT_EXPIRES = 3600  # 1 hour

# Whether to store results persistently or in memory only
CELERY_RESULT_PERSISTENT = False

# Store extended task metadata
CELERY_RESULT_EXTENDED = True

# Backend settings for result fetching
CELERY_RESULT_BACKEND_TRANSPORT_OPTIONS = {
    'master_name': None,  # Redis Sentinel master name (if using Sentinel)
    'socket_timeout': 5.0,
    'socket_connect_timeout': 5.0,
    'retry_on_timeout': True,
    'max_connections': 50,
}

# ============================================================================
# Redis with Authentication
# ============================================================================

"""
# .env.example
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=your_redis_password_here

CELERY_BROKER_URL=redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}
CELERY_RESULT_BACKEND=redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}
"""

# ============================================================================
# Redis Sentinel Configuration (High Availability)
# ============================================================================

# Redis Sentinel provides automatic failover
"""
CELERY_BROKER_URL = 'sentinel://sentinel1:26379;sentinel://sentinel2:26379'
CELERY_BROKER_TRANSPORT_OPTIONS = {
    'master_name': 'mymaster',
    'sentinel_kwargs': {
        'password': os.getenv('REDIS_SENTINEL_PASSWORD'),
    },
    'password': os.getenv('REDIS_PASSWORD'),
    'db': 0,
}

CELERY_RESULT_BACKEND = 'sentinel://sentinel1:26379;sentinel://sentinel2:26379'
CELERY_RESULT_BACKEND_TRANSPORT_OPTIONS = {
    'master_name': 'mymaster',
    'sentinel_kwargs': {
        'password': os.getenv('REDIS_SENTINEL_PASSWORD'),
    },
    'password': os.getenv('REDIS_PASSWORD'),
    'db': 0,
}
"""

# ============================================================================
# Redis Cluster Configuration
# ============================================================================

"""
# For Redis Cluster deployments
CELERY_BROKER_URL = 'redis://node1:6379,node2:6379,node3:6379/0'
CELERY_BROKER_TRANSPORT_OPTIONS = {
    'cluster': {
        'startup_nodes': [
            {'host': 'node1', 'port': 6379},
            {'host': 'node2', 'port': 6379},
            {'host': 'node3', 'port': 6379},
        ],
        'skip_full_coverage_check': True,
    },
    'password': os.getenv('REDIS_PASSWORD'),
}
"""

# ============================================================================
# SSL/TLS Configuration
# ============================================================================

"""
# For Redis with SSL/TLS encryption
CELERY_BROKER_URL = 'rediss://:password@host:6380/0'  # Note: rediss:// (with double 's')
CELERY_BROKER_USE_SSL = {
    'ssl_cert_reqs': 'required',  # or 'optional', 'none'
    'ssl_ca_certs': '/path/to/ca-cert.pem',
    'ssl_certfile': '/path/to/client-cert.pem',
    'ssl_keyfile': '/path/to/client-key.pem',
}

CELERY_REDIS_BACKEND_USE_SSL = {
    'ssl_cert_reqs': 'required',
    'ssl_ca_certs': '/path/to/ca-cert.pem',
    'ssl_certfile': '/path/to/client-cert.pem',
    'ssl_keyfile': '/path/to/client-key.pem',
}
"""

# ============================================================================
# Development vs Production Settings
# ============================================================================

# For development (local Redis, no auth)
if os.getenv('ENVIRONMENT') == 'development':
    CELERY_BROKER_URL = 'redis://localhost:6379/0'
    CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
    CELERY_REDIS_MAX_CONNECTIONS = 10

# For production (authenticated, pooled connections)
elif os.getenv('ENVIRONMENT') == 'production':
    CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL')
    CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND')
    CELERY_REDIS_MAX_CONNECTIONS = 100
    CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True

# ============================================================================
# Health Check Configuration
# ============================================================================

# Ping Redis to ensure connection is healthy
CELERY_BROKER_TRANSPORT_OPTIONS = {
    'health_check_interval': 30,  # Seconds between health checks
    'socket_keepalive': True,
    'socket_keepalive_options': {
        'TCP_KEEPIDLE': 60,
        'TCP_KEEPINTVL': 10,
        'TCP_KEEPCNT': 5,
    },
}

# ============================================================================
# Visibility Timeout (Important!)
# ============================================================================

# Time a message can be invisible before being returned to the queue
# Should be longer than your longest task execution time
CELERY_BROKER_TRANSPORT_OPTIONS = {
    **CELERY_BROKER_TRANSPORT_OPTIONS,
    'visibility_timeout': 3600,  # 1 hour
}

# ============================================================================
# Example: Complete Production Configuration
# ============================================================================

"""
# Production celeryconfig.py with Redis

import os

# Redis connection
broker_url = os.getenv('CELERY_BROKER_URL')
result_backend = os.getenv('CELERY_RESULT_BACKEND')

# Connection settings
broker_connection_retry_on_startup = True
broker_connection_retry = True
broker_connection_max_retries = 10

# Redis-specific settings
redis_max_connections = 100
redis_socket_timeout = 5.0
redis_socket_connect_timeout = 5.0

# Result backend settings
result_expires = 3600
result_persistent = False
result_extended = True

# Transport options
broker_transport_options = {
    'visibility_timeout': 3600,
    'health_check_interval': 30,
    'socket_keepalive': True,
    'retry_on_timeout': True,
    'max_connections': 100,
}

result_backend_transport_options = {
    'retry_on_timeout': True,
    'max_connections': 50,
}

# Security
if os.getenv('REDIS_SSL_ENABLED') == 'true':
    broker_use_ssl = {
        'ssl_cert_reqs': 'required',
        'ssl_ca_certs': os.getenv('REDIS_CA_CERT_PATH'),
    }
    redis_backend_use_ssl = broker_use_ssl
"""

# ============================================================================
# Docker Compose Example
# ============================================================================

"""
# docker-compose.yml

version: '3.8'

services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  celery_worker:
    build: .
    command: celery -A myapp worker --loglevel=info
    environment:
      - CELERY_BROKER_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
      - CELERY_RESULT_BACKEND=redis://:${REDIS_PASSWORD}@redis:6379/0
    depends_on:
      - redis

volumes:
  redis_data:
"""
