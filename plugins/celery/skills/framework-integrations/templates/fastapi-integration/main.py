"""
FastAPI main application with Celery integration
"""

from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
from celery.result import AsyncResult
from celery_app import celery
from tasks import sync_task, async_task

app = FastAPI(title="FastAPI + Celery")


class TaskRequest(BaseModel):
    data: dict


@app.post("/api/task")
async def create_task(request: TaskRequest):
    """Submit Celery task"""
    task = sync_task.delay(request.data)
    return {"task_id": task.id, "status": "queued"}


@app.get("/api/task/{task_id}")
async def get_task_status(task_id: str):
    """Check task status"""
    task_result = AsyncResult(task_id, app=celery)

    return {
        "task_id": task_id,
        "status": task_result.state,
        "result": task_result.result if task_result.ready() else None
    }


@app.post("/api/quick")
async def quick_task(request: TaskRequest, background_tasks: BackgroundTasks):
    """Use FastAPI BackgroundTasks for quick operations"""
    background_tasks.add_task(log_request, request.data)
    return {"status": "logged"}


def log_request(data):
    """Simple logging task"""
    print(f"Request logged: {data}")
