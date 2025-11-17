---
name: task-patterns
description: Production-ready Celery task templates with error handling, retries, rate limiting, time limits, and custom task classes. Use when creating Celery tasks, implementing retry logic, adding rate limiting, setting time limits, building custom task classes, validating task inputs with Pydantic, handling database operations, making API calls, or when user mentions task patterns, retry mechanisms, task templates, error handling, task best practices.
allowed-tools: Bash, Read, Write, Edit
---

# Task Patterns Skill

Production-ready Celery task templates with comprehensive error handling, retry mechanisms, rate limiting, and custom behavior patterns.

## Overview

This skill provides battle-tested templates and patterns for building robust Celery tasks. Each template demonstrates production-ready code with proper error handling, logging, retry logic, and security best practices.

## Core Patterns

### 1. Basic Task Template

**Template**: `templates/basic-task.py`

Simple task with standard error handling and logging.

**Use when**:
- Creating your first Celery task
- Need straightforward task execution
- No complex retry or limiting requirements

**Features**:
- Proper logging setup
- Basic error handling
- Synchronous and asynchronous execution examples
- Clear docstrings

### 2. Retry Task Template

**Template**: `templates/retry-task.py`

Tasks with automatic retry mechanisms and exponential backoff.

**Use when**:
- Calling external APIs that may fail transiently
- Database operations that could timeout
- Network operations prone to connection issues

**Features**:
- Automatic retry with `autoretry_for`
- Exponential backoff with jitter
- Manual retry control
- Fixed delay retries
- Configurable max retries

**Example**: See `examples/task-with-retries.md` for complete implementation guide

### 3. Rate Limited Task Template

**Template**: `templates/rate-limited-task.py`

Tasks with rate limiting to control execution speed.

**Use when**:
- Respecting external API rate limits
- Protecting database from overload
- Controlling resource consumption
- Meeting SLA requirements

**Features**:
- Per-second, per-minute, per-hour limits
- Batch processing with rate control
- Large dataset handling
- Dynamic rate limit adjustment

**Example**: See `examples/rate-limiting.md` for complete guide

### 4. Time Limited Task Template

**Template**: `templates/time-limited-task.py`

Tasks with soft and hard time limits to prevent runaway execution.

**Use when**:
- Long-running operations that could hang
- Operations with external dependencies
- Tasks that must complete within timeframe
- Preventing resource exhaustion

**Features**:
- Soft time limit (catchable)
- Hard time limit (force kill)
- Graceful timeout handling
- Progress saving on timeout
- Combined with retry logic

### 5. Custom Task Class Template

**Template**: `templates/custom-task-class.py`

Custom task base classes with specialized behavior.

**Use when**:
- Need database connection pooling
- Want to cache task results
- Require metrics tracking
- Need shared resources across tasks
- Implementing lifecycle hooks

**Features**:
- Database connection pooling
- Automatic result caching
- Metrics and monitoring
- Resource pool management
- Lifecycle hooks (before_start, on_success, on_failure, on_retry, after_return)

**Example**: See `examples/custom-task-classes.md` for comprehensive guide

### 6. Pydantic Validation Template

**Template**: `templates/pydantic-validation.py`

Type-safe tasks with Pydantic model validation.

**Use when**:
- Need strict input validation
- Want type safety
- Complex nested data structures
- API contract enforcement

**Features**:
- Pydantic models for input validation
- Enum types for constrained values
- Custom validators
- Standardized result format
- Comprehensive error messages

### 7. Database Task Template

**Template**: `templates/database-task.py`

Best practices for database operations in tasks.

**Use when**:
- Performing database queries
- Bulk database operations
- Transactional operations
- Database migrations

**Features**:
- Connection pooling
- Parameterized queries (SQL injection prevention)
- Transaction management
- Bulk insert operations
- Pagination support
- Aggregation queries

### 8. API Task Template

**Template**: `templates/api-task.py`

Best practices for external API calls in tasks.

**Use when**:
- Calling external APIs
- Webhook delivery
- Paginated API fetching
- Batch API calls
- API authentication

**Features**:
- Automatic retry on connection errors
- Rate limiting for API quotas
- Timeout handling
- Authentication patterns (Bearer, API key)
- Pagination support
- Batch processing

## Scripts

### generate-task.sh

**Usage**: `./scripts/generate-task.sh <template_name> <output_file> [task_name]`

Generate new Celery task from template with customizations.

**Available templates**:
- basic-task
- retry-task
- rate-limited-task
- time-limited-task
- custom-task-class
- pydantic-validation
- database-task
- api-task

**Example**:
```bash
./scripts/generate-task.sh retry-task tasks/my_api_call.py fetch_data
```

### test-task.sh

**Usage**: `./scripts/test-task.sh <task_file.py> [task_name]`

Test Celery task by:
1. Validating Python syntax
2. Checking imports
3. Verifying task structure
4. Security scanning
5. Best practices check
6. Optionally running task

**Example**:
```bash
./scripts/test-task.sh templates/retry-task.py fetch_api_data
```

### validate-task.sh

**Usage**: `./scripts/validate-task.sh <task_file.py>`

Comprehensive validation including:
- Required elements (Celery import, app initialization, decorators)
- Best practices (docstrings, type hints, error handling, logging)
- Retry configuration
- Security checks (no hardcoded credentials, SQL injection)
- Performance checks (rate limits, time limits)
- Code quality (examples, configuration)
- Pattern detection

**Example**:
```bash
./scripts/validate-task.sh templates/api-task.py
```

## Usage Examples

### Example 1: Create API Task with Retries

```python
# Use retry-task.py template
from templates.retry_task import fetch_api_data

# Queue task
result = fetch_api_data.delay('https://api.example.com/data')

# Get result
data = result.get(timeout=60)
print(data)
```

### Example 2: Rate-Limited Batch Processing

```python
# Use rate-limited-task.py template
from templates.rate_limited_task import api_call_rate_limited

# Process 100 items at 10/minute rate
for i in range(100):
    api_call_rate_limited.delay(f'/endpoint/{i}')

# Celery automatically enforces rate limit
```

### Example 3: Database Operations with Connection Pooling

```python
# Use database-task.py template
from templates.database_task import insert_record, bulk_insert

# Single insert
result1 = insert_record.delay('users', {
    'name': 'John Doe',
    'email': 'john@example.com'
})

# Bulk insert
records = [
    {'name': 'Jane', 'email': 'jane@example.com'},
    {'name': 'Bob', 'email': 'bob@example.com'},
]
result2 = bulk_insert.delay('users', records)
```

### Example 4: Custom Task with Metrics

```python
# Use custom-task-class.py template
from templates.custom_task_class import monitored_task

# Automatic metrics tracking
result = monitored_task.delay(123)

# Metrics logged automatically:
# - Start time
# - Duration
# - Success/failure
# - Arguments
```

### Example 5: Type-Safe Task with Pydantic

```python
# Use pydantic-validation.py template
from templates.pydantic_validation import process_user

# Valid data
user_data = {
    'user_id': 123,
    'email': 'user@example.com',
    'username': 'john_doe',
    'age': 30,
    'tags': ['premium']
}
result = process_user.delay(user_data)

# Invalid data returns structured error
invalid_data = {
    'user_id': -1,  # Invalid
    'email': 'not-email',  # Invalid
}
result = process_user.delay(invalid_data)
# Returns: {'status': 'error', 'errors': [...]}
```

## Best Practices

### 1. Always Use Placeholders for Credentials

```python
# ✅ CORRECT
api_key = os.getenv('API_KEY', 'your_api_key_here')

# ❌ WRONG
api_key = 'sk-abc123xyz456'
```

### 2. Set Appropriate Timeouts

```python
# ✅ CORRECT
response = requests.get(url, timeout=30)

# ❌ WRONG
response = requests.get(url)  # Can hang forever
```

### 3. Use Parameterized Queries

```python
# ✅ CORRECT
db.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# ❌ WRONG
db.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

### 4. Combine Retry with Rate Limiting

```python
@app.task(
    bind=True,
    autoretry_for=(RequestException,),
    retry_backoff=True,
    rate_limit='10/m'
)
def robust_api_call(self, url: str):
    """Retries on failure, respects rate limits."""
    pass
```

### 5. Log All Important Events

```python
@app.task(bind=True)
def well_logged_task(self, item_id: int):
    logger.info(f"Starting task for item {item_id}")
    try:
        result = process(item_id)
        logger.info(f"Successfully processed {item_id}")
        return result
    except Exception as exc:
        logger.error(f"Failed to process {item_id}: {exc}")
        raise
```

## Security Compliance

This skill follows strict security rules:
- All templates use placeholders for credentials
- No real API keys, passwords, or secrets
- Environment variable references in all code
- Parameterized queries to prevent SQL injection
- Security validation in test scripts

## Pattern Selection Guide

**Choose basic-task.py when**:
- Simple, straightforward operations
- No external dependencies
- Low failure risk

**Choose retry-task.py when**:
- External API calls
- Network operations
- Transient failures expected

**Choose rate-limited-task.py when**:
- API rate limits exist
- Need to control execution speed
- Protecting resources from overload

**Choose time-limited-task.py when**:
- Long-running operations
- Risk of hanging
- Need guaranteed completion time

**Choose custom-task-class.py when**:
- Need resource pooling
- Want lifecycle hooks
- Shared logic across tasks
- Metrics tracking required

**Choose pydantic-validation.py when**:
- Complex input validation needed
- Type safety important
- API contract enforcement
- Clear error messages required

**Choose database-task.py when**:
- Database operations
- Need connection pooling
- Transactional operations
- Bulk processing

**Choose api-task.py when**:
- External API integration
- Webhook delivery
- Authentication required
- Pagination needed

## Testing Tasks

### Test Individual Task

```bash
# Validate task structure
./scripts/validate-task.sh templates/retry-task.py

# Test task execution
./scripts/test-task.sh templates/retry-task.py fetch_api_data
```

### Run with Celery Worker

```bash
# Start worker
celery -A tasks worker --loglevel=info

# Execute tasks
python3 templates/retry-task.py
```

## Common Patterns

### Pattern: Retry with Backoff

```python
@app.task(
    bind=True,
    autoretry_for=(RequestException,),
    retry_backoff=True,
    retry_jitter=True,
    max_retries=5
)
```

### Pattern: Rate + Time Limits

```python
@app.task(
    rate_limit='10/m',
    soft_time_limit=60,
    time_limit=120
)
```

### Pattern: Validation + Retry

```python
@app.task(
    bind=True,
    autoretry_for=(ValidationError, RequestException),
    retry_backoff=True,
    max_retries=3
)
def validated_api_task(self, request: dict):
    # Validate with Pydantic
    req = ApiRequest(**request)
    # Make API call with retry
    return make_call(req.url)
```

## Quick Reference

### Task Decorator Options

```python
@app.task(
    bind=True,                    # Access self (required for retry)
    base=CustomTask,              # Custom task class
    autoretry_for=(Exception,),   # Exceptions to retry
    retry_backoff=True,           # Exponential backoff
    retry_backoff_max=600,        # Max backoff seconds
    retry_jitter=True,            # Add randomness
    max_retries=5,                # Max attempts
    default_retry_delay=10,       # Default delay
    rate_limit='10/m',            # Rate limit
    soft_time_limit=60,           # Soft timeout (catchable)
    time_limit=120,               # Hard timeout (kills task)
    ignore_result=False,          # Store result
    priority=5                    # Task priority (0-9)
)
```

### Retry Syntax

```python
# Automatic
autoretry_for=(RequestException, Timeout)

# Manual
raise self.retry(exc=exc, countdown=60)
```

### Rate Limit Syntax

```python
rate_limit='10/s'   # 10 per second
rate_limit='100/m'  # 100 per minute
rate_limit='1000/h' # 1000 per hour
```

## References

- [Celery Tasks Documentation](https://docs.celeryq.dev/en/stable/userguide/tasks.html)
- `examples/task-with-retries.md` - Complete retry guide
- `examples/rate-limiting.md` - Complete rate limiting guide
- `examples/custom-task-classes.md` - Custom class guide

## Validation

Always run validation before committing:

```bash
./scripts/validate-task.sh your-task.py
```

Validation checks:
- ✅ Required imports and setup
- ✅ Task decorators present
- ✅ Docstrings and type hints
- ✅ Error handling
- ✅ Security (no hardcoded credentials)
- ✅ Best practices compliance
