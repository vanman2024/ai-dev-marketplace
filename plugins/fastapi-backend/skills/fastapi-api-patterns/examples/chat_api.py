"""
Chat API Example - Complete CRUD with Search and Filtering

This example demonstrates a production-ready chat message API with:
- Full CRUD operations
- Pagination and filtering
- Search functionality
- User and channel filtering
- Date range queries
- Error handling
"""

from fastapi import APIRouter, HTTPException, Depends, status, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum

# ============================================================================
# MODELS
# ============================================================================

class MessageType(str, Enum):
    """Message type enumeration"""
    text = "text"
    image = "image"
    file = "file"
    system = "system"


class MessageBase(BaseModel):
    """Base message model"""
    content: str = Field(..., min_length=1, max_length=5000)
    user_id: int = Field(..., description="ID of user who sent the message")
    channel_id: int = Field(..., description="ID of channel/conversation")
    message_type: MessageType = Field(default=MessageType.text)
    metadata: Optional[dict] = Field(default=None, description="Additional metadata")


class MessageCreate(MessageBase):
    """Model for creating messages"""
    pass


class MessageUpdate(BaseModel):
    """Model for updating messages"""
    content: Optional[str] = Field(None, min_length=1, max_length=5000)
    metadata: Optional[dict] = None


class Message(MessageBase):
    """Message with ID and timestamps"""
    id: int
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

    class Config:
        from_attributes = True


class PaginatedMessages(BaseModel):
    """Paginated message response"""
    messages: List[Message]
    total: int
    page: int
    page_size: int
    pages: int


# ============================================================================
# ROUTER SETUP
# ============================================================================

router = APIRouter(
    prefix="/chat",
    tags=["chat"],
    responses={404: {"description": "Message not found"}},
)


# ============================================================================
# IN-MEMORY DATABASE
# ============================================================================

messages_db: dict[int, dict] = {}
next_message_id = 1


def get_current_time():
    return datetime.utcnow()


# ============================================================================
# ENDPOINTS
# ============================================================================

@router.post(
    "/messages",
    response_model=Message,
    status_code=status.HTTP_201_CREATED,
    summary="Send a message",
)
async def send_message(message: MessageCreate):
    """
    Send a new message to a channel.

    - **content**: Message content (1-5000 characters)
    - **user_id**: ID of the user sending the message
    - **channel_id**: ID of the channel/conversation
    - **message_type**: Type of message (text, image, file, system)
    - **metadata**: Optional metadata (e.g., file URLs, image dimensions)
    """
    global next_message_id

    current_time = get_current_time()
    message_data = message.model_dump()
    message_data.update({
        "id": next_message_id,
        "created_at": current_time,
        "updated_at": current_time,
        "is_deleted": False,
    })

    messages_db[next_message_id] = message_data
    next_message_id += 1

    return Message(**message_data)


@router.get(
    "/messages/{message_id}",
    response_model=Message,
    summary="Get message by ID",
)
async def get_message(message_id: int):
    """Get a specific message by ID"""
    if message_id not in messages_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Message with id {message_id} not found"
        )

    message = messages_db[message_id]

    if message["is_deleted"]:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message has been deleted"
        )

    return Message(**message)


@router.get(
    "/messages",
    response_model=PaginatedMessages,
    summary="List messages with filters",
)
async def list_messages(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Messages per page"),
    channel_id: Optional[int] = Query(None, description="Filter by channel ID"),
    user_id: Optional[int] = Query(None, description="Filter by user ID"),
    message_type: Optional[MessageType] = Query(None, description="Filter by message type"),
    search: Optional[str] = Query(None, description="Search in message content"),
    after: Optional[datetime] = Query(None, description="Messages after this time"),
    before: Optional[datetime] = Query(None, description="Messages before this time"),
    include_deleted: bool = Query(False, description="Include deleted messages"),
):
    """
    List messages with comprehensive filtering.

    Filters:
    - **channel_id**: Get messages from specific channel
    - **user_id**: Get messages from specific user
    - **message_type**: Filter by message type
    - **search**: Search in message content (case-insensitive)
    - **after**: Get messages after timestamp
    - **before**: Get messages before timestamp
    - **include_deleted**: Include soft-deleted messages

    Pagination:
    - **page**: Page number (starts at 1)
    - **page_size**: Messages per page (max 100)
    """
    # Start with all messages
    filtered_messages = list(messages_db.values())

    # Apply filters
    if not include_deleted:
        filtered_messages = [m for m in filtered_messages if not m["is_deleted"]]

    if channel_id is not None:
        filtered_messages = [m for m in filtered_messages if m["channel_id"] == channel_id]

    if user_id is not None:
        filtered_messages = [m for m in filtered_messages if m["user_id"] == user_id]

    if message_type is not None:
        filtered_messages = [m for m in filtered_messages if m["message_type"] == message_type]

    if search:
        search_lower = search.lower()
        filtered_messages = [
            m for m in filtered_messages
            if search_lower in m["content"].lower()
        ]

    if after:
        filtered_messages = [m for m in filtered_messages if m["created_at"] >= after]

    if before:
        filtered_messages = [m for m in filtered_messages if m["created_at"] <= before]

    # Sort by creation time (newest first)
    filtered_messages.sort(key=lambda m: m["created_at"], reverse=True)

    # Calculate pagination
    total = len(filtered_messages)
    pages = (total + page_size - 1) // page_size if total > 0 else 0

    if page > pages and total > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Page {page} does not exist. Total pages: {pages}"
        )

    # Paginate
    skip = (page - 1) * page_size
    paginated_messages = filtered_messages[skip : skip + page_size]

    return PaginatedMessages(
        messages=[Message(**m) for m in paginated_messages],
        total=total,
        page=page,
        page_size=page_size,
        pages=pages,
    )


@router.get(
    "/channels/{channel_id}/messages",
    response_model=List[Message],
    summary="Get recent messages in channel",
)
async def get_channel_messages(
    channel_id: int,
    limit: int = Query(50, ge=1, le=100, description="Number of messages"),
):
    """
    Get recent messages from a specific channel.

    Returns messages sorted by creation time (newest first).
    """
    channel_messages = [
        Message(**m) for m in messages_db.values()
        if m["channel_id"] == channel_id and not m["is_deleted"]
    ]

    # Sort by creation time (newest first)
    channel_messages.sort(key=lambda m: m.created_at, reverse=True)

    return channel_messages[:limit]


@router.patch(
    "/messages/{message_id}",
    response_model=Message,
    summary="Edit message",
)
async def edit_message(
    message_id: int,
    update: MessageUpdate,
    user_id: int = Query(..., description="ID of user editing the message"),
):
    """
    Edit a message (content or metadata).

    Only the user who sent the message can edit it.
    """
    if message_id not in messages_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Message with id {message_id} not found"
        )

    message = messages_db[message_id]

    if message["is_deleted"]:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cannot edit deleted message"
        )

    # Check if user owns the message
    if message["user_id"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only edit your own messages"
        )

    # Update message
    update_data = update.model_dump(exclude_unset=True)
    message.update(update_data)
    message["updated_at"] = get_current_time()

    return Message(**message)


@router.delete(
    "/messages/{message_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete message",
)
async def delete_message(
    message_id: int,
    user_id: int = Query(..., description="ID of user deleting the message"),
):
    """
    Delete a message (soft delete).

    Only the user who sent the message can delete it.
    """
    if message_id not in messages_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Message with id {message_id} not found"
        )

    message = messages_db[message_id]

    # Check if user owns the message
    if message["user_id"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own messages"
        )

    # Soft delete
    message["is_deleted"] = True
    message["updated_at"] = get_current_time()


@router.get(
    "/users/{user_id}/messages",
    response_model=List[Message],
    summary="Get user's messages",
)
async def get_user_messages(
    user_id: int,
    limit: int = Query(50, ge=1, le=100),
):
    """Get all messages sent by a specific user"""
    user_messages = [
        Message(**m) for m in messages_db.values()
        if m["user_id"] == user_id and not m["is_deleted"]
    ]

    user_messages.sort(key=lambda m: m.created_at, reverse=True)

    return user_messages[:limit]


@router.post(
    "/messages/search",
    response_model=PaginatedMessages,
    summary="Advanced message search",
)
async def search_messages(
    query: str = Query(..., min_length=1, description="Search query"),
    channel_ids: Optional[List[int]] = Query(None, description="Filter by channel IDs"),
    user_ids: Optional[List[int]] = Query(None, description="Filter by user IDs"),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
):
    """
    Advanced message search across channels.

    Search in message content with optional filters for specific channels and users.
    """
    query_lower = query.lower()

    # Filter messages
    results = [
        m for m in messages_db.values()
        if not m["is_deleted"] and query_lower in m["content"].lower()
    ]

    if channel_ids:
        results = [m for m in results if m["channel_id"] in channel_ids]

    if user_ids:
        results = [m for m in results if m["user_id"] in user_ids]

    # Sort by relevance (messages with query at start first) then by time
    results.sort(
        key=lambda m: (
            not m["content"].lower().startswith(query_lower),
            -m["created_at"].timestamp()
        )
    )

    # Paginate
    total = len(results)
    pages = (total + page_size - 1) // page_size if total > 0 else 0
    skip = (page - 1) * page_size
    paginated = results[skip : skip + page_size]

    return PaginatedMessages(
        messages=[Message(**m) for m in paginated],
        total=total,
        page=page,
        page_size=page_size,
        pages=pages,
    )


# ============================================================================
# STATISTICS ENDPOINTS
# ============================================================================

@router.get(
    "/channels/{channel_id}/stats",
    summary="Get channel statistics",
)
async def get_channel_stats(channel_id: int):
    """Get message statistics for a channel"""
    channel_messages = [
        m for m in messages_db.values()
        if m["channel_id"] == channel_id and not m["is_deleted"]
    ]

    if not channel_messages:
        return {
            "channel_id": channel_id,
            "total_messages": 0,
            "unique_users": 0,
            "message_types": {},
        }

    # Calculate stats
    unique_users = len(set(m["user_id"] for m in channel_messages))
    message_types = {}

    for msg in channel_messages:
        msg_type = msg["message_type"]
        message_types[msg_type] = message_types.get(msg_type, 0) + 1

    return {
        "channel_id": channel_id,
        "total_messages": len(channel_messages),
        "unique_users": unique_users,
        "message_types": message_types,
        "last_message_at": max(m["created_at"] for m in channel_messages),
    }
