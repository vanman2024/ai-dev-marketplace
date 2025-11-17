# Worker Queue Assignment Strategy Guide

This guide demonstrates how to design and implement worker pool strategies that match task characteristics to appropriate worker resources.

## Overview

Different tasks have different resource requirements:
- **CPU-bound**: Compute-intensive (ML training, video processing, data analysis)
- **I/O-bound**: Network/disk-intensive (API calls, file operations, emails)
- **Memory-bound**: Large dataset processing (aggregations, bulk imports)
- **Mixed**: Combination of resource types

Proper worker assignment ensures optimal resource utilization and performance.

## Worker Pool Architecture

### CPU-Intensive Worker Pool

**Characteristics:**
- Low concurrency (matches CPU core count)
- Low prefetch (prevents task hoarding)
- Frequent restarts (prevents memory leaks)
- Long timeouts (tasks take time to complete)

**Configuration:**

```python
# celery_config.py
WORKER_POOLS = {
    'cpu_workers': {
        'queues': ['cpu_ml_training', 'cpu_video_processing', 'cpu_data_analysis'],
        'concurrency': 4,  # Number of CPU cores
        'prefetch_multiplier': 1,  # Fetch one task at a time
        'max_tasks_per_child': 100,  # Restart after 100 tasks
        'time_limit': 3600,  # 1 hour hard limit
        'soft_time_limit': 3000,  # 50 minutes soft limit
    }
}
```

**Queue Definitions:**

```python
from kombu import Exchange, Queue

CPU_EXCHANGE = Exchange('cpu_tasks', type='direct', durable=True)

CELERY_QUEUES = (
    Queue('cpu_ml_training', exchange=CPU_EXCHANGE, routing_key='cpu.ml',
          queue_arguments={'x-max-length': 100}),
    Queue('cpu_video_processing', exchange=CPU_EXCHANGE, routing_key='cpu.video',
          queue_arguments={'x-max-length': 50}),
    Queue('cpu_data_analysis', exchange=CPU_EXCHANGE, routing_key='cpu.analysis',
          queue_arguments={'x-max-length': 200}),
)
```

**Start Command:**

```bash
celery -A myapp worker \
    -Q cpu_ml_training,cpu_video_processing,cpu_data_analysis \
    -c 4 \
    --prefetch-multiplier=1 \
    --max-tasks-per-child=100 \
    --time-limit=3600 \
    --soft-time-limit=3000 \
    -n cpu_worker@%h
```

**Example Tasks:**

```python
@app.task(bind=True, queue='cpu_ml_training')
def train_model(self, model_id, dataset_path):
    """CPU-intensive ML training"""
    # Model training logic
    pass

@app.task(bind=True, queue='cpu_video_processing')
def process_video(self, video_id):
    """CPU-intensive video encoding"""
    # Video processing logic
    pass

@app.task(bind=True, queue='cpu_data_analysis')
def analyze_dataset(self, dataset_id):
    """CPU-intensive data analysis"""
    # Data analysis logic
    pass
```

### I/O-Intensive Worker Pool

**Characteristics:**
- High concurrency (many concurrent I/O operations)
- High prefetch (keeps workers busy during I/O waits)
- Standard restarts
- Shorter timeouts (I/O operations are faster)

**Configuration:**

```python
WORKER_POOLS = {
    'io_workers': {
        'queues': ['io_api_calls', 'io_file_operations', 'io_email_sending'],
        'concurrency': 50,  # High for concurrent I/O
        'prefetch_multiplier': 10,  # Fetch multiple tasks
        'max_tasks_per_child': 1000,
        'time_limit': 300,  # 5 minutes hard limit
        'soft_time_limit': 240,  # 4 minutes soft limit
    }
}
```

**Queue Definitions:**

```python
IO_EXCHANGE = Exchange('io_tasks', type='direct', durable=True)

CELERY_QUEUES = (
    Queue('io_api_calls', exchange=IO_EXCHANGE, routing_key='io.api',
          queue_arguments={'x-max-length': 10000}),
    Queue('io_file_operations', exchange=IO_EXCHANGE, routing_key='io.file',
          queue_arguments={'x-max-length': 5000}),
    Queue('io_email_sending', exchange=IO_EXCHANGE, routing_key='io.email',
          queue_arguments={'x-max-length': 10000}),
)
```

**Start Command:**

```bash
celery -A myapp worker \
    -Q io_api_calls,io_file_operations,io_email_sending \
    -c 50 \
    --prefetch-multiplier=10 \
    --max-tasks-per-child=1000 \
    --time-limit=300 \
    --soft-time-limit=240 \
    -n io_worker@%h
```

**Example Tasks:**

```python
@app.task(bind=True, queue='io_api_calls')
def call_external_api(self, endpoint, payload):
    """I/O-intensive API call"""
    response = requests.post(endpoint, json=payload, timeout=30)
    return response.json()

@app.task(bind=True, queue='io_file_operations')
def upload_file(self, file_path, destination):
    """I/O-intensive file upload"""
    # Upload file logic
    pass

@app.task(bind=True, queue='io_email_sending')
def send_email(self, recipient, subject, body):
    """I/O-intensive email sending"""
    # Email sending logic
    pass
```

### Memory-Intensive Worker Pool

**Characteristics:**
- Very low concurrency (limited by available RAM)
- Low prefetch
- Frequent restarts (free memory)
- Long timeouts (large datasets take time)

**Configuration:**

```python
WORKER_POOLS = {
    'memory_workers': {
        'queues': ['memory_aggregations', 'memory_large_imports'],
        'concurrency': 2,  # Very low for memory-heavy tasks
        'prefetch_multiplier': 1,
        'max_tasks_per_child': 50,  # Restart frequently
        'time_limit': 7200,  # 2 hours hard limit
        'soft_time_limit': 6600,  # 1h 50m soft limit
    }
}
```

**Queue Definitions:**

```python
MEMORY_EXCHANGE = Exchange('memory_tasks', type='direct', durable=True)

CELERY_QUEUES = (
    Queue('memory_aggregations', exchange=MEMORY_EXCHANGE, routing_key='memory.aggregate',
          queue_arguments={'x-max-length': 100}),
    Queue('memory_large_imports', exchange=MEMORY_EXCHANGE, routing_key='memory.import',
          queue_arguments={'x-max-length': 50}),
)
```

**Start Command:**

```bash
celery -A myapp worker \
    -Q memory_aggregations,memory_large_imports \
    -c 2 \
    --prefetch-multiplier=1 \
    --max-tasks-per-child=50 \
    --time-limit=7200 \
    --soft-time-limit=6600 \
    -n memory_worker@%h
```

**Example Tasks:**

```python
@app.task(bind=True, queue='memory_aggregations')
def aggregate_user_data(self, date_range):
    """Memory-intensive data aggregation"""
    # Load large dataset into memory
    # Perform aggregations
    pass

@app.task(bind=True, queue='memory_large_imports')
def import_large_csv(self, file_path):
    """Memory-intensive bulk import"""
    # Load entire CSV into memory
    # Process and insert
    pass
```

### General Purpose Worker Pool

**Characteristics:**
- Moderate concurrency
- Standard settings
- Handles miscellaneous tasks

**Configuration:**

```python
WORKER_POOLS = {
    'general_workers': {
        'queues': ['general_background', 'general_scheduled'],
        'concurrency': 10,
        'prefetch_multiplier': 4,
        'max_tasks_per_child': 500,
        'time_limit': 600,  # 10 minutes
        'soft_time_limit': 540,  # 9 minutes
    }
}
```

## Dynamic Worker Assignment

Route tasks to appropriate workers based on characteristics:

```python
# routing.py
def route_by_resource_type(name, args, kwargs, options, task=None, **kw):
    """
    Route tasks to worker pools based on resource requirements
    """
    name_lower = name.lower()

    # CPU-intensive patterns
    cpu_patterns = ['train', 'model', 'process', 'analyze', 'compute', 'encode']
    if any(pattern in name_lower for pattern in cpu_patterns):
        if 'ml' in name_lower or 'model' in name_lower:
            return {'queue': 'cpu_ml_training', 'routing_key': 'cpu.ml'}
        elif 'video' in name_lower or 'image' in name_lower:
            return {'queue': 'cpu_video_processing', 'routing_key': 'cpu.video'}
        else:
            return {'queue': 'cpu_data_analysis', 'routing_key': 'cpu.analysis'}

    # I/O-intensive patterns
    io_patterns = ['api', 'fetch', 'download', 'upload', 'request', 'email', 'scrape']
    if any(pattern in name_lower for pattern in io_patterns):
        if 'api' in name_lower or 'fetch' in name_lower:
            return {'queue': 'io_api_calls', 'routing_key': 'io.api'}
        elif 'file' in name_lower or 'upload' in name_lower:
            return {'queue': 'io_file_operations', 'routing_key': 'io.file'}
        elif 'email' in name_lower:
            return {'queue': 'io_email_sending', 'routing_key': 'io.email'}

    # Memory-intensive patterns
    memory_patterns = ['aggregate', 'join', 'merge', 'import', 'bulk']
    if any(pattern in name_lower for pattern in memory_patterns):
        if 'aggregate' in name_lower:
            return {'queue': 'memory_aggregations', 'routing_key': 'memory.aggregate'}
        else:
            return {'queue': 'memory_large_imports', 'routing_key': 'memory.import'}

    # Check for explicit resource hint in kwargs
    if 'resource_type' in kwargs:
        resource_map = {
            'cpu': {'queue': 'cpu_data_analysis', 'routing_key': 'cpu.analysis'},
            'io': {'queue': 'io_api_calls', 'routing_key': 'io.api'},
            'memory': {'queue': 'memory_aggregations', 'routing_key': 'memory.aggregate'},
        }
        return resource_map.get(kwargs['resource_type'], {'queue': 'general_background'})

    # Default to general workers
    return {'queue': 'general_background', 'routing_key': 'general.background'}

# Apply routing
app.conf.task_routes = (route_by_resource_type,)
```

## Autoscaling Workers

Automatically scale workers based on load:

```bash
# CPU workers: 2-8 workers
celery -A myapp worker \
    -Q cpu_ml_training,cpu_video_processing,cpu_data_analysis \
    --autoscale=8,2 \
    -n cpu_worker@%h

# I/O workers: 20-100 workers
celery -A myapp worker \
    -Q io_api_calls,io_file_operations,io_email_sending \
    --autoscale=100,20 \
    -n io_worker@%h

# Memory workers: 1-4 workers
celery -A myapp worker \
    -Q memory_aggregations,memory_large_imports \
    --autoscale=4,1 \
    -n memory_worker@%h
```

**Autoscaling Configuration:**

```python
# Configure autoscaler behavior
app.conf.update(
    worker_autoscaler='celery.worker.autoscale:Autoscaler',
    worker_autoscale_max=100,  # Global max
    worker_autoscale_min=10,   # Global min
    worker_max_tasks_per_child=1000,
)
```

## Multi-Server Deployment

### Scenario: 3 Servers with Different Specs

**Server 1: High CPU (16 cores, 32GB RAM)**
```bash
# CPU-intensive workers
celery -A myapp worker \
    -Q cpu_ml_training,cpu_video_processing,cpu_data_analysis \
    -c 12 \
    --prefetch-multiplier=1 \
    -n cpu_worker1@%h
```

**Server 2: High Memory (8 cores, 128GB RAM)**
```bash
# Memory-intensive workers
celery -A myapp worker \
    -Q memory_aggregations,memory_large_imports \
    -c 4 \
    --prefetch-multiplier=1 \
    -n memory_worker1@%h
```

**Server 3: Balanced (8 cores, 64GB RAM)**
```bash
# I/O workers
celery -A myapp worker \
    -Q io_api_calls,io_file_operations,io_email_sending \
    -c 50 \
    --prefetch-multiplier=10 \
    -n io_worker1@%h

# General workers
celery -A myapp worker \
    -Q general_background,general_scheduled \
    -c 10 \
    --prefetch-multiplier=4 \
    -n general_worker1@%h
```

## Monitoring Worker Performance

### Check Active Workers

```bash
# List all active workers
celery -A myapp inspect active

# List workers by hostname
celery -A myapp inspect active_queues

# Check worker stats
celery -A myapp inspect stats
```

### Monitor Queue Lengths

```bash
# RabbitMQ
sudo rabbitmqctl list_queues name messages

# Redis
redis-cli LLEN cpu_ml_training
redis-cli LLEN io_api_calls
redis-cli LLEN memory_aggregations
```

### Flower Dashboard

```bash
# Start Flower
celery -A myapp flower --port=5555

# View at http://localhost:5555
# Shows:
# - Active workers by pool
# - Queue lengths
# - Task completion rates
# - Worker resource usage
```

## Best Practices

1. **Match Concurrency to Resources**: CPU workers = cores, I/O workers = many
2. **Set Appropriate Timeouts**: Longer for CPU/memory, shorter for I/O
3. **Use Prefetch Wisely**: Low for CPU/memory (1), high for I/O (10+)
4. **Restart Workers Regularly**: Prevents memory leaks and resource exhaustion
5. **Monitor Queue Lengths**: Alert on buildup indicating bottlenecks
6. **Separate Critical Paths**: Don't mix slow and fast tasks in same queue
7. **Test Under Load**: Validate worker assignments with realistic workloads
8. **Document Resource Requirements**: Make it clear what each pool handles
9. **Use Autoscaling**: Start small, scale up under load
10. **Geographic Distribution**: Consider worker placement for latency-sensitive tasks

## Common Mistakes

### Mistake 1: Same Concurrency for All Workers

```bash
# ❌ BAD: CPU worker with high concurrency
celery -A myapp worker -Q cpu_ml_training -c 50
```

**Problem**: CPU thrashing, poor performance

**Solution**: Match concurrency to CPU cores (4-16 typically)

### Mistake 2: High Prefetch for CPU Tasks

```bash
# ❌ BAD: CPU worker prefetching many tasks
celery -A myapp worker -Q cpu_ml_training --prefetch-multiplier=10
```

**Problem**: Worker hoards tasks, poor load balancing

**Solution**: Use `--prefetch-multiplier=1` for CPU/memory tasks

### Mistake 3: Mixing Task Types

```bash
# ❌ BAD: Fast I/O tasks mixed with slow CPU tasks
celery -A myapp worker -Q io_api_calls,cpu_ml_training -c 10
```

**Problem**: Fast tasks blocked behind slow ones

**Solution**: Separate queues and workers for different task types

### Mistake 4: No Time Limits

```python
# ❌ BAD: No time limit on long-running task
@app.task
def process_video(video_id):
    # Could run forever
    pass
```

**Problem**: Hung tasks block workers indefinitely

**Solution**: Always set time limits

```python
# ✅ GOOD
@app.task(time_limit=3600, soft_time_limit=3000)
def process_video(video_id):
    pass
```

## Conclusion

Proper worker queue assignment is critical for Celery performance. Match worker configurations to task characteristics, monitor performance, and adjust based on real-world usage patterns.
