# Complete Usage Guide: Ayrshare MCP Server

## Part 1: Loading into Claude Code (This Session)

### Step 1: Configure the MCP Server

The `.mcp.json` file has been created in this project:

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
# Exit current session
exit

# Restart Claude Code
claude-code
```

### Step 3: Verify MCP Server is Loaded

Once restarted, you'll see new tools available with the prefix `mcp__ayrshare__`:

```
Available tools:
  - mcp__ayrshare__post_to_social
  - mcp__ayrshare__schedule_post
  - mcp__ayrshare__list_platforms
  ... (19 total tools)
```

### Step 4: Use the MCP Tools

**Example 1: List Connected Platforms**

```
User: "Use the ayrshare MCP to show my connected social media accounts"

Claude: <invokes mcp__ayrshare__list_platforms>

Result:
✓ Connected Platforms: 4
  - facebook: Challange Red Seal Exams Canada
  - gmb: Skilled Trades Job Hub
  - linkedin: Ryan Angel (ryan-angel)
  - youtube: Ryan Angel
```

**Example 2: Post to Social Media**

```
User: "Post 'Hello from MCP!' to my Facebook and LinkedIn"

Claude: <invokes mcp__ayrshare__post_to_social with:
  post_text: "Hello from MCP!"
  platforms: ["facebook", "linkedin"]
>

Result:
✓ Post published successfully
  Post ID: post_xyz123
  Facebook: Published
  LinkedIn: Published
```

**Example 3: Get Analytics**

```
User: "Get analytics for post post_xyz123"

Claude: <invokes mcp__ayrshare__get_post_analytics with:
  post_id: "post_xyz123"
>

Result:
📊 Post Analytics:
  Likes: 42
  Comments: 8
  Shares: 5
  Impressions: 1,250
```

## Part 2: HTTP Mode for Remote Agents

### Start Server in HTTP Mode

```bash
cd /home/vanman2025/Projects/ai-dev-marketplace/ayrshare-mcp
python src/server.py --http

# Output:
# ✓ Server running on http://localhost:8000
# ✓ Health check: http://localhost:8000/health
```

### Configure Another Agent to Connect

In another Claude Code instance or agent:

```json
{
  "mcpServers": {
    "ayrshare-remote": {
      "url": "http://localhost:8000",
      "transport": "http"
    }
  }
}
```

### Remote Agent Usage

```
Remote Agent: "Connect to the ayrshare MCP at localhost:8000"
Remote Agent: "Use it to list my social media platforms"

<calls http://localhost:8000/tools/list_platforms>

Result: Same as above
```

## Part 3: Production Deployment

### Deploy to Railway

```bash
# From the ayrshare-mcp directory
railway login
railway init
railway up

# Get the URL
railway domain
# Returns: https://ayrshare-mcp-production.up.railway.app
```

### Global MCP Configuration

Add to `~/.config/claude-code/settings.json`:

```json
{
  "mcpServers": {
    "ayrshare-production": {
      "url": "https://ayrshare-mcp-production.up.railway.app",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer E64245A6-D7BC461C-B10BB820-DDDD6925"
      }
    }
  }
}
```

### Now ANY Agent Can Use It

```
Any Claude Code Agent Anywhere:
"Use the ayrshare-production MCP to post to my social media"

<calls https://ayrshare-mcp-production.up.railway.app/tools/post_to_social>
```

## Real-World Examples

### Example 1: Automated Social Media Campaign

```
User: "Schedule a week-long campaign promoting our new product"

Claude uses:
1. mcp__ayrshare__generate_hashtags("new product launch")
2. mcp__ayrshare__optimize_for_platform(content, "facebook")
3. mcp__ayrshare__optimize_for_platform(content, "linkedin")
4. mcp__ayrshare__schedule_post(monday_content, "2025-11-01T09:00:00Z")
5. mcp__ayrshare__schedule_post(wednesday_content, "2025-11-03T09:00:00Z")
6. mcp__ayrshare__schedule_post(friday_content, "2025-11-05T09:00:00Z")
```

### Example 2: Batch Content Upload

```
User: "Take these 10 blog posts and create social media posts for each"

Claude uses:
1. Read blog posts
2. Generate summaries
3. mcp__ayrshare__bulk_post([...10 posts with optimized content...])
```

### Example 3: Analytics Dashboard

```
User: "Show me performance across all my platforms this month"

Claude uses:
1. mcp__ayrshare__list_platforms() → get all connected accounts
2. mcp__ayrshare__get_social_analytics(["facebook", "linkedin", "youtube"])
3. mcp__ayrshare__get_profile_analytics("facebook")
4. Creates comparison table
```

## Tool Reference

### All 19 Available Tools

| Tool | Purpose | Example Usage |
|------|---------|---------------|
| `post_to_social` | Instant multi-platform posting | Post announcement now |
| `schedule_post` | Schedule future posts | Schedule for Monday 9am |
| `update_post` | Edit published posts | Fix typo in yesterday's post |
| `delete_post` | Remove posts | Delete that accidental post |
| `retry_post` | Retry failed posts | Retry the failed Instagram post |
| `copy_post` | Duplicate posts | Copy successful post to other accounts |
| `bulk_post` | Batch operations | Post 10 prepared messages |
| `get_post_analytics` | Single post metrics | How did my launch post perform? |
| `get_social_analytics` | Cross-platform analytics | Compare Facebook vs LinkedIn |
| `get_profile_analytics` | Account-level metrics | Overall Facebook performance |
| `list_platforms` | Show connected accounts | What's connected? |
| `upload_media` | Upload images/videos | Upload product photo |
| `validate_media_url` | Check URL validity | Is this image URL valid? |
| `get_unsplash_image` | Fetch stock photos | Get "business meeting" image |
| `post_with_auto_hashtags` | AI-generated hashtags | Post with smart hashtags |
| `create_evergreen_post` | Auto-repost content | Repost tips weekly |
| `post_with_first_comment` | Add automatic comment | Pin important link in comments |
| `submit_post_for_approval` | Approval workflow | Submit for manager approval |
| `approve_post` | Approve pending post | Approve pending announcement |

### 2 MCP Resources

| Resource | Purpose | Access Pattern |
|----------|---------|----------------|
| `ayrshare://history` | Get post history | Read recent posts |
| `ayrshare://platforms` | Get connected profiles | List all accounts |

### 3 MCP Prompts

| Prompt | Purpose | Input |
|--------|---------|-------|
| `optimize_for_platform` | Platform-specific optimization | content + target platform |
| `generate_hashtags` | Relevant hashtag generation | content + platforms |
| `schedule_campaign` | Campaign planning | theme + platforms + duration |

## Verification

After restart, verify the MCP is loaded:

```bash
# Check tools are available
claude-code --list-tools | grep ayrshare

# Should show:
# mcp__ayrshare__post_to_social
# mcp__ayrshare__schedule_post
# ... (19 total)
```

## Troubleshooting

### MCP Server Not Loading

```bash
# Check server can start
python src/server.py
# Should show: "Ayrshare Social Media API MCP server running"

# Check .mcp.json syntax
jq . .mcp.json

# Restart Claude Code
exit && claude-code
```

### Tools Not Available

```bash
# Verify configuration
cat .mcp.json

# Check environment variable
echo $AYRSHARE_API_KEY

# Test API key directly
python -c "
from dotenv import load_dotenv
import os
load_dotenv()
print(f'API Key: {os.getenv(\"AYRSHARE_API_KEY\")[:8]}...')
"
```

### API Errors

```bash
# Test live API connection
pytest tests/test_live_api.py -v

# Should pass all 3 tests:
# ✓ test_api_key_valid
# ✓ test_post_endpoint_format
# ✓ test_user_endpoint
```

## Next Steps

1. **Restart Claude Code** to load the MCP server
2. **Try a simple command**: "List my connected platforms"
3. **Test posting**: "Post a test message to LinkedIn only"
4. **Deploy to production**: Use Railway for persistent HTTP access
5. **Share with team**: Give them the HTTP endpoint URL
