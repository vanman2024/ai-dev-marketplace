"""
Celery Beat Periodic Task Schedule Configuration

Celery Beat is a scheduler that triggers tasks at regular intervals
(cron-like scheduling). This file shows various scheduling patterns.

Usage:
    1. Add this configuration to your celeryconfig.py or settings.py
    2. Start Celery Beat: celery -A myapp beat --loglevel=info
    3. Beat will submit tasks to queue at scheduled times
    4. Workers will execute the tasks

Requirements:
    pip install celery[redis]  # or celery[rabbitmq]
"""

from celery.schedules import crontab, solar
from datetime import timedelta

# ============================================================================
# Beat Schedule Configuration
# ============================================================================

CELERY_BEAT_SCHEDULE = {
    # ========================================================================
    # Interval-based Schedules
    # ========================================================================

    # Run every 30 seconds
    'check-status-every-30-seconds': {
        'task': 'tasks.check_system_status',
        'schedule': 30.0,  # seconds
        'args': ()
    },

    # Run every 5 minutes
    'cleanup-temp-files': {
        'task': 'tasks.cleanup_temp_files',
        'schedule': timedelta(minutes=5),
        'args': ()
    },

    # Run every hour
    'sync-data-hourly': {
        'task': 'tasks.sync_external_data',
        'schedule': timedelta(hours=1),
        'kwargs': {'source': 'api'}
    },

    # Run every day
    'daily-backup': {
        'task': 'tasks.backup_database',
        'schedule': timedelta(days=1),
        'args': ()
    },

    # ========================================================================
    # Cron-based Schedules
    # ========================================================================

    # Run at midnight every day
    'cleanup-old-records-midnight': {
        'task': 'tasks.cleanup_old_records',
        'schedule': crontab(hour=0, minute=0),
        'kwargs': {'days': 30}
    },

    # Run at 2:30 AM every day
    'database-maintenance': {
        'task': 'tasks.database_maintenance',
        'schedule': crontab(hour=2, minute=30),
        'args': ()
    },

    # Run every day at 9 AM
    'morning-report': {
        'task': 'tasks.generate_daily_report',
        'schedule': crontab(hour=9, minute=0),
        'args': ()
    },

    # Run every Monday at 9 AM
    'weekly-report-monday': {
        'task': 'tasks.generate_weekly_report',
        'schedule': crontab(hour=9, minute=0, day_of_week=1),
        'args': ()
    },

    # Run on first day of month at 8 AM
    'monthly-invoice': {
        'task': 'tasks.generate_monthly_invoice',
        'schedule': crontab(hour=8, minute=0, day_of_month=1),
        'args': ()
    },

    # Run every 15 minutes
    'check-api-health': {
        'task': 'tasks.check_api_health',
        'schedule': crontab(minute='*/15'),
        'args': ()
    },

    # Run every hour at minute 30
    'update-cache': {
        'task': 'tasks.update_cache',
        'schedule': crontab(minute=30),
        'args': ()
    },

    # Run Monday to Friday at 6 PM
    'weekday-summary': {
        'task': 'tasks.send_daily_summary',
        'schedule': crontab(hour=18, minute=0, day_of_week='1-5'),
        'args': ()
    },

    # Run every Sunday at 3 AM
    'weekly-cleanup': {
        'task': 'tasks.weekly_cleanup',
        'schedule': crontab(hour=3, minute=0, day_of_week=0),
        'args': ()
    },

    # ========================================================================
    # Solar Schedules (sunrise/sunset)
    # ========================================================================

    # Run at sunrise
    'morning-tasks-sunrise': {
        'task': 'tasks.morning_initialization',
        'schedule': solar('sunrise', -37.81753, 144.96715),  # Melbourne
        'args': ()
    },

    # Run at sunset
    'evening-tasks-sunset': {
        'task': 'tasks.evening_cleanup',
        'schedule': solar('sunset', -37.81753, 144.96715),
        'args': ()
    },

    # ========================================================================
    # Complex Schedules
    # ========================================================================

    # Run every 10 minutes between 9 AM and 5 PM on weekdays
    'business-hours-check': {
        'task': 'tasks.check_during_business_hours',
        'schedule': crontab(
            minute='*/10',
            hour='9-17',
            day_of_week='1-5'
        ),
        'args': ()
    },

    # Run at 8 AM, 12 PM, and 6 PM every day
    'three-times-daily': {
        'task': 'tasks.periodic_sync',
        'schedule': crontab(hour='8,12,18', minute=0),
        'args': ()
    },

    # Run on 1st and 15th of every month
    'semi-monthly-billing': {
        'task': 'tasks.process_billing',
        'schedule': crontab(hour=9, minute=0, day_of_month='1,15'),
        'args': ()
    },

    # ========================================================================
    # Conditional/Dynamic Schedules
    # ========================================================================

    # Run every 5 minutes only if enabled
    'conditional-task': {
        'task': 'tasks.conditional_execution',
        'schedule': timedelta(minutes=5),
        'kwargs': {'check_enabled': True}
    },
}

# ============================================================================
# Timezone Configuration
# ============================================================================

# Set timezone for cron schedules
CELERY_TIMEZONE = 'UTC'
CELERY_ENABLE_UTC = True

# Or use local timezone
# CELERY_TIMEZONE = 'America/New_York'
# CELERY_TIMEZONE = 'Europe/London'
# CELERY_TIMEZONE = 'Asia/Tokyo'

# ============================================================================
# Beat Scheduler Backend
# ============================================================================

# Default: Store schedule in memory (lost on restart)
# CELERY_BEAT_SCHEDULER = 'celery.beat:PersistentScheduler'

# Django: Store schedule in database (requires django-celery-beat)
# CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# SQLAlchemy: Store schedule in database
# CELERY_BEAT_SCHEDULER = 'celery_sqlalchemy_scheduler.schedulers:DatabaseScheduler'

# ============================================================================
# Beat Configuration Options
# ============================================================================

# Maximum number of tasks to schedule at once
CELERY_BEAT_MAX_LOOP_INTERVAL = 0  # Default is 0 (no limit)

# How often to check for schedule changes (seconds)
CELERY_BEAT_SYNC_EVERY = 0  # Default is 0 (check every tick)

# ============================================================================
# Example Task Definitions
# ============================================================================

"""
# tasks.py

from celery import shared_task
import logging

logger = logging.getLogger(__name__)

@shared_task
def check_system_status():
    '''Check system health'''
    logger.info("Checking system status")
    # Check logic here
    return {"status": "healthy"}

@shared_task
def cleanup_old_records(days=30):
    '''Delete records older than specified days'''
    logger.info(f"Cleaning up records older than {days} days")
    # Cleanup logic here
    return {"deleted": 42}

@shared_task
def generate_daily_report():
    '''Generate daily report'''
    logger.info("Generating daily report")
    # Report generation logic
    return {"status": "report generated"}

@shared_task
def generate_weekly_report():
    '''Generate weekly report'''
    logger.info("Generating weekly report")
    # Report generation logic
    return {"status": "weekly report generated"}

@shared_task
def backup_database():
    '''Backup database'''
    logger.info("Starting database backup")
    # Backup logic here
    return {"status": "backup completed"}

@shared_task
def conditional_execution(check_enabled=True):
    '''Task that checks if it should execute'''
    if not check_enabled:
        logger.info("Task execution skipped (disabled)")
        return {"status": "skipped"}

    logger.info("Executing conditional task")
    # Task logic here
    return {"status": "executed"}
"""

# ============================================================================
# Django Celery Beat Integration
# ============================================================================

"""
# Install django-celery-beat
pip install django-celery-beat

# Add to INSTALLED_APPS in settings.py
INSTALLED_APPS = [
    ...
    'django_celery_beat',
]

# Run migrations
python manage.py migrate django_celery_beat

# Use database scheduler
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Now you can manage schedules via Django admin or programmatically:

from django_celery_beat.models import PeriodicTask, IntervalSchedule, CrontabSchedule

# Create interval schedule (every 30 seconds)
schedule, created = IntervalSchedule.objects.get_or_create(
    every=30,
    period=IntervalSchedule.SECONDS,
)

PeriodicTask.objects.create(
    interval=schedule,
    name='Check system status',
    task='tasks.check_system_status',
)

# Create crontab schedule (every day at midnight)
schedule, created = CrontabSchedule.objects.get_or_create(
    minute='0',
    hour='0',
    day_of_week='*',
    day_of_month='*',
    month_of_year='*',
)

PeriodicTask.objects.create(
    crontab=schedule,
    name='Daily cleanup',
    task='tasks.cleanup_old_records',
    kwargs='{"days": 30}',
)

# Enable/disable tasks
task = PeriodicTask.objects.get(name='Check system status')
task.enabled = False
task.save()
"""

# ============================================================================
# Common Crontab Patterns
# ============================================================================

"""
# Every minute
crontab()

# Every 5 minutes
crontab(minute='*/5')

# Every 15 minutes
crontab(minute='*/15')

# Every hour
crontab(minute=0)

# Every hour at minute 30
crontab(minute=30)

# Every day at midnight
crontab(hour=0, minute=0)

# Every day at 2:30 AM
crontab(hour=2, minute=30)

# Every Monday at 9 AM
crontab(hour=9, minute=0, day_of_week=1)

# Every weekday at 9 AM
crontab(hour=9, minute=0, day_of_week='1-5')

# Every weekend at 10 AM
crontab(hour=10, minute=0, day_of_week='0,6')

# First day of month at 8 AM
crontab(hour=8, minute=0, day_of_month=1)

# Last day of month
crontab(hour=8, minute=0, day_of_month='28-31')

# Every quarter (Jan, Apr, Jul, Oct) on 1st at 9 AM
crontab(hour=9, minute=0, day_of_month=1, month_of_year='1,4,7,10')

# Multiple times per day
crontab(hour='8,12,16,20', minute=0)  # 8 AM, 12 PM, 4 PM, 8 PM

# Every 2 hours
crontab(minute=0, hour='*/2')

# Business hours (9 AM - 5 PM) on weekdays
crontab(minute=0, hour='9-17', day_of_week='1-5')
"""

# ============================================================================
# Testing Beat Schedule
# ============================================================================

"""
# Run Beat in development with verbose logging
celery -A myapp beat --loglevel=debug

# Run Beat with custom schedule
celery -A myapp beat --schedule=/tmp/celerybeat-schedule --loglevel=info

# Monitor scheduled tasks
celery -A myapp inspect scheduled

# Check active Beat schedule
celery -A myapp inspect active

# List registered tasks
celery -A myapp inspect registered
"""

# ============================================================================
# Production Beat Deployment
# ============================================================================

"""
# Use only ONE beat instance (multiple beats will duplicate tasks!)
# Run beat as a separate process from workers

# Supervisor configuration
[program:celery-beat]
command=celery -A myapp beat --loglevel=info
directory=/path/to/project
user=celery
numprocs=1  # MUST be 1!
autostart=true
autorestart=true
startsecs=10
stopwaitsecs=600
killasgroup=true
priority=998

# Systemd service
[Unit]
Description=Celery Beat Service
After=network.target

[Service]
Type=simple
User=celery
Group=celery
WorkingDirectory=/path/to/project
ExecStart=/path/to/venv/bin/celery -A myapp beat --loglevel=info
Restart=always

[Install]
WantedBy=multi-user.target

# Docker Compose
services:
  celery-beat:
    build: .
    command: celery -A myapp beat --loglevel=info
    environment:
      - CELERY_BROKER_URL=redis://redis:6379/0
    depends_on:
      - redis
    deploy:
      replicas: 1  # ONLY ONE INSTANCE!
"""
