"""
Pagination Utilities for FastAPI

Provides reusable pagination utilities including:
- Offset-based pagination
- Cursor-based pagination
- Page-based pagination
- Pagination dependencies
- Response models
"""

from typing import Generic, TypeVar, List, Optional
from pydantic import BaseModel, Field
from fastapi import Query

# ============================================================================
# TYPE VARIABLES FOR GENERIC RESPONSES
# ============================================================================

T = TypeVar('T')


# ============================================================================
# RESPONSE MODELS
# ============================================================================

class PaginatedResponse(BaseModel, Generic[T]):
    """Generic paginated response model"""
    items: List[T] = Field(..., description="List of items for current page")
    total: int = Field(..., description="Total number of items across all pages")
    page: int = Field(..., description="Current page number")
    page_size: int = Field(..., description="Number of items per page")
    pages: int = Field(..., description="Total number of pages")

    class Config:
        json_schema_extra = {
            "example": {
                "items": [],
                "total": 100,
                "page": 1,
                "page_size": 10,
                "pages": 10
            }
        }


class OffsetPaginatedResponse(BaseModel, Generic[T]):
    """Offset-based paginated response"""
    items: List[T] = Field(..., description="List of items")
    total: int = Field(..., description="Total number of items")
    skip: int = Field(..., description="Number of items skipped")
    limit: int = Field(..., description="Maximum number of items returned")
    has_more: bool = Field(..., description="Whether more items are available")


class CursorPaginatedResponse(BaseModel, Generic[T]):
    """Cursor-based paginated response"""
    items: List[T] = Field(..., description="List of items")
    next_cursor: Optional[str] = Field(None, description="Cursor for next page")
    prev_cursor: Optional[str] = Field(None, description="Cursor for previous page")
    has_more: bool = Field(..., description="Whether more items are available")


# ============================================================================
# PAGINATION PARAMETERS (DEPENDENCIES)
# ============================================================================

class PaginationParams(BaseModel):
    """Page-based pagination parameters"""
    page: int = Field(1, ge=1, description="Page number (starts at 1)")
    page_size: int = Field(10, ge=1, le=100, description="Items per page")


class OffsetPaginationParams(BaseModel):
    """Offset-based pagination parameters"""
    skip: int = Field(0, ge=0, description="Number of items to skip")
    limit: int = Field(10, ge=1, le=100, description="Maximum items to return")


class CursorPaginationParams(BaseModel):
    """Cursor-based pagination parameters"""
    cursor: Optional[str] = Field(None, description="Pagination cursor")
    limit: int = Field(10, ge=1, le=100, description="Maximum items to return")


# ============================================================================
# DEPENDENCY FUNCTIONS
# ============================================================================

async def pagination_params(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=100, description="Items per page"),
) -> PaginationParams:
    """
    Dependency for page-based pagination.

    Usage:
        @router.get("/items/")
        async def list_items(pagination: PaginationParams = Depends(pagination_params)):
            skip = (pagination.page - 1) * pagination.page_size
            return items[skip : skip + pagination.page_size]
    """
    return PaginationParams(page=page, page_size=page_size)


async def offset_pagination_params(
    skip: int = Query(0, ge=0, description="Number of items to skip"),
    limit: int = Query(10, ge=1, le=100, description="Max items to return"),
) -> OffsetPaginationParams:
    """
    Dependency for offset-based pagination.

    Usage:
        @router.get("/items/")
        async def list_items(pagination: OffsetPaginationParams = Depends(offset_pagination_params)):
            return items[pagination.skip : pagination.skip + pagination.limit]
    """
    return OffsetPaginationParams(skip=skip, limit=limit)


async def cursor_pagination_params(
    cursor: Optional[str] = Query(None, description="Pagination cursor"),
    limit: int = Query(10, ge=1, le=100, description="Max items to return"),
) -> CursorPaginationParams:
    """
    Dependency for cursor-based pagination.

    Usage:
        @router.get("/items/")
        async def list_items(pagination: CursorPaginationParams = Depends(cursor_pagination_params)):
            start_id = decode_cursor(pagination.cursor) if pagination.cursor else 0
            return get_items_after(start_id, pagination.limit)
    """
    return CursorPaginationParams(cursor=cursor, limit=limit)


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def create_paginated_response(
    items: List[T],
    total: int,
    page: int,
    page_size: int,
) -> PaginatedResponse[T]:
    """
    Create a paginated response from items and pagination params.

    Args:
        items: List of items for current page
        total: Total number of items across all pages
        page: Current page number
        page_size: Number of items per page

    Returns:
        PaginatedResponse with metadata
    """
    pages = (total + page_size - 1) // page_size if total > 0 else 0

    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        pages=pages,
    )


def create_offset_response(
    items: List[T],
    total: int,
    skip: int,
    limit: int,
) -> OffsetPaginatedResponse[T]:
    """
    Create an offset-based paginated response.

    Args:
        items: List of items
        total: Total number of items
        skip: Number of items skipped
        limit: Maximum items requested

    Returns:
        OffsetPaginatedResponse with metadata
    """
    has_more = skip + len(items) < total

    return OffsetPaginatedResponse(
        items=items,
        total=total,
        skip=skip,
        limit=limit,
        has_more=has_more,
    )


def create_cursor_response(
    items: List[T],
    next_cursor: Optional[str],
    prev_cursor: Optional[str] = None,
) -> CursorPaginatedResponse[T]:
    """
    Create a cursor-based paginated response.

    Args:
        items: List of items
        next_cursor: Cursor for next page (None if no more items)
        prev_cursor: Cursor for previous page (optional)

    Returns:
        CursorPaginatedResponse with cursors
    """
    return CursorPaginatedResponse(
        items=items,
        next_cursor=next_cursor,
        prev_cursor=prev_cursor,
        has_more=next_cursor is not None,
    )


# ============================================================================
# CURSOR ENCODING/DECODING
# ============================================================================

import base64
import json


def encode_cursor(data: dict) -> str:
    """
    Encode cursor data to base64 string.

    Args:
        data: Dictionary with cursor data (e.g., {"id": 123, "timestamp": "..."})

    Returns:
        Base64 encoded cursor string
    """
    json_str = json.dumps(data, sort_keys=True)
    return base64.urlsafe_b64encode(json_str.encode()).decode()


def decode_cursor(cursor: str) -> dict:
    """
    Decode cursor string to data dictionary.

    Args:
        cursor: Base64 encoded cursor string

    Returns:
        Dictionary with cursor data

    Raises:
        ValueError: If cursor is invalid
    """
    try:
        json_str = base64.urlsafe_b64decode(cursor.encode()).decode()
        return json.loads(json_str)
    except Exception as e:
        raise ValueError(f"Invalid cursor: {e}")


# ============================================================================
# PAGINATION HELPERS FOR DATABASES
# ============================================================================

def calculate_skip(page: int, page_size: int) -> int:
    """Calculate skip value from page number"""
    return (page - 1) * page_size


def calculate_pages(total: int, page_size: int) -> int:
    """Calculate total pages from total items and page size"""
    return (total + page_size - 1) // page_size if total > 0 else 0


def is_valid_page(page: int, total: int, page_size: int) -> bool:
    """Check if page number is valid"""
    if total == 0:
        return page == 1
    pages = calculate_pages(total, page_size)
    return 1 <= page <= pages


# ============================================================================
# EXAMPLE USAGE
# ============================================================================

"""
Example 1: Page-based pagination with dependency

from fastapi import Depends

@router.get("/items/", response_model=PaginatedResponse[Item])
async def list_items(pagination: PaginationParams = Depends(pagination_params)):
    # Get total count
    total = len(all_items)

    # Calculate pagination
    skip = (pagination.page - 1) * pagination.page_size

    # Get items for current page
    items = all_items[skip : skip + pagination.page_size]

    # Return paginated response
    return create_paginated_response(items, total, pagination.page, pagination.page_size)


Example 2: Offset-based pagination

@router.get("/items/", response_model=OffsetPaginatedResponse[Item])
async def list_items(pagination: OffsetPaginationParams = Depends(offset_pagination_params)):
    total = len(all_items)
    items = all_items[pagination.skip : pagination.skip + pagination.limit]
    return create_offset_response(items, total, pagination.skip, pagination.limit)


Example 3: Cursor-based pagination

@router.get("/items/", response_model=CursorPaginatedResponse[Item])
async def list_items(pagination: CursorPaginationParams = Depends(cursor_pagination_params)):
    # Decode cursor to get starting point
    if pagination.cursor:
        cursor_data = decode_cursor(pagination.cursor)
        start_id = cursor_data["id"]
    else:
        start_id = 0

    # Get items after cursor
    items = get_items_after_id(start_id, pagination.limit + 1)

    # Check if there are more items
    has_more = len(items) > pagination.limit
    if has_more:
        items = items[:pagination.limit]

    # Create next cursor
    next_cursor = None
    if has_more and items:
        next_cursor = encode_cursor({"id": items[-1].id})

    return create_cursor_response(items, next_cursor)


Example 4: With SQLAlchemy

from sqlalchemy.orm import Session

@router.get("/items/", response_model=PaginatedResponse[Item])
async def list_items(
    db: Session = Depends(get_db),
    pagination: PaginationParams = Depends(pagination_params),
):
    # Get total count
    total = db.query(ItemModel).count()

    # Calculate skip
    skip = (pagination.page - 1) * pagination.page_size

    # Query with pagination
    items = db.query(ItemModel).offset(skip).limit(pagination.page_size).all()

    return create_paginated_response(items, total, pagination.page, pagination.page_size)
"""
