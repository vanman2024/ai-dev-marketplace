"""
Ayrshare API Client Wrapper

Provides async interface to Ayrshare's social media API.
Handles authentication, request formatting, and error handling.
"""

import os
from typing import Any, Dict, List, Optional
from datetime import datetime

import httpx
from pydantic import BaseModel, Field


class AyrshareError(Exception):
    """Base exception for Ayrshare API errors"""
    pass


class AyrshareAuthError(AyrshareError):
    """Authentication-related errors"""
    pass


class AyrshareValidationError(AyrshareError):
    """Request validation errors"""
    pass


class PostResponse(BaseModel):
    """Response from post creation/update operations"""
    id: str
    status: str
    refId: Optional[str] = None
    errors: Optional[List[Dict[str, Any]]] = None
    warnings: Optional[List[str]] = None


class AnalyticsResponse(BaseModel):
    """Response from analytics queries"""
    data: Dict[str, Any]
    platforms: Optional[List[str]] = None


class AyrshareClient:
    """
    Async client for Ayrshare API

    Handles authentication, request/response formatting, and error handling
    for all Ayrshare API endpoints.
    """

    BASE_URL = "https://app.ayrshare.com/api"

    def __init__(self, api_key: Optional[str] = None, profile_key: Optional[str] = None):
        """
        Initialize Ayrshare client

        Args:
            api_key: Ayrshare API key (defaults to AYRSHARE_API_KEY env var)
            profile_key: Optional profile key for multi-tenant scenarios
        """
        self.api_key = api_key or os.getenv("AYRSHARE_API_KEY")
        if not self.api_key:
            raise AyrshareAuthError(
                "API key required. Set AYRSHARE_API_KEY environment variable or pass api_key parameter."
            )

        self.profile_key = profile_key or os.getenv("AYRSHARE_PROFILE_KEY")
        self.client = httpx.AsyncClient(timeout=30.0)

    def _get_headers(self) -> Dict[str, str]:
        """Build request headers with authentication"""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        if self.profile_key:
            headers["Profile-Key"] = self.profile_key

        return headers

    async def _request(
        self,
        method: str,
        endpoint: str,
        data: Optional[Dict[str, Any]] = None,
        params: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Make authenticated request to Ayrshare API

        Args:
            method: HTTP method (GET, POST, PUT, PATCH, DELETE)
            endpoint: API endpoint path
            data: Request body data
            params: Query parameters

        Returns:
            JSON response as dictionary

        Raises:
            AyrshareAuthError: Authentication failed
            AyrshareValidationError: Invalid request data
            AyrshareError: General API error
        """
        url = f"{self.BASE_URL}/{endpoint.lstrip('/')}"

        try:
            response = await self.client.request(
                method=method,
                url=url,
                headers=self._get_headers(),
                json=data,
                params=params,
            )

            # Handle error responses
            if response.status_code == 401:
                raise AyrshareAuthError("Invalid API key or authentication failed")
            elif response.status_code == 400:
                error_data = response.json() if response.text else {}
                raise AyrshareValidationError(
                    f"Invalid request: {error_data.get('message', response.text)}"
                )
            elif response.status_code >= 400:
                error_data = response.json() if response.text else {}
                raise AyrshareError(
                    f"API error ({response.status_code}): {error_data.get('message', response.text)}"
                )

            response.raise_for_status()
            return response.json() if response.text else {}

        except httpx.HTTPError as e:
            raise AyrshareError(f"HTTP request failed: {str(e)}")

    async def post(
        self,
        post_text: str,
        platforms: List[str],
        media_urls: Optional[List[str]] = None,
        scheduled_date: Optional[str] = None,
        shorten_links: bool = True,
        **kwargs,
    ) -> PostResponse:
        """
        Create and publish a post to social media platforms

        Args:
            post_text: Content of the post
            platforms: List of platforms to post to (e.g., ['facebook', 'twitter', 'linkedin'])
            media_urls: Optional list of image/video URLs to attach
            scheduled_date: Optional ISO 8601 datetime for scheduling (e.g., '2024-12-25T10:00:00Z')
            shorten_links: Whether to shorten URLs in post (default: True)
            **kwargs: Additional platform-specific parameters

        Returns:
            PostResponse with post ID and status
        """
        data = {
            "post": post_text,
            "platforms": platforms,
            "shortenLinks": shorten_links,
            **kwargs,
        }

        if media_urls:
            data["mediaUrls"] = media_urls

        if scheduled_date:
            data["scheduleDate"] = scheduled_date

        response = await self._request("POST", "/post", data=data)
        return PostResponse(**response)

    async def get_post(self, post_id: str) -> Dict[str, Any]:
        """
        Get details of a specific post

        Args:
            post_id: The post ID returned from post creation

        Returns:
            Post details including status and platform-specific data
        """
        return await self._request("GET", f"/post/{post_id}")

    async def delete_post(self, post_id: str, platforms: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Delete a post from specified platforms

        Args:
            post_id: The post ID to delete
            platforms: Optional list of specific platforms to delete from

        Returns:
            Deletion status
        """
        data = {"id": post_id}
        if platforms:
            data["platforms"] = platforms

        return await self._request("DELETE", "/post", data=data)

    async def update_post(
        self,
        post_id: str,
        post_text: Optional[str] = None,
        platforms: Optional[List[str]] = None,
    ) -> PostResponse:
        """
        Update an existing post

        Args:
            post_id: The post ID to update
            post_text: New post content
            platforms: Platforms to update on

        Returns:
            PostResponse with update status
        """
        data = {"id": post_id}
        if post_text:
            data["post"] = post_text
        if platforms:
            data["platforms"] = platforms

        response = await self._request("PATCH", "/post", data=data)
        return PostResponse(**response)

    async def get_analytics_post(
        self,
        post_id: str,
        platforms: Optional[List[str]] = None,
    ) -> AnalyticsResponse:
        """
        Get analytics for a specific post

        Args:
            post_id: The post ID to get analytics for
            platforms: Optional list of platforms to get analytics from

        Returns:
            Analytics data including likes, shares, comments, impressions
        """
        data = {"id": post_id}
        if platforms:
            data["platforms"] = platforms

        response = await self._request("POST", "/analytics/post", data=data)
        return AnalyticsResponse(data=response)

    async def get_analytics_social(
        self,
        platforms: List[str],
    ) -> AnalyticsResponse:
        """
        Get social network analytics across platforms

        Args:
            platforms: List of platforms to get analytics for

        Returns:
            Social network analytics data
        """
        data = {"platforms": platforms}
        response = await self._request("POST", "/analytics/social", data=data)
        return AnalyticsResponse(data=response, platforms=platforms)

    async def get_analytics_profile(
        self,
        platforms: Optional[List[str]] = None,
    ) -> AnalyticsResponse:
        """
        Get profile/account analytics including follower counts and demographics

        Args:
            platforms: Optional list of platforms to get analytics for

        Returns:
            Profile analytics data with follower counts and growth metrics
        """
        data = {}
        if platforms:
            data["platforms"] = platforms

        response = await self._request("POST", "/analytics/profile", data=data)
        return AnalyticsResponse(data=response, platforms=platforms)

    async def get_history(
        self,
        last_days: Optional[int] = 30,
        last_records: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get post history

        Args:
            last_days: Number of days to retrieve (default: 30)
            last_records: Alternative: number of recent records to retrieve

        Returns:
            List of historical posts
        """
        data = {}
        if last_records:
            data["lastRecords"] = last_records
        else:
            data["lastDays"] = last_days

        response = await self._request("POST", "/history", data=data)
        return response.get("posts", [])

    async def retry_post(self, post_id: str) -> PostResponse:
        """
        Retry a failed post

        Args:
            post_id: The post ID to retry

        Returns:
            PostResponse with retry status
        """
        data = {"id": post_id}
        response = await self._request("PUT", "/post", data=data)
        return PostResponse(**response)

    async def copy_post(
        self,
        post_id: str,
        platforms: List[str],
        scheduled_date: Optional[str] = None,
    ) -> PostResponse:
        """
        Copy an existing post to different platforms or reschedule

        Args:
            post_id: The post ID to copy
            platforms: Target platforms for the copy
            scheduled_date: Optional ISO 8601 datetime for scheduling the copy

        Returns:
            PostResponse with new post ID
        """
        data = {"id": post_id, "platforms": platforms}
        if scheduled_date:
            data["scheduleDate"] = scheduled_date

        response = await self._request("POST", "/post/copy", data=data)
        return PostResponse(**response)

    async def bulk_post(
        self,
        posts: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Create multiple posts in bulk

        Args:
            posts: List of post configurations, each with post text, platforms, etc.

        Returns:
            Bulk operation results with individual post statuses
        """
        data = {"posts": posts}
        return await self._request("PUT", "/post/bulk", data=data)

    async def upload_media(
        self,
        file_url: str,
        file_name: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Upload media file to Ayrshare media library

        Args:
            file_url: URL of the media file to upload
            file_name: Optional custom filename

        Returns:
            Upload result with media URL
        """
        data = {"url": file_url}
        if file_name:
            data["fileName"] = file_name

        return await self._request("POST", "/media/upload", data=data)

    async def validate_media_url(self, media_url: str) -> Dict[str, Any]:
        """
        Validate a media URL for accessibility and format

        Args:
            media_url: URL to validate

        Returns:
            Validation result with details
        """
        data = {"url": media_url}
        return await self._request("POST", "/media/validate", data=data)

    async def get_unsplash_image(
        self,
        query: Optional[str] = None,
        image_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get image from Unsplash integration

        Args:
            query: Search query for random relevant image
            image_id: Specific Unsplash image ID

        Returns:
            Unsplash image URL and details
        """
        data = {}
        if query:
            data["query"] = query
        if image_id:
            data["imageId"] = image_id

        return await self._request("POST", "/media/unsplash", data=data)

    async def post_with_auto_hashtag(
        self,
        post_text: str,
        platforms: List[str],
        max_hashtags: int = 2,
        position: str = "auto",
        **kwargs,
    ) -> PostResponse:
        """
        Create post with automatic hashtag generation

        Args:
            post_text: Content of the post
            platforms: List of platforms to post to
            max_hashtags: Maximum number of hashtags (1-10, default: 2)
            position: Where to place hashtags ("auto" or "end")
            **kwargs: Additional post parameters

        Returns:
            PostResponse with post ID and status
        """
        data = {
            "post": post_text,
            "platforms": platforms,
            "autoHashtag": {
                "max": max_hashtags,
                "position": position,
            },
            **kwargs,
        }

        response = await self._request("POST", "/post", data=data)
        return PostResponse(**response)

    async def post_evergreen(
        self,
        post_text: str,
        platforms: List[str],
        repeat: int,
        days_between: int,
        start_date: Optional[str] = None,
        **kwargs,
    ) -> PostResponse:
        """
        Create auto-reposting evergreen content

        Args:
            post_text: Content of the post
            platforms: List of platforms to post to
            repeat: Number of times to repost (1-10)
            days_between: Days between reposts (minimum 2)
            start_date: Optional start date (ISO 8601)
            **kwargs: Additional post parameters

        Returns:
            PostResponse with post ID and scheduled reposts
        """
        data = {
            "post": post_text,
            "platforms": platforms,
            "autoRepost": {
                "repeat": repeat,
                "days": days_between,
            },
            **kwargs,
        }

        if start_date:
            data["autoRepost"]["startDate"] = start_date

        response = await self._request("POST", "/post", data=data)
        return PostResponse(**response)

    async def post_with_first_comment(
        self,
        post_text: str,
        platforms: List[str],
        first_comment: str,
        comment_media_urls: Optional[List[str]] = None,
        **kwargs,
    ) -> PostResponse:
        """
        Create post with automatic first comment

        Args:
            post_text: Content of the post
            platforms: List of platforms to post to
            first_comment: Comment to post immediately after
            comment_media_urls: Optional media for comment (Facebook, LinkedIn, Twitter)
            **kwargs: Additional post parameters

        Returns:
            PostResponse with post ID and status
        """
        data = {
            "post": post_text,
            "platforms": platforms,
            "firstComment": {
                "comment": first_comment,
            },
            **kwargs,
        }

        if comment_media_urls:
            data["firstComment"]["mediaUrls"] = comment_media_urls

        response = await self._request("POST", "/post", data=data)
        return PostResponse(**response)

    async def post_with_approval(
        self,
        post_text: str,
        platforms: List[str],
        notes: Optional[str] = None,
        **kwargs,
    ) -> PostResponse:
        """
        Create post requiring approval before publication

        Args:
            post_text: Content of the post
            platforms: List of platforms to post to
            notes: Optional notes for approver
            **kwargs: Additional post parameters

        Returns:
            PostResponse with post ID in "awaiting approval" status
        """
        data = {
            "post": post_text,
            "platforms": platforms,
            "requiresApproval": True,
            **kwargs,
        }

        if notes:
            data["notes"] = notes

        response = await self._request("POST", "/post", data=data)
        return PostResponse(**response)

    async def approve_post(self, post_id: str) -> PostResponse:
        """
        Approve a post that requires approval

        Args:
            post_id: The post ID to approve

        Returns:
            PostResponse with approved status
        """
        data = {"id": post_id, "approved": True}
        response = await self._request("PATCH", "/post", data=data)
        return PostResponse(**response)

    async def get_profiles(self) -> List[Dict[str, Any]]:
        """
        Get list of user profiles and connected social accounts

        Returns:
            List of profiles with connected platforms
        """
        response = await self._request("GET", "/profiles")
        return response.get("profiles", [])

    # Comments API

    async def get_comments(
        self,
        post_id: str,
        platforms: Optional[List[str]] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get comments on a specific post

        Args:
            post_id: The Ayrshare post ID
            platforms: Optional list of specific platforms to get comments from

        Returns:
            List of comments with comment data
        """
        data = {"id": post_id}
        if platforms:
            data["platforms"] = platforms

        response = await self._request("POST", "/comments", data=data)
        return response.get("comments", [])

    async def add_comment(
        self,
        post_id: str,
        comment_text: str,
        platforms: Optional[List[str]] = None,
    ) -> PostResponse:
        """
        Add a comment to a post

        Args:
            post_id: The Ayrshare post ID or social network post ID
            comment_text: The comment content
            platforms: Optional list of platforms to comment on

        Returns:
            PostResponse with comment ID and status
        """
        data = {"id": post_id, "comment": comment_text}
        if platforms:
            data["platforms"] = platforms

        response = await self._request("POST", "/comments/post", data=data)
        return PostResponse(**response)

    async def reply_to_comment(
        self,
        comment_id: str,
        reply_text: str,
        platform: str,
    ) -> PostResponse:
        """
        Reply to an existing comment

        Args:
            comment_id: The social network comment ID
            reply_text: The reply content
            platform: The platform where the comment exists

        Returns:
            PostResponse with reply ID and status
        """
        data = {"commentId": comment_id, "comment": reply_text, "platform": platform}
        response = await self._request("POST", "/comments/reply", data=data)
        return PostResponse(**response)

    async def delete_comment(
        self,
        comment_id: str,
        platforms: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """
        Delete a comment

        Args:
            comment_id: The Ayrshare comment ID or social network comment ID
            platforms: Optional list of platforms to delete comment from

        Returns:
            Deletion status
        """
        data = {"id": comment_id}
        if platforms:
            data["platforms"] = platforms

        return await self._request("DELETE", "/comments", data=data)

    # Messages API (Business Plan)

    async def send_message(
        self,
        platform: str,
        recipient_id: str,
        message: str,
        media_urls: Optional[List[str]] = None,
    ) -> PostResponse:
        """
        Send a direct message (Facebook, Instagram, Twitter)

        Args:
            platform: Platform to send message on (facebook, instagram, twitter)
            recipient_id: Recipient's ID on the platform
            message: Message content
            media_urls: Optional media attachments

        Returns:
            PostResponse with message ID and status
        """
        data = {"platform": platform, "recipientId": recipient_id, "message": message}
        if media_urls:
            data["mediaUrls"] = media_urls

        response = await self._request("POST", "/messages/send", data=data)
        return PostResponse(**response)

    async def get_conversations(
        self,
        platform: str,
        limit: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get list of message conversations

        Args:
            platform: Platform to get conversations from
            limit: Optional limit on number of conversations

        Returns:
            List of conversation data
        """
        data = {"platform": platform}
        if limit:
            data["limit"] = limit

        response = await self._request("POST", "/messages/conversations", data=data)
        return response.get("conversations", [])

    async def get_conversation_messages(
        self,
        conversation_id: str,
        platform: str,
        limit: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get messages from a specific conversation

        Args:
            conversation_id: The conversation ID
            platform: The platform
            limit: Optional limit on number of messages

        Returns:
            List of messages
        """
        data = {"conversationId": conversation_id, "platform": platform}
        if limit:
            data["limit"] = limit

        response = await self._request("POST", "/messages/get", data=data)
        return response.get("messages", [])

    async def mark_messages_read(
        self,
        message_ids: List[str],
        platform: str,
    ) -> Dict[str, Any]:
        """
        Mark messages as read

        Args:
            message_ids: List of message IDs to mark as read
            platform: The platform

        Returns:
            Status response
        """
        data = {"messageIds": message_ids, "platform": platform}
        return await self._request("POST", "/messages/read", data=data)

    # Reviews API (Google Business Profile)

    async def get_reviews(
        self,
        location_id: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get Google Business Profile reviews

        Args:
            location_id: Optional specific location ID

        Returns:
            List of reviews
        """
        data = {}
        if location_id:
            data["locationId"] = location_id

        response = await self._request("POST", "/reviews", data=data)
        return response.get("reviews", [])

    async def reply_to_review(
        self,
        review_id: str,
        response_text: str,
    ) -> Dict[str, Any]:
        """
        Reply to a Google Business Profile review

        Args:
            review_id: The review ID
            response_text: The reply content

        Returns:
            Reply status
        """
        data = {"reviewId": review_id, "response": response_text}
        return await self._request("POST", "/reviews/reply", data=data)

    async def delete_review_response(
        self,
        review_id: str,
    ) -> Dict[str, Any]:
        """
        Delete a review response

        Args:
            review_id: The review ID

        Returns:
            Deletion status
        """
        data = {"reviewId": review_id}
        return await self._request("DELETE", "/reviews/reply", data=data)

    # Webhooks API (Business Plan)

    async def create_webhook(
        self,
        url: str,
        events: List[str],
    ) -> Dict[str, Any]:
        """
        Create a webhook subscription

        Args:
            url: Webhook endpoint URL
            events: List of events to subscribe to

        Returns:
            Webhook configuration with ID
        """
        data = {"url": url, "events": events}
        return await self._request("POST", "/webhooks", data=data)

    async def list_webhooks(self) -> List[Dict[str, Any]]:
        """
        List configured webhooks

        Returns:
            List of webhook configurations
        """
        response = await self._request("GET", "/webhooks")
        return response.get("webhooks", [])

    async def update_webhook(
        self,
        webhook_id: str,
        url: Optional[str] = None,
        events: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """
        Update webhook configuration

        Args:
            webhook_id: The webhook ID
            url: Optional new URL
            events: Optional new events list

        Returns:
            Updated webhook configuration
        """
        data = {"id": webhook_id}
        if url:
            data["url"] = url
        if events:
            data["events"] = events

        return await self._request("PATCH", "/webhooks", data=data)

    async def delete_webhook(
        self,
        webhook_id: str,
    ) -> Dict[str, Any]:
        """
        Delete a webhook

        Args:
            webhook_id: The webhook ID

        Returns:
            Deletion status
        """
        data = {"id": webhook_id}
        return await self._request("DELETE", "/webhooks", data=data)

    # Links API (Max Pack Add-on)

    async def shorten_link(
        self,
        url: str,
        custom_slug: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create shortened link

        Args:
            url: URL to shorten
            custom_slug: Optional custom slug for short URL

        Returns:
            Shortened URL and details
        """
        data = {"url": url}
        if custom_slug:
            data["customSlug"] = custom_slug

        return await self._request("POST", "/links/shorten", data=data)

    async def get_link_analytics(
        self,
        link_id: str,
    ) -> Dict[str, Any]:
        """
        Get analytics for a shortened link

        Args:
            link_id: The link ID

        Returns:
            Link analytics with click data
        """
        data = {"id": link_id}
        return await self._request("POST", "/links/analytics", data=data)

    # Ads API (Business Plan)

    async def create_ad(
        self,
        post_id: str,
        budget: float,
        duration: int,
        targeting: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Create Facebook ad from existing post

        Args:
            post_id: The post ID to boost
            budget: Ad budget in dollars
            duration: Duration in days
            targeting: Optional targeting parameters

        Returns:
            Ad creation response with ad ID
        """
        data = {"postId": post_id, "budget": budget, "duration": duration}
        if targeting:
            data["targeting"] = targeting

        return await self._request("POST", "/ads/create", data=data)

    async def get_ad_analytics(
        self,
        ad_id: str,
    ) -> Dict[str, Any]:
        """
        Get analytics for an ad

        Args:
            ad_id: The ad ID

        Returns:
            Ad performance metrics
        """
        data = {"id": ad_id}
        return await self._request("POST", "/ads/analytics", data=data)

    async def update_ad(
        self,
        ad_id: str,
        budget: Optional[float] = None,
        status: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Update ad configuration

        Args:
            ad_id: The ad ID
            budget: Optional new budget
            status: Optional new status (active, paused)

        Returns:
            Updated ad configuration
        """
        data = {"id": ad_id}
        if budget:
            data["budget"] = budget
        if status:
            data["status"] = status

        return await self._request("PATCH", "/ads", data=data)

    async def delete_ad(
        self,
        ad_id: str,
    ) -> Dict[str, Any]:
        """
        Delete/stop an ad

        Args:
            ad_id: The ad ID

        Returns:
            Deletion status
        """
        data = {"id": ad_id}
        return await self._request("DELETE", "/ads", data=data)

    # Profiles API (Business Plan)

    async def create_profile(
        self,
        title: str,
        messaging_active: Optional[bool] = None,
        team: Optional[List[str]] = None,
        email: Optional[str] = None,
        disable_social: Optional[List[str]] = None,
        tags: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """
        Create a new user profile (Business Plan required)

        Args:
            title: Profile title/name
            messaging_active: Enable messaging for profile
            team: List of team member emails
            email: Profile email address
            disable_social: List of social networks to disable
            tags: Tags for organizing profiles

        Returns:
            Profile creation response with profile key
        """
        data = {"title": title}
        if messaging_active is not None:
            data["messagingActive"] = messaging_active
        if team:
            data["team"] = team
        if email:
            data["email"] = email
        if disable_social:
            data["disableSocial"] = disable_social
        if tags:
            data["tags"] = tags

        return await self._request("POST", "/profiles/profile", data=data)

    async def list_profiles(
        self,
        title: Optional[str] = None,
        ref_id: Optional[str] = None,
        has_active_social: Optional[bool] = None,
        includes_active_social: Optional[List[str]] = None,
        action_log: Optional[bool] = None,
        limit: Optional[int] = None,
        cursor: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        List user profiles with filtering options (Business Plan required)

        Args:
            title: Filter by profile title
            ref_id: Filter by reference ID
            has_active_social: Filter profiles with active social accounts
            includes_active_social: Filter profiles with specific active platforms
            action_log: Include action log in response
            limit: Limit number of profiles returned
            cursor: Pagination cursor

        Returns:
            List of user profiles
        """
        params = {}
        if title:
            params["title"] = title
        if ref_id:
            params["refId"] = ref_id
        if has_active_social is not None:
            params["hasActiveSocial"] = has_active_social
        if includes_active_social:
            params["includesActiveSocial"] = ",".join(includes_active_social)
        if action_log is not None:
            params["actionLog"] = action_log
        if limit:
            params["limit"] = limit
        if cursor:
            params["cursor"] = cursor

        response = await self._request("GET", "/profiles", params=params)
        return response.get("profiles", [])

    async def get_profile_details(
        self,
        profile_key: str,
    ) -> Dict[str, Any]:
        """
        Get specific profile details (Business Plan required)

        Args:
            profile_key: The profile key

        Returns:
            Profile details
        """
        return await self._request("GET", f"/profiles/{profile_key}")

    async def update_profile(
        self,
        profile_key: str,
        settings: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Update profile settings (Business Plan required)

        Args:
            profile_key: The profile key
            settings: Settings to update (title, messagingActive, team, email, etc.)

        Returns:
            Updated profile data
        """
        return await self._request("PATCH", f"/profiles/{profile_key}", data=settings)

    async def delete_profile(
        self,
        profile_key: str,
    ) -> Dict[str, Any]:
        """
        Delete a user profile (Business Plan required)

        Args:
            profile_key: The profile key to delete

        Returns:
            Deletion status
        """
        return await self._request("DELETE", f"/profiles/{profile_key}")

    # History API (Extended)

    async def get_history_by_id(
        self,
        history_id: str,
    ) -> Dict[str, Any]:
        """
        Get specific post details from history

        Args:
            history_id: The history ID

        Returns:
            Post details
        """
        return await self._request("GET", f"/history/{history_id}")

    async def get_scheduled_posts(self) -> List[Dict[str, Any]]:
        """
        Get all scheduled posts

        Returns:
            List of scheduled posts
        """
        response = await self._request("GET", "/history/scheduled")
        return response.get("posts", [])

    async def get_auto_repost_series(
        self,
        auto_repost_id: str,
    ) -> List[Dict[str, Any]]:
        """
        Get auto-repost series by ID

        Args:
            auto_repost_id: The auto-repost series ID

        Returns:
            List of posts in the series
        """
        response = await self._request("GET", f"/history/auto-repost/{auto_repost_id}")
        return response.get("posts", [])

    # Media API (Extended)

    async def list_media(
        self,
        limit: Optional[int] = None,
        cursor: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        List all uploaded media files

        Args:
            limit: Limit number of media items
            cursor: Pagination cursor

        Returns:
            List of media items
        """
        params = {}
        if limit:
            params["limit"] = limit
        if cursor:
            params["cursor"] = cursor

        response = await self._request("GET", "/media", params=params)
        return response.get("media", [])

    async def get_media_details(
        self,
        media_id: str,
    ) -> Dict[str, Any]:
        """
        Get specific media details

        Args:
            media_id: The media ID

        Returns:
            Media details
        """
        return await self._request("GET", f"/media/{media_id}")

    async def delete_media(
        self,
        media_id: str,
    ) -> Dict[str, Any]:
        """
        Delete media from library

        Args:
            media_id: The media ID to delete

        Returns:
            Deletion status
        """
        return await self._request("DELETE", f"/media/{media_id}")

    # Auto Schedule API

    async def set_auto_schedule(
        self,
        schedule_config: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Set auto-posting schedule

        Args:
            schedule_config: Schedule configuration (times, days, platforms)

        Returns:
            Schedule creation response
        """
        return await self._request("POST", "/auto-schedule/set", data=schedule_config)

    async def get_auto_schedule(self) -> Dict[str, Any]:
        """
        Get current auto-schedule configuration

        Returns:
            Auto-schedule settings
        """
        return await self._request("GET", "/auto-schedule")

    async def update_auto_schedule(
        self,
        schedule_config: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Update auto-schedule settings

        Args:
            schedule_config: Updated schedule configuration

        Returns:
            Updated schedule
        """
        return await self._request("PUT", "/auto-schedule/update", data=schedule_config)

    async def delete_auto_schedule(self) -> Dict[str, Any]:
        """
        Remove auto-schedule

        Returns:
            Deletion status
        """
        return await self._request("DELETE", "/auto-schedule")

    # Brand API

    async def create_brand_profile(
        self,
        brand_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Create brand profile with assets

        Args:
            brand_data: Brand information (name, logo, colors, etc.)

        Returns:
            Brand profile creation response
        """
        return await self._request("POST", "/brand/create", data=brand_data)

    async def get_brand_assets(self) -> Dict[str, Any]:
        """
        Get brand assets and templates

        Returns:
            Brand assets
        """
        return await self._request("GET", "/brand")

    async def update_brand_settings(
        self,
        brand_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Update brand profile settings

        Args:
            brand_data: Updated brand information

        Returns:
            Updated brand profile
        """
        return await self._request("PUT", "/brand/update", data=brand_data)

    # Feed API

    async def get_social_feed(
        self,
        platform: str,
        limit: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get social media feed from specific platform

        Args:
            platform: Platform name (facebook, instagram, linkedin, twitter)
            limit: Limit number of posts

        Returns:
            List of feed posts
        """
        params = {}
        if limit:
            params["limit"] = limit

        response = await self._request("GET", f"/feed/{platform}", params=params)
        return response.get("posts", [])

    async def get_all_feeds(
        self,
        limit: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Get feeds from all connected platforms

        Args:
            limit: Limit number of posts per platform

        Returns:
            Feeds from all platforms
        """
        params = {}
        if limit:
            params["limit"] = limit

        response = await self._request("GET", "/feed", params=params)
        return response

    # Generate API (Max Pack Add-on)

    async def generate_post_text(
        self,
        prompt: str,
        platform: Optional[str] = None,
        tone: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Generate post text using AI (Max Pack required)

        Args:
            prompt: Content prompt
            platform: Target platform for optimization
            tone: Desired tone (professional, casual, friendly, etc.)

        Returns:
            Generated post text
        """
        data = {"prompt": prompt}
        if platform:
            data["platform"] = platform
        if tone:
            data["tone"] = tone

        return await self._request("POST", "/generate/text", data=data)

    async def generate_hashtags(
        self,
        content: str,
        count: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Generate hashtags for content (Max Pack required)

        Args:
            content: Post content
            count: Number of hashtags to generate

        Returns:
            Generated hashtags
        """
        data = {"content": content}
        if count:
            data["count"] = count

        return await self._request("POST", "/generate/hashtags", data=data)

    async def generate_caption(
        self,
        image_url: str,
        style: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Generate caption for image (Max Pack required)

        Args:
            image_url: URL of image
            style: Caption style

        Returns:
            Generated caption
        """
        data = {"imageUrl": image_url}
        if style:
            data["style"] = style

        return await self._request("POST", "/generate/caption", data=data)

    # Hashtags API

    async def suggest_hashtags(
        self,
        content: str,
        platform: Optional[str] = None,
    ) -> List[str]:
        """
        Get hashtag suggestions for content

        Args:
            content: Post content
            platform: Target platform

        Returns:
            List of suggested hashtags
        """
        data = {"content": content}
        if platform:
            data["platform"] = platform

        response = await self._request("POST", "/hashtags/suggest", data=data)
        return response.get("hashtags", [])

    async def get_trending_hashtags(
        self,
        platform: str,
        region: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get trending hashtags for platform

        Args:
            platform: Platform name
            region: Optional region filter

        Returns:
            List of trending hashtags
        """
        params = {"platform": platform}
        if region:
            params["region"] = region

        response = await self._request("GET", "/hashtags/trending", params=params)
        return response.get("hashtags", [])

    async def analyze_hashtag_performance(
        self,
        hashtag: str,
        time_range: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Analyze hashtag performance metrics

        Args:
            hashtag: Hashtag to analyze (with or without #)
            time_range: Time range for analysis (7d, 30d, 90d)

        Returns:
            Hashtag performance data
        """
        data = {"hashtag": hashtag}
        if time_range:
            data["timeRange"] = time_range

        return await self._request("POST", "/hashtags/analyze", data=data)

    # User API

    async def get_user_info(self) -> Dict[str, Any]:
        """
        Get user account information

        Returns:
            User account details
        """
        return await self._request("GET", "/user")

    async def update_user_settings(
        self,
        settings: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Update user account settings

        Args:
            settings: Settings to update

        Returns:
            Updated user settings
        """
        return await self._request("PUT", "/user/update", data=settings)

    async def get_api_limits(self) -> Dict[str, Any]:
        """
        Get API usage limits and current usage

        Returns:
            API limits and usage data
        """
        return await self._request("GET", "/user/limits")

    # Utils API

    async def verify_media_url(
        self,
        url: str,
    ) -> Dict[str, Any]:
        """
        Verify media URL accessibility

        Args:
            url: Media URL to verify

        Returns:
            Verification result
        """
        data = {"url": url}
        return await self._request("POST", "/utils/verify-media", data=data)

    async def get_timezones(self) -> List[str]:
        """
        Get list of available timezones

        Returns:
            List of timezone identifiers
        """
        response = await self._request("GET", "/utils/timezones")
        return response.get("timezones", [])

    async def convert_timezone(
        self,
        time: str,
        from_tz: str,
        to_tz: str,
    ) -> Dict[str, Any]:
        """
        Convert time between timezones

        Args:
            time: Time string (ISO 8601)
            from_tz: Source timezone
            to_tz: Target timezone

        Returns:
            Converted time
        """
        data = {"time": time, "fromTimezone": from_tz, "toTimezone": to_tz}
        return await self._request("POST", "/utils/convert-time", data=data)

    # Validate API

    async def validate_post(
        self,
        post_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Validate post parameters before publishing

        Args:
            post_data: Post data to validate

        Returns:
            Validation result
        """
        return await self._request("POST", "/validate/post", data=post_data)

    async def validate_media(
        self,
        media_url: str,
        platform: str,
    ) -> Dict[str, Any]:
        """
        Validate media for specific platform

        Args:
            media_url: Media URL
            platform: Target platform

        Returns:
            Validation result
        """
        data = {"url": media_url, "platform": platform}
        return await self._request("POST", "/validate/media", data=data)

    async def validate_schedule_time(
        self,
        schedule_date: str,
        platform: str,
    ) -> Dict[str, Any]:
        """
        Validate schedule time for platform

        Args:
            schedule_date: Schedule date (ISO 8601)
            platform: Target platform

        Returns:
            Validation result
        """
        data = {"scheduleDate": schedule_date, "platform": platform}
        return await self._request("POST", "/validate/schedule", data=data)

    async def close(self):
        """Close the HTTP client"""
        await self.client.aclose()

    async def __aenter__(self):
        """Context manager entry"""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        await self.close()
