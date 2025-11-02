# Claude Agent SDK Examples

Production-ready examples for common use cases.

## Python Examples

### Basic Usage

**`python/basic-query.py`** - Simplest example
```bash
python examples/python/basic-query.py
```

### MCP Integration

**`python/fastmcp-cloud-http.py`** - FastMCP Cloud with HTTP transport
```bash
# IMPORTANT: FastMCP Cloud uses HTTP, not SSE!
python examples/python/fastmcp-cloud-http.py
```

## Key Patterns

### ✅ Correct Package Name
```python
from claude_agent_sdk import query  # ✅ CORRECT
from claude_agent_sdk.types import ClaudeAgentOptions
```

NOT:
```python
from anthropic_agent_sdk import query  # ❌ WRONG
```

### ✅ FastMCP Cloud Configuration
```python
mcp_servers={
    "your-server": {
        "type": "http",  # ✅ Use HTTP for FastMCP Cloud
        "url": "https://your-server.fastmcp.app/mcp",
        "headers": {
            "Authorization": f"Bearer {FASTMCP_CLOUD_API_KEY}"
        }
    }
}
```

NOT:
```python
"type": "sse"  # ❌ SSE doesn't work with FastMCP Cloud
```

### ✅ Environment Variables
```python
env={
    "ANTHROPIC_API_KEY": ANTHROPIC_API_KEY,
    "FASTMCP_CLOUD_API_KEY": FASTMCP_CLOUD_API_KEY  # Include MCP keys
}
```

## Setup

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Add your API keys to `.env`:
```env
ANTHROPIC_API_KEY=sk-ant-api03-...
FASTMCP_CLOUD_API_KEY=fmcp_...
```

3. Install dependencies:
```bash
pip install claude-agent-sdk python-dotenv
```

4. Run examples:
```bash
python examples/python/basic-query.py
```

## Common Issues

### MCP Server Status: failed

**Cause**: Using wrong transport type

**Fix**: Use `"type": "http"` for FastMCP Cloud, not `"sse"`

### ImportError: No module named 'anthropic_agent_sdk'

**Cause**: Wrong package name

**Fix**: Install `claude-agent-sdk` (not `anthropic-agent-sdk`)
```bash
pip install claude-agent-sdk
```

### Connection refused / 401 errors

**Cause**: Missing or invalid FastMCP Cloud API key

**Fix**: Ensure `FASTMCP_CLOUD_API_KEY` is in your `.env` file and passed via `env` parameter
