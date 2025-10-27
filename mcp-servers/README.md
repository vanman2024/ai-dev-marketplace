# MCP Servers

This directory contains custom Model Context Protocol (MCP) servers built with FastMCP for the AI Dev Marketplace.

## 🚀 Available Servers

### 1. CATS MCP Server (`cats-mcp-server/`)

**Purpose**: Complete Applicant Tracking System API wrapper

**Features**:
- 162 endpoints across 17 toolsets
- Candidate, job, company, and pipeline management
- Resume parsing and attachments
- Webhooks and analytics
- Configurable toolset loading

**Key Endpoints**:
- Candidates (CRUD, search, filtering)
- Jobs (posting, applications, workflows)
- Companies & Contacts
- Pipelines (workflow management)
- Activities, Tags, Tasks
- Webhooks (24 event types)

**API Details**:
- Base URL: `https://api.catsone.com/v3`
- Rate Limit: 500 requests/hour
- Authentication: Token-based

**Quick Start**:
```bash
cd cats-mcp-server
cp .env.example .env
# Edit .env with your CATS_API_KEY
./start.sh
```

**Server URL**: `http://localhost:8000`

**Documentation**: See `cats-mcp-server/README.md`

---

### 2. Marketing Automation Server (`marketing-automation/`)

**Purpose**: AI-powered marketing content generation and automation

**Features**:
- **Image Generation**: Google Imagen 3/4 ($0.02-0.06 per image)
- **Video Generation**: Google Veo 2/3 ($0.10-0.50 per second)
- **Content Generation**: Claude 3.5 Sonnet + Gemini 2.0 Flash
- **Cost Tracking**: Built-in cost estimation
- **Batch Operations**: Generate multiple assets efficiently

**Capabilities**:
- Generate social media images (1024x1024, 1536x1536)
- Create marketing videos (1080p, 24-30fps, up to 8s)
- AI-powered content writing
- Automated asset organization
- Usage analytics

**Pricing**:
- Imagen 3: $0.02-0.04 per image
- Imagen 4: $0.06 per image
- Veo 2: $0.10 per second (4K)
- Veo 3: $0.50 per second (4K)
- Claude 3.5 Sonnet: $3/$15 per million tokens
- Gemini 2.0 Flash: Free tier available

**Quick Start**:
```bash
cd marketing-automation
cp .env.example .env
# Edit .env with your Google Cloud and API keys
./start.sh  # If exists, or:
python server.py
```

**Server URL**: `http://localhost:8000` (or configured port)

**Documentation**: See `marketing-automation/README.md`

---

## 🔧 Common Setup

### Prerequisites

Both servers require:
- Python 3.10+
- pip (Python package manager)
- Virtual environment support

### Standard Setup Process

1. **Clone/Navigate to server directory**:
   ```bash
   cd mcp-servers/<server-name>
   ```

2. **Create virtual environment** (if not exists):
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Linux/Mac
   # or
   .venv\Scripts\activate  # Windows
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment**:
   ```bash
   cp .env.example .env
   nano .env  # Edit with your API keys
   ```

5. **Start server**:
   ```bash
   python server.py
   # or if start script exists:
   ./start.sh
   ```

---

## 🔌 MCP Integration

### Adding to Claude Desktop

Add to your Claude Desktop configuration (`~/.config/claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "cats-api": {
      "url": "http://localhost:8000/sse",
      "transport": {
        "type": "sse"
      }
    },
    "marketing-automation": {
      "url": "http://localhost:8001/sse",
      "transport": {
        "type": "sse"
      }
    }
  }
}
```

**Note**: Adjust ports if you've configured servers differently.

### Adding to Project `.mcp.json`

The project root `.mcp.json` can reference these servers:

```json
{
  "mcpServers": {
    "cats-api": {
      "command": "python",
      "args": ["mcp-servers/cats-mcp-server/server.py"],
      "cwd": "/home/vanman2025/Projects/ai-dev-marketplace"
    },
    "marketing-automation": {
      "command": "python",
      "args": ["mcp-servers/marketing-automation/server.py"],
      "cwd": "/home/vanman2025/Projects/ai-dev-marketplace"
    }
  }
}
```

---

## 📊 Server Comparison

| Feature | CATS MCP Server | Marketing Automation |
|---------|----------------|---------------------|
| **Purpose** | ATS/Recruitment API | Content Generation |
| **Primary SDK** | CATS API v3 | Google Vertex AI |
| **Framework** | FastMCP | FastMCP |
| **External API** | Yes (CATS) | Yes (Google Cloud) |
| **Rate Limits** | 500/hour | Variable by service |
| **Cost Model** | Included in CATS plan | Pay-per-use |
| **Authentication** | API Token | Service Account + API Keys |
| **Endpoints** | 162 | ~15-20 tools |
| **Best For** | Recruitment workflows | Marketing campaigns |

---

## 🛠️ Development

### Creating a New MCP Server

1. **Create server directory**:
   ```bash
   mkdir mcp-servers/my-new-server
   cd mcp-servers/my-new-server
   ```

2. **Initialize FastMCP project**:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install "fastmcp[all]"
   ```

3. **Create `server.py`**:
   ```python
   from fastmcp import FastMCP
   
   mcp = FastMCP("My Server")
   
   @mcp.tool()
   async def my_tool(param: str) -> dict:
       """Tool description"""
       return {"result": param}
   ```

4. **Add documentation**:
   - Create `README.md`
   - Add `.env.example`
   - Document setup and usage

5. **Update this README** with new server info

### Testing

Each server should include:
- `test_server.py` - Unit tests
- Example usage in README
- Verification script

---

## 📚 Additional Resources

### FastMCP Documentation
- **GitHub**: https://github.com/jlowin/fastmcp
- **PyPI**: https://pypi.org/project/fastmcp/
- **Docs**: Plugin docs at `plugins/fastmcp/`

### MCP Protocol
- **Spec**: https://modelcontextprotocol.io
- **Claude Integration**: https://docs.anthropic.com/claude/docs/mcp

### Related Documentation
- **CATS API**: `plugins/domain-plugin-builder/docs/reference/cats-api-documentation.md`
- **Google Imagen/Veo**: `plugins/domain-plugin-builder/docs/reference/google-imagen-veo-documentation.md`
- **Marketing Automation**: `plugins/domain-plugin-builder/docs/reference/ai-marketing-automation-system.md`

---

## 🐛 Troubleshooting

### Server Won't Start

1. **Check virtual environment**:
   ```bash
   which python  # Should point to .venv/bin/python
   ```

2. **Verify dependencies**:
   ```bash
   pip list | grep fastmcp
   ```

3. **Check environment variables**:
   ```bash
   cat .env
   ```

### Connection Issues

1. **Verify server is running**:
   ```bash
   curl http://localhost:8000
   ```

2. **Check port conflicts**:
   ```bash
   lsof -i :8000
   ```

3. **Review server logs** in terminal output

### API Errors

1. **Verify API keys** in `.env`
2. **Check rate limits** for external APIs
3. **Review API documentation** for endpoint requirements

---

## 📝 Maintenance

### Updating Dependencies

```bash
cd mcp-servers/<server-name>
source .venv/bin/activate
pip install --upgrade fastmcp httpx
pip freeze > requirements.txt
```

### Adding New Tools

1. Edit `server.py`
2. Add tool with `@mcp.tool()` decorator
3. Document in server README
4. Test thoroughly
5. Update version in `pyproject.toml`

---

**Last Updated**: 2025-10-26  
**Maintained By**: AI Dev Marketplace Team
