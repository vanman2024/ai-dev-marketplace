"""
Complete Chat with Memory Example
Demonstrates chat application with Mem0 conversation persistence
"""

from fastapi import FastAPI, Depends, BackgroundTasks
from pydantic import BaseModel, Field
from typing import List, Dict, Optional
from contextlib import asynccontextmanager
import logging

# Import memory service (adjust path as needed)
# from app.services.memory_service import MemoryService
# from app.api.deps import get_current_user, get_memory_service

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Models
class ChatMessage(BaseModel):
    """Chat message model"""

    role: str = Field(..., description="Message role: user or assistant")
    content: str = Field(..., description="Message content")


class ChatRequest(BaseModel):
    """Chat request with memory support"""

    message: str = Field(..., description="User message")
    session_id: Optional[str] = Field(None, description="Session ID for grouping")
    use_memory: bool = Field(True, description="Whether to use memory context")
    memory_search_limit: int = Field(3, description="Number of memories to retrieve")


class ChatResponse(BaseModel):
    """Chat response with memory info"""

    response: str
    memories_used: List[Dict] = []
    session_id: Optional[str] = None
    memory_stored: bool = False


# Application setup
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for memory service initialization"""
    # Startup
    logger.info("Initializing chat with memory service...")

    # Initialize memory service
    # memory_service = MemoryService(settings)
    # app.state.memory_service = memory_service

    logger.info("Memory service initialized")

    yield

    # Shutdown
    logger.info("Shutting down...")


app = FastAPI(
    title="Chat with Memory API",
    description="FastAPI chat application with Mem0 memory integration",
    version="1.0.0",
    lifespan=lifespan,
)


# Chat endpoint with memory
@app.post("/chat", response_model=ChatResponse)
async def chat_with_memory(
    request: ChatRequest,
    background_tasks: BackgroundTasks,
    # user_id: str = Depends(get_current_user),
    # memory_service = Depends(get_memory_service)
):
    """
    Chat endpoint with memory integration.

    Features:
    - Retrieves relevant conversation history
    - Generates context-aware responses
    - Stores conversation in background
    - Session management
    """
    user_id = "demo_user"  # Replace with actual user_id from auth

    try:
        memories_used = []

        # 1. Retrieve relevant memories if enabled
        if request.use_memory:
            logger.info(f"Searching memories for user {user_id}")
            # memories = await memory_service.search_memories(
            #     query=request.message,
            #     user_id=user_id,
            #     limit=request.memory_search_limit
            # )
            memories = []  # Placeholder

            memories_used = [
                {"memory": mem.get("memory", ""), "score": mem.get("score", 0)}
                for mem in memories
            ]

            logger.info(f"Found {len(memories_used)} relevant memories")

        # 2. Build context from memories
        context = ""
        if memories_used:
            context = "Relevant context from previous conversations:\n"
            for mem in memories_used:
                context += f"- {mem['memory']}\n"

        # 3. Generate AI response (placeholder - integrate with your AI service)
        # For demo, simple echo with context awareness
        if context:
            ai_response = f"[Based on your history] {request.message}"
        else:
            ai_response = f"Response to: {request.message}"

        # 4. Store conversation in background
        conversation_messages = [
            {"role": "user", "content": request.message},
            {"role": "assistant", "content": ai_response},
        ]

        metadata = {
            "session_id": request.session_id,
            "memory_context_used": len(memories_used),
        }

        # background_tasks.add_task(
        #     memory_service.add_conversation,
        #     user_id,
        #     conversation_messages,
        #     metadata
        # )

        logger.info(f"Conversation queued for storage (user: {user_id})")

        return ChatResponse(
            response=ai_response,
            memories_used=memories_used,
            session_id=request.session_id,
            memory_stored=True,
        )

    except Exception as e:
        logger.error(f"Error in chat: {e}")
        return ChatResponse(
            response="Sorry, I encountered an error processing your message.",
            memories_used=[],
            session_id=request.session_id,
            memory_stored=False,
        )


# Stream chat endpoint (for real-time responses)
@app.post("/chat/stream")
async def chat_stream(
    request: ChatRequest,
    background_tasks: BackgroundTasks,
):
    """
    Streaming chat endpoint with memory.

    Returns:
        Server-Sent Events stream with chat response
    """
    from fastapi.responses import StreamingResponse
    import asyncio

    user_id = "demo_user"

    async def generate_stream():
        """Generate streaming response"""
        try:
            # Retrieve memories
            memories = []  # await memory_service.search_memories(...)
            context = (
                "\n".join([m.get("memory", "") for m in memories]) if memories else ""
            )

            # Simulate streaming AI response
            response_text = f"Streaming response with context: {request.message}"

            # Stream word by word
            for word in response_text.split():
                yield f"data: {word}\n\n"
                await asyncio.sleep(0.1)

            # Store conversation in background
            conversation = [
                {"role": "user", "content": request.message},
                {"role": "assistant", "content": response_text},
            ]

            # background_tasks.add_task(
            #     memory_service.add_conversation,
            #     user_id,
            #     conversation
            # )

            yield "data: [DONE]\n\n"

        except Exception as e:
            logger.error(f"Streaming error: {e}")
            yield f"data: Error: {str(e)}\n\n"

    return StreamingResponse(generate_stream(), media_type="text/event-stream")


# Get conversation history
@app.get("/chat/history")
async def get_chat_history(
    session_id: Optional[str] = None,
    limit: int = 10,
    # user_id: str = Depends(get_current_user),
    # memory_service = Depends(get_memory_service)
):
    """
    Get chat history for a user or session.

    Args:
        session_id: Optional session filter
        limit: Maximum number of conversations
    """
    user_id = "demo_user"

    try:
        # Get all memories
        # memories = await memory_service.get_all_memories(user_id, limit=limit * 2)
        memories = []  # Placeholder

        # Filter by session if provided
        if session_id:
            memories = [
                m
                for m in memories
                if m.get("metadata", {}).get("session_id") == session_id
            ]

        # Format as chat history
        history = []
        for mem in memories[:limit]:
            history.append(
                {
                    "memory": mem.get("memory", ""),
                    "timestamp": mem.get("metadata", {}).get("timestamp"),
                    "session_id": mem.get("metadata", {}).get("session_id"),
                }
            )

        return {"user_id": user_id, "history": history, "count": len(history)}

    except Exception as e:
        logger.error(f"Error getting history: {e}")
        return {"user_id": user_id, "history": [], "count": 0, "error": str(e)}


# Clear chat history
@app.delete("/chat/history")
async def clear_chat_history(
    session_id: Optional[str] = None,
    # user_id: str = Depends(get_current_user),
    # memory_service = Depends(get_memory_service)
):
    """
    Clear chat history for a user or session.

    Args:
        session_id: Optional - clear only specific session
    """
    user_id = "demo_user"

    try:
        if session_id:
            # Clear specific session (would need custom implementation)
            return {"message": f"Session {session_id} cleared (not implemented)"}
        else:
            # Clear all memories
            # success = await memory_service.delete_all_memories(user_id)
            success = True

            if success:
                return {"message": f"All chat history cleared for user {user_id}"}
            else:
                return {"error": "Failed to clear history"}

    except Exception as e:
        logger.error(f"Error clearing history: {e}")
        return {"error": str(e)}


# Health check
@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "chat-with-memory",
        "memory": "enabled",
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
