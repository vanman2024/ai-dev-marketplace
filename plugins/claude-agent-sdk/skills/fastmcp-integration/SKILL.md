---
name: fastmcp-integration
description: Examples and patterns for integrating FastMCP Cloud servers with Claude Agent SDK using HTTP transport
---

# FastMCP Cloud Integration Skill

This skill provides examples and troubleshooting for FastMCP Cloud integration.

## Critical Pattern: Use HTTP Transport

**FastMCP Cloud uses HTTP, NOT SSE!**

### ✅ Correct Configuration

**Example: Basic FastMCP Cloud Integration**

```python
import os
import asyncio
from dotenv import load_dotenv
from claude_agent_sdk import query
from claude_agent_sdk.types import ClaudeAgentOptions

load_dotenv()

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
FASTMCP_CLOUD_API_KEY = os.getenv("FASTMCP_CLOUD_API_KEY")

async def main():
    async for message in query(
        prompt="List available tools from the MCP server",
        options=ClaudeAgentOptions(
            model="claude-sonnet-4-20250514",

            # ✅ CRITICAL: Use HTTP for FastMCP Cloud
            mcp_servers={
                "your-server": {
                    "type": "http",  # ← Must be "http" not "sse"
                    "url": "https://your-server.fastmcp.app/mcp",
                    "headers": {
                        "Authorization": f"Bearer {FASTMCP_CLOUD_API_KEY}"
                    }
                }
            },

            # Allow MCP tools
            allowed_tools=["mcp__your-server__*"],

            # Pass API keys via env
            env={
                "ANTHROPIC_API_KEY": ANTHROPIC_API_KEY,
                "FASTMCP_CLOUD_API_KEY": FASTMCP_CLOUD_API_KEY
            }
        )
    ):
        if hasattr(message, 'type') and message.type == 'text':
            print(message.text)

if __name__ == "__main__":
    asyncio.run(main())
```

**Example: Multiple FastMCP Cloud Servers**

```python
mcp_servers={
    "cats": {
        "type": "http",
        "url": "https://catsmcp.fastmcp.app/mcp",
        "headers": {"Authorization": f"Bearer {FASTMCP_CLOUD_API_KEY}"}
    },
    "github": {
        "type": "http",
        "url": "https://github-mcp.fastmcp.app/mcp",
        "headers": {"Authorization": f"Bearer {FASTMCP_CLOUD_API_KEY}"}
    }
}

allowed_tools=[
    "mcp__cats__*",      # All CATS tools
    "mcp__github__*",    # All GitHub tools
]
```

**Example: Checking MCP Connection Status**

```python
async for message in query(...):
    if hasattr(message, 'type') and message.type == 'system':
        if hasattr(message, 'data') and 'mcp_servers' in message.data:
            for server in message.data['mcp_servers']:
                status = server.get('status', 'unknown')
                name = server.get('name', 'unknown')
                print(f"✅ MCP Server '{name}': {status}")

                if status == 'failed':
                    print("❌ Connection failed!")
                    print("   Check: 1) Using 'type': 'http'")
                    print("   Check: 2) FASTMCP_CLOUD_API_KEY is valid")
                    print("   Check: 3) URL is correct")
```

### ❌ Common Mistakes

**Wrong transport type:**
```python
"type": "sse"  # ❌ Doesn't work with FastMCP Cloud
```

**Missing API key:**
```python
# ❌ Not passing FASTMCP_CLOUD_API_KEY
env={"ANTHROPIC_API_KEY": ANTHROPIC_API_KEY}
```

**Wrong package:**
```python
from anthropic_agent_sdk import query  # ❌ Wrong!
# Should be:
from claude_agent_sdk import query  # ✅ Correct
```

## Troubleshooting

### Symptom: `'mcp_servers': [{'name': 'cats', 'status': 'failed'}]`

**Causes:**
1. Using `"type": "sse"` instead of `"type": "http"`
2. Missing or invalid `FASTMCP_CLOUD_API_KEY`
3. Wrong URL format

**Fix:**
- Change to `"type": "http"`
- Verify API key is correct and passed in `env` parameter
- Ensure URL is `https://your-server.fastmcp.app/mcp` (with `/mcp` endpoint)

### Symptom: `ImportError: No module named 'anthropic_agent_sdk'`

**Cause:** Wrong package name

**Fix:**
```bash
pip uninstall anthropic-agent-sdk  # Remove wrong package
pip install claude-agent-sdk       # Install correct package
```

## Complete Example

See `examples/python/fastmcp-cloud-http.py` for a full working example.

## Environment Variables

Required in `.env`:
```env
ANTHROPIC_API_KEY=sk-ant-api03-...
FASTMCP_CLOUD_API_KEY=fmcp_...
```

Must be passed via `env` parameter:
```python
env={
    "ANTHROPIC_API_KEY": os.getenv("ANTHROPIC_API_KEY"),
    "FASTMCP_CLOUD_API_KEY": os.getenv("FASTMCP_CLOUD_API_KEY")
}
```

## Additional Examples

See the `examples/` directory in this skill:
- `examples/multi-server.py` - Connecting to multiple FastMCP Cloud servers
- `examples/connection-status.py` - Testing and troubleshooting connections

## Related Resources

- Basic example: `@plugins/claude-agent-sdk/examples/python/basic-query.py`
- FastMCP Cloud example: `@plugins/claude-agent-sdk/examples/python/fastmcp-cloud-http.py`
- Examples README: `@plugins/claude-agent-sdk/examples/README.md`
- Agent SDK Docs: `@plugins/claude-agent-sdk/docs/sdk-documentation.md`
- FastMCP Cloud: https://fastmcp.com
- MCP Protocol: https://modelcontextprotocol.io
