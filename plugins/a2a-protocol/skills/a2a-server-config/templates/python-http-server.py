"""
A2A HTTP Server with FastAPI
Provides HTTP transport for Agent-to-Agent communication following MCP standards.
"""

import os
from typing import Any
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# SECURITY: NEVER hardcode API keys - always use environment variables
API_KEY = os.getenv("ANTHROPIC_API_KEY", "your_anthropic_key_here")

app = FastAPI(title="A2A HTTP Server", version="1.0.0")

# CORS configuration for cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class MessageRequest(BaseModel):
    """Request model for A2A messages"""
    content: str
    agent_id: str | None = None
    context: dict[str, Any] | None = None


class MessageResponse(BaseModel):
    """Response model for A2A messages"""
    content: str
    agent_id: str
    status: str


@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "ok", "server": "A2A HTTP Server"}


@app.get("/health")
async def health():
    """Detailed health check"""
    return {
        "status": "healthy",
        "transport": "http",
        "version": "1.0.0"
    }


@app.post("/message")
async def handle_message(request: MessageRequest) -> MessageResponse:
    """
    Handle A2A message exchange

    Example request:
    {
        "content": "Hello from agent",
        "agent_id": "agent-1",
        "context": {"task": "greeting"}
    }
    """
    # Process message here
    # This is where you'd integrate with your agent logic

    response_content = f"Received: {request.content}"

    return MessageResponse(
        content=response_content,
        agent_id=request.agent_id or "server",
        status="success"
    )


if __name__ == "__main__":
    import uvicorn

    # Configuration from environment
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    reload = os.getenv("RELOAD", "false").lower() == "true"

    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=reload,
        log_level="info"
    )
