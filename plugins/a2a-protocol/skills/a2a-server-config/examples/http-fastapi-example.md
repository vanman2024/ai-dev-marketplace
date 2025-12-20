# HTTP Server with FastAPI - Complete Example

This example demonstrates setting up a complete A2A HTTP server using FastAPI with proper configuration, CORS, and environment variables.

## Step 1: Generate Server

```bash
bash scripts/generate-server.sh http python server.py
```

## Step 2: Create Environment Configuration

Create `.env` file (NEVER commit this):

```bash
# Server Configuration
PORT=8000
HOST=0.0.0.0
RELOAD=true

# CORS Settings
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173

# API Keys (NEVER commit real values)
ANTHROPIC_API_KEY=your_anthropic_key_here
```

Create `.env.example` (safe to commit):

```bash
# Server Configuration
PORT=8000
HOST=0.0.0.0
RELOAD=true

# CORS Settings
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173

# API Keys - Get from https://console.anthropic.com/
ANTHROPIC_API_KEY=your_anthropic_key_here
```

## Step 3: Install Dependencies

Create `requirements.txt`:

```
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
python-dotenv==1.0.0
```

Install:

```bash
pip install -r requirements.txt
```

## Step 4: Validate Configuration

```bash
bash scripts/validate-config.sh server.py
```

Expected output:
```
Validating A2A server configuration: server.py
Checking for hardcoded API keys...
  OK: No hardcoded API keys found
Checking for environment variable usage...
  OK: Environment variables are used
Checking CORS configuration...
  OK: CORS configuration found
Checking transport configuration...
  OK: Transport configuration found
Checking .gitignore...
  OK: .env files are in .gitignore

Validation PASSED
```

## Step 5: Start Server

```bash
python server.py
```

Output:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

## Step 6: Test the Server

Test health endpoint:

```bash
curl http://localhost:8000/health
```

Response:
```json
{
  "status": "healthy",
  "transport": "http",
  "version": "1.0.0"
}
```

Test message endpoint:

```bash
curl -X POST http://localhost:8000/message \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello from agent-1",
    "agent_id": "agent-1",
    "context": {"task": "greeting"}
  }'
```

Response:
```json
{
  "content": "Received: Hello from agent-1",
  "agent_id": "agent-1",
  "status": "success"
}
```

## Step 7: Test Transport

```bash
bash scripts/test-transport.sh http
```

## Client Integration

### JavaScript/TypeScript Client

```typescript
async function sendMessage(content: string, agentId: string) {
  const response = await fetch('http://localhost:8000/message', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      content,
      agent_id: agentId,
      context: {}
    })
  });

  return await response.json();
}

// Usage
const result = await sendMessage('Hello', 'agent-1');
console.log(result);
```

### Python Client

```python
import requests

def send_message(content: str, agent_id: str):
    response = requests.post(
        'http://localhost:8000/message',
        json={
            'content': content,
            'agent_id': agent_id,
            'context': {}
        }
    )
    return response.json()

# Usage
result = send_message('Hello', 'agent-1')
print(result)
```

## Production Deployment

1. Set `RELOAD=false` in production
2. Use proper ALLOWED_ORIGINS (not `*`)
3. Add authentication middleware
4. Use HTTPS in production
5. Set up monitoring and logging

Example production `.env`:

```bash
PORT=8000
HOST=0.0.0.0
RELOAD=false
ALLOWED_ORIGINS=https://app.example.com
ANTHROPIC_API_KEY=production_key_from_secrets_manager
```
