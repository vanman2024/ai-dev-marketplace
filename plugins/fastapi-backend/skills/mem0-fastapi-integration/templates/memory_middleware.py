"""
Mem0 Memory Middleware and Dependencies for FastAPI
Provides dependency injection and request-scoped memory access
"""

from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

# Security
security = HTTPBearer()


class AuthenticationError(HTTPException):
    """Custom authentication error"""

    def __init__(self, detail: str = "Could not validate credentials"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_memory_service(request: Request):
    """
    Get memory service from app state.

    Args:
        request: FastAPI request object

    Returns:
        MemoryService instance
    """
    return request.app.state.memory_service


def get_ai_service(request: Request):
    """
    Get AI service from app state.

    Args:
        request: FastAPI request object

    Returns:
        AIService instance
    """
    return request.app.state.ai_service


async def verify_token(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    request: Request = None,
) -> str:
    """
    Verify JWT token and return user_id.

    Args:
        credentials: HTTP bearer credentials
        request: FastAPI request object

    Returns:
        User ID from token

    Raises:
        AuthenticationError: If token is invalid
    """
    try:
        settings = request.app.state.settings if request else None
        if not settings:
            raise AuthenticationError("Settings not available")

        payload = jwt.decode(
            credentials.credentials,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise AuthenticationError()
        return user_id
    except JWTError as e:
        logger.error(f"JWT validation error: {e}")
        raise AuthenticationError()


async def get_current_user(user_id: str = Depends(verify_token)) -> str:
    """
    Get current authenticated user.

    Args:
        user_id: User ID from token verification

    Returns:
        User ID
    """
    return user_id


async def get_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(
        HTTPBearer(auto_error=False)
    ),
) -> Optional[str]:
    """
    Get user ID if authenticated, otherwise return None (for development).

    Args:
        credentials: Optional HTTP bearer credentials

    Returns:
        User ID or "development_user" for development
    """
    if not credentials:
        return "development_user"  # Development fallback

    try:
        return await verify_token(credentials)
    except AuthenticationError:
        return "development_user"  # Development fallback


async def get_user_context(
    user_id: str = Depends(get_current_user),
    memory_service=Depends(get_memory_service),
) -> Dict[str, Any]:
    """
    Get enriched user context from memory.

    Args:
        user_id: Current user ID
        memory_service: MemoryService instance

    Returns:
        Dict with user context including preferences and memory stats
    """
    try:
        summary = await memory_service.get_user_summary(user_id)
        return {
            "user_id": user_id,
            "preferences": summary.get("user_preferences", []),
            "total_conversations": summary.get("total_memories", 0),
            "memory_categories": summary.get("memory_categories", {}),
        }
    except Exception as e:
        logger.error(f"Error getting user context: {e}")
        return {
            "user_id": user_id,
            "preferences": [],
            "total_conversations": 0,
            "memory_categories": {},
        }


class MemoryMiddleware:
    """
    Middleware for automatic memory tracking.
    Can be used to automatically store conversations.
    """

    def __init__(self, app, memory_service):
        self.app = app
        self.memory_service = memory_service

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            # Add memory service to scope
            scope["memory_service"] = self.memory_service

        await self.app(scope, receive, send)


# Rate limiting helpers
class RateLimitExceeded(HTTPException):
    """Rate limit exceeded exception"""

    def __init__(self, detail: str = "Rate limit exceeded"):
        super().__init__(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail=detail)


async def check_memory_rate_limit(
    user_id: str = Depends(get_current_user),
    request: Request = None,
) -> str:
    """
    Check if user has exceeded memory operation rate limit.

    Args:
        user_id: Current user ID
        request: FastAPI request object

    Returns:
        User ID if within limits

    Raises:
        RateLimitExceeded: If rate limit exceeded
    """
    # Implement rate limiting logic here
    # This is a placeholder for actual rate limiting implementation
    # You can use Redis, in-memory cache, or other solutions

    # Example: Check request count in last minute
    # if user_request_count > limit:
    #     raise RateLimitExceeded()

    return user_id
