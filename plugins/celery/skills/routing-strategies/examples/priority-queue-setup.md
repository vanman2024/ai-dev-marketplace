# Priority Queue Setup Guide

This guide demonstrates how to implement priority-based task routing in Celery with RabbitMQ and Redis.

## Overview

Priority queues allow urgent tasks to jump ahead of lower-priority tasks in the queue. Celery supports priorities from 0 (lowest) to 255 (highest), though most applications use a simpler 0-10 scale.

## Priority Levels

We recommend a 5-level priority system:

- **10 - Critical**: Security alerts, system failures (process immediately)
- **7-9 - High**: User-facing operations, time-sensitive tasks
- **4-6 - Normal**: Standard background tasks (default)
- **1-3 - Low**: Cleanup, maintenance, non-urgent tasks
- **0 - Minimal**: Can be delayed indefinitely

## Implementation with RabbitMQ

RabbitMQ has native priority queue support via the `x-max-priority` queue argument.

### Step 1: Configure Priority Queues

```python
# celery_config.py
from kombu import Exchange, Queue

PRIORITY_EXCHANGE = Exchange('priority_tasks', type='direct', durable=True)

CELERY_QUEUES = (
    # Single queue with priority support
    Queue(
        'priority_queue',
        exchange=PRIORITY_EXCHANGE,
        routing_key='priority',
        queue_arguments={
            'x-max-priority': 10,  # Maximum priority value
        }
    ),
)
```

### Step 2: Define Tasks with Priorities

```python
# tasks.py
from celery import Celery

app = Celery('myapp')

# Method 1: Set priority in task decorator
@app.task(name='critical_task', priority=10)
def critical_security_alert(message):
    """Critical priority task - executes first"""
    # Handle security alert
    pass

@app.task(name='high_priority_task', priority=7)
def user_notification(user_id, message):
    """High priority - user-facing operation"""
    # Send notification
    pass

@app.task(name='normal_task', priority=5)
def generate_report(report_id):
    """Normal priority - standard background task"""
    # Generate report
    pass

@app.task(name='low_priority_task', priority=2)
def cleanup_old_files():
    """Low priority - can be delayed"""
    # Cleanup files
    pass
```

### Step 3: Call Tasks with Runtime Priority

```python
# Method 2: Override priority at runtime
normal_task.apply_async(
    args=[report_id],
    priority=9  # Bump to high priority for this specific call
)

# Method 3: Use priority in kwargs (with dynamic routing)
user_notification.apply_async(
    args=[user_id, message],
    kwargs={'priority': 'high'}
)
```

### Step 4: Start Workers

```bash
# Start worker consuming from priority queue
celery -A myapp worker \
    -Q priority_queue \
    --prefetch-multiplier=1 \
    -c 4 \
    -n priority_worker@%h
```

**Important**: Use `--prefetch-multiplier=1` for better priority handling. Higher prefetch values can cause lower-priority tasks to be fetched before higher-priority ones arrive.

## Implementation with Redis

Redis doesn't have native priority queue support, so we use separate queues per priority level.

### Step 1: Configure Separate Queues

```python
# celery_config.py
from kombu import Exchange, Queue

PRIORITY_EXCHANGE = Exchange('priority_tasks', type='direct', durable=True)

CELERY_QUEUES = (
    Queue('critical_priority', exchange=PRIORITY_EXCHANGE, routing_key='critical'),
    Queue('high_priority', exchange=PRIORITY_EXCHANGE, routing_key='high'),
    Queue('normal_priority', exchange=PRIORITY_EXCHANGE, routing_key='normal'),
    Queue('low_priority', exchange=PRIORITY_EXCHANGE, routing_key='low'),
)

# Route tasks to appropriate queue
CELERY_ROUTES = {
    'tasks.critical_task': {'queue': 'critical_priority'},
    'tasks.high_priority_task': {'queue': 'high_priority'},
    'tasks.normal_task': {'queue': 'normal_priority'},
    'tasks.low_priority_task': {'queue': 'low_priority'},
}
```

### Step 2: Start Workers in Priority Order

```bash
# Worker consumes queues in priority order
celery -A myapp worker \
    -Q critical_priority,high_priority,normal_priority,low_priority \
    --prefetch-multiplier=1 \
    -c 4 \
    -n priority_worker@%h
```

Workers process queues from left to right, so critical tasks are always checked first.

## Testing Priority Configuration

### Test Script

```python
# test_priorities.py
from tasks import critical_task, high_priority_task, normal_task, low_priority_task
import time

print("Sending tasks in reverse priority order...")

# Send low priority first
low_priority_task.apply_async()
print("Sent low priority task")
time.sleep(0.1)

# Send normal priority
normal_task.apply_async()
print("Sent normal priority task")
time.sleep(0.1)

# Send high priority
high_priority_task.apply_async()
print("Sent high priority task")
time.sleep(0.1)

# Send critical priority last
critical_task.apply_async()
print("Sent critical priority task")

print("\nExpected execution order: critical → high → normal → low")
print("Check worker logs to verify priority order")
```

### Expected Worker Output

```
[2025-11-16 10:00:01] Received task: critical_task
[2025-11-16 10:00:01] Task critical_task succeeded
[2025-11-16 10:00:02] Received task: high_priority_task
[2025-11-16 10:00:02] Task high_priority_task succeeded
[2025-11-16 10:00:03] Received task: normal_task
[2025-11-16 10:00:03] Task normal_task succeeded
[2025-11-16 10:00:04] Received task: low_priority_task
[2025-11-16 10:00:04] Task low_priority_task succeeded
```

## Dynamic Priority Routing

For more flexible priority assignment:

```python
# routing.py
def route_by_priority(name, args, kwargs, options, task=None, **kw):
    """
    Route tasks based on priority in kwargs or task metadata
    """
    # Check for priority in kwargs
    priority = kwargs.get('priority', 'normal')

    if isinstance(priority, str):
        queue_map = {
            'critical': 'critical_priority',
            'high': 'high_priority',
            'normal': 'normal_priority',
            'low': 'low_priority',
        }
        queue = queue_map.get(priority.lower(), 'normal_priority')
    else:
        # Numeric priority
        if priority >= 8:
            queue = 'critical_priority'
        elif priority >= 6:
            queue = 'high_priority'
        elif priority >= 4:
            queue = 'normal_priority'
        else:
            queue = 'low_priority'

    return {'queue': queue, 'routing_key': queue.replace('_priority', '')}

# Configure routing
app.conf.task_routes = (route_by_priority,)
```

Usage:

```python
# Route based on string priority
some_task.apply_async(kwargs={'priority': 'high'})

# Route based on numeric priority
some_task.apply_async(priority=9)

# Route based on condition
if is_urgent:
    some_task.apply_async(kwargs={'priority': 'critical'})
else:
    some_task.apply_async(kwargs={'priority': 'normal'})
```

## Monitoring Priority Queues

### Check Queue Lengths (RabbitMQ)

```bash
# Using rabbitmqctl
sudo rabbitmqctl list_queues name messages

# Using RabbitMQ Management API
curl -u guest:guest http://localhost:15672/api/queues
```

### Check Queue Lengths (Redis)

```bash
# Using redis-cli
redis-cli LLEN priority_queue

# For separate queues
redis-cli LLEN critical_priority
redis-cli LLEN high_priority
redis-cli LLEN normal_priority
redis-cli LLEN low_priority
```

### Flower Monitoring

```bash
# Start Flower
celery -A myapp flower

# View at http://localhost:5555
# Shows task counts per queue and priorities
```

## Best Practices

1. **Use Meaningful Priorities**: Reserve 10 for true emergencies only
2. **Low Prefetch**: Set `--prefetch-multiplier=1` for better priority handling
3. **Separate Critical Workers**: Consider dedicated workers for critical tasks
4. **Document Priority Levels**: Make it clear what each priority means
5. **Monitor Queue Lengths**: Alert on buildup in high-priority queues
6. **Test Priority Behavior**: Verify tasks execute in expected order
7. **Don't Overuse High Priority**: If everything is high priority, nothing is
8. **Set Defaults**: Configure `task_default_priority` for consistent behavior

## Common Pitfalls

### Pitfall 1: High Prefetch Multiplier

```python
# ❌ BAD: High prefetch defeats priority
celery -A myapp worker --prefetch-multiplier=10
```

**Problem**: Worker fetches 10 low-priority tasks, then high-priority task arrives. Worker must finish low-priority tasks first.

**Solution**: Use `--prefetch-multiplier=1` for priority queues.

### Pitfall 2: Not Configuring x-max-priority

```python
# ❌ BAD: Missing priority configuration
Queue('tasks', exchange=Exchange('default'), routing_key='tasks')
```

**Problem**: RabbitMQ queue doesn't support priorities without `x-max-priority`.

**Solution**: Add queue arguments:

```python
# ✅ GOOD
Queue('tasks', exchange=Exchange('default'), routing_key='tasks',
      queue_arguments={'x-max-priority': 10})
```

### Pitfall 3: Redis with Single Queue

```python
# ❌ BAD: Redis doesn't support native priorities
Queue('tasks', routing_key='tasks')  # All tasks same priority
```

**Solution**: Use separate queues per priority level.

## Conclusion

Priority queues are essential for handling time-sensitive tasks. Choose the implementation that matches your broker (native support for RabbitMQ, separate queues for Redis) and always test priority behavior before deploying to production.
