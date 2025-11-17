"""
FastAPI Celery tasks
"""

from celery_app import celery
import asyncio


@celery.task
def sync_task(data):
    """Synchronous task"""
    return {"processed": data}


@celery.task
async def async_task(data):
    """Async task (Celery 5.2+)"""
    await asyncio.sleep(1)
    return {"processed": data, "async": True}


@celery.task(bind=True, max_retries=3)
def retriable_task(self, data):
    """Task with retry logic"""
    try:
        # Risky operation
        return process_data(data)
    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)


def process_data(data):
    """Helper function"""
    return {"status": "success", "data": data}
