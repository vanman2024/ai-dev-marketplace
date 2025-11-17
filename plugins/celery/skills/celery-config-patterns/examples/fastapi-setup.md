# FastAPI + Celery Complete Setup Guide

Comprehensive guide for integrating Celery with FastAPI applications.

## Quick Start

```bash
# Install dependencies
pip install celery[redis] fastapi uvicorn

# Create celery_app.py
# Create main.py with FastAPI app
# Start Redis
# Run: celery -A celery_app worker --loglevel=info
# Run: uvicorn main:app --reload
```

## Complete Setup

See Django setup guide for detailed explanations. FastAPI follows similar patterns with async support.

## Key Differences from Django/Flask

1. Lifespan event integration
2. Async task support
3. Pydantic model validation
4. Background task coordination with FastAPI's BackgroundTasks

## FastAPI + Celery Example

```python
# main.py
from fastapi import FastAPI
from celery_app import celery_app

app = FastAPI()

@app.post("/tasks")
async def create_task(data: dict):
    task = process_data.delay(data)
    return {"task_id": task.id}

@app.get("/tasks/{task_id}")
async def get_task(task_id: str):
    from celery.result import AsyncResult
    task = AsyncResult(task_id)
    return {"status": task.status, "result": task.result}
```

For complete patterns, refer to templates/celery-app-fastapi.py
