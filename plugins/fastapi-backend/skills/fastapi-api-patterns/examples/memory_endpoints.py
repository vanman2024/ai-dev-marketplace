"""
Memory/Context Management API Example for AI Applications

This example demonstrates endpoints for managing AI conversation context:
- Store conversation sessions
- Retrieve context by session ID
- Update context with new messages
- Clear old contexts
- Search contexts by keywords
- Pagination for large context histories
"""

from fastapi import APIRouter, HTTPException, Depends, status, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from enum import Enum

# ============================================================================
# MODELS
# ============================================================================

class MessageRole(str, Enum):
    """Message role in conversation"""
    system = "system"
    user = "user"
    assistant = "assistant"
    function = "function"


class ConversationMessage(BaseModel):
    """Single message in conversation"""
    role: MessageRole = Field(..., description="Message role")
    content: str = Field(..., description="Message content")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    metadata: Optional[Dict[str, Any]] = Field(default=None, description="Additional metadata")


class ContextBase(BaseModel):
    """Base context model"""
    session_id: str = Field(..., description="Unique session identifier")
    user_id: str = Field(..., description="User identifier")
    application: str = Field(..., description="Application/agent identifier")
    system_prompt: Optional[str] = Field(None, description="System prompt for this session")
    max_messages: int = Field(default=50, ge=1, le=500, description="Max messages to retain")


class ContextCreate(ContextBase):
    """Model for creating new context"""
    initial_messages: Optional[List[ConversationMessage]] = Field(
        default=None,
        description="Initial messages to populate context"
    )


class ContextUpdate(BaseModel):
    """Model for updating context"""
    system_prompt: Optional[str] = None
    max_messages: Optional[int] = Field(None, ge=1, le=500)


class Context(ContextBase):
    """Context with full data"""
    id: int
    messages: List[ConversationMessage] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime
    last_accessed: datetime
    message_count: int = 0

    class Config:
        from_attributes = True


class AddMessagesRequest(BaseModel):
    """Request to add messages to context"""
    messages: List[ConversationMessage] = Field(..., min_items=1)


class PaginatedContexts(BaseModel):
    """Paginated contexts response"""
    contexts: List[Context]
    total: int
    page: int
    page_size: int
    pages: int


class ContextSummary(BaseModel):
    """Summary of context without full messages"""
    id: int
    session_id: str
    user_id: str
    application: str
    message_count: int
    created_at: datetime
    updated_at: datetime
    last_accessed: datetime


# ============================================================================
# ROUTER SETUP
# ============================================================================

router = APIRouter(
    prefix="/memory",
    tags=["memory", "context"],
    responses={404: {"description": "Context not found"}},
)


# ============================================================================
# IN-MEMORY DATABASE
# ============================================================================

contexts_db: dict[int, dict] = {}
session_index: dict[str, int] = {}  # session_id -> context_id
next_context_id = 1


def get_current_time():
    return datetime.utcnow()


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def trim_messages(messages: List[dict], max_messages: int) -> List[dict]:
    """Keep only the most recent messages"""
    if len(messages) <= max_messages:
        return messages

    # Keep system messages and most recent user/assistant messages
    system_messages = [m for m in messages if m["role"] == MessageRole.system]
    other_messages = [m for m in messages if m["role"] != MessageRole.system]

    # Sort by timestamp
    other_messages.sort(key=lambda m: m["timestamp"])

    # Keep most recent
    keep_count = max_messages - len(system_messages)
    recent_messages = other_messages[-keep_count:] if keep_count > 0 else []

    return system_messages + recent_messages


# ============================================================================
# ENDPOINTS
# ============================================================================

@router.post(
    "/contexts",
    response_model=Context,
    status_code=status.HTTP_201_CREATED,
    summary="Create conversation context",
)
async def create_context(context: ContextCreate):
    """
    Create a new conversation context.

    - **session_id**: Unique session identifier (must be unique)
    - **user_id**: User identifier
    - **application**: Application/agent identifier
    - **system_prompt**: Optional system prompt for this session
    - **max_messages**: Maximum number of messages to retain (default: 50)
    - **initial_messages**: Optional initial messages
    """
    global next_context_id

    # Check if session_id already exists
    if context.session_id in session_index:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Context with session_id '{context.session_id}' already exists"
        )

    # Create context
    current_time = get_current_time()
    messages = []

    if context.initial_messages:
        messages = [msg.model_dump() for msg in context.initial_messages]

    context_data = context.model_dump(exclude={'initial_messages'})
    context_data.update({
        "id": next_context_id,
        "messages": messages,
        "created_at": current_time,
        "updated_at": current_time,
        "last_accessed": current_time,
        "message_count": len(messages),
    })

    contexts_db[next_context_id] = context_data
    session_index[context.session_id] = next_context_id
    next_context_id += 1

    return Context(**context_data)


@router.get(
    "/contexts/{context_id}",
    response_model=Context,
    summary="Get context by ID",
)
async def get_context(context_id: int):
    """Get a conversation context by ID"""
    if context_id not in contexts_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Context with id {context_id} not found"
        )

    context = contexts_db[context_id]
    context["last_accessed"] = get_current_time()

    return Context(**context)


@router.get(
    "/sessions/{session_id}",
    response_model=Context,
    summary="Get context by session ID",
)
async def get_context_by_session(session_id: str):
    """Get a conversation context by session ID"""
    context_id = session_index.get(session_id)

    if not context_id or context_id not in contexts_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Context with session_id '{session_id}' not found"
        )

    context = contexts_db[context_id]
    context["last_accessed"] = get_current_time()

    return Context(**context)


@router.post(
    "/contexts/{context_id}/messages",
    response_model=Context,
    summary="Add messages to context",
)
async def add_messages(
    context_id: int,
    request: AddMessagesRequest,
):
    """
    Add new messages to a conversation context.

    Messages are automatically trimmed to max_messages limit.
    """
    if context_id not in contexts_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Context with id {context_id} not found"
        )

    context = contexts_db[context_id]

    # Add new messages
    new_messages = [msg.model_dump() for msg in request.messages]
    context["messages"].extend(new_messages)

    # Trim if needed
    context["messages"] = trim_messages(context["messages"], context["max_messages"])

    # Update metadata
    context["message_count"] = len(context["messages"])
    context["updated_at"] = get_current_time()
    context["last_accessed"] = get_current_time()

    return Context(**context)


@router.patch(
    "/contexts/{context_id}",
    response_model=Context,
    summary="Update context settings",
)
async def update_context(
    context_id: int,
    update: ContextUpdate,
):
    """Update context settings (system prompt, max messages)"""
    if context_id not in contexts_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Context with id {context_id} not found"
        )

    context = contexts_db[context_id]

    # Update fields
    update_data = update.model_dump(exclude_unset=True)

    if "max_messages" in update_data:
        new_max = update_data["max_messages"]
        context["max_messages"] = new_max
        # Trim messages if new max is smaller
        context["messages"] = trim_messages(context["messages"], new_max)
        context["message_count"] = len(context["messages"])

    if "system_prompt" in update_data:
        context["system_prompt"] = update_data["system_prompt"]

    context["updated_at"] = get_current_time()

    return Context(**context)


@router.delete(
    "/contexts/{context_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete context",
)
async def delete_context(context_id: int):
    """Delete a conversation context"""
    if context_id not in contexts_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Context with id {context_id} not found"
        )

    context = contexts_db[context_id]
    session_id = context["session_id"]

    del contexts_db[context_id]
    del session_index[session_id]


@router.post(
    "/contexts/{context_id}/clear",
    response_model=Context,
    summary="Clear context messages",
)
async def clear_context(
    context_id: int,
    keep_system: bool = Query(True, description="Keep system messages"),
):
    """
    Clear all messages from a context.

    Optionally keep system messages.
    """
    if context_id not in contexts_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Context with id {context_id} not found"
        )

    context = contexts_db[context_id]

    if keep_system:
        # Keep only system messages
        context["messages"] = [
            m for m in context["messages"]
            if m["role"] == MessageRole.system
        ]
    else:
        # Clear all messages
        context["messages"] = []

    context["message_count"] = len(context["messages"])
    context["updated_at"] = get_current_time()

    return Context(**context)


@router.get(
    "/contexts",
    response_model=PaginatedContexts,
    summary="List contexts",
)
async def list_contexts(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user_id: Optional[str] = Query(None, description="Filter by user ID"),
    application: Optional[str] = Query(None, description="Filter by application"),
    min_messages: Optional[int] = Query(None, ge=0, description="Min message count"),
):
    """
    List conversation contexts with filtering.

    Filters:
    - **user_id**: Filter by user ID
    - **application**: Filter by application/agent
    - **min_messages**: Filter by minimum message count
    """
    # Apply filters
    filtered_contexts = list(contexts_db.values())

    if user_id:
        filtered_contexts = [c for c in filtered_contexts if c["user_id"] == user_id]

    if application:
        filtered_contexts = [c for c in filtered_contexts if c["application"] == application]

    if min_messages is not None:
        filtered_contexts = [c for c in filtered_contexts if c["message_count"] >= min_messages]

    # Sort by last accessed (most recent first)
    filtered_contexts.sort(key=lambda c: c["last_accessed"], reverse=True)

    # Paginate
    total = len(filtered_contexts)
    pages = (total + page_size - 1) // page_size if total > 0 else 0
    skip = (page - 1) * page_size
    paginated = filtered_contexts[skip : skip + page_size]

    return PaginatedContexts(
        contexts=[Context(**c) for c in paginated],
        total=total,
        page=page,
        page_size=page_size,
        pages=pages,
    )


@router.get(
    "/users/{user_id}/contexts",
    response_model=List[ContextSummary],
    summary="Get user's contexts",
)
async def get_user_contexts(
    user_id: str,
    limit: int = Query(50, ge=1, le=100),
):
    """Get all contexts for a specific user"""
    user_contexts = [
        c for c in contexts_db.values()
        if c["user_id"] == user_id
    ]

    # Sort by last accessed
    user_contexts.sort(key=lambda c: c["last_accessed"], reverse=True)

    # Limit results
    user_contexts = user_contexts[:limit]

    return [ContextSummary(**c) for c in user_contexts]


@router.post(
    "/contexts/cleanup",
    summary="Cleanup old contexts",
)
async def cleanup_old_contexts(
    days_old: int = Query(30, ge=1, description="Delete contexts older than this many days"),
    dry_run: bool = Query(True, description="Preview without deleting"),
):
    """
    Cleanup contexts that haven't been accessed recently.

    Use dry_run=True to preview what would be deleted.
    """
    cutoff_time = get_current_time() - timedelta(days=days_old)

    old_contexts = [
        c for c in contexts_db.values()
        if c["last_accessed"] < cutoff_time
    ]

    if dry_run:
        return {
            "dry_run": True,
            "contexts_to_delete": len(old_contexts),
            "cutoff_date": cutoff_time,
            "preview": [
                {
                    "id": c["id"],
                    "session_id": c["session_id"],
                    "last_accessed": c["last_accessed"],
                }
                for c in old_contexts[:10]  # Show first 10
            ]
        }

    # Actually delete
    deleted_count = 0
    for context in old_contexts:
        context_id = context["id"]
        session_id = context["session_id"]
        del contexts_db[context_id]
        del session_index[session_id]
        deleted_count += 1

    return {
        "dry_run": False,
        "deleted": deleted_count,
        "cutoff_date": cutoff_time,
    }


@router.get(
    "/contexts/search",
    response_model=PaginatedContexts,
    summary="Search contexts",
)
async def search_contexts(
    query: str = Query(..., min_length=1, description="Search in messages"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    """Search for contexts containing specific text in messages"""
    query_lower = query.lower()

    # Search in message content
    matching_contexts = []
    for context in contexts_db.values():
        for message in context["messages"]:
            if query_lower in message["content"].lower():
                matching_contexts.append(context)
                break  # Don't add same context multiple times

    # Sort by last accessed
    matching_contexts.sort(key=lambda c: c["last_accessed"], reverse=True)

    # Paginate
    total = len(matching_contexts)
    pages = (total + page_size - 1) // page_size if total > 0 else 0
    skip = (page - 1) * page_size
    paginated = matching_contexts[skip : skip + page_size]

    return PaginatedContexts(
        contexts=[Context(**c) for c in paginated],
        total=total,
        page=page,
        page_size=page_size,
        pages=pages,
    )
