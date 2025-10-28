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


# Comments API Tools

@mcp.tool()
async def get_post_comments(
    post_id: str,
    platforms: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Get comments on a specific social media post

    Retrieves all comments for a post across specified platforms.
    Useful for monitoring engagement and responding to user interactions.

    Args:
        post_id: The Ayrshare post ID
        platforms: Optional list of specific platforms to get comments from
                  (e.g., ["facebook", "instagram"]). If not specified, gets from all platforms.

    Returns:
        Dictionary with comments list and metadata

    Example:
        get_post_comments(
            post_id="eIT96IYEodNuzU4oMmwG",
            platforms=["facebook", "twitter"]
        )
    """
    try:
        client = get_client()
        comments = await client.get_comments(
            post_id=post_id,
            platforms=platforms,
        )

        return {
            "status": "success",
            "post_id": post_id,
            "total_comments": len(comments),
            "comments": comments,
            "platforms": platforms or "all",
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def add_comment_to_post(
    post_id: str,
    comment_text: str,
    platforms: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Add a comment to a social media post

    Post a comment on your own post or another post across specified platforms.

    Args:
        post_id: The Ayrshare post ID or social network post ID
        comment_text: The content of the comment
        platforms: Optional list of platforms to comment on

    Returns:
        Dictionary with comment ID and status

    Example:
        add_comment_to_post(
            post_id="eIT96IYEodNuzU4oMmwG",
            comment_text="Thanks for all the engagement!",
            platforms=["facebook", "linkedin"]
        )
    """
    try:
        client = get_client()
        response = await client.add_comment(
            post_id=post_id,
            comment_text=comment_text,
            platforms=platforms,
        )

        return {
            "status": "success",
            "comment_id": response.id,
            "post_id": post_id,
            "platforms": platforms or "all",
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def reply_to_comment(
    comment_id: str,
    reply_text: str,
    platform: str,
) -> Dict[str, Any]:
    """
    Reply to an existing comment on a social media post

    Respond to a comment made by another user on your posts.

    Args:
        comment_id: The social network comment ID
        reply_text: The content of your reply
        platform: The platform where the comment exists (e.g., "facebook", "instagram")

    Returns:
        Dictionary with reply ID and status

    Example:
        reply_to_comment(
            comment_id="123456789_987654321",
            reply_text="Thank you for your feedback!",
            platform="facebook"
        )
    """
    try:
        client = get_client()
        response = await client.reply_to_comment(
            comment_id=comment_id,
            reply_text=reply_text,
            platform=platform,
        )

        return {
            "status": "success",
            "reply_id": response.id,
            "comment_id": comment_id,
            "platform": platform,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def delete_post_comment(
    comment_id: str,
    platforms: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Delete a comment from social media platforms

    Remove a comment from your posts across specified platforms.

    Args:
        comment_id: The Ayrshare comment ID or social network comment ID
        platforms: Optional list of platforms to delete comment from

    Returns:
        Dictionary with deletion status

    Example:
        delete_post_comment(
            comment_id="commentID123",
            platforms=["facebook", "twitter"]
        )
    """
    try:
        client = get_client()
        result = await client.delete_comment(
            comment_id=comment_id,
            platforms=platforms,
        )

        return {
            "status": "success",
            "comment_id": comment_id,
            "deleted_from": platforms or "all platforms",
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Messages API Tools (Business Plan)

@mcp.tool()
async def send_direct_message(
    platform: str,
    recipient_id: str,
    message: str,
    media_urls: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Send a direct message to a user (Business Plan required)

    Send DMs on Facebook, Instagram, or Twitter/X.

    Args:
        platform: Platform to send message on ("facebook", "instagram", "twitter")
        recipient_id: Recipient's ID on the platform
        message: Message content
        media_urls: Optional media attachments

    Returns:
        Dictionary with message ID and status

    Example:
        send_direct_message(
            platform="instagram",
            recipient_id="123456789",
            message="Thanks for your interest!",
            media_urls=["https://example.com/product-image.jpg"]
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        response = await client.send_message(
            platform=platform,
            recipient_id=recipient_id,
            message=message,
            media_urls=media_urls,
        )

        return {
            "status": "success",
            "message_id": response.id,
            "platform": platform,
            "recipient_id": recipient_id,
            "warnings": response.warnings,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_message_conversations(
    platform: str,
    limit: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Get list of message conversations (Business Plan required)

    Retrieve DM conversations from Facebook, Instagram, or Twitter/X.

    Args:
        platform: Platform to get conversations from
        limit: Optional limit on number of conversations

    Returns:
        Dictionary with conversations list

    Example:
        get_message_conversations(
            platform="instagram",
            limit=50
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        conversations = await client.get_conversations(
            platform=platform,
            limit=limit,
        )

        return {
            "status": "success",
            "platform": platform,
            "total_conversations": len(conversations),
            "conversations": conversations,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_conversation_history(
    conversation_id: str,
    platform: str,
    limit: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Get messages from a specific conversation (Business Plan required)

    Retrieve message history from a DM conversation.

    Args:
        conversation_id: The conversation ID
        platform: The platform
        limit: Optional limit on number of messages

    Returns:
        Dictionary with messages list

    Example:
        get_conversation_history(
            conversation_id="conv_12345",
            platform="facebook",
            limit=100
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        messages = await client.get_conversation_messages(
            conversation_id=conversation_id,
            platform=platform,
            limit=limit,
        )

        return {
            "status": "success",
            "conversation_id": conversation_id,
            "platform": platform,
            "total_messages": len(messages),
            "messages": messages,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def mark_messages_as_read(
    message_ids: List[str],
    platform: str,
) -> Dict[str, Any]:
    """
    Mark messages as read (Business Plan required)

    Mark one or more messages as read in DM conversations.

    Args:
        message_ids: List of message IDs to mark as read
        platform: The platform

    Returns:
        Dictionary with status

    Example:
        mark_messages_as_read(
            message_ids=["msg_123", "msg_124"],
            platform="instagram"
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.mark_messages_read(
            message_ids=message_ids,
            platform=platform,
        )

        return {
            "status": "success",
            "marked_read": len(message_ids),
            "platform": platform,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Reviews API Tools (Google Business Profile)

@mcp.tool()
async def get_google_business_reviews(
    location_id: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Get Google Business Profile reviews

    Retrieve reviews for your Google Business Profile location(s).

    Args:
        location_id: Optional specific location ID. If not provided, gets all locations.

    Returns:
        Dictionary with reviews list

    Example:
        get_google_business_reviews(
            location_id="location_12345"
        )
    """
    try:
        client = get_client()
        reviews = await client.get_reviews(location_id=location_id)

        return {
            "status": "success",
            "total_reviews": len(reviews),
            "reviews": reviews,
            "location_id": location_id or "all",
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def respond_to_review(
    review_id: str,
    response_text: str,
) -> Dict[str, Any]:
    """
    Reply to a Google Business Profile review

    Respond to a customer review on your Google Business Profile.

    Args:
        review_id: The review ID
        response_text: Your reply to the review

    Returns:
        Dictionary with reply status

    Example:
        respond_to_review(
            review_id="review_12345",
            response_text="Thank you for your feedback! We're glad you enjoyed our service."
        )
    """
    try:
        client = get_client()
        result = await client.reply_to_review(
            review_id=review_id,
            response_text=response_text,
        )

        return {
            "status": "success",
            "review_id": review_id,
            "responded": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def remove_review_response(
    review_id: str,
) -> Dict[str, Any]:
    """
    Delete a review response from Google Business Profile

    Remove your reply to a customer review.

    Args:
        review_id: The review ID

    Returns:
        Dictionary with deletion status

    Example:
        remove_review_response(review_id="review_12345")
    """
    try:
        client = get_client()
        result = await client.delete_review_response(review_id=review_id)

        return {
            "status": "success",
            "review_id": review_id,
            "response_deleted": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Webhooks API Tools (Business Plan)

@mcp.tool()
async def setup_webhook_endpoint(
    url: str,
    events: List[str],
) -> Dict[str, Any]:
    """
    Create a webhook subscription (Business Plan required)

    Configure real-time notifications for social media events.

    Args:
        url: Your webhook endpoint URL
        events: List of events to subscribe to (e.g., ["post.published", "comment.added"])

    Returns:
        Dictionary with webhook ID and configuration

    Example:
        setup_webhook_endpoint(
            url="https://myserver.com/webhooks/ayrshare",
            events=["post.published", "post.failed", "comment.added"]
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.create_webhook(
            url=url,
            events=events,
        )

        return {
            "status": "success",
            "webhook_id": result.get("id"),
            "url": url,
            "events": events,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def list_webhook_subscriptions() -> Dict[str, Any]:
    """
    List configured webhooks (Business Plan required)

    Get all webhook subscriptions for your account.

    Returns:
        Dictionary with webhooks list

    Example:
        list_webhook_subscriptions()

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        webhooks = await client.list_webhooks()

        return {
            "status": "success",
            "total_webhooks": len(webhooks),
            "webhooks": webhooks,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def update_webhook_configuration(
    webhook_id: str,
    url: Optional[str] = None,
    events: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Update webhook configuration (Business Plan required)

    Modify webhook URL or event subscriptions.

    Args:
        webhook_id: The webhook ID
        url: Optional new webhook URL
        events: Optional new events list

    Returns:
        Dictionary with updated configuration

    Example:
        update_webhook_configuration(
            webhook_id="webhook_123",
            url="https://myserver.com/new-webhook-endpoint",
            events=["post.published", "post.failed"]
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.update_webhook(
            webhook_id=webhook_id,
            url=url,
            events=events,
        )

        return {
            "status": "success",
            "webhook_id": webhook_id,
            "updated": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def remove_webhook(
    webhook_id: str,
) -> Dict[str, Any]:
    """
    Delete a webhook subscription (Business Plan required)

    Remove a webhook to stop receiving event notifications.

    Args:
        webhook_id: The webhook ID to delete

    Returns:
        Dictionary with deletion status

    Example:
        remove_webhook(webhook_id="webhook_123")

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.delete_webhook(webhook_id=webhook_id)

        return {
            "status": "success",
            "webhook_id": webhook_id,
            "deleted": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Links API Tools (Max Pack Add-on)

@mcp.tool()
async def shorten_url(
    url: str,
    custom_slug: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Create a shortened link (Max Pack Add-on required)

    Shorten URLs for social media posts with optional custom slug.

    Args:
        url: The URL to shorten
        custom_slug: Optional custom slug for the shortened URL

    Returns:
        Dictionary with shortened URL and details

    Example:
        shorten_url(
            url="https://example.com/very/long/url/path",
            custom_slug="promo2024"
        )

    Note: Requires Ayrshare Max Pack Add-on
    """
    try:
        client = get_client()
        result = await client.shorten_link(
            url=url,
            custom_slug=custom_slug,
        )

        return {
            "status": "success",
            "original_url": url,
            "shortened_url": result.get("shortUrl"),
            "link_id": result.get("id"),
            "custom_slug": custom_slug,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_link_analytics(
    link_id: str,
) -> Dict[str, Any]:
    """
    Get analytics for a shortened link (Max Pack Add-on required)

    Track clicks, referrers, and other metrics for shortened URLs.

    Args:
        link_id: The shortened link ID

    Returns:
        Dictionary with link analytics data

    Example:
        get_link_analytics(link_id="link_12345")

    Note: Requires Ayrshare Max Pack Add-on
    """
    try:
        client = get_client()
        analytics = await client.get_link_analytics(link_id=link_id)

        return {
            "status": "success",
            "link_id": link_id,
            "analytics": analytics,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Ads API Tools (Business Plan)

@mcp.tool()
async def create_ad_from_post(
    post_id: str,
    budget: float,
    duration: int,
    targeting: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Create a Facebook ad from an existing post (Business Plan required)

    Boost a post by turning it into a paid Facebook advertisement.

    Args:
        post_id: The post ID to boost
        budget: Ad budget in dollars
        duration: Duration in days
        targeting: Optional targeting parameters (age, location, interests, etc.)

    Returns:
        Dictionary with ad ID and creation status

    Example:
        create_ad_from_post(
            post_id="eIT96IYEodNuzU4oMmwG",
            budget=100.00,
            duration=7,
            targeting={
                "age_min": 25,
                "age_max": 55,
                "locations": ["US", "CA", "UK"],
                "interests": ["technology", "business"]
            }
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.create_ad(
            post_id=post_id,
            budget=budget,
            duration=duration,
            targeting=targeting,
        )

        return {
            "status": "success",
            "ad_id": result.get("id"),
            "post_id": post_id,
            "budget": budget,
            "duration": duration,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_ad_analytics(
    ad_id: str,
) -> Dict[str, Any]:
    """
    Get analytics for a Facebook ad (Business Plan required)

    Track ad performance including impressions, clicks, and conversions.

    Args:
        ad_id: The ad ID

    Returns:
        Dictionary with ad performance metrics

    Example:
        get_ad_analytics(ad_id="ad_12345")

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        analytics = await client.get_ad_analytics(ad_id=ad_id)

        return {
            "status": "success",
            "ad_id": ad_id,
            "analytics": analytics,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def manage_ad_campaign(
    ad_id: str,
    budget: Optional[float] = None,
    status: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Update ad campaign settings (Business Plan required)

    Modify budget or pause/resume ad campaigns.

    Args:
        ad_id: The ad ID
        budget: Optional new budget in dollars
        status: Optional new status ("active" or "paused")

    Returns:
        Dictionary with updated ad configuration

    Example:
        manage_ad_campaign(
            ad_id="ad_12345",
            budget=150.00,
            status="active"
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.update_ad(
            ad_id=ad_id,
            budget=budget,
            status=status,
        )

        return {
            "status": "success",
            "ad_id": ad_id,
            "updated": True,
            "new_budget": budget,
            "new_status": status,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def stop_ad_campaign(
    ad_id: str,
) -> Dict[str, Any]:
    """
    Stop and delete a Facebook ad campaign (Business Plan required)

    Permanently stop an ad and remove it from your account.

    Args:
        ad_id: The ad ID to stop

    Returns:
        Dictionary with deletion status

    Example:
        stop_ad_campaign(ad_id="ad_12345")

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.delete_ad(ad_id=ad_id)

        return {
            "status": "success",
            "ad_id": ad_id,
            "stopped": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Profiles API Tools (Business Plan)

@mcp.tool()
async def create_user_profile(
    title: str,
    messaging_active: Optional[bool] = None,
    team: Optional[List[str]] = None,
    email: Optional[str] = None,
    disable_social: Optional[List[str]] = None,
    tags: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Create a new user profile (Business Plan required)

    Enables multi-user management for SaaS applications.

    Args:
        title: Profile title/name
        messaging_active: Enable messaging for profile
        team: List of team member emails
        email: Profile email address
        disable_social: List of social networks to disable
        tags: Tags for organizing profiles

    Returns:
        Dictionary with profile key and creation status

    Example:
        create_user_profile(
            title="Client ABC - Marketing Team",
            email="client@example.com",
            tags=["enterprise", "q1-2025"]
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.create_profile(
            title=title,
            messaging_active=messaging_active,
            team=team,
            email=email,
            disable_social=disable_social,
            tags=tags,
        )

        return {
            "status": "success",
            "profile_key": result.get("profileKey"),
            "title": title,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def list_user_profiles(
    title: Optional[str] = None,
    ref_id: Optional[str] = None,
    has_active_social: Optional[bool] = None,
    includes_active_social: Optional[List[str]] = None,
    limit: Optional[int] = None,
) -> Dict[str, Any]:
    """
    List user profiles with filtering options (Business Plan required)

    Args:
        title: Filter by profile title
        ref_id: Filter by reference ID
        has_active_social: Filter profiles with active social accounts
        includes_active_social: Filter profiles with specific active platforms
        limit: Limit number of profiles returned

    Returns:
        Dictionary with profiles list

    Example:
        list_user_profiles(
            has_active_social=True,
            includes_active_social=["facebook", "instagram"]
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        profiles = await client.list_profiles(
            title=title,
            ref_id=ref_id,
            has_active_social=has_active_social,
            includes_active_social=includes_active_social,
            limit=limit,
        )

        return {
            "status": "success",
            "total_profiles": len(profiles),
            "profiles": profiles,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_user_profile_details(
    profile_key: str,
) -> Dict[str, Any]:
    """
    Get specific profile details (Business Plan required)

    Args:
        profile_key: The profile key

    Returns:
        Dictionary with profile details

    Example:
        get_user_profile_details(profile_key="AX1XGG-9jK3M5LS-GR5RX5G-LLCK8EA")

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.get_profile_details(profile_key=profile_key)

        return {
            "status": "success",
            "profile": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def update_user_profile(
    profile_key: str,
    settings: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Update profile settings (Business Plan required)

    Args:
        profile_key: The profile key
        settings: Settings to update (title, messagingActive, team, email, etc.)

    Returns:
        Dictionary with updated profile data

    Example:
        update_user_profile(
            profile_key="AX1XGG-9jK3M5LS-GR5RX5G-LLCK8EA",
            settings={"title": "Updated Title", "messagingActive": True}
        )

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.update_profile(
            profile_key=profile_key,
            settings=settings,
        )

        return {
            "status": "success",
            "profile_key": profile_key,
            "updated": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def delete_user_profile(
    profile_key: str,
) -> Dict[str, Any]:
    """
    Delete a user profile (Business Plan required)

    WARNING: This action cannot be undone and will delete all post history
    for this profile.

    Args:
        profile_key: The profile key to delete

    Returns:
        Dictionary with deletion status

    Example:
        delete_user_profile(profile_key="AX1XGG-9jK3M5LS-GR5RX5G-LLCK8EA")

    Note: Requires Ayrshare Business Plan
    """
    try:
        client = get_client()
        result = await client.delete_profile(profile_key=profile_key)

        return {
            "status": "success",
            "profile_key": profile_key,
            "deleted": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# History API Tools (Extended)

@mcp.tool()
async def get_post_by_history_id(
    history_id: str,
) -> Dict[str, Any]:
    """
    Get specific post details from history

    Args:
        history_id: The history ID

    Returns:
        Dictionary with post details

    Example:
        get_post_by_history_id(history_id="eIT96IYEodNuzU4oMmwG")
    """
    try:
        client = get_client()
        result = await client.get_history_by_id(history_id=history_id)

        return {
            "status": "success",
            "post": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_all_scheduled_posts() -> Dict[str, Any]:
    """
    Get all scheduled posts

    View upcoming content calendar and manage scheduled campaigns.

    Returns:
        Dictionary with scheduled posts list

    Example:
        get_all_scheduled_posts()
    """
    try:
        client = get_client()
        posts = await client.get_scheduled_posts()

        return {
            "status": "success",
            "total_scheduled": len(posts),
            "posts": posts,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_repost_series(
    auto_repost_id: str,
) -> Dict[str, Any]:
    """
    Get auto-repost series by ID

    Retrieve all posts in an evergreen content series.

    Args:
        auto_repost_id: The auto-repost series ID

    Returns:
        Dictionary with posts in the series

    Example:
        get_repost_series(auto_repost_id="F5wdoaOAAGtDQVciExSxL")
    """
    try:
        client = get_client()
        posts = await client.get_auto_repost_series(auto_repost_id=auto_repost_id)

        return {
            "status": "success",
            "auto_repost_id": auto_repost_id,
            "total_posts": len(posts),
            "posts": posts,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Media API Tools (Extended)

@mcp.tool()
async def list_all_media(
    limit: Optional[int] = None,
) -> Dict[str, Any]:
    """
    List all uploaded media files

    View your media library with uploaded images and videos.

    Args:
        limit: Limit number of media items

    Returns:
        Dictionary with media items list

    Example:
        list_all_media(limit=50)
    """
    try:
        client = get_client()
        media = await client.list_media(limit=limit)

        return {
            "status": "success",
            "total_media": len(media),
            "media": media,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_media_item_details(
    media_id: str,
) -> Dict[str, Any]:
    """
    Get specific media details

    Args:
        media_id: The media ID

    Returns:
        Dictionary with media details

    Example:
        get_media_item_details(media_id="media_12345")
    """
    try:
        client = get_client()
        result = await client.get_media_details(media_id=media_id)

        return {
            "status": "success",
            "media": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def delete_media_file(
    media_id: str,
) -> Dict[str, Any]:
    """
    Delete media from library

    Args:
        media_id: The media ID to delete

    Returns:
        Dictionary with deletion status

    Example:
        delete_media_file(media_id="media_12345")
    """
    try:
        client = get_client()
        result = await client.delete_media(media_id=media_id)

        return {
            "status": "success",
            "media_id": media_id,
            "deleted": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Auto Schedule API Tools

@mcp.tool()
async def setup_auto_schedule(
    schedule_config: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Set auto-posting schedule

    Configure AI-powered optimal posting times for your content.

    Args:
        schedule_config: Schedule configuration (times, days, platforms, timezone)

    Returns:
        Dictionary with schedule creation response

    Example:
        setup_auto_schedule(
            schedule_config={
                "times": ["09:00", "14:00", "18:00"],
                "days": ["monday", "wednesday", "friday"],
                "platforms": ["facebook", "twitter", "linkedin"],
                "timezone": "America/New_York"
            }
        )
    """
    try:
        client = get_client()
        result = await client.set_auto_schedule(schedule_config=schedule_config)

        return {
            "status": "success",
            "schedule_created": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_current_auto_schedule() -> Dict[str, Any]:
    """
    Get current auto-schedule configuration

    View your automated posting schedule settings.

    Returns:
        Dictionary with auto-schedule settings

    Example:
        get_current_auto_schedule()
    """
    try:
        client = get_client()
        result = await client.get_auto_schedule()

        return {
            "status": "success",
            "schedule": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def modify_auto_schedule(
    schedule_config: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Update auto-schedule settings

    Args:
        schedule_config: Updated schedule configuration

    Returns:
        Dictionary with updated schedule

    Example:
        modify_auto_schedule(
            schedule_config={
                "times": ["10:00", "15:00"],
                "platforms": ["facebook", "instagram"]
            }
        )
    """
    try:
        client = get_client()
        result = await client.update_auto_schedule(schedule_config=schedule_config)

        return {
            "status": "success",
            "schedule_updated": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def remove_auto_schedule() -> Dict[str, Any]:
    """
    Remove auto-schedule

    Disable automated posting schedule.

    Returns:
        Dictionary with deletion status

    Example:
        remove_auto_schedule()
    """
    try:
        client = get_client()
        result = await client.delete_auto_schedule()

        return {
            "status": "success",
            "schedule_removed": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Brand API Tools

@mcp.tool()
async def create_brand_profile_config(
    brand_data: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Create brand profile with assets

    Setup brand identity including logos, colors, and templates.

    Args:
        brand_data: Brand information (name, logo, colors, fonts, templates)

    Returns:
        Dictionary with brand profile creation response

    Example:
        create_brand_profile_config(
            brand_data={
                "name": "My Brand",
                "logo": "https://example.com/logo.png",
                "colors": {
                    "primary": "#FF5733",
                    "secondary": "#C70039"
                },
                "fonts": ["Roboto", "Arial"]
            }
        )
    """
    try:
        client = get_client()
        result = await client.create_brand_profile(brand_data=brand_data)

        return {
            "status": "success",
            "brand_created": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_brand_profile_assets() -> Dict[str, Any]:
    """
    Get brand assets and templates

    Retrieve all brand assets including logos, colors, and templates.

    Returns:
        Dictionary with brand assets

    Example:
        get_brand_profile_assets()
    """
    try:
        client = get_client()
        result = await client.get_brand_assets()

        return {
            "status": "success",
            "brand": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def update_brand_profile_settings(
    brand_data: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Update brand profile settings

    Args:
        brand_data: Updated brand information

    Returns:
        Dictionary with updated brand profile

    Example:
        update_brand_profile_settings(
            brand_data={
                "colors": {
                    "primary": "#00FF00"
                }
            }
        )
    """
    try:
        client = get_client()
        result = await client.update_brand_settings(brand_data=brand_data)

        return {
            "status": "success",
            "brand_updated": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Feed API Tools

@mcp.tool()
async def get_platform_feed(
    platform: str,
    limit: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Get social media feed from specific platform

    Retrieve posts from your social media feed.

    Args:
        platform: Platform name (facebook, instagram, linkedin, twitter)
        limit: Limit number of posts

    Returns:
        Dictionary with feed posts

    Example:
        get_platform_feed(platform="instagram", limit=20)
    """
    try:
        client = get_client()
        posts = await client.get_social_feed(platform=platform, limit=limit)

        return {
            "status": "success",
            "platform": platform,
            "total_posts": len(posts),
            "posts": posts,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_all_platform_feeds(
    limit: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Get feeds from all connected platforms

    Retrieve posts from all connected social media platforms.

    Args:
        limit: Limit number of posts per platform

    Returns:
        Dictionary with feeds from all platforms

    Example:
        get_all_platform_feeds(limit=10)
    """
    try:
        client = get_client()
        result = await client.get_all_feeds(limit=limit)

        return {
            "status": "success",
            "feeds": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Generate API Tools (Max Pack Add-on)

@mcp.tool()
async def ai_generate_post_text(
    prompt: str,
    platform: Optional[str] = None,
    tone: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Generate post text using AI (Max Pack Add-on required)

    AI-powered content generation for social media posts.

    Args:
        prompt: Content prompt describing what you want to post about
        platform: Target platform for optimization (facebook, twitter, linkedin, etc.)
        tone: Desired tone (professional, casual, friendly, humorous, etc.)

    Returns:
        Dictionary with generated post text

    Example:
        ai_generate_post_text(
            prompt="New product launch announcement for eco-friendly water bottles",
            platform="instagram",
            tone="friendly"
        )

    Note: Requires Ayrshare Max Pack Add-on
    """
    try:
        client = get_client()
        result = await client.generate_post_text(
            prompt=prompt,
            platform=platform,
            tone=tone,
        )

        return {
            "status": "success",
            "generated_text": result.get("text"),
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def ai_generate_hashtags_for_content(
    content: str,
    count: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Generate hashtags for content using AI (Max Pack Add-on required)

    Args:
        content: Post content to generate hashtags for
        count: Number of hashtags to generate (default varies by platform)

    Returns:
        Dictionary with generated hashtags

    Example:
        ai_generate_hashtags_for_content(
            content="Excited to announce our new sustainable product line!",
            count=5
        )

    Note: Requires Ayrshare Max Pack Add-on
    """
    try:
        client = get_client()
        result = await client.generate_hashtags(content=content, count=count)

        return {
            "status": "success",
            "hashtags": result.get("hashtags"),
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def ai_generate_image_caption(
    image_url: str,
    style: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Generate caption for image using AI (Max Pack Add-on required)

    Args:
        image_url: URL of the image to generate caption for
        style: Caption style (descriptive, creative, humorous, etc.)

    Returns:
        Dictionary with generated caption

    Example:
        ai_generate_image_caption(
            image_url="https://example.com/product-image.jpg",
            style="creative"
        )

    Note: Requires Ayrshare Max Pack Add-on
    """
    try:
        client = get_client()
        result = await client.generate_caption(image_url=image_url, style=style)

        return {
            "status": "success",
            "caption": result.get("caption"),
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Hashtags API Tools

@mcp.tool()
async def suggest_relevant_hashtags(
    content: str,
    platform: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Get hashtag suggestions for content

    Discover relevant hashtags to maximize reach and engagement.

    Args:
        content: Post content to get hashtag suggestions for
        platform: Target platform for platform-specific suggestions

    Returns:
        Dictionary with suggested hashtags

    Example:
        suggest_relevant_hashtags(
            content="New sustainable fashion collection",
            platform="instagram"
        )
    """
    try:
        client = get_client()
        hashtags = await client.suggest_hashtags(content=content, platform=platform)

        return {
            "status": "success",
            "hashtags": hashtags,
            "total_suggestions": len(hashtags),
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_trending_platform_hashtags(
    platform: str,
    region: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Get trending hashtags for platform

    Discover what's trending on a specific social media platform.

    Args:
        platform: Platform name (twitter, instagram, tiktok, etc.)
        region: Optional region filter (e.g., "US", "UK", "CA")

    Returns:
        Dictionary with trending hashtags and metrics

    Example:
        get_trending_platform_hashtags(platform="twitter", region="US")
    """
    try:
        client = get_client()
        hashtags = await client.get_trending_hashtags(platform=platform, region=region)

        return {
            "status": "success",
            "platform": platform,
            "region": region or "global",
            "trending_hashtags": hashtags,
            "total_trending": len(hashtags),
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def analyze_hashtag_metrics(
    hashtag: str,
    time_range: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Analyze hashtag performance metrics

    Track hashtag usage, engagement, and trends over time.

    Args:
        hashtag: Hashtag to analyze (with or without #)
        time_range: Time range for analysis (7d, 30d, 90d)

    Returns:
        Dictionary with hashtag performance data

    Example:
        analyze_hashtag_metrics(hashtag="#marketing", time_range="30d")
    """
    try:
        client = get_client()
        result = await client.analyze_hashtag_performance(
            hashtag=hashtag,
            time_range=time_range,
        )

        return {
            "status": "success",
            "hashtag": hashtag,
            "time_range": time_range or "default",
            "analytics": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# User API Tools

@mcp.tool()
async def get_account_information() -> Dict[str, Any]:
    """
    Get user account information

    View your Ayrshare account details and settings.

    Returns:
        Dictionary with user account details

    Example:
        get_account_information()
    """
    try:
        client = get_client()
        result = await client.get_user_info()

        return {
            "status": "success",
            "account": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def update_account_settings(
    settings: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Update user account settings

    Args:
        settings: Settings to update (preferences, notifications, etc.)

    Returns:
        Dictionary with updated user settings

    Example:
        update_account_settings(
            settings={
                "emailNotifications": True,
                "timezone": "America/New_York"
            }
        )
    """
    try:
        client = get_client()
        result = await client.update_user_settings(settings=settings)

        return {
            "status": "success",
            "settings_updated": True,
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def get_api_usage_limits() -> Dict[str, Any]:
    """
    Get API usage limits and current usage

    View your API rate limits, post quotas, and current usage.

    Returns:
        Dictionary with API limits and usage data

    Example:
        get_api_usage_limits()
    """
    try:
        client = get_client()
        result = await client.get_api_limits()

        return {
            "status": "success",
            "limits": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Utils API Tools

@mcp.tool()
async def verify_media_accessibility(
    url: str,
) -> Dict[str, Any]:
    """
    Verify media URL accessibility and format

    Check if a media URL is accessible, has correct format, and meets
    Ayrshare's requirements before using it in a post.

    Args:
        url: Media URL to verify

    Returns:
        Dictionary with verification result

    Example:
        verify_media_accessibility(url="https://example.com/image.jpg")
    """
    try:
        client = get_client()
        result = await client.verify_media_url(url=url)

        return {
            "status": "success",
            "url": url,
            "valid": result.get("valid", True),
            "issues": result.get("issues", []),
            "details": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def list_available_timezones() -> Dict[str, Any]:
    """
    Get list of available timezones

    View all supported timezone identifiers for scheduling posts.

    Returns:
        Dictionary with timezone list

    Example:
        list_available_timezones()
    """
    try:
        client = get_client()
        timezones = await client.get_timezones()

        return {
            "status": "success",
            "total_timezones": len(timezones),
            "timezones": timezones,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def convert_time_between_timezones(
    time: str,
    from_tz: str,
    to_tz: str,
) -> Dict[str, Any]:
    """
    Convert time between timezones

    Useful for scheduling posts across different time zones.

    Args:
        time: Time string in ISO 8601 format
        from_tz: Source timezone (e.g., "America/New_York")
        to_tz: Target timezone (e.g., "Europe/London")

    Returns:
        Dictionary with converted time

    Example:
        convert_time_between_timezones(
            time="2025-01-15T14:00:00",
            from_tz="America/New_York",
            to_tz="Europe/London"
        )
    """
    try:
        client = get_client()
        result = await client.convert_timezone(time=time, from_tz=from_tz, to_tz=to_tz)

        return {
            "status": "success",
            "original_time": time,
            "from_timezone": from_tz,
            "to_timezone": to_tz,
            "converted_time": result.get("convertedTime"),
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# Validate API Tools

@mcp.tool()
async def validate_post_before_publishing(
    post_data: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Validate post parameters before publishing

    Pre-flight check to identify potential issues before posting.

    Args:
        post_data: Post data to validate (post, platforms, mediaUrls, etc.)

    Returns:
        Dictionary with validation result

    Example:
        validate_post_before_publishing(
            post_data={
                "post": "Hello, world!",
                "platforms": ["facebook", "twitter"],
                "mediaUrls": ["https://example.com/image.jpg"]
            }
        )
    """
    try:
        client = get_client()
        result = await client.validate_post(post_data=post_data)

        return {
            "status": "success",
            "valid": result.get("valid", True),
            "issues": result.get("issues", []),
            "warnings": result.get("warnings", []),
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def validate_media_for_platform(
    media_url: str,
    platform: str,
) -> Dict[str, Any]:
    """
    Validate media for specific platform

    Check if media meets platform-specific requirements.

    Args:
        media_url: Media URL to validate
        platform: Target platform (facebook, instagram, twitter, etc.)

    Returns:
        Dictionary with validation result

    Example:
        validate_media_for_platform(
            media_url="https://example.com/video.mp4",
            platform="instagram"
        )
    """
    try:
        client = get_client()
        result = await client.validate_media(media_url=media_url, platform=platform)

        return {
            "status": "success",
            "media_url": media_url,
            "platform": platform,
            "valid": result.get("valid", True),
            "issues": result.get("issues", []),
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


@mcp.tool()
async def validate_schedule_datetime(
    schedule_date: str,
    platform: str,
) -> Dict[str, Any]:
    """
    Validate schedule time for platform

    Check if schedule date/time is valid for the target platform.

    Args:
        schedule_date: Schedule date in ISO 8601 format
        platform: Target platform

    Returns:
        Dictionary with validation result

    Example:
        validate_schedule_datetime(
            schedule_date="2025-12-25T10:00:00Z",
            platform="facebook"
        )
    """
    try:
        client = get_client()
        result = await client.validate_schedule_time(
            schedule_date=schedule_date,
            platform=platform,
        )

        return {
            "status": "success",
            "schedule_date": schedule_date,
            "platform": platform,
            "valid": result.get("valid", True),
            "issues": result.get("issues", []),
            "result": result,
        }

    except AyrshareError as e:
        return {"status": "error", "message": str(e)}


# ============================================================================
# MCP RESOURCES - Dynamic Data Access
# ============================================================================


@mcp.resource("ayrshare://analytics/dashboard/{period}")
async def get_analytics_dashboard(uri: str) -> str:
    """
    Real-time analytics dashboard with aggregated metrics

    URI Patterns:
    - ayrshare://analytics/dashboard/daily - Last 24 hours
    - ayrshare://analytics/dashboard/weekly - Last 7 days
    - ayrshare://analytics/dashboard/monthly - Last 30 days
    - ayrshare://analytics/dashboard/quarterly - Last 90 days

    Returns comprehensive analytics across all platforms including
    engagement rates, reach, impressions, and top-performing content.
    """
    try:
        # Extract period from URI
        period = uri.split("/")[-1]

        period_days = {
            "daily": 1,
            "weekly": 7,
            "monthly": 30,
            "quarterly": 90,
        }

        days = period_days.get(period, 7)

        client = get_client()
        history = await client.get_history(last_days=days)

        if not history:
            return f"No data available for {period} period."

        # Aggregate metrics
        total_posts = len(history)
        platforms_used = set()
        successful_posts = 0
        failed_posts = 0
        scheduled_posts = 0

        for post in history:
            status = post.get("status", "")
            if status == "success":
                successful_posts += 1
            elif status == "error" or status == "failed":
                failed_posts += 1
            elif status == "scheduled" or status == "pending":
                scheduled_posts += 1

            platforms_used.update(post.get("platforms", []))

        # Build dashboard
        result = [
            f"# Analytics Dashboard - {period.title()} Report",
            f"*Data for last {days} days*\n",
            "## Overview",
            f"- **Total Posts**: {total_posts}",
            f"- **Successful**: {successful_posts} ({successful_posts/total_posts*100:.1f}%)" if total_posts > 0 else "- **Successful**: 0",
            f"- **Failed**: {failed_posts}",
            f"- **Scheduled**: {scheduled_posts}",
            f"- **Platforms Used**: {len(platforms_used)} ({', '.join(sorted(platforms_used))})\n",
            "## Performance Metrics",
            f"- **Success Rate**: {successful_posts/total_posts*100:.1f}%" if total_posts > 0 else "- **Success Rate**: N/A",
            f"- **Average Posts per Day**: {total_posts/days:.1f}",
            f"- **Posting Consistency**: {'High' if total_posts/days >= 2 else 'Medium' if total_posts/days >= 1 else 'Low'}\n",
        ]

        # Top platforms
        platform_counts = {}
        for post in history:
            for platform in post.get("platforms", []):
                platform_counts[platform] = platform_counts.get(platform, 0) + 1

        if platform_counts:
            result.append("## Platform Breakdown")
            sorted_platforms = sorted(platform_counts.items(), key=lambda x: x[1], reverse=True)
            for platform, count in sorted_platforms[:5]:
                percentage = (count / total_posts * 100) if total_posts > 0 else 0
                result.append(f"- **{platform.title()}**: {count} posts ({percentage:.1f}%)")
            result.append("")

        # Recent activity
        result.append("## Recent Activity")
        for post in history[:5]:
            result.append(f"- {post.get('created', 'Unknown date')}: {post.get('status', 'unknown').title()} on {', '.join(post.get('platforms', []))}")

        return "\n".join(result)

    except AyrshareError as e:
        return f"Error fetching analytics dashboard: {str(e)}"


@mcp.resource("ayrshare://calendar/{year}/{month}")
async def get_content_calendar(uri: str) -> str:
    """
    Content calendar for scheduled posts

    URI Pattern:
    - ayrshare://calendar/2024/12 - December 2024
    - ayrshare://calendar/2025/01 - January 2025

    Shows all scheduled posts for the specified month in a calendar view.
    Great for content planning and visualization.
    """
    try:
        # Extract year and month from URI
        parts = uri.split("/")
        year = parts[-2]
        month = parts[-1]

        client = get_client()
        scheduled = await client.get_scheduled_posts()

        if not scheduled:
            return f"No scheduled posts found for {year}-{month}."

        # Filter posts for the requested month
        month_posts = []
        target_prefix = f"{year}-{month}"

        for post in scheduled:
            schedule_date = post.get("scheduleDate", "")
            if schedule_date.startswith(target_prefix):
                month_posts.append(post)

        if not month_posts:
            return f"No scheduled posts found for {year}-{month}."

        # Build calendar view
        result = [
            f"# Content Calendar - {year}/{month}",
            f"*{len(month_posts)} scheduled posts*\n",
        ]

        # Group by date
        posts_by_date = {}
        for post in month_posts:
            schedule_date = post.get("scheduleDate", "")
            date_part = schedule_date.split("T")[0]  # Get YYYY-MM-DD
            if date_part not in posts_by_date:
                posts_by_date[date_part] = []
            posts_by_date[date_part].append(post)

        # Display posts by date
        for date in sorted(posts_by_date.keys()):
            day_posts = posts_by_date[date]
            result.append(f"## {date} ({len(day_posts)} posts)")

            for post in day_posts:
                time_part = post.get("scheduleDate", "").split("T")[1][:5] if "T" in post.get("scheduleDate", "") else "00:00"
                platforms = ", ".join(post.get("platforms", []))
                content = post.get("post", "")[:60] + "..." if len(post.get("post", "")) > 60 else post.get("post", "")

                result.append(f"- **{time_part}** [{platforms}]: {content}")

            result.append("")

        return "\n".join(result)

    except AyrshareError as e:
        return f"Error fetching content calendar: {str(e)}"


@mcp.resource("ayrshare://profiles/overview")
async def get_profiles_overview() -> str:
    """
    Overview of all customer profiles for multi-tenant management

    Shows all user profiles with their connected platforms, activity status,
    and usage statistics. Critical for SaaS management and customer monitoring.
    """
    try:
        client = get_client()
        profiles = await client.list_profiles(has_active_social_accounts=True, limit=100)

        if not profiles:
            return "No customer profiles found. Create profiles using the create_user_profile tool."

        # Build overview
        result = [
            "# Customer Profiles Overview",
            f"*Total Profiles: {len(profiles)}*\n",
        ]

        # Profile summary
        total_platforms = 0
        active_profiles = 0
        inactive_profiles = 0

        for profile in profiles:
            connected = profile.get("activeSocialAccounts", [])
            if connected:
                active_profiles += 1
                total_platforms += len(connected)
            else:
                inactive_profiles += 1

        result.extend([
            "## Summary",
            f"- **Active Profiles**: {active_profiles}",
            f"- **Inactive Profiles**: {inactive_profiles}",
            f"- **Total Connected Platforms**: {total_platforms}",
            f"- **Average Platforms per Profile**: {total_platforms/active_profiles:.1f}" if active_profiles > 0 else "- **Average Platforms per Profile**: 0\n",
        ])

        # List each profile
        result.append("## Profile Details")
        for profile in profiles:
            title = profile.get("title", "Unnamed Profile")
            ref_id = profile.get("refId", "N/A")
            created = profile.get("created", "Unknown")
            platforms = profile.get("activeSocialAccounts", [])

            result.append(f"\n### {title}")
            result.append(f"- **Ref ID**: {ref_id}")
            result.append(f"- **Created**: {created}")

            if platforms:
                result.append(f"- **Connected Platforms** ({len(platforms)}): {', '.join(platforms)}")
            else:
                result.append("- **Connected Platforms**: None")

        return "\n".join(result)

    except AyrshareError as e:
        return f"Error fetching profiles overview: {str(e)}"


# ============================================================================
# MCP PROMPTS - LLM Workflow Templates
# ============================================================================


@mcp.prompt()
def create_social_post(
    topic: str,
    platform: str,
    tone: str = "professional",
    target_audience: str = "general",
    call_to_action: str = "",
    include_hashtags: bool = True
) -> str:
    """
    Generate platform-optimized social media post content

    Creates a prompt for an LLM to generate engaging social media content
    optimized for specific platforms with proper formatting, hashtags, and CTAs.

    Args:
        topic: The main topic or subject of the post
        platform: Target platform (facebook, twitter, linkedin, instagram, tiktok)
        tone: Desired tone (professional, casual, funny, inspiring, educational)
        target_audience: Description of target audience
        call_to_action: Optional CTA to include
        include_hashtags: Whether to include hashtags (default: True)

    Returns:
        Prompt string for LLM to generate the post
    """
    platform_specs = {
        "twitter": {
            "char_limit": 280,
            "best_practices": [
                "Be concise and punchy",
                "Use 1-2 relevant hashtags",
                "Include mentions when appropriate",
                "Front-load important information"
            ],
            "style": "conversational and concise"
        },
        "facebook": {
            "char_limit": 63206,
            "best_practices": [
                "Tell a story",
                "Ask questions to encourage engagement",
                "Use minimal hashtags (0-2)",
                "Include emojis sparingly"
            ],
            "style": "friendly and engaging storytelling"
        },
        "linkedin": {
            "char_limit": 3000,
            "best_practices": [
                "Lead with value and insights",
                "Use 3-5 professional hashtags",
                "Include data or statistics when relevant",
                "End with thought-provoking questions"
            ],
            "style": "professional thought leadership"
        },
        "instagram": {
            "char_limit": 2200,
            "best_practices": [
                "Focus on visual storytelling",
                "Use 10-30 relevant hashtags",
                "Include emojis strategically",
                "Break text into readable chunks with line breaks"
            ],
            "style": "visual-first with engaging caption"
        },
        "tiktok": {
            "char_limit": 2200,
            "best_practices": [
                "Be authentic and relatable",
                "Use 3-5 trending hashtags",
                "Keep it short and attention-grabbing",
                "Embrace trends and challenges"
            ],
            "style": "fun, trendy, and authentic"
        }
    }

    specs = platform_specs.get(platform.lower(), platform_specs["facebook"])

    prompt_parts = [
        f"Create an engaging social media post for {platform.title()}:\n",
        f"**Topic**: {topic}",
        f"**Tone**: {tone}",
        f"**Target Audience**: {target_audience}",
        f"**Character Limit**: {specs['char_limit']}",
        f"**Style**: {specs['style']}\n",
        "**Best Practices for this platform**:"
    ]

    for practice in specs['best_practices']:
        prompt_parts.append(f"- {practice}")

    prompt_parts.append("\n**Requirements**:")
    prompt_parts.append("1. Stay within character limit")
    prompt_parts.append(f"2. Match the {tone} tone")
    prompt_parts.append(f"3. Appeal to {target_audience}")
    prompt_parts.append("4. Optimize for engagement and shareability")

    if call_to_action:
        prompt_parts.append(f"5. Include this call-to-action: {call_to_action}")

    if include_hashtags:
        prompt_parts.append("6. Include platform-appropriate hashtags")

    prompt_parts.append("\n**Output Format**:")
    prompt_parts.append("Return ONLY the final post text, ready to publish. Do not include any explanations or meta-commentary.")

    return "\n".join(prompt_parts)


@mcp.prompt()
def analyze_performance(
    post_analytics: str,
    time_period: str = "last 30 days",
    platform: str = "all platforms"
) -> str:
    """
    Analyze social media performance and provide actionable insights

    Creates a prompt for an LLM to interpret analytics data and provide
    strategic recommendations for improving social media performance.

    Args:
        post_analytics: JSON or text with analytics data (engagement, reach, etc.)
        time_period: Time period covered by the data
        platform: Specific platform or "all platforms"

    Returns:
        Prompt string for LLM to analyze performance
    """
    return f"""Analyze this social media performance data and provide actionable insights:

**Time Period**: {time_period}
**Platform**: {platform}

**Analytics Data**:
{post_analytics}

**Analysis Requirements**:

1. **Performance Overview**
   - Summarize key metrics (engagement rate, reach, impressions)
   - Identify best and worst performing content
   - Compare to industry benchmarks if possible

2. **Trends & Patterns**
   - What content types perform best?
   - What posting times show highest engagement?
   - Which platforms are most effective?
   - Are there any concerning trends?

3. **Audience Insights**
   - What does engagement tell us about the audience?
   - Which demographics are most responsive?
   - What topics resonate most?

4. **Actionable Recommendations**
   - Specific strategies to improve engagement
   - Content suggestions based on performance data
   - Posting schedule optimizations
   - Platform-specific tactical improvements

5. **Next Steps**
   - Top 3-5 priority actions to implement
   - Expected impact of each recommendation
   - Timeline for implementation

**Output Format**:
Provide a clear, structured analysis with specific numbers and percentages. Focus on actionable insights rather than generic advice. Be data-driven and strategic."""


if __name__ == "__main__":
    # Run server
    # For STDIO (Claude Desktop): mcp.run()
    # For HTTP: mcp.run(transport="http")
    import sys

    transport = "http" if "--http" in sys.argv else "stdio"
    mcp.run(transport=transport)
