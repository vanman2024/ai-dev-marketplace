# Complete Docker Deployment Example

This guide demonstrates a full production-ready Celery deployment using Docker Compose.

## Scenario

Deploy a complete Celery infrastructure with:
- Redis broker
- PostgreSQL result backend
- 3 Celery workers
- Beat scheduler
- Flower monitoring dashboard

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Project with Celery tasks configured

## Step 1: Project Structure

```
my-celery-project/
├── app/
│   ├── __init__.py
│   ├── celery_app.py
│   ├── tasks.py
│   └── celeryconfig.py
├── docker-compose.yml
├── Dockerfile.worker
├── requirements.txt
├── .env
└── .dockerignore
```

## Step 2: Environment Configuration

Create `.env` file (NEVER commit this):

```bash
# Broker Configuration
CELERY_BROKER_URL=redis://redis:6379/0

# Result Backend
POSTGRES_DB=celery_results
POSTGRES_USER=celery
POSTGRES_PASSWORD=your_secure_postgres_password_here

CELERY_RESULT_BACKEND=db+postgresql://celery:your_secure_postgres_password_here@postgres:5432/celery_results

# Application Settings
APP_ENV=production
LOG_LEVEL=info

# Flower Authentication
FLOWER_USER=admin
FLOWER_PASSWORD=your_secure_flower_password_here
```

Create `.env.example` for version control:

```bash
# Broker Configuration
CELERY_BROKER_URL=redis://redis:6379/0

# Result Backend
POSTGRES_DB=celery_results
POSTGRES_USER=celery
POSTGRES_PASSWORD=your_postgres_password_here

CELERY_RESULT_BACKEND=db+postgresql://celery:your_postgres_password_here@postgres:5432/celery_results

# Application Settings
APP_ENV=production
LOG_LEVEL=info

# Flower Authentication
FLOWER_USER=admin
FLOWER_PASSWORD=your_flower_password_here
```

## Step 3: Generate Configuration Files

```bash
# Use the deployment script
./scripts/deploy.sh docker --env=production --dry-run

# This generates:
# - docker-compose.yml
# - Dockerfile.worker
```

## Step 4: Build Images

```bash
# Build the worker image
docker-compose build celery-worker

# View built image
docker images | grep celery-worker
```

## Step 5: Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# Should see:
# - redis (Up, healthy)
# - postgres (Up, healthy)
# - celery-worker (Up, healthy)
# - celery-beat (Up, healthy)
# - flower (Up, healthy)
```

## Step 6: Verify Health

```bash
# Check worker health
docker-compose exec celery-worker celery -A myapp inspect ping

# Expected output:
# -> celery@worker1: OK
# -> celery@worker2: OK
# -> celery@worker3: OK

# Check Redis
docker-compose exec redis redis-cli ping
# Expected: PONG

# Check PostgreSQL
docker-compose exec postgres pg_isready -U celery
# Expected: accepting connections

# Check logs
docker-compose logs -f celery-worker
```

## Step 7: Submit Test Tasks

```bash
# Enter worker container
docker-compose exec celery-worker python

# In Python shell:
>>> from celery import current_app
>>> result = current_app.send_task('myapp.tasks.add', args=[4, 5])
>>> result.get(timeout=10)
9
>>> exit()
```

## Step 8: Access Flower Dashboard

Open browser to http://localhost:5555

Login with credentials from `.env`:
- Username: admin
- Password: your_flower_password_here

You should see:
- Active workers: 3
- Processed tasks
- Real-time monitoring

## Step 9: Scale Workers

```bash
# Scale to 5 workers
docker-compose up -d --scale celery-worker=5

# Verify
docker-compose ps | grep celery-worker
# Should show 5 instances

# Check in Flower
# Dashboard should show 5 active workers
```

## Step 10: Test Beat Scheduler

```bash
# View beat schedule
docker-compose exec celery-beat cat /var/lib/celery/celerybeat-schedule.db

# Check beat logs
docker-compose logs -f celery-beat

# Should see periodic task execution logs
```

## Monitoring and Maintenance

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f celery-worker

# Last 100 lines
docker-compose logs --tail=100 celery-worker

# With timestamps
docker-compose logs -f -t celery-worker
```

### Check Resource Usage

```bash
# Container stats
docker stats

# Specific service
docker stats celery-worker
```

### Restart Services

```bash
# Restart all workers
docker-compose restart celery-worker

# Restart specific service
docker-compose restart celery-beat

# Graceful restart (allows tasks to finish)
docker-compose kill -s SIGTERM celery-worker
docker-compose up -d celery-worker
```

### Update Application Code

```bash
# Rebuild with new code
docker-compose build celery-worker

# Rolling restart (zero downtime)
docker-compose up -d --no-deps --scale celery-worker=6 celery-worker
sleep 30
docker-compose up -d --no-deps --scale celery-worker=3 celery-worker
```

## Troubleshooting

### Workers Not Starting

```bash
# Check logs
docker-compose logs celery-worker

# Common issues:
# - Import errors: Check PYTHONPATH
# - Connection errors: Verify broker URL
# - Permission errors: Check file ownership
```

### Tasks Not Executing

```bash
# Verify workers are registered
docker-compose exec celery-worker celery -A myapp inspect registered

# Check active tasks
docker-compose exec celery-worker celery -A myapp inspect active

# Verify queues
docker-compose exec celery-worker celery -A myapp inspect active_queues
```

### High Memory Usage

```bash
# Check memory per worker
docker stats --no-stream celery-worker

# Reduce concurrency in docker-compose.yml:
command: celery -A myapp worker --loglevel=info --concurrency=2

# Or add max-tasks-per-child:
command: celery -A myapp worker --loglevel=info --max-tasks-per-child=100

# Restart to apply
docker-compose restart celery-worker
```

### Database Connection Errors

```bash
# Check PostgreSQL
docker-compose exec postgres psql -U celery -d celery_results -c "\dt"

# Verify connection string
docker-compose exec celery-worker env | grep CELERY_RESULT_BACKEND

# Test connection manually
docker-compose exec celery-worker python -c "
from sqlalchemy import create_engine
engine = create_engine('$CELERY_RESULT_BACKEND')
conn = engine.connect()
print('Connection successful')
conn.close()
"
```

## Production Best Practices

1. **Use docker-compose.prod.yml for production**
   - Separate dev/prod configurations
   - Production-specific resource limits

2. **External databases**
   - Use managed Redis (AWS ElastiCache, Azure Cache)
   - Use managed PostgreSQL (RDS, Cloud SQL)

3. **Volume management**
   - Use named volumes for persistence
   - Regular database backups

4. **Security**
   - Never commit `.env` files
   - Use Docker secrets for sensitive data
   - Run containers as non-root user

5. **Monitoring**
   - Export logs to centralized system
   - Set up alerts for worker failures
   - Monitor queue depth

6. **High availability**
   - Multiple Redis instances (Sentinel)
   - PostgreSQL replication
   - Worker distribution across hosts

## Cleanup

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: deletes data)
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

## Next Steps

- Configure log rotation
- Set up automated backups
- Implement monitoring with Prometheus
- Add Grafana dashboards
- Configure autoscaling based on metrics
