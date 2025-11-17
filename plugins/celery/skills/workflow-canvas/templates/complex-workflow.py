"""
Complex Celery Workflow Patterns
Production-ready multi-stage pipeline architectures
"""

from celery import Celery, chain, group, chord
from typing import List, Dict, Any, Optional
import time

app = Celery('complex_workflows')
app.config_from_object({
    'broker_url': 'redis://localhost:6379/0',
    'result_backend': 'redis://localhost:6379/0',
    'task_serializer': 'json',
    'result_serializer': 'json',
    'accept_content': ['json'],
    'result_expires': 3600,
    'task_track_started': True,
    'worker_prefetch_multiplier': 1,
    'task_acks_late': True,
})


# ============================================================================
# ETL Pipeline Pattern
# ============================================================================

@app.task
def extract_from_source(source_config: dict) -> List[dict]:
    """Extract data from source"""
    return [
        {'source': source_config['name'], 'id': i, 'data': f"record_{i}"}
        for i in range(source_config.get('limit', 10))
    ]


@app.task(ignore_result=False)
def transform_record(record: dict) -> dict:
    """Transform single record"""
    record['transformed'] = True
    record['timestamp'] = time.time()
    return record


@app.task(ignore_result=False)
def validate_record(record: dict) -> dict:
    """Validate transformed record"""
    record['valid'] = len(record.get('data', '')) > 0
    return record


@app.task
def load_batch(records: List[dict]) -> dict:
    """Load batch to destination"""
    valid_records = [r for r in records if r.get('valid')]
    return {
        'loaded': len(valid_records),
        'total': len(records),
        'success_rate': len(valid_records) / len(records) * 100 if records else 0
    }


@app.task
def notify_completion(result: dict) -> dict:
    """Send completion notification"""
    result['notification_sent'] = True
    return result


def etl_pipeline_workflow(sources: List[dict]):
    """Complete ETL pipeline with parallel processing"""
    workflow = chain(
        # Stage 1: Extract from all sources in parallel
        group(extract_from_source.s(source) for source in sources),

        # Stage 2: Flatten and transform records
        # (This would use a custom task to flatten in production)

        # Stage 3: Transform and validate in parallel, then load
        chord([
            chain(
                transform_record.s(record),
                validate_record.s()
            )
            for source_records in [extract_from_source.s(s).apply_async().get() for s in sources]
            for record in source_records
        ])(load_batch.s()),

        # Stage 4: Send notification
        notify_completion.s()
    )

    return workflow.apply_async()


# ============================================================================
# Multi-Stage Processing Pipeline
# ============================================================================

@app.task
def fetch_work_items() -> List[dict]:
    """Fetch items to process"""
    return [{'id': i, 'priority': i % 3} for i in range(20)]


@app.task(ignore_result=False)
def stage_1_processing(item: dict) -> dict:
    """First processing stage"""
    item['stage1_complete'] = True
    return item


@app.task(ignore_result=False)
def stage_2_processing(item: dict) -> dict:
    """Second processing stage"""
    item['stage2_complete'] = True
    return item


@app.task(ignore_result=False)
def stage_3_processing(item: dict) -> dict:
    """Third processing stage"""
    item['stage3_complete'] = True
    return item


@app.task
def aggregate_stage(results: List[dict]) -> dict:
    """Aggregate stage results"""
    return {
        'processed_count': len(results),
        'all_complete': all(r.get('stage3_complete') for r in results)
    }


def multi_stage_pipeline():
    """Pipeline with sequential stages and parallel processing within each"""
    workflow = chain(
        # Fetch work items
        fetch_work_items.s(),

        # Stage 1: Parallel processing
        chord(
            group(stage_1_processing.s(item) for item in fetch_work_items.s().apply_async().get())
        )(lambda x: x),  # Pass through results

        # Stage 2: Parallel processing
        chord(
            group(stage_2_processing.s(item) for item in x)
        )(lambda x: x),

        # Stage 3: Parallel processing with aggregation
        chord(
            group(stage_3_processing.s(item) for item in x)
        )(aggregate_stage.s())
    )

    return workflow.apply_async()


# ============================================================================
# Fan-Out / Fan-In Pattern
# ============================================================================

@app.task
def split_job(job_spec: dict) -> List[dict]:
    """Split job into parallel tasks"""
    num_chunks = job_spec.get('num_chunks', 4)
    total_items = job_spec.get('total_items', 100)
    chunk_size = total_items // num_chunks

    return [
        {
            'chunk_id': i,
            'start': i * chunk_size,
            'end': (i + 1) * chunk_size if i < num_chunks - 1 else total_items
        }
        for i in range(num_chunks)
    ]


@app.task(ignore_result=False)
def process_chunk(chunk: dict) -> dict:
    """Process single chunk"""
    items_processed = chunk['end'] - chunk['start']
    return {
        'chunk_id': chunk['chunk_id'],
        'items_processed': items_processed,
        'start': chunk['start'],
        'end': chunk['end']
    }


@app.task
def merge_results(chunks: List[dict]) -> dict:
    """Merge chunk results"""
    return {
        'total_chunks': len(chunks),
        'total_items': sum(c['items_processed'] for c in chunks),
        'chunks': sorted(chunks, key=lambda x: x['chunk_id'])
    }


def fan_out_fan_in_workflow(job_spec: dict):
    """Fan-out for parallel processing, fan-in for aggregation"""
    workflow = chain(
        # Split job
        split_job.s(job_spec),

        # Fan-out: Process chunks in parallel
        # Fan-in: Merge results
        chord(
            group(process_chunk.s(chunk) for chunk in split_job.s(job_spec).apply_async().get())
        )(merge_results.s())
    )

    return workflow.apply_async()


# ============================================================================
# Priority-Based Processing Pipeline
# ============================================================================

@app.task(ignore_result=False)
def classify_priority(item: dict) -> dict:
    """Classify item priority"""
    value = item.get('value', 0)
    if value > 80:
        item['priority'] = 'critical'
    elif value > 50:
        item['priority'] = 'high'
    elif value > 20:
        item['priority'] = 'medium'
    else:
        item['priority'] = 'low'
    return item


@app.task(ignore_result=False)
def process_by_priority(item: dict) -> dict:
    """Process item based on priority"""
    priority = item.get('priority', 'low')
    processing_time = {
        'critical': 0.1,
        'high': 0.5,
        'medium': 1.0,
        'low': 2.0
    }
    time.sleep(processing_time.get(priority, 1.0))
    item['processed'] = True
    return item


@app.task
def aggregate_by_priority(results: List[dict]) -> dict:
    """Aggregate results by priority"""
    by_priority = {}
    for item in results:
        priority = item.get('priority', 'unknown')
        by_priority.setdefault(priority, []).append(item)

    return {
        priority: {
            'count': len(items),
            'items': [i.get('id') for i in items]
        }
        for priority, items in by_priority.items()
    }


def priority_pipeline_workflow(items: List[dict]):
    """Process items with priority-based execution"""
    workflow = chord(
        chain(
            classify_priority.s(item),
            process_by_priority.s()
        ).set(
            priority=9 if item.get('value', 0) > 80 else
                    7 if item.get('value', 0) > 50 else
                    4 if item.get('value', 0) > 20 else 1
        )
        for item in items
    )(aggregate_by_priority.s())

    return workflow.apply_async()


# ============================================================================
# Retry and Fallback Pattern
# ============================================================================

@app.task(
    autoretry_for=(Exception,),
    retry_kwargs={'max_retries': 3, 'countdown': 5},
    retry_backoff=True
)
def primary_processing(item: dict) -> dict:
    """Primary processing with retries"""
    # Simulate occasional failures
    if item.get('id', 0) % 7 == 0:
        raise ValueError("Simulated processing error")
    item['processed_by'] = 'primary'
    return item


@app.task
def fallback_processing(item: dict) -> dict:
    """Fallback processing if primary fails"""
    item['processed_by'] = 'fallback'
    return item


@app.task(bind=True, ignore_result=False)
def process_with_fallback(self, item: dict) -> dict:
    """Process with automatic fallback"""
    try:
        return primary_processing.s(item).apply_async().get(timeout=10)
    except Exception as exc:
        self.update_state(state='FALLBACK', meta={'reason': str(exc)})
        return fallback_processing.s(item).apply_async().get()


@app.task
def aggregate_processing_methods(results: List[dict]) -> dict:
    """Aggregate by processing method"""
    primary_count = sum(1 for r in results if r.get('processed_by') == 'primary')
    fallback_count = sum(1 for r in results if r.get('processed_by') == 'fallback')

    return {
        'total': len(results),
        'primary': primary_count,
        'fallback': fallback_count,
        'fallback_rate': fallback_count / len(results) * 100 if results else 0
    }


def retry_fallback_workflow(items: List[dict]):
    """Process with retry and fallback logic"""
    workflow = chord(
        process_with_fallback.s(item) for item in items
    )(aggregate_processing_methods.s())

    return workflow.apply_async()


# ============================================================================
# Conditional Branching Pipeline
# ============================================================================

@app.task
def route_item(item: dict) -> str:
    """Determine processing route"""
    if item.get('type') == 'A':
        return 'route_a'
    elif item.get('type') == 'B':
        return 'route_b'
    else:
        return 'route_default'


@app.task(ignore_result=False)
def process_route_a(item: dict) -> dict:
    """Processing for route A"""
    item['route'] = 'A'
    item['result'] = item.get('value', 0) * 2
    return item


@app.task(ignore_result=False)
def process_route_b(item: dict) -> dict:
    """Processing for route B"""
    item['route'] = 'B'
    item['result'] = item.get('value', 0) * 3
    return item


@app.task(ignore_result=False)
def process_route_default(item: dict) -> dict:
    """Default processing route"""
    item['route'] = 'default'
    item['result'] = item.get('value', 0)
    return item


@app.task(bind=True)
def conditional_processor(self, item: dict) -> dict:
    """Process item based on routing logic"""
    route = route_item(item)

    if route == 'route_a':
        return process_route_a.s(item).apply_async().get()
    elif route == 'route_b':
        return process_route_b.s(item).apply_async().get()
    else:
        return process_route_default.s(item).apply_async().get()


def conditional_workflow(items: List[dict]):
    """Workflow with conditional branching"""
    workflow = chord(
        conditional_processor.s(item) for item in items
    )(aggregate_by_priority.s())  # Reuse aggregation

    return workflow.apply_async()


# ============================================================================
# Usage Examples
# ============================================================================

if __name__ == '__main__':
    # ETL Pipeline
    print("ETL Pipeline:")
    sources = [
        {'name': 'source_1', 'limit': 5},
        {'name': 'source_2', 'limit': 5},
    ]
    result = etl_pipeline_workflow(sources)
    print(f"ETL Result: {result.get(timeout=60)}")

    # Fan-out / Fan-in
    print("\nFan-out / Fan-in:")
    job = {'num_chunks': 4, 'total_items': 100}
    result = fan_out_fan_in_workflow(job)
    print(f"Result: {result.get(timeout=60)}")

    # Priority Processing
    print("\nPriority Processing:")
    items = [{'id': i, 'value': i * 10} for i in range(10)]
    result = priority_pipeline_workflow(items)
    print(f"Priority Result: {result.get(timeout=60)}")

    # Retry with Fallback
    print("\nRetry with Fallback:")
    items = [{'id': i, 'data': f"item_{i}"} for i in range(20)]
    result = retry_fallback_workflow(items)
    print(f"Fallback Result: {result.get(timeout=60)}")
