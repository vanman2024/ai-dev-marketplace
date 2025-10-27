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

    async def close(self):
        """Close the HTTP client"""
        await self.client.aclose()

    async def __aenter__(self):
        """Context manager entry"""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        await self.close()
