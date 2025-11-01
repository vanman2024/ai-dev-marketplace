# Production Best Practices

Guidelines and patterns for production-ready FastAPI applications.

## Project Organization

### Recommended Structure

```
production-api/
├── app/
│   ├── __init__.py
│   ├── main.py                  # Application entry
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py            # Settings
│   │   ├── dependencies.py      # Dependency injection
│   │   ├── security.py          # Auth utilities
│   │   └── logging.py           # Logging config
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py              # Route dependencies
│   │   └── routes/
│   │       ├── __init__.py
│   │       ├── health.py
│   │       ├── auth.py
│   │       └── users.py
│   ├── models/                  # Database models
│   │   ├── __init__.py
│   │   └── user.py
│   ├── schemas/                 # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── token.py
│   ├── services/                # Business logic
│   │   ├── __init__.py
│   │   ├── user_service.py
│   │   └── auth_service.py
│   ├── db/
│   │   ├── __init__.py
│   │   ├── session.py           # Database session
│   │   └── base.py              # Base model class
│   └── middleware/
│       ├── __init__.py
│       ├── error_handler.py
│       └── request_id.py
├── alembic/                     # Database migrations
│   ├── versions/
│   └── env.py
├── tests/
│   ├── conftest.py
│   ├── test_api/
│   ├── test_services/
│   └── test_integration/
├── scripts/
│   ├── start.sh
│   └── migrate.sh
├── .env.example
├── .env.development
├── .env.production
├── alembic.ini
├── pyproject.toml
├── Dockerfile
├── docker-compose.yml
└── README.md
```

## Configuration Management

### Environment-Specific Settings

```python
# app/core/config.py
from functools import lru_cache
from pydantic_settings import BaseSettings

class BaseConfig(BaseSettings):
    """Base configuration"""
    PROJECT_NAME: str = "Production API"
    VERSION: str = "1.0.0"
    SECRET_KEY: str

    class Config:
        env_file = ".env"
        case_sensitive = True

class DevelopmentConfig(BaseConfig):
    """Development configuration"""
    DEBUG: bool = True
    DATABASE_URL: str = "sqlite:///./dev.db"
    LOG_LEVEL: str = "DEBUG"

class ProductionConfig(BaseConfig):
    """Production configuration"""
    DEBUG: bool = False
    DATABASE_URL: str
    LOG_LEVEL: str = "INFO"
    ALLOWED_ORIGINS: list[str]

    class Config:
        env_file = ".env.production"

@lru_cache()
def get_settings() -> BaseConfig:
    """Get environment-specific settings"""
    import os
    env = os.getenv("ENVIRONMENT", "development")

    if env == "production":
        return ProductionConfig()
    return DevelopmentConfig()

settings = get_settings()
```

## Security Best Practices

### 1. Input Validation

```python
from pydantic import BaseModel, Field, EmailStr, field_validator

class UserCreate(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8)

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain uppercase")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain digit")
        return v
```

### 2. Authentication

```python
# app/core/security.py
from datetime import datetime, timedelta
from jose import jwt
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm="HS256")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)
```

### 3. Protected Routes

```python
# app/api/deps.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    token = credentials.credentials
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=["HS256"]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401)
    except JWTError:
        raise HTTPException(status_code=401)

    # Fetch user from database
    user = await get_user_by_id(user_id)
    if user is None:
        raise HTTPException(status_code=401)

    return user
```

## Error Handling

### Global Exception Handler

```python
# app/middleware/error_handler.py
from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import logging

logger = logging.getLogger(__name__)

async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError
):
    logger.warning(f"Validation error: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": exc.errors(),
            "body": exc.body,
        },
    )

async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"},
    )

# Register in main.py
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)
```

## Structured Logging

```python
# app/core/logging.py
import logging
import sys
from pythonjsonlogger import jsonlogger

def setup_logging():
    """Configure structured JSON logging"""
    logger = logging.getLogger()
    logger.setLevel(settings.LOG_LEVEL)

    handler = logging.StreamHandler(sys.stdout)
    formatter = jsonlogger.JsonFormatter(
        '%(asctime)s %(name)s %(levelname)s %(message)s'
    )
    handler.setFormatter(formatter)
    logger.addHandler(handler)

# In main.py
from app.core.logging import setup_logging
setup_logging()
```

## Database Session Management

```python
# app/db/session.py
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DB_ECHO_LOG,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
)

async_session = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

async def get_db() -> AsyncSession:
    """Dependency for database sessions"""
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

## Testing Strategy

### Dependency Overrides

```python
# tests/conftest.py
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.config import Settings

class TestSettings(Settings):
    DATABASE_URL: str = "sqlite:///./test.db"
    SECRET_KEY: str = "test-secret-key"

@pytest.fixture
def client():
    from app.core.config import get_settings
    app.dependency_overrides[get_settings] = lambda: TestSettings()

    with TestClient(app) as c:
        yield c

    app.dependency_overrides.clear()
```

### Integration Tests

```python
# tests/test_integration/test_auth_flow.py
import pytest

@pytest.mark.asyncio
async def test_full_auth_flow(client):
    # Register
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "test@example.com",
            "username": "testuser",
            "password": "SecurePass123"
        }
    )
    assert response.status_code == 201

    # Login
    response = client.post(
        "/api/v1/auth/login",
        json={
            "username": "testuser",
            "password": "SecurePass123"
        }
    )
    assert response.status_code == 200
    token = response.json()["access_token"]

    # Access protected route
    response = client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"
```

## Performance Optimization

### 1. Async Database Queries

```python
# Use async/await for all I/O
from sqlalchemy import select

async def get_users(db: AsyncSession, skip: int = 0, limit: int = 100):
    result = await db.execute(
        select(User).offset(skip).limit(limit)
    )
    return result.scalars().all()
```

### 2. Response Caching

```python
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend
from fastapi_cache.decorator import cache

@app.on_event("startup")
async def startup():
    redis = aioredis.from_url("redis://localhost")
    FastAPICache.init(RedisBackend(redis), prefix="fastapi-cache")

@router.get("/expensive-data")
@cache(expire=3600)  # Cache for 1 hour
async def get_expensive_data():
    # Expensive computation
    return {"data": "..."}
```

### 3. Background Tasks

```python
from fastapi import BackgroundTasks

def send_notification(email: str, message: str):
    # Send email notification
    pass

@router.post("/items")
async def create_item(
    item: ItemCreate,
    background_tasks: BackgroundTasks
):
    # Create item
    new_item = await create_item_in_db(item)

    # Send notification in background
    background_tasks.add_task(
        send_notification,
        email="admin@example.com",
        message=f"New item created: {new_item.id}"
    )

    return new_item
```

## Monitoring & Observability

### Health Checks

```python
@router.get("/health/detailed")
async def detailed_health(db: AsyncSession = Depends(get_db)):
    checks = {
        "api": True,
        "database": False,
        "redis": False,
    }

    # Database check
    try:
        await db.execute("SELECT 1")
        checks["database"] = True
    except Exception:
        pass

    # Redis check
    try:
        await redis.ping()
        checks["redis"] = True
    except Exception:
        pass

    all_healthy = all(checks.values())

    return {
        "status": "healthy" if all_healthy else "degraded",
        "checks": checks,
    }
```

### Metrics

```python
from prometheus_fastapi_instrumentator import Instrumentator

# In main.py
Instrumentator().instrument(app).expose(app)

# Access metrics at /metrics
```

## Deployment Checklist

- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] Secret keys rotated from defaults
- [ ] CORS properly configured
- [ ] HTTPS enabled
- [ ] Rate limiting implemented
- [ ] Logging configured
- [ ] Health checks working
- [ ] Monitoring setup
- [ ] Backup strategy in place
- [ ] Error tracking (Sentry, etc.)
- [ ] Performance tested
- [ ] Security headers configured
- [ ] Dependencies up to date
- [ ] Documentation complete

## Docker Production Setup

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY pyproject.toml .
RUN pip install --no-cache-dir -e .

# Copy application
COPY app/ ./app/
COPY alembic/ ./alembic/
COPY alembic.ini .

# Run as non-root
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=postgresql://user:pass@db/dbname
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

volumes:
  postgres_data:
```
