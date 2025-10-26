# FastMCP 2.0 - Plugin Builder Documentation

**Comprehensive guide for building FastMCP plugins and integrations**

## 📋 Table of Contents

### 🎯 Quick Reference
1. [Framework Overview](#framework-overview)
2. [Installation & Setup](#installation--setup)
3. [Quick Start Guide](#quick-start-guide)

### 🔧 Core Plugin Components
4. [Server Development](#server-development)
   - Server Configuration
   - Tools API
   - Resources API
   - Prompts API
   - Middleware System
5. [Client Development](#client-development)
   - Client Configuration
   - Transport Layers
   - Callback Handlers

### 🔐 Security & Authentication
6. [Authentication Providers](#authentication-providers)
   - OAuth 2.1 Providers (Google, GitHub, Azure, etc.)
   - JWT & Token Verification
   - Bearer Token Auth
7. [Authorization Middleware](#authorization-middleware)

### 🚀 Deployment & Integration
8. [Deployment Options](#deployment-options)
   - Local Development
   - HTTP Deployment
   - FastMCP Cloud
   - Production Configuration
9. [Platform Integrations](#platform-integrations)
   - FastAPI Integration
   - OpenAPI Integration
   - LLM Platform Integration (Anthropic, OpenAI, Gemini)
   - IDE Integration (Claude Desktop, Cursor)

### 📚 Plugin Development Reference
10. [CLI Tools](#cli-tools)
11. [API Reference](#api-reference)
12. [Advanced Patterns](#advanced-patterns)
13. [Code Examples & Templates](#code-examples--templates)

### 💡 Best Practices
14. [Development Best Practices](#development-best-practices)
15. [Production Best Practices](#production-best-practices)
16. [Testing & Debugging](#testing--debugging)

---

## Overview

### What is FastMCP?

FastMCP is the standard framework for building Model Context Protocol (MCP) applications in Python. It provides:

- **🚀 Fast**: High-level interface means less code and faster development
- **🍀 Simple**: Build MCP servers with minimal boilerplate
- **🐍 Pythonic**: Feels natural to Python developers
- **🔍 Complete**: Everything for production — enterprise auth, deployment tools, testing frameworks, client libraries

### What is MCP?

The Model Context Protocol lets you build servers that expose data and functionality to LLM applications in a secure, standardized way. MCP servers can:

- **Expose data through Resources** (like GET endpoints for loading information)
- **Provide functionality through Tools** (like POST endpoints for executing code)
- **Define interaction patterns through Prompts** (reusable templates for LLM interactions)

### Why FastMCP?

FastMCP handles all the complex protocol details so you can focus on building. In most cases, decorating a Python function is all you need — FastMCP handles the rest.

**Key Features:**

- Full compliance with MCP 2025-06-18 specification
- OAuth 2.1 authentication with enterprise providers (Google, GitHub, Azure, Auth0, WorkOS)
- HTTP and STDIO transports
- OpenAPI/FastAPI integration
- Declarative JSON configuration
- MCP Inspector integration
- Comprehensive testing tools
- FastMCP Cloud hosting (free for personal servers)

---

## Installation

### Prerequisites

- Python 3.10 or higher
- `uv` (recommended) or `pip`

### Install FastMCP

**Using uv (recommended):**

```bash
uv add fastmcp
```

**Using pip:**

```bash
pip install fastmcp
```

### Verify Installation

```bash
fastmcp version
```

Expected output:
```
FastMCP version:     2.13.0
MCP version:         1.17.0
Python version:      3.12.2
Platform:            Linux-5.15.0
FastMCP root path:   ~/fastmcp
```

### Upgrading from FastMCP 1.0

FastMCP 1.0 was incorporated into the official MCP SDK. FastMCP 2.0 is the actively maintained version with production features. To upgrade:

```python
# Before (FastMCP 1.0)
# from mcp.server.fastmcp import FastMCP

# After (FastMCP 2.0)
from fastmcp import FastMCP

mcp = FastMCP("My MCP Server")
```

---

## Quick Start

### Create Your First Server

**1. Create a server file:**

```python
# server.py
from fastmcp import FastMCP

mcp = FastMCP("My First Server")

@mcp.tool
def greet(name: str) -> str:
    """Greet someone by name"""
    return f"Hello, {name}!"

@mcp.resource("config://app")
def get_config() -> dict:
    """Get application configuration"""
    return {"version": "1.0", "author": "MyTeam"}

if __name__ == "__main__":
    mcp.run()
```

**2. Run the server:**

```bash
# STDIO transport (default)
python server.py

# HTTP transport
fastmcp run server.py --transport http --port 8000
```

**3. Test with a client:**

```python
import asyncio
from fastmcp import Client

async def main():
    async with Client("http://localhost:8000/mcp") as client:
        result = await client.call_tool("greet", {"name": "World"})
        print(result)

asyncio.run(main())
```

### Deploy to FastMCP Cloud

1. Push `server.py` to a GitHub repository
2. Sign in to [FastMCP Cloud](https://fastmcp.cloud) with your GitHub account
3. Create a new project from your repository
4. Enter `server.py:mcp` as the server entrypoint

Your server will be available at `https://your-project.fastmcp.app/mcp` (free for personal servers)!

---

## Core Concepts

### FastMCP Server

The central object for defining and managing MCP components:

```python
from fastmcp import FastMCP

# Basic server
mcp = FastMCP(name="MyAssistantServer")

# Server with instructions for LLMs
mcp = FastMCP(
    name="HelpfulAssistant",
    instructions="This server provides data analysis tools. Call get_average() to analyze numerical data.",
    version="1.0.0"
)

# Server with authentication
from fastmcp.server.auth import GoogleProvider

auth = GoogleProvider(
    client_id="your-client-id",
    client_secret="your-client-secret",
    base_url="https://myserver.com"
)

mcp = FastMCP(
    name="Protected Server",
    auth=auth,
    mask_error_details=True,
    include_tags={"public"},
    exclude_tags={"internal", "deprecated"}
)
```

### Tools

Tools are Python functions executable by LLMs:

```python
@mcp.tool
def add(a: int, b: int) -> int:
    """Add two numbers together"""
    return a + b

# Tool with field validation and metadata
from typing import Annotated
from pydantic import Field

@mcp.tool(
    name="search_products",
    description="Search the product catalog",
    tags={"catalog", "search"},
    annotations={"readOnlyHint": True}
)
def search_products(
    query: Annotated[str, Field(description="Search query")],
    category: Annotated[str | None, Field(description="Category")] = None,
    max_results: Annotated[int, Field(ge=1, le=100)] = 10
) -> list[dict]:
    """Search for products"""
    return [{"id": 1, "name": "Product A"}][:max_results]
```

### Resources

Resources provide read-only access to data:

```python
# Static resource
@mcp.resource("resource://greeting")
def get_greeting() -> str:
    """Simple greeting message"""
    return "Hello from FastMCP Resources!"

# Resource with JSON data
@mcp.resource(
    uri="data://config",
    name="ApplicationConfig",
    mime_type="application/json",
    tags={"config", "settings"},
    annotations={"readOnlyHint": True}
)
def get_config() -> dict:
    """Get application configuration"""
    return {"theme": "dark", "version": "1.2.0"}

# Resource template (dynamic content)
@mcp.resource("weather://{city}/current")
def get_weather(city: str) -> dict:
    """Weather information for a specific city"""
    return {
        "city": city.capitalize(),
        "temperature": 22,
        "condition": "Sunny"
    }
```

### Prompts

Prompts are reusable message templates for LLMs:

```python
@mcp.prompt
def analyze_data(data_points: list[float]) -> str:
    """Creates a prompt for analyzing numerical data"""
    formatted_data = ", ".join(str(point) for point in data_points)
    return f"Please analyze these data points: {formatted_data}"

# Prompt with metadata
@mcp.prompt(
    name="analysis_prompt",
    title="Data Analysis Prompt",
    description="Analyzes data patterns",
    meta={"complexity": "high", "domain": "analytics"}
)
def analysis_prompt(dataset: str) -> str:
    """Analyze patterns in dataset"""
    return f"Analyze the patterns in {dataset}"
```

### Context

The `Context` object provides access to server capabilities:

```python
from fastmcp import Context

@mcp.tool
async def process_data(data_uri: str, ctx: Context) -> dict:
    """Process data with progress reporting"""
    await ctx.info(f"Processing data from {data_uri}")
    
    # Read resource
    resource = await ctx.read_resource(data_uri)
    data = resource[0].text if resource else ""
    
    # Report progress
    await ctx.report_progress(progress=50, total=100)
    
    # Request LLM sampling
    summary = await ctx.sample(f"Summarize: {data[:200]}")
    
    await ctx.report_progress(progress=100, total=100)
    return {"length": len(data), "summary": summary.text}
```

---

## Server Development

### Server Configuration

#### Basic Server Options

```python
mcp = FastMCP(
    name="MyServer",                      # Server name
    instructions="Usage instructions",    # LLM guidance
    version="1.0.0",                      # Server version
    auth=None,                            # Authentication provider
    lifespan=None,                        # Startup/shutdown logic
    tools=[],                             # Pre-defined tools
    include_tags={"public"},              # Only expose these tags
    exclude_tags={"internal"},            # Hide these tags
    on_duplicate_tools="error",           # "error", "warn", or "replace"
    on_duplicate_resources="warn",        # Handle duplicates
    on_duplicate_prompts="replace",       # Handle duplicates
    include_fastmcp_meta=True,            # Include FastMCP metadata
)
```

#### Server Composition

```python
# Import and mount sub-servers
from fastmcp import FastMCP

main = FastMCP(name="Main")
sub = FastMCP(name="Sub")

@sub.tool
def hello():
    return "hi"

# Mount directly with prefix
main.mount(sub, prefix="sub")

# Tools accessible as: sub_hello
```

### Tools API

#### Tool Definition

```python
@mcp.tool
def basic_tool(x: int) -> str:
    """Basic tool"""
    return str(x)

# Custom name
@mcp.tool("custom_name")
def my_tool(x: int) -> str:
    return str(x)

# Full configuration
@mcp.tool(
    name="my_tool",
    description="Does something cool",
    tags={"utility"},
    enabled=True,
    exclude_args=["internal_param"],
    annotations=ToolAnnotations(
        title="Tool Title",
        readOnlyHint=False,
        destructiveHint=False
    ),
    meta={"version": "2.0"}
)
def advanced_tool(x: int, internal_param: str = "default") -> str:
    return f"Result: {x}"
```

#### Tool Result Control

```python
from fastmcp.tools.tool import ToolResult
from mcp.types import TextContent

@mcp.tool
def advanced_tool() -> ToolResult:
    """Tool with full output control"""
    return ToolResult(
        content=[TextContent(text="Human-readable summary")],
        structured_content={"data": "value", "count": 42}
    )
```

#### Dynamic Tool Management

```python
# Get tool
tool = await mcp.get_tool("add")

# Enable/disable
tool.enable()
tool.disable()

# Add tool programmatically
from fastmcp.tools.tool import Tool

tool = Tool.from_function(
    fn=lambda x: x * 2,
    name="double",
    description="Double a number"
)
mcp.add_tool(tool)
```

### Resources API

#### Resource Templates

```python
# Static resource
@mcp.resource("data://config")
def get_config() -> dict:
    return {"version": "1.0"}

# Template with parameters
@mcp.resource("repos://{owner}/{repo}/info")
def get_repo_info(owner: str, repo: str) -> dict:
    """Retrieve GitHub repository information"""
    return {
        "owner": owner,
        "name": repo,
        "full_name": f"{owner}/{repo}",
        "stars": 120
    }

# Resource with annotations
@mcp.resource(
    "repos://{owner}/{repo}/info",
    annotations={"readOnlyHint": True, "idempotentHint": True}
)
def get_repo_info(owner: str, repo: str) -> dict:
    return {"owner": owner, "name": repo}
```

#### Async Resources

```python
from pathlib import Path
import aiofiles

@mcp.resource("file://{path}")
async def read_file(path: str) -> str:
    """Read file contents asynchronously"""
    file_path = Path(path)
    async with aiofiles.open(file_path, 'r') as f:
        return await f.read()
```

### Middleware

#### Built-in Middleware

```python
from fastmcp.server.middleware import (
    LoggingMiddleware,
    TimingMiddleware,
    RateLimitMiddleware
)

mcp = FastMCP(
    "Server with Middleware",
    middleware=[
        LoggingMiddleware(),
        TimingMiddleware(),
        RateLimitMiddleware(max_requests=100, window_seconds=60)
    ]
)
```

#### Custom Middleware

```python
from fastmcp.server.middleware import Middleware, MiddlewareContext

class LoggingMiddleware(Middleware):
    """Middleware that logs all MCP operations"""
    
    async def on_message(self, context: MiddlewareContext, call_next):
        """Called for all MCP messages"""
        print(f"Processing {context.method} from {context.source}")
        
        result = await call_next(context)
        
        print(f"Completed {context.method}")
        return result

# Add to server
mcp.add_middleware(LoggingMiddleware())
```

#### Response Caching Middleware

```python
from fastmcp.server.middleware.caching import ResponseCachingMiddleware

mcp.add_middleware(ResponseCachingMiddleware(
    tools_ttl=300,           # Cache tool results for 5 minutes
    resources_ttl=60,        # Cache resources for 1 minute
    prompts_ttl=600          # Cache prompts for 10 minutes
))
```

### Server Lifecycle

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan():
    # Startup
    print("Server starting...")
    db = await connect_to_database()
    
    yield  # Server runs
    
    # Shutdown
    print("Server shutting down...")
    await db.close()

mcp = FastMCP("MyServer", lifespan=lifespan)
```

---

## Client Development

### FastMCP Client

#### Creating Clients

```python
from fastmcp import Client, FastMCP

# In-memory server (ideal for testing)
server = FastMCP("TestServer")
client = Client(server)

# HTTP server
client = Client("https://example.com/mcp")

# Local Python script
client = Client("my_mcp_server.py")

# Multi-server configuration
config = {
    "mcpServers": {
        "weather": {"url": "https://weather-api.example.com/mcp"},
        "calendar": {"command": "python", "args": ["./calendar_server.py"]}
    }
}
client = Client(config)
```

#### Basic Operations

```python
async with client:
    # Ping server
    await client.ping()
    
    # List available operations
    tools = await client.list_tools()
    resources = await client.list_resources()
    prompts = await client.list_prompts()
    
    # Execute tool
    result = await client.call_tool("multiply", {"a": 5, "b": 3})
    print(result.data)  # 15
    
    # Read resource
    content = await client.read_resource("file:///config/settings.json")
    print(content[0].text)
    
    # Get prompt
    prompt = await client.get_prompt("analyze_data", {"dataset": "sales"})
    print(prompt.messages)
```

#### Callback Handlers

```python
from fastmcp.client.logging import LogMessage

async def log_handler(message: LogMessage):
    """Handle server log messages"""
    print(f"Server log [{message.level}]: {message.data}")

async def progress_handler(progress: float, total: float | None, message: str | None):
    """Monitor long-running operations"""
    percentage = (progress / total * 100) if total else 0
    print(f"Progress: {percentage:.1f}% - {message}")

async def sampling_handler(messages, params, context):
    """Respond to server LLM requests"""
    # Integrate with your LLM service
    return "Generated response from LLM"

client = Client(
    "my_mcp_server.py",
    log_handler=log_handler,
    progress_handler=progress_handler,
    sampling_handler=sampling_handler,
    timeout=30.0
)
```

### Transports

#### HTTP/SSE Transport

```python
from fastmcp.client.transports import HttpSseTransport

transport = HttpSseTransport(
    url="https://api.example.com/mcp",
    headers={"Authorization": "Bearer token"}
)

client = Client(transport=transport)
```

#### STDIO Transport

```python
from fastmcp.client.transports import StdioTransport

transport = StdioTransport(
    command="python",
    args=["server.py"],
    env={"API_KEY": "secret"}
)

client = Client(transport=transport)
```

#### In-Memory Transport

```python
from fastmcp.client.transports import FastMCPTransport

server = FastMCP("TestServer")
transport = FastMCPTransport(server)
client = Client(transport=transport)
```

---

## Authentication & Security

### OAuth 2.1 Authentication

FastMCP supports enterprise OAuth providers out of the box.

#### Google OAuth

```python
from fastmcp import FastMCP
from fastmcp.server.auth.providers.google import GoogleProvider

auth = GoogleProvider(
    client_id="123456789.apps.googleusercontent.com",
    client_secret="GOCSPX-abc123...",
    base_url="http://localhost:8000",
    required_scopes=["openid", "https://www.googleapis.com/auth/userinfo.email"]
)

mcp = FastMCP(name="Google Secured App", auth=auth)

@mcp.tool
async def get_user_info() -> dict:
    """Returns authenticated user information"""
    from fastmcp.server.dependencies import get_access_token
    
    token = get_access_token()
    return {
        "email": token.claims.get("email"),
        "name": token.claims.get("name")
    }

if __name__ == "__main__":
    mcp.run(transport="http", port=8000)
```

#### GitHub OAuth

```python
from fastmcp.server.auth.providers.github import GitHubProvider

auth = GitHubProvider(
    client_id="Ov23liAbcDefGhiJkLmN",
    client_secret="github_pat_...",
    base_url="http://localhost:8000"
)

mcp = FastMCP(name="GitHub Secured App", auth=auth)
```

#### Azure (Microsoft Entra) OAuth

```python
from fastmcp.server.auth.providers.azure import AzureProvider

auth = AzureProvider(
    client_id="835f09b6-0f0f-40cc-85cb-f32c5829a149",
    client_secret="your-client-secret",
    tenant_id="08541b6e-646d-43de-a0eb-834e6713d6d5",
    base_url="http://localhost:8000",
    required_scopes=["your-scope"]
)

mcp = FastMCP(name="Azure Secured App", auth=auth)
```

#### WorkOS & AuthKit

```python
from fastmcp.server.auth.providers.workos import WorkOSProvider, AuthKitProvider

# WorkOS OAuth
workos_auth = WorkOSProvider(
    client_id="client_YOUR_CLIENT_ID",
    client_secret="YOUR_CLIENT_SECRET",
    authkit_domain="https://your-app.authkit.app",
    base_url="http://localhost:8000"
)

# AuthKit (DCR-compliant)
authkit_auth = AuthKitProvider(
    authkit_domain="https://your-project-12345.authkit.app",
    base_url="http://localhost:8000"
)

mcp = FastMCP("Protected Server", auth=authkit_auth)
```

#### AWS Cognito

```python
from fastmcp.server.auth.providers.aws import AWSCognitoProvider

auth = AWSCognitoProvider(
    user_pool_id="eu-central-1_XXXXXXXXX",
    aws_region="eu-central-1",
    client_id="your-app-client-id",
    client_secret="your-app-client-secret",
    base_url="http://localhost:8000"
)

mcp = FastMCP("AWS Secured App", auth=auth)
```

#### Auth0

```python
from fastmcp.server.auth.providers.auth0 import Auth0Provider

auth = Auth0Provider(
    config_url="https://.../.well-known/openid-configuration",
    client_id="tv2ObNgaZAWWhhycr7Bz1LU2mxlnsmsB",
    client_secret="vPYqbjemq...",
    audience="https://...",
    base_url="http://localhost:8000"
)

mcp = FastMCP("Auth0 Secured App", auth=auth)
```

### JWT Token Verification

```python
from fastmcp.server.auth.providers.jwt import JWTVerifier, RSAKeyPair

# Generate RSA key pair
key_pair = RSAKeyPair.generate()
access_token = key_pair.create_token(audience="dice-server")

# Create JWT verifier
auth = JWTVerifier(
    public_key=key_pair.public_key,
    audience="dice-server"
)

mcp = FastMCP(name="JWT Protected Server", auth=auth)
```

### Bearer Token Authentication

```python
from fastmcp.server.auth import BearerTokenProvider

auth = BearerTokenProvider(tokens={"secret-token-123": {"user_id": "admin"}})

mcp = FastMCP("Protected API", auth=auth)
```

### Client-Side OAuth

```python
from fastmcp import Client

# OAuth with default settings
async with Client("https://fastmcp.cloud/mcp", auth="oauth") as client:
    await client.ping()

# OAuth with custom settings
from fastmcp.client.auth.oauth import OAuth

oauth = OAuth(
    client_name="My MCP Client",
    redirect_port=8080,
    token_storage_cache_dir="~/.my-app/oauth-cache"
)

async with Client("https://api.example.com/mcp", auth=oauth) as client:
    result = await client.call_tool("protected_tool", {})
```

### Authorization Middleware

#### Permit.io Integration

```python
from fastmcp import FastMCP
from permit_fastmcp.middleware.middleware import PermitMcpMiddleware

mcp = FastMCP("Secure FastMCP Server 🔒")

@mcp.tool
def greet(name: str) -> str:
    return f"Hello, {name}!"

# Add Permit.io authorization
mcp.add_middleware(PermitMcpMiddleware(
    permit_pdp_url="http://localhost:7766",
    permit_api_key="your-permit-api-key"
))
```

#### Eunomia Authorization

```python
from fastmcp import FastMCP
from eunomia_mcp import EunomiaMiddleware

mcp = FastMCP("Policy-Protected Server")

# Add Eunomia authorization middleware
mcp.add_middleware(EunomiaMiddleware(
    policy_file="policies.json"
))
```

---

## Deployment

### Running Servers Locally

#### STDIO Transport

```python
# server.py
from fastmcp import FastMCP

mcp = FastMCP("MyServer")

@mcp.tool
def hello(name: str) -> str:
    return f"Hello, {name}!"

if __name__ == "__main__":
    mcp.run()  # Default: STDIO transport
```

Run:
```bash
python server.py
```

#### HTTP Transport

```python
if __name__ == "__main__":
    mcp.run(transport="http", host="0.0.0.0", port=8000)
```

Run:
```bash
python server.py
```

Access at: `http://localhost:8000/mcp`

### FastMCP CLI

#### Run Command

```bash
# Auto-detect server entrypoint
fastmcp run server.py

# Specify entrypoint
fastmcp run server.py:mcp

# With specific transport
fastmcp run server.py --transport http --port 8000

# With dependencies
fastmcp run server.py --with pandas --with requests

# With fastmcp.json configuration
fastmcp run fastmcp.json

# With environment variables
fastmcp run server.py --env API_KEY=secret --env DEBUG=true
```

#### Dev Command (with MCP Inspector)

```bash
# Launch with Inspector UI
fastmcp dev server.py

# With dependencies
fastmcp dev server.py --with pandas

# With fastmcp.json
fastmcp dev fastmcp.json
```

#### Install Command

```bash
# Install in Claude Desktop
fastmcp install claude-desktop server.py

# Install in Claude Code
fastmcp install claude-code server.py

# Install in Cursor
fastmcp install cursor server.py

# Generate MCP JSON
fastmcp install mcp-json server.py --name "My Server" --with pandas

# Copy to clipboard
fastmcp install mcp-json server.py --copy
```

#### Inspect Command

```bash
# Show text summary
fastmcp inspect server.py

# Output FastMCP format JSON
fastmcp inspect server.py --format fastmcp

# Output MCP protocol format
fastmcp inspect server.py --format mcp

# Save to file
fastmcp inspect server.py --format fastmcp -o manifest.json
```

### Declarative Configuration

#### fastmcp.json

```json
{
  "$schema": "https://gofastmcp.com/public/schemas/fastmcp.json/v1.json",
  "source": {
    "path": "server.py",
    "entrypoint": "mcp"
  },
  "environment": {
    "dependencies": ["pandas", "matplotlib", "seaborn"],
    "python_version": "3.11"
  },
  "deployment": {
    "transport": "http",
    "port": 8000,
    "log_level": "INFO"
  },
  "metadata": {
    "name": "My Analysis Server",
    "description": "Data analysis MCP server"
  }
}
```

Run:
```bash
fastmcp run fastmcp.json
```

### HTTP Deployment

#### Mounting in FastAPI

```python
from fastapi import FastAPI
from fastmcp import FastMCP

# Create MCP server
mcp = FastMCP("MyServer")

@mcp.tool
def analyze(data: str) -> dict:
    return {"result": f"Analyzed: {data}"}

# Create FastAPI app
api = FastAPI()

@api.get("/api/status")
def status():
    return {"status": "ok"}

# Mount MCP server
api.mount("/mcp", mcp.http_app())

# Run: uvicorn app:api --host 0.0.0.0 --port 8000
```

#### Mounting in Starlette

```python
from starlette.applications import Starlette
from starlette.routing import Mount
from fastmcp import FastMCP

mcp = FastMCP("MyServer")
mcp_app = mcp.http_app(path='/mcp')

app = Starlette(
    routes=[
        Mount("/mcp-server", app=mcp_app),
    ],
    lifespan=mcp_app.lifespan,
)
```

### FastMCP Cloud

1. **Prerequisites:**
   - GitHub account
   - GitHub repository with FastMCP server

2. **Deployment Steps:**
   - Visit [fastmcp.cloud](https://fastmcp.cloud)
   - Sign in with GitHub
   - Create project from repository
   - Configure server entrypoint (e.g., `server.py:mcp`)
   - Deploy!

3. **Features:**
   - Automatic dependency detection
   - Built-in authentication
   - Instant deployment
   - Free for personal servers

Your server URL: `https://your-project.fastmcp.app/mcp`

### Production Considerations

#### OAuth Token Security

For production OAuth deployments:

```python
from fastmcp.server.auth.providers.google import GoogleProvider
from fastmcp.server.auth.oauth_proxy import OAuthProxy

# Explicit JWT signing key
auth = GoogleProvider(
    client_id="...",
    client_secret="...",
    base_url="https://myserver.com",
    jwt_signing_key="your-base64-encoded-key"  # Required for production
)

# Network-accessible storage for tokens
from py_key_value_aio import RedisStore

storage = RedisStore(url="redis://localhost:6379")
auth.storage = storage
```

#### Mounting Authenticated Servers

When mounting OAuth-protected servers under a path prefix:

```python
from fastapi import FastAPI
from fastmcp import FastMCP

mcp = FastMCP("MyServer", auth=auth)
mcp_app = mcp.http_app(path="/mcp")

app = FastAPI()
app.mount("/api", mcp_app)

# IMPORTANT: Mount well-known routes at root
from starlette.routing import Mount

app.routes.insert(0, Mount("/.well-known", app=auth.get_well_known_routes()))
```

---

## Integrations

### FastAPI Integration

#### Generate MCP from FastAPI

```python
from fastapi import FastAPI
from fastmcp import FastMCP

# Existing FastAPI app
app = FastAPI()

@app.get("/products/{product_id}")
def get_product(product_id: int):
    return {"id": product_id, "name": "Product"}

# Convert to MCP server
mcp = FastMCP.from_fastapi(app=app)

if __name__ == "__main__":
    mcp.run()
```

#### Mount MCP in FastAPI

```python
from fastapi import FastAPI
from fastmcp import FastMCP

# Create MCP server
mcp = FastMCP("Analytics Tools")

@mcp.tool
def analyze_pricing(category: str) -> dict:
    """Analyze pricing for a category"""
    return {"category": category, "avg_price": 49.99}

# Mount in FastAPI
api = FastAPI()
api.mount("/mcp", mcp.http_app())
```

### OpenAPI Integration

```python
import httpx
from fastmcp import FastMCP

# Load OpenAPI spec
spec = httpx.get("https://api.example.com/openapi.json").json()

# Create HTTP client
client = httpx.AsyncClient(
    base_url="https://api.example.com",
    headers={"Authorization": "Bearer YOUR_TOKEN"}
)

# Create MCP server
mcp = FastMCP.from_openapi(
    openapi_spec=spec,
    client=client,
    name="My API Server"
)

if __name__ == "__main__":
    mcp.run()
```

#### Custom Route Mapping

```python
from fastmcp.server.openapi import RouteMap, MCPType

mcp = FastMCP.from_openapi(
    openapi_spec=spec,
    client=client,
    route_maps=[
        # GET requests with path params → ResourceTemplates
        RouteMap(methods=["GET"], pattern=r".*\{.*\}.*", mcp_type=MCPType.RESOURCE_TEMPLATE),
        # All other GET → Resources
        RouteMap(methods=["GET"], pattern=r".*", mcp_type=MCPType.RESOURCE),
        # Exclude admin routes
        RouteMap(pattern=r"^/admin/.*", mcp_type=MCPType.EXCLUDE),
    ]
)
```

### Anthropic API Integration

```python
from anthropic import Anthropic

client = Anthropic()

# Use FastMCP server with Anthropic API
response = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    mcp=[{
        "type": "remote",
        "url": "https://your-server.fastmcp.app/mcp",
        "name": "my_server"
    }],
    messages=[{"role": "user", "content": "Roll some dice!"}]
)

print(response.content)
```

### OpenAI Integration

```python
from openai import OpenAI

client = OpenAI()

# Use FastMCP with Responses API
resp = client.responses.create(
    model="gpt-4.1",
    tools=[{
        "type": "mcp",
        "server_label": "dice_server",
        "server_url": "https://your-server-url.com/mcp/",
        "require_approval": "never"
    }],
    input="Roll a few dice!"
)

print(resp.output_text)
```

### Gemini Integration

```python
import google.generativeai as genai
from fastmcp import Client

# Configure Gemini
genai.configure(api_key="YOUR_API_KEY")
model = genai.GenerativeModel(
    model_name='gemini-2.0-flash-exp',
    tools=Client("server.py")
)

# Use MCP tools
chat = model.start_chat()
response = chat.send_message("Roll some dice for me")
print(response.text)
```

### Claude Desktop Integration

```bash
fastmcp install claude-desktop server.py --server-name "My Server" --with pandas
```

Configuration added to `~/Library/Application Support/Claude/claude_desktop_config.json`

### Cursor Integration

```bash
fastmcp install cursor server.py --workspace /path/to/project --with pandas
```

### ChatGPT Integration

Deploy your server and add to ChatGPT:

1. **Chat Mode** (requires Developer Mode):
   - Settings → Developer Mode → Enable
   - Add MCP server URL

2. **Deep Research Mode**:
   - Works without Developer Mode
   - Add server URL in research settings

---

## CLI Reference

### Command Overview

| Command | Purpose | Dependency Management |
|---------|---------|----------------------|
| `run` | Run server directly | Uses local environment or uv with flags |
| `dev` | Run with MCP Inspector | Always uses uv subprocess |
| `install` | Install in MCP clients | Creates isolated environment |
| `inspect` | Generate server report | Uses current environment |
| `project prepare` | Create persistent uv project | Creates uv project with dependencies |
| `version` | Display version info | N/A |

### Common Options

| Option | Flag | Description |
|--------|------|-------------|
| Transport | `--transport` | `stdio`, `http`, `sse` |
| Host | `--host` | Server host (default: `127.0.0.1`) |
| Port | `--port` | Server port (default: `8000`) |
| Log Level | `--log-level` | `DEBUG`, `INFO`, `WARNING`, `ERROR` |
| Python Version | `--python` | Python version (e.g., `3.11`) |
| Dependencies | `--with` | Additional packages |
| Editable Package | `--with-editable`, `-e` | Local package directory |
| Requirements | `--with-requirements` | Requirements file |
| Environment | `--env` | Environment variables |
| Environment File | `--env-file` | Load from .env file |
| Project Directory | `--project` | Run in project directory |

### Examples

```bash
# Run with dependencies
fastmcp run server.py --with pandas --with matplotlib

# Dev mode with Inspector
fastmcp dev server.py -e . --with pandas

# Install in Claude Desktop with custom name
fastmcp install claude-desktop server.py --server-name "Data Tools" --with pandas

# Generate MCP JSON
fastmcp install mcp-json server.py --name "My Server" --copy

# Inspect server capabilities
fastmcp inspect server.py --format fastmcp -o manifest.json

# Prepare persistent project
fastmcp project prepare fastmcp.json --output-dir ./my-env
fastmcp run fastmcp.json --project ./my-env
```

---

## API Reference

### FastMCP Server Class

**Constructor:**

```python
FastMCP(
    name: str,
    instructions: str | None = None,
    version: str | None = None,
    auth: OAuthProvider | TokenVerifier | None = None,
    lifespan: AsyncContextManager | None = None,
    tools: list[Tool | Callable] | None = None,
    include_tags: set[str] | None = None,
    exclude_tags: set[str] | None = None,
    on_duplicate_tools: Literal["error", "warn", "replace"] = "error",
    on_duplicate_resources: Literal["error", "warn", "replace"] = "warn",
    on_duplicate_prompts: Literal["error", "warn", "replace"] = "replace",
    include_fastmcp_meta: bool = True
)
```

**Methods:**

- `run(transport="stdio", host="127.0.0.1", port=8000, path="/mcp")` - Run server
- `run_async()` - Async version of run
- `tool(fn, name=None, ...)` - Register tool decorator
- `resource(uri, name=None, ...)` - Register resource decorator
- `prompt(fn, name=None, ...)` - Register prompt decorator
- `mount(server, prefix)` - Mount sub-server
- `add_middleware(middleware)` - Add middleware
- `http_app(path="/mcp")` - Create ASGI app
- `get_tool(name)` - Get tool by name
- `get_resource(uri)` - Get resource by URI
- `get_prompt(name)` - Get prompt by name

**Class Methods:**

- `from_openapi(openapi_spec, client, ...)` - Create from OpenAPI spec
- `from_fastapi(app, name=None, ...)` - Create from FastAPI app
- `as_proxy(backend, name=None)` - Create proxy server

### FastMCP Client Class

**Constructor:**

```python
Client(
    transport: str | Transport | FastMCP | dict,
    log_handler: Callable | None = None,
    progress_handler: Callable | None = None,
    sampling_handler: Callable | None = None,
    roots: list | None = None,
    timeout: float = 30.0
)
```

**Methods:**

- `ping()` - Ping server
- `list_tools()` - List available tools
- `list_resources()` - List available resources
- `list_prompts()` - List available prompts
- `call_tool(name, arguments)` - Execute tool
- `read_resource(uri)` - Read resource
- `get_prompt(name, arguments)` - Get prompt
- `is_connected()` - Check connection status

### Context API

**Methods:**

- `fastmcp` - Get FastMCP instance
- `request_context` - Get request context
- `report_progress(progress, total, message)` - Report progress
- `read_resource(uri)` - Read resource
- `sample(messages, **params)` - Request LLM sampling
- `log(message, level, logger_name, extra)` - Send log message
- `info(message)` - Log info message
- `warning(message)` - Log warning message
- `error(message)` - Log error message
- `client_id` - Get client ID

### Tool API

**Tool Decorator:**

```python
@mcp.tool(
    name: str | None = None,
    description: str | None = None,
    tags: set[str] | None = None,
    output_schema: dict | None = None,
    annotations: ToolAnnotations | None = None,
    exclude_args: list[str] | None = None,
    meta: dict | None = None,
    enabled: bool = True
)
```

**Tool Class:**

```python
Tool.from_function(
    fn: Callable,
    name: str | None = None,
    description: str | None = None,
    tags: set[str] | None = None,
    enabled: bool = True,
    annotations: ToolAnnotations | None = None,
    meta: dict | None = None
)
```

### Resource API

**Resource Decorator:**

```python
@mcp.resource(
    uri: str,
    name: str | None = None,
    title: str | None = None,
    description: str | None = None,
    mime_type: str | None = None,
    tags: set[str] | None = None,
    enabled: bool = True,
    annotations: Annotations | None = None,
    meta: dict | None = None
)
```

### Prompt API

**Prompt Decorator:**

```python
@mcp.prompt(
    name: str | None = None,
    title: str | None = None,
    description: str | None = None,
    tags: set[str] | None = None,
    enabled: bool = True,
    meta: dict | None = None
)
```

---

## Advanced Features

### Server Composition & Mounting

```python
# Create specialized servers
weather_server = FastMCP("Weather")
calendar_server = FastMCP("Calendar")

@weather_server.tool
def get_forecast(city: str) -> dict:
    return {"city": city, "temp": 72}

@calendar_server.tool
def add_event(title: str) -> dict:
    return {"event": title, "added": True}

# Compose into main server
main = FastMCP("Main")
main.mount(weather_server, prefix="weather")
main.mount(calendar_server, prefix="calendar")

# Tools accessible as:
# - weather_get_forecast
# - calendar_add_event
```

### Proxy Servers

```python
# Create proxy to remote server
async def create_proxy():
    proxy = await FastMCP.as_proxy(
        "http://remote-server.com/mcp",
        name="Remote Proxy"
    )
    proxy.run(transport="stdio")

# Proxy with authentication
async def authenticated_proxy():
    proxy = await FastMCP.as_proxy(
        "https://protected-api.com/mcp",
        name="Authenticated Proxy",
        client_kwargs={"auth": "oauth"}
    )
    proxy.run(transport="stdio")

# Proxy that adds local tools
async def enhanced_proxy():
    proxy = await FastMCP.as_proxy(
        "http://remote-server.com/mcp",
        name="Enhanced Proxy"
    )
    
    @proxy.tool
    def local_tool(text: str) -> str:
        """Local tool added to proxy"""
        return f"Local: {text}"
    
    proxy.run()
```

### Sampling (LLM Requests from Server)

```python
from fastmcp import Context

@mcp.tool
async def generate_summary(content: str, ctx: Context) -> dict:
    """Generate a summary using the client's LLM"""
    
    # Request LLM completion from client
    summary = await ctx.sample(
        f"Summarize this in 10 words: {content[:200]}",
        system_prompt="You are a concise summarizer",
        max_tokens=50
    )
    
    return {
        "original_length": len(content),
        "summary": summary.text
    }
```

### Elicitation (User Input from Server)

```python
from fastmcp import Context

@mcp.tool
async def confirm_delete(file_path: str, ctx: Context) -> dict:
    """Delete file with user confirmation"""
    
    # Request user confirmation
    confirmation = await ctx.elicit(
        prompt=f"Are you sure you want to delete {file_path}?",
        schema={
            "type": "object",
            "properties": {
                "confirmed": {"type": "boolean"}
            }
        }
    )
    
    if confirmation.get("confirmed"):
        # Perform deletion
        return {"deleted": file_path}
    else:
        return {"deleted": None, "reason": "User cancelled"}
```

### Tool Transformation

```python
from fastmcp.utilities.mcp_config import MCPConfig

# Configure tool transformations
config = MCPConfig(
    mcp_servers={
        "my_server": {
            "url": "http://localhost:8000/mcp",
            "tool_transformations": {
                "rename": {
                    "old_tool_name": "new_tool_name"
                },
                "exclude": ["internal_tool", "debug_tool"]
            }
        }
    }
)

client = Client(config)
```

### Component Manager

```python
from fastmcp.contrib.component_manager import ComponentManager

mcp = FastMCP("Dynamic Server")

# Add component manager
component_manager = ComponentManager(mcp)
mcp.add_middleware(component_manager)

# Enable/disable components via HTTP API
# POST /tools/{tool_name}/enable
# POST /tools/{tool_name}/disable
# POST /resources/{uri:path}/enable
# POST /prompts/{prompt_name}/disable
```

### Storage Backends

```python
from py_key_value_aio import RedisStore, ElasticsearchStore, DynamoDBStore

# Redis storage
storage = RedisStore(url="redis://localhost:6379")

# Elasticsearch storage
storage = ElasticsearchStore(
    hosts=["http://localhost:9200"],
    index_name="mcp-storage"
)

# DynamoDB storage
storage = DynamoDBStore(
    table_name="mcp-storage",
    region_name="us-east-1"
)

# Use with OAuth provider
from fastmcp.server.auth.providers.google import GoogleProvider

auth = GoogleProvider(
    client_id="...",
    client_secret="...",
    base_url="https://myserver.com",
    storage=storage  # Use network storage
)
```

---

## Best Practices

### Development Workflow

1. **Start with clear server design:**
   ```python
   mcp = FastMCP(
       name="Descriptive Name",
       instructions="Clear usage instructions for LLMs",
       version="1.0.0"
   )
   ```

2. **Use type hints and docstrings:**
   ```python
   @mcp.tool
   def analyze_data(data: list[float], threshold: float = 0.5) -> dict:
       """
       Analyze numerical data against a threshold.
       
       Args:
           data: List of numerical values to analyze
           threshold: Minimum value to consider (default: 0.5)
           
       Returns:
           Dictionary with analysis results including count, average, and filtered values
       """
       filtered = [x for x in data if x >= threshold]
       return {
           "count": len(filtered),
           "average": sum(filtered) / len(filtered) if filtered else 0,
           "values": filtered
       }
   ```

3. **Test with FastMCP Client:**
   ```python
   import pytest
   from fastmcp import Client
   
   @pytest.fixture
   async def client():
       async with Client(mcp) as c:
           yield c
   
   async def test_analyze_data(client):
       result = await client.call_tool(
           "analyze_data",
           {"data": [0.3, 0.6, 0.9], "threshold": 0.5}
       )
       assert result.data["count"] == 2
   ```

4. **Use fastmcp.json for configuration:**
   ```json
   {
     "$schema": "https://gofastmcp.com/public/schemas/fastmcp.json/v1.json",
     "source": {"path": "server.py", "entrypoint": "mcp"},
     "environment": {"dependencies": ["pandas", "requests"]},
     "deployment": {"transport": "http", "port": 8000}
   }
   ```

### Production Deployment

1. **Use explicit authentication:**
   - Never rely on development defaults
   - Set `jwt_signing_key` for OAuth providers
   - Use network-accessible storage backends

2. **Configure proper logging:**
   ```python
   mcp = FastMCP("Production Server")
   mcp.add_middleware(LoggingMiddleware(level="INFO"))
   ```

3. **Implement health checks:**
   ```python
   @mcp.custom_route("/health", methods=["GET"])
   async def health_check():
       return {"status": "healthy", "timestamp": datetime.utcnow()}
   ```

4. **Set up monitoring:**
   - Use `TimingMiddleware` for performance metrics
   - Implement custom metrics collection
   - Monitor token usage for OAuth flows

5. **Handle errors gracefully:**
   ```python
   @mcp.tool
   async def risky_operation(data: str) -> dict:
       """Operation that might fail"""
       try:
           result = await perform_operation(data)
           return {"success": True, "result": result}
       except Exception as e:
           await ctx.error(f"Operation failed: {str(e)}")
           return {"success": False, "error": str(e)}
   ```

### Security Best Practices

1. **Always use authentication in production:**
   ```python
   # ❌ Bad
   mcp = FastMCP("Production Server")  # No auth
   
   # ✅ Good
   mcp = FastMCP("Production Server", auth=oauth_provider)
   ```

2. **Validate tool inputs:**
   ```python
   from pydantic import Field
   from typing import Annotated
   
   @mcp.tool
   def process_data(
       value: Annotated[int, Field(ge=0, le=100)],
       email: Annotated[str, Field(pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')]
   ) -> dict:
       """Process data with validated inputs"""
       return {"processed": value}
   ```

3. **Use environment variables for secrets:**
   ```python
   import os
   
   auth = GoogleProvider(
       client_id=os.getenv("GOOGLE_CLIENT_ID"),
       client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
       base_url=os.getenv("SERVER_BASE_URL")
   )
   ```

4. **Implement rate limiting:**
   ```python
   from fastmcp.server.middleware import RateLimitMiddleware
   
   mcp.add_middleware(RateLimitMiddleware(
       max_requests=100,
       window_seconds=60
   ))
   ```

### Performance Optimization

1. **Use async for I/O operations:**
   ```python
   @mcp.tool
   async def fetch_data(url: str) -> dict:
       """Fetch data asynchronously"""
       async with httpx.AsyncClient() as client:
           response = await client.get(url)
           return response.json()
   ```

2. **Implement response caching:**
   ```python
   from fastmcp.server.middleware.caching import ResponseCachingMiddleware
   
   mcp.add_middleware(ResponseCachingMiddleware(
       tools_ttl=300,      # 5 minutes
       resources_ttl=60    # 1 minute
   ))
   ```

3. **Optimize resource templates:**
   ```python
   # ❌ Bad: Loads all data every time
   @mcp.resource("data://{id}")
   def get_data(id: str) -> dict:
       all_data = load_all_data()  # Expensive!
       return all_data[id]
   
   # ✅ Good: Loads only requested data
   @mcp.resource("data://{id}")
   async def get_data(id: str) -> dict:
       return await load_data_by_id(id)
   ```

4. **Use connection pooling:**
   ```python
   # Create shared async client
   client = httpx.AsyncClient(
       limits=httpx.Limits(max_connections=100)
   )
   
   @asynccontextmanager
   async def lifespan():
       yield
       await client.aclose()
   
   mcp = FastMCP("Optimized Server", lifespan=lifespan)
   ```

### Debugging Tips

1. **Use the MCP Inspector:**
   ```bash
   fastmcp dev server.py
   ```

2. **Enable debug logging:**
   ```bash
   fastmcp run server.py --log-level DEBUG
   ```

3. **Inspect server capabilities:**
   ```bash
   fastmcp inspect server.py --format fastmcp -o debug-manifest.json
   ```

4. **Test with in-memory client:**
   ```python
   from fastmcp import Client
   
   async with Client(mcp) as client:
       # Direct access for debugging
       tools = await client.list_tools()
       print(f"Available tools: {[t.name for t in tools]}")
   ```

---

## Resources & Links

### Official Documentation

- **Website**: [https://gofastmcp.com](https://gofastmcp.com)
- **GitHub**: [https://github.com/jlowin/fastmcp](https://github.com/jlowin/fastmcp)
- **Discord**: [https://discord.com/invite/aGsSC3yDF4](https://discord.com/invite/aGsSC3yDF4)
- **FastMCP Cloud**: [https://fastmcp.cloud](https://fastmcp.cloud)

### LLM-Friendly Formats

- **MCP Server**: `https://gofastmcp.com/mcp`
- **llms.txt**: [https://gofastmcp.com/llms.txt](https://gofastmcp.com/llms.txt)
- **llms-full.txt**: [https://gofastmcp.com/llms-full.txt](https://gofastmcp.com/llms-full.txt)
- **Any page as markdown**: Append `.md` to URL (e.g., `https://gofastmcp.com/getting-started/welcome.md`)

### MCP Ecosystem

- **Model Context Protocol**: [https://modelcontextprotocol.io](https://modelcontextprotocol.io)
- **MCP Python SDK**: [https://github.com/modelcontextprotocol/python-sdk](https://github.com/modelcontextprotocol/python-sdk)
- **MCP Inspector**: [https://github.com/modelcontextprotocol/inspector](https://github.com/modelcontextprotocol/inspector)

### Authentication Providers

- **Google OAuth**: [https://console.cloud.google.com](https://console.cloud.google.com)
- **GitHub OAuth**: [https://github.com/settings/developers](https://github.com/settings/developers)
- **Azure (Microsoft Entra)**: [https://portal.azure.com](https://portal.azure.com)
- **WorkOS**: [https://workos.com](https://workos.com)
- **Auth0**: [https://auth0.com](https://auth0.com)
- **AWS Cognito**: [https://aws.amazon.com/cognito](https://aws.amazon.com/cognito)
- **Descope**: [https://www.descope.com](https://www.descope.com)
- **Scalekit**: [https://app.scalekit.com](https://app.scalekit.com)

### Authorization Middleware

- **Permit.io**: [https://github.com/permitio/permit-fastmcp](https://github.com/permitio/permit-fastmcp)
- **Eunomia**: [https://github.com/whataboutyou-ai/eunomia](https://github.com/whataboutyou-ai/eunomia)

### Version Information

- **Current Version**: 2.13.0 "Cache Me If You Can"
- **MCP Version**: 1.17.0
- **Python Support**: 3.10+
- **Release Date**: October 25, 2025

### Key Release Features

**v2.13.0 (Latest):**
- Pluggable storage backends with py-key-value-aio
- OAuth maturity with consent screen and RFC 7662 introspection
- Platform-aware token management
- Response caching middleware
- Path prefix mounting for OAuth

**v2.12.0:**
- Enterprise OAuth with WorkOS AuthKit
- Declarative JSON configuration (fastmcp.json)
- OAuth proxy for non-DCR providers
- Sampling API fallback
- Comprehensive auth support (Google, GitHub, Azure, Auth0, AWS Cognito)

**v2.11.0:**
- Next-generation OpenAPI parser (experimental)
- Performance improvements
- Better serverless compatibility

**v2.10.0:**
- Full MCP 2025-06-18 spec compliance
- Elicitation support
- Output schemas for tools
- Proxy server forwarding

---

## Changelog Highlights

### Recent Breaking Changes

**v2.13.0:**
- OAuth providers now require explicit JWT signing keys for production
- Token storage must be network-accessible for multi-instance deployments

**v2.12.0:**
- Authentication module (`fastmcp.server.auth`) is exempt from stability guarantees temporarily

**v2.10.0:**
- `client.call_tool()` return signature changed for elicitation support

### Migration Guides

See [Upgrade Guide](https://gofastmcp.com/development/upgrade-guide) for detailed migration instructions.

---

## Contributing

FastMCP welcomes contributions! See the [Contributing Guide](https://gofastmcp.com/development/contributing) for:

- Setting up development environment
- Running tests and pre-commit hooks
- Submitting issues and pull requests
- Code standards and review process

**Development Setup:**

```bash
git clone https://github.com/jlowin/fastmcp.git
cd fastmcp
uv sync
uv run pre-commit install
```

**Running Tests:**

```bash
# Run all tests
uv run pytest

# Run with coverage
uv run pytest --cov=fastmcp

# Preview documentation
just docs
```

---

## License

FastMCP is made with 💙 by [Prefect](https://www.prefect.io/).

---

**This documentation was compiled on October 25, 2025 based on FastMCP 2.13.0**

For the most up-to-date information, visit [https://gofastmcp.com](https://gofastmcp.com)
