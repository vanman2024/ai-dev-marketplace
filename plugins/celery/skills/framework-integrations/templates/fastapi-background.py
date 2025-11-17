"""
FastAPI + Celery: BackgroundTasks vs Celery comparison and integration

This template shows when to use FastAPI BackgroundTasks vs Celery,
and how to integrate both in a FastAPI application.
"""

from fastapi import FastAPI, BackgroundTasks, Depends, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, EmailStr
from celery import Celery
from celery.result import AsyncResult
import asyncio
import time
from typing import Optional


# ═══════════════════════════════════════════════════════════════
# Setup
# ═══════════════════════════════════════════════════════════════

app = FastAPI(title="FastAPI + Celery Integration")

# Celery configuration
celery = Celery(
    "fastapi_app",
    broker="redis://your_redis_url_here",
    backend="redis://your_redis_url_here"
)

celery.conf.update(
    task_serializer='json',
    result_serializer='json',
    accept_content=['json'],
    timezone='UTC',
    enable_utc=True,
)


# ═══════════════════════════════════════════════════════════════
# Models
# ═══════════════════════════════════════════════════════════════

class EmailRequest(BaseModel):
    to: EmailStr
    subject: str
    body: str


class ReportRequest(BaseModel):
    user_id: int
    report_type: str
    email: EmailStr


class TaskResponse(BaseModel):
    task_id: str
    status: str
    message: str


# ═══════════════════════════════════════════════════════════════
# Decision Matrix: BackgroundTasks vs Celery
# ═══════════════════════════════════════════════════════════════

"""
Use FastAPI BackgroundTasks when:
✅ Task completes in <30 seconds
✅ Task is fire-and-forget (no result needed)
✅ Task doesn't need retries
✅ Task runs only once (not recurring)
✅ OK if task fails when server restarts
✅ Examples: Logging, simple notifications, cache cleanup

Use Celery when:
✅ Task takes >30 seconds
✅ Need result/status tracking
✅ Need automatic retries on failure
✅ Need scheduled/periodic tasks
✅ Need distributed workers
✅ Task must survive server restarts
✅ Examples: Email campaigns, video processing, report generation
"""


# ═══════════════════════════════════════════════════════════════
# FastAPI BackgroundTasks Examples
# ═══════════════════════════════════════════════════════════════

def log_request(endpoint: str, user_id: int):
    """Simple logging - perfect for BackgroundTasks"""
    time.sleep(0.1)  # Simulate logging delay
    print(f"User {user_id} accessed {endpoint}")


async def send_simple_notification(email: str, message: str):
    """Async notification - BackgroundTasks can handle async"""
    await asyncio.sleep(0.5)  # Simulate async operation
    print(f"Notification sent to {email}: {message}")


@app.post("/api/quick-action")
async def quick_action(
    user_id: int,
    background_tasks: BackgroundTasks
):
    """
    ✅ Use BackgroundTasks for quick operations
    Good for: logging, simple notifications
    """
    # Do main work
    result = {"status": "success", "user_id": user_id}

    # Add background tasks (runs after response sent)
    background_tasks.add_task(log_request, "/api/quick-action", user_id)
    background_tasks.add_task(
        send_simple_notification,
        "user@example.com",
        "Action completed"
    )

    return result


@app.post("/api/cache-warmup")
async def cache_warmup(background_tasks: BackgroundTasks):
    """
    ✅ Use BackgroundTasks for cache operations
    """
    def warm_cache():
        time.sleep(2)  # Simulate cache warming
        print("Cache warmed up")

    background_tasks.add_task(warm_cache)
    return {"status": "Cache warming started"}


# ═══════════════════════════════════════════════════════════════
# Celery Task Examples
# ═══════════════════════════════════════════════════════════════

@celery.task(bind=True, max_retries=3)
def send_bulk_emails(self, email_list: list, subject: str, body: str):
    """
    ✅ Use Celery for long-running, retriable tasks
    Good for: bulk operations, email campaigns
    """
    try:
        for email in email_list:
            time.sleep(1)  # Simulate email sending
            print(f"Sent email to {email}")

        return {"sent": len(email_list), "status": "complete"}

    except Exception as exc:
        # Retry with exponential backoff
        raise self.retry(exc=exc, countdown=60 * (2 ** self.request.retries))


@celery.task(bind=True)
def generate_report(self, user_id: int, report_type: str):
    """
    ✅ Use Celery for heavy computation
    Good for: reports, data processing, video encoding
    """
    # Simulate heavy computation
    time.sleep(10)

    # Update progress
    self.update_state(
        state='PROGRESS',
        meta={'current': 50, 'total': 100}
    )

    time.sleep(10)

    return {
        "user_id": user_id,
        "report_type": report_type,
        "url": f"/reports/{user_id}_{report_type}.pdf",
        "status": "complete"
    }


@celery.task
def process_uploaded_file(file_path: str, user_id: int):
    """
    ✅ Use Celery for file processing
    Good for: image processing, video encoding, data import
    """
    time.sleep(5)  # Simulate processing
    return {
        "file_path": file_path,
        "user_id": user_id,
        "processed": True
    }


# ═══════════════════════════════════════════════════════════════
# Celery API Endpoints
# ═══════════════════════════════════════════════════════════════

@app.post("/api/send-bulk-email", response_model=TaskResponse)
async def send_bulk_email_endpoint(emails: list[EmailStr], subject: str, body: str):
    """
    ✅ Use Celery for bulk operations
    Returns task ID for status checking
    """
    task = send_bulk_emails.delay(emails, subject, body)

    return TaskResponse(
        task_id=task.id,
        status="queued",
        message=f"Bulk email task queued. Check status at /api/task/{task.id}"
    )


@app.post("/api/generate-report", response_model=TaskResponse)
async def generate_report_endpoint(request: ReportRequest):
    """
    ✅ Use Celery for long-running tasks
    """
    task = generate_report.delay(request.user_id, request.report_type)

    return TaskResponse(
        task_id=task.id,
        status="processing",
        message=f"Report generation started. Check status at /api/task/{task.id}"
    )


@app.get("/api/task/{task_id}")
async def get_task_status(task_id: str):
    """
    Get Celery task status and result
    """
    task_result = AsyncResult(task_id, app=celery)

    if task_result.state == 'PENDING':
        return {
            "task_id": task_id,
            "status": "pending",
            "message": "Task is waiting in queue"
        }

    elif task_result.state == 'PROGRESS':
        return {
            "task_id": task_id,
            "status": "processing",
            "progress": task_result.info
        }

    elif task_result.state == 'SUCCESS':
        return {
            "task_id": task_id,
            "status": "complete",
            "result": task_result.result
        }

    elif task_result.state == 'FAILURE':
        return {
            "task_id": task_id,
            "status": "failed",
            "error": str(task_result.info)
        }

    else:
        return {
            "task_id": task_id,
            "status": task_result.state.lower()
        }


# ═══════════════════════════════════════════════════════════════
# Combining BackgroundTasks and Celery
# ═══════════════════════════════════════════════════════════════

@app.post("/api/process-order")
async def process_order(
    order_id: int,
    user_email: EmailStr,
    background_tasks: BackgroundTasks
):
    """
    ✅ BEST PRACTICE: Use both appropriately
    - BackgroundTasks: Quick logging
    - Celery: Heavy processing, retriable operations
    """
    # Quick logging (BackgroundTasks)
    background_tasks.add_task(log_request, "/api/process-order", order_id)

    # Heavy processing (Celery)
    task = process_order_task.delay(order_id)

    # Quick notification (BackgroundTasks)
    background_tasks.add_task(
        send_simple_notification,
        user_email,
        f"Order {order_id} is being processed"
    )

    return {
        "order_id": order_id,
        "task_id": task.id,
        "message": "Order processing started"
    }


@celery.task(bind=True, max_retries=3)
def process_order_task(self, order_id: int):
    """Process order with Celery for reliability"""
    try:
        # Payment processing
        time.sleep(2)
        self.update_state(state='PROGRESS', meta={'step': 'payment'})

        # Inventory update
        time.sleep(2)
        self.update_state(state='PROGRESS', meta={'step': 'inventory'})

        # Shipping
        time.sleep(2)
        self.update_state(state='PROGRESS', meta={'step': 'shipping'})

        return {"order_id": order_id, "status": "complete"}

    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)


# ═══════════════════════════════════════════════════════════════
# Async Celery Tasks (Celery 5.2+)
# ═══════════════════════════════════════════════════════════════

@celery.task
async def async_api_call(url: str):
    """
    ✅ Celery supports async tasks
    Good for: API calls, async I/O operations
    """
    import httpx

    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        return response.json()


@app.post("/api/fetch-external-data")
async def fetch_external_data(url: str):
    """
    Use async Celery task for I/O-bound operations
    """
    task = async_api_call.delay(url)

    return TaskResponse(
        task_id=task.id,
        status="queued",
        message="API call queued"
    )


# ═══════════════════════════════════════════════════════════════
# Error Handling Patterns
# ═══════════════════════════════════════════════════════════════

@celery.task(bind=True, autoretry_for=(Exception,), retry_kwargs={'max_retries': 5})
def reliable_task(self, data: dict):
    """
    ✅ Automatic retries for transient failures
    """
    # Task will automatically retry on any exception
    time.sleep(2)
    return {"processed": True, "data": data}


@app.post("/api/reliable-process")
async def reliable_process(data: dict):
    """
    Submit task with automatic retry handling
    """
    task = reliable_task.delay(data)

    return TaskResponse(
        task_id=task.id,
        status="queued",
        message="Task queued with automatic retries"
    )


# ═══════════════════════════════════════════════════════════════
# Configuration Best Practices
# ═══════════════════════════════════════════════════════════════

"""
# settings.py or config.py

from pydantic import BaseSettings

class Settings(BaseSettings):
    # Redis for Celery
    celery_broker_url: str = "redis://your_redis_url_here"
    celery_result_backend: str = "redis://your_redis_url_here"

    # FastAPI
    api_title: str = "My API"
    debug: bool = False

    # Email (if using)
    smtp_host: str = "smtp.example.com"
    smtp_port: int = 587
    smtp_user: str = "your_smtp_user_here"
    smtp_password: str = "your_smtp_password_here"

    class Config:
        env_file = ".env"

settings = Settings()


# Use in both FastAPI and Celery
app = FastAPI(title=settings.api_title)

celery = Celery(
    "app",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend
)
"""


# ═══════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════

"""
Decision Tree:

Task takes <30s, no retries needed?
  → Use FastAPI BackgroundTasks

Task takes >30s, needs retries, or needs result tracking?
  → Use Celery

Need scheduled/periodic tasks?
  → Use Celery Beat

Need distributed workers?
  → Use Celery

Task is fire-and-forget logging/notification?
  → Use FastAPI BackgroundTasks

Both together:
  → BackgroundTasks for quick operations
  → Celery for reliable, long-running tasks
"""


# ═══════════════════════════════════════════════════════════════
# Running the Application
# ═══════════════════════════════════════════════════════════════

"""
# Terminal 1: Start FastAPI
uvicorn main:app --reload

# Terminal 2: Start Celery worker
celery -A main.celery worker --loglevel=info

# Terminal 3: (Optional) Start Celery Beat for periodic tasks
celery -A main.celery beat --loglevel=info

# Terminal 4: (Optional) Monitor with Flower
celery -A main.celery flower
"""
