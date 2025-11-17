# Redis Sentinel Configuration Example

Redis Sentinel provides high availability for Redis by monitoring Redis instances and performing automatic failover when the master becomes unavailable.

## Overview

**Use when:**
- Requiring automatic failover for Redis broker
- Running Redis in production with HA requirements
- Need to minimize downtime during Redis failures

**Architecture:**
- Multiple Redis instances (1 master, N replicas)
- Multiple Sentinel instances (minimum 3 for quorum)
- Automatic master election on failure

## Sentinel Setup

### 1. Redis Configuration

**Master Redis (redis-master.conf):**
```conf
# Basic settings
port 6379
bind 0.0.0.0
protected-mode yes
requirepass your_redis_password_here
masterauth your_redis_password_here

# Persistence
save 900 1
save 300 10
save 60 10000
appendonly yes

# Memory management (CRITICAL for Celery)
maxmemory 512mb
maxmemory-policy noeviction

# Replication
min-replicas-to-write 1
min-replicas-max-lag 10
```

**Replica Redis (redis-replica.conf):**
```conf
# Basic settings
port 6380
bind 0.0.0.0
protected-mode yes
requirepass your_redis_password_here

# Replication
replicaof redis-master 6379
masterauth your_redis_password_here
replica-read-only yes

# Persistence
appendonly yes

# Memory management
maxmemory 512mb
maxmemory-policy noeviction
```

### 2. Sentinel Configuration

**sentinel.conf (run 3+ instances on different ports):**
```conf
# Sentinel instance
port 26379
bind 0.0.0.0

# Monitor master
sentinel monitor mymaster redis-master 6379 2
sentinel auth-pass mymaster your_redis_password_here

# Timing settings
sentinel down-after-milliseconds mymaster 5000
sentinel parallel-syncs mymaster 1
sentinel failover-timeout mymaster 10000

# Notification (optional)
sentinel notification-script mymaster /path/to/notify.sh
```

**Key parameters:**
- `mymaster`: Name of the Redis master group
- `2`: Quorum - number of Sentinels that must agree on failure
- `5000ms`: Time to wait before marking master as down
- `10000ms`: Timeout for failover process

### 3. Celery Configuration with Sentinel

**celery_sentinel.py:**
```python
import os
from celery import Celery

# Sentinel configuration
SENTINEL_HOSTS = os.getenv('REDIS_SENTINEL_HOSTS', 'localhost:26379;localhost:26380;localhost:26381')
SENTINEL_MASTER = os.getenv('REDIS_SENTINEL_MASTER', 'mymaster')
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD')
REDIS_DB = int(os.getenv('REDIS_DB', 0))

# Build sentinel URL
# Format: sentinel://host1:port1;host2:port2/db_number
broker_url = f'sentinel://{SENTINEL_HOSTS}/{REDIS_DB}'

# Initialize Celery
app = Celery('myapp', broker=broker_url, backend=broker_url)

# Sentinel transport options
app.conf.broker_transport_options = {
    'master_name': SENTINEL_MASTER,
    'sentinel_kwargs': {
        'password': REDIS_PASSWORD,
    },
    # Connection pool settings
    'max_connections': 50,
    'socket_keepalive': True,
    'socket_timeout': 5.0,
    'retry_on_timeout': True,
}

# Result backend with Sentinel
app.conf.result_backend_transport_options = {
    'master_name': SENTINEL_MASTER,
    'sentinel_kwargs': {
        'password': REDIS_PASSWORD,
    },
}

# Standard Celery configuration
app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    result_expires=3600,

    task_acks_late=True,
    task_reject_on_worker_lost=True,

    worker_prefetch_multiplier=4,
    worker_max_tasks_per_child=1000,
)

if __name__ == '__main__':
    # Test connection
    try:
        app.connection().ensure_connection(max_retries=3)
        print("✅ Connected to Redis via Sentinel")
    except Exception as e:
        print(f"❌ Connection failed: {e}")
```

### 4. Environment Variables

**.env:**
```bash
# Redis Sentinel configuration
REDIS_SENTINEL_HOSTS=sentinel1:26379;sentinel2:26379;sentinel3:26379
REDIS_SENTINEL_MASTER=mymaster
REDIS_PASSWORD=your_redis_password_here
REDIS_DB=0

# Celery broker URL
CELERY_BROKER_URL=sentinel://sentinel1:26379;sentinel2:26379;sentinel3:26379/0
```

## Docker Compose Example

**docker-compose.sentinel.yml:**
```yaml
version: '3.8'

services:
  redis-master:
    image: redis:7-alpine
    container_name: redis-master
    command: redis-server --requirepass your_redis_password_here --maxmemory-policy noeviction
    ports:
      - "6379:6379"
    volumes:
      - redis_master_data:/data
    networks:
      - redis-sentinel

  redis-replica-1:
    image: redis:7-alpine
    container_name: redis-replica-1
    command: >
      redis-server
      --replicaof redis-master 6379
      --masterauth your_redis_password_here
      --requirepass your_redis_password_here
      --maxmemory-policy noeviction
    depends_on:
      - redis-master
    networks:
      - redis-sentinel

  redis-replica-2:
    image: redis:7-alpine
    container_name: redis-replica-2
    command: >
      redis-server
      --replicaof redis-master 6379
      --masterauth your_redis_password_here
      --requirepass your_redis_password_here
      --maxmemory-policy noeviction
    depends_on:
      - redis-master
    networks:
      - redis-sentinel

  sentinel-1:
    image: redis:7-alpine
    container_name: sentinel-1
    command: >
      sh -c "echo 'sentinel monitor mymaster redis-master 6379 2' > /etc/sentinel.conf &&
             echo 'sentinel auth-pass mymaster your_redis_password_here' >> /etc/sentinel.conf &&
             echo 'sentinel down-after-milliseconds mymaster 5000' >> /etc/sentinel.conf &&
             redis-sentinel /etc/sentinel.conf"
    ports:
      - "26379:26379"
    depends_on:
      - redis-master
    networks:
      - redis-sentinel

  sentinel-2:
    image: redis:7-alpine
    container_name: sentinel-2
    command: >
      sh -c "echo 'sentinel monitor mymaster redis-master 6379 2' > /etc/sentinel.conf &&
             echo 'sentinel auth-pass mymaster your_redis_password_here' >> /etc/sentinel.conf &&
             echo 'sentinel down-after-milliseconds mymaster 5000' >> /etc/sentinel.conf &&
             redis-sentinel /etc/sentinel.conf"
    ports:
      - "26380:26379"
    depends_on:
      - redis-master
    networks:
      - redis-sentinel

  sentinel-3:
    image: redis:7-alpine
    container_name: sentinel-3
    command: >
      sh -c "echo 'sentinel monitor mymaster redis-master 6379 2' > /etc/sentinel.conf &&
             echo 'sentinel auth-pass mymaster your_redis_password_here' >> /etc/sentinel.conf &&
             echo 'sentinel down-after-milliseconds mymaster 5000' >> /etc/sentinel.conf &&
             redis-sentinel /etc/sentinel.conf"
    ports:
      - "26381:26379"
    depends_on:
      - redis-master
    networks:
      - redis-sentinel

volumes:
  redis_master_data:

networks:
  redis-sentinel:
    driver: bridge
```

## Testing Sentinel Failover

### 1. Check Sentinel Status

```bash
# Connect to any Sentinel
redis-cli -p 26379

# Get master info
SENTINEL master mymaster

# Get replica info
SENTINEL replicas mymaster

# Get Sentinel info
SENTINEL sentinels mymaster
```

### 2. Simulate Master Failure

```bash
# Stop master Redis
docker stop redis-master

# Watch Sentinel logs for failover
docker logs -f sentinel-1

# Verify new master
redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
```

### 3. Monitor with Python

```python
from redis.sentinel import Sentinel

# Connect to Sentinels
sentinel = Sentinel([
    ('localhost', 26379),
    ('localhost', 26380),
    ('localhost', 26381)
], socket_timeout=0.1)

# Get current master
master = sentinel.discover_master('mymaster')
print(f"Current master: {master}")

# Get master connection
master_conn = sentinel.master_for(
    'mymaster',
    socket_timeout=0.1,
    password='your_redis_password_here'
)

# Test connection
print(master_conn.ping())
```

## Production Best Practices

### 1. Deployment

- **Sentinel instances**: Deploy at least 3 Sentinels (odd number)
- **Quorum**: Set to majority (e.g., 2 for 3 Sentinels)
- **Network**: Deploy Sentinels on different hosts/availability zones
- **Monitoring**: Monitor all Sentinels and Redis instances

### 2. Configuration

- **Passwords**: Always use strong passwords for Redis
- **Network**: Configure `bind` carefully for security
- **Persistence**: Enable both RDB and AOF
- **Memory**: Set `maxmemory-policy noeviction` (critical for Celery)

### 3. Celery Integration

- **Connection pooling**: Configure appropriate pool size
- **Retry logic**: Enable retry on timeout
- **Health checks**: Monitor connection health
- **Failover time**: Expect 5-10 second delay during failover

## Troubleshooting

### Sentinel not detecting master down

- Check `down-after-milliseconds` setting
- Verify network connectivity between Sentinel and master
- Check Sentinel logs for error messages

### Failover not completing

- Verify quorum setting (must be > 50% of Sentinels)
- Check `failover-timeout` setting
- Ensure replicas can reach master

### Celery connection errors during failover

- Expected behavior - tasks will retry automatically
- Configure appropriate retry delays
- Monitor worker logs during failover

## References

- Redis Sentinel Documentation: https://redis.io/topics/sentinel
- Celery Redis Sentinel: https://docs.celeryq.dev/en/stable/getting-started/backends-and-brokers/redis.html
- High Availability Guide: https://redis.io/topics/sentinel#fundamental-things-to-know

## Security Notes

- Always use authentication (`requirepass`, `masterauth`)
- Configure firewall rules for Sentinel ports (26379+)
- Use SSL/TLS for production deployments
- Never expose Sentinel ports to public internet
- Rotate passwords regularly
- Monitor for unauthorized access attempts
