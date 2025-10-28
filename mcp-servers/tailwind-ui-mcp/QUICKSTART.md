# Tailwind UI MCP Server - Quick Start

Get up and running in 2 minutes.

## Installation (One-Time Setup)

```bash
# 1. Navigate to project
cd /home/vanman2025/Projects/ai-dev-marketplace/tailwind-ui-mcp

# 2. Create and activate virtual environment
uv venv && source .venv/bin/activate

# 3. Install FastMCP
uv pip install fastmcp python-dotenv

# 4. Copy environment config
cp .env.example .env
```

## Running the Server

### STDIO Mode (Claude Desktop/Code)
```bash
python server.py
```

### HTTP Mode (Web/API)
```bash
python server.py --transport http --port 8000
```

## Testing

```bash
# Check server info
# In Claude: "Show me info about the Tailwind UI server"

# Get example queries
# In Claude: "How do I search for button components?"
```

## Adding to Claude Desktop

Edit `~/.config/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "tailwind-ui": {
      "command": "python",
      "args": ["/home/vanman2025/Projects/ai-dev-marketplace/tailwind-ui-mcp/server.py"],
      "env": {
        "SUPABASE_PROJECT_ID": "wsmhiiharnhqupdniwgw"
      }
    }
  }
}
```

Restart Claude Desktop.

## Project Structure

```
tailwind-ui-mcp/
├── server.py                           # Main FastMCP server
├── pyproject.toml                      # Python project config
├── requirements.txt                    # Dependencies
├── .env                                # Your config (gitignored)
├── .env.example                        # Config template
├── README_PYTHON.md                    # Full documentation
├── SETUP.md                            # Detailed setup guide
├── TOOLS.md                            # Tool development guide
├── QUICKSTART.md                       # This file
├── claude_desktop_config.example.json  # Claude Desktop example
└── .venv/                              # Virtual environment (gitignored)
```

## Current Tools

1. **server_info** - Get server metadata and statistics
2. **get_example_query** - Get SQL query examples

## Planned Tools (To Be Added)

3. **search_components** - Natural language search
4. **get_component_code** - Retrieve full component code
5. **list_categories** - Browse categories
6. **filter_by_tags** - Filter by features
7. **get_dependencies** - Get component dependencies
8. **browse_by_category** - Explore by category

## Common Commands

```bash
# Activate environment
source .venv/bin/activate

# Run server (STDIO)
python server.py

# Run server (HTTP on port 8000)
python server.py --transport http

# Install dependencies
uv pip install -r requirements.txt

# Update FastMCP
uv pip install --upgrade fastmcp

# Deactivate environment
deactivate
```

## Database Info

- **Project ID**: wsmhiiharnhqupdniwgw
- **Table**: sections
- **Components**: 490+
- **Access**: Via Supabase MCP tools

## Key Files

| File | Purpose |
|------|---------|
| `server.py` | Main server code |
| `.env` | Configuration (DO NOT COMMIT) |
| `requirements.txt` | Python dependencies |
| `README_PYTHON.md` | Full documentation |
| `SETUP.md` | Installation guide |
| `TOOLS.md` | Tool development |

## Troubleshooting

**Server won't start?**
```bash
source .venv/bin/activate
uv pip install fastmcp python-dotenv
```

**Can't connect to Claude?**
- Check `claude_desktop_config.json` syntax
- Verify absolute path to server.py
- Restart Claude Desktop

**Import errors?**
```bash
uv pip install --force-reinstall fastmcp
```

## Next Steps

1. **Verify Setup**: Run `python server.py` successfully
2. **Add to Claude**: Configure `claude_desktop_config.json`
3. **Test Tools**: Try `server_info` tool
4. **Add Components**: Implement remaining 6 tools (see TOOLS.md)
5. **Customize**: Extend with your own tools

## Documentation

- **Setup Guide**: SETUP.md
- **Full Docs**: README_PYTHON.md
- **Tool Guide**: TOOLS.md
- **FastMCP Docs**: https://gofastmcp.com

## Support

- **FastMCP**: https://github.com/jlowin/fastmcp
- **MCP Protocol**: https://modelcontextprotocol.io
- **Supabase**: https://supabase.com/docs

---

**Ready!** Your Tailwind UI MCP server is set up. Add the remaining tools to start accessing your component library with natural language.
