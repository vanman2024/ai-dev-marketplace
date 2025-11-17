"""
Celery RPC Result Backend Configuration
========================================

RPC backend returns results as AMQP messages, ideal for transient results
that are consumed immediately by the initiating client.

Advantages:
- No additional backend service required
- Minimal infrastructure
- Fast result delivery

Limitations:
- Results can only be retrieved once
- Lost on broker restart (unless persistent mode enabled)
- Only accessible by the client that sent the task

SECURITY: Broker credentials should be in environment variables.
"""

import os
from celery import Celery

# Security: Load broker credentials from environment
BROKER_USER = os.getenv('BROKER_USER', 'guest')
BROKER_PASSWORD = os.getenv('BROKER_PASSWORD', 'your_broker_password_here')
BROKER_HOST = os.getenv('BROKER_HOST', 'localhost')
BROKER_PORT = os.getenv('BROKER_PORT', '5672')
BROKER_VHOST = os.getenv('BROKER_VHOST', '/')

# Construct broker URL
broker_url = f'amqp://{BROKER_USER}:{BROKER_PASSWORD}@{BROKER_HOST}:{BROKER_PORT}/{BROKER_VHOST}'

# RPC backend uses the broker for results
result_backend = 'rpc://'

app = Celery('myapp', broker=broker_url, backend=result_backend)

# RPC Backend Configuration
app.conf.update(
    # Persistence
    result_persistent=True,  # Results survive broker restarts
    # result_persistent=False,  # Default: transient results

    # Result Exchange Configuration
    result_exchange='celery_results',
    result_exchange_type='direct',

    # Serialization
    result_serializer='json',
    result_accept_content=['json'],
    result_compression='gzip',

    # Expiration
    # Note: RPC backend doesn't have built-in expiration
    # Results are cleaned up when retrieved or broker restarts
    result_expires=3600,  # 1 hour (advisory only)

    # Chord Settings (for group coordination)
    result_chord_join_timeout=3.0,
)

# Example Tasks
@app.task(bind=True)
def immediate_result_task(self, x, y):
    """Task designed for immediate result consumption"""
    result = x * y
    return {
        'result': result,
        'task_id': self.request.id
    }

@app.task(bind=True, ignore_result=True)
def notification_task(self, message):
    """Fire-and-forget notification task"""
    print(f"Notification: {message}")
    # No result stored

# Usage Pattern
def synchronous_pattern():
    """Typical RPC backend usage: send task and wait for result"""
    # Send task
    result = immediate_result_task.delay(10, 5)

    # Block until result ready
    try:
        value = result.get(timeout=10)
        print(f"Result: {value}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # IMPORTANT: Results can only be retrieved once with RPC backend
        # After get(), the result is consumed and removed
        pass

# Asynchronous Pattern (Not Recommended for RPC)
def async_pattern_warning():
    """
    WARNING: RPC backend is NOT ideal for async patterns

    Problem: If the client disconnects or crashes before calling get(),
    the result is lost forever.

    For async patterns, use Redis or Database backend instead.
    """
    result = immediate_result_task.delay(10, 5)
    # Don't disconnect or the result will be lost!
    # Must call result.get() in the same process/session

# Persistent Mode Example
def configure_persistent_results():
    """Enable persistent results for reliability"""
    app.conf.update(
        result_persistent=True,  # Results survive broker restarts

        # Also configure broker for persistence
        broker_connection_retry_on_startup=True,
        broker_connection_max_retries=10,
    )

# Monitoring Results
def check_result_status(result):
    """Check result status without consuming it"""
    # Note: state() works, but get() consumes the result
    print(f"Task ID: {result.id}")
    print(f"Status: {result.status}")  # PENDING, SUCCESS, FAILURE
    print(f"Ready: {result.ready()}")

    # WARNING: get() will consume the result!
    # After get(), subsequent get() calls will fail
    if result.ready():
        value = result.get(timeout=1)
        print(f"Value: {value}")

if __name__ == '__main__':
    # Example 1: Synchronous pattern (recommended)
    print("=== Synchronous Pattern ===")
    result = immediate_result_task.delay(7, 8)
    print(f"Result: {result.get(timeout=10)}")

    # Example 2: Check status before getting
    print("\n=== Status Check Pattern ===")
    result = immediate_result_task.delay(3, 4)
    print(f"Status: {result.status}")

    import time
    while not result.ready():
        print("Waiting...")
        time.sleep(0.5)

    print(f"Result: {result.get()}")

"""
Environment Variables (.env):
------------------------------
BROKER_USER=guest
BROKER_PASSWORD=your_broker_password_here
BROKER_HOST=localhost
BROKER_PORT=5672
BROKER_VHOST=/

RabbitMQ Configuration:
-----------------------
# Create user
rabbitmqctl add_user celery your_secure_password_here

# Set permissions
rabbitmqctl set_permissions -p / celery ".*" ".*" ".*"

# For persistence, configure queue durability
rabbitmqctl set_policy celery_results "^celery_results" \
  '{"queue-mode":"lazy","max-length":10000}' \
  --apply-to queues

When to Use RPC Backend:
------------------------
✅ DO USE when:
- Results consumed immediately
- Single client per task
- Minimal infrastructure requirements
- Microservice architectures with direct responses

❌ DON'T USE when:
- Multiple clients need results
- Results needed after client disconnect
- Long-term result storage required
- Async/background result retrieval patterns

Alternative: Consider Redis backend if you need:
- Multiple result retrievals
- Result persistence beyond immediate consumption
- Better async patterns
- Automatic expiration and cleanup
"""
