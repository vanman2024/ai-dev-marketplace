"""
Celery Beat Crontab Schedule Configuration

Provides comprehensive crontab-based periodic task scheduling patterns.
Use for time-of-day specific task execution requirements.

Security: No hardcoded credentials - all configuration from environment.
"""

from celery import Celery
from celery.schedules import crontab
import os

# Initialize Celery app
app = Celery('tasks')

# Load configuration from environment
app.config_from_object('celeryconfig')

# Alternative: Direct configuration
app.conf.update(
    broker_url=os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0'),
    result_backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0'),
    timezone='UTC',  # Set your timezone
)

# Crontab Schedule Configuration
app.conf.beat_schedule = {
    # Daily task at midnight
    'daily-midnight-task': {
        'task': 'tasks.daily_report',
        'schedule': crontab(hour=0, minute=0),
        'args': (),
    },

    # Weekday morning task
    'weekday-morning-task': {
        'task': 'tasks.morning_sync',
        'schedule': crontab(hour=7, minute=30, day_of_week='mon-fri'),
        'args': (),
    },

    # Every 15 minutes during business hours
    'business-hours-task': {
        'task': 'tasks.process_orders',
        'schedule': crontab(hour='9-17', minute='*/15', day_of_week='mon-fri'),
        'args': (),
    },

    # Weekly task (Monday at 3am)
    'weekly-maintenance': {
        'task': 'tasks.weekly_cleanup',
        'schedule': crontab(hour=3, minute=0, day_of_week=1),
        'args': (),
    },

    # Monthly task (1st of month at midnight)
    'monthly-report': {
        'task': 'tasks.monthly_report',
        'schedule': crontab(hour=0, minute=0, day_of_month=1),
        'args': (),
    },

    # Multiple time windows
    'peak-hours-processing': {
        'task': 'tasks.process_peak_load',
        'schedule': crontab(hour='8,12,18', minute=0),
        'args': (),
    },

    # Every hour on the hour
    'hourly-task': {
        'task': 'tasks.hourly_sync',
        'schedule': crontab(minute=0),
        'args': (),
    },

    # End of business day
    'end-of-day-task': {
        'task': 'tasks.eod_report',
        'schedule': crontab(hour=17, minute=0, day_of_week='mon-fri'),
        'args': (),
    },

    # Weekend batch processing
    'weekend-batch': {
        'task': 'tasks.batch_process',
        'schedule': crontab(hour=2, minute=0, day_of_week='sat,sun'),
        'args': (),
    },

    # Quarter-hour intervals
    'quarter-hour-check': {
        'task': 'tasks.status_check',
        'schedule': crontab(minute='0,15,30,45'),
        'args': (),
    },

    # First weekday of month
    'first-weekday-of-month': {
        'task': 'tasks.monthly_billing',
        'schedule': crontab(hour=8, minute=0, day_of_month='1-7', day_of_week=1),
        'args': (),
    },

    # Last day of month (approximate - day 28-31)
    'end-of-month-task': {
        'task': 'tasks.month_end_close',
        'schedule': crontab(hour=23, minute=0, day_of_month='28-31'),
        'args': (),
    },
}

# Advanced Crontab Patterns
app.conf.beat_schedule.update({
    # Complex pattern: Every 10 minutes on Thu/Fri between specific hours
    'complex-schedule': {
        'task': 'tasks.complex_job',
        'schedule': crontab(
            minute='*/10',
            hour='3-4,17-18,22-23',
            day_of_week='thu,fri'
        ),
        'args': (),
    },

    # Task with kwargs and options
    'task-with-options': {
        'task': 'tasks.process_data',
        'schedule': crontab(hour=1, minute=0),
        'kwargs': {'priority': 'high', 'batch_size': 1000},
        'options': {
            'expires': 3600,  # Task expires after 1 hour
            'queue': 'priority',
        }
    },
})


# Crontab Expression Reference
"""
Field           Allowed Values          Special Characters
-----           --------------          ------------------
minute          0-59                    * , - /
hour            0-23                    * , - /
day_of_week     0-6 (0=Sun) or mon-sun  * , - /
day_of_month    1-31                    * , - /
month_of_year   1-12                    * , - /

Special Patterns:
- * : Any value
- , : Value list separator (1,3,5)
- - : Range of values (1-5)
- / : Step values (*/15 = every 15 minutes)

Examples:
crontab()                           # Execute every minute
crontab(minute=0, hour=0)           # Daily at midnight
crontab(minute='*/15')              # Every 15 minutes
crontab(hour=7, minute=30, day_of_week=1)  # Monday 7:30 AM
crontab(hour='9-17', minute=0)      # Every hour 9 AM - 5 PM
crontab(minute=0, day_of_week='mon-fri')   # Every hour on weekdays
"""


# Timezone-Aware Scheduling
"""
Set timezone in Celery configuration:
    app.conf.timezone = 'America/New_York'
    app.conf.enable_utc = True

Crontab schedules respect the configured timezone.
UTC is recommended for consistency across distributed systems.
"""


# Testing Schedules
"""
To test schedules without waiting:
1. Use shorter intervals in development
2. Run beat with --loglevel=debug
3. Check beat_schedule is properly registered
4. Monitor task execution in flower or logs

Command:
    celery -A tasks beat --loglevel=debug
"""


if __name__ == '__main__':
    # Start Celery Beat scheduler
    # In production, run as separate process:
    #   celery -A tasks beat --loglevel=info

    from celery.bin import beat
    beat.beat(app=app).run()
