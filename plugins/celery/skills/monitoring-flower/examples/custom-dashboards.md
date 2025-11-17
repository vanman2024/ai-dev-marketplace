# Custom Dashboards Guide

Create custom Flower views and dashboards tailored to specific workflows, teams, and use cases.

## Overview

This guide covers:

1. Creating custom dashboard handlers
2. Building workflow-specific views
3. Implementing custom metrics
4. Adding filtering and grouping
5. Real-time updates and exports

---

## Custom Dashboard Architecture

```
Custom Handler → Data Collection → Template Rendering → Browser Display
                       ↓
                 Custom Metrics
```

**Components:**

- **Handler**: Tornado web handler for custom routes
- **Data Collection**: Query Celery state and compute metrics
- **Template**: HTML/JS for visualization
- **Metrics**: Custom computed values for your workflow

---

## Example 1: ML Training Dashboard

Monitor machine learning training jobs with specialized metrics.

### Handler Implementation

```python
# custom_dashboards/ml_dashboard.py
from flower.views import BaseHandler
from tornado import gen
from tornado.web import authenticated

class MLTrainingDashboard(BaseHandler):
    """
    Custom dashboard for ML training workflows.

    Features:
        - Training job status
        - GPU utilization tracking
        - Model performance metrics
        - ETA calculations
    """

    @authenticated
    @gen.coroutine
    def get(self):
        # Query parameters
        time_range = self.get_argument("time_range", "24h")
        model_filter = self.get_argument("model", "")

        # Collect data
        training_jobs = yield self.get_training_jobs(time_range, model_filter)
        gpu_workers = yield self.get_gpu_workers()
        metrics = self.compute_training_metrics(training_jobs)

        # Render template
        self.render(
            "ml_training_dashboard.html",
            training_jobs=training_jobs,
            gpu_workers=gpu_workers,
            metrics=metrics,
            time_range=time_range,
        )

    @gen.coroutine
    def get_training_jobs(self, time_range, model_filter):
        """Get ML training tasks."""
        app = self.application
        training_jobs = []

        for task_uuid, task in app.state.tasks.items():
            # Filter training tasks
            if "train_model" not in task.name:
                continue

            # Filter by model type
            if model_filter and model_filter not in str(task.args):
                continue

            # Extract training metadata
            training_jobs.append({
                "uuid": task_uuid,
                "model_name": self.extract_model_name(task),
                "state": task.state,
                "progress": self.extract_progress(task),
                "loss": self.extract_loss(task),
                "accuracy": self.extract_accuracy(task),
                "started": task.started,
                "runtime": task.runtime,
                "eta": self.calculate_eta(task),
                "gpu_id": self.extract_gpu_id(task),
            })

        return training_jobs

    def compute_training_metrics(self, training_jobs):
        """Compute ML-specific metrics."""
        return {
            "active_jobs": len([j for j in training_jobs if j["state"] == "STARTED"]),
            "completed_today": len([j for j in training_jobs if j["state"] == "SUCCESS"]),
            "failed_today": len([j for j in training_jobs if j["state"] == "FAILURE"]),
            "average_training_time": self._compute_avg_time(training_jobs),
            "best_accuracy": max([j["accuracy"] for j in training_jobs if j["accuracy"]], default=0),
        }

    def extract_model_name(self, task):
        """Extract model name from task args."""
        try:
            return task.args[0] if task.args else "unknown"
        except:
            return "unknown"

    def extract_progress(self, task):
        """Extract training progress percentage."""
        # Parse from task result or custom state
        try:
            result = task.result or {}
            return result.get("progress", 0)
        except:
            return 0

    def calculate_eta(self, task):
        """Calculate estimated time to completion."""
        if task.state != "STARTED":
            return None

        progress = self.extract_progress(task)
        if progress <= 0:
            return None

        elapsed = task.runtime or 0
        total_time = elapsed / (progress / 100)
        remaining = total_time - elapsed

        return remaining
```

### Template (Simplified)

```html
<!-- templates/ml_training_dashboard.html -->
<!DOCTYPE html>
<html>
<head>
    <title>ML Training Dashboard</title>
    <meta http-equiv="refresh" content="30">
    <style>
        .job-card { border: 1px solid #ccc; padding: 15px; margin: 10px; }
        .progress-bar { background: #4CAF50; height: 20px; }
        .metric { font-size: 2em; font-weight: bold; }
    </style>
</head>
<body>
    <h1>ML Training Dashboard</h1>

    <!-- Metrics Overview -->
    <div class="metrics">
        <div class="metric-card">
            <div class="label">Active Jobs</div>
            <div class="metric">{{ metrics.active_jobs }}</div>
        </div>
        <div class="metric-card">
            <div class="label">Completed Today</div>
            <div class="metric">{{ metrics.completed_today }}</div>
        </div>
        <div class="metric-card">
            <div class="label">Best Accuracy</div>
            <div class="metric">{{ "%.2f"|format(metrics.best_accuracy) }}%</div>
        </div>
    </div>

    <!-- Training Jobs -->
    <h2>Active Training Jobs</h2>
    {% for job in training_jobs %}
    <div class="job-card">
        <h3>{{ job.model_name }}</h3>
        <div>State: <strong>{{ job.state }}</strong></div>
        <div>Progress:
            <div class="progress-bar" style="width: {{ job.progress }}%">
                {{ job.progress }}%
            </div>
        </div>
        <div>Loss: {{ "%.4f"|format(job.loss or 0) }}</div>
        <div>Accuracy: {{ "%.2f"|format(job.accuracy or 0) }}%</div>
        <div>Runtime: {{ "%.1f"|format(job.runtime or 0) }}s</div>
        {% if job.eta %}
        <div>ETA: {{ "%.0f"|format(job.eta) }}s</div>
        {% end %}
        <div>GPU: {{ job.gpu_id or 'N/A' }}</div>
    </div>
    {% end %}
</body>
</html>
```

### Registration

```python
# Register with Flower
from flower import Flower
from custom_dashboards.ml_dashboard import MLTrainingDashboard

app = Flower(broker="redis://localhost:6379/0")
app.add_handlers(r".*", [
    (r"/ml-dashboard", MLTrainingDashboard),
])
app.start()
```

---

## Example 2: ETL Pipeline Dashboard

Monitor Extract, Transform, Load workflows with stage tracking.

### Handler Implementation

```python
class ETLPipelineDashboard(BaseHandler):
    """Dashboard for ETL pipeline monitoring."""

    @authenticated
    @gen.coroutine
    def get(self):
        # Get pipeline ID from query
        pipeline_id = self.get_argument("pipeline", "")

        # Collect tasks by stage
        extract_tasks = yield self.get_stage_tasks("extract", pipeline_id)
        transform_tasks = yield self.get_stage_tasks("transform", pipeline_id)
        load_tasks = yield self.get_stage_tasks("load", pipeline_id)

        # Compute pipeline health
        pipeline_health = self.compute_pipeline_health(
            extract_tasks, transform_tasks, load_tasks
        )

        self.render(
            "etl_pipeline_dashboard.html",
            extract_tasks=extract_tasks,
            transform_tasks=transform_tasks,
            load_tasks=load_tasks,
            pipeline_health=pipeline_health,
        )

    @gen.coroutine
    def get_stage_tasks(self, stage, pipeline_id):
        """Get tasks for specific pipeline stage."""
        app = self.application
        stage_tasks = []

        for task_uuid, task in app.state.tasks.items():
            # Filter by stage and pipeline
            if stage not in task.name:
                continue

            if pipeline_id and pipeline_id not in str(task.args):
                continue

            stage_tasks.append({
                "uuid": task_uuid,
                "name": task.name,
                "state": task.state,
                "records_processed": self.extract_record_count(task),
                "data_volume": self.extract_data_volume(task),
                "error_count": self.extract_error_count(task),
                "runtime": task.runtime,
            })

        return stage_tasks

    def compute_pipeline_health(self, extract, transform, load):
        """Compute overall pipeline health."""
        all_tasks = extract + transform + load

        if not all_tasks:
            return {"status": "unknown", "score": 0}

        success = len([t for t in all_tasks if t["state"] == "SUCCESS"])
        failure = len([t for t in all_tasks if t["state"] == "FAILURE"])

        success_rate = (success / len(all_tasks)) * 100

        if success_rate >= 95:
            status = "healthy"
        elif success_rate >= 80:
            status = "degraded"
        else:
            status = "unhealthy"

        return {
            "status": status,
            "score": success_rate,
            "total_tasks": len(all_tasks),
            "successful": success,
            "failed": failure,
        }
```

---

## Example 3: Team-Based Dashboard

Separate views for different teams or projects.

### Handler Implementation

```python
class TeamDashboard(BaseHandler):
    """Dashboard filtered by team."""

    @authenticated
    @gen.coroutine
    def get(self):
        team = self.get_argument("team", "default")

        # Get team's workers
        team_workers = yield self.get_team_workers(team)

        # Get team's tasks
        team_tasks = yield self.get_team_tasks(team)

        # Compute team metrics
        team_metrics = self.compute_team_metrics(team_workers, team_tasks)

        self.render(
            "team_dashboard.html",
            team=team,
            workers=team_workers,
            tasks=team_tasks,
            metrics=team_metrics,
        )

    @gen.coroutine
    def get_team_workers(self, team):
        """Get workers belonging to team."""
        app = self.application
        stats = yield app.inspect.stats()

        team_workers = []
        for worker_name, worker_stats in (stats or {}).items():
            # Filter by team tag in worker name
            if f"team-{team}" in worker_name:
                team_workers.append({
                    "name": worker_name,
                    "status": "online",
                    "pool_size": worker_stats.get("pool", {}).get("max-concurrency", 0),
                })

        return team_workers

    @gen.coroutine
    def get_team_tasks(self, team):
        """Get tasks belonging to team."""
        app = self.application
        team_tasks = []

        for task_uuid, task in app.state.tasks.items():
            # Filter by team tag in task routing_key
            if hasattr(task, "routing_key") and f"team_{team}" in task.routing_key:
                team_tasks.append({
                    "uuid": task_uuid,
                    "name": task.name,
                    "state": task.state,
                    "runtime": task.runtime,
                })

        return team_tasks
```

---

## Example 4: Real-Time Updates with WebSockets

Add real-time updates to custom dashboards.

### WebSocket Handler

```python
from tornado.websocket import WebSocketHandler

class DashboardWebSocket(WebSocketHandler):
    """WebSocket for real-time dashboard updates."""

    clients = set()

    def open(self):
        """Client connected."""
        self.clients.add(self)
        print(f"WebSocket opened: {self.request.remote_ip}")

    def on_close(self):
        """Client disconnected."""
        self.clients.remove(self)
        print(f"WebSocket closed: {self.request.remote_ip}")

    @classmethod
    def send_update(cls, data):
        """Send update to all connected clients."""
        for client in cls.clients:
            try:
                client.write_message(data)
            except:
                pass
```

### JavaScript Client

```javascript
// Connect to WebSocket
const ws = new WebSocket('ws://localhost:5555/ws/dashboard');

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);

    // Update dashboard metrics
    document.getElementById('worker-count').textContent = data.workers;
    document.getElementById('task-count').textContent = data.tasks;
    document.getElementById('success-rate').textContent = data.success_rate + '%';
};

ws.onerror = function(error) {
    console.error('WebSocket error:', error);
};
```

---

## Example 5: Export Dashboard Data

Export dashboard data as CSV/JSON for reporting.

### Export Handler

```python
class DashboardExport(BaseHandler):
    """Export dashboard data."""

    @authenticated
    @gen.coroutine
    def get(self):
        export_format = self.get_argument("format", "json")
        metric_type = self.get_argument("type", "tasks")

        # Collect data
        data = yield self.collect_export_data(metric_type)

        # Format output
        if export_format == "csv":
            self.set_header("Content-Type", "text/csv")
            self.set_header(
                "Content-Disposition",
                f"attachment; filename=celery_{metric_type}.csv"
            )
            self.write(self.format_as_csv(data))
        else:
            self.set_header("Content-Type", "application/json")
            self.write(json.dumps(data, indent=2))

    def format_as_csv(self, data):
        """Format data as CSV."""
        import csv
        from io import StringIO

        output = StringIO()
        if data:
            writer = csv.DictWriter(output, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)

        return output.getvalue()
```

---

## Best Practices

### Performance

1. **Cache expensive queries**:
```python
from functools import lru_cache

@lru_cache(maxsize=128)
def get_expensive_metric(self):
    # Expensive computation
    pass
```

2. **Limit data ranges**:
```python
# Only load recent data
MAX_TASKS = 1000
cutoff_time = datetime.now() - timedelta(hours=24)
```

3. **Use pagination**:
```python
page = int(self.get_argument("page", "1"))
per_page = 50
start = (page - 1) * per_page
end = start + per_page
```

### Security

1. **Validate inputs**:
```python
allowed_teams = ["team-a", "team-b", "team-c"]
team = self.get_argument("team")
if team not in allowed_teams:
    raise ValueError("Invalid team")
```

2. **Implement authorization**:
```python
@authenticated
def get(self):
    user = self.get_current_user()
    if not user.can_access_dashboard():
        raise HTTPError(403)
```

3. **Rate limiting**:
```python
from ratelimit import limits

@limits(calls=10, period=60)
def get(self):
    # Rate-limited endpoint
    pass
```

---

## Production Checklist

- [ ] Custom handlers tested
- [ ] Templates validated
- [ ] Authentication enabled
- [ ] Authorization implemented
- [ ] Input validation added
- [ ] Rate limiting configured
- [ ] Caching implemented
- [ ] Error handling added
- [ ] Logging configured
- [ ] Documentation written

---

## Additional Resources

- **Tornado Documentation**: https://www.tornadoweb.org/
- **Flower Source Code**: https://github.com/mher/flower
- **WebSocket Guide**: https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API
- **Chart.js**: https://www.chartjs.org/ (for visualizations)
