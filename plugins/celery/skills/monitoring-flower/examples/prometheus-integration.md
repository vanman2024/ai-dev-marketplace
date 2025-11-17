# Prometheus Integration Guide

Complete guide for integrating Celery metrics with Prometheus and Grafana, including metrics collection, alerting, and dashboard setup.

## Overview

This guide covers:

1. Setting up Prometheus metrics exporter
2. Configuring Prometheus to scrape metrics
3. Creating Grafana dashboards
4. Setting up alerting rules
5. Performance optimization

---

## Architecture

```
Celery Workers → Events → Metrics Exporter → Prometheus → Grafana
                     ↓
                  Flower
```

**Components:**

- **Celery Workers**: Generate task events
- **Metrics Exporter**: Converts events to Prometheus metrics
- **Prometheus**: Scrapes and stores metrics
- **Grafana**: Visualizes metrics and alerts
- **Flower**: Web-based monitoring (optional, complementary)

---

## Step 1: Install Dependencies

```bash
# Install Prometheus client
pip install prometheus-client

# Install Celery and Redis/RabbitMQ client
pip install celery redis  # or kombu for RabbitMQ

# Verify installation
python -c "import prometheus_client; print('OK')"
```

---

## Step 2: Start Metrics Exporter

### Method 1: Using Template

```bash
# Copy template
cp templates/prometheus-metrics.py metrics_exporter.py

# Set environment variables
export CELERY_BROKER_URL="redis://localhost:6379/0"
export PROMETHEUS_PORT="8000"
export METRICS_UPDATE_INTERVAL="15"

# Start exporter
python metrics_exporter.py
```

### Method 2: Custom Implementation

```python
# metrics_exporter.py
import os
from celery import Celery
from prometheus_client import Counter, Gauge, start_http_server

# Configuration
BROKER_URL = os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0")
METRICS_PORT = int(os.getenv("PROMETHEUS_PORT", "8000"))

# Create Celery app
app = Celery('tasks', broker=BROKER_URL)

# Define metrics
task_counter = Counter(
    'celery_tasks_total',
    'Total tasks by state',
    ['state', 'task_name']
)

workers_online = Gauge(
    'celery_workers_online',
    'Number of online workers'
)

# Start metrics server
start_http_server(METRICS_PORT)

# Collect metrics (implement collection logic)
# ... see templates/prometheus-metrics.py for full implementation

if __name__ == '__main__':
    print(f"Metrics available at http://localhost:{METRICS_PORT}/metrics")
    # Run collection loop
```

### Method 3: As Systemd Service

```bash
# Create service file
sudo nano /etc/systemd/system/celery-metrics.service
```

```ini
[Unit]
Description=Celery Prometheus Metrics Exporter
After=network.target redis.service

[Service]
Type=simple
User=celery
WorkingDirectory=/opt/yourproject
Environment="CELERY_BROKER_URL=redis://localhost:6379/0"
Environment="PROMETHEUS_PORT=8000"
ExecStart=/opt/yourproject/venv/bin/python metrics_exporter.py
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable celery-metrics
sudo systemctl start celery-metrics
```

### Verify Metrics Endpoint

```bash
# Test metrics endpoint
curl http://localhost:8000/metrics

# Expected output:
# celery_tasks_total{state="SUCCESS",task_name="tasks.add"} 42
# celery_workers_online 3
# celery_queue_length{queue_name="celery"} 0
```

---

## Step 3: Configure Prometheus

### Install Prometheus

```bash
# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz

# Extract
tar xvf prometheus-2.45.0.linux-amd64.tar.gz
cd prometheus-2.45.0.linux-amd64

# Or install via package manager
sudo apt-get install prometheus  # Debian/Ubuntu
sudo yum install prometheus       # RHEL/CentOS
```

### Configure Scraping

Edit `prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# Alerting configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - localhost:9093

# Load alert rules
rule_files:
  - "celery_alerts.yml"

# Scrape configurations
scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Celery metrics
  - job_name: 'celery'
    static_configs:
      - targets: ['localhost:8000']
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: '/metrics'

  # Flower (optional)
  - job_name: 'flower'
    static_configs:
      - targets: ['localhost:5555']
```

### Start Prometheus

```bash
# Start Prometheus
./prometheus --config.file=prometheus.yml

# Or as systemd service
sudo systemctl start prometheus

# Verify
curl http://localhost:9090
```

### Verify Scraping

1. Open http://localhost:9090
2. Go to Status → Targets
3. Verify `celery` job is UP
4. Check Last Scrape and Errors

---

## Step 4: Create Grafana Dashboards

### Install Grafana

```bash
# Add Grafana repository
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"

# Install
sudo apt-get update
sudo apt-get install grafana

# Start service
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### Add Prometheus Data Source

1. Open http://localhost:3000 (default login: admin/admin)
2. Go to Configuration → Data Sources
3. Add Prometheus data source
4. Set URL: `http://localhost:9090`
5. Click Save & Test

### Import Pre-built Dashboard

1. Go to Dashboards → Import
2. Enter dashboard ID: **15913** (Celery Dashboard)
3. Select Prometheus data source
4. Click Import

### Create Custom Dashboard

**Dashboard Structure:**

```json
{
  "dashboard": {
    "title": "Celery Monitoring",
    "panels": [
      {
        "title": "Task Success Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(celery_tasks_total{state=\"SUCCESS\"}[5m])"
          }
        ]
      },
      {
        "title": "Task Failure Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(celery_tasks_total{state=\"FAILURE\"}[5m])"
          }
        ]
      },
      {
        "title": "Active Workers",
        "type": "stat",
        "targets": [
          {
            "expr": "celery_workers_online"
          }
        ]
      },
      {
        "title": "Queue Depth",
        "type": "graph",
        "targets": [
          {
            "expr": "celery_queue_length"
          }
        ]
      }
    ]
  }
}
```

### Key Metrics to Display

**Overview Panel:**

```promql
# Total tasks processed
sum(celery_tasks_total)

# Success rate percentage
(sum(celery_tasks_total{state="SUCCESS"}) / sum(celery_tasks_total)) * 100

# Active workers
celery_workers_online

# Current queue depth
sum(celery_queue_length)
```

**Task Metrics:**

```promql
# Tasks per second by state
rate(celery_tasks_total[1m])

# Tasks by name
sum by (task_name) (celery_tasks_total)

# Task success/failure ratio
sum(celery_tasks_total{state="SUCCESS"}) / sum(celery_tasks_total{state="FAILURE"})
```

**Performance Metrics:**

```promql
# Average task runtime
rate(celery_task_runtime_seconds_sum[5m]) / rate(celery_task_runtime_seconds_count[5m])

# 95th percentile task runtime
histogram_quantile(0.95, celery_task_runtime_seconds_bucket)

# Slow tasks (>30 seconds)
count(celery_task_runtime_seconds_bucket{le="30"})
```

**Worker Metrics:**

```promql
# Workers by status
celery_workers_online

# Worker pool size
sum by (worker) (celery_worker_pool_size)

# Tasks per worker
sum by (worker) (celery_tasks_total)
```

---

## Step 5: Configure Alerting

### Create Alert Rules

Create `celery_alerts.yml`:

```yaml
groups:
  - name: celery_alerts
    interval: 30s
    rules:
      # Critical: No workers online
      - alert: CeleryNoWorkersOnline
        expr: celery_workers_online == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "No Celery workers online"
          description: "All Celery workers are offline for more than 2 minutes"

      # Critical: High failure rate
      - alert: CeleryHighFailureRate
        expr: |
          (
            rate(celery_tasks_total{state="FAILURE"}[5m]) /
            rate(celery_tasks_total[5m])
          ) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High Celery task failure rate"
          description: "Task failure rate is above 10% for 5 minutes"

      # Warning: High queue depth
      - alert: CeleryHighQueueDepth
        expr: celery_queue_length > 1000
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Celery queue depth is high"
          description: "Queue {{ $labels.queue_name }} has {{ $value }} tasks"

      # Warning: Slow task processing
      - alert: CelerySlowTaskProcessing
        expr: |
          rate(celery_task_runtime_seconds_sum[5m]) /
          rate(celery_task_runtime_seconds_count[5m]) > 60
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Celery tasks are processing slowly"
          description: "Average task runtime is {{ $value }}s"

      # Warning: Task retry rate
      - alert: CeleryHighRetryRate
        expr: rate(celery_tasks_total{state="RETRY"}[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High Celery task retry rate"
          description: "Task retry rate is above 5%"

      # Info: Worker pool at capacity
      - alert: CeleryWorkerPoolFull
        expr: |
          sum by (worker) (celery_worker_active_tasks) >=
          sum by (worker) (celery_worker_pool_size)
        for: 15m
        labels:
          severity: info
        annotations:
          summary: "Celery worker pool at capacity"
          description: "Worker {{ $labels.worker }} is at full capacity"
```

### Configure Alertmanager

Install Alertmanager:

```bash
# Download
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz

# Extract and run
tar xvf alertmanager-0.26.0.linux-amd64.tar.gz
cd alertmanager-0.26.0.linux-amd64
./alertmanager --config.file=alertmanager.yml
```

Configure `alertmanager.yml`:

```yaml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'severity']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'team-notifications'

receivers:
  - name: 'team-notifications'
    email_configs:
      - to: 'alerts@yourcompany.com'
        from: 'prometheus@yourcompany.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your_email_here@gmail.com'
        auth_password: 'your_app_password_here'

    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts'
        title: 'Celery Alert'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

    pagerduty_configs:
      - service_key: 'your_pagerduty_key_here'
```

---

## Step 6: Performance Optimization

### Optimize Metrics Collection

```python
# Reduce update interval for large deployments
UPDATE_INTERVAL = 30  # seconds

# Limit task history
MAX_TASKS_IN_MEMORY = 5000

# Use sampling for high-volume metrics
SAMPLE_RATE = 0.1  # 10% sampling
```

### Optimize Prometheus

```yaml
# prometheus.yml
global:
  scrape_interval: 30s  # Increase for high-volume
  scrape_timeout: 10s

storage:
  tsdb:
    retention.time: 15d  # Reduce retention
    retention.size: 50GB
```

### Optimize Grafana

```ini
# grafana.ini
[dashboards]
min_refresh_interval = 10s

[dataproxy]
timeout = 30
```

---

## Troubleshooting

### Metrics Not Appearing

**Check exporter is running:**

```bash
curl http://localhost:8000/metrics
```

**Check Prometheus scraping:**

```bash
# View Prometheus targets
curl http://localhost:9090/api/v1/targets | jq
```

**Check Celery events are enabled:**

```bash
celery -A yourapp control enable_events
```

### High Cardinality Issues

**Problem**: Too many unique metric labels

**Solution**: Limit labels

```python
# Bad: High cardinality
task_counter = Counter('tasks', 'Tasks', ['task_name', 'args', 'worker', 'queue'])

# Good: Limited labels
task_counter = Counter('tasks', 'Tasks', ['task_name', 'state'])
```

### Missing Worker Metrics

**Enable worker stats:**

```bash
# Start workers with events
celery -A yourapp worker --events

# Or enable runtime
celery -A yourapp control enable_events
```

---

## Production Checklist

- [ ] Metrics exporter running as systemd service
- [ ] Prometheus scraping successfully
- [ ] Grafana dashboard created
- [ ] Alert rules configured
- [ ] Alertmanager notifications tested
- [ ] Retention policies set
- [ ] Resource limits configured
- [ ] Backup strategy for Prometheus data
- [ ] Security (authentication) enabled
- [ ] Documentation updated

---

## Additional Resources

- **Prometheus Documentation**: https://prometheus.io/docs/
- **Grafana Dashboards**: https://grafana.com/grafana/dashboards/
- **Alertmanager**: https://prometheus.io/docs/alerting/latest/alertmanager/
- **PromQL Guide**: https://prometheus.io/docs/prometheus/latest/querying/basics/
