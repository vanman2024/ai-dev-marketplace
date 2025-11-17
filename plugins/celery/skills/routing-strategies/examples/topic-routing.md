# Topic-Based Routing Implementation Guide

This guide demonstrates how to implement flexible topic-based routing using RabbitMQ topic exchanges in Celery.

## Overview

Topic exchanges enable pattern-based routing using routing keys with wildcards:
- `*` (star) - Matches exactly one word
- `#` (hash) - Matches zero or more words

This allows creating hierarchical routing structures like:
- `email.transactional.welcome`
- `user.notification.email`
- `report.sales.generate`

## Why Use Topic Routing?

**Advantages:**
- **Flexibility**: Route to multiple queues with patterns
- **Scalability**: Add new task types without changing routing config
- **Organization**: Natural hierarchical structure for related tasks
- **Multi-consumer**: Same task can be consumed by multiple queues

**Use Cases:**
- Event-driven architectures
- Microservices communication
- Notification systems with multiple channels
- Multi-tenant applications

## Implementation

### Step 1: Define Topic Exchanges

```python
# celery_config.py
from kombu import Exchange, Queue

# Create topic exchanges for different domains
EMAIL_EXCHANGE = Exchange('email_tasks', type='topic', durable=True)
USER_EXCHANGE = Exchange('user_events', type='topic', durable=True)
REPORT_EXCHANGE = Exchange('report_tasks', type='topic', durable=True)
NOTIFICATION_EXCHANGE = Exchange('notifications', type='topic', durable=True)
```

### Step 2: Configure Queues with Routing Patterns

```python
CELERY_QUEUES = (
    # Email queues
    Queue(
        'email_transactional',
        exchange=EMAIL_EXCHANGE,
        routing_key='email.transactional.*',  # Matches welcome, verification, reset
    ),
    Queue(
        'email_marketing',
        exchange=EMAIL_EXCHANGE,
        routing_key='email.marketing.#',  # Matches all marketing emails
    ),
    Queue(
        'email_notifications',
        exchange=EMAIL_EXCHANGE,
        routing_key='email.notification.*',
    ),

    # User event queues
    Queue(
        'user_notifications',
        exchange=USER_EXCHANGE,
        routing_key='user.notification.*',  # user.notification.email, user.notification.sms
    ),
    Queue(
        'user_profile_updates',
        exchange=USER_EXCHANGE,
        routing_key='user.profile.#',  # user.profile.update, user.profile.photo.upload
    ),

    # Report queues
    Queue(
        'reports_sales',
        exchange=REPORT_EXCHANGE,
        routing_key='report.sales.#',  # All sales reports
    ),
    Queue(
        'reports_analytics',
        exchange=REPORT_EXCHANGE,
        routing_key='report.analytics.#',
    ),

    # Notification channels
    Queue(
        'notifications_push',
        exchange=NOTIFICATION_EXCHANGE,
        routing_key='notification.push.#',
    ),
    Queue(
        'notifications_sms',
        exchange=NOTIFICATION_EXCHANGE,
        routing_key='notification.sms.*',
    ),
)
```

### Step 3: Configure Task Routes

```python
CELERY_ROUTES = {
    # Email tasks
    'myapp.tasks.send_welcome_email': {
        'exchange': 'email_tasks',
        'routing_key': 'email.transactional.welcome'
    },
    'myapp.tasks.send_verification_email': {
        'exchange': 'email_tasks',
        'routing_key': 'email.transactional.verification'
    },
    'myapp.tasks.send_marketing_campaign': {
        'exchange': 'email_tasks',
        'routing_key': 'email.marketing.campaign.send'
    },

    # User tasks
    'myapp.tasks.notify_user_email': {
        'exchange': 'user_events',
        'routing_key': 'user.notification.email'
    },
    'myapp.tasks.update_profile': {
        'exchange': 'user_events',
        'routing_key': 'user.profile.update'
    },

    # Report tasks
    'myapp.tasks.generate_sales_report': {
        'exchange': 'report_tasks',
        'routing_key': 'report.sales.generate'
    },
}
```

### Step 4: Apply Configuration

```python
# app.py
from celery import Celery
from celery_config import CELERY_QUEUES, CELERY_ROUTES

app = Celery('myapp')

app.conf.update(
    broker_url=os.environ.get('CELERY_BROKER_URL'),
    task_queues=CELERY_QUEUES,
    task_routes=CELERY_ROUTES,
)
```

## Routing Key Patterns

### Exact Match
```python
routing_key='email.welcome'
# Matches only: email.welcome
```

### Single Wildcard (*)
```python
routing_key='email.*.send'
# Matches:
#   email.welcome.send ✓
#   email.notification.send ✓
#   email.marketing.campaign.send ✗ (two words between)
```

### Multi Wildcard (#)
```python
routing_key='email.#'
# Matches:
#   email.send ✓
#   email.welcome.send ✓
#   email.marketing.campaign.send ✓
#   email.anything.goes.here ✓
```

### Combined Wildcards
```python
routing_key='*.notification.#'
# Matches:
#   user.notification.email ✓
#   user.notification.sms ✓
#   admin.notification.security.alert ✓
#   notification.email ✗ (no word before notification)
```

## Dynamic Topic Routing

For flexible routing based on task characteristics:

```python
# routing.py
def route_by_topic_pattern(name, args, kwargs, options, task=None, **kw):
    """
    Generate routing key from task name and arguments
    """
    parts = name.split('.')

    # Email tasks
    if 'email' in name.lower():
        email_type = 'notification'
        if 'welcome' in name.lower() or 'verify' in name.lower():
            email_type = 'transactional'
        elif 'marketing' in name.lower():
            email_type = 'marketing'

        return {
            'exchange': 'email_tasks',
            'routing_key': f'email.{email_type}.{parts[-1]}'
        }

    # User tasks
    if 'user' in name.lower():
        action = parts[-1]  # Last part is action (update, create, delete)
        category = 'general'

        if 'notification' in name.lower():
            category = 'notification'
        elif 'profile' in name.lower():
            category = 'profile'

        return {
            'exchange': 'user_events',
            'routing_key': f'user.{category}.{action}'
        }

    # Report tasks
    if 'report' in name.lower():
        report_type = 'general'
        if 'sales' in name.lower():
            report_type = 'sales'
        elif 'analytics' in name.lower():
            report_type = 'analytics'

        return {
            'exchange': 'report_tasks',
            'routing_key': f'report.{report_type}.{parts[-1]}'
        }

    # Default routing
    return {'exchange': 'default', 'routing_key': 'default.task'}

# Configure dynamic routing
app.conf.task_routes = (route_by_topic_pattern,)
```

## Multi-Queue Routing

Topic exchanges allow a single task to be routed to multiple queues:

```python
# Email task routed to TWO queues
CELERY_QUEUES = (
    # Queue 1: All emails
    Queue('all_emails', exchange=EMAIL_EXCHANGE, routing_key='email.#'),

    # Queue 2: Transactional emails only
    Queue('transactional_emails', exchange=EMAIL_EXCHANGE, routing_key='email.transactional.*'),
)

# When you send email.transactional.welcome:
# → Goes to BOTH all_emails and transactional_emails queues
```

**Use cases:**
- Logging/audit trail (all tasks go to logging queue)
- Analytics (all tasks go to analytics queue)
- Multi-region processing (same task processed in multiple regions)

## Worker Configuration

### Specialized Workers

```bash
# Email worker (all email queues)
celery -A myapp worker \
    -Q email_transactional,email_marketing,email_notifications \
    -c 20 \
    -n email_worker@%h

# User worker (all user queues)
celery -A myapp worker \
    -Q user_notifications,user_profile_updates \
    -c 10 \
    -n user_worker@%h

# Report worker (all report queues)
celery -A myapp worker \
    -Q reports_sales,reports_analytics \
    -c 4 \
    -n report_worker@%h
```

### Multi-Domain Workers

```bash
# Worker handling multiple domains
celery -A myapp worker \
    -Q email_transactional,user_notifications,reports_sales \
    -c 15 \
    -n general_worker@%h
```

## Testing Topic Routing

### Test Script

```python
# test_topic_routing.py
from myapp import app
from kombu import Connection

# Get broker connection
with Connection(app.conf.broker_url) as conn:
    # Create producer
    producer = conn.Producer()

    # Test different routing keys
    test_messages = [
        ('email.transactional.welcome', {'user_id': 123}),
        ('email.marketing.campaign.send', {'campaign_id': 456}),
        ('user.notification.email', {'user_id': 789}),
        ('user.profile.update', {'user_id': 789}),
        ('report.sales.generate', {'month': '2025-11'}),
    ]

    for routing_key, payload in test_messages:
        # Extract exchange from routing key
        domain = routing_key.split('.')[0]
        exchange_map = {
            'email': 'email_tasks',
            'user': 'user_events',
            'report': 'report_tasks',
        }
        exchange = exchange_map.get(domain, 'default')

        # Publish message
        producer.publish(
            payload,
            exchange=exchange,
            routing_key=routing_key,
            serializer='json'
        )
        print(f"Sent: {routing_key} → {exchange}")

print("\nCheck worker logs to verify routing")
```

### Verify Routing with RabbitMQ

```bash
# List all queues and message counts
sudo rabbitmqctl list_queues name messages

# Inspect queue bindings
sudo rabbitmqctl list_bindings

# Check specific queue bindings
sudo rabbitmqctl list_bindings | grep email_transactional
```

## Advanced Patterns

### Priority + Topic Routing

```python
Queue(
    'email_urgent',
    exchange=EMAIL_EXCHANGE,
    routing_key='email.*.urgent',
    queue_arguments={'x-max-priority': 10}
)

# Route urgent emails
'myapp.tasks.urgent_email': {
    'exchange': 'email_tasks',
    'routing_key': 'email.transactional.urgent',
    'priority': 9
}
```

### Geographic Routing

```python
# Different queues per region
Queue('tasks_us_east', exchange=TASKS_EXCHANGE, routing_key='tasks.us-east.#')
Queue('tasks_eu_west', exchange=TASKS_EXCHANGE, routing_key='tasks.eu-west.#')

# Dynamic region routing
def route_by_region(name, args, kwargs, options, task=None, **kw):
    region = kwargs.get('region', 'us-east')
    return {
        'exchange': 'tasks',
        'routing_key': f'tasks.{region}.{name.split(".")[-1]}'
    }
```

### Event Bus Pattern

```python
# Publish events to multiple consumers
EVENT_EXCHANGE = Exchange('events', type='topic', durable=True)

CELERY_QUEUES = (
    # Analytics consumer
    Queue('analytics', exchange=EVENT_EXCHANGE, routing_key='event.#'),

    # Logging consumer
    Queue('logs', exchange=EVENT_EXCHANGE, routing_key='event.#'),

    # User-specific events
    Queue('user_events', exchange=EVENT_EXCHANGE, routing_key='event.user.#'),
)

# Publish event (goes to all matching queues)
app.send_task(
    'myapp.tasks.log_event',
    exchange='events',
    routing_key='event.user.login'
)
```

## Best Practices

1. **Consistent Naming**: Use clear, hierarchical routing key structure
2. **Document Patterns**: Maintain documentation of routing key conventions
3. **Avoid Deep Hierarchies**: Keep routing keys to 3-4 levels maximum
4. **Use Wildcards Sparingly**: Over-broad patterns can cause unintended routing
5. **Test Routing**: Always test new routing keys before production
6. **Monitor Queue Lengths**: Ensure tasks are reaching intended queues
7. **Version Routing Keys**: Include version in key for breaking changes (e.g., `email.v2.welcome`)

## Common Pitfalls

### Pitfall 1: Over-broad Wildcards

```python
# ❌ BAD: Too broad, matches everything
routing_key='#'
```

**Solution**: Be specific about what you want to match.

### Pitfall 2: Forgetting Word Boundaries

```python
# Pattern: email.*.send
# Task: email.marketing.campaign.send
# ❌ Doesn't match! (two words between email and send)
```

**Solution**: Use `#` for multi-word matching.

### Pitfall 3: Inconsistent Naming

```python
# ❌ BAD: Inconsistent structure
routing_key='send.email.welcome'
routing_key='email.marketing.send'
```

**Solution**: Establish naming convention (e.g., always `domain.category.action`).

## Conclusion

Topic-based routing provides flexibility and scalability for complex Celery applications. Use meaningful routing key hierarchies and test patterns thoroughly before deploying to production.
