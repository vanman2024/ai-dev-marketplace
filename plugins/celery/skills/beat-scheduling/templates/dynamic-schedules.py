"""
Dynamic Celery Beat Schedule Configuration

Programmatic and runtime schedule registration patterns.
Use for environment-based, plugin-based, or conditional schedule setup.

Security: No hardcoded credentials - all configuration from environment.
"""

from celery import Celery
from celery.schedules import crontab, schedule, solar
from datetime import timedelta
import os
import json

# Initialize Celery app
app = Celery('tasks')

# Load configuration from environment
app.config_from_object('celeryconfig')

# Alternative: Direct configuration
app.conf.update(
    broker_url=os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0'),
    result_backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0'),
    timezone='UTC',
)


# ============================================================================
# Method 1: Using @on_after_configure Decorator
# ============================================================================

@app.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    """
    Register periodic tasks after Celery configuration is complete.
    This is the recommended approach for dynamic schedule registration.
    """

    # Simple interval task
    sender.add_periodic_task(30.0, check_status.s(), name='status-check')

    # Task with timedelta
    sender.add_periodic_task(
        timedelta(minutes=5),
        cleanup_cache.s(),
        name='cache-cleanup'
    )

    # Crontab task
    sender.add_periodic_task(
        crontab(hour=0, minute=0),
        daily_report.s(),
        name='daily-report'
    )

    # Task with arguments
    sender.add_periodic_task(
        timedelta(hours=1),
        process_batch.s(batch_size=100),
        name='hourly-batch'
    )

    # Task with kwargs
    sender.add_periodic_task(
        timedelta(minutes=15),
        sync_data.s(),
        kwargs={'full_sync': False},
        name='incremental-sync'
    )

    # Task with expiration
    sender.add_periodic_task(
        10.0,
        time_sensitive.s(),
        expires=5,
        name='time-critical'
    )


# ============================================================================
# Method 2: Environment-Based Configuration
# ============================================================================

@app.on_after_configure.connect
def setup_environment_tasks(sender, **kwargs):
    """
    Register tasks based on environment variables.
    Useful for feature flags and environment-specific schedules.
    """

    # Feature flag controlled task
    if os.getenv('ENABLE_MONITORING') == 'true':
        sender.add_periodic_task(
            60.0,
            monitor_system.s(),
            name='system-monitor'
        )

    # Environment-specific intervals
    interval = int(os.getenv('HEALTH_CHECK_INTERVAL', '30'))
    sender.add_periodic_task(
        interval,
        health_check.s(),
        name='health-check'
    )

    # Production vs Development schedules
    environment = os.getenv('ENVIRONMENT', 'development')
    if environment == 'production':
        # More frequent in production
        sender.add_periodic_task(
            timedelta(minutes=1),
            critical_monitor.s(),
            name='critical-monitor'
        )
    else:
        # Less frequent in development
        sender.add_periodic_task(
            timedelta(minutes=15),
            critical_monitor.s(),
            name='critical-monitor'
        )


# ============================================================================
# Method 3: Configuration File Based Registration
# ============================================================================

def load_schedule_config(config_path):
    """Load schedule configuration from JSON file"""
    with open(config_path, 'r') as f:
        return json.load(f)


@app.on_after_configure.connect
def setup_config_file_tasks(sender, **kwargs):
    """
    Register tasks from external configuration file.
    Useful for user-defined or plugin-based schedules.
    """

    config_path = os.getenv('SCHEDULE_CONFIG_PATH', 'schedules.json')

    if os.path.exists(config_path):
        config = load_schedule_config(config_path)

        for task_config in config.get('tasks', []):
            # Parse schedule
            schedule_type = task_config['schedule']['type']
            schedule_params = task_config['schedule']['params']

            if schedule_type == 'interval':
                task_schedule = timedelta(**schedule_params)
            elif schedule_type == 'crontab':
                task_schedule = crontab(**schedule_params)
            elif schedule_type == 'solar':
                task_schedule = solar(**schedule_params)
            else:
                continue

            # Register task
            sender.add_periodic_task(
                task_schedule,
                app.signature(task_config['task']),
                args=task_config.get('args', []),
                kwargs=task_config.get('kwargs', {}),
                name=task_config['name']
            )


"""
Example schedules.json:
{
  "tasks": [
    {
      "name": "hourly-sync",
      "task": "tasks.sync_data",
      "schedule": {
        "type": "interval",
        "params": {"hours": 1}
      },
      "args": [],
      "kwargs": {"full_sync": false}
    },
    {
      "name": "daily-report",
      "task": "tasks.generate_report",
      "schedule": {
        "type": "crontab",
        "params": {"hour": 0, "minute": 0}
      }
    }
  ]
}
"""


# ============================================================================
# Method 4: Plugin-Based Registration
# ============================================================================

class SchedulePlugin:
    """Base class for schedule plugins"""

    def register_schedules(self, sender):
        """Override to register plugin schedules"""
        raise NotImplementedError


class MonitoringPlugin(SchedulePlugin):
    """Example monitoring plugin"""

    def register_schedules(self, sender):
        sender.add_periodic_task(
            30.0,
            monitor_system.s(),
            name='monitoring-plugin-task'
        )


class ReportingPlugin(SchedulePlugin):
    """Example reporting plugin"""

    def register_schedules(self, sender):
        sender.add_periodic_task(
            crontab(hour=0, minute=0),
            daily_report.s(),
            name='reporting-plugin-task'
        )


# Plugin registry
SCHEDULE_PLUGINS = [
    MonitoringPlugin(),
    ReportingPlugin(),
]


@app.on_after_configure.connect
def setup_plugin_tasks(sender, **kwargs):
    """Register tasks from all plugins"""
    for plugin in SCHEDULE_PLUGINS:
        plugin.register_schedules(sender)


# ============================================================================
# Method 5: Database-Driven Dynamic Schedules
# ============================================================================

def get_schedules_from_database():
    """
    Fetch schedules from database.
    Replace with actual database query.
    """
    # Example return structure
    return [
        {
            'name': 'tenant-1-sync',
            'task': 'tasks.sync_tenant_data',
            'schedule': {'type': 'interval', 'seconds': 300},
            'kwargs': {'tenant_id': 1}
        },
        {
            'name': 'tenant-2-sync',
            'task': 'tasks.sync_tenant_data',
            'schedule': {'type': 'interval', 'seconds': 600},
            'kwargs': {'tenant_id': 2}
        },
    ]


@app.on_after_configure.connect
def setup_database_tasks(sender, **kwargs):
    """
    Register tasks from database.
    Note: For full database-backed schedules, use django-celery-beat.
    """

    schedules = get_schedules_from_database()

    for schedule_config in schedules:
        # Parse schedule
        schedule_data = schedule_config['schedule']
        if schedule_data['type'] == 'interval':
            task_schedule = schedule_data.get('seconds', 60)
        # Add other schedule types as needed

        # Register task
        sender.add_periodic_task(
            task_schedule,
            app.signature(schedule_config['task']),
            kwargs=schedule_config.get('kwargs', {}),
            name=schedule_config['name']
        )


# ============================================================================
# Method 6: Conditional Registration
# ============================================================================

@app.on_after_configure.connect
def setup_conditional_tasks(sender, **kwargs):
    """Register tasks based on runtime conditions"""

    # Register based on day of week
    import datetime
    if datetime.datetime.now().weekday() < 5:  # Weekday
        sender.add_periodic_task(
            timedelta(hours=1),
            business_hours_task.s(),
            name='weekday-task'
        )

    # Register based on system resources
    import psutil
    if psutil.virtual_memory().total > 8 * 1024 * 1024 * 1024:  # > 8GB RAM
        sender.add_periodic_task(
            timedelta(minutes=30),
            memory_intensive_task.s(),
            name='high-memory-task'
        )

    # Register based on feature detection
    try:
        import optional_module
        sender.add_periodic_task(
            timedelta(hours=1),
            optional_feature_task.s(),
            name='optional-feature'
        )
    except ImportError:
        pass


# ============================================================================
# Method 7: Dynamic Schedule Updates
# ============================================================================

class DynamicScheduleManager:
    """Manage schedules at runtime"""

    def __init__(self, app):
        self.app = app
        self.registered_tasks = {}

    def add_schedule(self, name, task_signature, schedule_obj):
        """Add new schedule dynamically"""
        self.app.add_periodic_task(
            schedule_obj,
            task_signature,
            name=name
        )
        self.registered_tasks[name] = {
            'task': task_signature,
            'schedule': schedule_obj
        }

    def remove_schedule(self, name):
        """
        Remove schedule dynamically.
        Note: Requires beat scheduler restart to take effect.
        """
        if name in self.registered_tasks:
            del self.registered_tasks[name]
            # Signal beat scheduler to reload

    def update_schedule(self, name, new_schedule):
        """
        Update existing schedule.
        Note: Requires beat scheduler restart to take effect.
        """
        if name in self.registered_tasks:
            self.registered_tasks[name]['schedule'] = new_schedule
            # Signal beat scheduler to reload


# Initialize manager
schedule_manager = DynamicScheduleManager(app)


# ============================================================================
# Example Tasks
# ============================================================================

@app.task
def check_status():
    """Example status check task"""
    print("Checking status...")
    return "OK"

@app.task
def cleanup_cache():
    """Example cache cleanup task"""
    print("Cleaning cache...")
    return "Cache cleaned"

@app.task
def daily_report():
    """Example daily report task"""
    print("Generating daily report...")
    return "Report generated"

@app.task
def process_batch(batch_size):
    """Example batch processing task"""
    print(f"Processing batch of size {batch_size}...")
    return f"Processed {batch_size} items"

@app.task
def sync_data(full_sync=False):
    """Example data sync task"""
    sync_type = "full" if full_sync else "incremental"
    print(f"Performing {sync_type} sync...")
    return f"{sync_type} sync complete"

@app.task
def time_sensitive():
    """Example time-sensitive task"""
    print("Executing time-critical operation...")
    return "Complete"

@app.task
def monitor_system():
    """Example monitoring task"""
    print("Monitoring system...")
    return "Monitoring complete"

@app.task
def health_check():
    """Example health check task"""
    print("Performing health check...")
    return "Healthy"

@app.task
def critical_monitor():
    """Example critical monitoring task"""
    print("Monitoring critical systems...")
    return "Critical systems OK"

@app.task
def business_hours_task():
    """Example business hours task"""
    print("Executing business hours task...")
    return "Complete"

@app.task
def memory_intensive_task():
    """Example memory-intensive task"""
    print("Executing memory-intensive task...")
    return "Complete"

@app.task
def optional_feature_task():
    """Example optional feature task"""
    print("Executing optional feature...")
    return "Complete"


# ============================================================================
# Best Practices
# ============================================================================

"""
1. Registration Timing:
   - Use @on_after_configure for automatic registration
   - Avoid registering in module-level code
   - Ensure registration happens before beat starts

2. Schedule Management:
   - Keep track of registered schedules
   - Use meaningful task names
   - Document schedule purposes
   - Avoid schedule conflicts

3. Testing:
   - Test schedule registration logic
   - Verify conditional registration paths
   - Test with different environments
   - Mock external dependencies

4. Performance:
   - Minimize database queries during registration
   - Cache configuration data when possible
   - Use lazy loading for expensive operations
   - Monitor beat scheduler memory usage

5. Maintenance:
   - Log schedule registration
   - Implement health checks
   - Monitor task execution
   - Set up alerting for failures
"""


# ============================================================================
# Testing Dynamic Schedules
# ============================================================================

"""
Development Testing:

1. Verify registration:
   celery -A tasks beat inspect scheduled

2. Test with environment variables:
   ENABLE_MONITORING=true celery -A tasks beat --loglevel=debug

3. Test configuration files:
   SCHEDULE_CONFIG_PATH=test_schedules.json celery -A tasks beat

4. Monitor registration in logs:
   celery -A tasks beat --loglevel=debug | grep "Scheduler"
"""


if __name__ == '__main__':
    # Start Celery Beat scheduler
    from celery.bin import beat
    beat.beat(app=app).run()
