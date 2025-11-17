"""
Topic Exchange Routing Configuration Template

Topic exchanges allow pattern-based routing using wildcard matching:
- * (star) matches exactly one word
- # (hash) matches zero or more words

Example routing keys:
- user.notification.email matches user.notification.*
- email.welcome.send matches email.#
- report.sales.generate.pdf matches report.*.generate.#

Usage:
    from celery import Celery
    from topic_exchange import configure_topic_routing

    app = Celery('myapp')
    configure_topic_routing(app)
"""

import os
from kombu import Exchange, Queue

# Broker configuration
BROKER_URL = os.environ.get('CELERY_BROKER_URL', 'amqp://guest:guest@localhost:5672//')
RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Topic exchanges for different domains
USER_EXCHANGE = Exchange('user_events', type='topic', durable=True)
EMAIL_EXCHANGE = Exchange('email_tasks', type='topic', durable=True)
REPORT_EXCHANGE = Exchange('report_tasks', type='topic', durable=True)
DATA_EXCHANGE = Exchange('data_tasks', type='topic', durable=True)
NOTIFICATION_EXCHANGE = Exchange('notifications', type='topic', durable=True)

# Queue definitions with topic patterns
CELERY_TOPIC_QUEUES = (
    # User-related queues
    Queue(
        'user_notifications',
        exchange=USER_EXCHANGE,
        routing_key='user.notification.*',  # Matches user.notification.email, user.notification.sms
        queue_arguments={'x-max-length': 10000}
    ),

    Queue(
        'user_profile_updates',
        exchange=USER_EXCHANGE,
        routing_key='user.profile.#',  # Matches user.profile.update, user.profile.photo.upload
        queue_arguments={'x-max-length': 5000}
    ),

    Queue(
        'user_authentication',
        exchange=USER_EXCHANGE,
        routing_key='user.auth.*',  # Matches user.auth.login, user.auth.logout
        queue_arguments={'x-max-length': 5000}
    ),

    # Email queues with different priorities
    Queue(
        'email_transactional',
        exchange=EMAIL_EXCHANGE,
        routing_key='email.transactional.*',  # Welcome, verification, password reset
        queue_arguments={'x-max-priority': 10}
    ),

    Queue(
        'email_marketing',
        exchange=EMAIL_EXCHANGE,
        routing_key='email.marketing.#',  # All marketing emails
        queue_arguments={'x-max-length': 20000}
    ),

    Queue(
        'email_notifications',
        exchange=EMAIL_EXCHANGE,
        routing_key='email.notification.*',  # User notifications via email
        queue_arguments={'x-max-length': 10000}
    ),

    # Report generation queues
    Queue(
        'reports_sales',
        exchange=REPORT_EXCHANGE,
        routing_key='report.sales.#',  # All sales reports
        queue_arguments={'x-max-length': 1000}
    ),

    Queue(
        'reports_analytics',
        exchange=REPORT_EXCHANGE,
        routing_key='report.analytics.#',  # All analytics reports
        queue_arguments={'x-max-length': 1000}
    ),

    Queue(
        'reports_exports',
        exchange=REPORT_EXCHANGE,
        routing_key='report.*.export',  # Any export type
        queue_arguments={'x-max-length': 500}
    ),

    # Data processing queues
    Queue(
        'data_ingestion',
        exchange=DATA_EXCHANGE,
        routing_key='data.ingest.*',  # Data ingestion from various sources
        queue_arguments={'x-max-length': 5000}
    ),

    Queue(
        'data_transformation',
        exchange=DATA_EXCHANGE,
        routing_key='data.transform.#',  # All transformation tasks
        queue_arguments={'x-max-length': 2000}
    ),

    Queue(
        'data_analysis',
        exchange=DATA_EXCHANGE,
        routing_key='data.analyze.*',  # Data analysis tasks
        queue_arguments={'x-max-length': 1000}
    ),

    # Notification queues by channel
    Queue(
        'notifications_push',
        exchange=NOTIFICATION_EXCHANGE,
        routing_key='notification.push.#',  # All push notifications
        queue_arguments={'x-max-length': 15000}
    ),

    Queue(
        'notifications_sms',
        exchange=NOTIFICATION_EXCHANGE,
        routing_key='notification.sms.*',  # SMS notifications
        queue_arguments={'x-max-length': 5000}
    ),

    Queue(
        'notifications_webhook',
        exchange=NOTIFICATION_EXCHANGE,
        routing_key='notification.webhook.#',  # Webhook deliveries
        queue_arguments={'x-max-length': 10000}
    ),
)

# Task routing with topic patterns
CELERY_TOPIC_ROUTES = {
    # User tasks
    'myapp.tasks.send_user_notification': {
        'exchange': 'user_events',
        'routing_key': 'user.notification.email'
    },
    'myapp.tasks.update_user_profile': {
        'exchange': 'user_events',
        'routing_key': 'user.profile.update'
    },
    'myapp.tasks.upload_profile_photo': {
        'exchange': 'user_events',
        'routing_key': 'user.profile.photo.upload'
    },
    'myapp.tasks.process_login': {
        'exchange': 'user_events',
        'routing_key': 'user.auth.login'
    },

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
    'myapp.tasks.send_email_notification': {
        'exchange': 'email_tasks',
        'routing_key': 'email.notification.send'
    },

    # Report tasks
    'myapp.tasks.generate_sales_report': {
        'exchange': 'report_tasks',
        'routing_key': 'report.sales.generate'
    },
    'myapp.tasks.generate_analytics_dashboard': {
        'exchange': 'report_tasks',
        'routing_key': 'report.analytics.dashboard'
    },
    'myapp.tasks.export_user_data': {
        'exchange': 'report_tasks',
        'routing_key': 'report.users.export'
    },

    # Data tasks
    'myapp.tasks.ingest_api_data': {
        'exchange': 'data_tasks',
        'routing_key': 'data.ingest.api'
    },
    'myapp.tasks.transform_raw_data': {
        'exchange': 'data_tasks',
        'routing_key': 'data.transform.raw'
    },
    'myapp.tasks.analyze_user_behavior': {
        'exchange': 'data_tasks',
        'routing_key': 'data.analyze.users'
    },

    # Notification tasks
    'myapp.tasks.send_push_notification': {
        'exchange': 'notifications',
        'routing_key': 'notification.push.send'
    },
    'myapp.tasks.send_sms_notification': {
        'exchange': 'notifications',
        'routing_key': 'notification.sms.send'
    },
    'myapp.tasks.trigger_webhook': {
        'exchange': 'notifications',
        'routing_key': 'notification.webhook.trigger'
    },
}


def route_by_topic_pattern(name, args, kwargs, options, task=None, **kw):
    """
    Dynamic routing using topic patterns

    Analyzes task name and arguments to construct routing key
    """
    # Extract components from task name
    parts = name.split('.')

    if 'user' in name.lower():
        if 'notification' in name.lower():
            return {
                'exchange': 'user_events',
                'routing_key': f'user.notification.{parts[-1]}'
            }
        elif 'profile' in name.lower():
            return {
                'exchange': 'user_events',
                'routing_key': f'user.profile.{parts[-1]}'
            }
        elif 'auth' in name.lower():
            return {
                'exchange': 'user_events',
                'routing_key': f'user.auth.{parts[-1]}'
            }

    if 'email' in name.lower():
        if 'marketing' in name.lower():
            return {
                'exchange': 'email_tasks',
                'routing_key': f'email.marketing.{parts[-1]}'
            }
        elif 'transactional' in name.lower() or any(x in name.lower() for x in ['welcome', 'verify', 'reset']):
            return {
                'exchange': 'email_tasks',
                'routing_key': f'email.transactional.{parts[-1]}'
            }
        else:
            return {
                'exchange': 'email_tasks',
                'routing_key': f'email.notification.{parts[-1]}'
            }

    if 'report' in name.lower():
        report_type = 'general'
        if 'sales' in name.lower():
            report_type = 'sales'
        elif 'analytics' in name.lower():
            report_type = 'analytics'

        action = 'generate'
        if 'export' in name.lower():
            action = 'export'

        return {
            'exchange': 'report_tasks',
            'routing_key': f'report.{report_type}.{action}'
        }

    if 'data' in name.lower():
        if 'ingest' in name.lower():
            return {
                'exchange': 'data_tasks',
                'routing_key': f'data.ingest.{parts[-1]}'
            }
        elif 'transform' in name.lower():
            return {
                'exchange': 'data_tasks',
                'routing_key': f'data.transform.{parts[-1]}'
            }
        elif 'analyze' in name.lower():
            return {
                'exchange': 'data_tasks',
                'routing_key': f'data.analyze.{parts[-1]}'
            }

    # Default routing
    return {
        'exchange': 'default',
        'routing_key': 'default.task'
    }


def configure_topic_routing(app, use_dynamic_routing=False):
    """
    Configure Celery app with topic-based routing

    Args:
        app: Celery application instance
        use_dynamic_routing: If True, use dynamic routing function
                           If False, use static route dictionary
    """
    app.conf.update(
        broker_url=BROKER_URL,
        result_backend=RESULT_BACKEND,
        task_queues=CELERY_TOPIC_QUEUES,
        task_routes=route_by_topic_pattern if use_dynamic_routing else CELERY_TOPIC_ROUTES,

        # Performance settings
        worker_prefetch_multiplier=4,
        task_acks_late=True,
        worker_max_tasks_per_child=1000,

        # Serialization
        task_serializer='json',
        result_serializer='json',
        accept_content=['json'],
    )

    return app


# Worker configuration examples
WORKER_CONFIGURATIONS = {
    'user_worker': {
        'queues': ['user_notifications', 'user_profile_updates', 'user_authentication'],
        'concurrency': 10,
        'command': "celery -A myapp worker -Q user_notifications,user_profile_updates,user_authentication -c 10 -n user@%h"
    },
    'email_worker': {
        'queues': ['email_transactional', 'email_marketing', 'email_notifications'],
        'concurrency': 20,
        'command': "celery -A myapp worker -Q email_transactional,email_marketing,email_notifications -c 20 -n email@%h"
    },
    'report_worker': {
        'queues': ['reports_sales', 'reports_analytics', 'reports_exports'],
        'concurrency': 4,
        'command': "celery -A myapp worker -Q reports_sales,reports_analytics,reports_exports -c 4 -n report@%h"
    },
    'data_worker': {
        'queues': ['data_ingestion', 'data_transformation', 'data_analysis'],
        'concurrency': 8,
        'command': "celery -A myapp worker -Q data_ingestion,data_transformation,data_analysis -c 8 -n data@%h"
    },
    'notification_worker': {
        'queues': ['notifications_push', 'notifications_sms', 'notifications_webhook'],
        'concurrency': 15,
        'command': "celery -A myapp worker -Q notifications_push,notifications_sms,notifications_webhook -c 15 -n notify@%h"
    },
}


# Example usage
if __name__ == '__main__':
    from celery import Celery

    app = Celery('myapp')
    configure_topic_routing(app, use_dynamic_routing=False)

    print("Topic-based routing configured")
    print(f"\nConfigured Exchanges and Queues:")
    for queue in CELERY_TOPIC_QUEUES:
        print(f"  Exchange: {queue.exchange.name} ({queue.exchange.type})")
        print(f"    → Queue: {queue.name}")
        print(f"      Routing Key: {queue.routing_key}\n")

    print(f"Worker Configuration Commands:")
    for worker_name, config in WORKER_CONFIGURATIONS.items():
        print(f"\n{worker_name}:")
        print(f"  {config['command']}")
