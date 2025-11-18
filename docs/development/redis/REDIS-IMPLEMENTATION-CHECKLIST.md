# Redis Implementation Checklist for RedAI

> **Phase-by-phase integration guide for Redis in RedAI platform**  
> **Complete implementation roadmap with code examples**

---

## Table of Contents

1. [Phase 1: Environment Setup](#phase-1-environment-setup)
2. [Phase 2: Basic Integration](#phase-2-basic-integration)
3. [Phase 3: Celery Broker](#phase-3-celery-broker)
4. [Phase 4: Caching Layer](#phase-4-caching-layer)
5. [Phase 5: Session Management](#phase-5-session-management)
6. [Phase 6: Performance & Monitoring](#phase-6-performance--monitoring)
7. [Testing Guide](#testing-guide)
8. [Production Deployment](#production-deployment)

---

## Phase 1: Environment Setup

### ✅ Task 1.1: Install Redis

**Docker (Recommended)**

```bash
# Update docker-compose.yml
cd /home/gotime2022/Projects/RedAI

# Add Redis service to docker-compose.yml
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: redai_redis
    ports:
      - '6379:6379'
    volumes:
      - redis_data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    restart: unless-stopped
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  redis_data:
    driver: local
```

**Start Redis**

```bash
docker-compose up -d redis

# Verify Redis is running
docker exec -it redai_redis redis-cli ping
# Expected: PONG
```

### ✅ Task 1.2: Create Redis Configuration

```bash
# Create redis.conf in project root
touch redis.conf
```

```conf
# redis.conf

# Network
bind 0.0.0.0
port 6379
timeout 300

# Persistence
appendonly yes
appendfsync everysec
save 900 1
save 300 10
save 60 10000

# Memory
maxmemory 512mb
maxmemory-policy allkeys-lru

# Logging
loglevel notice
logfile ""

# Security
requirepass ${REDIS_PASSWORD:-}  # Set via environment variable

# Performance
tcp-backlog 511
tcp-keepalive 300
```

### ✅ Task 1.3: Install Python Client

```bash
cd backend
pip install redis
pip install hiredis  # Optional: faster parser

# Update requirements.txt
echo "redis==5.0.1" >> requirements.txt
echo "hiredis==2.2.3" >> requirements.txt
```

### ✅ Task 1.4: Add Environment Variables

```bash
# .env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=  # Empty for development
REDIS_MAX_CONNECTIONS=50
```

---

## Phase 2: Basic Integration

### ✅ Task 2.1: Create Redis Client Module

```bash
# Create backend/api/services/redis_client.py
mkdir -p backend/api/services
touch backend/api/services/redis_client.py
```

```python
# backend/api/services/redis_client.py
import redis
from redis import ConnectionPool
from functools import wraps
from typing import Any, Callable, Optional
import json
import logging
from api.config.settings import settings

logger = logging.getLogger(__name__)

class RedisClient:
    """Redis client wrapper with connection pooling"""

    def __init__(self):
        self.pool = ConnectionPool(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            db=settings.REDIS_DB,
            password=settings.REDIS_PASSWORD if settings.REDIS_PASSWORD else None,
            max_connections=settings.REDIS_MAX_CONNECTIONS,
            decode_responses=True,
            socket_timeout=5,
            socket_connect_timeout=5,
            retry_on_timeout=True
        )
        self.client = redis.Redis(connection_pool=self.pool)
        self._test_connection()

    def _test_connection(self):
        """Test Redis connection on startup"""
        try:
            self.client.ping()
            logger.info("✅ Redis connection established")
        except redis.ConnectionError as e:
            logger.error(f"❌ Redis connection failed: {e}")
            raise

    def get(self, key: str) -> Optional[str]:
        """Get value by key"""
        try:
            return self.client.get(key)
        except redis.RedisError as e:
            logger.error(f"Redis GET error for key {key}: {e}")
            return None

    def set(self, key: str, value: str, ttl: Optional[int] = None) -> bool:
        """Set key-value with optional TTL (seconds)"""
        try:
            if ttl:
                return self.client.setex(key, ttl, value)
            return self.client.set(key, value)
        except redis.RedisError as e:
            logger.error(f"Redis SET error for key {key}: {e}")
            return False

    def delete(self, key: str) -> bool:
        """Delete key"""
        try:
            return bool(self.client.delete(key))
        except redis.RedisError as e:
            logger.error(f"Redis DELETE error for key {key}: {e}")
            return False

    def exists(self, key: str) -> bool:
        """Check if key exists"""
        try:
            return bool(self.client.exists(key))
        except redis.RedisError as e:
            logger.error(f"Redis EXISTS error for key {key}: {e}")
            return False

    def get_json(self, key: str) -> Optional[dict]:
        """Get JSON value"""
        value = self.get(key)
        if value:
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                logger.error(f"Failed to decode JSON for key {key}")
        return None

    def set_json(self, key: str, value: dict, ttl: Optional[int] = None) -> bool:
        """Set JSON value"""
        try:
            json_str = json.dumps(value)
            return self.set(key, json_str, ttl)
        except (TypeError, ValueError) as e:
            logger.error(f"Failed to encode JSON for key {key}: {e}")
            return False

    def increment(self, key: str, amount: int = 1) -> int:
        """Increment counter"""
        try:
            return self.client.incrby(key, amount)
        except redis.RedisError as e:
            logger.error(f"Redis INCR error for key {key}: {e}")
            return 0

    def get_many(self, keys: list) -> list:
        """Get multiple keys"""
        try:
            return self.client.mget(keys)
        except redis.RedisError as e:
            logger.error(f"Redis MGET error: {e}")
            return []

    def set_many(self, mapping: dict, ttl: Optional[int] = None) -> bool:
        """Set multiple key-value pairs"""
        try:
            pipe = self.client.pipeline()
            for key, value in mapping.items():
                if ttl:
                    pipe.setex(key, ttl, value)
                else:
                    pipe.set(key, value)
            pipe.execute()
            return True
        except redis.RedisError as e:
            logger.error(f"Redis MSET error: {e}")
            return False

    def delete_pattern(self, pattern: str) -> int:
        """Delete keys matching pattern"""
        try:
            cursor = 0
            deleted_count = 0
            while True:
                cursor, keys = self.client.scan(cursor, match=pattern, count=100)
                if keys:
                    deleted_count += self.client.delete(*keys)
                if cursor == 0:
                    break
            return deleted_count
        except redis.RedisError as e:
            logger.error(f"Redis DELETE_PATTERN error for {pattern}: {e}")
            return 0

    def health_check(self) -> dict:
        """Check Redis health"""
        try:
            info = self.client.info()
            return {
                "status": "healthy",
                "uptime_seconds": info.get("uptime_in_seconds"),
                "connected_clients": info.get("connected_clients"),
                "used_memory_human": info.get("used_memory_human"),
                "hit_rate": self._calculate_hit_rate(info)
            }
        except redis.RedisError as e:
            return {
                "status": "unhealthy",
                "error": str(e)
            }

    def _calculate_hit_rate(self, info: dict) -> float:
        """Calculate cache hit rate"""
        hits = info.get("keyspace_hits", 0)
        misses = info.get("keyspace_misses", 0)
        total = hits + misses
        return (hits / total * 100) if total > 0 else 0.0

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.pool.disconnect()

# Global Redis client instance
redis_client = RedisClient()
```

### ✅ Task 2.2: Update Settings

```python
# backend/api/config/settings.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # ... existing settings ...

    # Redis Configuration
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0
    REDIS_PASSWORD: str = ""
    REDIS_MAX_CONNECTIONS: int = 50

    class Config:
        env_file = ".env"

settings = Settings()
```

### ✅ Task 2.3: Test Redis Connection

```python
# backend/tests/test_redis_connection.py
import pytest
from api.services.redis_client import redis_client

def test_redis_connection():
    """Test Redis connection"""
    assert redis_client.client.ping() == True

def test_redis_set_get():
    """Test basic set/get operations"""
    key = "test:key"
    value = "test_value"

    # Set
    assert redis_client.set(key, value) == True

    # Get
    assert redis_client.get(key) == value

    # Delete
    assert redis_client.delete(key) == True
    assert redis_client.get(key) is None

def test_redis_json():
    """Test JSON operations"""
    key = "test:json"
    data = {"name": "Test", "value": 123}

    # Set JSON
    assert redis_client.set_json(key, data) == True

    # Get JSON
    retrieved = redis_client.get_json(key)
    assert retrieved == data

    # Cleanup
    redis_client.delete(key)

def test_redis_health():
    """Test health check"""
    health = redis_client.health_check()
    assert health["status"] == "healthy"
    assert "uptime_seconds" in health
```

**Run tests:**

```bash
cd backend
pytest tests/test_redis_connection.py -v
```

---

## Phase 3: Celery Broker

### ✅ Task 3.1: Configure Celery with Redis

```python
# backend/api/config/celery_config.py
from celery import Celery
from api.config.settings import settings

# Create Celery app
celery_app = Celery(
    "redai",
    broker=f"redis://{settings.REDIS_HOST}:{settings.REDIS_PORT}/0",
    backend=f"redis://{settings.REDIS_HOST}:{settings.REDIS_PORT}/1"
)

# Celery configuration
celery_app.conf.update(
    # Task serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,

    # Task routing
    task_routes={
        'api.tasks.generate_questions.*': {'queue': 'questions'},
        'api.tasks.validate_citations.*': {'queue': 'validation'},
        'api.tasks.analytics.*': {'queue': 'analytics'},
    },

    # Result backend
    result_expires=3600,  # 1 hour
    result_backend_transport_options={
        'master_name': 'mymaster',
        'visibility_timeout': 3600,
    },

    # Broker settings
    broker_connection_retry_on_startup=True,
    broker_pool_limit=10,

    # Worker settings
    worker_prefetch_multiplier=4,
    worker_max_tasks_per_child=1000,

    # Task settings
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    task_track_started=True,
)

# Import tasks
celery_app.autodiscover_tasks(['api.tasks'])
```

### ✅ Task 3.2: Create Example Celery Task

```python
# backend/api/tasks/example_tasks.py
from api.config.celery_config import celery_app
from api.services.redis_client import redis_client
import logging

logger = logging.getLogger(__name__)

@celery_app.task(name="api.tasks.test_redis_task")
def test_redis_task(message: str) -> dict:
    """Test task that uses Redis"""
    key = f"task:test:{test_redis_task.request.id}"

    # Store in Redis
    redis_client.set(key, message, ttl=300)

    logger.info(f"Task {test_redis_task.request.id}: Stored message in Redis")

    return {
        "task_id": test_redis_task.request.id,
        "message": message,
        "redis_key": key
    }

@celery_app.task(name="api.tasks.batch_generate_questions", bind=True)
def batch_generate_questions(self, exam_id: int, count: int = 10):
    """
    Generate multiple questions in batch
    Uses Redis for progress tracking
    """
    progress_key = f"batch:progress:{self.request.id}"

    try:
        for i in range(count):
            # Simulate question generation
            # In production: call Gemini API

            # Update progress in Redis
            progress = {
                "current": i + 1,
                "total": count,
                "percentage": ((i + 1) / count) * 100,
                "status": "in_progress"
            }
            redis_client.set_json(progress_key, progress, ttl=600)

            # Update Celery task state
            self.update_state(
                state='PROGRESS',
                meta=progress
            )

        # Mark complete
        final_progress = {
            "current": count,
            "total": count,
            "percentage": 100,
            "status": "completed"
        }
        redis_client.set_json(progress_key, final_progress, ttl=600)

        return {"status": "completed", "count": count}

    except Exception as e:
        logger.error(f"Batch generation failed: {e}")
        redis_client.set_json(
            progress_key,
            {"status": "failed", "error": str(e)},
            ttl=600
        )
        raise
```

### ✅ Task 3.3: Create FastAPI Endpoints for Celery

```python
# backend/api/routes/tasks.py
from fastapi import APIRouter, HTTPException
from api.tasks.example_tasks import test_redis_task, batch_generate_questions
from api.services.redis_client import redis_client
from api.config.celery_config import celery_app

router = APIRouter(prefix="/tasks", tags=["tasks"])

@router.post("/test")
async def create_test_task(message: str):
    """Create test task"""
    task = test_redis_task.delay(message)
    return {
        "task_id": task.id,
        "status": "queued"
    }

@router.get("/test/{task_id}")
async def get_test_task_result(task_id: str):
    """Get task result"""
    task_result = celery_app.AsyncResult(task_id)

    if task_result.ready():
        return {
            "task_id": task_id,
            "status": "completed",
            "result": task_result.result
        }
    else:
        return {
            "task_id": task_id,
            "status": "pending"
        }

@router.post("/batch/generate-questions")
async def create_batch_generation(exam_id: int, count: int = 10):
    """Start batch question generation"""
    task = batch_generate_questions.delay(exam_id, count)
    return {
        "task_id": task.id,
        "status": "queued",
        "progress_endpoint": f"/tasks/batch/progress/{task.id}"
    }

@router.get("/batch/progress/{task_id}")
async def get_batch_progress(task_id: str):
    """Get batch generation progress"""
    # Get from Redis
    progress_key = f"batch:progress:{task_id}"
    progress = redis_client.get_json(progress_key)

    if not progress:
        # Fallback to Celery task state
        task_result = celery_app.AsyncResult(task_id)
        if task_result.state == 'PENDING':
            return {"status": "pending"}
        elif task_result.state == 'PROGRESS':
            return task_result.info

    return progress
```

### ✅ Task 3.4: Start Celery Worker

```bash
# Terminal 1: Start Celery worker
cd backend
celery -A api.config.celery_config:celery_app worker --loglevel=info

# Terminal 2: Start Celery beat (for periodic tasks)
celery -A api.config.celery_config:celery_app beat --loglevel=info

# Terminal 3: Start FastAPI server
uvicorn main:app --reload
```

---

## Phase 4: Caching Layer

### ✅ Task 4.1: Create Caching Utilities

```python
# backend/api/services/cache.py
from functools import wraps
from typing import Any, Callable, Optional
from api.services.redis_client import redis_client
import json
import hashlib

def generate_cache_key(prefix: str, *args, **kwargs) -> str:
    """Generate consistent cache key"""
    key_parts = [prefix]

    # Add args
    for arg in args:
        key_parts.append(str(arg))

    # Add sorted kwargs
    for k, v in sorted(kwargs.items()):
        key_parts.append(f"{k}:{v}")

    key_string = ":".join(key_parts)

    # Hash if too long
    if len(key_string) > 200:
        key_hash = hashlib.sha256(key_string.encode()).hexdigest()[:16]
        return f"{prefix}:{key_hash}"

    return key_string

def cache_result(ttl: int = 3600, key_prefix: Optional[str] = None):
    """
    Decorator to cache function results in Redis

    Usage:
        @cache_result(ttl=300, key_prefix="exam")
        def get_exam_data(exam_id: int):
            return database_query()
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def async_wrapper(*args, **kwargs) -> Any:
            # Generate cache key
            prefix = key_prefix or f"cache:{func.__module__}.{func.__name__}"
            cache_key = generate_cache_key(prefix, *args, **kwargs)

            # Try to get from cache
            cached_value = redis_client.get_json(cache_key)
            if cached_value is not None:
                return cached_value

            # Execute function
            result = await func(*args, **kwargs)

            # Cache result
            if result is not None:
                redis_client.set_json(cache_key, result, ttl)

            return result

        @wraps(func)
        def sync_wrapper(*args, **kwargs) -> Any:
            # Generate cache key
            prefix = key_prefix or f"cache:{func.__module__}.{func.__name__}"
            cache_key = generate_cache_key(prefix, *args, **kwargs)

            # Try to get from cache
            cached_value = redis_client.get_json(cache_key)
            if cached_value is not None:
                return cached_value

            # Execute function
            result = func(*args, **kwargs)

            # Cache result
            if result is not None:
                redis_client.set_json(cache_key, result, ttl)

            return result

        # Return appropriate wrapper based on function type
        import inspect
        if inspect.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper

    return decorator

def invalidate_cache(key_pattern: str):
    """Invalidate cache by pattern"""
    return redis_client.delete_pattern(key_pattern)
```

### ✅ Task 4.2: Apply Caching to Endpoints

```python
# backend/api/routes/exams.py
from fastapi import APIRouter, Depends
from api.services.cache import cache_result, invalidate_cache
from api.services.redis_client import redis_client
from sqlalchemy.orm import Session

router = APIRouter(prefix="/exams", tags=["exams"])

@router.get("/{exam_id}")
@cache_result(ttl=3600, key_prefix="exam")
async def get_exam(exam_id: int, db: Session = Depends(get_db)):
    """Get exam by ID (cached for 1 hour)"""
    exam = db.query(Exam).filter_by(id=exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")
    return exam.to_dict()

@router.get("/{exam_id}/questions")
@cache_result(ttl=600, key_prefix="exam:questions")
async def get_exam_questions(exam_id: int, db: Session = Depends(get_db)):
    """Get exam questions (cached for 10 minutes)"""
    questions = db.query(Question).filter_by(exam_id=exam_id).all()
    return [q.to_dict() for q in questions]

@router.put("/{exam_id}")
async def update_exam(
    exam_id: int,
    exam_data: dict,
    db: Session = Depends(get_db)
):
    """Update exam and invalidate cache"""
    exam = db.query(Exam).filter_by(id=exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")

    # Update exam
    for key, value in exam_data.items():
        setattr(exam, key, value)
    db.commit()

    # Invalidate cache
    invalidate_cache(f"exam:{exam_id}*")

    return exam.to_dict()
```

---

## Phase 5: Session Management

### ✅ Task 5.1: Create Session Manager

```python
# backend/api/services/session.py
from api.services.redis_client import redis_client
import secrets
from datetime import datetime, timedelta
from typing import Optional

class SessionManager:
    def __init__(self, session_ttl: int = 86400):  # 24 hours
        self.redis = redis_client
        self.session_ttl = session_ttl

    def create_session(self, user_id: int, user_data: dict) -> str:
        """Create new session"""
        session_id = secrets.token_urlsafe(32)
        session_key = f"session:{session_id}"

        session_data = {
            "user_id": user_id,
            "created_at": datetime.utcnow().isoformat(),
            **user_data
        }

        self.redis.set_json(session_key, session_data, self.session_ttl)

        # Track user sessions
        user_sessions_key = f"user:{user_id}:sessions"
        self.redis.client.sadd(user_sessions_key, session_id)
        self.redis.client.expire(user_sessions_key, self.session_ttl)

        return session_id

    def get_session(self, session_id: str) -> Optional[dict]:
        """Get session data"""
        session_key = f"session:{session_id}"
        session_data = self.redis.get_json(session_key)

        if session_data:
            # Refresh TTL on access
            self.redis.client.expire(session_key, self.session_ttl)

        return session_data

    def update_session(self, session_id: str, data: dict):
        """Update session data"""
        session_key = f"session:{session_id}"
        existing = self.get_session(session_id)

        if existing:
            existing.update(data)
            existing["updated_at"] = datetime.utcnow().isoformat()
            self.redis.set_json(session_key, existing, self.session_ttl)

    def delete_session(self, session_id: str):
        """Delete session (logout)"""
        session_key = f"session:{session_id}"
        session_data = self.get_session(session_id)

        if session_data:
            user_id = session_data.get("user_id")
            # Remove from user's session set
            user_sessions_key = f"user:{user_id}:sessions"
            self.redis.client.srem(user_sessions_key, session_id)

        self.redis.delete(session_key)

    def delete_all_user_sessions(self, user_id: int):
        """Delete all sessions for a user"""
        user_sessions_key = f"user:{user_id}:sessions"
        session_ids = self.redis.client.smembers(user_sessions_key)

        for session_id in session_ids:
            self.delete_session(session_id)

        self.redis.delete(user_sessions_key)

session_manager = SessionManager()
```

### ✅ Task 5.2: Create Auth Dependency

```python
# backend/api/dependencies.py
from fastapi import Header, HTTPException, Depends
from api.services.session import session_manager
from typing import Optional

async def get_current_user(
    authorization: Optional[str] = Header(None)
) -> dict:
    """Get current user from session"""
    if not authorization:
        raise HTTPException(status_code=401, detail="Not authenticated")

    # Extract session ID from Bearer token
    try:
        session_id = authorization.split(" ")[1]
    except IndexError:
        raise HTTPException(status_code=401, detail="Invalid authorization header")

    # Get session
    session_data = session_manager.get_session(session_id)
    if not session_data:
        raise HTTPException(status_code=401, detail="Session expired or invalid")

    return session_data
```

### ✅ Task 5.3: Update Auth Routes

```python
# backend/api/routes/auth.py
from fastapi import APIRouter, HTTPException, Depends
from api.services.session import session_manager
from api.dependencies import get_current_user
from sqlalchemy.orm import Session

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/login")
async def login(email: str, password: str, db: Session = Depends(get_db)):
    """Login and create session"""
    # Verify credentials
    user = db.query(User).filter_by(email=email).first()
    if not user or not user.verify_password(password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # Create session
    session_id = session_manager.create_session(
        user_id=user.id,
        user_data={
            "email": user.email,
            "role": user.role,
            "name": user.name
        }
    )

    return {
        "session_id": session_id,
        "user": {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "role": user.role
        }
    }

@router.post("/logout")
async def logout(current_user: dict = Depends(get_current_user)):
    """Logout and delete session"""
    # Session ID is in authorization header
    # We need to extract it again
    from fastapi import Request
    request = Request
    session_id = request.headers.get("authorization").split(" ")[1]

    session_manager.delete_session(session_id)

    return {"message": "Logged out successfully"}

@router.get("/me")
async def get_current_user_info(current_user: dict = Depends(get_current_user)):
    """Get current user info"""
    return current_user

@router.post("/logout-all")
async def logout_all_sessions(current_user: dict = Depends(get_current_user)):
    """Logout from all devices"""
    user_id = current_user["user_id"]
    session_manager.delete_all_user_sessions(user_id)
    return {"message": "Logged out from all devices"}
```

---

## Phase 6: Performance & Monitoring

### ✅ Task 6.1: Add Health Check Endpoint

```python
# backend/api/routes/health.py
from fastapi import APIRouter
from api.services.redis_client import redis_client

router = APIRouter(prefix="/health", tags=["health"])

@router.get("/redis")
async def redis_health():
    """Check Redis health"""
    return redis_client.health_check()
```

### ✅ Task 6.2: Install Redis Insight

```bash
# Download Redis Insight
# https://redis.io/insight/

# Or use Docker
docker run -d \
  --name redis-insight \
  -p 5540:5540 \
  redis/redisinsight:latest

# Access at: http://localhost:5540
```

### ✅ Task 6.3: Configure Monitoring

```python
# backend/api/services/redis_monitor.py
from api.services.redis_client import redis_client
import logging

logger = logging.getLogger(__name__)

def log_redis_stats():
    """Log Redis statistics"""
    try:
        info = redis_client.client.info()
        logger.info(f"""
        Redis Stats:
        - Connected clients: {info.get('connected_clients')}
        - Used memory: {info.get('used_memory_human')}
        - Total commands processed: {info.get('total_commands_processed')}
        - Keyspace hits: {info.get('keyspace_hits')}
        - Keyspace misses: {info.get('keyspace_misses')}
        - Hit rate: {redis_client._calculate_hit_rate(info):.2f}%
        """)
    except Exception as e:
        logger.error(f"Failed to get Redis stats: {e}")
```

---

## Testing Guide

### ✅ Test Redis Connection

```python
# backend/tests/test_redis.py
import pytest
from api.services.redis_client import redis_client

def test_redis_basic_operations():
    """Test basic Redis operations"""
    # Set
    assert redis_client.set("test_key", "test_value") == True

    # Get
    assert redis_client.get("test_key") == "test_value"

    # Exists
    assert redis_client.exists("test_key") == True

    # Delete
    assert redis_client.delete("test_key") == True
    assert redis_client.exists("test_key") == False
```

### ✅ Test Caching

```python
def test_caching_decorator():
    """Test cache decorator"""
    from api.services.cache import cache_result

    call_count = 0

    @cache_result(ttl=60, key_prefix="test")
    def expensive_function(x: int):
        nonlocal call_count
        call_count += 1
        return x * 2

    # First call - executes function
    result1 = expensive_function(5)
    assert result1 == 10
    assert call_count == 1

    # Second call - from cache
    result2 = expensive_function(5)
    assert result2 == 10
    assert call_count == 1  # Not incremented
```

### ✅ Test Session Management

```python
def test_session_lifecycle():
    """Test session creation, retrieval, and deletion"""
    from api.services.session import session_manager

    # Create session
    session_id = session_manager.create_session(
        user_id=123,
        user_data={"email": "test@example.com"}
    )
    assert session_id is not None

    # Get session
    session = session_manager.get_session(session_id)
    assert session["user_id"] == 123
    assert session["email"] == "test@example.com"

    # Delete session
    session_manager.delete_session(session_id)
    assert session_manager.get_session(session_id) is None
```

---

## Production Deployment

### ✅ Production Redis Configuration

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: redai_redis_prod
    restart: always
    ports:
      - '127.0.0.1:6379:6379' # Bind to localhost only
    volumes:
      - redis_prod_data:/data
      - ./redis.prod.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - redai_network
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 10s
      timeout: 5s
      retries: 5
    logging:
      driver: 'json-file'
      options:
        max-size: '10m'
        max-file: '3'

volumes:
  redis_prod_data:
    driver: local

networks:
  redai_network:
    driver: bridge
```

```conf
# redis.prod.conf
# Network
bind 127.0.0.1
port 6379
timeout 300

# Security
requirepass ${REDIS_PASSWORD}
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG ""

# Persistence
appendonly yes
appendfsync everysec
save 900 1
save 300 10
save 60 10000

# Memory
maxmemory 2gb
maxmemory-policy allkeys-lru

# Performance
tcp-backlog 511
tcp-keepalive 300

# Logging
loglevel notice
logfile "/data/redis.log"

# Slow log
slowlog-log-slower-than 10000
slowlog-max-len 128
```

### ✅ Environment Variables (Production)

```bash
# .env.production
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=your_secure_password_here
REDIS_MAX_CONNECTIONS=100
```

### ✅ Monitoring & Alerts

```python
# backend/api/services/redis_alerts.py
from api.services.redis_client import redis_client
import logging

logger = logging.getLogger(__name__)

def check_redis_health_alerts():
    """Check Redis health and send alerts"""
    try:
        health = redis_client.health_check()

        # Check memory usage
        memory = health.get("used_memory_human", "")
        if "G" in memory:  # Gigabytes
            gb = float(memory.replace("G", ""))
            if gb > 1.5:  # 1.5 GB threshold
                logger.warning(f"Redis memory usage high: {memory}")

        # Check hit rate
        hit_rate = health.get("hit_rate", 100)
        if hit_rate < 70:  # 70% threshold
            logger.warning(f"Redis cache hit rate low: {hit_rate:.2f}%")

        # Check connected clients
        clients = health.get("connected_clients", 0)
        if clients > 80:  # 80 clients threshold
            logger.warning(f"High number of Redis clients: {clients}")

    except Exception as e:
        logger.error(f"Redis health check failed: {e}")
        # Send alert to monitoring system
```

---

## Summary Checklist

### Environment

- [ ] Redis Docker container running
- [ ] redis.conf configured
- [ ] Python redis client installed
- [ ] Environment variables set

### Integration

- [ ] Redis client module created
- [ ] Connection pooling configured
- [ ] Health check endpoint added
- [ ] Tests passing

### Celery

- [ ] Celery configured with Redis broker
- [ ] Tasks created and tested
- [ ] Workers running
- [ ] Task monitoring set up

### Caching

- [ ] Cache decorator implemented
- [ ] API endpoints cached
- [ ] Cache invalidation working
- [ ] Hit rate > 70%

### Sessions

- [ ] Session manager created
- [ ] Auth endpoints updated
- [ ] Session refresh working
- [ ] Multi-device logout working

### Production

- [ ] Production redis.conf created
- [ ] Security configured (password, renamed commands)
- [ ] Monitoring alerts set up
- [ ] Redis Insight installed
- [ ] Backup strategy implemented

---

**Next Steps:**

1. Complete Phase 1-2 for basic Redis integration
2. Implement Celery integration (Phase 3)
3. Add caching layer (Phase 4)
4. Integrate session management (Phase 5)
5. Set up monitoring (Phase 6)
6. Deploy to production

**Documentation:**

- [REDIS-COMPREHENSIVE-DOCUMENTATION.md](./REDIS-COMPREHENSIVE-DOCUMENTATION.md) - Full reference
- [REDIS-QUICK-REFERENCE.md](./REDIS-QUICK-REFERENCE.md) - Command cheat sheet
