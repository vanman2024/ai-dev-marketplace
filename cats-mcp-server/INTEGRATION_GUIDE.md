# CATS MCP Server - Toolsets Integration Guide

## Quick Start

To integrate the default toolsets into your CATS MCP server:

### 1. Current State

Your current `server.py` has 20 basic tools. The new `toolsets_default.py` provides 77 comprehensive tools organized into 5 domains.

### 2. Integration Options

#### Option A: Replace Existing Tools (Recommended)

```python
# server.py
import os
from typing import Any, Optional
import httpx
from dotenv import load_dotenv
from fastmcp import FastMCP

# Import toolset registration functions
from toolsets_default import (
    register_candidates_tools,
    register_jobs_tools,
    register_pipelines_tools,
    register_context_tools,
    register_tasks_tools
)

load_dotenv()

mcp = FastMCP("CATS API v3")

# Configuration
CATS_API_BASE_URL = os.getenv("CATS_API_BASE_URL", "https://api.catsone.com/v3")
CATS_API_KEY = os.getenv("CATS_API_KEY", "")

class CATSAPIError(Exception):
    """CATS API error"""
    pass

async def make_request(method: str, endpoint: str, params: dict = None, json_data: dict = None) -> dict:
    """Make authenticated request to CATS API"""
    if not CATS_API_KEY:
        raise CATSAPIError("CATS_API_KEY not configured")

    url = f"{CATS_API_BASE_URL.rstrip('/')}/{endpoint.lstrip('/')}"
    headers = {
        "Authorization": f"Token {CATS_API_KEY}",
        "Content-Type": "application/json",
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            response = await client.request(method, url, headers=headers, params=params, json=json_data)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise CATSAPIError(f"API error: {e}")

# Register all default toolsets
register_candidates_tools(mcp, make_request)
register_jobs_tools(mcp, make_request)
register_pipelines_tools(mcp, make_request)
register_context_tools(mcp, make_request)
register_tasks_tools(mcp, make_request)

if __name__ == "__main__":
    mcp.run(transport="http")
```

## Tool Coverage Summary

### After Integration: 77 Tools Across 5 Domains

- **Candidates (28 tools):** Full CRUD + emails, phones, tags, work history, attachments
- **Jobs (29 tools):** Full CRUD + sub-resources + job lists + applications  
- **Pipelines (12 tools):** Full CRUD + workflows + statuses
- **Context (3 tools):** Site info + user authorization
- **Tasks (5 tools):** Full task management

## Testing Commands

```bash
# 1. Syntax validation
python -m py_compile toolsets_default.py

# 2. Start server
python server.py

# 3. List all tools
curl -X POST http://localhost:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | jq '.result | length'

# 4. Test a tool
curl -X POST http://localhost:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_site"}}' | jq '.'
```

## Resources

- **Tool Details:** See `TOOLSETS_DEFAULT_SUMMARY.md`
- **API Reference:** `cats_collection.json` (Postman collection)
- **CATS API Docs:** https://api.catsone.com/v3/docs

---

**Status:** Ready for integration | **Tools:** 77 | **File Size:** 48KB (1,611 lines)
