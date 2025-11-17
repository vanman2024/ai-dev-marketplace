"""
Celery Chain Workflow Patterns
Sequential task execution with result forwarding
"""

from celery import Celery, chain
from typing import Any

app = Celery('chain_workflows')
app.config_from_object({
    'broker_url': 'redis://localhost:6379/0',
    'result_backend': 'redis://localhost:6379/0',
    'task_serializer': 'json',
    'result_serializer': 'json',
    'accept_content': ['json'],
})


# ============================================================================
# Basic Chain Pattern
# ============================================================================

@app.task
def fetch_data(url: str) -> dict:
    """Fetch data from source"""
    # Placeholder implementation
    return {'url': url, 'data': 'sample_data'}


@app.task
def transform_data(data: dict) -> dict:
    """Transform fetched data"""
    data['transformed'] = True
    return data


@app.task
def save_data(data: dict) -> str:
    """Save transformed data"""
    return f"Saved: {data}"


def basic_chain_example():
    """Sequential pipeline: fetch → transform → save"""
    workflow = chain(
        fetch_data.s('https://api.example.com/data'),
        transform_data.s(),
        save_data.s()
    )

    result = workflow.apply_async()
    return result.get(timeout=30)


# ============================================================================
# Chain with Immutable Tasks
# ============================================================================

@app.task
def notify_start(message: str) -> None:
    """Send start notification (doesn't return data)"""
    print(f"Notification: {message}")


@app.task
def process_item(item: dict) -> dict:
    """Process single item"""
    item['processed'] = True
    return item


@app.task
def notify_complete(message: str) -> None:
    """Send completion notification"""
    print(f"Notification: {message}")


def immutable_chain_example():
    """Chain with independent tasks using .si()"""
    workflow = chain(
        notify_start.si('Starting pipeline'),
        fetch_data.s('https://api.example.com/items'),
        process_item.s(),
        save_data.s(),
        notify_complete.si('Pipeline complete')
    )

    result = workflow.apply_async()
    return result.get(timeout=30)


# ============================================================================
# Partial Application Pattern
# ============================================================================

@app.task
def apply_discount(price: float, discount_percent: float) -> float:
    """Apply discount to price"""
    return price * (1 - discount_percent / 100)


@app.task
def add_tax(price: float, tax_rate: float = 0.08) -> float:
    """Add tax to price"""
    return price * (1 + tax_rate)


@app.task
def format_price(price: float) -> str:
    """Format price for display"""
    return f"${price:.2f}"


def partial_application_example():
    """Create reusable workflow with partial application"""
    # Create partial signature with discount preset
    apply_10_percent_discount = apply_discount.s(discount_percent=10)

    # Build chain with partial
    workflow = chain(
        apply_10_percent_discount,
        add_tax.s(),
        format_price.s()
    )

    # Execute with different prices
    result1 = workflow.clone(args=(100.0,)).apply_async()
    result2 = workflow.clone(args=(250.0,)).apply_async()

    return {
        'price1': result1.get(timeout=10),
        'price2': result2.get(timeout=10)
    }


# ============================================================================
# Error Handling in Chains
# ============================================================================

@app.task
def risky_operation(data: dict) -> dict:
    """Operation that might fail"""
    if not data.get('valid'):
        raise ValueError("Invalid data")
    return data


@app.task
def handle_chain_error(request, exc, traceback) -> None:
    """Error callback for chain failures"""
    print(f"Chain failed in task {request.id}: {exc}")
    # Log to monitoring system
    # Send alert notification


def error_handling_chain_example():
    """Chain with error callback"""
    workflow = chain(
        fetch_data.s('https://api.example.com/risky'),
        risky_operation.s(),
        save_data.s()
    )

    # Attach error handler
    workflow.on_error(handle_chain_error.s())

    result = workflow.apply_async()
    return result


# ============================================================================
# Conditional Chain Pattern
# ============================================================================

@app.task
def validate_input(data: dict) -> dict:
    """Validate input data"""
    data['is_valid'] = data.get('value', 0) > 0
    return data


@app.task
def create_conditional_chain(data: dict) -> Any:
    """Create different chains based on data"""
    if data.get('is_valid'):
        # Valid data: full processing
        return chain(
            transform_data.s(data),
            save_data.s()
        ).apply_async()
    else:
        # Invalid data: error handling
        return chain(
            notify_start.si('Invalid data received'),
            save_data.s({'error': 'validation_failed'})
        ).apply_async()


def conditional_chain_example():
    """Different execution paths based on validation"""
    workflow = chain(
        fetch_data.s('https://api.example.com/input'),
        validate_input.s(),
        create_conditional_chain.s()
    )

    result = workflow.apply_async()
    return result


# ============================================================================
# Retry Pattern in Chains
# ============================================================================

@app.task(
    autoretry_for=(Exception,),
    retry_kwargs={'max_retries': 3, 'countdown': 5},
    retry_backoff=True,
    retry_backoff_max=600,
    retry_jitter=True
)
def fetch_with_retry(url: str) -> dict:
    """Fetch data with automatic retries"""
    # Simulated API call
    return {'url': url, 'data': 'fetched_data'}


def retry_chain_example():
    """Chain with retry logic"""
    workflow = chain(
        fetch_with_retry.s('https://api.example.com/unstable'),
        transform_data.s(),
        save_data.s()
    )

    result = workflow.apply_async()
    return result.get(timeout=60)


# ============================================================================
# Usage Examples
# ============================================================================

if __name__ == '__main__':
    # Basic sequential chain
    print("Basic chain:")
    result = basic_chain_example()
    print(f"Result: {result}")

    # Chain with immutable tasks
    print("\nImmutable chain:")
    result = immutable_chain_example()
    print(f"Result: {result}")

    # Partial application
    print("\nPartial application:")
    results = partial_application_example()
    print(f"Results: {results}")

    # Conditional execution
    print("\nConditional chain:")
    result = conditional_chain_example()
    print(f"Result: {result}")
