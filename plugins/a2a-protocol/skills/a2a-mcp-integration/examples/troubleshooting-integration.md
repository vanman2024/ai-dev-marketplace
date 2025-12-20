# Troubleshooting A2A + MCP Integration

Common issues and solutions when integrating Agent-to-Agent Protocol with Model Context Protocol.

## Table of Contents

1. [Connection Issues](#connection-issues)
2. [Authentication Errors](#authentication-errors)
3. [Protocol Version Mismatches](#protocol-version-mismatches)
4. [Task Delegation Failures](#task-delegation-failures)
5. [Tool Execution Problems](#tool-execution-problems)
6. [Performance Issues](#performance-issues)
7. [Data Format Incompatibilities](#data-format-incompatibilities)

---

## Connection Issues

### A2A Connection Refused

**Symptoms:**
```
Error: Connection refused to A2A server at https://a2a.example.com
```

**Possible Causes:**
1. A2A server is down or unreachable
2. Incorrect base URL
3. Firewall blocking connection
4. Network connectivity issues

**Solutions:**

```bash
# 1. Check server reachability
curl https://a2a.example.com/health

# 2. Verify base URL in environment
echo $A2A_BASE_URL

# 3. Test with ping
ping a2a.example.com

# 4. Check firewall rules
sudo iptables -L | grep a2a

# 5. Try with verbose logging
A2A_LOG_LEVEL=debug python your_agent.py
```

**Fix:**
```python
# Add connection retry logic
import time
from a2a import Client, ConnectionError

def create_a2a_client_with_retry(max_retries=3):
    for attempt in range(max_retries):
        try:
            client = Client(
                api_key=os.getenv("A2A_API_KEY"),
                base_url=os.getenv("A2A_BASE_URL"),
                timeout=30
            )
            client.ping()  # Test connection
            return client
        except ConnectionError:
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
            else:
                raise
```

---

### MCP Server Not Responding

**Symptoms:**
```
Error: MCP server timeout at http://localhost:3000
```

**Possible Causes:**
1. MCP server not started
2. Wrong port number
3. Server crashed
4. Transport mode mismatch (stdio vs HTTP)

**Solutions:**

```bash
# 1. Check if MCP server is running
ps aux | grep mcp

# 2. Check port availability
netstat -tuln | grep 3000

# 3. Start MCP server
mcp-server start --port 3000

# 4. Check MCP logs
tail -f /var/log/mcp/server.log

# 5. Verify transport mode
echo $MCP_TRANSPORT  # Should be 'stdio' or 'http'
```

**Fix:**
```typescript
// Add health check before operations
import { Client as MCPClient } from '@modelcontextprotocol/sdk';

async function createMCPClientWithHealthCheck() {
  const client = new MCPClient({
    serverUrl: process.env.MCP_SERVER_URL
  });

  try {
    await client.connect();
    // Verify server is responsive
    const tools = await client.listTools();
    console.log(`MCP server connected, ${tools.length} tools available`);
    return client;
  } catch (error) {
    console.error('MCP server health check failed:', error);
    throw new Error('MCP server not responding');
  }
}
```

---

## Authentication Errors

### A2A Invalid API Key

**Symptoms:**
```
Error: 401 Unauthorized - Invalid API key
```

**Possible Causes:**
1. API key not set or incorrect
2. API key expired
3. Wrong environment (dev key in prod)
4. Extra whitespace in key

**Solutions:**

```bash
# 1. Verify API key is set
echo "${A2A_API_KEY}" | cat -A  # Shows hidden characters

# 2. Check key format
if [[ $A2A_API_KEY == a2a_* ]]; then
    echo "Key format looks correct"
else
    echo "Key format may be incorrect"
fi

# 3. Test authentication
curl -H "Authorization: Bearer $A2A_API_KEY" \
     https://a2a.example.com/api/v1/ping

# 4. Regenerate key (if necessary)
# Visit your A2A dashboard to regenerate
```

**Fix:**
```python
# Add validation before using
import os
import re

def validate_api_key(key_name):
    key = os.getenv(key_name)

    if not key:
        raise ValueError(f"{key_name} not set")

    # Remove any whitespace
    key = key.strip()

    # Check format (example pattern)
    if not re.match(r'^a2a_[a-zA-Z0-9]{40}$', key):
        raise ValueError(f"{key_name} has invalid format")

    return key

# Use it
a2a_api_key = validate_api_key("A2A_API_KEY")
```

---

### MCP Authentication Failed

**Symptoms:**
```
Error: MCP server rejected connection - authentication failed
```

**Possible Causes:**
1. MCP server requires authentication but none provided
2. Wrong authentication method
3. Credentials mismatch

**Solutions:**

```bash
# 1. Check if MCP requires auth
curl http://localhost:3000/info

# 2. Verify MCP auth configuration
cat config/mcp-server-config.json | grep auth

# 3. Test with credentials
curl -H "Authorization: Bearer $MCP_API_KEY" \
     http://localhost:3000/tools
```

**Fix:**
```typescript
// Configure MCP client with authentication
const mcpClient = new MCPClient({
  serverUrl: process.env.MCP_SERVER_URL,
  auth: {
    type: 'bearer',
    token: process.env.MCP_API_KEY
  }
});
```

---

## Protocol Version Mismatches

### Incompatible A2A Protocol Version

**Symptoms:**
```
Error: Protocol version mismatch. Client: 2.0, Server: 1.0
```

**Solutions:**

```bash
# Check installed versions
pip list | grep a2a-protocol
npm list @a2a/protocol

# Check server version
curl https://a2a.example.com/version

# Upgrade client to match server
pip install --upgrade a2a-protocol
# or
npm install @a2a/protocol@latest
```

**Fix:**
```python
# Add version negotiation
from a2a import Client

client = Client(
    api_key=api_key,
    protocol_version="1.0",  # Match server version
    fallback_versions=["1.1", "1.2"]  # Try these if 1.0 fails
)
```

---

### MCP SDK Version Conflict

**Symptoms:**
```
TypeError: MCPClient.call_tool() got unexpected keyword argument 'timeout'
```

**Solutions:**

```bash
# Check MCP SDK version
pip show mcp-sdk
npm list @modelcontextprotocol/sdk

# Compare with server requirements
cat requirements.txt | grep mcp
cat package.json | grep @modelcontextprotocol

# Upgrade/downgrade to compatible version
pip install mcp-sdk==1.0.0
npm install @modelcontextprotocol/sdk@1.0.0
```

---

## Task Delegation Failures

### Agent Not Found

**Symptoms:**
```
Error: Agent 'agent-worker-01' not found in network
```

**Possible Causes:**
1. Worker agent not registered
2. Worker agent disconnected
3. Agent ID typo
4. Network partition

**Solutions:**

```python
# Check registered agents
async def list_available_agents(a2a_client):
    agents = await a2a_client.discover_agents()
    print("Available agents:")
    for agent in agents:
        print(f"  - {agent.id}: {agent.name}")
    return agents

# Use discovery before delegation
agents = await list_available_agents(a2a_client)
worker = next((a for a in agents if a.capabilities.get('role') == 'worker'), None)

if not worker:
    raise ValueError("No worker agents available")

# Delegate to discovered worker
result = await a2a_client.send_task(worker.id, task)
```

---

### Task Timeout

**Symptoms:**
```
Error: Task 'task-123' timed out after 30 seconds
```

**Solutions:**

```python
# Increase timeout for long-running tasks
task = Task(
    type="data_analysis",
    params={"dataset": "large_dataset"},
    timeout=300  # 5 minutes instead of default 30s
)

# Or implement progress monitoring
async def execute_with_progress(agent_id, task):
    response = await a2a_client.send_task_async(agent_id, task)

    # Poll for progress
    while not response.is_complete():
        progress = await response.get_progress()
        print(f"Progress: {progress}%")
        await asyncio.sleep(5)

    return await response.get_result()
```

---

## Tool Execution Problems

### Tool Not Found

**Symptoms:**
```
Error: MCP tool 'web_search' not found
```

**Solutions:**

```python
# List available tools
async def list_mcp_tools(mcp_client):
    tools = await mcp_client.list_tools()
    print("Available MCP tools:")
    for tool in tools:
        print(f"  - {tool.name}: {tool.description}")
    return tools

# Verify tool exists before calling
tools = await list_mcp_tools(mcp_client)
tool_names = [t.name for t in tools]

if 'web_search' not in tool_names:
    raise ValueError("web_search tool not available")

# Execute
result = await mcp_client.call_tool('web_search', params)
```

---

### Tool Parameter Validation Error

**Symptoms:**
```
Error: Invalid parameter 'query' for tool 'web_search': expected string, got int
```

**Solutions:**

```typescript
// Get tool schema and validate parameters
const tools = await mcpClient.listTools();
const webSearchTool = tools.find(t => t.name === 'web_search');

function validateParams(params: any, schema: any) {
  // Validate against tool's input schema
  for (const [key, value] of Object.entries(params)) {
    const paramSchema = schema.properties[key];

    if (!paramSchema) {
      throw new Error(`Unknown parameter: ${key}`);
    }

    if (paramSchema.type === 'string' && typeof value !== 'string') {
      throw new Error(`${key} must be string, got ${typeof value}`);
    }
  }
}

// Validate before execution
validateParams(params, webSearchTool.inputSchema);
const result = await mcpClient.callTool('web_search', params);
```

---

## Performance Issues

### Slow Agent Discovery

**Symptoms:**
- Agent discovery takes > 5 seconds
- High latency in A2A operations

**Solutions:**

```python
# Implement agent discovery caching
from datetime import datetime, timedelta

class AgentDiscoveryCache:
    def __init__(self, ttl_seconds=300):
        self.cache = {}
        self.ttl = timedelta(seconds=ttl_seconds)

    async def discover_agents(self, a2a_client, capabilities=None):
        cache_key = str(capabilities)

        if cache_key in self.cache:
            cached_time, agents = self.cache[cache_key]
            if datetime.now() - cached_time < self.ttl:
                print("Using cached agent discovery")
                return agents

        # Fetch fresh data
        agents = await a2a_client.discover_agents(capabilities)
        self.cache[cache_key] = (datetime.now(), agents)
        return agents

# Use cached discovery
cache = AgentDiscoveryCache(ttl_seconds=300)
agents = await cache.discover_agents(a2a_client, {"role": "worker"})
```

---

### MCP Tool Execution Bottleneck

**Symptoms:**
- Tools take too long to execute
- Sequential execution limiting throughput

**Solutions:**

```python
# Execute tools in parallel
import asyncio

async def execute_tools_parallel(mcp_client, tool_calls):
    """Execute multiple MCP tools in parallel"""
    tasks = [
        mcp_client.call_tool(call['name'], call['params'])
        for call in tool_calls
    ]

    results = await asyncio.gather(*tasks, return_exceptions=True)

    return [
        {"tool": call['name'], "result": result}
        for call, result in zip(tool_calls, results)
    ]

# Use it
tool_calls = [
    {"name": "web_search", "params": {"query": "AI"}},
    {"name": "data_fetch", "params": {"url": "https://example.com"}},
    {"name": "database_read", "params": {"table": "users"}}
]

results = await execute_tools_parallel(mcp_client, tool_calls)
```

---

## Data Format Incompatibilities

### JSON Serialization Errors

**Symptoms:**
```
TypeError: Object of type datetime is not JSON serializable
```

**Solutions:**

```python
import json
from datetime import datetime
from typing import Any

class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)

# Use when sending tasks
task_data = {
    "timestamp": datetime.now(),
    "query": "renewable energy"
}

# Serialize properly
json_data = json.dumps(task_data, cls=CustomJSONEncoder)

# Or convert before creating task
def sanitize_for_json(data: Any) -> Any:
    if isinstance(data, datetime):
        return data.isoformat()
    elif isinstance(data, dict):
        return {k: sanitize_for_json(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [sanitize_for_json(i) for i in data]
    return data

clean_data = sanitize_for_json(task_data)
```

---

## Getting Help

If these solutions don't resolve your issue:

1. **Check Logs**: Enable debug logging for both A2A and MCP
   ```bash
   A2A_LOG_LEVEL=debug MCP_LOG_LEVEL=debug python your_agent.py
   ```

2. **Community Support**:
   - A2A Discord: https://discord.gg/a2a-protocol
   - MCP GitHub Discussions: https://github.com/modelcontextprotocol/specification/discussions

3. **Report Issues**:
   - A2A Issues: https://github.com/a2a/protocol/issues
   - MCP Issues: https://github.com/modelcontextprotocol/specification/issues

4. **Professional Support**:
   - Contact your A2A provider
   - Check MCP documentation: https://modelcontextprotocol.io

---

**Last Updated:** 2025-12-20
**Version:** 1.0.0
