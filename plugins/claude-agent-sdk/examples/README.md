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

### ✅ Basic Query Pattern
```python
import os
import asyncio
from dotenv import load_dotenv
from claude_agent_sdk import query
from claude_agent_sdk.types import ClaudeAgentOptions

load_dotenv()

async def main():
    async for message in query(
        prompt="Your question here",
        options=ClaudeAgentOptions(
            model="claude-sonnet-4-20250514",
            max_turns=5,
            env={"ANTHROPIC_API_KEY": os.getenv("ANTHROPIC_API_KEY")}
        )
    ):
        if hasattr(message, 'type') and message.type == 'text':
            print(message.text)

if __name__ == "__main__":
    asyncio.run(main())
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

### ✅ Environment Variables Pattern
```python
env={
    "ANTHROPIC_API_KEY": ANTHROPIC_API_KEY,
    "FASTMCP_CLOUD_API_KEY": FASTMCP_CLOUD_API_KEY  # Include MCP keys
}
```

### ✅ File Structure Template
```
my-agent-project/
├── main.py                 # Your agent code
├── requirements.txt        # Dependencies
├── .env                    # API keys (gitignored)
├── .env.example           # Template for .env
├── .gitignore             # Git ignore rules
└── README.md              # Setup instructions
```

**requirements.txt**:
```
claude-agent-sdk>=0.1.6
python-dotenv>=1.0.0
```

**.env.example**:
```env
ANTHROPIC_API_KEY=your_anthropic_api_key_here
FASTMCP_CLOUD_API_KEY=your_fastmcp_api_key_here
```

**.gitignore**:
```
.env
.env.local
__pycache__/
venv/
.venv/
*.pyc
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
