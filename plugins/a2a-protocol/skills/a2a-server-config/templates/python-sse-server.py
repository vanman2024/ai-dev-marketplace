"""
A2A SSE (Server-Sent Events) Server
Provides SSE transport for real-time streaming Agent-to-Agent communication.
"""

import os
import asyncio
from typing import AsyncGenerator
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sse_starlette.sse import EventSourceResponse

# SECURITY: NEVER hardcode API keys - always use environment variables
API_KEY = os.getenv("ANTHROPIC_API_KEY", "your_anthropic_key_here")

app = FastAPI(title="A2A SSE Server", version="1.0.0")

# CORS configuration for SSE
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


async def event_generator() -> AsyncGenerator[dict, None]:
    """
    Generate SSE events
    Yields events in format: {"event": "message", "data": "content"}
    """
    counter = 0

    while True:
        # Your agent logic here - this is a simple counter example
        counter += 1

        yield {
            "event": "message",
            "data": f"Agent update #{counter}",
            "id": str(counter)
        }

        # Wait before next event
        await asyncio.sleep(2)

        # Stop after 10 events (remove this in production)
        if counter >= 10:
            yield {
                "event": "complete",
                "data": "Stream completed"
            }
            break


@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "ok", "server": "A2A SSE Server"}


@app.get("/events")
async def events():
    """
    SSE endpoint for streaming events

    Client usage:
        const eventSource = new EventSource('http://localhost:8000/events');
        eventSource.onmessage = (event) => {
            console.log('Received:', event.data);
        };
    """
    return EventSourceResponse(event_generator())


@app.get("/stream/{agent_id}")
async def agent_stream(agent_id: str):
    """
    Agent-specific event stream

    Example: GET /stream/agent-1
    """
    async def agent_event_generator() -> AsyncGenerator[dict, None]:
        counter = 0
        while counter < 5:
            counter += 1
            yield {
                "event": "agent_message",
                "data": f"Update from {agent_id}: {counter}",
                "id": f"{agent_id}-{counter}"
            }
            await asyncio.sleep(1)

    return EventSourceResponse(agent_event_generator())


if __name__ == "__main__":
    import uvicorn

    # Configuration from environment
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))

    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        log_level="info"
    )
