# MCP-Integrated FastAPI Example

FastAPI application with MCP server integration for dual-mode operation (HTTP + STDIO).

## Structure

```
mcp-api/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── core/
│   │   ├── __init__.py
│   │   └── config.py
│   ├── api/
│   │   └── routes/
│   │       ├── __init__.py
│   │       └── health.py
│   ├── mcp/
│   │   ├── __init__.py
│   │   ├── server.py
│   │   └── tools/
│   │       ├── __init__.py
│   │       └── data_tools.py
│   └── services/
│       ├── __init__.py
│       └── data_service.py
├── .mcp.json
├── pyproject.toml
└── README.md
```

## app/main.py

```python
"""FastAPI + MCP Server Application"""

from fastapi import FastAPI
from app.core.config import settings
from app.api.routes import health
from app.mcp.server import mcp_server, run_mcp_server

app = FastAPI(title=settings.PROJECT_NAME, version=settings.VERSION)

# Include HTTP routes
app.include_router(health.router, prefix="/health", tags=["health"])

@app.get("/")
async def root():
    return {"message": f"Welcome to {settings.PROJECT_NAME}"}

# Dual-mode support
if __name__ == "__main__":
    import sys
    import asyncio
    import uvicorn

    if "--mcp" in sys.argv:
        # Run as MCP server (STDIO mode)
        print("Starting MCP server in STDIO mode...")
        asyncio.run(run_mcp_server())
    else:
        # Run as HTTP server
        print("Starting HTTP server...")
        uvicorn.run(
            "app.main:app",
            host=settings.HOST,
            port=settings.PORT,
            reload=settings.DEBUG,
        )
```

## app/mcp/server.py

```python
"""MCP Server Configuration"""

from mcp.server import Server
from mcp.server.stdio import stdio_server
from app.mcp.tools.data_tools import register_data_tools

# Create MCP server
mcp_server = Server("fastapi-mcp-service")

# Register tools
register_data_tools(mcp_server)

async def run_mcp_server():
    """Run MCP server in STDIO mode"""
    async with stdio_server() as (read_stream, write_stream):
        await mcp_server.run(
            read_stream,
            write_stream,
            mcp_server.create_initialization_options()
        )
```

## app/mcp/tools/data_tools.py

```python
"""MCP Tools for Data Operations"""

from mcp.server import Server
from mcp.types import Tool, TextContent
from app.services.data_service import DataService

def register_data_tools(server: Server):
    """Register data-related MCP tools"""

    data_service = DataService()

    @server.list_tools()
    async def list_tools() -> list[Tool]:
        return [
            Tool(
                name="get_data",
                description="Retrieve data by ID",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "id": {
                            "type": "string",
                            "description": "Data ID"
                        }
                    },
                    "required": ["id"]
                }
            ),
            Tool(
                name="store_data",
                description="Store new data",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "key": {"type": "string"},
                        "value": {"type": "string"}
                    },
                    "required": ["key", "value"]
                }
            ),
        ]

    @server.call_tool()
    async def call_tool(name: str, arguments: dict) -> list[TextContent]:
        if name == "get_data":
            result = await data_service.get_data(arguments["id"])
            return [TextContent(
                type="text",
                text=f"Data: {result}"
            )]

        elif name == "store_data":
            await data_service.store_data(
                arguments["key"],
                arguments["value"]
            )
            return [TextContent(
                type="text",
                text="Data stored successfully"
            )]

        raise ValueError(f"Unknown tool: {name}")
```

## app/services/data_service.py

```python
"""Data Service - Shared Business Logic"""

class DataService:
    """Business logic shared between HTTP and MCP interfaces"""

    def __init__(self):
        self.storage: dict[str, str] = {}

    async def get_data(self, data_id: str) -> str | None:
        """Retrieve data by ID"""
        return self.storage.get(data_id)

    async def store_data(self, key: str, value: str) -> None:
        """Store data"""
        self.storage[key] = value

    async def list_all(self) -> dict[str, str]:
        """List all data"""
        return self.storage.copy()
```

## .mcp.json

```json
{
  "mcpServers": {
    "fastapi-mcp-service": {
      "command": "python",
      "args": ["-m", "app.main", "--mcp"],
      "description": "FastAPI MCP Service"
    }
  }
}
```

## pyproject.toml

```toml
[project]
name = "mcp-integrated-api"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.32.0",
    "pydantic>=2.0.0",
    "pydantic-settings>=2.0.0",
    "mcp>=1.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "httpx>=0.27.0",
]
```

## Usage

### HTTP Mode

```bash
# Run as HTTP server
python -m app.main

# Or with uvicorn
uvicorn app.main:app --reload

# Test HTTP endpoints
curl http://localhost:8000/
curl http://localhost:8000/health
```

### MCP Mode

```bash
# Run as MCP server (STDIO)
python -m app.main --mcp

# Or configure in Claude Desktop's config
# The server will communicate via STDIO protocol
```

### Both Modes Simultaneously

```bash
# Terminal 1: HTTP server
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Terminal 2: MCP server
python -m app.main --mcp
```

## Key Features

**Dual-Mode Operation:**
- Same codebase serves both HTTP and MCP
- Shared business logic in services layer
- Consistent data access patterns

**MCP Tools:**
- Tools implemented as async functions
- Type-safe with Pydantic validation
- Reusable across different agents

**HTTP API:**
- Standard REST endpoints
- OpenAPI documentation
- Health checks

**Shared Services:**
- Business logic decoupled from interfaces
- Easy to test
- Single source of truth

## Testing

```python
# test_http_api.py
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200

# test_mcp_tools.py
import pytest
from app.mcp.tools.data_tools import register_data_tools
from mcp.server import Server

@pytest.mark.asyncio
async def test_store_data():
    server = Server("test")
    register_data_tools(server)

    result = await server.call_tool(
        "store_data",
        {"key": "test", "value": "data"}
    )
    assert "successfully" in result[0].text.lower()
```

## When to Use

Perfect for:
- Building AI agent backends
- Tools that need both programmatic and HTTP access
- Services requiring Claude integration
- Dual-interface applications

Benefits:
- Code reuse between interfaces
- Consistent behavior
- Easy to test
- Flexible deployment
