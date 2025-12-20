"""
A2A WebSocket Server
Provides WebSocket transport for bidirectional real-time Agent-to-Agent communication.
"""

import os
import json
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

# SECURITY: NEVER hardcode API keys - always use environment variables
API_KEY = os.getenv("ANTHROPIC_API_KEY", "your_anthropic_key_here")

app = FastAPI(title="A2A WebSocket Server", version="1.0.0")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ConnectionManager:
    """Manage WebSocket connections"""

    def __init__(self):
        self.active_connections: dict[str, WebSocket] = {}

    async def connect(self, agent_id: str, websocket: WebSocket):
        """Accept new connection"""
        await websocket.accept()
        self.active_connections[agent_id] = websocket

    def disconnect(self, agent_id: str):
        """Remove connection"""
        if agent_id in self.active_connections:
            del self.active_connections[agent_id]

    async def send_message(self, agent_id: str, message: dict):
        """Send message to specific agent"""
        if agent_id in self.active_connections:
            websocket = self.active_connections[agent_id]
            await websocket.send_json(message)

    async def broadcast(self, message: dict, exclude: str | None = None):
        """Broadcast message to all connected agents"""
        for agent_id, websocket in self.active_connections.items():
            if agent_id != exclude:
                await websocket.send_json(message)


manager = ConnectionManager()


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "server": "A2A WebSocket Server",
        "active_connections": len(manager.active_connections)
    }


@app.websocket("/ws/{agent_id}")
async def websocket_endpoint(websocket: WebSocket, agent_id: str):
    """
    WebSocket endpoint for bidirectional communication

    Client usage:
        const ws = new WebSocket('ws://localhost:8000/ws/agent-1');
        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            console.log('Received:', data);
        };
        ws.send(JSON.stringify({type: 'message', content: 'Hello'}));
    """
    await manager.connect(agent_id, websocket)

    try:
        # Send welcome message
        await websocket.send_json({
            "type": "connected",
            "agent_id": agent_id,
            "message": f"Connected as {agent_id}"
        })

        # Main message loop
        while True:
            # Receive message
            data = await websocket.receive_text()
            message = json.loads(data)

            # Handle different message types
            msg_type = message.get("type", "message")

            if msg_type == "message":
                # Process agent message
                content = message.get("content", "")

                # Your agent logic here
                response = {
                    "type": "response",
                    "from": "server",
                    "to": agent_id,
                    "content": f"Received: {content}"
                }

                await websocket.send_json(response)

            elif msg_type == "broadcast":
                # Broadcast to all other agents
                broadcast_msg = {
                    "type": "broadcast",
                    "from": agent_id,
                    "content": message.get("content", "")
                }
                await manager.broadcast(broadcast_msg, exclude=agent_id)

            elif msg_type == "ping":
                # Respond to ping
                await websocket.send_json({"type": "pong"})

    except WebSocketDisconnect:
        manager.disconnect(agent_id)

        # Notify other agents
        await manager.broadcast({
            "type": "agent_disconnected",
            "agent_id": agent_id
        })


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
