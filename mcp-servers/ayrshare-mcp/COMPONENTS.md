# Ayrshare MCP Server - Component Reference

Complete list of all MCP components available in the Ayrshare server.

## 📊 Summary

- **11 MCP Tools** - Executable functions for social media operations
- **2 MCP Resources** - Data access via URI templates
- **3 MCP Prompts** - LLM interaction templates for content optimization

---

## 🛠️ Tools (11)

### Core Posting Operations

#### 1. `post_to_social`
Publish posts to multiple social media platforms immediately.

**Parameters:**
- `post_text` (str): Content to publish
- `platforms` (List[str]): Target platforms
- `media_urls` (Optional[List[str]]): Media attachments
- `shorten_links` (bool): Auto-shorten URLs (default: true)

**Example:**
```json
{
  "post_text": "Check out our new product launch!",
  "platforms": ["facebook", "twitter", "linkedin"],
  "media_urls": ["https://example.com/image.jpg"]
}
```

#### 2. `schedule_post`
Schedule posts for future publication.

**Parameters:**
- `post_text` (str): Content to publish
- `platforms` (List[str]): Target platforms
- `scheduled_date` (str): ISO 8601 datetime (e.g., "2024-12-25T10:00:00Z")
- `media_urls` (Optional[List[str]]): Media attachments
- `shorten_links` (bool): Auto-shorten URLs

**Example:**
```json
{
  "post_text": "Happy Holidays!",
  "platforms": ["facebook", "instagram"],
  "scheduled_date": "2024-12-25T09:00:00Z"
}
```

#### 3. `delete_post`
Remove published posts from platforms.

**Parameters:**
- `post_id` (str): Post ID to delete
- `platforms` (Optional[List[str]]): Specific platforms (or all if omitted)

#### 4. `update_post`
Modify existing scheduled or published posts.

**Parameters:**
- `post_id` (str): Post ID to update
- `post_text` (Optional[str]): New content
- `platforms` (Optional[List[str]]): Platforms to update on

#### 5. `retry_post`
Retry a failed post publication.

**Parameters:**
- `post_id` (str): Post ID to retry

#### 6. `copy_post`
Duplicate an existing post to different platforms or reschedule.

**Parameters:**
- `post_id` (str): Post ID to copy
- `platforms` (List[str]): Target platforms for the copy
- `scheduled_date` (Optional[str]): New schedule time

**Example:**
```json
{
  "post_id": "abc123",
  "platforms": ["linkedin", "pinterest"],
  "scheduled_date": "2024-12-26T15:00:00Z"
}
```

#### 7. `bulk_post`
Create multiple posts in a single operation.

**Parameters:**
- `posts` (List[Dict]): Array of post configurations

**Example:**
```json
{
  "posts": [
    {
      "post": "First post content",
      "platforms": ["facebook", "twitter"]
    },
    {
      "post": "Second post content",
      "platforms": ["linkedin"],
      "scheduleDate": "2024-12-25T12:00:00Z"
    }
  ]
}
```

### Analytics Operations

#### 8. `get_post_analytics`
Get engagement metrics for a specific post.

**Parameters:**
- `post_id` (str): Post ID
- `platforms` (Optional[List[str]]): Specific platforms

**Returns:** Likes, shares, comments, impressions, reach, engagement rate

#### 9. `get_social_analytics`
Get aggregate analytics across multiple platforms.

**Parameters:**
- `platforms` (List[str]): Platforms to analyze

**Returns:** Cross-platform performance trends and comparisons

#### 10. `get_profile_analytics`
Get account-level metrics and demographics.

**Parameters:**
- `platforms` (Optional[List[str]]): Specific platforms (or all)

**Returns:** Follower counts, growth metrics, demographics, audience insights

### Utility Operations

#### 11. `list_platforms`
Get information about all supported social media platforms.

**Returns:**
```json
{
  "status": "success",
  "total_platforms": 13,
  "platforms": {
    "facebook": {
      "name": "Facebook",
      "supports_images": true,
      "supports_videos": true,
      "supports_scheduling": true,
      "max_chars": 63206
    },
    ...
  }
}
```

---

## 📁 Resources (2)

Resources provide read-only access to data via URI patterns.

### 1. `ayrshare://history`
Get recent post history (last 30 days).

**Access:** Read the resource at URI `ayrshare://history`

**Returns:** Markdown-formatted history with post IDs, status, platforms, content previews, and scheduling info.

### 2. `ayrshare://platforms`
Get connected social media profiles and accounts.

**Access:** Read the resource at URI `ayrshare://platforms`

**Returns:** Markdown-formatted list of connected profiles with platform details and connection status.

---

## 💬 Prompts (3)

Prompts are templates for LLM interactions to generate optimized content.

### 1. `optimize_for_platform`
Generate platform-optimized social media content.

**Parameters:**
- `post_content` (str): Original content
- `target_platform` (str): Target platform (facebook, twitter, linkedin, instagram, tiktok)

**Output:** Prompt for LLM to create platform-specific optimized content considering:
- Character limits
- Platform tone and culture
- Hashtag strategies
- Engagement best practices

**Platform Specs Included:**
- Twitter: 280 chars, conversational, 1-2 hashtags
- Facebook: 63206 chars, friendly, minimal hashtags
- LinkedIn: 3000 chars, professional, 3-5 hashtags
- Instagram: 2200 chars, visual-first, 10-30 hashtags
- TikTok: 2200 chars, fun/trendy, 3-5 trending hashtags

### 2. `generate_hashtags`
Generate relevant hashtags for social media posts.

**Parameters:**
- `post_content` (str): Post content
- `target_platforms` (List[str]): Target platforms
- `max_hashtags` (int): Maximum number (default: 5)

**Output:** Prompt for LLM to generate:
- Mix of popular and niche hashtags
- Platform-specific trends
- Industry/topic-specific tags
- Avoids spammy hashtags

### 3. `schedule_campaign`
Generate comprehensive social media campaign schedule.

**Parameters:**
- `campaign_name` (str): Campaign name
- `start_date` (str): Start date (YYYY-MM-DD)
- `end_date` (str): End date (YYYY-MM-DD)
- `post_frequency` (str): Posting frequency (e.g., "daily", "3x per week")
- `platforms` (List[str]): Target platforms
- `campaign_goals` (str): Campaign objectives

**Output:** Prompt for LLM to create detailed schedule with:
- Posting calendar with dates/times
- Content strategy and themes
- Engagement strategy
- Performance tracking metrics

---

## 🌐 Supported Platforms (13)

1. **Facebook** - Full featured posting, analytics, scheduling
2. **Instagram** - Posts, Reels, Stories (business account required)
3. **Twitter/X** - Full support for posts and engagement
4. **LinkedIn** - Professional content and analytics
5. **TikTok** - Video content and trending features
6. **YouTube** - Video uploads and channel management
7. **Pinterest** - Pin creation and board management
8. **Reddit** - Community posts with Markdown support
9. **Snapchat** - Posts and Spotlight content
10. **Telegram** - Channel and group posting
11. **Threads** - Meta's text-based platform
12. **Bluesky** - Decentralized social network
13. **Google Business Profile** - Local business updates (formerly Google My Business)

---

## 🔐 Authentication

The server supports two authentication modes:

### Single User (Premium Plan)
- **API Key only** - Set `AYRSHARE_API_KEY` environment variable
- Use for personal accounts or single organization

### Multi-Tenant (Business/Enterprise Plans)
- **API Key + Profile Key** - Set both `AYRSHARE_API_KEY` and `AYRSHARE_PROFILE_KEY`
- Use for managing multiple users/clients
- Profile Key allows posting on behalf of specific user profiles

---

## 📝 Usage Examples

### Example 1: Post to Multiple Platforms
```python
from fastmcp import Client

async with Client("ayrshare-mcp/src/server.py") as client:
    result = await client.call_tool("post_to_social", {
        "post_text": "Excited to announce our new product!",
        "platforms": ["facebook", "twitter", "linkedin"],
        "media_urls": ["https://example.com/product.jpg"]
    })
    print(result.data)
```

### Example 2: Schedule Campaign
```python
# Get campaign schedule prompt
prompt = await client.get_prompt("schedule_campaign", {
    "campaign_name": "Summer Sale 2024",
    "start_date": "2024-06-01",
    "end_date": "2024-06-30",
    "post_frequency": "daily",
    "platforms": ["facebook", "instagram", "twitter"],
    "campaign_goals": "Increase summer sales by 30%"
})

# Use prompt with LLM to generate schedule
# Then implement schedule using schedule_post tool
```

### Example 3: Optimize Content for Platform
```python
# Generate platform-optimized content
prompt = await client.get_prompt("optimize_for_platform", {
    "post_content": "Our new eco-friendly product line launches next week! Made from 100% recycled materials with zero waste packaging. Join us in making a difference for the planet.",
    "target_platform": "twitter"
})

# LLM generates optimized tweet within 280 chars with hashtags
```

### Example 4: Bulk Post Creation
```python
result = await client.call_tool("bulk_post", {
    "posts": [
        {
            "post": "Monday motivation! Start your week strong 💪",
            "platforms": ["facebook", "instagram"]
        },
        {
            "post": "New blog post: 10 Tips for Social Media Success",
            "platforms": ["linkedin", "twitter"],
            "mediaUrls": ["https://example.com/blog-featured.jpg"]
        },
        {
            "post": "Weekend vibes! What are you up to?",
            "platforms": ["facebook", "threads"],
            "scheduleDate": "2024-12-21T18:00:00Z"
        }
    ]
})
```

### Example 5: Get Analytics
```python
# Post analytics
post_analytics = await client.call_tool("get_post_analytics", {
    "post_id": "abc123",
    "platforms": ["facebook", "twitter"]
})

# Profile analytics
profile_analytics = await client.call_tool("get_profile_analytics", {
    "platforms": ["instagram", "tiktok"]
})

# Social network analytics
social_analytics = await client.call_tool("get_social_analytics", {
    "platforms": ["facebook", "instagram", "linkedin"]
})
```

---

## 🚀 Quick Start

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure API key:**
   ```bash
   cp .env.example .env
   # Edit .env and add your AYRSHARE_API_KEY
   ```

3. **Run server:**
   ```bash
   # STDIO mode (for Claude Desktop)
   python src/server.py

   # HTTP mode (for remote access)
   python src/server.py --http
   ```

4. **Test with FastMCP Inspector:**
   ```bash
   fastmcp dev src/server.py
   ```

---

## 📚 Additional Resources

- **Ayrshare API Docs**: https://www.ayrshare.com/docs
- **FastMCP Docs**: https://gofastmcp.com
- **Get API Key**: https://app.ayrshare.com/api-key
- **Connect Social Accounts**: https://app.ayrshare.com/accounts

---

**Last Updated:** 2025-01-27
**Server Version:** 1.0.0
**FastMCP Version:** 2.13.0
