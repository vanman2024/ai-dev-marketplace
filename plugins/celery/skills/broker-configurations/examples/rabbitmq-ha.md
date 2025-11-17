# RabbitMQ High Availability Configuration Example

RabbitMQ quorum queues provide high availability and data safety for Celery message brokers using a Raft consensus algorithm.

## Overview

**Use when:**
- Requiring high availability for message broker
- Need guaranteed message delivery
- Running in production with strict reliability requirements
- Multiple worker nodes processing tasks

**Benefits:**
- Automatic leader election
- Data replication across cluster nodes
- Fault tolerance (survives node failures)
- No message loss on node failure

## Quorum Queues vs Classic Mirrored Queues

| Feature | Quorum Queues | Classic Mirrored |
|---------|---------------|------------------|
| Consensus | Raft algorithm | None (primary-backup) |
| Data safety | High | Medium |
| Performance | Good | Better for small messages |
| Recommended | ✅ Yes (since 5.5) | ❌ Deprecated |

## RabbitMQ Cluster Setup

### 1. Cluster Configuration

**rabbitmq.conf (all nodes):**
```conf
# Cluster settings
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config
cluster_formation.classic_config.nodes.1 = rabbit@node1
cluster_formation.classic_config.nodes.2 = rabbit@node2
cluster_formation.classic_config.nodes.3 = rabbit@node3

# Erlang cookie (must be same on all nodes)
# Set via: echo "your_erlang_cookie_here" > /var/lib/rabbitmq/.erlang.cookie

# Memory and disk
vm_memory_high_watermark.relative = 0.4
disk_free_limit.relative = 1.5

# Performance
channel_max = 2048
heartbeat = 60

# Queue defaults
default_queue_type = quorum
```

### 2. Docker Compose Cluster

**docker-compose.rabbitmq-cluster.yml:**
```yaml
version: '3.8'

services:
  rabbitmq-1:
    image: rabbitmq:3.13-management-alpine
    hostname: rabbitmq-1
    container_name: rabbitmq-1
    environment:
      RABBITMQ_ERLANG_COOKIE: your_erlang_cookie_here
      RABBITMQ_DEFAULT_USER: celery
      RABBITMQ_DEFAULT_PASS: your_rabbitmq_password_here
      RABBITMQ_DEFAULT_VHOST: celery_vhost
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - rabbitmq1_data:/var/lib/rabbitmq
      - ./rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro
    networks:
      - rabbitmq-cluster

  rabbitmq-2:
    image: rabbitmq:3.13-management-alpine
    hostname: rabbitmq-2
    container_name: rabbitmq-2
    environment:
      RABBITMQ_ERLANG_COOKIE: your_erlang_cookie_here
      RABBITMQ_DEFAULT_USER: celery
      RABBITMQ_DEFAULT_PASS: your_rabbitmq_password_here
    ports:
      - "5673:5672"
      - "15673:15672"
    volumes:
      - rabbitmq2_data:/var/lib/rabbitmq
      - ./rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro
    depends_on:
      - rabbitmq-1
    networks:
      - rabbitmq-cluster

  rabbitmq-3:
    image: rabbitmq:3.13-management-alpine
    hostname: rabbitmq-3
    container_name: rabbitmq-3
    environment:
      RABBITMQ_ERLANG_COOKIE: your_erlang_cookie_here
      RABBITMQ_DEFAULT_USER: celery
      RABBITMQ_DEFAULT_PASS: your_rabbitmq_password_here
    ports:
      - "5674:5672"
      - "15674:15672"
    volumes:
      - rabbitmq3_data:/var/lib/rabbitmq
      - ./rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro
    depends_on:
      - rabbitmq-1
    networks:
      - rabbitmq-cluster

  # HAProxy for load balancing
  haproxy:
    image: haproxy:2.8-alpine
    container_name: rabbitmq-haproxy
    ports:
      - "5670:5670"  # Load balanced AMQP
      - "15670:15670"  # Load balanced management
      - "8404:8404"  # HAProxy stats
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
    depends_on:
      - rabbitmq-1
      - rabbitmq-2
      - rabbitmq-3
    networks:
      - rabbitmq-cluster

volumes:
  rabbitmq1_data:
  rabbitmq2_data:
  rabbitmq3_data:

networks:
  rabbitmq-cluster:
    driver: bridge
```

### 3. HAProxy Configuration

**haproxy.cfg:**
```conf
global
    log stdout format raw local0
    maxconn 4096

defaults
    log global
    mode tcp
    timeout connect 10s
    timeout client 30s
    timeout server 30s
    retries 3

# HAProxy stats
listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /
    stats refresh 10s

# AMQP load balancer
listen rabbitmq_amqp
    bind *:5670
    mode tcp
    balance roundrobin
    option tcplog
    server rabbitmq-1 rabbitmq-1:5672 check inter 5s
    server rabbitmq-2 rabbitmq-2:5672 check inter 5s
    server rabbitmq-3 rabbitmq-3:5672 check inter 5s

# Management UI load balancer
listen rabbitmq_management
    bind *:15670
    mode http
    balance roundrobin
    option httplog
    server rabbitmq-1 rabbitmq-1:15672 check inter 5s
    server rabbitmq-2 rabbitmq-2:15672 check inter 5s
    server rabbitmq-3 rabbitmq-3:15672 check inter 5s
```

## Celery Configuration with Quorum Queues

**celery_quorum.py:**
```python
import os
from celery import Celery
from kombu import Queue, Exchange

# RabbitMQ cluster nodes (with HAProxy)
RABBITMQ_HOST = os.getenv('RABBITMQ_HOST', 'localhost')
RABBITMQ_PORT = int(os.getenv('RABBITMQ_PORT', 5670))  # HAProxy port
RABBITMQ_USER = os.getenv('RABBITMQ_USER', 'celery')
RABBITMQ_PASSWORD = os.getenv('RABBITMQ_PASSWORD')
RABBITMQ_VHOST = os.getenv('RABBITMQ_VHOST', 'celery_vhost')

# Build broker URL
broker_url = f'amqp://{RABBITMQ_USER}:{RABBITMQ_PASSWORD}@{RABBITMQ_HOST}:{RABBITMQ_PORT}/{RABBITMQ_VHOST}'

# Initialize Celery
app = Celery('myapp', broker=broker_url)

# CRITICAL: Enable publisher confirms for quorum queues
app.conf.broker_transport_options = {
    'confirm_publish': True,  # Required for quorum queues
    'max_retries': 3,
    'interval_start': 0,
    'interval_step': 0.2,
    'interval_max': 0.5,
}

# Define exchanges
default_exchange = Exchange('celery', type='direct', durable=True)
priority_exchange = Exchange('priority', type='direct', durable=True)

# Queue configuration with quorum queues
app.conf.task_queues = (
    # Default queue with quorum type
    Queue(
        'celery',
        exchange=default_exchange,
        routing_key='celery',
        queue_arguments={
            'x-queue-type': 'quorum',  # Enable quorum queue
            'x-delivery-limit': 3,  # Max redelivery attempts
            'x-max-in-memory-length': 10000,  # In-memory message limit
        }
    ),
    # High priority queue
    Queue(
        'high_priority',
        exchange=priority_exchange,
        routing_key='high',
        queue_arguments={
            'x-queue-type': 'quorum',
            'x-delivery-limit': 5,
            'x-max-priority': 10,  # Enable message priority
        }
    ),
    # Low priority queue
    Queue(
        'low_priority',
        exchange=default_exchange,
        routing_key='low',
        queue_arguments={
            'x-queue-type': 'quorum',
            'x-delivery-limit': 2,
        }
    ),
)

# Celery configuration for HA
app.conf.update(
    # Task routing
    task_default_queue='celery',
    task_default_exchange='celery',
    task_default_routing_key='celery',

    # Serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',

    # Result backend (use Redis or database, not RabbitMQ)
    result_backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0'),
    result_expires=3600,

    # Worker settings
    worker_prefetch_multiplier=4,
    worker_max_tasks_per_child=1000,

    # Task execution (critical for HA)
    task_acks_late=True,  # Acknowledge after completion
    task_reject_on_worker_lost=True,  # Requeue on worker crash

    # Time limits
    task_time_limit=3600,
    task_soft_time_limit=3000,

    # Monitoring
    worker_send_task_events=True,
    task_send_sent_event=True,

    # Timezone
    timezone='UTC',
    enable_utc=True,
)

# Task routing
app.conf.task_routes = {
    'myapp.tasks.critical_*': {
        'queue': 'high_priority',
        'routing_key': 'high',
    },
    'myapp.tasks.background_*': {
        'queue': 'low_priority',
        'routing_key': 'low',
    },
}

if __name__ == '__main__':
    # Test connection
    try:
        with app.connection() as conn:
            conn.ensure_connection(max_retries=3)
            print("✅ Connected to RabbitMQ cluster")

            # Verify quorum queues
            from kombu.admin import QueueAdmin
            admin = QueueAdmin(conn)
            print("✅ Quorum queues configured")
    except Exception as e:
        print(f"❌ Connection failed: {e}")
```

## Testing High Availability

### 1. Start Cluster

```bash
# Start cluster with HAProxy
docker-compose -f docker-compose.rabbitmq-cluster.yml up -d

# Wait for cluster to form
sleep 10

# Check cluster status
docker exec rabbitmq-1 rabbitmqctl cluster_status
```

### 2. Verify Quorum Queue

```bash
# List queues
docker exec rabbitmq-1 rabbitmqctl list_queues name type

# Check queue details
docker exec rabbitmq-1 rabbitmqctl list_queues name type arguments

# Expected output: x-queue-type: quorum
```

### 3. Test Node Failure

**Scenario: Stop one node, verify tasks continue**

```python
# test_ha.py
from celery import Celery
import time

app = Celery(broker='amqp://celery:password@localhost:5670/celery_vhost')

@app.task
def test_task(n):
    return f"Task {n} completed"

# Send tasks
for i in range(100):
    test_task.delay(i)
    print(f"Sent task {i}")
    time.sleep(0.1)
```

**Kill node during execution:**
```bash
# While tasks are running
docker stop rabbitmq-2

# Watch logs
docker logs -f rabbitmq-1

# Verify tasks continue (may see brief delay)
# Check HAProxy stats: http://localhost:8404
```

### 4. Monitor Queue Replication

```bash
# Check queue leader
docker exec rabbitmq-1 rabbitmqctl list_queues name pid slave_pids

# Check queue members
docker exec rabbitmq-1 rabbitmqctl list_queues name members

# Expected: 3 members (one per node)
```

## Production Best Practices

### 1. Cluster Sizing

- **Minimum**: 3 nodes (for quorum)
- **Recommended**: 5 or 7 nodes (better fault tolerance)
- **Avoid**: Even numbers (no clear majority)

### 2. Quorum Queue Settings

```python
# Conservative settings for critical tasks
queue_arguments = {
    'x-queue-type': 'quorum',
    'x-delivery-limit': 5,  # Higher for retries
    'x-max-in-memory-length': 5000,  # Lower for memory safety
    'x-quorum-initial-group-size': 3,  # Number of replicas
}
```

### 3. Network Configuration

- **Latency**: Keep cluster nodes in same datacenter (< 10ms latency)
- **Bandwidth**: Ensure sufficient bandwidth for replication
- **Partitions**: Use network partition handling mode `pause_minority`

### 4. Monitoring

**Key metrics:**
- Queue length (per queue)
- Consumer count
- Message rate (in/out)
- Node memory usage
- Disk space
- Cluster status

**Monitoring script:**
```bash
#!/bin/bash
# monitor-cluster.sh

docker exec rabbitmq-1 rabbitmqctl cluster_status
docker exec rabbitmq-1 rabbitmqctl list_queues name messages consumers
docker exec rabbitmq-1 rabbitmqctl list_channels
```

## Troubleshooting

### Cluster won't form

- Verify Erlang cookie matches on all nodes
- Check network connectivity between nodes
- Ensure hostnames resolve correctly
- Check firewall rules (ports 4369, 25672)

### Quorum queue leader election fails

- Verify at least 3 nodes are running
- Check cluster status for network partitions
- Restart affected nodes in sequence

### High memory usage

- Reduce `x-max-in-memory-length`
- Increase message consumer count
- Scale workers horizontally
- Monitor queue depths

### Slow message delivery

- Check network latency between nodes
- Verify disk I/O performance
- Reduce replication factor for non-critical queues
- Use classic queues for high-throughput non-critical tasks

## References

- Quorum Queues: https://www.rabbitmq.com/quorum-queues.html
- Clustering Guide: https://www.rabbitmq.com/clustering.html
- HA Guide: https://www.rabbitmq.com/ha.html
- Celery RabbitMQ: https://docs.celeryq.dev/en/stable/getting-started/backends-and-brokers/rabbitmq.html

## Security Notes

- Use strong passwords for all accounts
- Enable SSL/TLS for production
- Configure firewall rules (allow only necessary ports)
- Use separate vhosts for different applications
- Rotate Erlang cookie periodically
- Monitor authentication failures
- Use management UI only on internal network
