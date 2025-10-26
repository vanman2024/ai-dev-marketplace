# CATS MCP Server - Deployment Guide

This guide covers all deployment modes for the CATS MCP server.

## Deployment Modes

The CATS MCP server supports three deployment scenarios:

1. **STDIO (Local Integration)** - For Claude Desktop, Claude Code, Cursor
2. **HTTP (Remote Services)** - For web applications, cloud deployment, multiple clients
3. **Auth-Required** - Add OAuth/JWT authentication to either STDIO or HTTP

---

## 1. STDIO Deployment (Local Integration)

**Use case**: Claude Desktop, Claude Code, Cursor integration via `.mcp.json`

### Configuration

Add to your `.mcp.json` file:

```json
{
  "mcpServers": {
    "cats": {
      "command": "python",
      "args": [
        "/absolute/path/to/cats-mcp-server/server.py"
      ],
      "env": {
        "CATS_API_KEY": "your_cats_api_key_here",
        "CATS_API_BASE_URL": "https://api.catsone.com/v3",
        "CATS_TOOLSETS": "candidates,jobs,pipelines",
        "CATS_TRANSPORT": "stdio"
      }
    }
  }
}
```

### .mcp.json Locations

- **Claude Desktop**: `~/.claude/config.json`
- **Claude Code**: `.mcp.json` in project root
- **Cursor**: `.cursor/mcp_config.json`

### Testing STDIO Locally

```bash
# Set environment variables
export CATS_API_KEY="your_api_key"
export CATS_TRANSPORT="stdio"
export CATS_TOOLSETS="candidates,jobs,pipelines"

# Run server (will use STDIO by default)
python server.py
```

---

## 2. HTTP Deployment (Remote Services)

**Use case**: Web applications, cloud hosting, remote access, multiple clients

### Basic HTTP Server

```bash
# Set environment variables
export CATS_API_KEY="your_api_key"
export CATS_TRANSPORT="http"
export CATS_PORT="8000"
export CATS_HOST="0.0.0.0"
export CATS_TOOLSETS="candidates,jobs,pipelines"

# Run HTTP server
python server.py
```

Access at: `http://localhost:8000/mcp`

### Production HTTP Deployment

**Docker Example**:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN pip install fastmcp httpx python-dotenv

# Copy server files
COPY server.py toolsets_*.py ./

# Set environment
ENV CATS_TRANSPORT=http
ENV CATS_PORT=8000
ENV CATS_HOST=0.0.0.0

# Expose port
EXPOSE 8000

# Run server
CMD ["python", "server.py"]
```

**docker-compose.yml**:

```yaml
version: '3.8'
services:
  cats-mcp:
    build: .
    ports:
      - "8000:8000"
    environment:
      - CATS_API_KEY=${CATS_API_KEY}
      - CATS_API_BASE_URL=https://api.catsone.com/v3
      - CATS_TOOLSETS=candidates,jobs,pipelines,companies
      - CATS_TRANSPORT=http
      - CATS_PORT=8000
    restart: unless-stopped
```

### Cloud Deployment

**Railway/Render/Fly.io**:

1. Set environment variables in platform UI:
   - `CATS_API_KEY`
   - `CATS_TRANSPORT=http`
   - `CATS_PORT=8000`
   - `CATS_TOOLSETS=candidates,jobs,pipelines`

2. Deploy from Git repository

3. Access at: `https://your-app.railway.app/mcp`

---

## 3. Authentication (Future)

CATS server currently uses API key authentication to the CATS API. For multi-user scenarios, you can add OAuth/JWT:

### OAuth Integration Example

```python
from fastmcp.server.auth.providers.google import GoogleProvider

auth = GoogleProvider(
    client_id="your_google_client_id",
    client_secret="your_google_client_secret",
    redirect_uri="http://localhost:8000/oauth/callback"
)

mcp = FastMCP("CATS API v3", auth=auth)
```

### Supported Auth Providers

- Google OAuth 2.1
- GitHub OAuth
- Azure AD
- Auth0
- WorkOS/AuthKit
- AWS Cognito
- JWT Bearer Tokens

See [FastMCP Auth Documentation](https://gofastmcp.com/servers/auth/oauth-proxy) for details.

---

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CATS_API_KEY` | **Yes** | - | Your CATS API v3 key |
| `CATS_API_BASE_URL` | No | `https://api.catsone.com/v3` | CATS API endpoint |
| `CATS_TRANSPORT` | No | `stdio` | Transport mode: `stdio` or `http` |
| `CATS_TOOLSETS` | No | DEFAULT toolsets | Comma-separated toolset list or `all` |
| `CATS_PORT` | No | `8000` | HTTP server port (HTTP mode only) |
| `CATS_HOST` | No | `0.0.0.0` | HTTP server host (HTTP mode only) |

---

## Toolset Configuration

Load only the toolsets you need for optimal token usage:

```bash
# Default toolsets (77 tools)
export CATS_TOOLSETS=""  # Uses DEFAULT

# Specific toolsets
export CATS_TOOLSETS="candidates,jobs,companies"

# Everything (163 tools)
export CATS_TOOLSETS="all"

# List available toolsets
python server.py --list-toolsets
```

---

## Testing

### In-Memory Testing (No Transport)

```python
import pytest
from fastmcp.client import Client
from server import mcp

@pytest.fixture
async def mcp_client():
    async with Client(transport=mcp) as client:
        yield client

async def test_list_tools(mcp_client):
    tools = await mcp_client.list_tools()
    assert len(tools) > 0
```

Run: `pytest test_demo.py`

### STDIO Testing

```bash
export CATS_TRANSPORT="stdio"
python server.py
# Server runs in STDIO mode, ready for .mcp.json integration
```

### HTTP Testing

```bash
export CATS_TRANSPORT="http"
python server.py

# In another terminal:
curl http://localhost:8000/mcp
```

---

## Troubleshooting

### "CATS_API_KEY not configured"
- Set `CATS_API_KEY` environment variable or in `.mcp.json`

### "Module not found: toolsets_*"
- Ensure all toolset files (`toolsets_default.py`, `toolsets_recruiting.py`, `toolsets_data.py`) are in the same directory as `server.py`

### STDIO mode not working in Claude Desktop
- Verify `.mcp.json` path is absolute (not relative)
- Check environment variables are set in config
- Restart Claude Desktop after config changes

### HTTP mode connection refused
- Verify port 8000 is not in use: `lsof -i :8000`
- Check firewall rules allow port 8000
- Use `0.0.0.0` as host for external access

### Rate Limiting (500 req/hour)
- Monitor `X-Rate-Limit-Remaining` response header
- Implement exponential backoff on 429 responses
- Consider caching frequently accessed data

---

## Security Best Practices

1. **Never commit API keys** - Use `.env` files (add to `.gitignore`)
2. **Use environment variables** - Don't hardcode credentials
3. **HTTPS only in production** - Use SSL/TLS for HTTP deployments
4. **Restrict toolsets** - Load only needed toolsets per user/app
5. **Add authentication** - For multi-user or public deployments
6. **Monitor rate limits** - Implement retry logic and caching
7. **Validate inputs** - CATS server validates all parameters

---

## Production Checklist

- [ ] API key stored securely (environment variable)
- [ ] Transport mode configured (`stdio` or `http`)
- [ ] Toolsets optimized for use case
- [ ] HTTPS/SSL configured (HTTP mode)
- [ ] Rate limiting implemented
- [ ] Error handling and logging enabled
- [ ] Monitoring and health checks
- [ ] Backup/fallback strategy
- [ ] Documentation for users

---

## Resources

- **CATS API Docs**: https://docs.catsone.com/api/v3/
- **FastMCP Docs**: https://gofastmcp.com/
- **MCP Protocol**: https://modelcontextprotocol.io/
- **FastMCP Deployment**: https://gofastmcp.com/deployment/running-server
- **FastMCP Auth**: https://gofastmcp.com/servers/auth/oauth-proxy
