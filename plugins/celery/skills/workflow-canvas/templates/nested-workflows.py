"""
Celery Nested Workflow Patterns
Advanced workflow composition and nesting strategies
"""

from celery import Celery, chain, group, chord, signature
from typing import List, Dict, Any

app = Celery('nested_workflows')
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
# Chain of Chords Pattern
# ============================================================================

@app.task(ignore_result=False)
def process_batch_stage1(batch_id: int) -> dict:
    """First stage processing"""
    return {'batch_id': batch_id, 'stage1_result': batch_id * 10}


@app.task
def aggregate_stage1(results: List[dict]) -> dict:
    """Aggregate stage 1 results"""
    return {
        'stage': 1,
        'batches': len(results),
        'total': sum(r['stage1_result'] for r in results)
    }


@app.task(ignore_result=False)
def process_batch_stage2(batch_id: int, stage1_total: int) -> dict:
    """Second stage processing with stage1 data"""
    return {
        'batch_id': batch_id,
        'stage2_result': batch_id * stage1_total
    }


@app.task
def aggregate_stage2(results: List[dict]) -> dict:
    """Aggregate stage 2 results"""
    return {
        'stage': 2,
        'batches': len(results),
        'total': sum(r['stage2_result'] for r in results)
    }


def chain_of_chords_workflow(num_batches: int = 5):
    """Chain multiple chord operations"""
    # Stage 1: Process batches in parallel
    stage1 = chord(
        process_batch_stage1.s(i) for i in range(num_batches)
    )(aggregate_stage1.s())

    # Get stage1 result
    stage1_result = stage1.apply_async().get(timeout=30)

    # Stage 2: Process with stage1 results
    stage2 = chord(
        process_batch_stage2.s(i, stage1_result['total'])
        for i in range(num_batches)
    )(aggregate_stage2.s())

    return stage2.apply_async()


# ============================================================================
# Groups within Chains Pattern
# ============================================================================

@app.task
def prepare_data(dataset_id: str) -> dict:
    """Prepare dataset for processing"""
    return {
        'dataset_id': dataset_id,
        'items': [{'id': i} for i in range(10)]
    }


@app.task(ignore_result=False)
def transform_item(item: dict) -> dict:
    """Transform single item"""
    item['transformed'] = True
    return item


@app.task
def collect_results(results: List[dict]) -> dict:
    """Collect transformation results"""
    return {
        'transformed_count': len(results),
        'items': results
    }


@app.task
def finalize_dataset(data: dict) -> dict:
    """Finalize dataset processing"""
    data['finalized'] = True
    return data


def groups_in_chains_workflow(dataset_id: str):
    """Embed parallel processing within sequential flow"""
    workflow = chain(
        # Step 1: Prepare data
        prepare_data.s(dataset_id),

        # Step 2: Transform items in parallel (embedded group)
        # Note: This is a simplified pattern; in production you'd use a custom task
        # that creates the group dynamically

        # Step 3: Finalize
        finalize_dataset.s()
    )

    # Alternative with explicit group
    data = prepare_data.s(dataset_id).apply_async().get()
    transformed = group(
        transform_item.s(item) for item in data['items']
    ).apply_async().get()
    data['items'] = transformed

    return finalize_dataset.s(data).apply_async()


# ============================================================================
# Nested Chords Pattern
# ============================================================================

@app.task(ignore_result=False)
def outer_task(value: int) -> int:
    """Outer level task"""
    return value * 2


@app.task
def outer_callback(results: List[int]) -> dict:
    """Outer chord callback"""
    return {'outer_sum': sum(results), 'outer_count': len(results)}


@app.task(ignore_result=False)
def inner_task(value: int) -> int:
    """Inner level task"""
    return value + 10


@app.task
def inner_callback(results: List[int]) -> int:
    """Inner chord callback"""
    return sum(results)


def nested_chords_workflow():
    """Chord within chord pattern"""
    # Inner chord: process sub-items
    inner_chord = chord(
        inner_task.s(i) for i in range(5)
    )(inner_callback.s())

    # Get inner result
    inner_result = inner_chord.apply_async().get(timeout=30)

    # Outer chord: use inner result
    outer_chord = chord(
        outer_task.s(i + inner_result) for i in range(10)
    )(outer_callback.s())

    return outer_chord.apply_async()


# ============================================================================
# Dynamic Workflow Generation
# ============================================================================

@app.task
def analyze_workload(workload_spec: dict) -> dict:
    """Analyze workload to determine processing strategy"""
    size = workload_spec.get('size', 0)

    if size < 10:
        return {'strategy': 'sequential', 'chunks': 1}
    elif size < 100:
        return {'strategy': 'parallel', 'chunks': 4}
    else:
        return {'strategy': 'hierarchical', 'chunks': 10}


@app.task(ignore_result=False)
def process_chunk(chunk_id: int, strategy: str) -> dict:
    """Process chunk with strategy"""
    return {
        'chunk_id': chunk_id,
        'strategy': strategy,
        'result': chunk_id * 100
    }


@app.task
def create_dynamic_workflow(workload: dict, strategy_info: dict) -> Any:
    """Create workflow based on analysis"""
    strategy = strategy_info['strategy']
    chunks = strategy_info['chunks']

    if strategy == 'sequential':
        # Simple chain
        workflow = chain(
            process_chunk.s(i, strategy) for i in range(chunks)
        )
    elif strategy == 'parallel':
        # Group for parallel processing
        workflow = group(
            process_chunk.s(i, strategy) for i in range(chunks)
        )
    else:
        # Chord for hierarchical processing
        workflow = chord(
            process_chunk.s(i, strategy) for i in range(chunks)
        )(collect_results.s())

    return workflow.apply_async()


def dynamic_workflow_example(workload_spec: dict):
    """Generate workflow dynamically based on workload"""
    workflow = chain(
        analyze_workload.s(workload_spec),
        create_dynamic_workflow.s(workload_spec)
    )

    return workflow.apply_async()


# ============================================================================
# Recursive Workflow Pattern
# ============================================================================

@app.task(bind=True)
def recursive_processor(self, data: dict, depth: int = 0, max_depth: int = 3) -> dict:
    """Process data recursively"""
    if depth >= max_depth:
        return {'depth': depth, 'value': data.get('value', 0), 'leaf': True}

    # Process current level
    current_value = data.get('value', 0) * 2

    # Create sub-tasks for next level
    if depth < max_depth - 1:
        sub_tasks = group(
            recursive_processor.s(
                {'value': current_value + i},
                depth + 1,
                max_depth
            )
            for i in range(3)
        )

        results = sub_tasks.apply_async().get(timeout=30)

        return {
            'depth': depth,
            'value': current_value,
            'children': results,
            'leaf': False
        }
    else:
        return {'depth': depth, 'value': current_value, 'leaf': True}


def recursive_workflow_example():
    """Recursive task execution"""
    result = recursive_processor.s({'value': 1}, depth=0, max_depth=3)
    return result.apply_async()


# ============================================================================
# Map-Reduce Pattern with Nesting
# ============================================================================

@app.task(ignore_result=False)
def map_function(item: dict) -> dict:
    """Map function for processing"""
    return {
        'id': item['id'],
        'mapped_value': item.get('value', 0) * 2,
        'category': 'A' if item['id'] % 2 == 0 else 'B'
    }


@app.task
def reduce_by_category(mapped_items: List[dict]) -> dict:
    """Reduce function grouping by category"""
    categories = {}
    for item in mapped_items:
        category = item.get('category', 'unknown')
        categories.setdefault(category, []).append(item)

    return {
        cat: {
            'count': len(items),
            'sum': sum(i['mapped_value'] for i in items)
        }
        for cat, items in categories.items()
    }


@app.task(ignore_result=False)
def secondary_map(category_data: tuple) -> dict:
    """Secondary map on reduced data"""
    category, data = category_data
    return {
        'category': category,
        'processed_sum': data['sum'] * 1.5,
        'count': data['count']
    }


@app.task
def final_reduce(results: List[dict]) -> dict:
    """Final reduction"""
    return {
        'total_categories': len(results),
        'grand_total': sum(r['processed_sum'] for r in results),
        'details': results
    }


def nested_map_reduce_workflow(items: List[dict]):
    """Nested map-reduce pattern"""
    # First map-reduce
    first_map = group(map_function.s(item) for item in items)
    mapped = first_map.apply_async().get(timeout=30)
    reduced = reduce_by_category.s(mapped).apply_async().get()

    # Second map-reduce on categories
    second_map = chord(
        secondary_map.s((cat, data)) for cat, data in reduced.items()
    )(final_reduce.s())

    return second_map.apply_async()


# ============================================================================
# Conditional Nested Workflows
# ============================================================================

@app.task
def check_condition(data: dict) -> str:
    """Check condition to determine workflow path"""
    size = data.get('size', 0)
    if size > 100:
        return 'large'
    elif size > 10:
        return 'medium'
    else:
        return 'small'


@app.task
def create_nested_workflow(data: dict, condition: str) -> Any:
    """Create nested workflow based on condition"""
    if condition == 'large':
        # Complex nested workflow
        return chord(
            chain(
                process_chunk.s(i, 'large'),
                transform_item.s()
            )
            for i in range(10)
        )(collect_results.s()).apply_async()

    elif condition == 'medium':
        # Simple parallel workflow
        return group(
            process_chunk.s(i, 'medium') for i in range(5)
        ).apply_async()

    else:
        # Sequential workflow
        return chain(
            process_chunk.s(i, 'small') for i in range(3)
        ).apply_async()


def conditional_nested_workflow(data: dict):
    """Generate nested workflow based on conditions"""
    workflow = chain(
        check_condition.s(data),
        create_nested_workflow.s(data)
    )

    return workflow.apply_async()


# ============================================================================
# Usage Examples
# ============================================================================

if __name__ == '__main__':
    # Chain of chords
    print("Chain of chords:")
    result = chain_of_chords_workflow(5)
    print(f"Result: {result.get(timeout=60)}")

    # Nested chords
    print("\nNested chords:")
    result = nested_chords_workflow()
    print(f"Result: {result.get(timeout=60)}")

    # Dynamic workflow
    print("\nDynamic workflow:")
    workload = {'size': 50, 'type': 'batch'}
    result = dynamic_workflow_example(workload)
    print(f"Result: {result.get(timeout=60)}")

    # Map-reduce nested
    print("\nNested map-reduce:")
    items = [{'id': i, 'value': i * 5} for i in range(20)]
    result = nested_map_reduce_workflow(items)
    print(f"Result: {result.get(timeout=60)}")

    # Conditional nested
    print("\nConditional nested:")
    data = {'size': 150, 'items': []}
    result = conditional_nested_workflow(data)
    print(f"Result: {result.get(timeout=60)}")
