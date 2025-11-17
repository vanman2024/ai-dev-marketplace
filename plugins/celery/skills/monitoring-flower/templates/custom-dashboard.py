"""
Custom Dashboard Templates for Flower

Create custom views and dashboards for Flower monitoring.
Useful for workflow-specific monitoring, team dashboards, and specialized views.

Features:
    - Custom task filtering and grouping
    - Worker organization by team/zone
    - Workflow-specific metrics
    - Custom refresh rates
    - Exportable reports

Usage:
    1. Create custom view class
    2. Register with Flower application
    3. Access via /custom-dashboard URL
    4. Customize templates in templates/custom_*.html

Security:
    - Validate all user inputs
    - Implement proper authentication
    - Sanitize data for display
    - Rate limit API endpoints
"""

import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional

from flower.views import BaseHandler
from tornado import gen
from tornado.web import authenticated


# ============================================================================
# Base Custom Dashboard Handler
# ============================================================================

class CustomDashboardHandler(BaseHandler):
    """
    Base handler for custom Flower dashboards.

    Provides common functionality for custom views:
        - Worker filtering
        - Task filtering
        - Metric computation
        - Data export
    """

    @authenticated
    @gen.coroutine
    def get(self):
        """
        Render custom dashboard.

        Query Parameters:
            - refresh: Auto-refresh interval in seconds
            - worker: Filter by worker name pattern
            - task: Filter by task name pattern
            - state: Filter by task state (SUCCESS, FAILURE, etc.)
            - time_range: Time range for metrics (1h, 6h, 24h, 7d)
        """
        # Get query parameters
        refresh_interval = self.get_argument("refresh", "30")
        worker_filter = self.get_argument("worker", "")
        task_filter = self.get_argument("task", "")
        state_filter = self.get_argument("state", "")
        time_range = self.get_argument("time_range", "1h")

        # Collect dashboard data
        data = yield self.collect_dashboard_data(
            worker_filter=worker_filter,
            task_filter=task_filter,
            state_filter=state_filter,
            time_range=time_range,
        )

        # Render template
        self.render(
            "custom_dashboard.html",
            data=data,
            refresh_interval=refresh_interval,
            worker_filter=worker_filter,
            task_filter=task_filter,
            state_filter=state_filter,
            time_range=time_range,
        )

    @gen.coroutine
    def collect_dashboard_data(
        self,
        worker_filter: str = "",
        task_filter: str = "",
        state_filter: str = "",
        time_range: str = "1h",
    ) -> Dict:
        """
        Collect data for custom dashboard.

        Args:
            worker_filter: Worker name pattern
            task_filter: Task name pattern
            state_filter: Task state filter
            time_range: Time range for metrics

        Returns:
            Dictionary with dashboard data
        """
        # Get workers
        workers = yield self.get_filtered_workers(worker_filter)

        # Get tasks
        tasks = yield self.get_filtered_tasks(task_filter, state_filter, time_range)

        # Compute metrics
        metrics = self.compute_metrics(workers, tasks)

        return {
            "workers": workers,
            "tasks": tasks,
            "metrics": metrics,
            "timestamp": datetime.now().isoformat(),
        }

    @gen.coroutine
    def get_filtered_workers(self, pattern: str) -> List[Dict]:
        """
        Get workers matching filter pattern.

        Args:
            pattern: Worker name pattern (supports wildcards)

        Returns:
            List of worker dictionaries
        """
        app = self.application
        workers = []

        # Get all workers
        stats = yield app.inspect.stats()
        if not stats:
            return workers

        # Filter workers
        for worker_name, worker_stats in stats.items():
            if not pattern or pattern.lower() in worker_name.lower():
                workers.append({
                    "name": worker_name,
                    "status": "online",
                    "pool_size": worker_stats.get("pool", {}).get("max-concurrency", 0),
                    "processed_tasks": worker_stats.get("total", {}).get("celery.tasks", 0),
                })

        return workers

    @gen.coroutine
    def get_filtered_tasks(
        self,
        task_pattern: str,
        state_filter: str,
        time_range: str,
    ) -> List[Dict]:
        """
        Get tasks matching filters.

        Args:
            task_pattern: Task name pattern
            state_filter: Task state (SUCCESS, FAILURE, etc.)
            time_range: Time range (1h, 6h, 24h, 7d)

        Returns:
            List of task dictionaries
        """
        app = self.application
        tasks = []

        # Parse time range
        time_delta = self._parse_time_range(time_range)
        cutoff_time = datetime.now() - time_delta

        # Get tasks from Flower's state
        for task_uuid, task in app.state.tasks.items():
            task_time = datetime.fromtimestamp(task.timestamp)

            # Apply filters
            if task_time < cutoff_time:
                continue

            if task_pattern and task_pattern.lower() not in task.name.lower():
                continue

            if state_filter and task.state != state_filter:
                continue

            # Add to results
            tasks.append({
                "uuid": task_uuid,
                "name": task.name,
                "state": task.state,
                "received": task.received,
                "started": task.started,
                "timestamp": task.timestamp,
                "runtime": task.runtime,
                "worker": task.worker.hostname if task.worker else None,
            })

        return tasks

    def _parse_time_range(self, time_range: str) -> timedelta:
        """Parse time range string to timedelta."""
        mapping = {
            "1h": timedelta(hours=1),
            "6h": timedelta(hours=6),
            "24h": timedelta(hours=24),
            "7d": timedelta(days=7),
            "30d": timedelta(days=30),
        }
        return mapping.get(time_range, timedelta(hours=1))

    def compute_metrics(self, workers: List[Dict], tasks: List[Dict]) -> Dict:
        """
        Compute dashboard metrics.

        Args:
            workers: List of workers
            tasks: List of tasks

        Returns:
            Dictionary of computed metrics
        """
        metrics = {
            "total_workers": len(workers),
            "total_tasks": len(tasks),
            "tasks_by_state": {},
            "tasks_by_worker": {},
            "average_runtime": 0,
            "success_rate": 0,
        }

        # Count tasks by state
        for task in tasks:
            state = task["state"]
            metrics["tasks_by_state"][state] = metrics["tasks_by_state"].get(state, 0) + 1

            # Count by worker
            worker = task.get("worker", "unknown")
            metrics["tasks_by_worker"][worker] = metrics["tasks_by_worker"].get(worker, 0) + 1

        # Compute average runtime
        runtimes = [task["runtime"] for task in tasks if task.get("runtime")]
        if runtimes:
            metrics["average_runtime"] = sum(runtimes) / len(runtimes)

        # Compute success rate
        success_count = metrics["tasks_by_state"].get("SUCCESS", 0)
        if len(tasks) > 0:
            metrics["success_rate"] = (success_count / len(tasks)) * 100

        return metrics


# ============================================================================
# ML Training Dashboard Example
# ============================================================================

class MLTrainingDashboard(CustomDashboardHandler):
    """
    Custom dashboard for ML training workflows.

    Features:
        - Training job status
        - GPU utilization
        - Model performance metrics
        - Training time estimates
    """

    @authenticated
    @gen.coroutine
    def get(self):
        """Render ML training dashboard."""
        # Get training-specific tasks
        training_tasks = yield self.get_training_tasks()

        # Get GPU worker stats
        gpu_workers = yield self.get_gpu_workers()

        # Compute training metrics
        training_metrics = self.compute_training_metrics(training_tasks)

        self.render(
            "ml_training_dashboard.html",
            training_tasks=training_tasks,
            gpu_workers=gpu_workers,
            training_metrics=training_metrics,
        )

    @gen.coroutine
    def get_training_tasks(self) -> List[Dict]:
        """Get ML training tasks."""
        tasks = yield self.get_filtered_tasks(
            task_pattern="train_model",
            state_filter="",
            time_range="24h",
        )
        return tasks

    @gen.coroutine
    def get_gpu_workers(self) -> List[Dict]:
        """Get workers with GPU resources."""
        workers = yield self.get_filtered_workers(pattern="gpu")
        return workers

    def compute_training_metrics(self, tasks: List[Dict]) -> Dict:
        """Compute ML training-specific metrics."""
        return {
            "active_training_jobs": len([t for t in tasks if t["state"] == "STARTED"]),
            "completed_today": len([t for t in tasks if t["state"] == "SUCCESS"]),
            "failed_today": len([t for t in tasks if t["state"] == "FAILURE"]),
            "average_training_time": self._compute_avg_time(tasks),
        }

    def _compute_avg_time(self, tasks: List[Dict]) -> float:
        """Compute average training time."""
        completed_tasks = [t for t in tasks if t.get("runtime")]
        if not completed_tasks:
            return 0
        return sum(t["runtime"] for t in completed_tasks) / len(completed_tasks)


# ============================================================================
# ETL Pipeline Dashboard Example
# ============================================================================

class ETLPipelineDashboard(CustomDashboardHandler):
    """
    Custom dashboard for ETL (Extract, Transform, Load) workflows.

    Features:
        - Pipeline stage tracking
        - Data volume metrics
        - Error rate monitoring
        - SLA compliance
    """

    @authenticated
    @gen.coroutine
    def get(self):
        """Render ETL pipeline dashboard."""
        # Get ETL tasks grouped by stage
        extract_tasks = yield self.get_filtered_tasks("extract", "", "6h")
        transform_tasks = yield self.get_filtered_tasks("transform", "", "6h")
        load_tasks = yield self.get_filtered_tasks("load", "", "6h")

        # Compute pipeline metrics
        pipeline_metrics = {
            "extract": self._compute_stage_metrics(extract_tasks),
            "transform": self._compute_stage_metrics(transform_tasks),
            "load": self._compute_stage_metrics(load_tasks),
        }

        self.render(
            "etl_pipeline_dashboard.html",
            extract_tasks=extract_tasks,
            transform_tasks=transform_tasks,
            load_tasks=load_tasks,
            pipeline_metrics=pipeline_metrics,
        )

    def _compute_stage_metrics(self, tasks: List[Dict]) -> Dict:
        """Compute metrics for pipeline stage."""
        return {
            "total": len(tasks),
            "success": len([t for t in tasks if t["state"] == "SUCCESS"]),
            "failure": len([t for t in tasks if t["state"] == "FAILURE"]),
            "in_progress": len([t for t in tasks if t["state"] == "STARTED"]),
        }


# ============================================================================
# API Endpoint for Custom Metrics
# ============================================================================

class CustomMetricsAPI(BaseHandler):
    """
    JSON API for custom metrics export.

    Useful for:
        - External monitoring systems
        - Custom alerting
        - Data warehouse integration
        - Report generation
    """

    @authenticated
    @gen.coroutine
    def get(self):
        """
        Get custom metrics as JSON.

        Query Parameters:
            - metric_type: Type of metrics (workers, tasks, custom)
            - format: Output format (json, csv)
        """
        metric_type = self.get_argument("metric_type", "workers")
        output_format = self.get_argument("format", "json")

        # Collect metrics based on type
        if metric_type == "workers":
            data = yield self._get_worker_metrics()
        elif metric_type == "tasks":
            data = yield self._get_task_metrics()
        else:
            data = yield self._get_custom_metrics()

        # Format output
        if output_format == "csv":
            self.set_header("Content-Type", "text/csv")
            self.write(self._format_as_csv(data))
        else:
            self.set_header("Content-Type", "application/json")
            self.write(json.dumps(data, indent=2))

    @gen.coroutine
    def _get_worker_metrics(self) -> Dict:
        """Get worker metrics."""
        app = self.application
        stats = yield app.inspect.stats()

        metrics = []
        for worker_name, worker_stats in (stats or {}).items():
            metrics.append({
                "worker": worker_name,
                "pool_size": worker_stats.get("pool", {}).get("max-concurrency", 0),
                "processed": worker_stats.get("total", {}).get("celery.tasks", 0),
            })

        return {"workers": metrics}

    @gen.coroutine
    def _get_task_metrics(self) -> Dict:
        """Get task metrics."""
        # Implementation similar to get_filtered_tasks
        return {"tasks": []}

    @gen.coroutine
    def _get_custom_metrics(self) -> Dict:
        """Get custom computed metrics."""
        return {"custom_metrics": {}}

    def _format_as_csv(self, data: Dict) -> str:
        """Format data as CSV."""
        # Simple CSV formatting
        # In production, use csv module
        return "metric,value\n" + "\n".join(
            f"{k},{v}" for k, v in data.items()
        )


# ============================================================================
# Application Registration
# ============================================================================

"""
Register custom handlers with Flower application:

from flower import Flower
from custom_dashboard import (
    CustomDashboardHandler,
    MLTrainingDashboard,
    ETLPipelineDashboard,
    CustomMetricsAPI,
)

# Create Flower app
app = Flower(broker="redis://localhost:6379/0")

# Register custom handlers
app.add_handlers(r".*", [
    (r"/custom-dashboard", CustomDashboardHandler),
    (r"/ml-dashboard", MLTrainingDashboard),
    (r"/etl-dashboard", ETLPipelineDashboard),
    (r"/api/metrics", CustomMetricsAPI),
])

# Start Flower
app.start()
"""


# ============================================================================
# HTML Template Examples
# ============================================================================

"""
Create templates/custom_dashboard.html:

<!DOCTYPE html>
<html>
<head>
    <title>Custom Celery Dashboard</title>
    <meta http-equiv="refresh" content="{{ refresh_interval }}">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .metric-card { border: 1px solid #ddd; padding: 15px; margin: 10px; display: inline-block; }
        .metric-value { font-size: 2em; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    </style>
</head>
<body>
    <h1>Custom Celery Dashboard</h1>

    <div class="metrics">
        <div class="metric-card">
            <div class="metric-label">Total Workers</div>
            <div class="metric-value">{{ data.metrics.total_workers }}</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Total Tasks</div>
            <div class="metric-value">{{ data.metrics.total_tasks }}</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">Success Rate</div>
            <div class="metric-value">{{ "%.1f"|format(data.metrics.success_rate) }}%</div>
        </div>
    </div>

    <h2>Recent Tasks</h2>
    <table>
        <thead>
            <tr>
                <th>Task Name</th>
                <th>State</th>
                <th>Worker</th>
                <th>Runtime</th>
            </tr>
        </thead>
        <tbody>
            {% for task in data.tasks %}
            <tr>
                <td>{{ task.name }}</td>
                <td>{{ task.state }}</td>
                <td>{{ task.worker or 'N/A' }}</td>
                <td>{{ "%.2f"|format(task.runtime or 0) }}s</td>
            </tr>
            {% end %}
        </tbody>
    </table>
</body>
</html>
"""
