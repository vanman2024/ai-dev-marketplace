---
name: fastmcp-integration
description: Examples and patterns for integrating FastMCP Cloud servers with Claude Agent SDK using HTTP transport
---

# FastMCP Cloud Integration Skill

This skill provides examples and troubleshooting for FastMCP Cloud integration.

## Critical Pattern: Use HTTP Transport

**FastMCP Cloud uses HTTP, NOT SSE!**

### ✅ Correct Configuration

```python
from claude_agent_sdk import query
from claude_agent_sdk.types import ClaudeAgentOptions

async for message in query(
    prompt="Your query here",
    options=ClaudeAgentOptions(
        mcp_servers={
            "your-server": {
                "type": "http",  # ← CRITICAL: Use HTTP for FastMCP Cloud
                "url": "https://your-server.fastmcp.app/mcp",
                "headers": {
                    "Authorization": f"Bearer {FASTMCP_CLOUD_API_KEY}"
                }
            }
        },
        allowed_tools=["mcp__your-server__*"],
        env={
            "ANTHROPIC_API_KEY": ANTHROPIC_API_KEY,
            "FASTMCP_CLOUD_API_KEY": FASTMCP_CLOUD_API_KEY
        }
    )
):
    # Handle messages
    pass
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

## Related Resources

- Examples: `/examples/python/fastmcp-cloud-http.py`
- Agent SDK Docs: `docs/sdk-documentation.md`
- FastMCP Cloud: https://fastmcp.com
