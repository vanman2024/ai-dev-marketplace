# Ayrshare MCP Server

A production-ready FastMCP server providing **complete Ayrshare API coverage** with **75+ MCP tools** across 15 API categories. Post to 13+ platforms including Facebook, Instagram, Twitter/X, LinkedIn, TikTok, YouTube, Pinterest, Reddit, Snapchat, Telegram, Threads, Bluesky, and Google Business Profile through a unified interface.

**Features**: Multi-user SaaS management, AI content generation, advanced automation, complete media library, brand management, and comprehensive validation tools.

## Features

### Core Publishing
- **Multi-Platform Publishing**: Post to 13+ social networks simultaneously
- **Scheduling**: Schedule posts for future publication with ISO 8601 date format
- **Bulk Operations**: Create multiple posts in a single operation
- **Auto-Hashtags**: Automatic hashtag generation (1-10 hashtags)
- **Evergreen Content**: Auto-reposting for timeless content (1-10 reposts)
- **First Comment**: Automatic first comment on posts
- **Approval Workflows**: Submit posts for approval before publication

### Engagement Management
- **Comments API**: Read, add, reply to, and delete comments on posts
- **Direct Messages**: Send DMs, manage conversations, mark as read (Business Plan)
- **Google Business Reviews**: Get reviews, respond, manage review responses

### Analytics & Insights
- **Post Analytics**: Engagement metrics (likes, shares, comments, impressions)
- **Social Analytics**: Aggregate analytics across multiple platforms
- **Profile Analytics**: Follower counts, demographics, and audience insights
- **Link Analytics**: Track performance of shortened URLs

### Multi-User & SaaS (Business Plan)
- **Profiles API**: Complete multi-user profile management for SaaS platforms
- **Team Management**: Create team profiles with email-based access
- **Profile Filtering**: Filter by connected platforms, tags, and activity
- **OAuth Integration**: User-managed social account linking

### AI-Powered Features (Max Pack)
- **Content Generation**: AI-powered post text creation with tone control
- **Hashtag Generation**: AI-driven hashtag suggestions
- **Image Captions**: Automatic AI caption generation for images

### Automation & Scheduling
- **Auto-Schedule API**: AI-powered optimal posting times
- **Evergreen Content**: Auto-repost for timeless content (1-10 reposts)
- **Scheduled Posts Calendar**: View and manage content calendar
- **Auto-Repost Tracking**: Track series of recurring posts

### Content Discovery & Optimization
- **Hashtag Discovery**: Trending and relevant hashtag suggestions
- **Performance Analytics**: Track hashtag metrics over time
- **Social Feeds**: Retrieve platform-specific content feeds
- **Regional Trends**: Discover trending content by region

### Brand Management
- **Brand Profiles**: Centralized brand identity management
- **Brand Assets**: Store logos, colors, and templates
- **Consistent Branding**: Apply brand guidelines across posts

### Advanced Features
- **Webhooks**: Real-time notifications for post events (Business Plan)
- **Link Shortening**: Custom URL shortening with analytics (Max Pack)
- **Ads Management**: Complete Facebook Ads integration with targeting
- **Media Library**: Complete media asset management with 90-day storage
- **Unsplash Integration**: Access royalty-free images

### Quality Assurance & Validation
- **Pre-Publishing Validation**: Validate posts before publishing
- **Media Verification**: Check media URLs and format compatibility
- **Schedule Validation**: Verify schedule times and timezone handling
- **Error Prevention**: Catch issues before they reach social platforms

### Infrastructure
- **Complete History API**: Track all posts with advanced filtering
- **User Management**: Account settings and API usage limits
- **Timezone Tools**: List and convert between timezones
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

### Core Posting Tools

#### 1. post_to_social
Publish a post immediately to multiple platforms.

```python
{
    "post_text": "Check out our new product launch! 🚀",
    "platforms": ["facebook", "twitter", "linkedin"],
    "media_urls": ["https://example.com/image.jpg"],
    "shorten_links": true
}
```

#### 2. schedule_post
Schedule a post for future publication (ISO 8601 date format).

```python
{
    "post_text": "Happy New Year! 🎉",
    "platforms": ["facebook", "instagram"],
    "scheduled_date": "2025-01-01T00:00:00Z",
    "media_urls": ["https://example.com/celebration.jpg"]
}
```

#### 3. delete_post
Delete a post from specified platforms.

```python
{
    "post_id": "abc123",
    "platforms": ["facebook"]  # Optional: omit to delete from all
}
```

#### 4. update_post
Update content of an existing scheduled or published post.

```python
{
    "post_id": "abc123",
    "post_text": "Updated content",
    "platforms": ["facebook", "twitter"]
}
```

#### 5. retry_post
Retry a failed post (useful after temporary platform issues).

```python
{
    "post_id": "abc123"
}
```

#### 6. copy_post
Copy an existing post to different platforms or reschedule.

```python
{
    "post_id": "abc123",
    "platforms": ["linkedin", "pinterest"],
    "scheduled_date": "2024-12-26T15:00:00Z"  # Optional
}
```

### Advanced Posting Tools

#### 7. bulk_post
Create multiple posts in a single operation.

```python
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

#### 8. post_with_auto_hashtags
Post with automatic hashtag generation (1-10 hashtags).

```python
{
    "post_text": "Excited to announce our new sustainable product line!",
    "platforms": ["twitter", "instagram"],
    "max_hashtags": 3,
    "position": "auto"  # or "end"
}
```

#### 9. create_evergreen_post
Create auto-reposting content (1-10 reposts, minimum 2 days between).

```python
{
    "post_text": "The best time to start is now!",
    "platforms": ["facebook", "twitter"],
    "repeat": 5,
    "days_between": 7,
    "start_date": "2024-12-25T09:00:00Z"  # Optional
}
```

#### 10. post_with_first_comment
Post with automatic first comment (20-90 seconds after post).

```python
{
    "post_text": "New blog post is live!",
    "platforms": ["facebook", "linkedin"],
    "first_comment": "Read more at our website: https://example.com/blog",
    "comment_media_urls": ["https://example.com/blog-preview.jpg"]
}
```

#### 11. submit_post_for_approval
Submit post for approval before publication.

```python
{
    "post_text": "Big announcement coming soon!",
    "platforms": ["facebook", "twitter", "linkedin"],
    "notes": "Please review for compliance",
    "scheduled_date": "2024-12-25T10:00:00Z"
}
```

#### 12. approve_post
Approve a post that is awaiting approval.

```python
{
    "post_id": "abc123"
}
```

### Analytics Tools

#### 13. get_post_analytics
Get engagement metrics for a specific post.

```python
{
    "post_id": "abc123",
    "platforms": ["facebook", "twitter"]
}
```

Returns: Likes, shares, comments, impressions, reach, engagement rate.

#### 14. get_social_analytics
Get aggregate analytics across multiple platforms.

```python
{
    "platforms": ["facebook", "instagram", "twitter"]
}
```

#### 15. get_profile_analytics
Get profile/account analytics including follower counts and demographics.

```python
{
    "platforms": ["facebook", "linkedin"]  # Optional
}
```

### Comments API Tools

#### 16. get_post_comments
Get all comments on a specific post.

```python
{
    "post_id": "abc123",
    "platforms": ["facebook", "instagram"]  # Optional
}
```

#### 17. add_comment_to_post
Add a comment to an existing post.

```python
{
    "post_id": "abc123",
    "comment_text": "Thanks for all the feedback!",
    "platforms": ["facebook", "linkedin"]
}
```

#### 18. reply_to_comment
Reply to a specific comment.

```python
{
    "comment_id": "comment_xyz",
    "reply_text": "Thank you for your support!",
    "platform": "facebook"
}
```

#### 19. delete_post_comment
Delete a comment from a post.

```python
{
    "comment_id": "comment_xyz",
    "platforms": ["facebook"]
}
```

### Direct Messages API Tools (Business Plan Required)

#### 20. send_direct_message
Send a direct message to a user.

```python
{
    "platform": "facebook",
    "recipient_id": "user123",
    "message": "Thank you for reaching out!",
    "media_urls": ["https://example.com/response.jpg"]  # Optional
}
```

#### 21. get_message_conversations
Get list of message conversations.

```python
{
    "platform": "instagram",
    "limit": 50  # Optional
}
```

#### 22. get_conversation_history
Get messages from a specific conversation.

```python
{
    "conversation_id": "conv123",
    "platform": "facebook",
    "limit": 100  # Optional
}
```

#### 23. mark_messages_as_read
Mark messages as read.

```python
{
    "message_ids": ["msg1", "msg2", "msg3"],
    "platform": "instagram"
}
```

### Google Business Reviews API Tools

#### 24. get_google_business_reviews
Get reviews for Google Business Profile locations.

```python
{
    "location_id": "loc123"  # Optional: omit for all locations
}
```

#### 25. respond_to_review
Respond to a Google Business Profile review.

```python
{
    "review_id": "review123",
    "response_text": "Thank you for your feedback!"
}
```

#### 26. remove_review_response
Delete a review response.

```python
{
    "review_id": "review123"
}
```

### Webhooks API Tools (Business Plan Required)

#### 27. setup_webhook_endpoint
Create a webhook subscription for post events.

```python
{
    "url": "https://your-domain.com/webhook",
    "events": ["post.published", "post.failed", "post.scheduled"]
}
```

#### 28. list_webhook_subscriptions
Get all configured webhooks.

```python
{}
```

#### 29. update_webhook_configuration
Update an existing webhook.

```python
{
    "webhook_id": "webhook123",
    "url": "https://new-domain.com/webhook",  # Optional
    "events": ["post.published", "post.analytics"]  # Optional
}
```

#### 30. remove_webhook
Delete a webhook subscription.

```python
{
    "webhook_id": "webhook123"
}
```

### Links API Tools (Max Pack Add-on Required)

#### 31. shorten_url
Shorten a URL with optional custom slug.

```python
{
    "url": "https://example.com/very/long/url/path",
    "custom_slug": "promo2024"  # Optional
}
```

#### 32. get_link_analytics
Get analytics for a shortened link.

```python
{
    "link_id": "link123"
}
```

### Ads API Tools (Business Plan Required)

#### 33. create_ad_from_post
Create a paid ad campaign from an existing post.

```python
{
    "post_id": "abc123",
    "budget": 50.00,
    "duration": 7,  # days
    "targeting": {  # Optional
        "age_range": "25-45",
        "interests": ["technology", "business"]
    }
}
```

#### 34. get_ad_analytics
Get performance analytics for an ad campaign.

```python
{
    "ad_id": "ad123"
}
```

#### 35. manage_ad_campaign
Update ad budget or status.

```python
{
    "ad_id": "ad123",
    "budget": 75.00,  # Optional
    "status": "paused"  # Optional: active, paused
}
```

#### 36. stop_ad_campaign
Stop and delete an ad campaign.

```python
{
    "ad_id": "ad123"
}
```

### Media Management Tools

#### 37. upload_media
Upload media to Ayrshare library for reuse.

```python
{
    "file_url": "https://example.com/product-image.jpg",
    "file_name": "summer-collection-hero.jpg"  # Optional
}
```

#### 38. validate_media_url
Validate a media URL for accessibility and format.

```python
{
    "media_url": "https://example.com/image.jpg"
}
```

#### 39. get_unsplash_image
Get royalty-free image from Unsplash integration.

```python
{
    "query": "sunset beach vacation",  # Search query
    # OR
    "image_id": "HubtZZb2fCM"  # Specific image ID
}
```

### Platform Information

#### 40. list_platforms
Get information about all supported platforms.

```python
{}
```

Returns: Platform capabilities, character limits, and requirements.

---

### Multi-User Profile Management (Business Plan)

#### 41. create_user_profile
Create a new user profile for multi-tenant SaaS applications.

```python
{
    "title": "Client ABC Social Account",
    "messaging_active": true,
    "team": false,
    "disable_social": ["snapchat", "tiktok"],
    "tags": ["client-abc", "premium-tier"]
}
```

#### 42. list_user_profiles
List and filter all user profiles.

```python
{
    "has_active_social_accounts": true,
    "includes_active_social_accounts": ["facebook", "instagram"],
    "action_log": true,
    "limit": 100
}
```

#### 43. get_user_profile_details
Get detailed information about a specific profile.

```python
{
    "profile_key": "PROFILE_KEY_HERE"
}
```

#### 44. update_user_profile
Update profile settings and configuration.

```python
{
    "profile_key": "PROFILE_KEY_HERE",
    "settings": {
        "messaging_active": false,
        "disable_social": ["reddit"]
    }
}
```

#### 45. delete_user_profile
Delete a user profile (irreversible).

```python
{
    "profile_key": "PROFILE_KEY_HERE"
}
```

---

### History & Content Calendar

#### 46. get_post_by_history_id
Get detailed information about a specific historical post.

```python
{
    "history_id": "hist_abc123"
}
```

#### 47. get_all_scheduled_posts
View your content calendar with all scheduled posts.

```python
{}
```

#### 48. get_repost_series
Track an evergreen content auto-repost series.

```python
{
    "auto_repost_id": "repost_xyz789"
}
```

---

### Media Library Management

#### 49. list_all_media
List all media files in your library with pagination.

```python
{
    "limit": 50,
    "cursor": "next_page_token"  # Optional
}
```

#### 50. get_media_item_details
Get detailed information about a specific media file.

```python
{
    "media_id": "media_abc123"
}
```

#### 51. delete_media_file
Remove a media file from your library.

```python
{
    "media_id": "media_abc123"
}
```

---

### Automation & AI Scheduling

#### 52. setup_auto_schedule
Configure AI-powered optimal posting times.

```python
{
    "schedule_config": {
        "timezone": "America/New_York",
        "days": ["monday", "wednesday", "friday"],
        "times_per_day": 2
    }
}
```

#### 53. get_current_auto_schedule
View current auto-schedule configuration.

```python
{}
```

#### 54. modify_auto_schedule
Update auto-schedule settings.

```python
{
    "schedule_config": {
        "times_per_day": 3
    }
}
```

#### 55. remove_auto_schedule
Disable auto-scheduling.

```python
{}
```

---

### Brand Management

#### 56. create_brand_profile_config
Set up centralized brand identity.

```python
{
    "brand_data": {
        "name": "Company Name",
        "colors": ["#FF5733", "#C70039"],
        "logo_url": "https://example.com/logo.png",
        "tone": "professional"
    }
}
```

#### 57. get_brand_profile_assets
Retrieve brand assets and guidelines.

```python
{}
```

#### 58. update_brand_profile_settings
Update brand configuration.

```python
{
    "brand_data": {
        "tone": "casual",
        "tagline": "Innovation at its best"
    }
}
```

---

### Social Feed Retrieval

#### 59. get_platform_feed
Get content feed from a specific platform.

```python
{
    "platform": "instagram",
    "limit": 20
}
```

#### 60. get_all_platform_feeds
Get feeds from all connected platforms.

```python
{
    "limit": 50
}
```

---

### AI Content Generation (Max Pack)

#### 61. ai_generate_post_text
AI-powered post text creation.

```python
{
    "prompt": "Write about our new product launch",
    "platform": "linkedin",
    "tone": "professional"
}
```

#### 62. ai_generate_hashtags_for_content
AI-driven hashtag generation.

```python
{
    "content": "Excited to announce our new sustainable product line!",
    "count": 5
}
```

#### 63. ai_generate_image_caption
Automatic AI caption generation for images.

```python
{
    "image_url": "https://example.com/product.jpg",
    "style": "engaging"
}
```

---

### Hashtag Discovery & Analytics

#### 64. suggest_relevant_hashtags
Get relevant hashtag suggestions for your content.

```python
{
    "content": "Check out our latest tech innovation",
    "platform": "twitter"
}
```

#### 65. get_trending_platform_hashtags
Discover trending hashtags by platform and region.

```python
{
    "platform": "instagram",
    "region": "US"
}
```

#### 66. analyze_hashtag_metrics
Track hashtag performance over time.

```python
{
    "hashtag": "#TechInnovation",
    "time_range": "30days"
}
```

---

### Account Management

#### 67. get_account_information
Get your account details and status.

```python
{}
```

#### 68. update_account_settings
Update account preferences.

```python
{
    "settings": {
        "email_notifications": true,
        "timezone": "America/Los_Angeles"
    }
}
```

#### 69. get_api_usage_limits
Monitor API usage and rate limits.

```python
{}
```

---

### Utility Functions

#### 70. verify_media_accessibility
Pre-check media URL accessibility and format.

```python
{
    "url": "https://example.com/video.mp4"
}
```

#### 71. list_available_timezones
Get list of supported timezones for scheduling.

```python
{}
```

#### 72. convert_time_between_timezones
Convert times between timezones.

```python
{
    "time": "2024-12-25T10:00:00",
    "from_tz": "America/New_York",
    "to_tz": "Europe/London"
}
```

---

### Pre-Publishing Validation

#### 73. validate_post_before_publishing
Validate post parameters before publishing.

```python
{
    "post_data": {
        "post": "Hello world!",
        "platforms": ["facebook", "twitter"],
        "mediaUrls": ["https://example.com/image.jpg"]
    }
}
```

#### 74. validate_media_for_platform
Check media compatibility for specific platforms.

```python
{
    "media_url": "https://example.com/video.mp4",
    "platform": "instagram"
}
```

#### 75. validate_schedule_datetime
Verify schedule time is valid for platforms.

```python
{
    "schedule_date": "2024-12-25T10:00:00Z",
    "platform": "linkedin"
}
```

---

## Available Resources

MCP Resources provide URI-based access to dynamic data that updates automatically. These are especially useful for monitoring, reporting, and real-time data access.

### 1. ayrshare://history

Access recent post history (last 30 days).

**Returns**: Formatted list of posts with status, platforms, and content.

**Use Cases**: Content auditing, compliance tracking, performance review

### 2. ayrshare://platforms

Access connected social media profiles and their connection status.

**Returns**: List of connected platforms with account details and status.

**Use Cases**: Account management, troubleshooting connection issues

### 3. ayrshare://analytics/dashboard/{period}

Real-time analytics dashboard with aggregated metrics across all platforms.

**URI Patterns**:
- `ayrshare://analytics/dashboard/daily` - Last 24 hours
- `ayrshare://analytics/dashboard/weekly` - Last 7 days
- `ayrshare://analytics/dashboard/monthly` - Last 30 days
- `ayrshare://analytics/dashboard/quarterly` - Last 90 days

**Returns**: Comprehensive dashboard with:
- Total posts and success rate
- Platform breakdown
- Posting consistency metrics
- Recent activity summary

**Use Cases**: Performance monitoring, client reporting, strategic planning

**Example**:
```python
# Access monthly dashboard
dashboard = await mcp.read_resource("ayrshare://analytics/dashboard/monthly")
```

### 4. ayrshare://calendar/{year}/{month}

Content calendar view showing all scheduled posts for a specific month.

**URI Patterns**:
- `ayrshare://calendar/2024/12` - December 2024
- `ayrshare://calendar/2025/01` - January 2025

**Returns**: Calendar view with:
- All scheduled posts grouped by date
- Post times and platforms
- Content previews
- Total post count per day

**Use Cases**: Content planning, scheduling visualization, campaign coordination

**Example**:
```python
# View December 2024 calendar
calendar = await mcp.read_resource("ayrshare://calendar/2024/12")
```

### 5. ayrshare://profiles/overview

Overview of all customer profiles for multi-tenant SaaS management.

**Returns**: Comprehensive profile summary with:
- Total active and inactive profiles
- Connected platforms per profile
- Average platforms per customer
- Individual profile details

**Use Cases**: Customer management, SaaS monitoring, account health tracking

**Example**:
```python
# Get all customer profiles
profiles = await mcp.read_resource("ayrshare://profiles/overview")
```

---

## Available Prompts

MCP Prompts provide templated LLM workflows for common social media tasks. These help maintain consistency and quality across content creation.

### 1. create_social_post

Generate platform-optimized social media content with proper formatting, hashtags, and CTAs.

**Parameters**:
- `topic` (required): Main topic or subject of the post
- `platform` (required): Target platform (facebook, twitter, linkedin, instagram, tiktok)
- `tone`: Desired tone (professional, casual, funny, inspiring, educational) - default: "professional"
- `target_audience`: Description of target audience - default: "general"
- `call_to_action`: Optional CTA to include
- `include_hashtags`: Whether to include hashtags - default: true

**Supported Platforms**:
- **Twitter**: 280 chars, 1-2 hashtags, punchy style
- **Facebook**: Story-driven, minimal hashtags, engaging questions
- **LinkedIn**: Professional, 3-5 hashtags, thought leadership
- **Instagram**: Visual-first, 10-30 hashtags, emoji support
- **TikTok**: Authentic, 3-5 trending hashtags, attention-grabbing

**Returns**: Complete prompt for LLM to generate ready-to-publish content

**Example Usage**:
```python
# Generate LinkedIn post about AI
prompt = create_social_post(
    topic="The future of AI in business",
    platform="linkedin",
    tone="professional",
    target_audience="business executives",
    call_to_action="Read our full report",
    include_hashtags=True
)
```

### 2. analyze_performance

Analyze social media performance data and provide strategic insights and recommendations.

**Parameters**:
- `post_analytics` (required): JSON or text with analytics data
- `time_period`: Time period covered - default: "last 30 days"
- `platform`: Specific platform or "all platforms" - default: "all platforms"

**Analysis Includes**:
1. **Performance Overview**: Key metrics, best/worst content, benchmarks
2. **Trends & Patterns**: Content types, posting times, platform effectiveness
3. **Audience Insights**: Engagement patterns, demographics, topic resonance
4. **Actionable Recommendations**: Specific improvement strategies
5. **Next Steps**: Priority actions with expected impact

**Returns**: Structured prompt for comprehensive performance analysis

**Example Usage**:
```python
# Analyze monthly performance
analytics_data = """
{
  "total_posts": 45,
  "engagement_rate": 3.2%,
  "reach": 125000,
  "top_platform": "linkedin"
}
"""

prompt = analyze_performance(
    post_analytics=analytics_data,
    time_period="last 30 days",
    platform="all platforms"
)
```

### 3. optimize_for_platform *(Existing)*

Optimize existing post content for specific platforms considering character limits and best practices.

### 4. generate_hashtags *(Existing)*

Generate relevant, platform-appropriate hashtags for post content.

### 5. schedule_campaign *(Existing)*

Plan and schedule multi-post campaigns across platforms.

---

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

Recently implemented:

- [x] Bulk post operations
- [x] Advanced scheduling (recurring posts, evergreen content)
- [x] Webhook support for post status updates
- [x] Media library management
- [x] Comments API (read, add, reply, delete)
- [x] Direct Messages API (send, read, manage conversations)
- [x] Google Business Reviews API (read, respond, manage)
- [x] Links API (URL shortening and analytics)
- [x] Ads API (create, manage, analyze campaigns)
- [x] Auto-hashtag generation
- [x] First comment automation
- [x] Approval workflows

Future enhancements planned:

- [ ] Post templates and content library
- [ ] A/B testing support
- [ ] Enhanced analytics with charts
- [ ] RSS feed integration
- [ ] Content calendar view
- [ ] Social listening and monitoring
- [ ] Competitor analysis tools

---

**Built with FastMCP** - A modern framework for building Model Context Protocol servers.
