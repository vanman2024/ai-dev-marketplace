# Complex Workflow Architectures

Production-ready patterns combining chains, groups, and chords for sophisticated workflows.

## Pattern 1: Multi-Stage ETL Pipeline

**Scenario:** Extract from multiple sources → Transform in parallel → Aggregate → Load

```python
from celery import chain, group, chord

def multi_source_etl_pipeline(sources):
    """
    ETL Pipeline Architecture:
    1. Extract from all sources (parallel)
    2. Transform each dataset (parallel)
    3. Validate transformations (parallel)
    4. Aggregate results (chord callback)
    5. Load to warehouse (sequential)
    """
    workflow = chain(
        # Stage 1: Parallel extraction
        group(extract_from_source.s(source) for source in sources),

        # Stage 2: Transform extracted data in parallel, then aggregate
        chord(
            chain(
                transform_dataset.s(dataset),
                validate_transformation.s()
            )
            for source in sources
            for dataset in [extract_from_source.s(source).apply_async().get()]
        )(aggregate_transformed_data.s()),

        # Stage 3: Load to warehouse
        load_to_warehouse.s(),

        # Stage 4: Verify and notify
        chain(
            verify_data_integrity.s(),
            send_completion_notification.si('ETL Complete')
        )
    )

    return workflow.apply_async()
```

**Architecture:** Combines parallel extraction, parallel transformation with aggregation, sequential loading.

## Pattern 2: Hierarchical Data Processing

**Scenario:** Process data at multiple hierarchy levels (company → department → team)

```python
from celery import chord, group

def hierarchical_processing_workflow(company_data):
    """
    Hierarchy: Company → Departments → Teams
    Process at each level, aggregate up the hierarchy
    """
    department_results = []

    # Process each department
    for department in company_data['departments']:
        # Process teams within department in parallel
        team_chord = chord(
            process_team.s(team) for team in department['teams']
        )(aggregate_department.s(department['name']))

        department_results.append(team_chord.apply_async())

    # Wait for all departments
    dept_aggregations = [r.get(timeout=120) for r in department_results]

    # Company-level aggregation
    return aggregate_company.s(dept_aggregations).apply_async().get()

@app.task(ignore_result=False)
def process_team(team):
    """Process team-level data"""
    return {
        'team': team['name'],
        'members': len(team['members']),
        'metrics': calculate_team_metrics(team)
    }

@app.task
def aggregate_department(teams, dept_name):
    """Aggregate team data to department level"""
    return {
        'department': dept_name,
        'teams': len(teams),
        'total_members': sum(t['members'] for t in teams),
        'dept_metrics': calculate_dept_metrics(teams)
    }

@app.task
def aggregate_company(departments):
    """Aggregate department data to company level"""
    return {
        'departments': len(departments),
        'total_teams': sum(d['teams'] for d in departments),
        'total_members': sum(d['total_members'] for d in departments),
        'company_metrics': calculate_company_metrics(departments)
    }
```

**Use case:** Roll-up reporting, hierarchical aggregations, organizational analytics.

## Pattern 3: Conditional Branch Workflow

**Scenario:** Different processing paths based on data characteristics

```python
from celery import chain, chord, group

def conditional_processing_workflow(items):
    """
    Route items to different processing pipelines:
    - Critical items: Fast lane with priority
    - Standard items: Normal processing
    - Bulk items: Batched processing
    """
    # Classify items
    critical = [item for item in items if item['priority'] == 'critical']
    standard = [item for item in items if item['priority'] == 'standard']
    bulk = [item for item in items if item['priority'] == 'bulk']

    workflows = []

    # Critical: Fast processing with immediate notification
    if critical:
        critical_workflow = chord(
            process_critical_item.s(item).set(priority=9)
            for item in critical
        )(notify_critical_complete.s())
        workflows.append(critical_workflow.apply_async())

    # Standard: Normal parallel processing
    if standard:
        standard_workflow = chord(
            process_standard_item.s(item).set(priority=5)
            for item in standard
        )(aggregate_standard_results.s())
        workflows.append(standard_workflow.apply_async())

    # Bulk: Batched processing
    if bulk:
        # Split into batches
        batch_size = 50
        batches = [bulk[i:i+batch_size] for i in range(0, len(bulk), batch_size)]

        bulk_workflow = chord(
            process_bulk_batch.s(batch).set(priority=1)
            for batch in batches
        )(aggregate_bulk_results.s())
        workflows.append(bulk_workflow.apply_async())

    # Wait for all workflows
    results = [w.get(timeout=300) for w in workflows]

    return combine_results.s(results).apply_async().get()
```

**Pattern:** Priority-based routing with different processing strategies per priority level.

## Pattern 4: Progressive Refinement Pipeline

**Scenario:** Iteratively refine results through multiple passes

```python
from celery import chain, chord

def progressive_refinement_workflow(initial_data, max_iterations=3):
    """
    Iterative refinement:
    1. Process all items
    2. Validate quality
    3. Re-process low-quality items
    4. Repeat until quality threshold met or max iterations
    """
    current_data = initial_data
    iteration = 0

    while iteration < max_iterations:
        # Process current batch
        processed = chord(
            process_item.s(item) for item in current_data
        )(collect_processed_items.s()).apply_async().get(timeout=180)

        # Check quality
        quality_check = assess_quality.s(processed).apply_async().get()

        if quality_check['quality_score'] >= 0.95:
            # Quality threshold met
            return finalize_results.s(processed).apply_async().get()

        # Extract low-quality items for reprocessing
        current_data = [
            item for item in processed
            if item['quality_score'] < 0.95
        ]

        iteration += 1

    # Max iterations reached
    return finalize_with_warnings.s(processed).apply_async().get()

@app.task(ignore_result=False)
def process_item(item):
    """Process or reprocess item"""
    result = apply_processing(item)
    return {
        'id': item['id'],
        'result': result,
        'quality_score': calculate_quality(result)
    }

@app.task
def assess_quality(items):
    """Assess overall batch quality"""
    scores = [item['quality_score'] for item in items]
    return {
        'quality_score': sum(scores) / len(scores),
        'items_below_threshold': sum(1 for s in scores if s < 0.95)
    }
```

**Use case:** ML model training, iterative optimization, quality improvement loops.

## Pattern 5: Scatter-Gather with Timeout

**Scenario:** Request data from multiple sources, use whatever returns in time

```python
from celery import group
import time

def scatter_gather_with_timeout(request_spec, timeout_seconds=10):
    """
    Scatter: Send requests to all sources
    Gather: Collect responses that arrive in time
    """
    sources = [
        'primary_api',
        'backup_api',
        'cache_source',
        'fallback_source'
    ]

    # Scatter: Send to all sources
    job = group(
        fetch_from_source.s(source, request_spec).set(
            time_limit=timeout_seconds,
            soft_time_limit=timeout_seconds - 1
        )
        for source in sources
    )

    result = job.apply_async()

    # Gather with timeout
    start_time = time.time()
    gathered_results = []

    for child in result.children:
        remaining_time = timeout_seconds - (time.time() - start_time)

        if remaining_time <= 0:
            break

        try:
            child_result = child.get(timeout=remaining_time)
            gathered_results.append(child_result)
        except:
            # Timeout or error - skip this source
            continue

    # Use best available result
    return select_best_result.s(gathered_results).apply_async().get()

@app.task
def select_best_result(results):
    """Select best result from multiple sources"""
    if not results:
        raise ValueError("No results available")

    # Prefer primary source, fall back to others
    for source_priority in ['primary_api', 'backup_api', 'cache_source', 'fallback_source']:
        for result in results:
            if result.get('source') == source_priority:
                return result

    # Return any available result
    return results[0]
```

**Pattern:** Race condition with timeout, fallback to available results.

## Pattern 6: Pipeline with Checkpoints

**Scenario:** Long pipeline with save points for recovery

```python
from celery import chain, chord

def checkpointed_pipeline(job_id, input_data):
    """
    Pipeline with checkpoints:
    - Save state after each major phase
    - Can resume from checkpoints if failure occurs
    """
    # Check if checkpoint exists
    checkpoint = load_checkpoint(job_id)

    if checkpoint:
        # Resume from checkpoint
        start_phase = checkpoint['phase']
        data = checkpoint['data']
    else:
        start_phase = 1
        data = input_data

    # Phase 1: Initial processing
    if start_phase <= 1:
        data = chord(
            process_chunk.s(chunk) for chunk in split_data(data)
        )(merge_chunks.s()).apply_async().get(timeout=300)

        save_checkpoint(job_id, phase=1, data=data)

    # Phase 2: Transformation
    if start_phase <= 2:
        data = chain(
            transform_data.s(data),
            validate_transformation.s()
        ).apply_async().get(timeout=180)

        save_checkpoint(job_id, phase=2, data=data)

    # Phase 3: Enrichment
    if start_phase <= 3:
        data = chord(
            enrich_item.s(item) for item in data
        )(aggregate_enriched.s()).apply_async().get(timeout=240)

        save_checkpoint(job_id, phase=3, data=data)

    # Phase 4: Finalization
    result = finalize_pipeline.s(data).apply_async().get(timeout=60)

    # Clear checkpoint on success
    clear_checkpoint(job_id)

    return result
```

**Recovery:** Pipeline can resume from last successful checkpoint after failure.

## Pattern 7: A/B Testing Workflow

**Scenario:** Run two different processing approaches, compare results

```python
from celery import group, chord

def ab_testing_workflow(test_data, algorithm_a, algorithm_b):
    """
    Run both algorithms in parallel, compare results
    """
    # Split data for testing
    test_split = len(test_data) // 2
    data_a = test_data[:test_split]
    data_b = test_data[test_split:]

    # Run both algorithms in parallel
    workflow_a = chord(
        algorithm_a.s(item) for item in data_a
    )(collect_results.s('algorithm_a'))

    workflow_b = chord(
        algorithm_b.s(item) for item in data_b
    )(collect_results.s('algorithm_b'))

    # Execute both
    result_a = workflow_a.apply_async()
    result_b = workflow_b.apply_async()

    # Compare results
    comparison = compare_algorithms.s(
        result_a.get(timeout=180),
        result_b.get(timeout=180)
    ).apply_async().get()

    return comparison

@app.task
def compare_algorithms(results_a, results_b):
    """Compare performance of two algorithms"""
    return {
        'algorithm_a': {
            'accuracy': calculate_accuracy(results_a),
            'latency': results_a['avg_latency'],
            'throughput': results_a['throughput']
        },
        'algorithm_b': {
            'accuracy': calculate_accuracy(results_b),
            'latency': results_b['avg_latency'],
            'throughput': results_b['throughput']
        },
        'recommendation': select_winner(results_a, results_b)
    }
```

**Testing:** Compare different implementations with real workload.

## Pattern 8: Multi-Tenant Processing

**Scenario:** Process data for multiple tenants with isolation and quotas

```python
from celery import group, chord

def multi_tenant_processing(tenant_data_map):
    """
    Process data for multiple tenants:
    - Isolated processing per tenant
    - Quota enforcement
    - Tenant-specific configuration
    """
    tenant_workflows = []

    for tenant_id, tenant_data in tenant_data_map.items():
        # Get tenant configuration
        tenant_config = get_tenant_config(tenant_id)

        # Check quota
        if not check_quota(tenant_id, len(tenant_data)):
            log_quota_exceeded(tenant_id)
            continue

        # Create tenant-specific workflow
        tenant_workflow = chord(
            process_tenant_item.s(
                item,
                tenant_id=tenant_id,
                config=tenant_config
            ).set(
                priority=tenant_config.get('priority', 5),
                time_limit=tenant_config.get('time_limit', 300)
            )
            for item in tenant_data
        )(aggregate_tenant_results.s(tenant_id))

        tenant_workflows.append({
            'tenant_id': tenant_id,
            'workflow': tenant_workflow.apply_async()
        })

    # Collect all tenant results
    results = []
    for tw in tenant_workflows:
        try:
            result = tw['workflow'].get(timeout=600)
            results.append({
                'tenant_id': tw['tenant_id'],
                'result': result
            })
        except Exception as exc:
            results.append({
                'tenant_id': tw['tenant_id'],
                'error': str(exc)
            })

    return results
```

**Multi-tenancy:** Isolated processing with per-tenant quotas and configuration.

## Best Practices for Complex Workflows

1. **Break into phases:** Logical stages with clear boundaries
2. **Add checkpoints:** Enable recovery from failures
3. **Monitor progress:** Track completion of major phases
4. **Set timeouts:** Both per-task and workflow-level
5. **Handle partial failures:** Don't let one tenant/item block others
6. **Use priorities:** Critical paths get higher priority
7. **Add metrics:** Track performance of each stage
8. **Test components:** Validate individual stages before combining

## Performance Optimization

```python
# Good: Phased execution with aggregation
phase1 = chord(tasks1)(aggregate1.s())
result1 = phase1.apply_async().get()

phase2 = chord(tasks2)(aggregate2.s())
result2 = phase2.apply_async().get()

# Bad: Deep nesting
workflow = chord(
    chord(
        chord(tasks3)(callback3.s())
        for group in groups
    )(callback2.s())
)(callback1.s())
```

## Monitoring Complex Workflows

```python
def monitor_workflow(workflow_result, phases):
    """Monitor multi-phase workflow progress"""
    status = {
        'phases': [],
        'overall_progress': 0
    }

    for i, phase in enumerate(phases):
        phase_result = phase.get('result')

        if phase_result.ready():
            status['phases'].append({
                'phase': i + 1,
                'status': 'complete',
                'result': phase_result.result
            })
        else:
            status['phases'].append({
                'phase': i + 1,
                'status': 'running'
            })

    completed_phases = sum(1 for p in status['phases'] if p['status'] == 'complete')
    status['overall_progress'] = (completed_phases / len(phases)) * 100

    return status
```
