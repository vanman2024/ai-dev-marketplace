# Redis Result Backend Complete Setup Guide

Complete guide for configuring Celery with Redis result backend including single instance, sentinel, and cluster configurations.

## Prerequisites

```bash
# Install Redis
sudo apt-get install redis-server  # Ubuntu/Debian
brew install redis                 # macOS

# Install Python dependencies
pip install celery redis
```

## Basic Redis Backend Configuration

### 1. Single Redis Instance (Development)

**Environment Variables (.env):**
```bash
# SECURITY: Never commit actual credentials
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password_here
REDIS_DB=0
```

**Celery Configuration (celeryconfig.py):**
```python
import os
from celery import Celery

# Security: Load from environment
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = os.getenv('REDIS_PORT', '6379')
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')
REDIS_DB = os.getenv('REDIS_DB', '0')

# Build connection string
if REDIS_PASSWORD:
    result_backend = f'redis://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}'
else:
    result_backend = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}'

app = Celery('myapp', backend=result_backend)

# Configure Redis backend
app.conf.update(
    result_expires=86400,  # 24 hours
    result_serializer='json',
    result_compression='gzip',
    result_extended=True,

    # Connection settings
    redis_max_connections=50,
    redis_socket_timeout=120,
    redis_socket_keepalive=True,
    redis_retry_on_timeout=True,
)
```

### 2. Redis Configuration (redis.conf)

**Production Redis Settings:**
```conf
# Bind to specific network interface
bind 127.0.0.1 ::1

# Enable authentication
requirepass your_strong_redis_password_here

# Persistence (for result durability)
save 900 1      # Save after 900s if 1 key changed
save 300 10     # Save after 300s if 10 keys changed
save 60 10000   # Save after 60s if 10000 keys changed

# Enable AOF (Append Only File)
appendonly yes
appendfsync everysec

# Memory management
maxmemory 2gb
maxmemory-policy allkeys-lru

# Disable dangerous commands
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG ""

# Logging
loglevel notice
logfile /var/log/redis/redis-server.log
```

**Apply configuration:**
```bash
# Edit Redis config
sudo nano /etc/redis/redis.conf

# Restart Redis
sudo systemctl restart redis-server

# Verify
redis-cli ping
# Response: PONG
```

## Advanced Redis Configurations

### 3. Redis Sentinel (High Availability)

**Sentinel provides automatic failover when master goes down.**

**Sentinel Configuration (sentinel.conf):**
```conf
# Monitor master
sentinel monitor mymaster 127.0.0.1 6379 2

# Authentication
sentinel auth-pass mymaster your_redis_password_here

# Failover settings
sentinel down-after-milliseconds mymaster 5000
sentinel parallel-syncs mymaster 1
sentinel failover-timeout mymaster 10000
```

**Celery Configuration with Sentinel:**
```python
import os
from celery import Celery

# Sentinel configuration
SENTINEL_HOSTS = [
    ('sentinel1.example.com', 26379),
    ('sentinel2.example.com', 26379),
    ('sentinel3.example.com', 26379),
]
SENTINEL_MASTER = 'mymaster'
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')

# Construct sentinel URL
# Format: sentinel://sentinel1:26379;sentinel2:26379/master_name
sentinel_hosts = ';'.join([f'{host}:{port}' for host, port in SENTINEL_HOSTS])
result_backend = f'sentinel://:{REDIS_PASSWORD}@{sentinel_hosts}/{SENTINEL_MASTER}'

app = Celery('myapp', backend=result_backend)

app.conf.update(
    result_backend_transport_options={
        'master_name': SENTINEL_MASTER,
        'sentinel_kwargs': {
            'password': REDIS_PASSWORD,
        },
    },
)
```

**Start Sentinel:**
```bash
# Start Redis Sentinel
redis-sentinel /etc/redis/sentinel.conf

# Check sentinel status
redis-cli -p 26379 sentinel masters
```

### 4. Redis Cluster (Horizontal Scaling)

**Redis Cluster distributes data across multiple nodes.**

**Cluster Setup:**
```bash
# Create cluster (6 nodes: 3 masters, 3 replicas)
redis-cli --cluster create \
  127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 \
  127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 \
  --cluster-replicas 1

# Verify cluster
redis-cli -c -p 7000 cluster nodes
```

**Celery Configuration with Cluster:**
```python
import os
from celery import Celery

# Cluster nodes
REDIS_CLUSTER_NODES = [
    {'host': 'node1.example.com', 'port': 7000},
    {'host': 'node2.example.com', 'port': 7001},
    {'host': 'node3.example.com', 'port': 7002},
]
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')

# Construct cluster URL
# Note: Celery's Redis cluster support is limited
# Use redis-py-cluster for full support
from rediscluster import RedisCluster

startup_nodes = REDIS_CLUSTER_NODES
rc = RedisCluster(
    startup_nodes=startup_nodes,
    decode_responses=True,
    password=REDIS_PASSWORD
)

# Custom backend using cluster
from celery.backends.redis import RedisBackend

class RedisClusterBackend(RedisBackend):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.client = rc

app = Celery('myapp')
app.backend = RedisClusterBackend()
```

## SSL/TLS Configuration (Production)

**Secure Redis connections with SSL:**

**Redis Configuration (redis.conf):**
```conf
# Enable TLS
port 0
tls-port 6379
tls-cert-file /path/to/redis.crt
tls-key-file /path/to/redis.key
tls-ca-cert-file /path/to/ca.crt
tls-auth-clients no
```

**Celery Configuration with SSL:**
```python
import os
import ssl
from celery import Celery

REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')

# Use rediss:// scheme for SSL
result_backend = f'rediss://:{REDIS_PASSWORD}@{REDIS_HOST}:6379/0'

app = Celery('myapp', backend=result_backend)

app.conf.update(
    result_backend_transport_options={
        'ssl_cert_reqs': ssl.CERT_REQUIRED,
        'ssl_ca_certs': '/path/to/ca.crt',
        'ssl_certfile': '/path/to/client.crt',
        'ssl_keyfile': '/path/to/client.key',
    },
)
```

## Performance Tuning

### Connection Pooling

```python
app.conf.update(
    # Adjust based on worker count
    redis_max_connections=worker_concurrency * 2,

    # Or unlimited (use with caution)
    redis_max_connections=None,

    # Connection timeouts
    redis_socket_timeout=120,
    redis_socket_connect_timeout=5,
)
```

### Result Expiration

```python
app.conf.update(
    # Aggressive expiration for high-volume systems
    result_expires=3600,  # 1 hour

    # Or keep results longer
    result_expires=7 * 86400,  # 7 days

    # Never expire (requires manual cleanup)
    result_expires=None,
)
```

### Compression

```python
app.conf.update(
    # Enable compression for large results
    result_compression='gzip',

    # Only compress results over threshold
    # (requires custom serializer)
)
```

## Monitoring and Maintenance

### Redis Monitoring

```bash
# Monitor Redis in real-time
redis-cli monitor

# Check memory usage
redis-cli info memory

# Check connected clients
redis-cli client list

# Check key count
redis-cli dbsize

# Check slow queries
redis-cli slowlog get 10
```

### Celery Result Monitoring

```python
from celery import Celery

app = Celery('myapp')

# Check backend status
def check_backend():
    backend = app.backend
    try:
        backend.client.ping()
        print("✓ Redis backend is healthy")
    except Exception as e:
        print(f"✗ Redis backend error: {e}")

# Monitor result storage
def monitor_results():
    import redis
    r = redis.from_url(app.conf.result_backend)

    # Count celery result keys
    keys = r.keys('celery-task-meta-*')
    print(f"Active results: {len(keys)}")

    # Check memory usage
    info = r.info('memory')
    print(f"Memory used: {info['used_memory_human']}")
```

### Cleanup Script

```python
# Cleanup expired results manually
def cleanup_expired_results():
    import redis
    r = redis.from_url(app.conf.result_backend)

    # Celery result keys
    keys = r.keys('celery-task-meta-*')

    deleted = 0
    for key in keys:
        ttl = r.ttl(key)
        if ttl == -1:  # No expiration set
            r.delete(key)
            deleted += 1

    print(f"Deleted {deleted} orphaned results")
```

## Troubleshooting

### Connection Issues

**Problem: Connection refused**
```bash
# Check Redis is running
sudo systemctl status redis-server

# Check Redis port
netstat -an | grep 6379

# Test connection
redis-cli -h localhost -p 6379 ping
```

**Problem: Authentication failed**
```bash
# Verify password
redis-cli -h localhost -p 6379 -a your_password_here ping

# Check redis.conf
grep requirepass /etc/redis/redis.conf
```

### Performance Issues

**Problem: Slow result retrieval**
```bash
# Check Redis memory
redis-cli info memory

# Check slow log
redis-cli slowlog get 10

# Monitor commands
redis-cli monitor | grep "celery-task-meta"
```

**Solution: Increase memory or adjust maxmemory-policy**
```conf
# redis.conf
maxmemory 4gb
maxmemory-policy allkeys-lru
```

### Result Not Found

**Problem: Results disappearing**

1. Check expiration settings
2. Check Redis memory and eviction policy
3. Verify Redis persistence is enabled
4. Check for manual key deletion

```python
# Debug result storage
result = task.delay()
print(f"Task ID: {result.id}")

# Check if key exists in Redis
import redis
r = redis.from_url(app.conf.result_backend)
key = f'celery-task-meta-{result.id}'
exists = r.exists(key)
print(f"Key exists: {exists}")

ttl = r.ttl(key)
print(f"TTL: {ttl} seconds")
```

## Security Best Practices

1. **Always use authentication:**
   ```conf
   requirepass strong_random_password_here
   ```

2. **Bind to specific interfaces:**
   ```conf
   bind 127.0.0.1 ::1
   ```

3. **Use SSL/TLS in production:**
   ```python
   result_backend = 'rediss://...'
   ```

4. **Disable dangerous commands:**
   ```conf
   rename-command FLUSHDB ""
   rename-command FLUSHALL ""
   ```

5. **Use firewall rules:**
   ```bash
   sudo ufw allow from 10.0.0.0/24 to any port 6379
   ```

6. **Store credentials in environment variables:**
   ```bash
   # Never commit to git
   REDIS_PASSWORD=actual_password_here
   ```

## Complete Example

**Directory Structure:**
```
myproject/
├── .env                 # Environment variables (not in git)
├── .env.example         # Example template (in git)
├── .gitignore          # Protect .env
├── celeryconfig.py     # Celery configuration
├── tasks.py            # Task definitions
└── worker.py           # Worker startup
```

**.env.example:**
```bash
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password_here
REDIS_DB=0
```

**tasks.py:**
```python
from celeryconfig import app

@app.task
def add(x, y):
    return x + y

@app.task(bind=True)
def long_task(self, items):
    total = sum(items)
    return {'total': total, 'count': len(items)}
```

**worker.py:**
```python
from celeryconfig import app

if __name__ == '__main__':
    app.worker_main(['worker', '--loglevel=info'])
```

**Usage:**
```bash
# Start worker
python worker.py

# In another terminal, send tasks
python -c "from tasks import add; result = add.delay(4, 6); print(result.get())"
```

## Resources

- [Redis Documentation](https://redis.io/documentation)
- [Redis Sentinel Guide](https://redis.io/topics/sentinel)
- [Redis Cluster Tutorial](https://redis.io/topics/cluster-tutorial)
- [Celery Redis Backend](https://docs.celeryq.dev/en/stable/userguide/configuration.html#redis-backend-settings)

---

**Last Updated:** 2025-11-16
**Celery Version:** 5.0+
**Redis Version:** 6.0+
