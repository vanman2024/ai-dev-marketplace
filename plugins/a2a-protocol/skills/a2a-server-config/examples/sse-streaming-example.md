# SSE Streaming Server - Example

This example demonstrates setting up a Server-Sent Events (SSE) server for real-time streaming communication.

## Step 1: Generate Server

```bash
bash scripts/generate-server.sh sse python sse_server.py
```

## Step 2: Install Dependencies

Create `requirements.txt`:

```
fastapi==0.104.1
uvicorn[standard]==0.24.0
sse-starlette==1.8.2
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
python sse_server.py
```

## Step 5: Test SSE Stream

### Using curl

```bash
curl -N http://localhost:8000/events
```

Output (streaming):
```
id: 1
event: message
data: {"counter": 1, "message": "Agent update #1", "timestamp": "2025-12-20T10:00:00Z"}

id: 2
event: message
data: {"counter": 2, "message": "Agent update #2", "timestamp": "2025-12-20T10:00:02Z"}

...
```

### Test Transport Script

```bash
bash scripts/test-transport.sh sse
```

## Client Integration

### JavaScript/Browser Client

```html
<!DOCTYPE html>
<html>
<head>
  <title>SSE Client</title>
</head>
<body>
  <h1>Agent Stream</h1>
  <div id="messages"></div>

  <script>
    const eventSource = new EventSource('http://localhost:8000/events');

    eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);
      console.log('Received:', data);

      // Display message
      const div = document.getElementById('messages');
      div.innerHTML += `<p>${data.message}</p>`;
    };

    eventSource.addEventListener('complete', (event) => {
      console.log('Stream completed');
      eventSource.close();
    });

    eventSource.onerror = (error) => {
      console.error('SSE error:', error);
      eventSource.close();
    };
  </script>
</body>
</html>
```

### React Client

```typescript
import { useEffect, useState } from 'react';

interface StreamMessage {
  counter: number;
  message: string;
  timestamp: string;
}

function AgentStream() {
  const [messages, setMessages] = useState<StreamMessage[]>([]);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const eventSource = new EventSource('http://localhost:8000/events');

    eventSource.onopen = () => {
      setIsConnected(true);
      console.log('Connected to stream');
    };

    eventSource.onmessage = (event) => {
      const data: StreamMessage = JSON.parse(event.data);
      setMessages(prev => [...prev, data]);
    };

    eventSource.addEventListener('complete', () => {
      eventSource.close();
      setIsConnected(false);
    });

    eventSource.onerror = () => {
      eventSource.close();
      setIsConnected(false);
    };

    return () => {
      eventSource.close();
    };
  }, []);

  return (
    <div>
      <h1>Agent Stream {isConnected ? '🟢' : '🔴'}</h1>
      <ul>
        {messages.map((msg, idx) => (
          <li key={idx}>{msg.message}</li>
        ))}
      </ul>
    </div>
  );
}
```

### Python Client

```python
import requests

def stream_events(url: str):
    """Stream SSE events from server"""
    response = requests.get(url, stream=True)

    for line in response.iter_lines():
        if not line:
            continue

        line = line.decode('utf-8')

        if line.startswith('data:'):
            data = line[5:].strip()
            print(f"Received: {data}")

        elif line.startswith('event:'):
            event = line[6:].strip()
            print(f"Event: {event}")

# Usage
stream_events('http://localhost:8000/events')
```

## Agent-Specific Streams

Access agent-specific streams:

```bash
curl -N http://localhost:8000/stream/agent-1
```

JavaScript:

```javascript
const agentId = 'agent-1';
const eventSource = new EventSource(`http://localhost:8000/stream/${agentId}`);

eventSource.addEventListener('agent_message', (event) => {
  const data = JSON.parse(event.data);
  console.log(`Message from ${data.agent_id}:`, data.message);
});
```

## Custom Event Generator

Modify the server to generate custom events:

```python
async def custom_event_generator() -> AsyncGenerator[dict, None]:
    """Generate custom agent events"""
    import asyncio
    from datetime import datetime

    tasks = ["Task A", "Task B", "Task C"]

    for task in tasks:
        # Simulate agent processing
        await asyncio.sleep(1)

        yield {
            "event": "task_update",
            "data": {
                "task": task,
                "status": "processing",
                "timestamp": datetime.utcnow().isoformat()
            }
        }

        await asyncio.sleep(2)

        yield {
            "event": "task_complete",
            "data": {
                "task": task,
                "status": "completed",
                "timestamp": datetime.utcnow().isoformat()
            }
        }

    yield {
        "event": "all_complete",
        "data": {"message": "All tasks completed"}
    }
```

## Use Cases

SSE is ideal for:

1. **Real-time agent updates** - Stream progress to UI
2. **Log streaming** - Live agent execution logs
3. **Status notifications** - Task completion events
4. **Metrics streaming** - Real-time performance data

## Limitations

- **One-way communication** (server to client only)
- **Client cannot send messages** (use HTTP POST separately)
- **No built-in reconnection** (handle in client)

For bidirectional communication, use WebSocket transport instead.
