# Ayrshare Social Media API - Comprehensive Documentation

**Status**: Documentation extracted January 2025  
**Source**: https://www.ayrshare.com/docs  
**Purpose**: Integrate unified social media posting API into AI Marketing Automation System

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Core Features](#core-features)
3. [Supported Platforms](#supported-platforms)
4. [API Architecture](#api-architecture)
5. [Authentication](#authentication)
6. [Post API](#post-api)
7. [Analytics API](#analytics-api)
8. [Messages API](#messages-api)
9. [Ads API](#ads-api)
10. [MCP Server](#mcp-server)
11. [Pricing & Plans](#pricing--plans)
12. [Integration Patterns](#integration-patterns)
13. [Use Cases for Marketing Automation](#use-cases-for-marketing-automation)
14. [Important Links](#important-links)

---

## Overview

### What is Ayrshare?

**Ayrshare is a unified API that lets you manage your users' social media presence across all major platforms with a single integration.**

Instead of dealing with 13 different social media APIs, you use just one:
- **Single API call** posts to multiple platforms simultaneously
- **One authentication system** for all networks
- **Unified response format** across all platforms
- **Consistent error handling** and retry logic

### Key Value Proposition

```
Traditional Approach:
❌ 13 different APIs to learn
❌ 13 different authentication systems
❌ 13 different rate limits to manage
❌ 13 different error formats
❌ Weeks/months of integration work

Ayrshare Approach:
✅ 1 API to learn
✅ 1 authentication system
✅ 1 rate limit to manage
✅ 1 consistent error format
✅ Hours of integration work
```

---

## Core Features

### Key Functionality

1. **13 social networks supported** - Comprehensive coverage
2. **Secure API access** - Using unique API Key
3. **Scheduled posting** - Schedule posts across all platforms
4. **Automated posting** - Based on predefined schedules
5. **Rich media support** - Images, videos, Reels, Stories, Spotlight
6. **Delete posts** - Remove posts from linked social networks
7. **Comprehensive analytics** - Likes, shares, engagement metrics
8. **Account metrics** - Follower count, demographic data
9. **Comment management** - View, add, delete post comments
10. **Link shortening** - Optional for all or specific URLs
11. **Unsplash integration** - Add specific images or random by keywords
12. **Auto hashtag generation** - Using relevant keywords
13. **Post history tracking** - Including non-Ayrshare posts
14. **Review management** - Retrieve, reply to, delete review responses
15. **RSS feed integration** - Automated content posting
16. **Media library** - Upload and store photos/videos
17. **Social Post Verification** - Keep accounts safe

### Business Plan Features (For Multiple Users)

1. **User account linking** - Enable users to link their own social accounts
2. **OAuth single sign-on** - Quick account linking
3. **Profile management** - Create and remove user profiles via API
4. **Advanced analytics** - Enhanced user analytics
5. **Webhook support** - Real-time updates
6. **Direct messages** - Management across platforms
7. **Facebook ads** - Create ads from existing posts

---

## Supported Platforms

Ayrshare currently supports **13 major social networks**:

| Platform | Posting | Analytics | Comments | Messages | Ads | Stories/Reels |
|----------|---------|-----------|----------|----------|-----|---------------|
| **Bluesky** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Facebook** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Google Business Profile** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Instagram** | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| **LinkedIn** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Pinterest** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Reddit** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Snapchat** | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Telegram** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Threads** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **TikTok** | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| **X (Twitter)** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **YouTube** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

### Platform-Specific Features

- **Facebook**: Posts, Stories, Ads, Messages, Comments, Analytics
- **Instagram**: Posts, Reels, Stories, Messages, Comments, Analytics
- **LinkedIn**: Posts, Comments, Analytics (no Stories)
- **TikTok**: Posts, Comments, Analytics (public visibility required for comments)
- **X (Twitter)**: Posts, Messages, Comments, Analytics
- **YouTube**: Video uploads, Comments, Analytics
- **Reddit**: Posts with Markdown formatting, Comments, Analytics
- **Threads**: Posts, Comments, Analytics
- **Bluesky**: Posts, Comments, Analytics
- **Pinterest**: Pins, Comments, Analytics
- **Telegram**: Posts, Analytics
- **Snapchat**: Posts, Spotlight, Analytics
- **Google Business**: Posts, Comments, Reviews, Analytics

---

## API Architecture

### Base URL

```
https://api.ayrshare.com/api
```

All endpoints use this base URL.

### Request Format

- **Method**: GET, POST, PUT, PATCH, DELETE
- **Content-Type**: `application/json`
- **Data Format**: JSON for request and response

### Response Format

All API responses are in JSON format:

```json
{
  "status": "success",
  "id": "eIT96IYEodNuzU4oMmwG",
  "refId": "9abf1426d6ce9122ef11c72bd",
  "postIds": {
    "facebook": "123456789_987654321",
    "twitter": "1234567890123456789",
    "linkedin": "urn:li:share:1234567890"
  }
}
```

### Compression Support

Ayrshare supports compression for all API requests:

```bash
Accept-Encoding: "deflate, gzip, br"
```

**Compression Details**:
- Only responses over 1024 bytes (1KB) are compressed
- Compression order: Brotli (br) first, then gzip, then deflate
- Brotli is the most efficient compression algorithm
- Response header contains content encoding used: `content-encoding: br`

**Recommended for**:
- `/history` endpoint (large responses)
- Any endpoint with extensive data

---

## Authentication

### API Key Authentication

**Format**: Bearer token in HTTP header

```bash
Authorization: Bearer API_KEY
```

**Where to find**:
- Ayrshare Dashboard → Primary Profile → API Key page

**Example** (if API Key is `2MPXPKQ-S03M5LS-GR5RX5G-AZCK8EA`):

```bash
curl -H "Authorization: Bearer 2MPXPKQ-S03M5LS-GR5RX5G-AZCK8EA" \
     -H "Content-Type: application/json" \
     -X GET https://api.ayrshare.com/api
```

### Profile Key (Business/Enterprise Only)

For managing multiple users/clients:

```bash
Authorization: Bearer API_KEY
Profile-Key: PROFILE_KEY
```

**Example**:
```bash
curl -H "Authorization: Bearer 2MPXPKQ-S03M5LS-GR5RX5G-AZCK8EA" \
     -H "Profile-Key: AX1XGG-9jK3M5LS-GR5RX5G-LLCK8EA" \
     -H "Content-Type: application/json" \
     -X GET https://api.ayrshare.com/api
```

**Important**:
- Profile Key is used to interact on behalf of a User Profile
- API Key is ALWAYS required in the header
- Missing API Key or using Profile Key in place of API Key = ERROR
- Business or Enterprise plan required

### Authentication Headers Summary

```javascript
// Premium Plan (single user)
const headers = {
  'Authorization': `Bearer ${API_KEY}`,
  'Content-Type': 'application/json'
};

// Business/Enterprise Plan (multiple users)
const headers = {
  'Authorization': `Bearer ${API_KEY}`,
  'Profile-Key': `${PROFILE_KEY}`,
  'Content-Type': 'application/json'
};
```

---

## Post API

### Overview

The Post API allows you to publish posts to 13 social networks with extensive customization options.

**Endpoint**: `POST /post`

### Basic Post Example

```json
{
  "post": "Hello, world! 🚀",
  "platforms": ["facebook", "twitter", "instagram", "linkedin"],
  "mediaUrls": ["https://example.com/image.jpg"],
  "scheduleDate": "2025-12-01T10:00:00Z"
}
```

### Post API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/post` | POST | Publish a post |
| `/post` | GET | Get a post |
| `/post` | DELETE | Delete a post |
| `/post` | PATCH | Update a post |
| `/post` | PUT | Retry a post |
| `/post/copy` | POST | Copy a post |
| `/post/bulk` | PUT | Bulk post |

### Advanced Post Features

#### 1. **Scheduled Posts**

Schedule posts for future publication:

```json
{
  "post": "Hello, world!",
  "mediaUrls": ["https://img.ayrshare.com/012/gb.jpg"],
  "platforms": ["facebook", "instagram"],
  "scheduleDate": "2023-07-08T12:30:00Z"
}
```

**Date Format**: ISO-8601 UTC (`YYYY-MM-DDThh:mm:ssZ`)  
**Example**: `2026-07-08T12:30:00Z`

**Important Notes**:
- If `scheduleDate` is in the past, post publishes immediately
- Media must be available at scheduled publication time
- Check status via Webhook, GET call, or Dashboard

**Error Handling Differences**:
- **Immediate Posts**: If one platform fails validation, others continue processing
- **Scheduled Posts**: All platforms must pass initial validation before scheduling
  - If any platform fails pre-validation, entire scheduling operation rejected
  - Platform-specific errors at posting time reported individually

#### 2. **Auto Hashtags**

Automatically add relevant hashtags to posts:

```json
{
  "post": "Check out our new product!",
  "platforms": ["twitter", "instagram"],
  "autoHashtag": {
    "max": 3,          // Integer 1-10, default 2
    "position": "auto" // "auto" or "end"
  }
}
```

Or simplified:
```json
{
  "autoHashtag": true
}
```

**Requires**: Paid plan

#### 3. **Auto Repost** (Evergreen Content)

Automatically repost content multiple times:

```json
{
  "post": "The most important things are the hardest to say - Stephen King",
  "platforms": ["twitter", "facebook"],
  "autoRepost": {
    "repeat": 3,                        // Min 1, Max 10
    "days": 5,                          // Min 2 days between reposts
    "startDate": "2021-07-08T12:30:00Z" // Optional
  }
}
```

**Response includes**:
- All future scheduled reposts
- `autoRepostId` for tracking the series
- Individual post IDs for each repost

**Important**:
- Cannot be used with top-level `scheduleDate`
- Use `startDate` parameter instead
- Follow social network posting frequency guidelines

#### 4. **First Comment**

Automatically add first comment immediately after publishing:

```json
{
  "post": "Check out our new product launch! 🚀",
  "platforms": ["facebook", "linkedin", "twitter"],
  "firstComment": {
    "comment": "My first comment",     // Required
    "mediaUrls": ["https://..."]       // Facebook, LinkedIn, Twitter only
  }
}
```

**Processing Time**:
- **Most networks**: ~20 second delay
- **TikTok**: Up to 90 second delay
- **TikTok Note**: Visibility must be set to `public` for first comments

**Why the delay?**
1. Original post must be fully published
2. Then comment is added to published post

#### 5. **Approval Workflow**

For posts requiring approval before publication:

```json
{
  "post": "Pending approval post",
  "platforms": ["facebook", "linkedin"],
  "requiresApproval": true,
  "notes": "need approval by John Smith" // Optional
}
```

**Workflow**:
1. Post with `requiresApproval: true`
2. Status becomes "awaiting approval"
3. Approve with PATCH operation: `{ "approved": true }`
4. Post publishes at scheduled time (or immediately if past)

**Warning**: If `scheduleDate` is in the past, post publishes immediately upon approval.

#### 6. **Multi-Platform Posts and Media**

Customize content for each platform:

```json
{
  "post": {
    "instagram": "Great IG pic!",
    "facebook": "Great FB pic!",
    "default": "Great default pic!"
  },
  "platforms": ["instagram", "facebook", "linkedin"],
  "mediaUrls": {
    "instagram": "https://img.ayrshare.com/012/gb.jpg",
    "linkedin": "https://img.ayrshare.com/012/gb.jpg",
    "default": "https://img.ayrshare.com/012/gb.jpg"
  }
}
```

**Result**:
- Instagram: Specific text + specific image
- Facebook: Specific text + default image
- LinkedIn: Default text + specific image

**Note**: For multiple images to different platforms, create separate posts.

#### 7. **Idempotent Posts**

Prevent duplicate posts from accidental retries:

```json
{
  "post": "Hello, world!",
  "platforms": ["twitter"],
  "idempotencyKey": "Unique Key"
}
```

**How it works**:
- Idempotency key must be unique per User Profile
- If same key is reused (regardless of post state), error returned
- Helps prevent duplicate posts from retry failures

**Important**: API must process request first to store key. Simultaneous requests with same key may not be caught.

#### 8. **Rich Text Posts**

Add formatting to posts:

```json
{
  "post": "<var>Hello</var>, how about a little <b>bold text</b> and <i>italics text</i> and an x<sub>2</sub>?",
  "platforms": ["twitter"]
}
```

**HTML Elements**:
- `<b>` or `<strong>`: **Bold text**
- `<i>` or `<em>`: *Italic text*
- `<var>`: 𝓕𝓪𝓷𝓬𝔂 text
- `<samp>`: 𝟷𝟸𝟹 (monospace numbers)
- `<sub>`: Subscript (x₂)
- `<sup>`: Superscript (x²)

**Supported networks**: Twitter, Facebook, LinkedIn, Telegram, Instagram  
**Reddit**: Use Reddit-flavored Markdown instead

#### 9. **Line Breaks**

For line breaks in posts:

```json
{
  "post": "This is a new\u2063\nline.",
  "platforms": ["twitter"]
}
```

**Format**: `\u2063\n` (invisible line break + newline)

**Note**: Some social networks don't support line breaks.

#### 10. **Shorten Links**

Automatically shorten URLs in posts:

```json
{
  "post": "Hello, world with a link https://www.ayrshare.com",
  "platforms": ["linkedin"],
  "shortenLinks": true
}
```

**Requires**: Max Pack add-on

#### 11. **Unsplash Images**

Integrate Unsplash images directly:

```json
{
  "post": "Hello, world!",
  "platforms": ["instagram"],
  "unsplash": "random"                  // Random image
  // OR
  "unsplash": "money"                   // Search-based image
  // OR
  "unsplash": ["HubtZZb2fCM"]          // Specific image ID
}
```

### Media Requirements

#### Image & Video Guidelines

**Valid URL Requirements**:
- URL must directly access media
- Test URL in browser first
- No redirect URLs (e.g., DropBox web app URLs)
- Ayrshare auto-converts Google Drive and Dropbox share URLs

**Important**:
- Media verification via `HEAD` request
- Hosting provider must not block `HEAD` requests (403 error)

#### Spaces & Special Characters

**Avoid**:
- Spaces in URL
- URL encoded spaces (`%20`)
- Special characters (even if URL encoded, like é)

**Bad Example**:
```
https://img.ayrshare.com/012/test .webp
```

#### Sanitize File Names & URLs

```javascript
// Sanitize file name
const sanitizeFileName = (url) => url.replace(/[^a-z0-9\/\.]/gi, "_");
sanitizeFileName("tést .webp"); // t_st_.webp

// Sanitize URL
const sanitizeUrl = (url) => {
  const [protocol, rest] = url.split("://");
  const [domain, ...path] = rest.split("/");
  const sanitizedPath = path.join("/").replace(/[^a-z0-9\/\.]/gi, "_");
  return `${protocol}://${domain}/${sanitizedPath}`;
};
sanitizeUrl("https://img.ayrshare.com/012/tést .webp");
// Output: https://img.ayrshare.com/012/t_st_.webp
```

#### Video Extension

If URL doesn't end in known video extension (`.mp4`):

```json
{
  "mediaUrls": ["https://example.com/video?id=123"],
  "isVideo": true
}
```

**Recommendation**: Use explicit video extensions (`.mp4`, `.mov`) for higher success rate.

#### Image or Video Only

Post media without text:

```json
{
  "post": "",
  "mediaUrls": ["https://example.com/image.jpg"],
  "platforms": ["facebook", "instagram"]
}
```

**Supported networks**: Facebook, Instagram, LinkedIn, Threads, TikTok, X/Twitter

#### Download Speed

- Test media hosting performance at [pingdom](https://tools.pingdom.com/)
- Recommended: **B rating minimum**
- Fast download speed crucial for posting success

#### Additional Information

- If self-hosting, ensure external access without special permissions
- For signed URLs (S3), set expiration to at least 7 days
- Test media URLs with Ayrshare's verify media tools

### ID Types

#### 1. Ayrshare Post ID

Generated by Ayrshare, returned in `id` field:
- Use for analytics across networks
- Add comments
- Delete post
- **Most commonly used ID**

#### 2. Social Post ID

Each social network's own unique ID, returned in `postIds` field:
- Use for platform-specific operations
- Retrieve data with analytics social post ID endpoint

#### 3. Ayrshare Comment ID

Generated by Ayrshare for comments, returned in `id` field:
- Get analytics on comment
- Add replies
- Delete comment

#### 4. Social Comment ID

Each network's own comment ID, returned in `commentId` field:
- Get details on comments published outside Ayrshare

### Error Codes

Ayrshare uses standard HTTP status codes:
- **200**: Success
- **400**: Bad Request
- **401**: Unauthorized
- **403**: Forbidden
- **404**: Not Found
- **429**: Too Many Requests
- **500**: Internal Server Error

**See Documentation**:
- HTTP Status Codes
- Ayrshare-specific Error Codes

---

## Analytics API

### Overview

Get comprehensive analytics for posts, accounts, and engagement metrics.

**Endpoints**:
- `/analytics/post` - Post analytics by Ayrshare ID
- `/analytics/social` - Post analytics by social network ID
- `/analytics/profile` - Account metrics (followers, demographics)

### Example Request

```json
POST /analytics/post
{
  "id": "eIT96IYEodNuzU4oMmwG",
  "platforms": ["facebook", "twitter"]
}
```

### Analytics Data Includes

- **Engagement**: Likes, shares, comments, reactions
- **Reach**: Impressions, views, clicks
- **Audience**: Follower count, demographics
- **Performance**: Best posting times, top content

---

## Messages API

### Overview

Unified messaging API for Facebook, Instagram, and X (Twitter):

**Capabilities**:
- Send text, image, and video messages
- Retrieve complete conversation histories
- Set up automated message responses
- Real-time updates via webhooks

**Supported Platforms**: Facebook, Instagram, X (Twitter)

**Requires**: Business Plan

### Example

```json
POST /messages/send
{
  "platform": "facebook",
  "recipientId": "123456789",
  "message": "Hello! Thanks for your interest.",
  "mediaUrls": ["https://example.com/image.jpg"]
}
```

### Webhook Actions

- Message received
- Message reactions
- Read receipts

---

## Ads API

### Overview

Create Facebook ads from existing posts.

**Features**:
- Boost posts to reach more people
- Manage ads and track performance
- Analyze ad spend and optimize campaigns

**Requires**: Business Plan

### Example

```json
POST /ads/create
{
  "postId": "eIT96IYEodNuzU4oMmwG",
  "budget": 100,
  "duration": 7
}
```

---

## MCP Server

### Status

⚠️ **DEPRECATED - New version coming soon**

### What is the MCP Server?

- **Model Context Protocol**: Open standard for sharing context with LLMs
- **Purpose**: Connect Ayrshare API docs to AI tools (Cursor, Claude Desktop)
- **Capabilities**:
  - Search through Ayrshare's API documentation
  - Understand available endpoints and parameters
  - Generate code that uses Ayrshare's APIs correctly
  - Provide contextually accurate suggestions

### Installation

```bash
npx mint-mcp add ayrshare
```

**Requires**: Node.js

### Integration

- Cursor
- Claude Desktop

### Example Usage

"How do you publish a post in Ayrshare. Use the MCP server."

### Limitations

⚠️ **Current MCP server only provides DOCUMENTATION SEARCH, not direct API integration**

**What it does**:
- ✅ Search API documentation
- ✅ Understand endpoints and parameters
- ✅ Generate code examples

**What it doesn't do**:
- ❌ Make actual API calls
- ❌ Post to social media directly
- ❌ Manage authentication

### Recommendation for Marketing Automation

**Option 1**: Build custom MCP server for direct API integration
- Define tools: `post_to_social`, `get_analytics`, `manage_comments`
- Direct API calls with authentication
- Full control over functionality

**Option 2**: Use REST API directly
- Standard HTTP requests
- Full API access
- No MCP server dependency

**Option 3**: Wait for new MCP server
- "Coming soon" per Ayrshare documentation
- Unknown timeline
- Unknown capabilities

---

## Pricing & Plans

### Plan Tiers

| Plan | Monthly Posts | Users | Price Range | Key Features |
|------|---------------|-------|-------------|--------------|
| **Free** | Limited | 1 | $0 | Basic posting |
| **Basic** | Higher limit | 1 | ~$20-50/mo | Scheduling, analytics |
| **Premium** | High limit | 1 | ~$50-100/mo | Advanced features |
| **Business** | Very high | Multiple | ~$100-300/mo | Multiple users, webhooks |
| **Enterprise** | Unlimited | Unlimited | Custom | Custom features, support |

**Note**: Visit [Ayrshare Pricing](https://www.ayrshare.com/pricing/) for current pricing.

### Feature Requirements

| Feature | Plan Required |
|---------|---------------|
| Basic posting | All plans |
| Scheduled posts | Basic+ |
| Analytics | Basic+ |
| Auto hashtags | Paid plans |
| Auto repost | Paid plans |
| Link shortening | Max Pack add-on |
| Multiple users | Business+ |
| Webhooks | Business+ |
| Direct messages | Business+ |
| Ads creation | Business+ |

### Max Pack Add-On

**Additional capabilities**:
- AI-powered content generation
- Enhanced analytics
- Expanded platform support
- Link shortening
- Additional features

---

## Integration Patterns

### Node.js Example

```javascript
const fetch = require('node-fetch');

const API_KEY = 'YOUR_API_KEY';
const BASE_URL = 'https://api.ayrshare.com/api';

async function publishPost(postData) {
  const response = await fetch(`${BASE_URL}/post`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(postData)
  });
  
  return await response.json();
}

// Usage
const post = {
  post: "Hello, world! 🚀",
  platforms: ["facebook", "twitter", "instagram"],
  mediaUrls: ["https://example.com/image.jpg"]
};

publishPost(post).then(console.log);
```

### Python Example

```python
import requests

API_KEY = 'YOUR_API_KEY'
BASE_URL = 'https://api.ayrshare.com/api'

def publish_post(post_data):
    headers = {
        'Authorization': f'Bearer {API_KEY}',
        'Content-Type': 'application/json'
    }
    
    response = requests.post(
        f'{BASE_URL}/post',
        headers=headers,
        json=post_data
    )
    
    return response.json()

# Usage
post = {
    "post": "Hello, world! 🚀",
    "platforms": ["facebook", "twitter", "instagram"],
    "mediaUrls": ["https://example.com/image.jpg"]
}

print(publish_post(post))
```

### Using Compression

```javascript
const fetch = require('node-fetch');

async function publishPostWithCompression(postData) {
  const response = await fetch(`${BASE_URL}/post`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
      'Accept-Encoding': 'deflate, gzip, br'
    },
    body: JSON.stringify(postData)
  });
  
  return await response.json();
}
```

---

## Use Cases for Marketing Automation

### 1. **Content Distribution**

**Scenario**: AI generates 120 social posts for product launch

```javascript
async function distributeContent(posts, platforms) {
  const results = [];
  
  for (const post of posts) {
    const result = await publishPost({
      post: post.text,
      platforms: platforms,
      mediaUrls: post.images,
      scheduleDate: post.scheduledTime
    });
    
    results.push(result);
  }
  
  return results;
}
```

### 2. **Scheduled Campaign**

**Scenario**: Schedule 90-day content calendar

```javascript
async function scheduleContentCalendar(calendar) {
  const schedules = [];
  
  for (const day of calendar) {
    for (const post of day.posts) {
      const result = await publishPost({
        post: post.content,
        platforms: post.platforms,
        mediaUrls: post.media,
        scheduleDate: post.date,
        autoHashtag: true
      });
      
      schedules.push(result);
    }
  }
  
  return schedules;
}
```

### 3. **Multi-Platform Video Distribution**

**Scenario**: Post video to all platforms supporting video

```javascript
async function distributeVideo(videoUrl, caption) {
  const videoPlatforms = [
    "facebook", "instagram", "tiktok", 
    "youtube", "twitter", "linkedin"
  ];
  
  return await publishPost({
    post: caption,
    platforms: videoPlatforms,
    mediaUrls: [videoUrl],
    isVideo: true
  });
}
```

### 4. **Platform-Specific Content**

**Scenario**: Customize content for each platform

```javascript
async function publishPlatformOptimized(content) {
  return await publishPost({
    post: {
      "instagram": content.instagram.text,
      "facebook": content.facebook.text,
      "twitter": content.twitter.text,
      "default": content.default.text
    },
    platforms: ["instagram", "facebook", "twitter", "linkedin"],
    mediaUrls: {
      "instagram": content.instagram.image,
      "facebook": content.facebook.image,
      "default": content.default.image
    }
  });
}
```

### 5. **Evergreen Content Rotation**

**Scenario**: Repost top-performing content

```javascript
async function createEvergreenPost(content) {
  return await publishPost({
    post: content.text,
    platforms: content.platforms,
    mediaUrls: content.images,
    autoRepost: {
      repeat: 4,      // Repost 4 times
      days: 30,       // Every 30 days
      startDate: content.startDate
    }
  });
}
```

### 6. **Engagement Monitoring**

**Scenario**: Track analytics for all posts

```javascript
async function getPostAnalytics(postId) {
  const response = await fetch(`${BASE_URL}/analytics/post`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      id: postId,
      platforms: ["facebook", "twitter", "instagram"]
    })
  });
  
  return await response.json();
}
```

### 7. **Automated Response System**

**Scenario**: Auto-reply to comments (requires Business Plan)

```javascript
async function autoReplyToComments(postId, replyTemplate) {
  // Get comments
  const comments = await getComments(postId);
  
  // Reply to each
  for (const comment of comments) {
    await replyToComment(comment.id, replyTemplate);
  }
}
```

---

## Important Links

### Official Documentation

1. **Main Documentation**: https://www.ayrshare.com/docs/introduction
2. **API Overview**: https://www.ayrshare.com/docs/apis/overview
3. **Quick Start Guide**: https://www.ayrshare.com/docs/quickstart

### API Endpoints Documentation

1. **Post API**: https://www.ayrshare.com/docs/apis/post/overview
   - POST Publish: https://www.ayrshare.com/docs/apis/post/post
   - GET Post: https://www.ayrshare.com/docs/apis/post/get-post
   - DELETE Post: https://www.ayrshare.com/docs/apis/post/delete-post
   - PATCH Update: https://www.ayrshare.com/docs/apis/post/update-post
   - PUT Retry: https://www.ayrshare.com/docs/apis/post/retry-post
   - POST Copy: https://www.ayrshare.com/docs/apis/post/copy-post
   - PUT Bulk: https://www.ayrshare.com/docs/apis/post/bulk-post

2. **Analytics API**: https://www.ayrshare.com/docs/apis/analytics/overview
3. **Messages API**: https://www.ayrshare.com/docs/apis/messages/overview
4. **Ads API**: https://www.ayrshare.com/docs/apis/ads/overview
5. **Comments API**: https://www.ayrshare.com/docs/apis/comments/overview
6. **Profiles API**: https://www.ayrshare.com/docs/apis/profiles/overview
7. **History API**: https://www.ayrshare.com/docs/apis/history/overview
8. **Media API**: https://www.ayrshare.com/docs/apis/media/overview
9. **Links API**: https://www.ayrshare.com/docs/apis/links/overview
10. **Webhooks API**: https://www.ayrshare.com/docs/apis/webhooks/overview

### Business Features

1. **Business Plan Overview**: https://www.ayrshare.com/docs/multiple-users/business-plan-overview
2. **User Integration**: https://www.ayrshare.com/docs/multiple-users/user-integration
3. **API Integration for Business**: https://www.ayrshare.com/docs/multiple-users/api-integration-business
4. **Manage User Profiles**: https://www.ayrshare.com/docs/multiple-users/manage-user-profiles

### Additional Resources

1. **MCP Server**: https://www.ayrshare.com/docs/additional/mcp-server (⚠️ Deprecated)
2. **Max Pack**: https://www.ayrshare.com/docs/additional/maxpack
3. **Media Guidelines**: https://www.ayrshare.com/docs/media-guidelines
4. **Error Codes**: 
   - HTTP Status: https://www.ayrshare.com/docs/errors/errors-http
   - Ayrshare Errors: https://www.ayrshare.com/docs/errors/errors-ayrshare
5. **Testing & Verification**: https://www.ayrshare.com/docs/testing/overview
6. **Postman Guide**: https://www.ayrshare.com/docs/testing/postman

### Packages & Guides

1. **Node.js Package**: https://www.ayrshare.com/docs/packages-guides/nodejs
2. **Python Package**: https://www.ayrshare.com/docs/packages-guides/python
3. **Bubble.io Guide**: https://www.ayrshare.com/docs/packages-guides/bubble
4. **Airtable Guide**: https://www.ayrshare.com/docs/packages-guides/airtable
5. **Make Guide**: https://www.ayrshare.com/docs/packages-guides/make
6. **Notion Guide**: https://www.ayrshare.com/docs/packages-guides/notion
7. **FlutterFlow Guide**: https://www.ayrshare.com/docs/packages-guides/flutterflow
8. **Retool Guide**: https://www.ayrshare.com/docs/packages-guides/retool

### Dashboard & Community

1. **Ayrshare Dashboard**: https://app.ayrshare.com
2. **Blog**: https://www.ayrshare.com/blog
3. **GitHub**: https://github.com/ayrshare
4. **Social API Demo (Node.js)**: https://github.com/ayrshare/social-api-demo
5. **YouTube Channel**: https://www.youtube.com/@ayrshare

### Pricing & Plans

1. **Pricing Page**: https://www.ayrshare.com/pricing/
2. **Business Plan Details**: https://www.ayrshare.com/business-plan-for-multiple-users/

---

## Integration Strategy for Marketing Automation

### Architecture

```
AI Marketing Automation System
│
├── Foundation (AI Tech Stack 1)
│   ├── Next.js 15
│   ├── Vercel AI SDK
│   ├── Supabase
│   ├── Mem0
│   └── FastMCP
│
└── Extensions (5% Domain-Specific)
    ├── google-imagen (Image generation)
    ├── google-veo (Video generation)
    └── ayrshare (Social media posting) ⭐ NEW
```

### Plugin Structure: `ayrshare`

```
.multiagent/plugins/ayrshare/
├── commands/
│   ├── init.md              # Initialize Ayrshare API
│   ├── post.md              # Publish posts
│   ├── schedule.md          # Schedule posts
│   ├── analytics.md         # Get analytics
│   ├── messages.md          # Manage messages
│   └── bulk.md              # Bulk operations
├── skills/
│   ├── social-media-best-practices/
│   │   ├── platform-optimization.md
│   │   ├── posting-times.md
│   │   └── content-strategies.md
│   └── error-handling/
│       ├── retry-logic.md
│       └── validation.md
├── docs/
│   ├── overview.md
│   ├── pricing.md
│   ├── api-reference.md
│   └── examples/
│       ├── basic-post.md
│       ├── scheduled-campaign.md
│       └── multi-platform.md
└── .mcp.json                # Point to custom or native MCP server
```

### Custom MCP Server Tools

If building custom MCP server:

```json
{
  "tools": [
    {
      "name": "post_to_social",
      "description": "Publish post to multiple social media platforms",
      "inputSchema": {
        "type": "object",
        "properties": {
          "post": { "type": "string" },
          "platforms": { "type": "array" },
          "mediaUrls": { "type": "array" },
          "scheduleDate": { "type": "string" }
        }
      }
    },
    {
      "name": "schedule_campaign",
      "description": "Schedule multiple posts across platforms",
      "inputSchema": {
        "type": "object",
        "properties": {
          "posts": { "type": "array" },
          "calendar": { "type": "object" }
        }
      }
    },
    {
      "name": "get_post_analytics",
      "description": "Get analytics for published posts",
      "inputSchema": {
        "type": "object",
        "properties": {
          "postId": { "type": "string" },
          "platforms": { "type": "array" }
        }
      }
    },
    {
      "name": "manage_comments",
      "description": "View, add, or delete comments on posts",
      "inputSchema": {
        "type": "object",
        "properties": {
          "action": { "enum": ["view", "add", "delete"] },
          "postId": { "type": "string" },
          "comment": { "type": "string" }
        }
      }
    }
  ]
}
```

### Cost Estimate (Updated)

**Original Marketing Automation Cost**: $43.82 per product launch

**With Ayrshare Integration**:
- Basic Plan (~$25/month for up to 100 posts/month)
- Or pay-per-post pricing (varies by volume)

**Estimated Additional Cost**: $0.20-0.50 per post (120 posts = $24-60)

**New Total**: **$67.82 - $103.82 per complete product launch**

**Still incredible ROI**: $103.82 → $50k-$500k (485× - 4,850× ROI)

---

## Summary

### Why Ayrshare for Marketing Automation?

1. **Single Integration**: Replace 13 different APIs with one
2. **Unified Response**: Consistent format across all platforms
3. **Comprehensive Coverage**: 13 major social networks
4. **Advanced Features**: Scheduling, analytics, auto-hashtags, evergreen content
5. **Business Features**: Multiple users, webhooks, messages, ads
6. **Time Savings**: Hours vs weeks/months of integration work
7. **Cost Effective**: $0.20-0.50 per post vs building 13 integrations
8. **Reliability**: Handles platform-specific requirements automatically

### Critical Missing Piece Solved

**Before Ayrshare**:
- ✅ AI generates 120 social posts ($7.20)
- ✅ AI generates 25 images ($1.50)
- ✅ AI generates 2 videos ($8.00)
- ❌ **No way to actually POST to social media**

**After Ayrshare**:
- ✅ AI generates 120 social posts ($7.20)
- ✅ AI generates 25 images ($1.50)
- ✅ AI generates 2 videos ($8.00)
- ✅ **Ayrshare posts to 13 platforms ($24-60)** ⭐

### Complete Marketing Automation Stack

```
Foundation (90-95%): AI Tech Stack 1
├── Next.js 15
├── Vercel AI SDK
├── Supabase
├── Mem0
└── FastMCP

Extensions (5-10%): Domain-Specific
├── google-imagen (☕ Image generation)
├── google-veo (🎬 Video generation)
└── ayrshare (📱 Social posting)
```

**Total Cost**: $67.82 - $103.82 per complete product launch  
**ROI for Recruitment Business**: 485× - 4,850× (better than marketing automation alone!)

---

**Documentation Version**: 1.0  
**Last Updated**: January 2025  
**Maintained By**: AI Dev Marketplace Team  
**For**: AI Marketing Automation System Integration
