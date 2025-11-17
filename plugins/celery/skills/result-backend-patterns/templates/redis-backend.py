"""
Celery Redis Result Backend Configuration
==========================================

Redis is recommended for most use cases requiring fast result storage
and retrieval with automatic expiration.

SECURITY: Never hardcode credentials. Use environment variables.
"""

import os
from celery import Celery

# Security: Load credentials from environment
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = os.getenv('REDIS_PORT', '6379')
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')  # Empty if no auth
REDIS_DB = os.getenv('REDIS_DB', '0')

# Construct Redis URL
# Format: redis://[:password@]host:port/db
if REDIS_PASSWORD:
    result_backend = f'redis://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}'
else:
    result_backend = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}'

# For SSL/TLS connections (production recommended)
# result_backend = f'rediss://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}'

app = Celery('myapp', backend=result_backend)

# Redis Backend Configuration
app.conf.update(
    # Connection Settings
    redis_socket_timeout=120,  # Socket timeout in seconds
    redis_socket_connect_timeout=5,  # Connection timeout
    redis_socket_keepalive=True,  # TCP keepalive
    redis_socket_keepalive_options={
        'TCP_KEEPIDLE': 60,
        'TCP_KEEPINTVL': 10,
        'TCP_KEEPCNT': 3,
    },

    # Connection Pool
    redis_max_connections=50,  # Adjust based on worker count
    # redis_max_connections=None,  # No limit (use with caution)

    # Retry on Timeout
    redis_retry_on_timeout=True,

    # Result Expiration (seconds)
    result_expires=86400,  # 24 hours (default)
    # result_expires=3600,  # 1 hour
    # result_expires=None,  # Never expire (not recommended)

    # Serialization
    result_serializer='json',  # Secure, cross-language
    result_accept_content=['json'],  # Whitelist
    result_compression='gzip',  # Compress large results

    # Extended Metadata
    result_extended=True,  # Store task name, args, retries, etc.

    # Backend Retry Logic
    result_backend_always_retry=True,
    result_backend_max_retries=10,
)

# Example Task
@app.task(bind=True)
def example_task(self, x, y):
    """Example task that returns a result"""
    result = x + y
    return {
        'result': result,
        'task_id': self.request.id,
        'task_name': self.name
    }

# Usage
if __name__ == '__main__':
    # Send task
    result = example_task.delay(4, 6)

    # Get result (blocks until ready)
    print(f"Result: {result.get(timeout=10)}")

    # Check status
    print(f"Status: {result.status}")

    # Get metadata
    print(f"Task ID: {result.id}")
    print(f"Ready: {result.ready()}")
    print(f"Successful: {result.successful()}")

    # Cleanup (release resources)
    result.forget()

"""
Environment Variables (.env):
------------------------------
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password_here
REDIS_DB=0

Redis Configuration (redis.conf):
----------------------------------
# For persistence (important for production)
save 900 1      # Save after 900s if 1 key changed
save 300 10     # Save after 300s if 10 keys changed
save 60 10000   # Save after 60s if 10000 keys changed

appendonly yes  # Enable AOF (append-only file)
appendfsync everysec

# Security
requirepass your_strong_password_here
maxmemory 2gb
maxmemory-policy allkeys-lru  # Evict least recently used keys

# Network
bind 127.0.0.1  # Restrict to localhost (or specific IPs)
protected-mode yes
"""
