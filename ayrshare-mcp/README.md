# Ayrshare MCP Server

A production-ready FastMCP server that provides social media posting capabilities through the Ayrshare API. Post to 13+ platforms including Facebook, Instagram, Twitter/X, LinkedIn, TikTok, YouTube, Pinterest, Reddit, Snapchat, Telegram, Threads, Bluesky, and Google Business Profile through a unified interface.

## Features

- **Multi-Platform Publishing**: Post to 13+ social networks simultaneously
- **Scheduling**: Schedule posts for future publication
- **Analytics**: Get engagement metrics (likes, shares, comments, impressions)
- **Media Support**: Attach images and videos to posts
- **History Tracking**: View recent post history across all platforms
- **Profile Management**: Manage multiple social media profiles
- **Link Shortening**: Automatic URL shortening
- **Error Handling**: Comprehensive error handling and validation

## Supported Platforms

| Platform | Images | Videos | Scheduling | Notes |
|----------|--------|--------|------------|-------|
| Facebook | ✅ | ✅ | ✅ | Up to 63,206 characters |
| Instagram | ✅ | ✅ | ✅ | Business account required |
| Twitter/X | ✅ | ✅ | ✅ | 280 character limit |
| LinkedIn | ✅ | ✅ | ✅ | Up to 3,000 characters |
| TikTok | ❌ | ✅ | ✅ | Videos only |
| YouTube | ❌ | ✅ | ✅ | Video uploads |
| Pinterest | ✅ | ✅ | ✅ | - |
| Reddit | ✅ | ✅ | ✅ | - |
| Snapchat | ✅ | ✅ | ✅ | - |
| Telegram | ✅ | ✅ | ✅ | - |
| Threads | ✅ | ✅ | ✅ | 500 character limit |
| Bluesky | ✅ | ❌ | ✅ | 300 character limit |
| Google Business Profile | ✅ | ✅ | ✅ | Formerly Google My Business |

## Prerequisites

- Python 3.10 or higher
- [Ayrshare API account](https://www.ayrshare.com/) (free tier available)
- API key from [Ayrshare dashboard](https://app.ayrshare.com/api-key)
- Social media accounts connected through Ayrshare

## Installation

### Option 1: Using uv (Recommended)

```bash
# Clone or navigate to the project directory
cd ayrshare-mcp

# Create virtual environment
uv venv

# Activate virtual environment
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
uv pip install -e .
```

### Option 2: Using pip

```bash
# Clone or navigate to the project directory
cd ayrshare-mcp

# Create virtual environment
python -m venv .venv

# Activate virtual environment
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -e .
```

## Configuration

1. **Copy environment template**:
   ```bash
   cp .env.example .env
   ```

2. **Get your Ayrshare API key**:
   - Sign up at [ayrshare.com](https://www.ayrshare.com/)
   - Navigate to [API Key page](https://app.ayrshare.com/api-key)
   - Copy your API key

3. **Add API key to .env**:
   ```bash
   AYRSHARE_API_KEY=your_actual_api_key_here
   ```

4. **Optional: Add Profile Key** (for multi-tenant scenarios):
   ```bash
   AYRSHARE_PROFILE_KEY=your_profile_key_here
   ```

5. **Connect social media accounts**:
   - Go to [Ayrshare dashboard](https://app.ayrshare.com/)
   - Click "Connect Account" for each platform you want to use
   - Follow the OAuth flow to authorize each platform

## Usage

### Running Locally (STDIO Mode)

For use with Claude Desktop or other MCP clients:

```bash
fastmcp run src/server.py
```

Or using Python directly:

```bash
python src/server.py
```

### Running as HTTP Server

For remote access or API integration:

```bash
python src/server.py --http
```

The server will start on `http://localhost:8000` by default.

### Testing the Server

You can test the server using FastMCP's dev mode:

```bash
fastmcp dev src/server.py
```

This opens an interactive interface to test all tools and resources.

## Available Tools

### 1. post_to_social

Publish a post immediately to multiple platforms.

```python
{
    "post_text": "Check out our new product launch! 🚀",
    "platforms": ["facebook", "twitter", "linkedin"],
    "media_urls": ["https://example.com/image.jpg"],
    "shorten_links": true
}
```

**Returns**:
```json
{
    "status": "success",
    "post_id": "abc123",
    "post_status": "published",
    "ref_id": "ref_xyz",
    "errors": null,
    "warnings": null
}
```

### 2. schedule_post

Schedule a post for future publication.

```python
{
    "post_text": "Happy New Year! 🎉",
    "platforms": ["facebook", "instagram"],
    "scheduled_date": "2025-01-01T00:00:00Z",
    "media_urls": ["https://example.com/celebration.jpg"]
}
```

**Date Format**: ISO 8601 (e.g., `2025-12-25T10:00:00Z` or `2025-12-25T10:00:00-05:00`)

### 3. get_post_analytics

Get engagement metrics for a post.

```python
{
    "post_id": "abc123",
    "platforms": ["facebook", "twitter"]
}
```

**Returns**: Likes, shares, comments, impressions, reach, and engagement rate.

### 4. delete_post

Delete a post from specified platforms.

```python
{
    "post_id": "abc123",
    "platforms": ["facebook"]  # Optional: omit to delete from all
}
```

### 5. list_platforms

Get information about all supported platforms.

```python
{}
```

**Returns**: Platform capabilities, character limits, and requirements.

## Available Resources

### ayrshare://history

Access recent post history (last 30 days).

**Returns**: Formatted list of posts with status, platforms, and content.

### ayrshare://platforms

Access connected social media profiles.

**Returns**: List of connected platforms and their status.

## Claude Desktop Integration

Add to your Claude Desktop configuration (`claude_desktop_config.json`):

### STDIO Mode (Recommended)

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

### HTTP Mode

```json
{
  "mcpServers": {
    "ayrshare": {
      "url": "http://localhost:8000",
      "transport": "http"
    }
  }
}
```

## Examples

### Post to Multiple Platforms

```python
# Immediate post
result = await post_to_social(
    post_text="Excited to announce our new feature! Learn more at example.com",
    platforms=["facebook", "twitter", "linkedin"],
    media_urls=["https://cdn.example.com/feature-image.jpg"]
)

print(f"Posted with ID: {result['post_id']}")
```

### Schedule Future Post

```python
# Schedule for Christmas morning
result = await schedule_post(
    post_text="Merry Christmas from our team! 🎄",
    platforms=["facebook", "instagram", "twitter"],
    scheduled_date="2024-12-25T09:00:00Z",
    media_urls=["https://cdn.example.com/holiday.jpg"]
)

print(f"Scheduled for: {result['scheduled_for']}")
```

### Get Analytics

```python
# Check post performance
analytics = await get_post_analytics(
    post_id="abc123"
)

print(f"Analytics: {analytics['analytics']}")
```

### View Post History

```python
# Access as resource
history = await mcp.get_resource("ayrshare://history")
print(history)
```

## Error Handling

The server provides detailed error messages for common issues:

- **Authentication Errors**: Invalid API key or missing credentials
- **Validation Errors**: Invalid platforms, malformed dates, missing required fields
- **API Errors**: Rate limits, platform-specific errors, network issues

All tools return a `status` field (`"success"` or `"error"`) and a `message` field for errors.

## Development

### Project Structure

```
ayrshare-mcp/
├── src/
│   ├── server.py           # FastMCP server with tools and resources
│   └── ayrshare_client.py  # Async Ayrshare API client wrapper
├── pyproject.toml          # Project dependencies and metadata
├── .env.example            # Environment variable template
├── .gitignore              # Git ignore patterns
└── README.md               # This file
```

### Running Tests

```bash
# Install dev dependencies
pip install -e ".[dev]"

# Run tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html
```

### Code Quality

```bash
# Format code
black src/

# Lint code
ruff check src/
```

## Security Best Practices

- **Never commit `.env` files**: API keys should only be in `.env` (gitignored)
- **Use environment variables**: Always load credentials from environment
- **Rotate API keys regularly**: Generate new keys periodically
- **Monitor usage**: Check Ayrshare dashboard for unusual activity
- **Use profile keys**: For multi-tenant scenarios, use separate profile keys

## Troubleshooting

### "Invalid API key" Error

- Verify API key in Ayrshare dashboard
- Check that key is correctly set in `.env` file
- Ensure `.env` file is in the project root directory

### "Platform not connected" Error

- Go to [Ayrshare dashboard](https://app.ayrshare.com/)
- Connect the social media account
- Verify connection status shows "Active"

### Scheduled Posts Not Publishing

- Check scheduled date is in the future
- Verify timezone (use UTC or include timezone offset)
- Confirm platform supports scheduling

### Media Upload Failures

- Ensure URLs are publicly accessible
- Check file size limits (varies by platform)
- Verify media format is supported by target platform

## API Rate Limits

Ayrshare enforces rate limits based on your plan:

- **Free Tier**: 5 posts per month
- **Starter Plan**: 50 posts per month
- **Professional Plan**: 500 posts per month
- **Business Plan**: Custom limits

Monitor your usage in the [Ayrshare dashboard](https://app.ayrshare.com/).

## Resources

- [Ayrshare Website](https://www.ayrshare.com/)
- [Ayrshare API Documentation](https://docs.ayrshare.com/)
- [FastMCP Documentation](https://github.com/jlowin/fastmcp)
- [Get API Key](https://app.ayrshare.com/api-key)
- [Connect Social Accounts](https://app.ayrshare.com/accounts)

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## Support

For issues and questions:

- **MCP Server Issues**: Open an issue in this repository
- **Ayrshare API Issues**: Contact [Ayrshare support](https://www.ayrshare.com/contact)
- **General Questions**: Check the [Ayrshare documentation](https://docs.ayrshare.com/)

## Roadmap

Future enhancements planned:

- [ ] Bulk post operations
- [ ] Post templates and content library
- [ ] Advanced scheduling (recurring posts)
- [ ] A/B testing support
- [ ] Enhanced analytics with charts
- [ ] Webhook support for post status updates
- [ ] Media library management
- [ ] RSS feed integration
- [ ] Content calendar view

---

**Built with FastMCP** - A modern framework for building Model Context Protocol servers.
