# Tailwind UI MCP Server - Setup Guide

Complete setup instructions for getting the Tailwind UI FastMCP server running.

## Quick Start (5 Minutes)

```bash
# 1. Navigate to project
cd /home/vanman2025/Projects/ai-dev-marketplace/tailwind-ui-mcp

# 2. Create virtual environment
uv venv

# 3. Activate environment
source .venv/bin/activate

# 4. Install FastMCP
uv pip install fastmcp python-dotenv

# 5. Configure environment
cp .env.example .env

# 6. Test server
python server.py
```

## Detailed Setup

### Step 1: Prerequisites Check

```bash
# Check Python version (must be 3.10+)
python --version

# Check if uv is installed
uv --version

# If uv not installed, install it
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Step 2: Virtual Environment

```bash
# Using uv (recommended)
uv venv

# Or using standard venv
python -m venv .venv
```

### Step 3: Activate Environment

```bash
# Linux/Mac
source .venv/bin/activate

# Windows
.venv\Scripts\activate

# Verify activation (should show .venv path)
which python
```

### Step 4: Install Dependencies

```bash
# Using uv (faster)
uv pip install -r requirements.txt

# Or using pip
pip install -r requirements.txt

# Verify installation
python -c "import fastmcp; print(fastmcp.__version__)"
```

### Step 5: Configure Environment

```bash
# Copy example file
cp .env.example .env

# Edit with your values (optional - defaults work)
# SUPABASE_PROJECT_ID is already set to wsmhiiharnhqupdniwgw
```

### Step 6: Test the Server

```bash
# Run in STDIO mode (default)
python server.py

# You should see:
# "Starting Tailwind UI Components MCP Server on STDIO"

# Press Ctrl+C to stop
```

### Step 7: Test HTTP Mode

```bash
# Run HTTP server on port 8000
python server.py --transport http

# Test with curl
curl http://localhost:8000/health

# Or visit in browser
# http://localhost:8000
```

## Integration with Claude Desktop

### Step 1: Locate Claude Desktop Config

```bash
# Linux
~/.config/Claude/claude_desktop_config.json

# Mac
~/Library/Application Support/Claude/claude_desktop_config.json

# Windows
%APPDATA%\Claude\claude_desktop_config.json
```

### Step 2: Add Server Configuration

Edit `claude_desktop_config.json`:

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

**Important:** Update the path in `args` to match your actual installation location.

### Step 3: Restart Claude Desktop

1. Quit Claude Desktop completely
2. Relaunch Claude Desktop
3. Check MCP status in settings

## Integration with Claude Code (VS Code)

### Step 1: Create MCP Config

Create or edit `.vscode/mcp.json` in your project:

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

### Step 2: Reload VS Code

1. Press `Cmd/Ctrl + Shift + P`
2. Type "Reload Window"
3. Press Enter

## Verification

### Test 1: Server Info Tool

In Claude Desktop/Code, try:
```
Can you show me information about the Tailwind UI server?
```

Expected response:
- Server name: "Tailwind UI Components"
- Version: 0.1.0
- Component count: 490+
- Categories list

### Test 2: Example Queries

In Claude Desktop/Code, try:
```
How do I search for button components in the Tailwind UI database?
```

Expected response:
- Example SQL queries
- Database field descriptions
- Query patterns

## Troubleshooting

### Error: "ModuleNotFoundError: No module named 'fastmcp'"

**Solution:**
```bash
# Ensure virtual environment is activated
source .venv/bin/activate

# Reinstall FastMCP
uv pip install fastmcp
```

### Error: "python: command not found"

**Solution:**
```bash
# Use python3 instead
python3 server.py

# Or create alias
alias python=python3
```

### Error: "Permission denied"

**Solution:**
```bash
# Make server.py executable
chmod +x server.py

# Or run with python directly
python server.py
```

### Error: "Address already in use"

**Solution:**
```bash
# Use different port
python server.py --transport http --port 8001

# Or find and kill process on port 8000
lsof -ti:8000 | xargs kill -9
```

### Claude Desktop doesn't see the server

**Solutions:**
1. Check config file syntax (valid JSON)
2. Verify absolute path to server.py
3. Check Python path is correct: `which python`
4. Restart Claude Desktop
5. Check Claude Desktop logs

### HTTP mode works but STDIO doesn't

**Solution:**
```bash
# Test STDIO directly
echo '{"jsonrpc": "2.0", "method": "ping", "id": 1}' | python server.py
```

## Next Steps

Once the server is running successfully:

1. **Add Component Search Tools**: Use `/fastmcp:add-components` to add:
   - `search_components` - Natural language search
   - `get_component_code` - Retrieve code
   - `list_categories` - Browse categories
   - `filter_by_tags` - Tag-based filtering

2. **Configure Supabase MCP**: Ensure Supabase MCP server is also running
   for database queries

3. **Test Full Workflow**: Try searching and retrieving components

4. **Customize**: Add additional tools based on your needs

## Development Setup

For development work on the server:

```bash
# Install dev dependencies
uv pip install -e ".[dev]"

# Run tests
pytest

# Format code
black server.py

# Lint
ruff check server.py
```

## Environment Variables Reference

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `SUPABASE_PROJECT_ID` | `wsmhiiharnhqupdniwgw` | No | Supabase project ID |
| `SERVER_PORT` | `8000` | No | HTTP server port |
| `SERVER_TRANSPORT` | `stdio` | No | Transport mode |

## File Permissions

Ensure proper permissions:

```bash
# Make server executable
chmod +x server.py

# Protect .env file
chmod 600 .env

# Set directory permissions
chmod 755 /home/vanman2025/Projects/ai-dev-marketplace/tailwind-ui-mcp
```

## Performance Tips

1. **STDIO Mode**: Faster for local development, lower latency
2. **HTTP Mode**: Better for debugging, can use curl/Postman
3. **Virtual Environment**: Always activate to avoid conflicts
4. **Keep Dependencies Minimal**: Only install what you need

## Security Checklist

- [ ] `.env` file is in `.gitignore`
- [ ] No API keys hardcoded in `server.py`
- [ ] File permissions set correctly
- [ ] Virtual environment activated
- [ ] Dependencies up to date

## Support Resources

- **FastMCP Docs**: https://gofastmcp.com
- **MCP Protocol**: https://modelcontextprotocol.io
- **Supabase Docs**: https://supabase.com/docs
- **Python Docs**: https://docs.python.org/3/

## Common Commands Reference

```bash
# Activate environment
source .venv/bin/activate

# Run server (STDIO)
python server.py

# Run server (HTTP)
python server.py --transport http --port 8000

# Install dependencies
uv pip install -r requirements.txt

# Update FastMCP
uv pip install --upgrade fastmcp

# Deactivate environment
deactivate

# Remove virtual environment
rm -rf .venv
```

---

**Setup complete!** You should now have a working Tailwind UI MCP server ready for tool development.
