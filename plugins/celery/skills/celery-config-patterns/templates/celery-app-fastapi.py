"""
FastAPI Celery Application Configuration

This configuration integrates Celery with FastAPI applications,
including support for async operations and lifespan events.

Usage:
    1. Copy this file to your project as celery_app.py
    2. Import in FastAPI app
    3. Run FastAPI: uvicorn main:app --reload
    4. Run Celery: celery -A celery_app worker --loglevel=info
"""

import os
from celery import Celery
from celery.result import AsyncResult

# Get configuration from environment
BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')
RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Create Celery application
celery_app = Celery('fastapi_app')

# Configure Celery
celery_app.conf.update(
    broker_url=BROKER_URL,
    result_backend=RESULT_BACKEND,
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,

    # Task execution settings
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    task_time_limit=300,
    task_soft_time_limit=240,

    # Worker settings
    worker_prefetch_multiplier=4,
    worker_max_tasks_per_child=1000,

    # Result backend settings
    result_expires=3600,
    result_persistent=False,

    # Broker settings
    broker_connection_retry_on_startup=True,
    broker_pool_limit=10,

    # Task discovery
    imports=['tasks'],  # Import tasks from tasks.py
)


# Helper function to get task status
def get_task_info(task_id: str) -> dict:
    """
    Get information about a Celery task.

    Args:
        task_id: Celery task ID

    Returns:
        Dictionary with task status and result
    """
    task_result = AsyncResult(task_id, app=celery_app)

    result = {
        'task_id': task_id,
        'status': task_result.status,
        'ready': task_result.ready(),
    }

    if task_result.ready():
        result['result'] = task_result.result
        result['successful'] = task_result.successful()
        if task_result.failed():
            result['traceback'] = task_result.traceback

    return result


# ============================================================================
# FastAPI Integration Example
# ============================================================================

"""
# main.py

from contextlib import asynccontextmanager
from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from celery_app import celery_app, get_task_info
from tasks import process_data, send_email


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Verify Celery connection
    try:
        celery_app.control.inspect().active()
        print("Celery connection successful")
    except Exception as e:
        print(f"Celery connection failed: {e}")

    yield

    # Shutdown: Clean up if needed
    print("Shutting down...")


app = FastAPI(title="FastAPI + Celery", lifespan=lifespan)


# Request/Response models
class TaskRequest(BaseModel):
    data: dict


class TaskResponse(BaseModel):
    task_id: str
    status: str


class TaskStatusResponse(BaseModel):
    task_id: str
    status: str
    result: dict = None
    ready: bool
    successful: bool = None
    traceback: str = None


# API Endpoints

@app.post("/tasks/process", response_model=TaskResponse)
async def create_task(request: TaskRequest):
    '''Submit a data processing task to Celery'''
    task = process_data.delay(request.data)
    return TaskResponse(task_id=task.id, status="submitted")


@app.get("/tasks/{task_id}", response_model=TaskStatusResponse)
async def get_task_status(task_id: str):
    '''Get the status of a Celery task'''
    try:
        task_info = get_task_info(task_id)
        return TaskStatusResponse(**task_info)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@app.post("/email/send")
async def send_email_endpoint(
    to: str,
    subject: str,
    body: str,
    background_tasks: BackgroundTasks
):
    '''
    Send email asynchronously.

    Note: For simple tasks, FastAPI's BackgroundTasks may be sufficient.
    Use Celery for tasks that need:
    - Retry logic
    - Result persistence
    - Task monitoring
    - Distributed execution
    '''
    # Option 1: FastAPI background task (simple, no persistence)
    # background_tasks.add_task(send_simple_email, to, subject, body)

    # Option 2: Celery task (better for production)
    task = send_email.delay(to, subject, body)

    return {
        "message": "Email queued",
        "task_id": task.id
    }


@app.get("/health")
async def health_check():
    '''Health check endpoint that includes Celery status'''
    try:
        # Check if Celery workers are available
        inspect = celery_app.control.inspect()
        active_workers = inspect.active()

        if not active_workers:
            return JSONResponse(
                status_code=503,
                content={
                    "status": "unhealthy",
                    "celery": "no workers available"
                }
            )

        return {
            "status": "healthy",
            "celery": {
                "workers": len(active_workers),
                "active_tasks": sum(len(tasks) for tasks in active_workers.values())
            }
        }
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "celery": str(e)
            }
        )


# tasks.py

from celery_app import celery_app
import time

@celery_app.task(name='tasks.process_data')
def process_data(data: dict):
    '''Process data asynchronously'''
    # Simulate processing
    time.sleep(2)
    return {
        "status": "completed",
        "processed_data": data,
        "timestamp": time.time()
    }


@celery_app.task(bind=True, max_retries=3, name='tasks.send_email')
def send_email(self, to: str, subject: str, body: str):
    '''Send email with retry logic'''
    try:
        # Email sending logic here
        time.sleep(1)
        return {"status": "sent", "to": to}
    except Exception as exc:
        # Retry with exponential backoff
        raise self.retry(exc=exc, countdown=2 ** self.request.retries)


@celery_app.task(name='tasks.long_running_task')
def long_running_task(duration: int):
    '''Example of a long-running task with progress updates'''
    from celery_app import celery_app

    for i in range(duration):
        time.sleep(1)
        # Update task state with progress
        long_running_task.update_state(
            state='PROGRESS',
            meta={'current': i + 1, 'total': duration}
        )

    return {'status': 'completed', 'duration': duration}


# Run commands:
# FastAPI: uvicorn main:app --reload
# Celery: celery -A celery_app worker --loglevel=info
"""


# ============================================================================
# Configuration File Example
# ============================================================================

"""
# celeryconfig.py

import os

# Broker settings
broker_url = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')
result_backend = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Task settings
task_serializer = 'json'
result_serializer = 'json'
accept_content = ['json']
timezone = 'UTC'
enable_utc = True

# Execution
task_acks_late = True
task_reject_on_worker_lost = True
task_time_limit = 300
task_soft_time_limit = 240

# Worker
worker_prefetch_multiplier = 4
worker_max_tasks_per_child = 1000

# Results
result_expires = 3600
result_persistent = False

# Monitoring
task_track_started = True
task_send_sent_event = True

# Task routing
task_routes = {
    'tasks.process_data': {'queue': 'processing'},
    'tasks.send_email': {'queue': 'emails'},
    'tasks.long_running_task': {'queue': 'long'},
}
"""
