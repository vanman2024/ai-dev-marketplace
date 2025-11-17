"""
Celery Chord Patterns
Parallel execution with callback synchronization
"""

from celery import Celery, chord, group
from typing import List, Dict, Any

app = Celery('chord_workflows')
app.config_from_object({
    'broker_url': 'redis://localhost:6379/0',
    'result_backend': 'redis://localhost:6379/0',
    'task_serializer': 'json',
    'result_serializer': 'json',
    'accept_content': ['json'],
    'result_expires': 3600,
    'task_track_started': True,
})


# ============================================================================
# Basic Chord Pattern
# ============================================================================

@app.task(ignore_result=False)
def add(x: int, y: int) -> int:
    """Add two numbers"""
    return x + y


@app.task
def tsum(numbers: List[int]) -> int:
    """Sum all numbers"""
    return sum(numbers)


def basic_chord_example():
    """Parallel addition with sum callback"""
    # Create chord: parallel adds → sum callback
    result = chord(
        add.s(i, i) for i in range(10)
    )(tsum.s()).get()

    return result


# ============================================================================
# Data Processing Pipeline with Chord
# ============================================================================

@app.task(ignore_result=False)
def fetch_dataset(source: str) -> List[dict]:
    """Fetch dataset from source"""
    return [
        {'source': source, 'id': i, 'value': i * 10}
        for i in range(5)
    ]


@app.task(ignore_result=False)
def process_record(record: dict) -> dict:
    """Process single record"""
    record['processed'] = True
    record['result'] = record['value'] * 2
    return record


@app.task
def aggregate_results(records: List[dict]) -> dict:
    """Aggregate processed records"""
    return {
        'total_records': len(records),
        'total_value': sum(r['result'] for r in records),
        'average': sum(r['result'] for r in records) / len(records)
    }


def data_pipeline_chord_example():
    """Data processing with chord aggregation"""
    sources = ['source_a', 'source_b', 'source_c']

    # Fetch all datasets in parallel
    datasets = [fetch_dataset.s(source).apply_async().get() for source in sources]

    # Flatten datasets
    all_records = [record for dataset in datasets for record in dataset]

    # Process all records in parallel, then aggregate
    result = chord(
        process_record.s(record) for record in all_records
    )(aggregate_results.s()).get()

    return result


# ============================================================================
# Error Handling in Chords
# ============================================================================

@app.task(ignore_result=False)
def risky_computation(value: int) -> int:
    """Computation that might fail"""
    if value == 5:
        raise ValueError(f"Cannot process value {value}")
    return value * 2


@app.task
def handle_chord_error(request, exc, traceback) -> dict:
    """Handle chord callback errors"""
    return {
        'error': True,
        'task_id': request.id,
        'exception': str(exc),
        'message': 'Chord callback failed'
    }


@app.task
def aggregate_with_error_handling(results: List[int]) -> dict:
    """Aggregate results with error handling"""
    try:
        return {
            'success': True,
            'total': sum(results),
            'count': len(results)
        }
    except Exception as exc:
        return {
            'success': False,
            'error': str(exc)
        }


def error_handling_chord_example():
    """Chord with error callback"""
    values = range(10)

    # Create chord with error handler
    workflow = chord(
        risky_computation.s(v) for v in values
    )(aggregate_with_error_handling.s())

    # Attach error callback
    workflow.on_error(handle_chord_error.s())

    try:
        result = workflow.apply_async().get(timeout=30)
        return result
    except Exception as exc:
        return {'error': str(exc)}


# ============================================================================
# Nested Chords Pattern
# ============================================================================

@app.task(ignore_result=False)
def process_batch(batch_id: int) -> List[int]:
    """Process batch and return results"""
    return [batch_id * 10 + i for i in range(5)]


@app.task
def aggregate_batch(results: List[List[int]]) -> dict:
    """Aggregate batch results"""
    flattened = [item for sublist in results for item in sublist]
    return {
        'batches_processed': len(results),
        'total_items': len(flattened),
        'sum': sum(flattened)
    }


@app.task(ignore_result=False)
def process_stage(stage_id: int, data: dict) -> dict:
    """Process single stage"""
    data['stage'] = stage_id
    data['value'] = data.get('value', 0) + stage_id * 10
    return data


@app.task
def finalize_pipeline(stage_results: List[dict]) -> dict:
    """Finalize multi-stage pipeline"""
    return {
        'stages_completed': len(stage_results),
        'final_value': sum(r['value'] for r in stage_results)
    }


def nested_chords_example():
    """Multi-stage pipeline with nested chords"""
    # Stage 1: Process batches
    stage1_chord = chord(
        process_batch.s(i) for i in range(3)
    )(aggregate_batch.s())

    # Wait for stage 1
    stage1_result = stage1_chord.apply_async().get(timeout=30)

    # Stage 2: Process stages with stage1 data
    stage2_chord = chord(
        process_stage.s(i, {'value': stage1_result['sum']})
        for i in range(5)
    )(finalize_pipeline.s())

    # Execute stage 2
    result = stage2_chord.apply_async().get(timeout=30)
    return result


# ============================================================================
# Conditional Chord Execution
# ============================================================================

@app.task(ignore_result=False)
def validate_data(item: dict) -> dict:
    """Validate data item"""
    item['valid'] = item.get('value', 0) > 0
    return item


@app.task
def process_valid_items(items: List[dict]) -> dict:
    """Process only valid items"""
    valid_items = [item for item in items if item.get('valid')]
    return {
        'valid_count': len(valid_items),
        'total_count': len(items),
        'valid_percentage': len(valid_items) / len(items) * 100 if items else 0
    }


def conditional_chord_example():
    """Chord with conditional processing"""
    items = [
        {'id': 1, 'value': 10},
        {'id': 2, 'value': -5},
        {'id': 3, 'value': 20},
        {'id': 4, 'value': 0},
    ]

    # Validate all items, then process valid ones
    result = chord(
        validate_data.s(item) for item in items
    )(process_valid_items.s()).get()

    return result


# ============================================================================
# Chord with Timeout
# ============================================================================

@app.task(ignore_result=False, time_limit=10, soft_time_limit=8)
def long_running_task(task_id: int) -> dict:
    """Long-running task with timeout"""
    import time
    time.sleep(task_id)  # Simulate work
    return {'task_id': task_id, 'completed': True}


@app.task
def aggregate_with_timeout(results: List[dict]) -> dict:
    """Aggregate results with timeout awareness"""
    completed = [r for r in results if r.get('completed')]
    return {
        'completed_count': len(completed),
        'total_count': len(results)
    }


def chord_with_timeout_example():
    """Chord with task timeouts"""
    task_ids = range(5)

    # Some tasks may timeout
    result = chord(
        long_running_task.s(tid).set(soft_time_limit=3)
        for tid in task_ids
    )(aggregate_with_timeout.s())

    try:
        return result.apply_async().get(timeout=15)
    except Exception as exc:
        return {'error': str(exc)}


# ============================================================================
# Monitoring Chord Progress
# ============================================================================

@app.task(ignore_result=False, bind=True)
def tracked_task(self, value: int) -> dict:
    """Task with progress tracking"""
    # Update state
    self.update_state(
        state='PROGRESS',
        meta={'current': value, 'status': 'processing'}
    )

    # Simulate work
    import time
    time.sleep(0.5)

    return {'value': value, 'processed': True}


@app.task
def aggregate_tracked_results(results: List[dict]) -> dict:
    """Aggregate tracked results"""
    return {
        'total_processed': len(results),
        'values': [r['value'] for r in results]
    }


def monitor_chord_progress():
    """Monitor chord execution progress"""
    values = range(10)

    # Create chord with tracked tasks
    workflow = chord(
        tracked_task.s(v) for v in values
    )(aggregate_tracked_results.s())

    result = workflow.apply_async()

    # Monitor progress
    while not result.ready():
        # Check individual task states
        for child in result.children or []:
            if hasattr(child, 'state'):
                print(f"Task {child.id}: {child.state}")

    return result.get()


# ============================================================================
# Usage Examples
# ============================================================================

if __name__ == '__main__':
    # Basic chord
    print("Basic chord:")
    result = basic_chord_example()
    print(f"Sum: {result}")

    # Data pipeline
    print("\nData pipeline:")
    result = data_pipeline_chord_example()
    print(f"Aggregation: {result}")

    # Error handling
    print("\nError handling:")
    result = error_handling_chord_example()
    print(f"Result: {result}")

    # Nested chords
    print("\nNested chords:")
    result = nested_chords_example()
    print(f"Pipeline result: {result}")

    # Conditional execution
    print("\nConditional chord:")
    result = conditional_chord_example()
    print(f"Validation result: {result}")
