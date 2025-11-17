# Chord Synchronization Examples

Real-world scenarios using Celery chords for parallel execution with callback aggregation.

## Example 1: MapReduce Pattern

**Scenario:** Process data in parallel (map), then aggregate results (reduce).

```python
from celery import chord

def map_reduce_example(dataset):
    """Classic MapReduce with chords"""
    # Map: Process each item in parallel
    # Reduce: Aggregate all results
    result = chord(
        map_function.s(item) for item in dataset
    )(reduce_function.s()).get(timeout=60)

    return result

@app.task(ignore_result=False)
def map_function(item):
    """Map: Transform individual item"""
    return {'id': item['id'], 'value': item['value'] * 2}

@app.task
def reduce_function(mapped_items):
    """Reduce: Aggregate transformed items"""
    return {
        'total': sum(item['value'] for item in mapped_items),
        'count': len(mapped_items),
        'average': sum(item['value'] for item in mapped_items) / len(mapped_items)
    }
```

**Why chords:** Parallel processing with guaranteed aggregation after all tasks complete.

## Example 2: Report Generation with Data Gathering

**Scenario:** Fetch data from multiple sources, then compile into single report.

```python
from celery import chord

def generate_quarterly_report(quarter, year):
    """Generate report from multiple data sources"""
    result = chord([
        fetch_sales_data.s(quarter, year),
        fetch_financial_data.s(quarter, year),
        fetch_customer_metrics.s(quarter, year),
        fetch_operational_data.s(quarter, year)
    ])(compile_comprehensive_report.s()).get(timeout=180)

    return result

@app.task(ignore_result=False)
def fetch_sales_data(quarter, year):
    """Fetch sales metrics"""
    return {'type': 'sales', 'revenue': 1000000, 'growth': 15}

@app.task
def compile_comprehensive_report(data_sections):
    """Compile all data into final report"""
    report = {
        'quarter': data_sections[0].get('quarter'),
        'sections': data_sections,
        'generated_at': time.time()
    }
    return generate_pdf(report)
```

**Synchronization:** Report only generated after ALL data sources fetched.

## Example 3: Distributed Computation

**Scenario:** Compute statistics across large dataset using parallel workers.

```python
from celery import chord

def compute_statistics(data_chunks):
    """Compute statistics using parallel processing"""
    result = chord(
        compute_chunk_stats.s(chunk) for chunk in data_chunks
    )(aggregate_statistics.s()).get(timeout=120)

    return result

@app.task(ignore_result=False)
def compute_chunk_stats(chunk):
    """Compute stats for data chunk"""
    return {
        'sum': sum(chunk),
        'count': len(chunk),
        'min': min(chunk),
        'max': max(chunk)
    }

@app.task
def aggregate_statistics(chunk_stats):
    """Aggregate chunk statistics"""
    return {
        'total_sum': sum(s['sum'] for s in chunk_stats),
        'total_count': sum(s['count'] for s in chunk_stats),
        'global_min': min(s['min'] for s in chunk_stats),
        'global_max': max(s['max'] for s in chunk_stats),
        'average': sum(s['sum'] for s in chunk_stats) / sum(s['count'] for s in chunk_stats)
    }
```

**Distributed processing:** Each worker processes chunk independently, aggregator combines results.

## Example 4: Multi-Service Health Check

**Scenario:** Check health of multiple services, aggregate into overall status.

```python
from celery import chord

def check_system_health():
    """Check health of all system components"""
    result = chord([
        check_database_health.s(),
        check_cache_health.s(),
        check_api_health.s(),
        check_queue_health.s(),
        check_storage_health.s()
    ])(aggregate_health_status.s()).get(timeout=30)

    return result

@app.task(ignore_result=False)
def check_database_health():
    """Check database connectivity and performance"""
    return {'service': 'database', 'status': 'healthy', 'latency': 15}

@app.task
def aggregate_health_status(health_checks):
    """Determine overall system health"""
    all_healthy = all(check['status'] == 'healthy' for check in health_checks)

    return {
        'overall_status': 'healthy' if all_healthy else 'degraded',
        'components': health_checks,
        'timestamp': time.time()
    }
```

**Aggregation logic:** Overall status depends on all component statuses.

## Example 5: Batch Processing with Notification

**Scenario:** Process batch items in parallel, send notification when all complete.

```python
from celery import chord

def process_batch_with_notification(items, user_email):
    """Process items and notify when complete"""
    result = chord(
        process_item.s(item) for item in items
    )(send_completion_notification.s(user_email)).get(timeout=300)

    return result

@app.task(ignore_result=False)
def process_item(item):
    """Process individual item"""
    return {'id': item['id'], 'status': 'processed'}

@app.task
def send_completion_notification(results, user_email):
    """Send notification after all items processed"""
    successful = sum(1 for r in results if r['status'] == 'processed')

    send_email(
        to=user_email,
        subject="Batch Processing Complete",
        body=f"Processed {successful}/{len(results)} items successfully"
    )

    return {'notified': user_email, 'results': results}
```

**Notification timing:** User only notified after ALL items processed.

## Example 6: Fan-out/Fan-in Pattern

**Scenario:** Split job into parallel tasks, combine results.

```python
from celery import chord, chain

def fan_out_fan_in_workflow(large_job):
    """Split work, process in parallel, merge results"""
    # Split job into chunks
    chunks = split_job.s(large_job).apply_async().get()

    # Fan-out: Process chunks in parallel
    # Fan-in: Merge results
    result = chord(
        process_chunk.s(chunk) for chunk in chunks
    )(merge_chunk_results.s()).get(timeout=180)

    return result

@app.task
def split_job(job):
    """Split large job into processable chunks"""
    num_chunks = 10
    chunk_size = len(job['items']) // num_chunks
    return [
        {'chunk_id': i, 'items': job['items'][i*chunk_size:(i+1)*chunk_size]}
        for i in range(num_chunks)
    ]

@app.task(ignore_result=False)
def process_chunk(chunk):
    """Process single chunk"""
    return {
        'chunk_id': chunk['chunk_id'],
        'processed_count': len(chunk['items']),
        'results': [process(item) for item in chunk['items']]
    }

@app.task
def merge_chunk_results(chunk_results):
    """Merge all chunk results"""
    return {
        'total_chunks': len(chunk_results),
        'total_items': sum(r['processed_count'] for r in chunk_results),
        'all_results': [r for chunk in chunk_results for r in chunk['results']]
    }
```

**Pattern:** Split → Parallel process → Merge back together.

## Example 7: Error Handling in Chords

**Scenario:** Handle failures in chord headers gracefully.

```python
from celery import chord

def chord_with_error_handling(items):
    """Chord with comprehensive error handling"""
    workflow = chord(
        safe_processing.s(item) for item in items
    )(aggregate_with_errors.s())

    workflow.on_error(handle_chord_error.s())

    try:
        result = workflow.apply_async().get(timeout=120)
        return result
    except Exception as exc:
        return {'error': str(exc), 'items': len(items)}

@app.task(ignore_result=False, bind=True)
def safe_processing(self, item):
    """Process with error capture"""
    try:
        # Risky operation
        if item.get('corrupt'):
            raise ValueError("Corrupted data")
        return {'id': item['id'], 'status': 'success'}
    except Exception as exc:
        return {'id': item['id'], 'status': 'error', 'error': str(exc)}

@app.task
def aggregate_with_errors(results):
    """Aggregate including error information"""
    successes = [r for r in results if r['status'] == 'success']
    failures = [r for r in results if r['status'] == 'error']

    return {
        'total': len(results),
        'successful': len(successes),
        'failed': len(failures),
        'success_rate': len(successes) / len(results) * 100
    }

@app.task
def handle_chord_error(request, exc, traceback):
    """Handle chord callback errors"""
    log_error({
        'chord_id': request.id,
        'error': str(exc),
        'type': 'chord_callback_error'
    })
    return {'chord_failed': True, 'error': str(exc)}
```

**Error resilience:** Individual task failures captured, callback receives all results.

## Example 8: Nested Chord Pattern

**Scenario:** Hierarchical processing with multiple aggregation levels.

```python
from celery import chord

def hierarchical_processing(categories):
    """Process categories, then aggregate at category and global level"""
    # Process each category
    category_results = []

    for category in categories:
        # Chord for each category
        category_chord = chord(
            process_item.s(item) for item in category['items']
        )(aggregate_category.s(category['name']))

        category_results.append(category_chord.apply_async())

    # Wait for all categories
    category_aggregations = [r.get(timeout=60) for r in category_results]

    # Global aggregation
    return aggregate_global.s(category_aggregations).apply_async().get()

@app.task(ignore_result=False)
def process_item(item):
    """Process individual item"""
    return {'id': item['id'], 'value': item['value'] * 2}

@app.task
def aggregate_category(items, category_name):
    """Aggregate items within category"""
    return {
        'category': category_name,
        'count': len(items),
        'total_value': sum(item['value'] for item in items)
    }

@app.task
def aggregate_global(category_aggregations):
    """Aggregate across all categories"""
    return {
        'total_categories': len(category_aggregations),
        'grand_total': sum(cat['total_value'] for cat in category_aggregations),
        'categories': category_aggregations
    }
```

**Two-level aggregation:** Category level, then global level.

## Example 9: Timed Batch Processing

**Scenario:** Process items in batches every N minutes, aggregate results.

```python
from celery import chord

@app.task
def process_pending_items():
    """Process accumulated items periodically"""
    # Get pending items
    items = get_pending_items()

    if not items:
        return {'status': 'no_items'}

    # Process batch
    result = chord(
        process_item.s(item) for item in items
    )(update_batch_status.s()).apply_async().get(timeout=300)

    return result

@app.task(ignore_result=False)
def process_item(item):
    """Process single pending item"""
    return {'id': item['id'], 'processed_at': time.time()}

@app.task
def update_batch_status(results):
    """Update batch processing status"""
    # Mark items as processed
    mark_items_processed([r['id'] for r in results])

    return {
        'batch_size': len(results),
        'completed_at': time.time()
    }

# Schedule periodic execution
from celery.schedules import crontab

app.conf.beat_schedule = {
    'process-pending-every-5min': {
        'task': 'tasks.process_pending_items',
        'schedule': crontab(minute='*/5'),
    },
}
```

**Periodic aggregation:** Batch processing on schedule with result tracking.

## Example 10: Dynamic Chord Creation

**Scenario:** Create chord dynamically based on runtime conditions.

```python
from celery import chord

def dynamic_chord_workflow(job_spec):
    """Create chord based on job specifications"""
    # Determine tasks based on job type
    if job_spec['type'] == 'comprehensive':
        header_tasks = [
            deep_analysis.s(job_spec['data']),
            detailed_validation.s(job_spec['data']),
            extended_processing.s(job_spec['data'])
        ]
    elif job_spec['type'] == 'quick':
        header_tasks = [
            quick_analysis.s(job_spec['data']),
            basic_validation.s(job_spec['data'])
        ]
    else:
        header_tasks = [
            standard_processing.s(job_spec['data'])
        ]

    # Create chord with dynamic header
    result = chord(header_tasks)(
        create_summary_report.s(job_spec['type'])
    ).apply_async().get(timeout=180)

    return result
```

**Dynamic composition:** Chord structure determined at runtime.

## Best Practices

1. **Always set `ignore_result=False`:** Tasks in chord headers MUST track results
2. **Enable result backend:** Chords require result storage (Redis, database)
3. **Add error callbacks:** Use `.on_error()` for chord failures
4. **Set appropriate timeouts:** Both header tasks and callback
5. **Monitor Redis version:** Requires Redis 2.2+ for proper operation
6. **Test callback independently:** Ensure callback handles expected data structure

## Common Pitfalls

❌ **Tasks with `ignore_result=True`:** Breaks chord synchronization
❌ **No result backend:** Chords require result storage
❌ **Callback ignores results parameter:** Must accept list from header
❌ **Missing timeout on `.get()`:** May wait indefinitely
❌ **Overriding `after_return()` without `super()`:** Breaks chord callbacks

## Performance Considerations

- **Result storage overhead:** All header results stored until callback completes
- **Synchronization delay:** Callback waits for slowest header task
- **Redis operations:** Multiple Redis calls for coordination
- **Memory usage:** Results held in memory during aggregation
