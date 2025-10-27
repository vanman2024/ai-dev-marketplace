"""
Tests for MCP tool functions

Comprehensive tests for all 19 Ayrshare MCP tools including:
- Success cases with valid inputs
- Error handling (auth, validation, API errors)
- Edge cases and boundary conditions
- Parametrized tests for multiple scenarios
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from dirty_equals import IsStr, IsPositive, IsList, IsDict
from inline_snapshot import snapshot
from src.ayrshare_client import AyrshareError, AyrshareAuthError, AyrshareValidationError


@pytest.mark.tools
@pytest.mark.asyncio
class TestPostToSocial:
    """Tests for post_to_social tool"""

    async def test_post_success(self, mcp_client, mock_ayrshare_success):
        """Test successful post to multiple platforms"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post.return_value = MagicMock(
                id="post-123",
                status="success",
                refId="ref-456",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "post_to_social",
                {
                    "post_text": "Test post content",
                    "platforms": ["facebook", "twitter"],
                    "shorten_links": True,
                },
            )

            assert result == snapshot({
                "status": "success",
                "post_id": IsStr,
                "post_status": "success",
                "ref_id": IsStr,
                "errors": None,
                "warnings": None,
            })

    async def test_post_with_media(self, mcp_client):
        """Test post with media URLs"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post.return_value = MagicMock(
                id="post-789",
                status="success",
                refId="ref-012",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "post_to_social",
                {
                    "post_text": "Check out this image!",
                    "platforms": ["instagram", "facebook"],
                    "media_urls": ["https://example.com/image.jpg"],
                },
            )

            assert result["status"] == "success"
            assert result["post_id"] == "post-789"

    @pytest.mark.parametrize(
        "invalid_platforms,expected_error",
        [
            (["invalid_platform"], "Invalid platforms"),
            (["facebook", "unknown_social"], "Invalid platforms"),
            (["twitter", "fake_network"], "Invalid platforms"),
        ],
    )
    async def test_invalid_platforms(self, mcp_client, invalid_platforms, expected_error):
        """Test error handling for invalid platforms"""
        result = await mcp_client.call_tool(
            "post_to_social",
            {
                "post_text": "Test post",
                "platforms": invalid_platforms,
            },
        )

        assert result["status"] == "error"
        assert expected_error in result["message"]
        assert "supported_platforms" in result

    async def test_auth_error(self, mcp_client):
        """Test authentication error handling"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post.side_effect = AyrshareAuthError("Invalid API key")
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "post_to_social",
                {
                    "post_text": "Test post",
                    "platforms": ["facebook"],
                },
            )

            assert result["status"] == "error"
            assert "Invalid API key" in result["message"]


@pytest.mark.tools
@pytest.mark.asyncio
class TestSchedulePost:
    """Tests for schedule_post tool"""

    async def test_schedule_success(self, mcp_client):
        """Test successful post scheduling"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post.return_value = MagicMock(
                id="scheduled-123",
                status="scheduled",
                refId="ref-scheduled",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "schedule_post",
                {
                    "post_text": "Future post",
                    "platforms": ["facebook", "twitter"],
                    "scheduled_date": "2025-12-25T10:00:00Z",
                },
            )

            assert result["status"] == "success"
            assert result["post_id"] == "scheduled-123"
            assert result["scheduled_for"] == "2025-12-25T10:00:00Z"

    @pytest.mark.parametrize(
        "invalid_date",
        [
            "not-a-date",
            "2024/12/25",
            "25-12-2024",
            "2024-13-01T10:00:00Z",  # Invalid month
            "invalid-iso-format",
        ],
    )
    async def test_invalid_date_format(self, mcp_client, invalid_date):
        """Test error handling for invalid date formats"""
        result = await mcp_client.call_tool(
            "schedule_post",
            {
                "post_text": "Test post",
                "platforms": ["facebook"],
                "scheduled_date": invalid_date,
            },
        )

        assert result["status"] == "error"
        assert "Invalid date format" in result["message"]

    async def test_schedule_with_media(self, mcp_client):
        """Test scheduled post with media"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post.return_value = MagicMock(
                id="scheduled-media-456",
                status="scheduled",
                refId="ref-media",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "schedule_post",
                {
                    "post_text": "Holiday announcement",
                    "platforms": ["instagram", "facebook"],
                    "scheduled_date": "2025-12-25T09:00:00-05:00",
                    "media_urls": ["https://example.com/holiday.jpg"],
                },
            )

            assert result["status"] == "success"
            assert result["post_status"] == "scheduled"


@pytest.mark.tools
@pytest.mark.asyncio
class TestGetPostAnalytics:
    """Tests for get_post_analytics tool"""

    async def test_analytics_success(self, mcp_client):
        """Test successful analytics retrieval"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_analytics_post.return_value = MagicMock(
                data={
                    "likes": 150,
                    "shares": 25,
                    "comments": 10,
                    "impressions": 5000,
                    "engagement_rate": 0.037,
                }
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "get_post_analytics",
                {
                    "post_id": "post-123",
                },
            )

            assert result["status"] == "success"
            assert result["post_id"] == "post-123"
            assert "analytics" in result
            assert result["analytics"]["likes"] == 150

    async def test_analytics_specific_platforms(self, mcp_client):
        """Test analytics for specific platforms"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_analytics_post.return_value = MagicMock(
                data={"facebook": {"likes": 100}, "twitter": {"likes": 50}}
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "get_post_analytics",
                {
                    "post_id": "post-456",
                    "platforms": ["facebook", "twitter"],
                },
            )

            assert result["status"] == "success"
            assert result["platforms"] == ["facebook", "twitter"]

    async def test_analytics_post_not_found(self, mcp_client):
        """Test analytics for non-existent post"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_analytics_post.side_effect = AyrshareError("Post not found")
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "get_post_analytics",
                {
                    "post_id": "nonexistent-post",
                },
            )

            assert result["status"] == "error"
            assert "Post not found" in result["message"]


@pytest.mark.tools
@pytest.mark.asyncio
class TestDeletePost:
    """Tests for delete_post tool"""

    async def test_delete_success(self, mcp_client):
        """Test successful post deletion"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.delete_post.return_value = {"deleted": True}
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "delete_post",
                {
                    "post_id": "post-to-delete",
                },
            )

            assert result["status"] == "success"
            assert result["post_id"] == "post-to-delete"

    async def test_delete_specific_platforms(self, mcp_client):
        """Test deletion from specific platforms"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.delete_post.return_value = {"deleted": True}
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "delete_post",
                {
                    "post_id": "post-123",
                    "platforms": ["facebook", "twitter"],
                },
            )

            assert result["status"] == "success"
            assert result["deleted_from"] == ["facebook", "twitter"]


@pytest.mark.tools
@pytest.mark.asyncio
class TestListPlatforms:
    """Tests for list_platforms tool"""

    async def test_list_platforms_success(self, mcp_client):
        """Test platform listing"""
        result = await mcp_client.call_tool("list_platforms", {})

        assert result["status"] == "success"
        assert result["total_platforms"] == 13
        assert "platforms" in result
        assert "facebook" in result["platforms"]
        assert "twitter" in result["platforms"]
        assert "instagram" in result["platforms"]

    async def test_platform_capabilities(self, mcp_client):
        """Test platform capability information"""
        result = await mcp_client.call_tool("list_platforms", {})

        facebook = result["platforms"]["facebook"]
        assert facebook["supports_images"] is True
        assert facebook["supports_videos"] is True
        assert facebook["max_chars"] == 63206

        twitter = result["platforms"]["twitter"]
        assert twitter["max_chars"] == 280
        assert "x" in twitter.get("alternatives", [])


@pytest.mark.tools
@pytest.mark.asyncio
class TestGetSocialAnalytics:
    """Tests for get_social_analytics tool"""

    async def test_social_analytics_success(self, mcp_client):
        """Test social network analytics retrieval"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_analytics_social.return_value = MagicMock(
                data={
                    "facebook": {"followers": 5420, "engagement_rate": 0.045},
                    "twitter": {"followers": 3210, "engagement_rate": 0.038},
                }
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "get_social_analytics",
                {
                    "platforms": ["facebook", "twitter"],
                },
            )

            assert result["status"] == "success"
            assert result["platforms"] == ["facebook", "twitter"]
            assert "analytics" in result


@pytest.mark.tools
@pytest.mark.asyncio
class TestGetProfileAnalytics:
    """Tests for get_profile_analytics tool"""

    async def test_profile_analytics_all_platforms(self, mcp_client):
        """Test profile analytics for all platforms"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_analytics_profile.return_value = MagicMock(
                data={"total_followers": 15320, "follower_growth": 234}
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool("get_profile_analytics", {})

            assert result["status"] == "success"
            assert result["platforms"] == "all"

    async def test_profile_analytics_specific_platforms(self, mcp_client):
        """Test profile analytics for specific platforms"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_analytics_profile.return_value = MagicMock(
                data={"linkedin": {"followers": 2540}}
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "get_profile_analytics",
                {
                    "platforms": ["linkedin"],
                },
            )

            assert result["status"] == "success"
            assert result["platforms"] == ["linkedin"]


@pytest.mark.tools
@pytest.mark.asyncio
class TestUpdatePost:
    """Tests for update_post tool"""

    async def test_update_post_text(self, mcp_client):
        """Test updating post content"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.update_post.return_value = MagicMock(
                id="post-123",
                status="updated",
                refId="ref-789",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "update_post",
                {
                    "post_id": "post-123",
                    "post_text": "Updated content",
                },
            )

            assert result["status"] == "success"
            assert result["updated"] is True

    async def test_update_post_platforms(self, mcp_client):
        """Test updating post on specific platforms"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.update_post.return_value = MagicMock(
                id="post-456",
                status="updated",
                refId="ref-012",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "update_post",
                {
                    "post_id": "post-456",
                    "post_text": "New text",
                    "platforms": ["facebook"],
                },
            )

            assert result["status"] == "success"


@pytest.mark.tools
@pytest.mark.asyncio
class TestRetryPost:
    """Tests for retry_post tool"""

    async def test_retry_success(self, mcp_client):
        """Test successful post retry"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.retry_post.return_value = MagicMock(
                id="post-123",
                status="success",
                refId="ref-retry",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "retry_post",
                {
                    "post_id": "post-123",
                },
            )

            assert result["status"] == "success"
            assert result["retried"] is True


@pytest.mark.tools
@pytest.mark.asyncio
class TestCopyPost:
    """Tests for copy_post tool"""

    async def test_copy_post_immediate(self, mcp_client):
        """Test copying post to new platforms immediately"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.copy_post.return_value = MagicMock(
                id="copy-post-789",
                status="success",
                refId="ref-copy",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "copy_post",
                {
                    "post_id": "post-123",
                    "platforms": ["linkedin", "pinterest"],
                },
            )

            assert result["status"] == "success"
            assert result["original_post_id"] == "post-123"
            assert result["new_post_id"] == "copy-post-789"

    async def test_copy_post_scheduled(self, mcp_client):
        """Test copying post with new schedule"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.copy_post.return_value = MagicMock(
                id="copy-scheduled-456",
                status="scheduled",
                refId="ref-copy-sched",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "copy_post",
                {
                    "post_id": "post-original",
                    "platforms": ["twitter"],
                    "scheduled_date": "2025-12-26T15:00:00Z",
                },
            )

            assert result["status"] == "success"
            assert result["scheduled_for"] == "2025-12-26T15:00:00Z"


@pytest.mark.tools
@pytest.mark.asyncio
class TestBulkPost:
    """Tests for bulk_post tool"""

    async def test_bulk_post_success(self, mcp_client):
        """Test bulk posting multiple posts"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.bulk_post.return_value = {
                "posts": [
                    {"id": "bulk-1", "status": "success"},
                    {"id": "bulk-2", "status": "success"},
                ]
            }
            mock_get_client.return_value = mock_client

            posts = [
                {
                    "post": "First bulk post",
                    "platforms": ["facebook", "twitter"],
                },
                {
                    "post": "Second bulk post",
                    "platforms": ["linkedin"],
                    "scheduleDate": "2025-12-25T12:00:00Z",
                },
            ]

            result = await mcp_client.call_tool(
                "bulk_post",
                {
                    "posts": posts,
                },
            )

            assert result["status"] == "success"
            assert result["total_posts"] == 2


@pytest.mark.tools
@pytest.mark.asyncio
class TestUploadMedia:
    """Tests for upload_media tool"""

    async def test_upload_media_success(self, mcp_client):
        """Test successful media upload"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.upload_media.return_value = {
                "url": "https://cdn.ayrshare.com/media/uploaded-image.jpg",
                "status": "uploaded",
            }
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "upload_media",
                {
                    "file_url": "https://example.com/source-image.jpg",
                    "file_name": "product-image.jpg",
                },
            )

            assert result["status"] == "success"
            assert result["uploaded"] is True
            assert "library_url" in result


@pytest.mark.tools
@pytest.mark.asyncio
class TestValidateMediaUrl:
    """Tests for validate_media_url tool"""

    async def test_validate_media_valid(self, mcp_client):
        """Test validation of valid media URL"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.validate_media_url.return_value = {
                "valid": True,
                "issues": [],
            }
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "validate_media_url",
                {
                    "media_url": "https://example.com/valid-image.jpg",
                },
            )

            assert result["status"] == "success"
            assert result["valid"] is True

    async def test_validate_media_invalid(self, mcp_client):
        """Test validation of invalid media URL"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.validate_media_url.return_value = {
                "valid": False,
                "issues": ["URL not accessible", "Invalid image format"],
            }
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "validate_media_url",
                {
                    "media_url": "https://example.com/broken-image.xyz",
                },
            )

            assert result["status"] == "success"
            assert result["valid"] is False
            assert len(result["issues"]) > 0


@pytest.mark.tools
@pytest.mark.asyncio
class TestGetUnsplashImage:
    """Tests for get_unsplash_image tool"""

    async def test_unsplash_by_query(self, mcp_client):
        """Test getting Unsplash image by search query"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_unsplash_image.return_value = {
                "url": "https://images.unsplash.com/photo-sunset",
                "id": "sunset-photo-123",
                "photographer": "John Doe",
                "attribution": "Photo by John Doe on Unsplash",
            }
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "get_unsplash_image",
                {
                    "query": "sunset beach",
                },
            )

            assert result["status"] == "success"
            assert "image_url" in result
            assert result["query"] == "sunset beach"

    async def test_unsplash_by_id(self, mcp_client):
        """Test getting Unsplash image by specific ID"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_unsplash_image.return_value = {
                "url": "https://images.unsplash.com/photo-specific",
                "id": "specific-id-456",
                "photographer": "Jane Smith",
                "attribution": "Photo by Jane Smith on Unsplash",
            }
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "get_unsplash_image",
                {
                    "image_id": "specific-id-456",
                },
            )

            assert result["status"] == "success"
            assert result["image_id"] == "specific-id-456"

    async def test_unsplash_missing_params(self, mcp_client):
        """Test error when neither query nor image_id provided"""
        result = await mcp_client.call_tool("get_unsplash_image", {})

        assert result["status"] == "error"
        assert "query or image_id must be provided" in result["message"]


@pytest.mark.tools
@pytest.mark.asyncio
class TestPostWithAutoHashtags:
    """Tests for post_with_auto_hashtags tool"""

    async def test_auto_hashtags_success(self, mcp_client):
        """Test post with automatic hashtag generation"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post_with_auto_hashtag.return_value = MagicMock(
                id="hashtag-post-123",
                status="success",
                refId="ref-hashtag",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "post_with_auto_hashtags",
                {
                    "post_text": "Excited about our new product!",
                    "platforms": ["twitter", "instagram"],
                    "max_hashtags": 3,
                },
            )

            assert result["status"] == "success"
            assert result["hashtags_generated"] is True

    @pytest.mark.parametrize(
        "max_hashtags,position",
        [
            (1, "auto"),
            (5, "end"),
            (10, "auto"),
        ],
    )
    async def test_auto_hashtags_variations(self, mcp_client, max_hashtags, position):
        """Test auto hashtags with different parameters"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post_with_auto_hashtag.return_value = MagicMock(
                id=f"hashtag-{max_hashtags}",
                status="success",
                refId="ref",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "post_with_auto_hashtags",
                {
                    "post_text": "Test post",
                    "platforms": ["instagram"],
                    "max_hashtags": max_hashtags,
                    "position": position,
                },
            )

            assert result["status"] == "success"
            assert result["max_hashtags"] == max_hashtags


@pytest.mark.tools
@pytest.mark.asyncio
class TestCreateEvergreenPost:
    """Tests for create_evergreen_post tool"""

    async def test_evergreen_post_success(self, mcp_client):
        """Test creating evergreen post with auto-reposting"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post_evergreen.return_value = MagicMock(
                id="evergreen-123",
                status="scheduled",
                refId="ref-evergreen",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "create_evergreen_post",
                {
                    "post_text": "Timeless wisdom quote",
                    "platforms": ["facebook", "twitter"],
                    "repeat": 5,
                    "days_between": 7,
                    "start_date": "2025-12-25T09:00:00Z",
                },
            )

            assert result["status"] == "success"
            assert result["evergreen"] is True
            assert result["repeat_count"] == 5
            assert result["days_between"] == 7


@pytest.mark.tools
@pytest.mark.asyncio
class TestPostWithFirstComment:
    """Tests for post_with_first_comment tool"""

    async def test_post_with_comment_success(self, mcp_client):
        """Test post with automatic first comment"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post_with_first_comment.return_value = MagicMock(
                id="comment-post-123",
                status="success",
                refId="ref-comment",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "post_with_first_comment",
                {
                    "post_text": "New blog post is live!",
                    "platforms": ["facebook", "linkedin"],
                    "first_comment": "Read more at https://blog.example.com",
                },
            )

            assert result["status"] == "success"
            assert result["first_comment_added"] is True

    async def test_post_with_comment_and_media(self, mcp_client):
        """Test first comment with media attachments"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post_with_first_comment.return_value = MagicMock(
                id="comment-media-456",
                status="success",
                refId="ref-comment-media",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "post_with_first_comment",
                {
                    "post_text": "Check out our gallery",
                    "platforms": ["facebook"],
                    "first_comment": "More photos here",
                    "comment_media_urls": ["https://example.com/gallery.jpg"],
                },
            )

            assert result["status"] == "success"


@pytest.mark.tools
@pytest.mark.asyncio
class TestSubmitPostForApproval:
    """Tests for submit_post_for_approval tool"""

    async def test_submit_for_approval_success(self, mcp_client):
        """Test submitting post for approval"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.post_with_approval.return_value = MagicMock(
                id="approval-post-123",
                status="awaiting_approval",
                refId="ref-approval",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "submit_post_for_approval",
                {
                    "post_text": "Sensitive announcement",
                    "platforms": ["facebook", "twitter", "linkedin"],
                    "notes": "Please review for compliance",
                },
            )

            assert result["status"] == "success"
            assert result["post_status"] == "awaiting_approval"


@pytest.mark.tools
@pytest.mark.asyncio
class TestApprovePost:
    """Tests for approve_post tool"""

    async def test_approve_post_success(self, mcp_client):
        """Test approving a post"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.approve_post.return_value = MagicMock(
                id="approved-post-123",
                status="approved",
                refId="ref-approved",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            result = await mcp_client.call_tool(
                "approve_post",
                {
                    "post_id": "approval-post-123",
                },
            )

            assert result["status"] == "success"
            assert result["approved"] is True
