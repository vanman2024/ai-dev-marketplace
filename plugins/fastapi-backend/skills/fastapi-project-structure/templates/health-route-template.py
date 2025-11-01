"""
Health Check Endpoints

Provides health and readiness endpoints for monitoring and orchestration.
"""

from fastapi import APIRouter, status
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()


class HealthResponse(BaseModel):
    """Health check response model."""

    status: str
    timestamp: datetime
    version: str | None = None


class ReadinessResponse(BaseModel):
    """Readiness check response model."""

    status: str
    timestamp: datetime
    checks: dict[str, bool]


@router.get(
    "",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
)
async def health_check():
    """
    Basic health check endpoint.

    Returns 200 if the service is running.
    """
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow(),
    )


@router.get(
    "/ready",
    response_model=ReadinessResponse,
    status_code=status.HTTP_200_OK,
)
async def readiness_check():
    """
    Readiness check endpoint.

    Verifies that the service is ready to handle requests.
    Checks database connections, external services, etc.
    """
    checks = {
        "api": True,
        # Add additional checks:
        # "database": await check_database(),
        # "cache": await check_cache(),
        # "external_service": await check_external_service(),
    }

    all_ready = all(checks.values())

    return ReadinessResponse(
        status="ready" if all_ready else "not_ready",
        timestamp=datetime.utcnow(),
        checks=checks,
    )


@router.get(
    "/live",
    status_code=status.HTTP_200_OK,
)
async def liveness_check():
    """
    Liveness check endpoint.

    Returns 200 if the service is alive.
    Used by orchestrators (Kubernetes, Docker Swarm) to determine if container should be restarted.
    """
    return {"status": "alive"}
