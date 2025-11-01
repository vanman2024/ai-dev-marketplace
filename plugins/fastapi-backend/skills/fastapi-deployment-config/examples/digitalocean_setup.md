# DigitalOcean App Platform Deployment Guide for FastAPI

Complete walkthrough for deploying production-ready FastAPI applications on DigitalOcean App Platform with managed databases, auto-scaling, and monitoring.

## Overview

DigitalOcean App Platform provides:
- Container-based deployment (Docker or buildpacks)
- Managed PostgreSQL, MySQL, Redis databases
- Auto-scaling capabilities
- CDN integration
- Built-in monitoring and alerts
- Custom domains with automatic SSL
- Starting at $12/month

## Prerequisites

- [ ] DigitalOcean account (sign up at [digitalocean.com](https://www.digitalocean.com))
- [ ] GitHub repository with FastAPI application
- [ ] Dockerfile in repository root
- [ ] `doctl` CLI installed (optional but recommended)

## Step-by-Step Deployment

### 1. Prepare Your Application

**Required files:**

```bash
your-repo/
├── main.py                    # FastAPI application
├── requirements.txt           # Python dependencies
├── Dockerfile                # Container configuration
├── digitalocean-app.yaml     # App Platform spec (optional)
└── .env.example              # Environment variable template
```

**Health check endpoint** (main.py):

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "fastapi-app"
    }
```

### 2. Install DigitalOcean CLI (Optional)

```bash
# macOS
brew install doctl

# Linux/WSL
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.98.0/doctl-1.98.0-linux-amd64.tar.gz
tar xf ~/doctl-1.98.0-linux-amd64.tar.gz
sudo mv ~/doctl /usr/local/bin

# Windows
# Download from: https://github.com/digitalocean/doctl/releases
```

**Authenticate:**

```bash
doctl auth init
# Enter your DigitalOcean API token
```

### 3. Create App Platform Specification

Create `digitalocean-app.yaml`:

```yaml
name: fastapi-app
region: nyc  # or: sfo, ams, sgp, lon, fra, tor, blr

services:
  - name: api
    dockerfile_path: Dockerfile
    source_dir: /

    github:
      repo: your-username/your-repo
      branch: main
      deploy_on_push: true

    instance_count: 1
    instance_size_slug: basic-xs  # $12/month

    envs:
      - key: ENVIRONMENT
        value: production
        scope: RUN_TIME

      - key: SECRET_KEY
        scope: RUN_TIME
        type: SECRET

      - key: DATABASE_URL
        scope: RUN_TIME
        type: SECRET

    health_check:
      http_path: /health
      initial_delay_seconds: 10
      period_seconds: 30
      timeout_seconds: 10

    routes:
      - path: /

databases:
  - name: db
    engine: PG
    version: "15"
    production: true  # For production tier with daily backups
    cluster_name: fastapi-db-cluster
    db_name: appdb
    db_user: appuser
```

### 4. Deploy via DigitalOcean Dashboard

#### 4.1. Create New App

1. **Navigate to App Platform:**
   - Login to [DigitalOcean](https://cloud.digitalocean.com)
   - Click "Apps" in left sidebar
   - Click "Create App"

2. **Choose Source:**
   - Select "GitHub"
   - Authorize DigitalOcean
   - Choose repository
   - Select branch (main/production)

3. **Configure Resources:**
   - DigitalOcean auto-detects Dockerfile
   - Confirm "Dockerfile" as build method
   - Set build context to `/`

4. **Configure App:**
   - **App Name:** `fastapi-app`
   - **Region:** Select closest to users
   - **Instance Size:** Basic ($12/mo) or Professional ($24/mo)
   - **Instance Count:** 1 (can scale later)

#### 4.2. Add Environment Variables

1. **Navigate to App Settings:**
   - Click on your app
   - Go to "Settings" tab
   - Scroll to "App-Level Environment Variables"

2. **Add Variables:**
   ```
   ENVIRONMENT=production
   SECRET_KEY=<click-encrypt-to-make-secret>
   LOG_LEVEL=INFO
   CORS_ORIGINS=https://yourdomain.com
   ```

3. **For sensitive values:**
   - Check "Encrypt" checkbox
   - DigitalOcean encrypts at rest

#### 4.3. Add Database Component

1. **In App Dashboard:**
   - Click "Create" → "Create Resources"
   - Select "Database"
   - Choose "PostgreSQL 15"

2. **Configure Database:**
   - **Cluster Name:** `fastapi-db-cluster`
   - **Database Name:** `appdb`
   - **Production Tier:** Enable for backups and high availability
   - **Size:** Basic ($15/mo) or Professional ($60/mo)

3. **Connect to App:**
   - DigitalOcean automatically creates `DATABASE_URL`
   - Available in environment as `${db.DATABASE_URL}`

#### 4.4. Configure Health Check

1. **In Service Settings:**
   - Navigate to your service
   - Click "Settings"
   - Scroll to "Health Check"

2. **Set Health Check:**
   ```
   HTTP Path: /health
   Initial Delay: 10 seconds
   Period: 30 seconds
   Timeout: 10 seconds
   Success Threshold: 1
   Failure Threshold: 3
   ```

#### 4.5. Deploy

1. **Review Configuration:**
   - Check all settings
   - Verify environment variables
   - Confirm pricing

2. **Deploy:**
   - Click "Create Resources"
   - Wait 5-10 minutes for deployment
   - Monitor build logs

### 5. Deploy via CLI (Alternative)

```bash
# Create app from YAML spec
doctl apps create --spec digitalocean-app.yaml

# Get app ID
doctl apps list

# Set environment variables
doctl apps update <app-id> --spec digitalocean-app.yaml

# Trigger deployment
doctl apps create-deployment <app-id>

# View logs
doctl apps logs <app-id> --type run

# Get app URL
doctl apps get <app-id> --format URL
```

### 6. Configure Custom Domain

#### 6.1. Add Domain to App

1. **In App Dashboard:**
   - Click on your app
   - Navigate to "Settings" tab
   - Scroll to "Domains"
   - Click "Add Domain"

2. **Enter Domain:**
   - Domain: `api.yourdomain.com`
   - DigitalOcean provides DNS records

#### 6.2. Configure DNS

Add CNAME record to your DNS provider:

```
Type: CNAME
Name: api
Value: <app-url>.ondigitalocean.app
TTL: 3600
```

For root domain, use ALIAS or ANAME:

```
Type: ALIAS (or ANAME)
Name: @
Value: <app-url>.ondigitalocean.app
```

#### 6.3. SSL Certificate

- DigitalOcean automatically provisions Let's Encrypt SSL
- Certificates renew automatically
- HTTPS enabled by default

### 7. Set Up Managed Database

#### 7.1. Create Database Cluster

**Via Dashboard:**
1. Navigate to "Databases"
2. Click "Create Database Cluster"
3. Choose PostgreSQL 15
4. Select cluster size:
   - **Basic:** $15/mo (1GB RAM, 1 vCPU, 10GB storage)
   - **Professional:** $60/mo (4GB RAM, 2 vCPU, 38GB storage)
5. Choose same region as app
6. Enable backups (daily snapshots)

**Via CLI:**

```bash
doctl databases create fastapi-db-cluster \
  --engine pg \
  --version 15 \
  --region nyc1 \
  --size db-s-1vcpu-1gb
```

#### 7.2. Connect Database to App

**Automatic (recommended):**
- In App Platform, add database component
- DigitalOcean auto-injects `DATABASE_URL`

**Manual:**

```bash
# Get connection string
doctl databases connection <database-id>

# Add to app environment
doctl apps update <app-id> --upsert-env DATABASE_URL=<connection-string>
```

#### 7.3. Database Security

1. **Trusted Sources:**
   - App Platform automatically added to trusted sources
   - To add manual IP:
     ```bash
     doctl databases firewalls append <database-id> --rule ip_addr:<ip-address>
     ```

2. **SSL Mode:**
   - Always use `sslmode=require` in connection string
   - DigitalOcean provides SSL certificates

### 8. Add Redis Cache (Optional)

```bash
# Create Redis cluster
doctl databases create fastapi-redis \
  --engine redis \
  --version 7 \
  --region nyc1 \
  --size db-s-1vcpu-1gb

# Get connection info
doctl databases connection <redis-id>

# Add to app environment
doctl apps update <app-id> --upsert-env REDIS_URL=<redis-url>
```

### 9. Configure Auto-Scaling

**Via Dashboard:**
1. Navigate to your app service
2. Click "Settings"
3. Scroll to "Scaling"
4. Configure:
   ```
   Min Instances: 1
   Max Instances: 5
   CPU Threshold: 80%
   Memory Threshold: 80%
   ```

**Via YAML spec:**

```yaml
services:
  - name: api
    autoscaling:
      min_instance_count: 1
      max_instance_count: 5
      metrics:
        cpu:
          percent: 80
```

### 10. Monitoring and Alerts

#### 10.1. Built-in Monitoring

**App Platform Dashboard shows:**
- Request rate
- Response time
- Error rate
- CPU usage
- Memory usage
- Bandwidth

**View Metrics:**
```bash
doctl apps tier instance-size list
doctl monitoring metrics bandwidth droplet <droplet-id>
```

#### 10.2. Set Up Alerts

1. **In DigitalOcean Dashboard:**
   - Navigate to "Monitoring"
   - Click "Create Alert Policy"

2. **Alert Types:**
   - CPU usage > 90%
   - Memory usage > 90%
   - Bandwidth limit approaching
   - Droplet offline

3. **Notification Methods:**
   - Email
   - Slack
   - PagerDuty
   - Webhook

### 11. Database Backups and Migrations

#### 11.1. Automatic Backups

DigitalOcean provides:
- **Daily backups** (production tier)
- **Point-in-time recovery** (7-day window)
- **Manual snapshots**

**Create manual backup:**

```bash
doctl databases backups list <database-id>
doctl databases backups create <database-id>
```

#### 11.2. Run Migrations

**Option 1: Pre-deployment job**

Add to `digitalocean-app.yaml`:

```yaml
jobs:
  - name: migrate
    kind: PRE_DEPLOY
    dockerfile_path: Dockerfile
    source_dir: /
    run_command: alembic upgrade head
    envs:
      - key: DATABASE_URL
        scope: RUN_TIME
```

**Option 2: Manual via console**

```bash
# SSH into app container
doctl apps logs <app-id> --type run --follow

# Or run one-off command
# (Note: DigitalOcean doesn't support one-off commands directly)
# Use a separate migration job instead
```

### 12. CI/CD Integration

#### 12.1. Auto-Deploy on Push

Already configured in `digitalocean-app.yaml`:

```yaml
github:
  deploy_on_push: true
  branch: main
```

#### 12.2. GitHub Actions Integration

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to DigitalOcean

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install doctl
        uses: digitalocean/action-doctl@v2
        with:
          token: ${{ secrets.DIGITALOCEAN_TOKEN }}

      - name: Trigger deployment
        run: |
          doctl apps create-deployment ${{ secrets.APP_ID }} --wait
```

### 13. Troubleshooting

#### Build Failures

**Check build logs:**
```bash
doctl apps logs <app-id> --type build
```

**Common issues:**
- Dockerfile syntax errors
- Missing dependencies
- Build timeout (increase in settings)

#### Runtime Errors

**Check runtime logs:**
```bash
doctl apps logs <app-id> --type run --follow
```

**Common issues:**
- Missing environment variables
- Database connection timeout
- Port binding issues

#### Database Connection Issues

**Test connection:**

```python
# test_db.py
import os
import psycopg2

conn = psycopg2.connect(os.getenv("DATABASE_URL"))
cur = conn.cursor()
cur.execute("SELECT version();")
print(cur.fetchone())
```

**Check trusted sources:**
```bash
doctl databases firewalls list <database-id>
```

#### Health Check Failures

**Debug health endpoint:**
```bash
# Get app URL
APP_URL=$(doctl apps get <app-id> --format URL --no-header)

# Test health check
curl -v https://$APP_URL/health
```

## Cost Breakdown

### App Platform
- **Basic:** $12/month (512MB RAM, 1 vCPU)
- **Professional XS:** $24/month (1GB RAM, 1 vCPU)
- **Professional S:** $48/month (2GB RAM, 1 vCPU)

### Databases
- **Basic:** $15/month (1GB RAM, 10GB storage, daily backups)
- **Professional:** $60/month (4GB RAM, 38GB storage, point-in-time recovery)

### Bandwidth
- 1TB included free per month
- $0.01/GB beyond quota

### Total Estimate
- **Starter:** $27/month (Basic app + Basic DB)
- **Production:** $84/month (Professional app + Professional DB)

## Best Practices

### 1. Use Managed Databases
Always use DigitalOcean managed databases for:
- Automatic backups
- High availability
- Maintenance and updates
- Monitoring

### 2. Enable Auto-Scaling
Configure auto-scaling for variable traffic:
```yaml
autoscaling:
  min_instance_count: 1
  max_instance_count: 5
```

### 3. Use App-Level Secrets
Encrypt sensitive environment variables

### 4. Monitor Costs
- Set up billing alerts
- Review usage monthly
- Optimize instance sizes

### 5. Regular Backups
- Enable daily automated backups
- Test restore procedures
- Keep manual snapshots before major changes

### 6. Security
- Use trusted sources for database access
- Enable SSL for all connections
- Rotate secrets regularly
- Implement rate limiting

## Resources

- [DigitalOcean App Platform Docs](https://docs.digitalocean.com/products/app-platform/)
- [doctl CLI Reference](https://docs.digitalocean.com/reference/doctl/)
- [App Platform Pricing](https://www.digitalocean.com/pricing/app-platform)
- [DigitalOcean Community](https://www.digitalocean.com/community)
- [DigitalOcean Status](https://status.digitalocean.com/)

---

**Deployment Time:** ~10-15 minutes
**Difficulty:** Medium
**Best For:** Production applications, teams needing managed infrastructure
