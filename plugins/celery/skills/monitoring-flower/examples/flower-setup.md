# Complete Flower Setup Guide

This guide walks through setting up Flower for production Celery monitoring, including installation, configuration, authentication, deployment, and integration with monitoring tools.

## Table of Contents

1. [Installation](#installation)
2. [Basic Configuration](#basic-configuration)
3. [Authentication Setup](#authentication-setup)
4. [Production Deployment](#production-deployment)
5. [Reverse Proxy Configuration](#reverse-proxy-configuration)
6. [SSL/TLS Setup](#ssltls-setup)
7. [Monitoring Integration](#monitoring-integration)
8. [Troubleshooting](#troubleshooting)

---

## Installation

### Prerequisites

- Python 3.8 or higher
- Running Celery application
- Redis or RabbitMQ broker
- (Optional) Nginx for reverse proxy

### Install Flower

```bash
# Basic installation
pip install flower

# With Redis support
pip install flower redis

# With all optional dependencies
pip install flower[prometheus]
```

### Verify Installation

```bash
# Check Flower version
flower --version

# Test Flower command
flower --help
```

---

## Basic Configuration

### Method 1: Environment Variables

Create `.env` file (NEVER commit with real credentials):

```bash
# .env
CELERY_BROKER_URL=redis://localhost:6379/0
FLOWER_PORT=5555
FLOWER_MAX_TASKS=10000
FLOWER_PERSISTENT=True
FLOWER_DB=flower.db

# Authentication (set real passwords!)
FLOWER_BASIC_AUTH=admin:your_admin_password_here
```

Create `.env.example` template (safe to commit):

```bash
# .env.example
CELERY_BROKER_URL=redis://localhost:6379/0
FLOWER_PORT=5555
FLOWER_MAX_TASKS=10000
FLOWER_PERSISTENT=True
FLOWER_DB=flower.db
FLOWER_BASIC_AUTH=admin:your_password_here
```

Add to `.gitignore`:

```bash
echo ".env" >> .gitignore
echo "flower.db" >> .gitignore
```

### Method 2: Configuration File

Create `flowerconfig.py`:

```python
import os

# Broker configuration
broker_url = os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0")

# Network configuration
port = 5555
address = "0.0.0.0"

# Persistence
persistent = True
db = "flower.db"

# Task history
max_tasks = 10000

# Authentication
basic_auth = os.getenv("FLOWER_BASIC_AUTH")
```

---

## Authentication Setup

### Option 1: Basic Authentication

**Simplest option for small teams**

```bash
# Set in environment
export FLOWER_BASIC_AUTH="admin:your_admin_password_here,viewer:your_viewer_password_here"

# Start Flower
flower --basic_auth=$FLOWER_BASIC_AUTH
```

**Multiple users with different access levels:**

```bash
# Admin users (full access)
ADMIN_AUTH="admin:secure_admin_pass,manager:secure_mgr_pass"

# Read-only users
VIEWER_AUTH="viewer:viewer_pass,analyst:analyst_pass"

# Combine
export FLOWER_BASIC_AUTH="$ADMIN_AUTH,$VIEWER_AUTH"
```

### Option 2: OAuth2 (Google)

**Best for organizations using Google Workspace**

**Step 1: Create OAuth2 Credentials**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 Client ID
5. Add authorized redirect URI: `http://your-domain.com/login`

**Step 2: Configure Flower**

```bash
# Set OAuth credentials
export FLOWER_OAUTH2_KEY="your_google_client_id_here"
export FLOWER_OAUTH2_SECRET="your_google_client_secret_here"
export FLOWER_OAUTH2_REDIRECT_URI="http://localhost:5555/login"
export FLOWER_AUTH_REGEX=".*@yourcompany\.com"

# Start Flower with OAuth
flower \
  --auth="$FLOWER_AUTH_REGEX" \
  --oauth2_key="$FLOWER_OAUTH2_KEY" \
  --oauth2_secret="$FLOWER_OAUTH2_SECRET" \
  --oauth2_redirect_uri="$FLOWER_OAUTH2_REDIRECT_URI"
```

**Step 3: Test OAuth Flow**

1. Navigate to `http://localhost:5555`
2. Click "Sign in with Google"
3. Authorize application
4. Should redirect to Flower dashboard

---

## Production Deployment

### Step 1: Create Dedicated User

```bash
# Create celery user
sudo useradd -r -s /bin/false celery

# Create directories
sudo mkdir -p /var/lib/flower
sudo mkdir -p /var/log/flower
sudo mkdir -p /opt/yourproject

# Set permissions
sudo chown -R celery:celery /var/lib/flower
sudo chown -R celery:celery /var/log/flower
sudo chown -R celery:celery /opt/yourproject
```

### Step 2: Install as Systemd Service

```bash
# Copy service file
sudo cp scripts/flower-systemd.service /etc/systemd/system/flower.service

# Edit configuration
sudo nano /etc/systemd/system/flower.service
```

Update these values:

```ini
[Service]
User=celery
Group=celery
WorkingDirectory=/opt/yourproject
Environment="CELERY_BROKER_URL=redis://your_redis_password_here@localhost:6379/0"
Environment="FLOWER_BASIC_AUTH=admin:your_secure_password_here"
ExecStart=/opt/yourproject/venv/bin/flower --broker=${CELERY_BROKER_URL}
```

### Step 3: Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable flower

# Start service
sudo systemctl start flower

# Check status
sudo systemctl status flower

# View logs
sudo journalctl -u flower -f
```

### Step 4: Verify Service

```bash
# Test connectivity
curl http://localhost:5555

# Run validation script
./scripts/test-flower.sh http://localhost:5555
```

---

## Reverse Proxy Configuration

### Nginx Configuration

**Create `/etc/nginx/sites-available/flower`:**

```nginx
# Flower Monitoring
server {
    listen 80;
    server_name flower.yourdomain.com;

    # Redirect HTTP to HTTPS (after SSL setup)
    # return 301 https://$server_name$request_uri;

    location / {
        proxy_pass http://localhost:5555;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (for real-time updates)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Access control (optional)
    # allow 10.0.0.0/8;    # Internal network
    # allow 192.168.0.0/16; # VPN
    # deny all;
}
```

**Enable site:**

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/flower /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### With URL Prefix

If hosting Flower under a path (e.g., `https://example.com/flower/`):

**Update Flower config:**

```python
# flowerconfig.py
url_prefix = "/flower"
```

**Update Nginx config:**

```nginx
location /flower/ {
    proxy_pass http://localhost:5555/;
    # ... rest of proxy settings
}
```

---

## SSL/TLS Setup

### Method 1: Let's Encrypt (Recommended)

```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d flower.yourdomain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

Certbot automatically updates Nginx configuration for HTTPS.

### Method 2: Manual Certificate

**Update Nginx configuration:**

```nginx
server {
    listen 443 ssl http2;
    server_name flower.yourdomain.com;

    # SSL certificates
    ssl_certificate /etc/ssl/certs/flower.crt;
    ssl_certificate_key /etc/ssl/private/flower.key;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000" always;

    location / {
        proxy_pass http://localhost:5555;
        # ... rest of proxy settings
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name flower.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

---

## Monitoring Integration

### Prometheus Metrics

**Start metrics exporter:**

```bash
# Install dependencies
pip install prometheus-client

# Run exporter
python templates/prometheus-metrics.py &

# Verify metrics
curl http://localhost:8000/metrics
```

**Configure Prometheus (`prometheus.yml`):**

```yaml
scrape_configs:
  - job_name: 'celery'
    static_configs:
      - targets: ['localhost:8000']
    scrape_interval: 15s
```

### Grafana Dashboard

1. Add Prometheus data source to Grafana
2. Import Celery dashboard (ID: 15913)
3. Or create custom dashboard with queries:

```promql
# Task success rate
rate(celery_tasks_total{state="SUCCESS"}[5m])

# Task failure rate
rate(celery_tasks_total{state="FAILURE"}[5m])

# Active workers
celery_workers_online

# Queue depth
celery_queue_length

# Average task runtime
rate(celery_task_runtime_seconds_sum[5m]) /
rate(celery_task_runtime_seconds_count[5m])
```

### Alerting

**Create alert rules (`alerts.yml`):**

```yaml
groups:
  - name: celery
    interval: 30s
    rules:
      # High failure rate
      - alert: CeleryHighFailureRate
        expr: |
          rate(celery_tasks_total{state="FAILURE"}[5m]) > 0.1
        for: 5m
        annotations:
          summary: "High Celery task failure rate"

      # No workers
      - alert: CeleryNoWorkers
        expr: celery_workers_online == 0
        for: 2m
        annotations:
          summary: "No Celery workers online"

      # High queue depth
      - alert: CeleryHighQueueDepth
        expr: celery_queue_length > 1000
        for: 10m
        annotations:
          summary: "Celery queue depth exceeds threshold"
```

---

## Troubleshooting

### Flower Won't Start

**Check port availability:**

```bash
# Check if port is in use
lsof -i :5555

# Kill process if needed
kill $(lsof -t -i :5555)
```

**Check broker connectivity:**

```bash
# Test Redis
redis-cli -h localhost -p 6379 ping

# Test RabbitMQ
rabbitmqctl status
```

**Check logs:**

```bash
# Systemd service logs
sudo journalctl -u flower -n 50 --no-pager

# Direct execution for debugging
flower --broker=$CELERY_BROKER_URL --logging=debug
```

### No Workers Visible

**Enable events on workers:**

```bash
# Enable events
celery -A yourapp control enable_events

# Or start workers with events
celery -A yourapp worker --events
```

**Check broker URL matches:**

```bash
# Workers
echo $CELERY_BROKER_URL

# Flower
# Should be the same!
```

### Authentication Not Working

**Test credentials:**

```bash
# Test basic auth
curl -u admin:password http://localhost:5555

# Check environment variable
echo $FLOWER_BASIC_AUTH

# Verify format (username:password)
```

**OAuth troubleshooting:**

- Verify redirect URI matches exactly
- Check OAuth credentials are valid
- Ensure email regex is correct
- Test with browser developer console

### Performance Issues

**Reduce task retention:**

```python
# flowerconfig.py
max_tasks = 5000  # Lower value
```

**Enable database persistence:**

```python
persistent = True
db = "flower.db"
```

**Increase resource limits:**

```ini
# systemd service
MemoryLimit=4G
CPUQuota=200%
```

---

## Production Checklist

Before deploying to production:

- [ ] Authentication enabled (basic auth or OAuth)
- [ ] HTTPS configured (Let's Encrypt or manual)
- [ ] Reverse proxy setup (Nginx/Caddy)
- [ ] Firewall rules configured
- [ ] Systemd service installed and enabled
- [ ] Resource limits set appropriately
- [ ] Database persistence enabled
- [ ] Task retention limit configured
- [ ] Monitoring integrated (Prometheus/Grafana)
- [ ] Alerting rules configured
- [ ] Backup strategy for flower.db
- [ ] Log rotation configured
- [ ] Security headers enabled
- [ ] Rate limiting configured
- [ ] Documentation updated
- [ ] Team access tested

---

## Additional Resources

- **Flower Documentation**: https://flower.readthedocs.io/
- **Celery Monitoring Guide**: https://docs.celeryq.dev/en/stable/userguide/monitoring.html
- **Nginx Reverse Proxy**: https://nginx.org/en/docs/http/ngx_http_proxy_module.html
- **Let's Encrypt**: https://letsencrypt.org/
- **Prometheus**: https://prometheus.io/
- **Grafana**: https://grafana.com/
