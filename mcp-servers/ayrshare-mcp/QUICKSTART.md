# Ayrshare MCP Server - Quick Start Guide

## 1. Installation (2 minutes)

```bash
# Navigate to project directory
cd ayrshare-mcp

# Install dependencies
pip install -r requirements.txt

# OR using uv (faster)
uv pip install -r requirements.txt
```

## 2. Configuration (1 minute)

```bash
# Copy environment template
cp .env.example .env

# Edit .env and add your API key
# AYRSHARE_API_KEY=your_actual_key_here
```

Get your API key from: https://app.ayrshare.com/api-key

## 3. Connect Social Accounts (3 minutes)

Visit https://app.ayrshare.com/accounts and connect your social media platforms:

- Facebook
- Instagram (requires business account)
- Twitter/X
- LinkedIn
- TikTok
- YouTube
- Pinterest
- Reddit
- Snapchat
- Telegram
- Threads
- Bluesky
- Google Business Profile

## 4. Test the Server (1 minute)

```bash
# Test import
python -c "import sys; sys.path.insert(0, 'src'); from server import mcp; print('Server loaded:', mcp.name)"

# Run server in STDIO mode (for Claude Desktop)
python src/server.py

# OR run as HTTP server
python src/server.py --http
```

## 5. Test with FastMCP Dev Mode

```bash
# Interactive testing interface
fastmcp dev src/server.py
```

This opens a web interface where you can:
- Test all 5 tools
- Access the 2 resources
- View tool schemas
- Make real API calls

## 6. Use with Claude Desktop

Add to `~/.config/Claude/claude_desktop_config.json` (macOS/Linux) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "ayrshare": {
      "command": "python",
      "args": ["/absolute/path/to/ayrshare-mcp/src/server.py"],
      "env": {
        "AYRSHARE_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

Restart Claude Desktop.

## Example Usage in Claude

Once configured, you can ask Claude:

> "Post 'Hello from Claude!' to Facebook and Twitter"

> "Schedule a post for tomorrow at 9am saying 'Good morning!'"

> "Show me my recent post analytics"

> "What social media platforms are supported?"

> "Show my post history"

## Testing Individual Tools

### 1. List Platforms
```python
list_platforms()
# Returns: All 13 supported platforms with capabilities
```

### 2. Post Immediately
```python
post_to_social(
    post_text="Testing Ayrshare MCP integration!",
    platforms=["twitter"],
    shorten_links=True
)
# Returns: post_id, status, warnings
```

### 3. Schedule Post
```python
schedule_post(
    post_text="Scheduled post test",
    platforms=["facebook", "twitter"],
    scheduled_date="2024-12-31T23:59:00Z"
)
# Returns: post_id, scheduled_for, platforms
```

### 4. Get Analytics
```python
get_post_analytics(
    post_id="abc123",
    platforms=["facebook"]
)
# Returns: likes, shares, comments, impressions, reach
```

### 5. Delete Post
```python
delete_post(
    post_id="abc123",
    platforms=["twitter"]
)
# Returns: deletion status
```

## Troubleshooting

### "API key required" Error
- Check `.env` file exists and contains `AYRSHARE_API_KEY`
- Verify key is correct in Ayrshare dashboard
- Make sure `.env` is in project root

### "Platform not connected" Error
- Go to https://app.ayrshare.com/accounts
- Connect the social media account
- Wait for status to show "Active"

### Import Errors
- Ensure all dependencies installed: `pip install -r requirements.txt`
- Check Python version: `python --version` (must be 3.10+)

### Server Won't Start
- Check for syntax errors: `python -m py_compile src/server.py`
- Verify FastMCP installed: `pip show fastmcp`

## Next Steps

1. **Add More Tools**: Extend server with additional Ayrshare endpoints
2. **Add Authentication**: Implement OAuth for multi-user scenarios
3. **Deploy to Cloud**: Use FastMCP Cloud for remote access
4. **Add Monitoring**: Track usage and errors
5. **Create Tests**: Write pytest tests for reliability

## Resources

- [Ayrshare API Docs](https://docs.ayrshare.com/)
- [FastMCP Documentation](https://github.com/jlowin/fastmcp)
- [Full README](./README.md)
