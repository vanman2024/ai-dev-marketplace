"""
Error Handling Utilities for FastAPI

Provides standardized error handling including:
- Custom exception classes
- Exception handlers
- Error response models
- Common HTTP exceptions
"""

from fastapi import FastAPI, Request, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import BaseModel, Field
from typing import Optional, Any, Dict
from datetime import datetime
import traceback
import logging

logger = logging.getLogger(__name__)


# ============================================================================
# ERROR RESPONSE MODELS
# ============================================================================

class ErrorDetail(BaseModel):
    """Detailed error information"""
    field: Optional[str] = Field(None, description="Field that caused the error")
    message: str = Field(..., description="Error message")
    type: Optional[str] = Field(None, description="Error type")


class ErrorResponse(BaseModel):
    """Standardized error response"""
    error: str = Field(..., description="Error type/code")
    message: str = Field(..., description="Human-readable error message")
    details: Optional[Any] = Field(None, description="Additional error details")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Error timestamp")
    path: Optional[str] = Field(None, description="Request path that caused error")

    class Config:
        json_schema_extra = {
            "example": {
                "error": "not_found",
                "message": "Resource not found",
                "details": {"resource_id": 123},
                "timestamp": "2024-01-01T12:00:00Z",
                "path": "/api/items/123"
            }
        }


# ============================================================================
# CUSTOM EXCEPTIONS
# ============================================================================

class AppException(Exception):
    """Base exception for application errors"""
    def __init__(
        self,
        message: str,
        status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR,
        error_code: str = "internal_error",
        details: Optional[Dict] = None,
    ):
        self.message = message
        self.status_code = status_code
        self.error_code = error_code
        self.details = details or {}
        super().__init__(self.message)


class NotFoundError(AppException):
    """Resource not found error"""
    def __init__(self, resource: str, resource_id: Any):
        super().__init__(
            message=f"{resource} with id {resource_id} not found",
            status_code=status.HTTP_404_NOT_FOUND,
            error_code="not_found",
            details={"resource": resource, "id": resource_id}
        )


class AlreadyExistsError(AppException):
    """Resource already exists error"""
    def __init__(self, resource: str, field: str, value: Any):
        super().__init__(
            message=f"{resource} with {field} '{value}' already exists",
            status_code=status.HTTP_409_CONFLICT,
            error_code="already_exists",
            details={"resource": resource, "field": field, "value": value}
        )


class UnauthorizedError(AppException):
    """Unauthorized access error"""
    def __init__(self, message: str = "Authentication required"):
        super().__init__(
            message=message,
            status_code=status.HTTP_401_UNAUTHORIZED,
            error_code="unauthorized",
        )


class ForbiddenError(AppException):
    """Forbidden access error"""
    def __init__(self, message: str = "Access forbidden"):
        super().__init__(
            message=message,
            status_code=status.HTTP_403_FORBIDDEN,
            error_code="forbidden",
        )


class ValidationError(AppException):
    """Business logic validation error"""
    def __init__(self, message: str, field: Optional[str] = None):
        details = {"field": field} if field else {}
        super().__init__(
            message=message,
            status_code=status.HTTP_400_BAD_REQUEST,
            error_code="validation_error",
            details=details,
        )


class RateLimitError(AppException):
    """Rate limit exceeded error"""
    def __init__(self, retry_after: int):
        super().__init__(
            message="Rate limit exceeded",
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            error_code="rate_limit_exceeded",
            details={"retry_after": retry_after}
        )


# ============================================================================
# EXCEPTION HANDLERS
# ============================================================================

async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    """Handler for custom application exceptions"""
    logger.warning(
        f"AppException: {exc.error_code} - {exc.message}",
        extra={"path": request.url.path, "details": exc.details}
    )

    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            error=exc.error_code,
            message=exc.message,
            details=exc.details,
            path=str(request.url.path),
        ).model_dump(),
    )


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """Handler for FastAPI HTTPException"""
    logger.warning(
        f"HTTPException: {exc.status_code} - {exc.detail}",
        extra={"path": request.url.path}
    )

    # Map status code to error type
    error_map = {
        400: "bad_request",
        401: "unauthorized",
        403: "forbidden",
        404: "not_found",
        405: "method_not_allowed",
        409: "conflict",
        422: "validation_error",
        429: "rate_limit_exceeded",
        500: "internal_error",
        503: "service_unavailable",
    }

    error_code = error_map.get(exc.status_code, "error")

    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            error=error_code,
            message=exc.detail,
            path=str(request.url.path),
        ).model_dump(),
    )


async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError
) -> JSONResponse:
    """Handler for request validation errors"""
    logger.warning(
        f"Validation error: {exc.errors()}",
        extra={"path": request.url.path}
    )

    # Format validation errors
    errors = []
    for error in exc.errors():
        field = ".".join(str(loc) for loc in error["loc"])
        errors.append({
            "field": field,
            "message": error["msg"],
            "type": error["type"],
        })

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=ErrorResponse(
            error="validation_error",
            message="Request validation failed",
            details={"errors": errors},
            path=str(request.url.path),
        ).model_dump(),
    )


async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Handler for unexpected exceptions"""
    logger.error(
        f"Unexpected error: {str(exc)}",
        extra={
            "path": request.url.path,
            "traceback": traceback.format_exc()
        }
    )

    # Don't expose internal error details in production
    message = "An unexpected error occurred"
    details = None

    # In development, include error details
    # if settings.DEBUG:
    #     message = str(exc)
    #     details = {"traceback": traceback.format_exc()}

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=ErrorResponse(
            error="internal_error",
            message=message,
            details=details,
            path=str(request.url.path),
        ).model_dump(),
    )


# ============================================================================
# SETUP FUNCTION
# ============================================================================

def setup_exception_handlers(app: FastAPI) -> None:
    """
    Register all exception handlers with the FastAPI app.

    Usage:
        app = FastAPI()
        setup_exception_handlers(app)
    """
    app.add_exception_handler(AppException, app_exception_handler)
    app.add_exception_handler(HTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(Exception, general_exception_handler)


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def raise_not_found(resource: str, resource_id: Any) -> None:
    """Raise a NotFoundError"""
    raise NotFoundError(resource, resource_id)


def raise_already_exists(resource: str, field: str, value: Any) -> None:
    """Raise an AlreadyExistsError"""
    raise AlreadyExistsError(resource, field, value)


def raise_unauthorized(message: str = "Authentication required") -> None:
    """Raise an UnauthorizedError"""
    raise UnauthorizedError(message)


def raise_forbidden(message: str = "Access forbidden") -> None:
    """Raise a ForbiddenError"""
    raise ForbiddenError(message)


def raise_validation_error(message: str, field: Optional[str] = None) -> None:
    """Raise a ValidationError"""
    raise ValidationError(message, field)


# ============================================================================
# COMMON HTTP EXCEPTIONS
# ============================================================================

def not_found_exception(resource: str, resource_id: Any) -> HTTPException:
    """Create a 404 Not Found exception"""
    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=f"{resource} with id {resource_id} not found"
    )


def bad_request_exception(message: str) -> HTTPException:
    """Create a 400 Bad Request exception"""
    return HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=message
    )


def unauthorized_exception(message: str = "Invalid credentials") -> HTTPException:
    """Create a 401 Unauthorized exception"""
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=message,
        headers={"WWW-Authenticate": "Bearer"},
    )


def forbidden_exception(message: str = "Access forbidden") -> HTTPException:
    """Create a 403 Forbidden exception"""
    return HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=message
    )


def conflict_exception(resource: str, field: str, value: Any) -> HTTPException:
    """Create a 409 Conflict exception"""
    return HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail=f"{resource} with {field} '{value}' already exists"
    )


# ============================================================================
# EXAMPLE USAGE
# ============================================================================

"""
Example 1: Setup in main.py

from fastapi import FastAPI
from app.utils.errors import setup_exception_handlers

app = FastAPI()
setup_exception_handlers(app)


Example 2: Using custom exceptions in endpoints

from app.utils.errors import NotFoundError, AlreadyExistsError

@router.get("/items/{item_id}")
async def get_item(item_id: int):
    item = db.get(item_id)
    if not item:
        raise NotFoundError("Item", item_id)
    return item

@router.post("/items/")
async def create_item(item: ItemCreate):
    if item_exists(item.name):
        raise AlreadyExistsError("Item", "name", item.name)
    return create_new_item(item)


Example 3: Using helper functions

from app.utils.errors import raise_not_found, raise_validation_error

@router.put("/items/{item_id}")
async def update_item(item_id: int, item: ItemUpdate):
    existing = db.get(item_id)
    if not existing:
        raise_not_found("Item", item_id)

    if item.price and item.price < 0:
        raise_validation_error("Price must be positive", field="price")

    return update_item_in_db(item_id, item)


Example 4: Using HTTPException shortcuts

from app.utils.errors import not_found_exception, conflict_exception

@router.delete("/items/{item_id}")
async def delete_item(item_id: int):
    if not db.exists(item_id):
        raise not_found_exception("Item", item_id)

    if item_has_dependencies(item_id):
        raise conflict_exception("Item", "id", item_id)

    db.delete(item_id)
"""
