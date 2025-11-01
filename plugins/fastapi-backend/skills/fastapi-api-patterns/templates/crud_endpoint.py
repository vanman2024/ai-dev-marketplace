"""
CRUD Endpoint Template for FastAPI

This template provides a complete CRUD (Create, Read, Update, Delete) endpoint
implementation with best practices for error handling, validation, and documentation.

To use this template:
1. Replace 'Item' with your model name
2. Update the Pydantic models with your fields
3. Implement database operations
4. Add authentication dependencies if needed
5. Customize error messages and status codes
"""

from fastapi import APIRouter, HTTPException, Depends, status, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

# ============================================================================
# PYDANTIC MODELS
# ============================================================================

class ItemBase(BaseModel):
    """Base model with shared properties"""
    name: str = Field(..., min_length=1, max_length=100, description="Item name")
    description: Optional[str] = Field(None, max_length=500, description="Item description")
    price: float = Field(..., gt=0, description="Item price (must be positive)")
    category: str = Field(..., description="Item category")
    is_active: bool = Field(default=True, description="Whether item is active")


class ItemCreate(ItemBase):
    """Model for creating new items"""
    pass


class ItemUpdate(BaseModel):
    """Model for updating existing items (all fields optional)"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    price: Optional[float] = Field(None, gt=0)
    category: Optional[str] = None
    is_active: Optional[bool] = None


class ItemInDB(ItemBase):
    """Model representing item in database"""
    id: int
    created_at: datetime
    updated_at: datetime


class Item(ItemInDB):
    """Model for returning items to clients"""
    class Config:
        from_attributes = True


class PaginatedItemsResponse(BaseModel):
    """Paginated response model"""
    items: List[Item]
    total: int
    page: int
    page_size: int
    pages: int


# ============================================================================
# ROUTER SETUP
# ============================================================================

router = APIRouter(
    prefix="/items",
    tags=["items"],
    responses={
        404: {"description": "Item not found"},
        400: {"description": "Bad request"},
    },
)


# ============================================================================
# IN-MEMORY DATABASE (REPLACE WITH REAL DATABASE)
# ============================================================================

# Simulated database
fake_items_db: dict[int, dict] = {}
next_id = 1


def get_current_time():
    """Get current timestamp"""
    return datetime.utcnow()


# ============================================================================
# CRUD ENDPOINTS
# ============================================================================

@router.post(
    "/",
    response_model=Item,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new item",
    description="Create a new item with the provided data",
    response_description="The created item with generated ID and timestamps",
)
async def create_item(item: ItemCreate):
    """
    Create a new item with all the information:

    - **name**: Item name (required, 1-100 characters)
    - **description**: Item description (optional, max 500 characters)
    - **price**: Item price (required, must be positive)
    - **category**: Item category (required)
    - **is_active**: Whether the item is active (default: true)

    Returns the created item with:
    - Generated ID
    - Created timestamp
    - Updated timestamp
    """
    global next_id

    # Check if item with same name exists (example validation)
    for existing_item in fake_items_db.values():
        if existing_item["name"].lower() == item.name.lower():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Item with name '{item.name}' already exists"
            )

    # Create item in database
    current_time = get_current_time()
    item_data = item.model_dump()
    item_data.update({
        "id": next_id,
        "created_at": current_time,
        "updated_at": current_time,
    })

    fake_items_db[next_id] = item_data
    next_id += 1

    return Item(**item_data)


@router.get(
    "/{item_id}",
    response_model=Item,
    summary="Get item by ID",
    description="Retrieve a single item by its ID",
    responses={
        200: {"description": "Item found and returned"},
        404: {"description": "Item not found"},
    }
)
async def get_item(item_id: int):
    """
    Get a specific item by ID.

    - **item_id**: The ID of the item to retrieve
    """
    if item_id not in fake_items_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item with id {item_id} not found"
        )

    return Item(**fake_items_db[item_id])


@router.get(
    "/",
    response_model=PaginatedItemsResponse,
    summary="List items with pagination",
    description="Retrieve a paginated list of items with optional filtering",
)
async def list_items(
    page: int = Query(1, ge=1, description="Page number (starts at 1)"),
    page_size: int = Query(10, ge=1, le=100, description="Items per page (max 100)"),
    category: Optional[str] = Query(None, description="Filter by category"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    search: Optional[str] = Query(None, description="Search in name and description"),
):
    """
    List all items with pagination and filtering.

    Supports the following filters:
    - **category**: Filter by category name
    - **is_active**: Filter by active status
    - **search**: Search in name and description (case-insensitive)

    Pagination:
    - **page**: Page number (starts at 1)
    - **page_size**: Number of items per page (1-100)

    Returns:
    - **items**: List of items for the current page
    - **total**: Total number of items matching filters
    - **page**: Current page number
    - **page_size**: Items per page
    - **pages**: Total number of pages
    """
    # Apply filters
    filtered_items = list(fake_items_db.values())

    if category:
        filtered_items = [
            item for item in filtered_items
            if item["category"].lower() == category.lower()
        ]

    if is_active is not None:
        filtered_items = [
            item for item in filtered_items
            if item["is_active"] == is_active
        ]

    if search:
        search_lower = search.lower()
        filtered_items = [
            item for item in filtered_items
            if search_lower in item["name"].lower()
            or (item["description"] and search_lower in item["description"].lower())
        ]

    # Calculate pagination
    total = len(filtered_items)
    pages = (total + page_size - 1) // page_size if total > 0 else 0

    # Validate page number
    if page > pages and total > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Page {page} does not exist. Total pages: {pages}"
        )

    # Paginate
    skip = (page - 1) * page_size
    paginated_items = filtered_items[skip : skip + page_size]

    return PaginatedItemsResponse(
        items=[Item(**item) for item in paginated_items],
        total=total,
        page=page,
        page_size=page_size,
        pages=pages,
    )


@router.put(
    "/{item_id}",
    response_model=Item,
    summary="Update entire item",
    description="Replace an entire item with new data",
)
async def update_item(item_id: int, item: ItemCreate):
    """
    Update an entire item (all fields required).

    - **item_id**: The ID of the item to update
    - All item fields must be provided

    Use PATCH for partial updates.
    """
    if item_id not in fake_items_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item with id {item_id} not found"
        )

    # Keep original creation data
    existing_item = fake_items_db[item_id]

    # Update with new data
    item_data = item.model_dump()
    item_data.update({
        "id": item_id,
        "created_at": existing_item["created_at"],
        "updated_at": get_current_time(),
    })

    fake_items_db[item_id] = item_data

    return Item(**item_data)


@router.patch(
    "/{item_id}",
    response_model=Item,
    summary="Partially update item",
    description="Update specific fields of an item",
)
async def partial_update_item(item_id: int, item: ItemUpdate):
    """
    Partially update an item (only provided fields are updated).

    - **item_id**: The ID of the item to update
    - Only include fields you want to update
    - Unspecified fields remain unchanged
    """
    if item_id not in fake_items_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item with id {item_id} not found"
        )

    existing_item = fake_items_db[item_id].copy()

    # Update only provided fields
    update_data = item.model_dump(exclude_unset=True)
    existing_item.update(update_data)
    existing_item["updated_at"] = get_current_time()

    fake_items_db[item_id] = existing_item

    return Item(**existing_item)


@router.delete(
    "/{item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete item",
    description="Delete an item by ID",
    responses={
        204: {"description": "Item deleted successfully"},
        404: {"description": "Item not found"},
    }
)
async def delete_item(item_id: int):
    """
    Delete an item.

    - **item_id**: The ID of the item to delete

    Returns no content on success.
    """
    if item_id not in fake_items_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item with id {item_id} not found"
        )

    del fake_items_db[item_id]
    # FastAPI automatically returns 204 No Content


# ============================================================================
# ADDITIONAL ENDPOINTS (OPTIONAL)
# ============================================================================

@router.get(
    "/{item_id}/exists",
    response_model=bool,
    summary="Check if item exists",
)
async def item_exists(item_id: int):
    """Check if an item exists without retrieving its data"""
    return item_id in fake_items_db


@router.get(
    "/category/{category}",
    response_model=List[Item],
    summary="Get items by category",
)
async def get_items_by_category(category: str):
    """Get all items in a specific category"""
    items = [
        Item(**item) for item in fake_items_db.values()
        if item["category"].lower() == category.lower()
    ]

    if not items:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No items found in category '{category}'"
        )

    return items
