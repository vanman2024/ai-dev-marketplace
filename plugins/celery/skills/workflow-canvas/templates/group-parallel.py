"""
Celery Group Patterns
Parallel task execution with result tracking
"""

from celery import Celery, group
from typing import List, Dict, Any
import time

app = Celery('group_workflows')
app.config_from_object({
    'broker_url': 'redis://localhost:6379/0',
    'result_backend': 'redis://localhost:6379/0',
    'task_serializer': 'json',
    'result_serializer': 'json',
    'accept_content': ['json'],
    'result_expires': 3600,
})


# ============================================================================
# Basic Group Pattern
# ============================================================================

@app.task
def process_item(item: dict) -> dict:
    """Process single item"""
    item['processed'] = True
    item['timestamp'] = time.time()
    return item


def basic_group_example():
    """Process multiple items in parallel"""
    items = [
        {'id': 1, 'name': 'item1'},
        {'id': 2, 'name': 'item2'},
        {'id': 3, 'name': 'item3'},
    ]

    # Create group of tasks
    job = group(process_item.s(item) for item in items)

    # Execute and wait for results
    result = job.apply_async()
    return result.get(timeout=30)


# ============================================================================
# Dynamic Group Creation
# ============================================================================

@app.task
def fetch_batch(batch_id: int) -> List[dict]:
    """Fetch batch of items"""
    return [
        {'batch': batch_id, 'item': i}
        for i in range(10)
    ]


@app.task
def process_batch(batch: List[dict]) -> dict:
    """Process entire batch"""
    return {
        'batch_size': len(batch),
        'items_processed': len(batch)
    }


def dynamic_group_example(num_batches: int = 5):
    """Create group with dynamic task count"""
    # Generate batch IDs
    batch_ids = range(num_batches)

    # Create parallel batch processing
    job = group(
        process_batch.s(fetch_batch.si(batch_id).apply_async().get())
        for batch_id in batch_ids
    )

    result = job.apply_async()
    return result.get(timeout=60)


# ============================================================================
# Group with Result Aggregation
# ============================================================================

@app.task
def compute_metric(data: dict) -> float:
    """Compute metric for dataset"""
    return data.get('value', 0) * 1.5


@app.task
def aggregate_metrics(results: List[float]) -> dict:
    """Aggregate results from parallel computations"""
    return {
        'total': sum(results),
        'average': sum(results) / len(results) if results else 0,
        'count': len(results),
        'max': max(results) if results else 0,
        'min': min(results) if results else 0,
    }


def group_aggregation_example():
    """Parallel computation with manual aggregation"""
    datasets = [
        {'id': i, 'value': i * 10}
        for i in range(1, 11)
    ]

    # Execute parallel computations
    job = group(compute_metric.s(data) for data in datasets)
    result = job.apply_async()

    # Wait for all results
    metrics = result.get(timeout=30)

    # Aggregate manually
    return aggregate_metrics.s(metrics).apply_async().get()


# ============================================================================
# Nested Groups Pattern
# ============================================================================

@app.task
def process_category(category: str, items: List[dict]) -> dict:
    """Process items in category"""
    return {
        'category': category,
        'processed_count': len(items)
    }


def nested_groups_example():
    """Group of groups for hierarchical processing"""
    categories = {
        'electronics': [{'id': 1}, {'id': 2}],
        'clothing': [{'id': 3}, {'id': 4}],
        'books': [{'id': 5}, {'id': 6}],
    }

    # Create group of category processing tasks
    category_jobs = [
        group([
            process_item.s(item)
            for item in items
        ])
        for category, items in categories.items()
    ]

    # Execute all category groups
    main_job = group(category_jobs)
    result = main_job.apply_async()

    return result.get(timeout=60)


# ============================================================================
# Error Handling in Groups
# ============================================================================

@app.task
def risky_processing(item: dict) -> dict:
    """Task that might fail"""
    if item.get('fail'):
        raise ValueError(f"Failed processing item {item.get('id')}")
    return {'id': item.get('id'), 'status': 'success'}


@app.task(bind=True)
def safe_processing(self, item: dict) -> dict:
    """Task with error handling"""
    try:
        if item.get('fail'):
            raise ValueError(f"Failed processing item {item.get('id')}")
        return {'id': item.get('id'), 'status': 'success'}
    except Exception as exc:
        # Return error info instead of failing
        return {
            'id': item.get('id'),
            'status': 'error',
            'error': str(exc)
        }


def group_error_handling_example():
    """Handle errors in parallel processing"""
    items = [
        {'id': 1, 'fail': False},
        {'id': 2, 'fail': True},
        {'id': 3, 'fail': False},
        {'id': 4, 'fail': True},
    ]

    # Use safe processing to capture errors
    job = group(safe_processing.s(item) for item in items)
    result = job.apply_async()

    # All tasks complete, including failed ones
    results = result.get(timeout=30)

    # Separate successes and failures
    successes = [r for r in results if r['status'] == 'success']
    failures = [r for r in results if r['status'] == 'error']

    return {
        'successes': successes,
        'failures': failures,
        'total': len(results)
    }


# ============================================================================
# Rate-Limited Group Processing
# ============================================================================

@app.task(rate_limit='10/m')
def rate_limited_api_call(endpoint: str) -> dict:
    """API call with rate limiting"""
    return {'endpoint': endpoint, 'status': 'completed'}


def rate_limited_group_example():
    """Process group with rate limiting"""
    endpoints = [f'/api/endpoint_{i}' for i in range(50)]

    # Tasks execute with rate limit
    job = group(rate_limited_api_call.s(ep) for ep in endpoints)
    result = job.apply_async()

    # This will take time due to rate limiting
    return result.get(timeout=300)


# ============================================================================
# Group with Priority Tasks
# ============================================================================

@app.task
def high_priority_task(item: dict) -> dict:
    """High priority processing"""
    return {'id': item['id'], 'priority': 'high', 'processed': True}


@app.task
def low_priority_task(item: dict) -> dict:
    """Low priority processing"""
    return {'id': item['id'], 'priority': 'low', 'processed': True}


def priority_group_example():
    """Group with different priority levels"""
    high_priority_items = [{'id': i} for i in range(1, 6)]
    low_priority_items = [{'id': i} for i in range(6, 21)]

    # Create separate groups with priorities
    high_priority_group = group(
        high_priority_task.s(item).set(priority=9)
        for item in high_priority_items
    )

    low_priority_group = group(
        low_priority_task.s(item).set(priority=1)
        for item in low_priority_items
    )

    # Execute both groups
    high_result = high_priority_group.apply_async()
    low_result = low_priority_group.apply_async()

    return {
        'high_priority': high_result.get(timeout=30),
        'low_priority': low_result.get(timeout=30)
    }


# ============================================================================
# Monitoring Group Progress
# ============================================================================

def monitor_group_progress():
    """Monitor group execution progress"""
    items = [{'id': i} for i in range(20)]

    job = group(process_item.s(item) for item in items)
    result = job.apply_async()

    # Monitor progress
    while not result.ready():
        completed = result.completed_count()
        total = len(items)
        print(f"Progress: {completed}/{total} ({completed/total*100:.1f}%)")
        time.sleep(1)

    # Get final results
    return result.get()


# ============================================================================
# Usage Examples
# ============================================================================

if __name__ == '__main__':
    # Basic parallel processing
    print("Basic group:")
    result = basic_group_example()
    print(f"Processed {len(result)} items")

    # Group with aggregation
    print("\nGroup with aggregation:")
    result = group_aggregation_example()
    print(f"Metrics: {result}")

    # Error handling
    print("\nError handling:")
    result = group_error_handling_example()
    print(f"Successes: {len(result['successes'])}, Failures: {len(result['failures'])}")

    # Priority processing
    print("\nPriority processing:")
    result = priority_group_example()
    print(f"High priority: {len(result['high_priority'])}, Low priority: {len(result['low_priority'])}")
