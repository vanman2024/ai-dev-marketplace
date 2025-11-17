"""
Celery Error Handling in Workflows
Comprehensive error handling patterns for canvas workflows
"""

from celery import Celery, chain, group, chord
from celery.exceptions import SoftTimeLimitExceeded, Retry
from typing import List, Dict, Any, Optional

app = Celery('error_handling_workflows')
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
# Basic Error Callback Pattern
# ============================================================================

@app.task
def risky_task(value: int) -> int:
    """Task that might fail"""
    if value % 3 == 0:
        raise ValueError(f"Cannot process value {value}")
    return value * 2


@app.task
def log_error(request, exc, traceback) -> dict:
    """Error callback to log failures"""
    return {
        'task_id': request.id,
        'task_name': request.task,
        'error_type': type(exc).__name__,
        'error_message': str(exc),
        'args': request.args,
        'kwargs': request.kwargs,
    }


def basic_error_callback_example():
    """Simple error handling with callback"""
    workflow = chain(
        risky_task.s(6),  # Will fail
        risky_task.s()
    ).on_error(log_error.s())

    try:
        result = workflow.apply_async()
        return result.get(timeout=10)
    except Exception as exc:
        return {'error': str(exc)}


# ============================================================================
# Try-Catch Pattern in Tasks
# ============================================================================

@app.task(bind=True)
def safe_processing(self, item: dict) -> dict:
    """Task with internal error handling"""
    try:
        # Risky operation
        if item.get('value', 0) < 0:
            raise ValueError("Negative values not allowed")

        result = item['value'] * 2
        return {'id': item['id'], 'result': result, 'status': 'success'}

    except ValueError as exc:
        # Handle specific error type
        self.update_state(
            state='VALIDATION_ERROR',
            meta={'error': str(exc), 'item': item}
        )
        return {'id': item['id'], 'error': str(exc), 'status': 'validation_failed'}

    except Exception as exc:
        # Handle unexpected errors
        self.update_state(
            state='PROCESSING_ERROR',
            meta={'error': str(exc), 'item': item}
        )
        return {'id': item['id'], 'error': str(exc), 'status': 'error'}


@app.task
def aggregate_with_errors(results: List[dict]) -> dict:
    """Aggregate results including errors"""
    successes = [r for r in results if r.get('status') == 'success']
    failures = [r for r in results if r.get('status') != 'success']

    return {
        'total': len(results),
        'successes': len(successes),
        'failures': len(failures),
        'success_rate': len(successes) / len(results) * 100 if results else 0,
        'failed_items': [f['id'] for f in failures]
    }


def safe_processing_workflow(items: List[dict]):
    """Process items with error capturing"""
    workflow = chord(
        safe_processing.s(item) for item in items
    )(aggregate_with_errors.s())

    return workflow.apply_async()


# ============================================================================
# Retry with Exponential Backoff
# ============================================================================

@app.task(
    bind=True,
    autoretry_for=(ConnectionError, TimeoutError),
    retry_kwargs={'max_retries': 5, 'countdown': 5},
    retry_backoff=True,
    retry_backoff_max=600,
    retry_jitter=True
)
def api_call_with_retry(self, endpoint: str) -> dict:
    """API call with automatic retry"""
    # Simulate API call
    import random
    if random.random() < 0.3:  # 30% failure rate
        raise ConnectionError("API temporarily unavailable")

    return {'endpoint': endpoint, 'status': 'success'}


@app.task(bind=True)
def manual_retry_task(self, item: dict, retry_count: int = 0) -> dict:
    """Task with manual retry logic"""
    max_retries = 3

    try:
        # Risky operation
        if item.get('flaky', False) and retry_count < 2:
            raise ConnectionError("Temporary failure")

        return {'id': item['id'], 'status': 'success', 'retries': retry_count}

    except ConnectionError as exc:
        if retry_count < max_retries:
            # Manual retry with backoff
            raise self.retry(
                exc=exc,
                countdown=2 ** retry_count,  # Exponential backoff
                max_retries=max_retries
            )
        else:
            return {
                'id': item['id'],
                'status': 'failed',
                'error': 'Max retries exceeded',
                'retries': retry_count
            }


# ============================================================================
# Timeout Handling
# ============================================================================

@app.task(bind=True, time_limit=10, soft_time_limit=8)
def task_with_timeout(self, duration: int) -> dict:
    """Task with timeout protection"""
    import time

    try:
        time.sleep(duration)
        return {'duration': duration, 'status': 'completed'}

    except SoftTimeLimitExceeded:
        # Soft timeout - can clean up
        self.update_state(
            state='TIMEOUT',
            meta={'duration': duration, 'timeout': 'soft'}
        )
        return {'duration': duration, 'status': 'soft_timeout'}


@app.task
def handle_timeout_results(results: List[dict]) -> dict:
    """Handle results including timeouts"""
    completed = [r for r in results if r.get('status') == 'completed']
    timeouts = [r for r in results if 'timeout' in r.get('status', '')]

    return {
        'total': len(results),
        'completed': len(completed),
        'timeouts': len(timeouts),
        'timeout_rate': len(timeouts) / len(results) * 100 if results else 0
    }


def timeout_handling_workflow():
    """Workflow with timeout handling"""
    durations = [1, 2, 9, 3, 11, 4]  # Some will timeout

    workflow = chord(
        task_with_timeout.s(d) for d in durations
    )(handle_timeout_results.s())

    return workflow.apply_async()


# ============================================================================
# Chord Error Handling
# ============================================================================

@app.task(ignore_result=False)
def chord_header_task(value: int) -> int:
    """Task in chord header"""
    if value == 5:
        raise ValueError(f"Cannot process {value}")
    return value * 2


@app.task
def chord_callback(results: List[int]) -> dict:
    """Chord callback with error info"""
    return {
        'results': results,
        'count': len(results),
        'sum': sum(results)
    }


@app.task
def chord_error_callback(request, exc, traceback) -> dict:
    """Handle chord errors"""
    return {
        'chord_failed': True,
        'callback_id': request.id,
        'error': str(exc),
        'error_type': type(exc).__name__
    }


def chord_error_handling_example():
    """Chord with error handling"""
    values = range(10)

    workflow = chord(
        chord_header_task.s(v) for v in values
    )(chord_callback.s())

    workflow.on_error(chord_error_callback.s())

    try:
        result = workflow.apply_async()
        return result.get(timeout=30)
    except Exception as exc:
        return {'error': str(exc)}


# ============================================================================
# Partial Failure Recovery
# ============================================================================

@app.task(bind=True, ignore_result=False)
def recoverable_task(self, item: dict) -> dict:
    """Task that can recover from certain errors"""
    try:
        # Primary processing
        if item.get('corrupt'):
            raise ValueError("Corrupted data")

        return {'id': item['id'], 'method': 'primary', 'status': 'success'}

    except ValueError:
        # Try recovery method
        try:
            # Recovery processing
            return {'id': item['id'], 'method': 'recovery', 'status': 'recovered'}
        except Exception as exc:
            return {'id': item['id'], 'method': 'none', 'status': 'failed', 'error': str(exc)}


@app.task
def analyze_recovery(results: List[dict]) -> dict:
    """Analyze recovery statistics"""
    by_method = {}
    for result in results:
        method = result.get('method', 'unknown')
        by_method.setdefault(method, []).append(result)

    return {
        'total': len(results),
        'primary': len(by_method.get('primary', [])),
        'recovered': len(by_method.get('recovery', [])),
        'failed': len(by_method.get('none', [])),
        'recovery_rate': len(by_method.get('recovery', [])) / len(results) * 100 if results else 0
    }


def recovery_workflow(items: List[dict]):
    """Workflow with recovery logic"""
    workflow = chord(
        recoverable_task.s(item) for item in items
    )(analyze_recovery.s())

    return workflow.apply_async()


# ============================================================================
# Circuit Breaker Pattern
# ============================================================================

class CircuitBreaker:
    """Simple circuit breaker implementation"""
    def __init__(self, failure_threshold: int = 5, timeout: int = 60):
        self.failure_count = 0
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.last_failure_time = 0
        self.state = 'CLOSED'  # CLOSED, OPEN, HALF_OPEN

    def is_open(self) -> bool:
        import time
        if self.state == 'OPEN':
            if time.time() - self.last_failure_time > self.timeout:
                self.state = 'HALF_OPEN'
                return False
            return True
        return False

    def record_success(self):
        self.failure_count = 0
        self.state = 'CLOSED'

    def record_failure(self):
        import time
        self.failure_count += 1
        self.last_failure_time = time.time()
        if self.failure_count >= self.failure_threshold:
            self.state = 'OPEN'


circuit_breaker = CircuitBreaker()


@app.task(bind=True)
def task_with_circuit_breaker(self, item: dict) -> dict:
    """Task with circuit breaker protection"""
    if circuit_breaker.is_open():
        return {
            'id': item['id'],
            'status': 'circuit_open',
            'error': 'Circuit breaker is open'
        }

    try:
        # Risky operation
        if item.get('fail'):
            raise ConnectionError("Service unavailable")

        circuit_breaker.record_success()
        return {'id': item['id'], 'status': 'success'}

    except Exception as exc:
        circuit_breaker.record_failure()
        return {
            'id': item['id'],
            'status': 'error',
            'error': str(exc),
            'circuit_state': circuit_breaker.state
        }


# ============================================================================
# Dead Letter Queue Pattern
# ============================================================================

@app.task
def add_to_dead_letter_queue(failed_task: dict) -> dict:
    """Add failed task to DLQ for later processing"""
    # In production, this would write to a database or queue
    return {
        'dlq_entry': True,
        'task_info': failed_task,
        'timestamp': __import__('time').time()
    }


@app.task(bind=True)
def task_with_dlq(self, item: dict) -> dict:
    """Task that sends failures to DLQ"""
    try:
        if item.get('value', 0) < 0:
            raise ValueError("Invalid value")

        return {'id': item['id'], 'status': 'success'}

    except Exception as exc:
        # Send to DLQ instead of failing workflow
        dlq_result = add_to_dead_letter_queue.s({
            'task_id': self.request.id,
            'item': item,
            'error': str(exc)
        }).apply_async().get()

        return {
            'id': item['id'],
            'status': 'dlq',
            'dlq_entry': dlq_result
        }


def dlq_workflow(items: List[dict]):
    """Workflow with dead letter queue"""
    workflow = chord(
        task_with_dlq.s(item) for item in items
    )(aggregate_with_errors.s())

    return workflow.apply_async()


# ============================================================================
# Usage Examples
# ============================================================================

if __name__ == '__main__':
    # Basic error callback
    print("Basic error callback:")
    result = basic_error_callback_example()
    print(f"Result: {result}")

    # Safe processing with error capturing
    print("\nSafe processing:")
    items = [
        {'id': 1, 'value': 10},
        {'id': 2, 'value': -5},
        {'id': 3, 'value': 20},
    ]
    result = safe_processing_workflow(items).get(timeout=30)
    print(f"Aggregate: {result}")

    # Timeout handling
    print("\nTimeout handling:")
    result = timeout_handling_workflow().get(timeout=60)
    print(f"Timeout results: {result}")

    # Recovery pattern
    print("\nRecovery pattern:")
    items = [
        {'id': 1, 'corrupt': False},
        {'id': 2, 'corrupt': True},
        {'id': 3, 'corrupt': False},
    ]
    result = recovery_workflow(items).get(timeout=30)
    print(f"Recovery stats: {result}")
