# FastAPI + Celery Async Integration Guide

Complete guide for integrating Celery with FastAPI, including async patterns.

## Why FastAPI + Celery?

- FastAPI: High-performance async web framework
- Celery: Reliable distributed task queue
- Complement each other perfectly:
  - FastAPI BackgroundTasks: Quick operations (<30s)
  - Celery: Long-running, distributed, retriable tasks

## Project Structure

```
app/
├── main.py              # FastAPI application
├── celery_app.py        # Celery configuration
├── tasks.py             # Task definitions
├── routers/
│   └── api.py           # API routes
├── models.py            # Pydantic models
└── config.py            # Settings
```

## Step 1: Install Dependencies

```bash
pip install fastapi uvicorn celery redis pydantic[email]
```

## Step 2: Create Configuration

**File:** `app/config.py`

```python
from pydantic import BaseSettings

class Settings(BaseSettings):
    app_name: str = "FastAPI + Celery"

    # Celery
    celery_broker_url: str = "redis://localhost:6379/0"
    celery_result_backend: str = "redis://localhost:6379/0"

    # Database (optional)
    database_url: str = "postgresql://your_database_url_here"

    class Config:
        env_file = ".env"

settings = Settings()
```

## Step 3: Create Celery App

**File:** `app/celery_app.py`

```python
from celery import Celery
from .config import settings

celery = Celery(
    "fastapi_app",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend
)

celery.conf.update(
    task_serializer='json',
    result_serializer='json',
    accept_content=['json'],
    timezone='UTC',
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,
    task_soft_time_limit=25 * 60,
)
```

## Step 4: Create Tasks

**File:** `app/tasks.py`

```python
from celery import current_task
from .celery_app import celery
import asyncio
import time

# Sync task
@celery.task
def process_data(data: dict):
    """Synchronous task"""
    time.sleep(5)
    return {"processed": data, "status": "complete"}

# Async task (Celery 5.2+)
@celery.task
async def async_process_data(data: dict):
    """Async task - can use await"""
    await asyncio.sleep(5)
    return {"processed": data, "async": True}

# Task with progress
@celery.task(bind=True)
def generate_report(self, user_id: int):
    """Report generation with progress updates"""
    total_steps = 100

    for i in range(total_steps):
        time.sleep(0.1)
        self.update_state(
            state='PROGRESS',
            meta={'current': i + 1, 'total': total_steps}
        )

    return {
        'user_id': user_id,
        'report_url': f'/reports/{user_id}.pdf',
        'status': 'complete'
    }

# Task with retry
@celery.task(bind=True, max_retries=3)
def send_email(self, recipient: str, subject: str, body: str):
    """Send email with retry"""
    try:
        # Email sending logic
        time.sleep(2)
        return f"Email sent to {recipient}"
    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)
```

## Step 5: Create Pydantic Models

**File:** `app/models.py`

```python
from pydantic import BaseModel, EmailStr

class TaskRequest(BaseModel):
    data: dict

class EmailRequest(BaseModel):
    to: EmailStr
    subject: str
    body: str

class TaskResponse(BaseModel):
    task_id: str
    status: str
    message: str

class TaskStatusResponse(BaseModel):
    task_id: str
    status: str
    result: dict | None = None
    progress: dict | None = None
```

## Step 6: Create FastAPI Application

**File:** `app/main.py`

```python
from fastapi import FastAPI, BackgroundTasks, HTTPException
from celery.result import AsyncResult
from .celery_app import celery
from .tasks import process_data, async_process_data, generate_report, send_email
from .models import TaskRequest, EmailRequest, TaskResponse, TaskStatusResponse
from .config import settings

app = FastAPI(title=settings.app_name)

# Health check
@app.get("/")
async def root():
    return {"status": "ok", "app": settings.app_name}

# Submit Celery task
@app.post("/api/process", response_model=TaskResponse)
async def submit_task(request: TaskRequest):
    """Submit data processing task to Celery"""
    task = process_data.delay(request.data)
    return TaskResponse(
        task_id=task.id,
        status="queued",
        message=f"Task submitted. Check status at /api/task/{task.id}"
    )

# Submit async task
@app.post("/api/async-process", response_model=TaskResponse)
async def submit_async_task(request: TaskRequest):
    """Submit async task"""
    task = async_process_data.delay(request.data)
    return TaskResponse(
        task_id=task.id,
        status="queued",
        message="Async task submitted"
    )

# Get task status
@app.get("/api/task/{task_id}", response_model=TaskStatusResponse)
async def get_task_status(task_id: str):
    """Get Celery task status"""
    task_result = AsyncResult(task_id, app=celery)

    response = TaskStatusResponse(
        task_id=task_id,
        status=task_result.state.lower()
    )

    if task_result.state == 'PENDING':
        response.result = {"message": "Task pending"}
    elif task_result.state == 'PROGRESS':
        response.progress = task_result.info
    elif task_result.state == 'SUCCESS':
        response.result = task_result.result
    elif task_result.state == 'FAILURE':
        response.result = {"error": str(task_result.info)}

    return response

# Generate report
@app.post("/api/report/{user_id}", response_model=TaskResponse)
async def create_report(user_id: int):
    """Generate report with progress tracking"""
    task = generate_report.delay(user_id)
    return TaskResponse(
        task_id=task.id,
        status="processing",
        message="Report generation started"
    )

# Send email
@app.post("/api/email", response_model=TaskResponse)
async def send_email_endpoint(request: EmailRequest):
    """Send email via Celery"""
    task = send_email.delay(request.to, request.subject, request.body)
    return TaskResponse(
        task_id=task.id,
        status="queued",
        message="Email queued"
    )

# FastAPI BackgroundTasks example
@app.post("/api/quick-log")
async def quick_log(request: TaskRequest, background_tasks: BackgroundTasks):
    """Use FastAPI BackgroundTasks for quick operations"""
    background_tasks.add_task(log_request, request.data)
    return {"status": "logged", "message": "Quick logging completed"}

def log_request(data: dict):
    """Quick logging function"""
    print(f"Request logged: {data}")

# Combining both
@app.post("/api/combined")
async def combined_tasks(
    request: TaskRequest,
    background_tasks: BackgroundTasks
):
    """
    Use both BackgroundTasks (quick) and Celery (heavy)
    """
    # Quick logging (BackgroundTasks)
    background_tasks.add_task(log_request, request.data)

    # Heavy processing (Celery)
    task = process_data.delay(request.data)

    return {
        "task_id": task.id,
        "status": "Processing started",
        "logged": True
    }
```

## Step 7: Run Application

### Terminal 1: FastAPI
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Terminal 2: Celery Worker
```bash
celery -A app.celery_app.celery worker -l info
```

### Terminal 3: Monitor (Optional)
```bash
celery -A app.celery_app.celery flower
```

## Testing Endpoints

```bash
# Submit task
curl -X POST http://localhost:8000/api/process \
  -H "Content-Type: application/json" \
  -d '{"data": {"key": "value"}}'

# Check status
curl http://localhost:8000/api/task/{task_id}

# Generate report
curl -X POST http://localhost:8000/api/report/123

# Send email
curl -X POST http://localhost:8000/api/email \
  -H "Content-Type: application/json" \
  -d '{"to": "user@example.com", "subject": "Test", "body": "Hello"}'
```

## Advanced Patterns

### Webhook Callbacks

```python
@celery.task(bind=True)
def long_task(self, webhook_url: str):
    """Task that posts result to webhook"""
    import httpx

    # Do work
    result = {"status": "complete"}

    # Post to webhook
    async with httpx.AsyncClient() as client:
        await client.post(webhook_url, json=result)

    return result

@app.post("/api/task-with-webhook")
async def task_with_webhook(request: TaskRequest, webhook_url: str):
    task = long_task.delay(webhook_url)
    return {"task_id": task.id}
```

### Task Chaining

```python
from celery import chain

@app.post("/api/workflow")
async def workflow(request: TaskRequest):
    """Chain multiple tasks"""
    workflow = chain(
        step1.s(request.data),
        step2.s(),
        step3.s()
    )
    result = workflow.apply_async()
    return {"workflow_id": result.id}
```

### SSE for Real-Time Updates

```python
from fastapi.responses import StreamingResponse
from sse_starlette.sse import EventSourceResponse

@app.get("/api/task/{task_id}/stream")
async def stream_task_status(task_id: str):
    """Stream task progress via SSE"""
    async def event_generator():
        task_result = AsyncResult(task_id, app=celery)

        while not task_result.ready():
            if task_result.state == 'PROGRESS':
                yield {
                    "event": "progress",
                    "data": str(task_result.info)
                }
            await asyncio.sleep(1)

        yield {
            "event": "complete",
            "data": str(task_result.result)
        }

    return EventSourceResponse(event_generator())
```

## Production Deployment

### Docker Compose

```yaml
version: '3.8'
services:
  redis:
    image: redis:alpine

  fastapi:
    build: .
    command: uvicorn app.main:app --host 0.0.0.0
    ports:
      - "8000:8000"
    depends_on:
      - redis

  celery:
    build: .
    command: celery -A app.celery_app.celery worker -l info
    depends_on:
      - redis

  flower:
    build: .
    command: celery -A app.celery_app.celery flower
    ports:
      - "5555:5555"
    depends_on:
      - redis
```

## Resources

- See: `templates/fastapi-integration/` for complete files
- See: `templates/fastapi-background.py` for decision guide
- FastAPI docs: https://fastapi.tiangolo.com/
- Celery docs: https://docs.celeryproject.org/
