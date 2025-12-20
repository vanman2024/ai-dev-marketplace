# STDIO Server - Simple Example

This example demonstrates setting up a basic A2A STDIO server for local process communication.

## Step 1: Generate Server

```bash
bash scripts/generate-server.sh stdio python stdio_server.py
```

## Step 2: Create Environment Configuration

Create `.env`:

```bash
# API Keys (NEVER commit real values)
ANTHROPIC_API_KEY=your_anthropic_key_here
```

## Step 3: Install Dependencies

Create `requirements.txt`:

```
python-dotenv==1.0.0
```

Install:

```bash
pip install -r requirements.txt
```

## Step 4: Start Server

```bash
python stdio_server.py
```

Server output (to stderr):
```
A2A STDIO Server started
```

## Step 5: Send Messages

The server reads JSON-RPC messages from stdin and writes responses to stdout.

### Example 1: Send a message

Input (stdin):
```json
{"jsonrpc": "2.0", "method": "message", "params": {"content": "Hello", "agent_id": "agent-1"}, "id": 1}
```

Output (stdout):
```json
{"jsonrpc": "2.0", "result": {"content": "Received from agent-1: Hello", "status": "success"}, "id": 1}
```

### Example 2: Ping/Pong

Input:
```json
{"jsonrpc": "2.0", "method": "ping", "params": {}, "id": 2}
```

Output:
```json
{"jsonrpc": "2.0", "result": {"pong": true}, "id": 2}
```

## Testing with Scripts

Create `test_stdio.sh`:

```bash
#!/bin/bash

# Start server in background
python stdio_server.py &
SERVER_PID=$!

# Wait for server to start
sleep 1

# Send test message
echo '{"jsonrpc": "2.0", "method": "message", "params": {"content": "Test", "agent_id": "test-agent"}, "id": 1}' | nc localhost 12345

# Clean up
kill $SERVER_PID
```

## Client Integration

### Python Client

```python
import subprocess
import json

class StdioClient:
    def __init__(self, server_script: str):
        self.process = subprocess.Popen(
            ['python', server_script],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

    def send_message(self, content: str, agent_id: str) -> dict:
        request = {
            "jsonrpc": "2.0",
            "method": "message",
            "params": {
                "content": content,
                "agent_id": agent_id
            },
            "id": 1
        }

        # Send request
        self.process.stdin.write(json.dumps(request) + '\n')
        self.process.stdin.flush()

        # Read response
        response_line = self.process.stdout.readline()
        return json.loads(response_line)

    def close(self):
        self.process.terminate()

# Usage
client = StdioClient('stdio_server.py')
result = client.send_message('Hello', 'agent-1')
print(result)
client.close()
```

### Node.js Client

```javascript
const { spawn } = require('child_process');

class StdioClient {
  constructor(serverScript) {
    this.process = spawn('python', [serverScript]);
    this.process.stderr.on('data', (data) => {
      console.error(`Server: ${data}`);
    });
  }

  async sendMessage(content, agentId) {
    return new Promise((resolve, reject) => {
      const request = {
        jsonrpc: '2.0',
        method: 'message',
        params: { content, agent_id: agentId },
        id: 1
      };

      // Listen for response
      this.process.stdout.once('data', (data) => {
        resolve(JSON.parse(data.toString()));
      });

      // Send request
      this.process.stdin.write(JSON.stringify(request) + '\n');
    });
  }

  close() {
    this.process.kill();
  }
}

// Usage
const client = new StdioClient('stdio_server.py');
client.sendMessage('Hello', 'agent-1').then(result => {
  console.log(result);
  client.close();
});
```

## Use Cases

STDIO transport is ideal for:

1. **Local agent communication** - Agents running on same machine
2. **Parent-child processes** - Main app spawning agent servers
3. **CLI tools** - Command-line agent interfaces
4. **Testing** - Simple test harnesses without network setup

## Limitations

- No network access (local only)
- Single client per server instance
- No built-in connection management
- Limited to text-based communication

For remote communication, use HTTP or WebSocket transport instead.
