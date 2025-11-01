"""
Memory API Routes for FastAPI
Complete REST API endpoints for Mem0 memory operations
"""

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status
from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


# Request Models
class ConversationRequest(BaseModel):
    """Request model for adding conversations"""

    messages: List[Dict[str, str]] = Field(..., description="Conversation messages")
    session_id: Optional[str] = Field(None, description="Session identifier")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata")

    class Config:
        json_schema_extra = {
            "example": {
                "messages": [
                    {"role": "user", "content": "Hello, I love pizza"},
                    {
                        "role": "assistant",
                        "content": "Great! I'll remember that you love pizza.",
                    },
                ],
                "session_id": "session_123",
                "metadata": {"importance": "high"},
            }
        }


class SearchRequest(BaseModel):
    """Request model for searching memories"""

    query: str = Field(..., description="Search query")
    limit: int = Field(5, ge=1, le=20, description="Number of results")
    filters: Optional[Dict[str, Any]] = Field(None, description="Search filters")

    class Config:
        json_schema_extra = {
            "example": {
                "query": "What food does the user like?",
                "limit": 5,
                "filters": {"category": "preferences"},
            }
        }


class PreferenceRequest(BaseModel):
    """Request model for adding preferences"""

    preference: str = Field(..., description="User preference")
    category: str = Field("general", description="Preference category")

    class Config:
        json_schema_extra = {
            "example": {
                "preference": "I prefer concise responses",
                "category": "communication",
            }
        }


class MemoryUpdateRequest(BaseModel):
    """Request model for updating memories"""

    memory_id: str = Field(..., description="Memory identifier")
    data: Dict[str, Any] = Field(..., description="Updated memory data")


class MemoryDeleteRequest(BaseModel):
    """Request model for deleting memories"""

    memory_id: str = Field(..., description="Memory identifier")


# Response Models
class MemoryResponse(BaseModel):
    """Standard memory operation response"""

    status: str
    message: str
    data: Optional[Dict[str, Any]] = None


# Routes
@router.post("/conversation", response_model=MemoryResponse)
async def add_conversation(
    request: ConversationRequest,
    background_tasks: BackgroundTasks,
    user_id: str = Depends(lambda: "get_current_user"),  # Replace with actual dependency
    memory_service=Depends(lambda: "get_memory_service"),  # Replace with actual dependency
):
    """
    Add conversation to user's memory.

    - **messages**: List of conversation messages with role and content
    - **session_id**: Optional session identifier for grouping
    - **metadata**: Additional metadata for conversation tracking
    """
    try:
        # Add to memory in background to not block response
        background_tasks.add_task(
            memory_service.add_conversation, user_id, request.messages, request.metadata
        )

        return MemoryResponse(
            status="success",
            message="Conversation queued for storage",
            data={
                "user_id": user_id,
                "session_id": request.session_id,
                "message_count": len(request.messages),
            },
        )
    except Exception as e:
        logger.error(f"Error adding conversation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to add conversation",
        )


@router.post("/search")
async def search_memories(
    request: SearchRequest,
    user_id: str = Depends(lambda: "get_current_user"),
    memory_service=Depends(lambda: "get_memory_service"),
):
    """
    Search user memories for relevant context.

    - **query**: Search query text
    - **limit**: Maximum number of results (1-20)
    - **filters**: Optional filters for narrowing search
    """
    try:
        memories = await memory_service.search_memories(
            query=request.query,
            user_id=user_id,
            limit=request.limit,
            filters=request.filters,
        )

        return {
            "query": request.query,
            "results": memories,
            "count": len(memories),
            "user_id": user_id,
        }
    except Exception as e:
        logger.error(f"Error searching memories: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search memories",
        )


@router.get("/summary")
async def get_memory_summary(
    user_id: str = Depends(lambda: "get_current_user"),
    memory_service=Depends(lambda: "get_memory_service"),
):
    """
    Get user memory summary and statistics.

    Returns comprehensive summary including:
    - Total memories count
    - Recent conversations
    - Memory categories
    - User preferences
    """
    try:
        summary = await memory_service.get_user_summary(user_id)

        return {"user_id": user_id, "summary": summary, "timestamp": "2025-10-31"}
    except Exception as e:
        logger.error(f"Error getting summary: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get memory summary",
        )


@router.get("/all")
async def get_all_memories(
    limit: int = 100,
    user_id: str = Depends(lambda: "get_current_user"),
    memory_service=Depends(lambda: "get_memory_service"),
):
    """
    Get all memories for a user.

    - **limit**: Maximum number of memories to retrieve (default: 100)
    """
    try:
        memories = await memory_service.get_all_memories(user_id=user_id, limit=limit)

        return {
            "user_id": user_id,
            "memories": memories,
            "count": len(memories),
            "limit": limit,
        }
    except Exception as e:
        logger.error(f"Error getting all memories: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get memories",
        )


@router.post("/preference", response_model=MemoryResponse)
async def add_user_preference(
    request: PreferenceRequest,
    user_id: str = Depends(lambda: "get_current_user"),
    memory_service=Depends(lambda: "get_memory_service"),
):
    """
    Add user preference to memory.

    - **preference**: User preference description
    - **category**: Preference category (e.g., communication, ui, content)
    """
    try:
        success = await memory_service.add_user_preference(
            user_id=user_id, preference=request.preference, category=request.category
        )

        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to add preference",
            )

        return MemoryResponse(
            status="success",
            message="Preference added successfully",
            data={
                "preference": request.preference,
                "category": request.category,
                "user_id": user_id,
            },
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error adding preference: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to add preference",
        )


@router.put("/update", response_model=MemoryResponse)
async def update_memory(
    request: MemoryUpdateRequest,
    user_id: str = Depends(lambda: "get_current_user"),
    memory_service=Depends(lambda: "get_memory_service"),
):
    """
    Update a specific memory.

    - **memory_id**: Memory identifier
    - **data**: Updated memory data
    """
    try:
        success = await memory_service.update_memory(
            memory_id=request.memory_id, user_id=user_id, data=request.data
        )

        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update memory",
            )

        return MemoryResponse(
            status="success",
            message="Memory updated successfully",
            data={"memory_id": request.memory_id},
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating memory: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update memory",
        )


@router.delete("/memory/{memory_id}", response_model=MemoryResponse)
async def delete_memory(
    memory_id: str,
    user_id: str = Depends(lambda: "get_current_user"),
    memory_service=Depends(lambda: "get_memory_service"),
):
    """
    Delete a specific memory.

    - **memory_id**: Memory identifier
    """
    try:
        success = await memory_service.delete_memory(
            memory_id=memory_id, user_id=user_id
        )

        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Memory not found"
            )

        return MemoryResponse(
            status="success",
            message="Memory deleted successfully",
            data={"memory_id": memory_id},
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting memory: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete memory",
        )


@router.delete("/user/{target_user_id}/all", response_model=MemoryResponse)
async def delete_all_user_memories(
    target_user_id: str,
    user_id: str = Depends(lambda: "get_current_user"),
    memory_service=Depends(lambda: "get_memory_service"),
):
    """
    Delete all memories for a user (requires admin or self).

    - **target_user_id**: User ID whose memories to delete
    """
    try:
        # Authorization check
        if user_id != target_user_id:
            # Add admin check here in production
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete other users' memories",
            )

        success = await memory_service.delete_all_memories(user_id=target_user_id)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete memories",
            )

        return MemoryResponse(
            status="success",
            message=f"All memories deleted for user {target_user_id}",
            data={"user_id": target_user_id},
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting all memories: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete memories",
        )


@router.get("/stats")
async def get_memory_stats(
    memory_service=Depends(lambda: "get_memory_service"),
):
    """
    Get memory service statistics.

    Returns overall service status and configuration.
    """
    try:
        stats = memory_service.get_memory_stats()
        return {"stats": stats, "timestamp": "2025-10-31"}
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get statistics",
        )
