"""
FastAPI + Celery integration
Place in app/celery_app.py or project root
"""

from celery import Celery

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
    task_track_started=True,
    task_time_limit=30 * 60,
)
