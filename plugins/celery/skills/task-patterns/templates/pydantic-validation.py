"""Celery Tasks with Pydantic Validation

Demonstrates type-safe tasks using Pydantic models for input validation.
"""
from celery import Celery
from celery.utils.log import get_task_logger
from pydantic import BaseModel, Field, validator, ValidationError
from typing import List, Optional
from datetime import datetime
from enum import Enum

logger = get_task_logger(__name__)

app = Celery('tasks', broker='redis://localhost:6379/0')


# Pydantic Models
class Priority(str, Enum):
    """Task priority levels."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"


class UserData(BaseModel):
    """User data model with validation."""
    user_id: int = Field(..., gt=0, description="User ID must be positive")
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    username: str = Field(..., min_length=3, max_length=50)
    age: Optional[int] = Field(None, ge=0, le=150)
    tags: List[str] = Field(default_factory=list)

    @validator('username')
    def username_alphanumeric(cls, v):
        """Ensure username is alphanumeric."""
        if not v.replace('_', '').replace('-', '').isalnum():
            raise ValueError('Username must be alphanumeric (with _ or -)')
        return v

    class Config:
        """Pydantic config."""
        use_enum_values = True


class ProcessingConfig(BaseModel):
    """Task processing configuration."""
    batch_size: int = Field(100, gt=0, le=1000)
    timeout: int = Field(60, gt=0, le=3600)
    retry_count: int = Field(3, ge=0, le=10)
    priority: Priority = Priority.MEDIUM
    notify_on_complete: bool = False
    metadata: dict = Field(default_factory=dict)


class TaskResult(BaseModel):
    """Standardized task result."""
    status: str
    message: str
    data: dict = Field(default_factory=dict)
    processed_at: datetime = Field(default_factory=datetime.utcnow)
    errors: List[str] = Field(default_factory=list)


@app.task(bind=True)
def process_user(self, user_data: dict) -> dict:
    """
    Process user data with Pydantic validation.

    Args:
        user_data: Dictionary matching UserData model

    Returns:
        dict: Processing result

    Example:
        result = process_user.delay({
            'user_id': 123,
            'email': 'user@example.com',
            'username': 'john_doe',
            'age': 30,
            'tags': ['premium', 'verified']
        })

    Raises:
        ValidationError: If user_data doesn't match schema
    """
    try:
        # Validate input using Pydantic
        user = UserData(**user_data)
        logger.info(f"Processing user {user.user_id}: {user.username}")

        # Your processing logic here
        result = TaskResult(
            status='success',
            message=f'User {user.username} processed successfully',
            data={
                'user_id': user.user_id,
                'email': user.email,
                'tags_count': len(user.tags)
            }
        )

        # Return validated result as dict
        return result.dict()

    except ValidationError as exc:
        logger.error(f"Validation error: {exc}")

        # Return structured error
        result = TaskResult(
            status='error',
            message='Validation failed',
            errors=[str(err) for err in exc.errors()]
        )
        return result.dict()


@app.task(bind=True)
def batch_process(self, items: List[dict], config: dict) -> dict:
    """
    Process batch of items with validated configuration.

    Args:
        items: List of items to process
        config: Processing configuration (matches ProcessingConfig model)

    Returns:
        dict: Batch processing results

    Example:
        result = batch_process.delay(
            items=[{'id': 1}, {'id': 2}, {'id': 3}],
            config={
                'batch_size': 100,
                'timeout': 120,
                'priority': 'high',
                'notify_on_complete': True
            }
        )
    """
    try:
        # Validate config
        cfg = ProcessingConfig(**config)
        logger.info(
            f"Processing {len(items)} items with batch_size={cfg.batch_size}, "
            f"priority={cfg.priority}"
        )

        processed_items = []
        failed_items = []

        # Process items in batches
        for i in range(0, len(items), cfg.batch_size):
            batch = items[i:i + cfg.batch_size]

            for item in batch:
                try:
                    # Your processing logic here
                    processed_items.append(item)
                except Exception as exc:
                    logger.error(f"Failed to process item {item}: {exc}")
                    failed_items.append({'item': item, 'error': str(exc)})

        # Build result
        result = TaskResult(
            status='completed' if not failed_items else 'partial',
            message=f'Processed {len(processed_items)}/{len(items)} items',
            data={
                'total_items': len(items),
                'processed': len(processed_items),
                'failed': len(failed_items),
                'failed_items': failed_items[:10],  # First 10 failures
                'config': cfg.dict()
            }
        )

        return result.dict()

    except ValidationError as exc:
        logger.error(f"Configuration validation error: {exc}")

        result = TaskResult(
            status='error',
            message='Invalid configuration',
            errors=[str(err) for err in exc.errors()]
        )
        return result.dict()


class DataTransformRequest(BaseModel):
    """Data transformation request."""
    source_format: str = Field(..., regex=r'^(json|csv|xml|yaml)$')
    target_format: str = Field(..., regex=r'^(json|csv|xml|yaml)$')
    data: str = Field(..., min_length=1)
    options: dict = Field(default_factory=dict)

    @validator('target_format')
    def different_formats(cls, v, values):
        """Ensure source and target formats are different."""
        if 'source_format' in values and v == values['source_format']:
            raise ValueError('Target format must differ from source format')
        return v


@app.task
def transform_data(request: dict) -> dict:
    """
    Transform data between formats with validation.

    Args:
        request: Transformation request (matches DataTransformRequest model)

    Returns:
        dict: Transformation result

    Example:
        result = transform_data.delay({
            'source_format': 'json',
            'target_format': 'csv',
            'data': '{"key": "value"}',
            'options': {'delimiter': ','}
        })
    """
    try:
        # Validate request
        req = DataTransformRequest(**request)
        logger.info(f"Transforming data from {req.source_format} to {req.target_format}")

        # Your transformation logic here
        transformed_data = f"Transformed from {req.source_format} to {req.target_format}"

        result = TaskResult(
            status='success',
            message='Data transformed successfully',
            data={
                'source_format': req.source_format,
                'target_format': req.target_format,
                'output': transformed_data
            }
        )

        return result.dict()

    except ValidationError as exc:
        logger.error(f"Request validation error: {exc}")

        result = TaskResult(
            status='error',
            message='Invalid transformation request',
            errors=[str(err) for err in exc.errors()]
        )
        return result.dict()


class ApiRequest(BaseModel):
    """API request with validation."""
    url: str = Field(..., regex=r'^https?://')
    method: str = Field('GET', regex=r'^(GET|POST|PUT|DELETE|PATCH)$')
    headers: dict = Field(default_factory=dict)
    body: Optional[dict] = None
    timeout: int = Field(30, gt=0, le=300)

    @validator('url')
    def validate_url_scheme(cls, v):
        """Ensure URL uses HTTPS in production."""
        import os
        if os.getenv('ENV') == 'production' and not v.startswith('https://'):
            raise ValueError('Production URLs must use HTTPS')
        return v


@app.task(bind=True, autoretry_for=(Exception,), max_retries=3)
def make_api_call(self, request: dict) -> dict:
    """
    Make validated API call.

    Args:
        request: API request (matches ApiRequest model)

    Returns:
        dict: API response

    Example:
        result = make_api_call.delay({
            'url': 'https://api.example.com/data',
            'method': 'POST',
            'body': {'key': 'value'},
            'timeout': 60
        })
    """
    import requests

    try:
        # Validate request
        api_req = ApiRequest(**request)
        logger.info(f"Making {api_req.method} request to {api_req.url}")

        # Make API call
        response = requests.request(
            method=api_req.method,
            url=api_req.url,
            headers=api_req.headers,
            json=api_req.body,
            timeout=api_req.timeout
        )
        response.raise_for_status()

        result = TaskResult(
            status='success',
            message='API call successful',
            data={
                'url': api_req.url,
                'method': api_req.method,
                'status_code': response.status_code,
                'response': response.json() if response.content else {}
            }
        )

        return result.dict()

    except ValidationError as exc:
        logger.error(f"Request validation error: {exc}")

        result = TaskResult(
            status='error',
            message='Invalid API request',
            errors=[str(err) for err in exc.errors()]
        )
        return result.dict()

    except requests.RequestException as exc:
        logger.error(f"API call failed: {exc}")
        raise  # Let autoretry_for handle the retry


# Example usage
if __name__ == '__main__':
    # Valid user data
    valid_user = {
        'user_id': 123,
        'email': 'user@example.com',
        'username': 'john_doe',
        'age': 30,
        'tags': ['premium', 'verified']
    }
    result1 = process_user.delay(valid_user)
    print(f"Process User Task ID: {result1.id}")

    # Invalid user data (will fail validation)
    invalid_user = {
        'user_id': -1,  # Invalid: must be positive
        'email': 'not-an-email',  # Invalid: bad format
        'username': 'ab',  # Invalid: too short
    }
    result2 = process_user.delay(invalid_user)
    print(f"Invalid User Task ID: {result2.id}")

    # Batch processing
    items = [{'id': i} for i in range(50)]
    config = {
        'batch_size': 10,
        'timeout': 120,
        'priority': 'high',
        'notify_on_complete': True
    }
    result3 = batch_process.delay(items, config)
    print(f"Batch Process Task ID: {result3.id}")

    # Data transformation
    transform_req = {
        'source_format': 'json',
        'target_format': 'csv',
        'data': '{"key": "value"}',
        'options': {'delimiter': ','}
    }
    result4 = transform_data.delay(transform_req)
    print(f"Transform Task ID: {result4.id}")

    # API call
    api_req = {
        'url': 'https://api.example.com/data',
        'method': 'GET',
        'timeout': 30
    }
    result5 = make_api_call.delay(api_req)
    print(f"API Call Task ID: {result5.id}")
