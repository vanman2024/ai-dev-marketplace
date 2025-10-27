# Using the Ayrshare MCP Server

## Option 1: Local STDIO Mode (Claude Code CLI)

### Step 1: Add to Claude Code's MCP settings

Edit `~/.config/claude-code/settings.json` or use `/mcp:add`:

```bash
# Add the server
/mcp:add ayrshare
```

Then add this configuration:

```json
{
  "mcpServers": {
    "ayrshare": {
      "command": "python",
      "args": [
        "/home/vanman2025/Projects/ai-dev-marketplace/ayrshare-mcp/src/server.py"
      ],
      "env": {
        "AYRSHARE_API_KEY": "E64245A6-D7BC461C-B10BB820-DDDD6925"
      }
    }
  }
}
```

### Step 2: Restart Claude Code

```bash
# Claude Code will auto-detect and load the MCP server
# Available tools will show in tool list
```

### Step 3: Use the tools

```
You: "Use the ayrshare MCP server to list my connected platforms"

Claude: <uses mcp__ayrshare__list_platforms tool>
```

## Option 2: HTTP Mode (Remote Access)

### Step 1: Start the server in HTTP mode

```bash
cd /home/vanman2025/Projects/ai-dev-marketplace/ayrshare-mcp
python src/server.py --http
# Server runs on http://localhost:8000
```

### Step 2: Connect via MCP Client

```python
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

# For HTTP mode, use HTTP client
import httpx

async def use_remote_mcp():
    async with httpx.AsyncClient() as client:
        # Access MCP tools via HTTP
        response = await client.post(
            "http://localhost:8000/tools/list_platforms"
        )
        print(response.json())
```

### Step 3: Configure for remote agents

Other agents can connect by pointing to your HTTP endpoint:

```json
{
  "mcpServers": {
    "ayrshare-remote": {
      "url": "http://your-server:8000",
      "transport": "http"
    }
  }
}
```

## Option 3: Cloud Deployment (Production)

### Deploy to Railway

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Deploy
railway up

# Get URL
railway domain
# Example: ayrshare-mcp-production.up.railway.app
```

### Connect Remote Agents

```json
{
  "mcpServers": {
    "ayrshare-production": {
      "url": "https://ayrshare-mcp-production.up.railway.app",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer YOUR_API_KEY"
      }
    }
  }
}
```

## Testing the Connection

### Test 1: Verify Server Starts

```bash
python src/server.py
# Should show: "Ayrshare Social Media API MCP server running"
```

### Test 2: Inspect Available Tools

```bash
fastmcp inspect src/server.py
# Shows: 19 tools, 2 resources, 3 prompts
```

### Test 3: Use via Claude Code

Once added to MCP settings:

```
You: "What MCP servers are available?"
Claude: Lists "ayrshare" with 19 tools

You: "Use ayrshare to show my connected social accounts"
Claude: Calls mcp__ayrshare__list_platforms
```

## Available MCP Tools

All 19 tools are prefixed with `mcp__ayrshare__`:

1. `mcp__ayrshare__post_to_social` - Post to platforms
2. `mcp__ayrshare__schedule_post` - Schedule posts
3. `mcp__ayrshare__get_post_analytics` - Get engagement metrics
4. `mcp__ayrshare__delete_post` - Delete posts
5. `mcp__ayrshare__update_post` - Update existing posts
6. `mcp__ayrshare__retry_post` - Retry failed posts
7. `mcp__ayrshare__copy_post` - Duplicate posts
8. `mcp__ayrshare__bulk_post` - Batch operations
9. `mcp__ayrshare__get_social_analytics` - Cross-platform analytics
10. `mcp__ayrshare__get_profile_analytics` - Account metrics
11. `mcp__ayrshare__list_platforms` - Show connected accounts
12. `mcp__ayrshare__upload_media` - Upload to media library
13. `mcp__ayrshare__validate_media_url` - Validate URLs
14. `mcp__ayrshare__get_unsplash_image` - Fetch Unsplash images
15. `mcp__ayrshare__post_with_auto_hashtags` - Auto-generate hashtags
16. `mcp__ayrshare__create_evergreen_post` - Auto-repost content
17. `mcp__ayrshare__post_with_first_comment` - Add automatic comments
18. `mcp__ayrshare__submit_post_for_approval` - Approval workflow
19. `mcp__ayrshare__approve_post` - Approve pending posts

## MCP Resources

- `mcp__ayrshare__history` - Get post history
- `mcp__ayrshare__platforms` - Get connected profiles

## MCP Prompts

- `mcp__ayrshare__optimize_for_platform` - Platform-specific optimization
- `mcp__ayrshare__generate_hashtags` - Generate relevant hashtags
- `mcp__ayrshare__schedule_campaign` - Plan campaign schedule

## Next Steps

1. **Local Development**: Add to Claude Code MCP config
2. **Test Integration**: Try the tools in Claude Code
3. **Deploy**: Choose Railway, Render, or Fly.io
4. **Share Access**: Give remote agents the HTTP endpoint
