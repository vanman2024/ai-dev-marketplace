"""
Prometheus Metrics Exporter for Celery

Exports Celery metrics to Prometheus for monitoring and alerting.
Provides real-time metrics about tasks, workers, and queues.

Metrics Exposed:
    - celery_tasks_total: Total tasks by state (SUCCESS, FAILURE, PENDING, etc.)
    - celery_workers_online: Number of online workers
    - celery_task_runtime_seconds: Task execution time histogram
    - celery_queue_length: Queue depth by queue name
    - celery_worker_pool_size: Worker pool size by worker

Usage:
    1. Install dependencies: pip install prometheus-client celery redis
    2. Set CELERY_BROKER_URL environment variable
    3. Run: python prometheus-metrics.py
    4. Metrics available at http://localhost:8000/metrics
    5. Configure Prometheus to scrape this endpoint

Security:
    - Never hardcode broker credentials
    - Use environment variables for configuration
    - Restrict metrics endpoint access with firewall
    - Consider authentication for production
"""

import os
import time
from collections import defaultdict
from typing import Dict

from celery import Celery
from prometheus_client import (
    Counter,
    Gauge,
    Histogram,
    start_http_server,
    REGISTRY,
)


# ============================================================================
# Configuration
# ============================================================================

# Celery broker URL from environment
BROKER_URL = os.getenv(
    "CELERY_BROKER_URL",
    "redis://localhost:6379/0"
)

# Metrics server port
METRICS_PORT = int(os.getenv("PROMETHEUS_PORT", "8000"))

# Update interval in seconds
UPDATE_INTERVAL = int(os.getenv("METRICS_UPDATE_INTERVAL", "15"))

# Celery app name
CELERY_APP = os.getenv("CELERY_APP", "tasks")


# ============================================================================
# Initialize Celery App
# ============================================================================

app = Celery(CELERY_APP, broker=BROKER_URL)
app.config_from_object("celeryconfig", silent=True)


# ============================================================================
# Prometheus Metrics Definitions
# ============================================================================

# Task counters by state
task_counter = Counter(
    "celery_tasks_total",
    "Total number of tasks by state",
    ["state", "task_name"]
)

# Worker status
workers_online = Gauge(
    "celery_workers_online",
    "Number of online workers"
)

worker_pool_size = Gauge(
    "celery_worker_pool_size",
    "Worker pool size",
    ["worker"]
)

# Task runtime histogram (buckets in seconds)
task_runtime = Histogram(
    "celery_task_runtime_seconds",
    "Task execution time in seconds",
    ["task_name"],
    buckets=(0.1, 0.5, 1.0, 5.0, 10.0, 30.0, 60.0, 300.0, 600.0, float("inf"))
)

# Queue depth
queue_length = Gauge(
    "celery_queue_length",
    "Number of tasks in queue",
    ["queue_name"]
)

# Task rate (tasks per second)
task_rate = Gauge(
    "celery_task_rate",
    "Task processing rate (tasks/second)",
    ["task_name"]
)

# Worker CPU and memory (if available)
worker_cpu = Gauge(
    "celery_worker_cpu_percent",
    "Worker CPU usage percentage",
    ["worker"]
)

worker_memory = Gauge(
    "celery_worker_memory_mb",
    "Worker memory usage in MB",
    ["worker"]
)


# ============================================================================
# Metrics Collector
# ============================================================================

class CeleryMetricsCollector:
    """Collects metrics from Celery and updates Prometheus gauges."""

    def __init__(self):
        self.task_counts = defaultdict(lambda: defaultdict(int))
        self.last_update = time.time()

    def collect_worker_metrics(self):
        """Collect metrics from active workers."""
        try:
            # Get active workers
            inspect = app.control.inspect()
            stats = inspect.stats()

            if not stats:
                workers_online.set(0)
                return

            # Update worker count
            workers_online.set(len(stats))

            # Update per-worker metrics
            for worker_name, worker_stats in stats.items():
                # Pool size
                pool = worker_stats.get("pool", {})
                if isinstance(pool, dict):
                    pool_size = pool.get("max-concurrency", 0)
                    worker_pool_size.labels(worker=worker_name).set(pool_size)

                # CPU and memory (if available in rusage)
                rusage = worker_stats.get("rusage", {})
                if rusage:
                    # Convert rusage values to percentages/MB
                    # Note: These are approximations
                    utime = rusage.get("utime", 0)
                    stime = rusage.get("stime", 0)
                    total_time = utime + stime
                    if total_time > 0:
                        worker_cpu.labels(worker=worker_name).set(total_time)

                    # Memory in MB
                    maxrss = rusage.get("maxrss", 0)
                    memory_mb = maxrss / 1024  # Convert KB to MB
                    worker_memory.labels(worker=worker_name).set(memory_mb)

        except Exception as e:
            print(f"Error collecting worker metrics: {e}")

    def collect_task_metrics(self):
        """Collect metrics about task states."""
        try:
            inspect = app.control.inspect()

            # Active tasks
            active = inspect.active()
            if active:
                for worker, tasks in active.items():
                    for task in tasks:
                        task_name = task.get("name", "unknown")
                        # Track as STARTED state
                        self.task_counts[task_name]["STARTED"] += 1

            # Scheduled tasks
            scheduled = inspect.scheduled()
            if scheduled:
                for worker, tasks in scheduled.items():
                    for task in tasks:
                        task_name = task.get("name", "unknown")
                        self.task_counts[task_name]["SCHEDULED"] += 1

            # Reserved tasks
            reserved = inspect.reserved()
            if reserved:
                for worker, tasks in reserved.items():
                    for task in tasks:
                        task_name = task.get("name", "unknown")
                        self.task_counts[task_name]["RESERVED"] += 1

            # Update Prometheus counters
            for task_name, states in self.task_counts.items():
                for state, count in states.items():
                    task_counter.labels(state=state, task_name=task_name).inc(count)

            # Clear counts for next iteration
            self.task_counts.clear()

        except Exception as e:
            print(f"Error collecting task metrics: {e}")

    def collect_queue_metrics(self):
        """Collect metrics about queue depths."""
        try:
            # Get queue lengths from broker
            # Note: This works for Redis broker, adjust for RabbitMQ
            from celery.app.control import Inspect

            inspect = Inspect(app=app)
            active_queues = inspect.active_queues()

            if active_queues:
                for worker, queues in active_queues.items():
                    for queue_info in queues:
                        queue_name = queue_info.get("name", "celery")

                        # Get queue length from Redis
                        if "redis" in BROKER_URL:
                            from redis import Redis
                            redis_client = Redis.from_url(BROKER_URL)
                            length = redis_client.llen(queue_name)
                            queue_length.labels(queue_name=queue_name).set(length)

        except Exception as e:
            print(f"Error collecting queue metrics: {e}")

    def collect_all_metrics(self):
        """Collect all metrics in one pass."""
        print(f"Collecting metrics at {time.strftime('%Y-%m-%d %H:%M:%S')}")

        self.collect_worker_metrics()
        self.collect_task_metrics()
        self.collect_queue_metrics()

        self.last_update = time.time()


# ============================================================================
# Task Event Handler (Optional - for detailed task metrics)
# ============================================================================

class TaskEventHandler:
    """
    Handles real-time task events for detailed metrics.

    Requires workers to have events enabled:
        celery -A myapp worker --events
    """

    def __init__(self):
        self.task_start_times = {}

    def on_task_sent(self, event):
        """Task was sent to worker."""
        task_name = event.get("name", "unknown")
        task_counter.labels(state="SENT", task_name=task_name).inc()

    def on_task_received(self, event):
        """Task was received by worker."""
        task_name = event.get("name", "unknown")
        task_uuid = event.get("uuid")
        self.task_start_times[task_uuid] = event.get("timestamp", time.time())
        task_counter.labels(state="RECEIVED", task_name=task_name).inc()

    def on_task_started(self, event):
        """Task execution started."""
        task_name = event.get("name", "unknown")
        task_counter.labels(state="STARTED", task_name=task_name).inc()

    def on_task_succeeded(self, event):
        """Task completed successfully."""
        task_name = event.get("name", "unknown")
        task_uuid = event.get("uuid")

        # Update success counter
        task_counter.labels(state="SUCCESS", task_name=task_name).inc()

        # Record runtime
        if task_uuid in self.task_start_times:
            runtime = event.get("timestamp", time.time()) - self.task_start_times[task_uuid]
            task_runtime.labels(task_name=task_name).observe(runtime)
            del self.task_start_times[task_uuid]

    def on_task_failed(self, event):
        """Task failed with exception."""
        task_name = event.get("name", "unknown")
        task_uuid = event.get("uuid")

        # Update failure counter
        task_counter.labels(state="FAILURE", task_name=task_name).inc()

        # Clean up start time
        if task_uuid in self.task_start_times:
            del self.task_start_times[task_uuid]

    def on_task_retried(self, event):
        """Task is being retried."""
        task_name = event.get("name", "unknown")
        task_counter.labels(state="RETRY", task_name=task_name).inc()

    def on_task_revoked(self, event):
        """Task was revoked."""
        task_name = event.get("name", "unknown")
        task_counter.labels(state="REVOKED", task_name=task_name).inc()


# ============================================================================
# Main Application
# ============================================================================

def start_event_monitor():
    """
    Start real-time event monitoring (optional).

    Requires workers to run with --events flag.
    Provides more detailed metrics but requires additional resources.
    """
    handler = TaskEventHandler()

    with app.connection() as connection:
        recv = app.events.Receiver(connection, handlers={
            "task-sent": handler.on_task_sent,
            "task-received": handler.on_task_received,
            "task-started": handler.on_task_started,
            "task-succeeded": handler.on_task_succeeded,
            "task-failed": handler.on_task_failed,
            "task-retried": handler.on_task_retried,
            "task-revoked": handler.on_task_revoked,
        })

        print("Event monitor started. Listening for task events...")
        recv.capture(limit=None, timeout=None, wakeup=True)


def start_polling_monitor():
    """
    Start polling-based monitoring.

    Polls Celery inspect API at regular intervals.
    Lower resource usage but less real-time than event monitoring.
    """
    collector = CeleryMetricsCollector()

    print(f"Polling monitor started. Update interval: {UPDATE_INTERVAL}s")

    while True:
        try:
            collector.collect_all_metrics()
        except Exception as e:
            print(f"Error in monitoring loop: {e}")

        time.sleep(UPDATE_INTERVAL)


def main():
    """
    Start Prometheus metrics exporter.

    Modes:
        - 'polling': Regular inspection API polling (default)
        - 'events': Real-time event monitoring (requires --events on workers)
    """
    mode = os.getenv("METRICS_MODE", "polling")

    # Validate configuration
    if not BROKER_URL:
        print("ERROR: CELERY_BROKER_URL environment variable is required")
        return

    print("=" * 70)
    print("Celery Prometheus Metrics Exporter")
    print("=" * 70)
    print(f"Broker URL:       {BROKER_URL.split('@')[-1] if '@' in BROKER_URL else BROKER_URL}")
    print(f"Metrics Port:     {METRICS_PORT}")
    print(f"Update Interval:  {UPDATE_INTERVAL}s")
    print(f"Mode:             {mode}")
    print("=" * 70)

    # Start Prometheus HTTP server
    start_http_server(METRICS_PORT)
    print(f"✓ Metrics server started at http://0.0.0.0:{METRICS_PORT}/metrics")

    # Start monitoring based on mode
    if mode == "events":
        print("Starting event-based monitoring...")
        start_event_monitor()
    else:
        print("Starting polling-based monitoring...")
        start_polling_monitor()


if __name__ == "__main__":
    main()


# ============================================================================
# Prometheus Scrape Configuration
# ============================================================================

"""
Add this to your prometheus.yml:

scrape_configs:
  - job_name: 'celery'
    static_configs:
      - targets: ['localhost:8000']
    scrape_interval: 15s

Grafana Dashboard:
  - Import dashboard ID: 15913 (Celery Dashboard)
  - Or create custom dashboard with these queries:

  # Task success rate
  rate(celery_tasks_total{state="SUCCESS"}[5m])

  # Task failure rate
  rate(celery_tasks_total{state="FAILURE"}[5m])

  # Active workers
  celery_workers_online

  # Queue depth
  celery_queue_length

  # Average task runtime
  rate(celery_task_runtime_seconds_sum[5m]) / rate(celery_task_runtime_seconds_count[5m])
"""


# ============================================================================
# Environment Variables
# ============================================================================

"""
Required:
  CELERY_BROKER_URL=redis://localhost:6379/0

Optional:
  PROMETHEUS_PORT=8000
  METRICS_UPDATE_INTERVAL=15
  METRICS_MODE=polling
  CELERY_APP=tasks
"""
