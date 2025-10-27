"""
Ayrshare MCP Server

FastMCP server providing social media posting capabilities through Ayrshare API.
Supports posting to 13+ platforms including Facebook, Instagram, Twitter/X, LinkedIn,
TikTok, YouTube, Pinterest, Reddit, Snapchat, Telegram, Threads, Bluesky, and Google Business Profile.
"""

import os
from typing import List, Optional, Dict, Any
from datetime import datetime

from dotenv import load_dotenv
from fastmcp import FastMCP

try:
    from src.ayrshare_client import AyrshareClient, AyrshareError
except ImportError:
    from ayrshare_client import AyrshareClient, AyrshareError

# Load environment variables
load_dotenv()

# Initialize FastMCP server
mcp = FastMCP("Ayrshare Social Media API")

# Client will be initialized lazily
_client: Optional[AyrshareClient] = None


def get_client() -> AyrshareClient:
    """Get or create the Ayrshare client instance"""
    global _client
    if _client is None:
        _client = AyrshareClient()
    return _client


# Supported platforms
SUPPORTED_PLATFORMS = [
    "facebook",
    "instagram",
    "twitter",  # Also accepts "x"
    "linkedin",
    "tiktok",
    "youtube",
    "pinterest",
    "reddit",
    "snapchat",
    "telegram",
    "threads",
    "bluesky",
    "gmb",  # Google My Business / Google Business Profile
]


@mcp.tool()
async def post_to_social(
    post_text: str,
    platforms: List[str],
    media_urls: Optional[List[str]] = None,
    shorten_links: bool = True,
) -> Dict[str, Any]:
    """
    Publish a post to multiple social media platforms immediately

    Args:
        post_text: The content of the post to publish (text, can include URLs)
        platforms: List of platform names to post to. Supported: facebook, instagram,
                  twitter (or x), linkedin, tiktok, youtube, pinterest, reddit,
                  snapchat, telegram, threads, bluesky, gmb
        media_urls: Optional list of image or video URLs to attach to the post
        shorten_links: Whether to automatically shorten URLs in the post (default: True)

    Returns:
        Dictionary with post ID, status, and any errors or warnings

    Example:
        post_to_social(
            post_text="Check out our new product launch!",
            platforms=["facebook", "twitter", "linkedin"],
            media_urls=["https://example.com/image.jpg"]
        )
    """
    try:
        # Validate platforms
        invalid_platforms = [p for p in platforms if p.lower() not in SUPPORTED_PLATFORMS and p.lower() != "x"]
        if invalid_platforms:
            return {
                "status": "error",
                "message": f"Invalid platforms: {', '.join(invalid_platforms)}",
                "supported_platforms": SUPPORTED_PLATFORMS,
            }

        # Create post
        client = get_client()
        response = await client.post(
            post_text=post_text,
            platforms=platforms,
            media_urls=media_urls,
            shorten_links=shorten_links,
        )

        return {
            "status": "success",
            "post_id": response.id,
            "post_status": response.status,
            "ref_id": response.refId,
            "errors": response.errors,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def schedule_post(
    post_text: str,
    platforms: List[str],
    scheduled_date: str,
    media_urls: Optional[List[str]] = None,
    shorten_links: bool = True,
) -> Dict[str, Any]:
    """
    Schedule a post to be published at a future date/time

    Args:
        post_text: The content of the post to publish
        platforms: List of platform names to post to
        scheduled_date: ISO 8601 datetime string for when to publish
                       (e.g., "2024-12-25T10:00:00Z" or "2024-12-25T10:00:00-05:00")
        media_urls: Optional list of image or video URLs to attach
        shorten_links: Whether to automatically shorten URLs (default: True)

    Returns:
        Dictionary with scheduled post ID, status, and scheduling details

    Example:
        schedule_post(
            post_text="Happy Holidays from our team!",
            platforms=["facebook", "instagram"],
            scheduled_date="2024-12-25T09:00:00Z"
        )
    """
    try:
        # Validate datetime format
        try:
            datetime.fromisoformat(scheduled_date.replace("Z", "+00:00"))
        except ValueError:
            return {
                "status": "error",
                "message": "Invalid date format. Use ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ",
            }

        # Create scheduled post
        client = get_client()
        response = await client.post(
            post_text=post_text,
            platforms=platforms,
            media_urls=media_urls,
            scheduled_date=scheduled_date,
            shorten_links=shorten_links,
        )

        return {
            "status": "success",
            "post_id": response.id,
            "scheduled_for": scheduled_date,
            "platforms": platforms,
            "post_status": response.status,
            "ref_id": response.refId,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_post_analytics(
    post_id: str,
    platforms: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Get engagement analytics for a specific post

    Retrieves metrics like likes, shares, comments, impressions, reach, and engagement rate
    for posts on connected social media platforms.

    Args:
        post_id: The unique post ID returned when the post was created
        platforms: Optional list of specific platforms to get analytics from.
                  If not specified, gets analytics from all platforms the post was published to.

    Returns:
        Dictionary containing analytics data with platform-specific metrics

    Example:
        get_post_analytics(
            post_id="abc123",
            platforms=["facebook", "twitter"]
        )
    """
    try:
        client = get_client()
        analytics = await client.get_analytics_post(
            post_id=post_id,
            platforms=platforms,
        )

        return {
            "status": "success",
            "post_id": post_id,
            "analytics": analytics.data,
            "platforms": platforms or "all",
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def delete_post(
    post_id: str,
    platforms: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Delete a published post from social media platforms

    Args:
        post_id: The unique post ID to delete
        platforms: Optional list of specific platforms to delete from.
                  If not specified, deletes from all platforms the post was published to.

    Returns:
        Dictionary with deletion status

    Example:
        delete_post(
            post_id="abc123",
            platforms=["facebook", "twitter"]
        )
    """
    try:
        client = get_client()
        result = await client.delete_post(
            post_id=post_id,
            platforms=platforms,
        )

        return {
            "status": "success",
            "post_id": post_id,
            "deleted_from": platforms or "all platforms",
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def list_platforms() -> Dict[str, Any]:
    """
    Get information about supported social media platforms

    Returns a list of all social media platforms supported by Ayrshare,
    along with their capabilities and requirements.

    Returns:
        Dictionary containing list of supported platforms with details

    Example:
        list_platforms()
    """
    platform_info = {
        "facebook": {
            "name": "Facebook",
            "supports_images": True,
            "supports_videos": True,
            "supports_scheduling": True,
            "max_chars": 63206,
        },
        "instagram": {
            "name": "Instagram",
            "supports_images": True,
            "supports_videos": True,
            "supports_scheduling": True,
            "max_chars": 2200,
            "notes": "Requires business account",
        },
        "twitter": {
            "name": "Twitter/X",
            "supports_images": True,
            "supports_videos": True,
            "supports_scheduling": True,
            "max_chars": 280,
            "alternatives": ["x"],
        },
        "linkedin": {
            "name": "LinkedIn",
            "supports_images": True,
            "supports_videos": True,
            "supports_scheduling": True,
            "max_chars": 3000,
        },
        "tiktok": {
            "name": "TikTok",
            "supports_images": False,
            "supports_videos": True,
            "supports_scheduling": True,
            "notes": "Videos only",
        },
        "youtube": {
            "name": "YouTube",
            "supports_images": False,
            "supports_videos": True,
            "supports_scheduling": True,
            "notes": "Video uploads only",
        },
        "pinterest": {
            "name": "Pinterest",
            "supports_images": True,
            "supports_videos": True,
            "supports_scheduling": True,
        },
        "reddit": {
            "name": "Reddit",
            "supports_images": True,
            "supports_videos": True,
            "supports_scheduling": True,
        },
        "snapchat": {
            "name": "Snapchat",
            "supports_images": True,
            "supports_videos": True,
            "supports_scheduling": True,
        },
        "telegram": {
            "name": "Telegram",
            "supports_images": True,
            "supports_videos": True,
            "supports_scheduling": True,
        },
        "threads": {
            "name": "Threads",
            "supports_images": True,
            "supports_videos": True,
            "supports_scheduling": True,
            "max_chars": 500,
        },
        "bluesky": {
            "name": "Bluesky",
            "supports_images": True,
            "supports_videos": False,
            "supports_scheduling": True,
            "max_chars": 300,
        },
        "gmb": {
            "name": "Google Business Profile",
            "supports_images": True,
            "supports_videos": True,
            "supports_scheduling": True,
            "notes": "Formerly Google My Business",
        },
    }

    return {
        "status": "success",
        "total_platforms": len(platform_info),
        "platforms": platform_info,
    }


@mcp.tool()
async def get_social_analytics(platforms: List[str]) -> Dict[str, Any]:
    """
    Get social network analytics across multiple platforms

    Retrieves aggregate analytics and metrics for specified social media platforms,
    including overall performance trends and cross-platform comparisons.

    Args:
        platforms: List of platforms to get analytics for
                  (e.g., ["facebook", "twitter", "linkedin"])

    Returns:
        Dictionary containing social network analytics with platform-specific metrics

    Example:
        get_social_analytics(platforms=["facebook", "instagram", "twitter"])
    """
    try:
        client = get_client()
        analytics = await client.get_analytics_social(platforms=platforms)

        return {
            "status": "success",
            "platforms": platforms,
            "analytics": analytics.data,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_profile_analytics(
    platforms: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Get profile/account analytics including follower counts and demographics

    Retrieves account-level metrics like follower count, follower growth,
    demographic data, and audience insights across connected platforms.

    Args:
        platforms: Optional list of specific platforms to get analytics from.
                  If not specified, gets analytics from all connected platforms.

    Returns:
        Dictionary containing profile analytics with follower metrics and demographics

    Example:
        get_profile_analytics(platforms=["facebook", "linkedin"])
    """
    try:
        client = get_client()
        analytics = await client.get_analytics_profile(platforms=platforms)

        return {
            "status": "success",
            "platforms": platforms or "all",
            "analytics": analytics.data,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def update_post(
    post_id: str,
    post_text: Optional[str] = None,
    platforms: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Update an existing scheduled or published post

    Args:
        post_id: The unique post ID to update
        post_text: Optional new content for the post
        platforms: Optional list of specific platforms to update on

    Returns:
        Dictionary with update status and post details

    Example:
        update_post(
            post_id="abc123",
            post_text="Updated content for the post",
            platforms=["facebook", "twitter"]
        )
    """
    try:
        client = get_client()
        response = await client.update_post(
            post_id=post_id,
            post_text=post_text,
            platforms=platforms,
        )

        return {
            "status": "success",
            "post_id": response.id,
            "post_status": response.status,
            "updated": True,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def retry_post(post_id: str) -> Dict[str, Any]:
    """
    Retry a failed post

    Useful when a post failed to publish due to temporary issues
    like network problems or platform downtime.

    Args:
        post_id: The unique post ID to retry

    Returns:
        Dictionary with retry status and results

    Example:
        retry_post(post_id="abc123")
    """
    try:
        client = get_client()
        response = await client.retry_post(post_id=post_id)

        return {
            "status": "success",
            "post_id": response.id,
            "post_status": response.status,
            "retried": True,
            "errors": response.errors,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def copy_post(
    post_id: str,
    platforms: List[str],
    scheduled_date: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Copy an existing post to different platforms or reschedule

    Creates a duplicate of an existing post, optionally to different platforms
    or with a new schedule.

    Args:
        post_id: The unique post ID to copy
        platforms: List of platforms to copy the post to
        scheduled_date: Optional ISO 8601 datetime for scheduling the copy

    Returns:
        Dictionary with new post ID and copy status

    Example:
        copy_post(
            post_id="abc123",
            platforms=["linkedin", "pinterest"],
            scheduled_date="2024-12-26T15:00:00Z"
        )
    """
    try:
        client = get_client()
        response = await client.copy_post(
            post_id=post_id,
            platforms=platforms,
            scheduled_date=scheduled_date,
        )

        return {
            "status": "success",
            "original_post_id": post_id,
            "new_post_id": response.id,
            "post_status": response.status,
            "platforms": platforms,
            "scheduled_for": scheduled_date,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def bulk_post(posts: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Create multiple posts in a single bulk operation

    Efficiently publish multiple posts across platforms in one API call.

    Args:
        posts: List of post configurations. Each post should have:
              - post (str): Post content/text
              - platforms (List[str]): Target platforms
              - mediaUrls (List[str], optional): Media URLs
              - scheduleDate (str, optional): ISO 8601 datetime

    Returns:
        Dictionary with bulk operation results and individual post statuses

    Example:
        bulk_post(posts=[
            {
                "post": "First post content",
                "platforms": ["facebook", "twitter"]
            },
            {
                "post": "Second post content",
                "platforms": ["linkedin"],
                "scheduleDate": "2024-12-25T12:00:00Z"
            }
        ])
    """
    try:
        client = get_client()
        result = await client.bulk_post(posts=posts)

        return {
            "status": "success",
            "total_posts": len(posts),
            "results": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def upload_media(
    file_url: str,
    file_name: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Upload media file to Ayrshare media library

    Uploads an image or video from a URL to your Ayrshare media library
    for reuse across multiple posts.

    Args:
        file_url: Public URL of the media file to upload
        file_name: Optional custom filename for the uploaded media

    Returns:
        Dictionary with upload status and media library URL

    Example:
        upload_media(
            file_url="https://example.com/product-image.jpg",
            file_name="summer-collection-hero.jpg"
        )
    """
    try:
        client = get_client()
        result = await client.upload_media(
            file_url=file_url,
            file_name=file_name,
        )

        return {
            "status": "success",
            "uploaded": True,
            "original_url": file_url,
            "library_url": result.get("url"),
            "file_name": file_name,
            "details": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def validate_media_url(media_url: str) -> Dict[str, Any]:
    """
    Validate a media URL for accessibility and format

    Checks if a media URL is accessible, has the correct format,
    and meets Ayrshare's requirements before using it in a post.

    Args:
        media_url: URL of the media file to validate

    Returns:
        Dictionary with validation result and any issues found

    Example:
        validate_media_url(media_url="https://example.com/image.jpg")
    """
    try:
        client = get_client()
        result = await client.validate_media_url(media_url=media_url)

        return {
            "status": "success",
            "valid": result.get("valid", True),
            "url": media_url,
            "issues": result.get("issues", []),
            "details": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_unsplash_image(
    query: Optional[str] = None,
    image_id: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Get image from Unsplash integration

    Fetch royalty-free images from Unsplash to use in your social media posts.
    Either search by query or get a specific image by ID.

    Args:
        query: Search query for a random relevant image (e.g., "business", "technology")
        image_id: Specific Unsplash image ID to retrieve

    Returns:
        Dictionary with Unsplash image URL and attribution details

    Example:
        # Search-based
        get_unsplash_image(query="sunset beach vacation")

        # Specific image
        get_unsplash_image(image_id="HubtZZb2fCM")
    """
    try:
        if not query and not image_id:
            return {
                "status": "error",
                "message": "Either query or image_id must be provided",
            }

        client = get_client()
        result = await client.get_unsplash_image(
            query=query,
            image_id=image_id,
        )

        return {
            "status": "success",
            "image_url": result.get("url"),
            "query": query,
            "image_id": image_id or result.get("id"),
            "attribution": result.get("attribution"),
            "photographer": result.get("photographer"),
            "details": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def post_with_auto_hashtags(
    post_text: str,
    platforms: List[str],
    max_hashtags: int = 2,
    position: str = "auto",
    media_urls: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Create post with automatic hashtag generation

    Ayrshare will automatically generate and add relevant hashtags to your post
    based on the content.

    Args:
        post_text: Content of the post
        platforms: List of platforms to post to
        max_hashtags: Maximum number of hashtags to generate (1-10, default: 2)
        position: Where to place hashtags ("auto" or "end")
        media_urls: Optional media attachments

    Returns:
        Dictionary with post ID and generated hashtags

    Example:
        post_with_auto_hashtags(
            post_text="Excited to announce our new sustainable product line!",
            platforms=["twitter", "instagram"],
            max_hashtags=3
        )
    """
    try:
        client = get_client()
        response = await client.post_with_auto_hashtag(
            post_text=post_text,
            platforms=platforms,
            max_hashtags=max_hashtags,
            position=position,
            mediaUrls=media_urls,
        )

        return {
            "status": "success",
            "post_id": response.id,
            "post_status": response.status,
            "hashtags_generated": True,
            "max_hashtags": max_hashtags,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def create_evergreen_post(
    post_text: str,
    platforms: List[str],
    repeat: int,
    days_between: int,
    start_date: Optional[str] = None,
    media_urls: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Create auto-reposting evergreen content

    Schedule a post to automatically repost multiple times at specified intervals.
    Perfect for timeless content like quotes, tips, or promotional messages.

    Args:
        post_text: Content of the post
        platforms: List of platforms to post to
        repeat: Number of times to repost (1-10)
        days_between: Days between reposts (minimum 2)
        start_date: Optional start date (ISO 8601, defaults to now)
        media_urls: Optional media attachments

    Returns:
        Dictionary with post ID and repost schedule

    Example:
        create_evergreen_post(
            post_text="The best time to start is now!",
            platforms=["facebook", "twitter"],
            repeat=5,
            days_between=7,
            start_date="2024-12-25T09:00:00Z"
        )
    """
    try:
        client = get_client()
        response = await client.post_evergreen(
            post_text=post_text,
            platforms=platforms,
            repeat=repeat,
            days_between=days_between,
            start_date=start_date,
            mediaUrls=media_urls,
        )

        return {
            "status": "success",
            "post_id": response.id,
            "post_status": response.status,
            "evergreen": True,
            "repeat_count": repeat,
            "days_between": days_between,
            "start_date": start_date,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def post_with_first_comment(
    post_text: str,
    platforms: List[str],
    first_comment: str,
    comment_media_urls: Optional[List[str]] = None,
    media_urls: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Create post with automatic first comment

    Post will be published first, then the first comment will be added automatically
    (approximately 20 seconds later, up to 90 seconds for TikTok).

    Args:
        post_text: Content of the main post
        platforms: List of platforms to post to
        first_comment: Comment to add immediately after post
        comment_media_urls: Optional media for the comment (Facebook, LinkedIn, Twitter only)
        media_urls: Optional media for the main post

    Returns:
        Dictionary with post ID and first comment status

    Example:
        post_with_first_comment(
            post_text="New blog post is live!",
            platforms=["facebook", "linkedin"],
            first_comment="Read more at our website: https://example.com/blog",
            comment_media_urls=["https://example.com/blog-preview.jpg"]
        )
    """
    try:
        client = get_client()
        response = await client.post_with_first_comment(
            post_text=post_text,
            platforms=platforms,
            first_comment=first_comment,
            comment_media_urls=comment_media_urls,
            mediaUrls=media_urls,
        )

        return {
            "status": "success",
            "post_id": response.id,
            "post_status": response.status,
            "first_comment_added": True,
            "comment_text": first_comment,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def submit_post_for_approval(
    post_text: str,
    platforms: List[str],
    notes: Optional[str] = None,
    media_urls: Optional[List[str]] = None,
    scheduled_date: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Submit post for approval before publication

    Creates a post that requires manual approval before it will be published.
    Useful for content review workflows.

    Args:
        post_text: Content of the post
        platforms: List of platforms to post to
        notes: Optional notes for the approver
        media_urls: Optional media attachments
        scheduled_date: Optional scheduled publication date (ISO 8601)

    Returns:
        Dictionary with post ID in "awaiting approval" status

    Example:
        submit_post_for_approval(
            post_text="Big announcement coming soon!",
            platforms=["facebook", "twitter", "linkedin"],
            notes="Please review for compliance before approval",
            scheduled_date="2024-12-25T10:00:00Z"
        )
    """
    try:
        client = get_client()
        response = await client.post_with_approval(
            post_text=post_text,
            platforms=platforms,
            notes=notes,
            mediaUrls=media_urls,
            scheduleDate=scheduled_date,
        )

        return {
            "status": "success",
            "post_id": response.id,
            "post_status": "awaiting_approval",
            "platforms": platforms,
            "notes": notes,
            "scheduled_date": scheduled_date,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def approve_post(post_id: str) -> Dict[str, Any]:
    """
    Approve a post that is awaiting approval

    Approves a post that was submitted with requiresApproval flag.
    Post will be published immediately or at its scheduled time.

    Args:
        post_id: The post ID to approve

    Returns:
        Dictionary with approval status

    Example:
        approve_post(post_id="abc123")
    """
    try:
        client = get_client()
        response = await client.approve_post(post_id=post_id)

        return {
            "status": "success",
            "post_id": response.id,
            "post_status": response.status,
            "approved": True,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.resource("ayrshare://history")
async def get_post_history() -> str:
    """
    Get recent post history from Ayrshare account

    Returns the last 30 days of posts across all connected platforms,
    including post content, status, platforms, and engagement metrics.
    """
    try:
        client = get_client()
        history = await client.get_history(last_days=30)

        if not history:
            return "No posts found in the last 30 days."

        # Format history as readable text
        result = ["# Post History (Last 30 Days)\n"]

        for post in history:
            result.append(f"## Post ID: {post.get('id', 'N/A')}")
            result.append(f"Status: {post.get('status', 'N/A')}")
            result.append(f"Platforms: {', '.join(post.get('platforms', []))}")
            result.append(f"Created: {post.get('created', 'N/A')}")

            if post.get("post"):
                result.append(f"Content: {post['post'][:100]}...")

            if post.get("scheduled"):
                result.append(f"Scheduled for: {post['scheduled']}")

            result.append("")  # Blank line

        return "\n".join(result)

    except AyrshareError as e:
        return f"Error fetching history: {str(e)}"


@mcp.resource("ayrshare://platforms")
async def get_connected_platforms() -> str:
    """
    Get connected social media profiles and platforms

    Returns information about which social media accounts are connected
    to the Ayrshare profile and available for posting.
    """
    try:
        client = get_client()
        profiles = await client.get_profiles()

        if not profiles:
            return "No connected profiles found. Please connect social media accounts in the Ayrshare dashboard."

        # Format profiles as readable text
        result = ["# Connected Social Media Profiles\n"]

        for profile in profiles:
            result.append(f"## Profile: {profile.get('title', 'Unnamed Profile')}")
            result.append(f"Profile Key: {profile.get('profileKey', 'N/A')}")

            platforms = profile.get("connectedAccounts", [])
            if platforms:
                result.append(f"Connected Platforms ({len(platforms)}):")
                for platform in platforms:
                    platform_name = platform.get("platform", "Unknown")
                    account = platform.get("account", "")
                    status = platform.get("status", "unknown")
                    result.append(f"  - {platform_name}: {account} ({status})")
            else:
                result.append("No platforms connected to this profile.")

            result.append("")  # Blank line

        return "\n".join(result)

    except AyrshareError as e:
        return f"Error fetching profiles: {str(e)}"


@mcp.prompt()
def optimize_for_platform(post_content: str, target_platform: str) -> str:
    """
    Generate platform-optimized social media post

    Creates a prompt for an LLM to optimize post content for a specific social media
    platform, considering character limits, hashtag best practices, and platform culture.

    Args:
        post_content: The original post content to optimize
        target_platform: The target platform (facebook, twitter, linkedin, instagram, etc.)

    Returns:
        Prompt string for LLM to generate optimized content
    """
    platform_specs = {
        "twitter": {
            "char_limit": 280,
            "tone": "conversational and concise",
            "hashtags": "1-2 relevant hashtags",
            "style": "punchy and engaging",
        },
        "facebook": {
            "char_limit": 63206,
            "tone": "friendly and personal",
            "hashtags": "minimal, focus on storytelling",
            "style": "detailed and engaging",
        },
        "linkedin": {
            "char_limit": 3000,
            "tone": "professional and insightful",
            "hashtags": "3-5 professional hashtags",
            "style": "thought leadership and value-driven",
        },
        "instagram": {
            "char_limit": 2200,
            "tone": "visual-first with engaging caption",
            "hashtags": "10-30 relevant hashtags",
            "style": "storytelling with emoji support",
        },
        "tiktok": {
            "char_limit": 2200,
            "tone": "fun, trendy, authentic",
            "hashtags": "3-5 trending hashtags",
            "style": "attention-grabbing and relatable",
        },
    }

    specs = platform_specs.get(target_platform.lower(), {
        "char_limit": 2000,
        "tone": "engaging and platform-appropriate",
        "hashtags": "2-5 relevant hashtags",
        "style": "clear and compelling",
    })

    return f"""Optimize this social media post for {target_platform}:

Original Content:
{post_content}

Platform Requirements for {target_platform}:
- Character Limit: {specs['char_limit']}
- Tone: {specs['tone']}
- Hashtag Strategy: {specs['hashtags']}
- Style: {specs['style']}

Please create an optimized version that:
1. Fits within the character limit
2. Matches the platform's tone and culture
3. Includes appropriate hashtags
4. Maximizes engagement potential
5. Preserves the core message

Return ONLY the optimized post content, ready to publish."""


@mcp.prompt()
def generate_hashtags(post_content: str, target_platforms: List[str], max_hashtags: int = 5) -> str:
    """
    Generate relevant hashtags for social media post

    Creates a prompt for an LLM to generate platform-appropriate hashtags
    based on post content and target platforms.

    Args:
        post_content: The post content to generate hashtags for
        target_platforms: List of target platforms
        max_hashtags: Maximum number of hashtags to generate (default: 5)

    Returns:
        Prompt string for LLM to generate hashtags
    """
    platform_list = ", ".join(target_platforms)

    return f"""Generate relevant hashtags for this social media post:

Post Content:
{post_content}

Target Platforms: {platform_list}
Maximum Hashtags: {max_hashtags}

Requirements:
1. Generate {max_hashtags} highly relevant hashtags
2. Mix of popular and niche hashtags
3. Consider platform-specific trends
4. Include industry/topic-specific tags
5. Avoid overused or spammy hashtags

Return hashtags in this format:
#hashtag1 #hashtag2 #hashtag3 ...

Focus on hashtags that will maximize reach and engagement on {platform_list}."""


@mcp.prompt()
def schedule_campaign(
    campaign_name: str,
    start_date: str,
    end_date: str,
    post_frequency: str,
    platforms: List[str],
    campaign_goals: str,
) -> str:
    """
    Generate social media campaign schedule

    Creates a prompt for an LLM to generate a comprehensive posting schedule
    for a social media campaign across multiple platforms.

    Args:
        campaign_name: Name of the campaign
        start_date: Campaign start date (YYYY-MM-DD)
        end_date: Campaign end date (YYYY-MM-DD)
        post_frequency: Posting frequency (e.g., "daily", "twice daily", "3x per week")
        platforms: List of target platforms
        campaign_goals: Campaign objectives and goals

    Returns:
        Prompt string for LLM to generate campaign schedule
    """
    platform_list = ", ".join(platforms)

    return f"""Create a detailed social media campaign schedule:

Campaign Details:
- Name: {campaign_name}
- Duration: {start_date} to {end_date}
- Posting Frequency: {post_frequency}
- Platforms: {platform_list}
- Goals: {campaign_goals}

Please create a comprehensive schedule that includes:

1. **Posting Calendar**
   - Specific dates and times for each post
   - Platform-specific content for {platform_list}
   - Content themes for each post

2. **Content Strategy**
   - Post types (promotional, educational, engaging, etc.)
   - Content mix ratios
   - Platform-specific adaptations

3. **Engagement Strategy**
   - Peak posting times for each platform
   - Community interaction plan
   - Response templates

4. **Performance Tracking**
   - Key metrics to monitor
   - Success criteria
   - Adjustment triggers

Format the schedule as a detailed calendar with:
- Date/Time
- Platform(s)
- Post Type
- Content Theme
- Call-to-Action

Focus on achieving: {campaign_goals}"""


if __name__ == "__main__":
    # Run server
    # For STDIO (Claude Desktop): mcp.run()
    # For HTTP: mcp.run(transport="http")
    import sys

    transport = "http" if "--http" in sys.argv else "stdio"
    mcp.run(transport=transport)
