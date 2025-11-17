# Group Parallel Processing Examples

Real-world scenarios using Celery groups for parallel task execution.

## Example 1: Bulk Email Campaign

**Scenario:** Send emails to thousands of recipients in parallel.

```python
from celery import group

def send_email_campaign(recipient_list):
    """Send emails in parallel"""
    job = group(
        send_email.s(recipient['email'], recipient['name'])
        for recipient in recipient_list
    )

    result = job.apply_async()

    # Wait for all emails to send
    results = result.get(timeout=300)

    # Count successes
    successful = sum(1 for r in results if r.get('sent'))
    return f"Sent {successful}/{len(recipient_list)} emails"
```

**Why groups:** All emails can be sent independently and simultaneously.

## Example 2: Image Processing Batch

**Scenario:** Resize multiple images in parallel.

```python
from celery import group

def batch_resize_images(image_urls, sizes):
    """Resize multiple images to multiple sizes"""
    # Create all resize tasks
    tasks = [
        resize_image.s(url, width, height)
        for url in image_urls
        for width, height in sizes
    ]

    # Execute in parallel
    job = group(tasks)
    result = job.apply_async()

    # Monitor progress
    total = len(tasks)
    while not result.ready():
        completed = result.completed_count()
        print(f"Progress: {completed}/{total} ({completed/total*100:.1f}%)")
        time.sleep(1)

    return result.get(timeout=600)
```

**Progress monitoring:** Track completion of parallel tasks in real-time.

## Example 3: API Data Aggregation

**Scenario:** Fetch data from multiple APIs concurrently.

```python
from celery import group

def aggregate_market_data(symbols):
    """Fetch stock data from multiple sources"""
    # Parallel API calls
    job = group(
        fetch_stock_price.s(symbol, 'yahoo'),
        fetch_stock_price.s(symbol, 'google'),
        fetch_stock_price.s(symbol, 'bloomberg')
        for symbol in symbols
    )

    result = job.apply_async()
    all_data = result.get(timeout=30)

    # Aggregate results
    aggregated = {}
    for data in all_data:
        symbol = data['symbol']
        aggregated.setdefault(symbol, []).append(data)

    return aggregated
```

**Use case:** Reduce API call latency by parallelizing requests.

## Example 4: Document Analysis

**Scenario:** Analyze multiple documents simultaneously.

```python
from celery import group

def analyze_document_batch(document_ids):
    """Analyze multiple documents in parallel"""
    # Create analysis tasks
    job = group(
        chain(
            load_document.s(doc_id),
            extract_text.s(),
            analyze_sentiment.s(),
            extract_entities.s()
        )
        for doc_id in document_ids
    )

    result = job.apply_async()
    return result.get(timeout=300)
```

**Nested pattern:** Each document goes through sequential chain, but all documents processed in parallel.

## Example 5: Database Bulk Operations

**Scenario:** Update multiple database records in parallel.

```python
from celery import group

def bulk_update_prices(product_updates):
    """Update product prices in parallel"""
    # Error-safe updates
    job = group(
        safe_update_price.s(product_id, new_price)
        for product_id, new_price in product_updates.items()
    )

    result = job.apply_async()
    results = result.get(timeout=60)

    # Separate successes and failures
    successes = [r for r in results if r.get('success')]
    failures = [r for r in results if not r.get('success')]

    return {
        'updated': len(successes),
        'failed': len(failures),
        'failures': failures
    }
```

**Error handling:** Each update captured individually, failures don't block others.

## Example 6: Priority-Based Processing

**Scenario:** Process high-priority items first, then low-priority.

```python
from celery import group

def prioritized_batch_processing(items):
    """Process with priority levels"""
    # Separate by priority
    high_priority = [item for item in items if item['priority'] == 'high']
    low_priority = [item for item in items if item['priority'] == 'low']

    # Process high priority first
    high_job = group(
        process_item.s(item).set(priority=9)
        for item in high_priority
    )

    low_job = group(
        process_item.s(item).set(priority=1)
        for item in low_priority
    )

    # Execute both groups
    high_result = high_job.apply_async()
    low_result = low_job.apply_async()

    return {
        'high': high_result.get(timeout=60),
        'low': low_result.get(timeout=120)
    }
```

**Priority queues:** High-priority tasks processed before low-priority.

## Example 7: Web Scraping

**Scenario:** Scrape multiple websites in parallel.

```python
from celery import group

def scrape_websites(urls):
    """Scrape multiple URLs in parallel"""
    job = group(
        scrape_url.s(url).set(
            time_limit=30,  # 30 second limit per URL
            soft_time_limit=25
        )
        for url in urls
    )

    result = job.apply_async()

    # Handle timeouts gracefully
    try:
        results = result.get(timeout=60)
    except Exception as exc:
        # Get partial results
        results = [
            child.result if child.ready() else {'error': 'timeout'}
            for child in result.children
        ]

    return results
```

**Timeout handling:** Individual task timeouts don't block group completion.

## Example 8: Report Generation

**Scenario:** Generate multiple report sections in parallel.

```python
from celery import group

def generate_comprehensive_report(report_id):
    """Generate report sections in parallel"""
    # Parallel section generation
    job = group([
        generate_executive_summary.s(report_id),
        generate_financial_section.s(report_id),
        generate_operational_metrics.s(report_id),
        generate_charts_and_graphs.s(report_id),
        generate_recommendations.s(report_id)
    ])

    result = job.apply_async()
    sections = result.get(timeout=180)

    # Combine sections
    complete_report = combine_report_sections.s(sections).apply_async().get()

    return complete_report
```

**Independent sections:** Each report section generated independently, then combined.

## Example 9: Rate-Limited API Calls

**Scenario:** Make many API calls respecting rate limits.

```python
from celery import group

@app.task(rate_limit='10/m')  # 10 per minute
def api_call_rate_limited(endpoint):
    """Rate-limited API call"""
    # Make API request
    return make_request(endpoint)

def batch_api_calls(endpoints):
    """Batch API calls with rate limiting"""
    # Group respects rate limit on each task
    job = group(
        api_call_rate_limited.s(endpoint)
        for endpoint in endpoints
    )

    result = job.apply_async()

    # This will take time due to rate limiting
    return result.get(timeout=600)
```

**Rate limiting:** Celery enforces rate limit across parallel tasks.

## Example 10: Machine Learning Batch Prediction

**Scenario:** Run predictions on multiple data points in parallel.

```python
from celery import group

def batch_predictions(data_points, model_id):
    """Parallel batch predictions"""
    # Split into chunks
    chunk_size = 100
    chunks = [
        data_points[i:i+chunk_size]
        for i in range(0, len(data_points), chunk_size)
    ]

    # Parallel predictions
    job = group(
        predict_batch.s(chunk, model_id)
        for chunk in chunks
    )

    result = job.apply_async()
    chunk_results = result.get(timeout=300)

    # Flatten results
    all_predictions = [
        pred
        for chunk_result in chunk_results
        for pred in chunk_result
    ]

    return all_predictions
```

**Chunking strategy:** Balance parallelism with task overhead.

## Best Practices from Examples

1. **Monitor progress:** Use `result.completed_count()` for tracking
2. **Handle partial failures:** Check individual task results
3. **Set timeouts:** Both per-task and group-level timeouts
4. **Chunk large batches:** Don't create thousands of tiny tasks
5. **Use priorities:** Differentiate urgent vs. background tasks
6. **Rate limiting:** Respect external API limits

## Performance Optimization

```python
# Good: Chunked processing
chunks = [items[i:i+100] for i in range(0, len(items), 100)]
job = group(process_chunk.s(chunk) for chunk in chunks)

# Bad: Too many tiny tasks
job = group(process_item.s(item) for item in items)  # 10,000 tasks!
```

## Error Handling Patterns

```python
from celery import group

def safe_batch_processing(items):
    """Process batch with error capturing"""
    # Each task captures its own errors
    job = group(
        safe_process.s(item)  # Returns success/error info
        for item in items
    )

    result = job.apply_async()
    results = result.get(timeout=120)

    # Analyze results
    successes = [r for r in results if r['status'] == 'success']
    failures = [r for r in results if r['status'] == 'error']

    return {
        'total': len(results),
        'succeeded': len(successes),
        'failed': len(failures),
        'failures': failures
    }
```

## Monitoring and Debugging

```python
# Check group status
result = job.apply_async()

# Individual child results
for i, child in enumerate(result.children):
    print(f"Task {i}: {child.state}")

# Get completed count
completed = result.completed_count()
total = len(job.tasks)
print(f"Progress: {completed}/{total}")

# Check if all done
if result.ready():
    all_results = result.get()
```

## When NOT to Use Groups

❌ **Sequential dependencies:** Use chains instead
❌ **Need aggregation after parallel work:** Use chords instead
❌ **Too many tasks:** Chunk into batches first
❌ **Tasks ignore results:** Groups require result tracking
