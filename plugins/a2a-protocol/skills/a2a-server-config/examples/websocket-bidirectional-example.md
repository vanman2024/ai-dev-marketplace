# WebSocket Bidirectional Communication - Example

This example demonstrates setting up a WebSocket server for full bidirectional real-time communication.

## Step 1: Generate Server

```bash
bash scripts/generate-server.sh websocket python ws_server.py
```

## Step 2: Install Dependencies

Create `requirements.txt`:

```
fastapi==0.104.1
uvicorn[standard]==0.24.0
websockets==12.0
python-dotenv==1.0.0
```

Install:

```bash
pip install -r requirements.txt
```

## Step 3: Configure Environment

Create `.env`:

```bash
PORT=8000
HOST=0.0.0.0
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
ANTHROPIC_API_KEY=your_anthropic_key_here
```

## Step 4: Start Server

```bash
python ws_server.py
```

Output:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
A2A WebSocket Server running on ws://0.0.0.0:8000/ws/{agent_id}
```

## Step 5: Test WebSocket Connection

### Using websocat (CLI)

Install:
```bash
cargo install websocat
# or
brew install websocat
```

Connect:
```bash
websocat ws://localhost:8000/ws/agent-1
```

Send message:
```json
{"type": "message", "content": "Hello from agent-1"}
```

Response:
```json
{"type": "response", "from": "server", "to": "agent-1", "content": "Received: Hello from agent-1"}
```

### Test Transport Script

```bash
bash scripts/test-transport.sh websocket
```

## Client Integration

### JavaScript/Browser Client

```javascript
const agentId = 'agent-1';
const ws = new WebSocket(`ws://localhost:8000/ws/${agentId}`);

// Connection opened
ws.onopen = () => {
  console.log('Connected to WebSocket server');

  // Send message
  ws.send(JSON.stringify({
    type: 'message',
    content: 'Hello from client'
  }));
};

// Receive messages
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Received:', data);

  if (data.type === 'connected') {
    console.log(`Connected as ${data.agent_id}`);
  } else if (data.type === 'response') {
    console.log(`Response: ${data.content}`);
  }
};

// Connection closed
ws.onclose = () => {
  console.log('Disconnected from server');
};

// Error handling
ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};
```

### React Hook for WebSocket

```typescript
import { useEffect, useState, useCallback } from 'react';

interface Message {
  type: string;
  content?: string;
  from?: string;
  [key: string]: any;
}

function useWebSocket(agentId: string) {
  const [ws, setWs] = useState<WebSocket | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const websocket = new WebSocket(`ws://localhost:8000/ws/${agentId}`);

    websocket.onopen = () => {
      setIsConnected(true);
      console.log('WebSocket connected');
    };

    websocket.onmessage = (event) => {
      const data: Message = JSON.parse(event.data);
      setMessages(prev => [...prev, data]);
    };

    websocket.onclose = () => {
      setIsConnected(false);
      console.log('WebSocket disconnected');
    };

    websocket.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    setWs(websocket);

    return () => {
      websocket.close();
    };
  }, [agentId]);

  const sendMessage = useCallback((content: string) => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'message',
        content
      }));
    }
  }, [ws]);

  const broadcast = useCallback((content: string) => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'broadcast',
        content
      }));
    }
  }, [ws]);

  return { messages, isConnected, sendMessage, broadcast };
}

// Usage in component
function AgentChat() {
  const { messages, isConnected, sendMessage, broadcast } = useWebSocket('agent-1');
  const [input, setInput] = useState('');

  const handleSend = () => {
    sendMessage(input);
    setInput('');
  };

  return (
    <div>
      <h1>Agent Chat {isConnected ? '🟢' : '🔴'}</h1>
      <div>
        {messages.map((msg, idx) => (
          <div key={idx}>{msg.content}</div>
        ))}
      </div>
      <input
        value={input}
        onChange={(e) => setInput(e.target.value)}
      />
      <button onClick={handleSend}>Send</button>
    </div>
  );
}
```

### Python Client

```python
import asyncio
import websockets
import json

async def websocket_client(agent_id: str):
    uri = f"ws://localhost:8000/ws/{agent_id}"

    async with websockets.connect(uri) as websocket:
        # Wait for connection message
        response = await websocket.recv()
        data = json.loads(response)
        print(f"Connected: {data}")

        # Send message
        await websocket.send(json.dumps({
            "type": "message",
            "content": "Hello from Python client"
        }))

        # Receive response
        response = await websocket.recv()
        data = json.loads(response)
        print(f"Received: {data}")

        # Send ping
        await websocket.send(json.dumps({"type": "ping"}))

        # Receive pong
        response = await websocket.recv()
        data = json.loads(response)
        print(f"Ping response: {data}")

# Run client
asyncio.run(websocket_client('agent-1'))
```

## Broadcasting to Multiple Agents

### Server-Side Broadcast

The server template includes broadcast functionality:

```python
# Client sends broadcast
ws.send(JSON.stringify({
  type: 'broadcast',
  content: 'Message to all agents'
}));
```

All connected agents (except sender) receive:
```json
{
  "type": "broadcast",
  "from": "agent-1",
  "content": "Message to all agents"
}
```

### Multi-Agent Chat Example

```javascript
// Agent 1
const ws1 = new WebSocket('ws://localhost:8000/ws/agent-1');
ws1.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === 'broadcast') {
    console.log(`Agent 1 received broadcast from ${data.from}: ${data.content}`);
  }
};

// Agent 2
const ws2 = new WebSocket('ws://localhost:8000/ws/agent-2');
ws2.onopen = () => {
  // Send broadcast to all other agents
  ws2.send(JSON.stringify({
    type: 'broadcast',
    content: 'Hello from Agent 2'
  }));
};

// Agent 1 will receive the broadcast
```

## Use Cases

WebSocket is ideal for:

1. **Multi-agent communication** - Agents collaborating in real-time
2. **Interactive chat** - Bidirectional conversation
3. **Live coordination** - Task distribution and status updates
4. **Real-time collaboration** - Multiple agents working together

## Best Practices

1. **Heartbeat/Ping** - Send periodic pings to keep connection alive
2. **Reconnection logic** - Handle disconnections gracefully
3. **Message queuing** - Buffer messages when connection is down
4. **Error handling** - Robust error handling for network issues
5. **Authentication** - Add auth before production use

## Comparison with Other Transports

| Feature | HTTP | STDIO | SSE | WebSocket |
|---------|------|-------|-----|-----------|
| Direction | Request/Response | Bidirectional | Server→Client | Bidirectional |
| Real-time | No | Yes | Yes | Yes |
| Network | Yes | No | Yes | Yes |
| Multiple Clients | Yes | No | Yes | Yes |
| Complexity | Low | Low | Medium | High |
| Use Case | APIs | Local CLI | Streaming | Real-time chat |
