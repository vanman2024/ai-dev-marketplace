"""
Integration tests for Ayrshare MCP Server

End-to-end workflow tests covering complete user scenarios:
- Creating and managing posts
- Scheduling campaigns
- Analytics workflows
- Media management
- Approval workflows
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from src.ayrshare_client import PostResponse, AnalyticsResponse


@pytest.mark.integration
@pytest.mark.asyncio
class TestPostWorkflow:
    """Integration tests for complete posting workflows"""

    async def test_create_post_get_analytics_workflow(self, mcp_client):
        """Test: Create post -> Get analytics -> Delete post"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Create post
            mock_client.post.return_value = MagicMock(
                id="workflow-post-123",
                status="success",
                refId="ref-workflow",
                errors=None,
                warnings=None,
            )

            create_result = await mcp_client.call_tool(
                "post_to_social",
                {
                    "post_text": "Integration test post",
                    "platforms": ["facebook", "twitter"],
                },
            )

            assert create_result["status"] == "success"
            post_id = create_result["post_id"]

            # Step 2: Get analytics
            mock_client.get_analytics_post.return_value = MagicMock(
                data={
                    "likes": 150,
                    "shares": 25,
                    "comments": 10,
                }
            )
            mock_get_client.return_value = mock_client

            analytics_result = await mcp_client.call_tool(
                "get_post_analytics",
                {"post_id": post_id},
            )

            assert analytics_result["status"] == "success"
            assert analytics_result["analytics"]["likes"] == 150

            # Step 3: Delete post
            mock_client.delete_post.return_value = {"deleted": True}

            delete_result = await mcp_client.call_tool(
                "delete_post",
                {"post_id": post_id},
            )

            assert delete_result["status"] == "success"

    async def test_schedule_copy_workflow(self, mcp_client):
        """Test: Schedule post -> Copy to different platforms"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Schedule post
            mock_client.post.return_value = MagicMock(
                id="scheduled-original",
                status="scheduled",
                refId="ref-sched",
                errors=None,
                warnings=None,
            )

            schedule_result = await mcp_client.call_tool(
                "schedule_post",
                {
                    "post_text": "Scheduled announcement",
                    "platforms": ["facebook"],
                    "scheduled_date": "2025-12-25T10:00:00Z",
                },
            )

            assert schedule_result["status"] == "success"
            original_post_id = schedule_result["post_id"]

            # Step 2: Copy to additional platforms
            mock_client.copy_post.return_value = MagicMock(
                id="copy-post-456",
                status="scheduled",
                refId="ref-copy",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            copy_result = await mcp_client.call_tool(
                "copy_post",
                {
                    "post_id": original_post_id,
                    "platforms": ["twitter", "linkedin"],
                    "scheduled_date": "2025-12-25T11:00:00Z",
                },
            )

            assert copy_result["status"] == "success"
            assert copy_result["original_post_id"] == original_post_id

    async def test_failed_post_retry_workflow(self, mcp_client):
        """Test: Post fails -> Retry post -> Success"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Create post (with warnings/errors)
            mock_client.post.return_value = MagicMock(
                id="failed-post-789",
                status="partial_failure",
                refId="ref-fail",
                errors=[{"platform": "twitter", "error": "API rate limit"}],
                warnings=["Instagram post delayed"],
            )

            post_result = await mcp_client.call_tool(
                "post_to_social",
                {
                    "post_text": "Test post that may fail",
                    "platforms": ["facebook", "twitter", "instagram"],
                },
            )

            assert post_result["status"] == "success"
            post_id = post_result["post_id"]

            # Step 2: Retry failed post
            mock_client.retry_post.return_value = MagicMock(
                id=post_id,
                status="success",
                refId="ref-retry",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            retry_result = await mcp_client.call_tool(
                "retry_post",
                {"post_id": post_id},
            )

            assert retry_result["status"] == "success"
            assert retry_result["retried"] is True


@pytest.mark.integration
@pytest.mark.asyncio
class TestMediaWorkflow:
    """Integration tests for media management workflows"""

    async def test_upload_validate_post_workflow(self, mcp_client):
        """Test: Upload media -> Validate URL -> Post with media"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Upload media
            mock_client.upload_media.return_value = {
                "url": "https://cdn.ayrshare.com/media/uploaded-image.jpg",
                "status": "uploaded",
            }

            upload_result = await mcp_client.call_tool(
                "upload_media",
                {
                    "file_url": "https://example.com/source-image.jpg",
                    "file_name": "product-image.jpg",
                },
            )

            assert upload_result["status"] == "success"
            media_url = upload_result["library_url"]

            # Step 2: Validate media URL
            mock_client.validate_media_url.return_value = {
                "valid": True,
                "issues": [],
            }

            validate_result = await mcp_client.call_tool(
                "validate_media_url",
                {"media_url": media_url},
            )

            assert validate_result["valid"] is True

            # Step 3: Post with validated media
            mock_client.post.return_value = MagicMock(
                id="post-with-media-123",
                status="success",
                refId="ref-media",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            post_result = await mcp_client.call_tool(
                "post_to_social",
                {
                    "post_text": "Check out our new product!",
                    "platforms": ["instagram", "facebook"],
                    "media_urls": [media_url],
                },
            )

            assert post_result["status"] == "success"

    async def test_unsplash_post_workflow(self, mcp_client):
        """Test: Get Unsplash image -> Post with image"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Get Unsplash image
            mock_client.get_unsplash_image.return_value = {
                "url": "https://images.unsplash.com/photo-nature",
                "id": "nature-photo-123",
                "photographer": "John Doe",
                "attribution": "Photo by John Doe on Unsplash",
            }

            unsplash_result = await mcp_client.call_tool(
                "get_unsplash_image",
                {"query": "nature landscape"},
            )

            assert unsplash_result["status"] == "success"
            image_url = unsplash_result["image_url"]
            attribution = unsplash_result["attribution"]

            # Step 2: Post with attribution
            mock_client.post.return_value = MagicMock(
                id="unsplash-post-456",
                status="success",
                refId="ref-unsplash",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            post_text = f"Beautiful nature scenery. {attribution}"
            post_result = await mcp_client.call_tool(
                "post_to_social",
                {
                    "post_text": post_text,
                    "platforms": ["facebook", "twitter"],
                    "media_urls": [image_url],
                },
            )

            assert post_result["status"] == "success"


@pytest.mark.integration
@pytest.mark.asyncio
class TestCampaignWorkflow:
    """Integration tests for campaign management workflows"""

    async def test_bulk_campaign_workflow(self, mcp_client):
        """Test: Create bulk posts -> Get analytics for each"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Create bulk posts
            bulk_posts = [
                {
                    "post": "Campaign post 1: Product announcement",
                    "platforms": ["facebook", "twitter"],
                },
                {
                    "post": "Campaign post 2: Behind the scenes",
                    "platforms": ["instagram"],
                    "mediaUrls": ["https://example.com/bts.jpg"],
                },
                {
                    "post": "Campaign post 3: Customer testimonial",
                    "platforms": ["linkedin"],
                },
            ]

            mock_client.bulk_post.return_value = {
                "posts": [
                    {"id": "bulk-1", "status": "success"},
                    {"id": "bulk-2", "status": "success"},
                    {"id": "bulk-3", "status": "success"},
                ]
            }

            bulk_result = await mcp_client.call_tool(
                "bulk_post",
                {"posts": bulk_posts},
            )

            assert bulk_result["status"] == "success"
            assert bulk_result["total_posts"] == 3

            # Step 2: Get analytics for each post
            mock_client.get_analytics_post.return_value = MagicMock(
                data={"likes": 100, "shares": 20}
            )
            mock_get_client.return_value = mock_client

            for post_result in bulk_result["results"]["posts"]:
                analytics = await mcp_client.call_tool(
                    "get_post_analytics",
                    {"post_id": post_result["id"]},
                )
                assert analytics["status"] == "success"

    async def test_evergreen_campaign_workflow(self, mcp_client):
        """Test: Create evergreen posts -> Monitor with history resource"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Create evergreen posts
            mock_client.post_evergreen.return_value = MagicMock(
                id="evergreen-1",
                status="scheduled",
                refId="ref-evergreen",
                errors=None,
                warnings=None,
            )

            evergreen_result = await mcp_client.call_tool(
                "create_evergreen_post",
                {
                    "post_text": "Timeless business tip",
                    "platforms": ["facebook", "twitter"],
                    "repeat": 10,
                    "days_between": 7,
                },
            )

            assert evergreen_result["status"] == "success"
            assert evergreen_result["evergreen"] is True

            # Step 2: Check history to see scheduled reposts
            mock_client.get_history.return_value = [
                {
                    "id": "evergreen-1",
                    "post": "Timeless business tip",
                    "status": "scheduled",
                    "platforms": ["facebook", "twitter"],
                    "created": "2024-01-15T10:00:00Z",
                    "scheduled": "2024-01-22T10:00:00Z",
                }
            ]
            mock_get_client.return_value = mock_client

            history = await mcp_client.read_resource("ayrshare://history")

            assert "evergreen-1" in history
            assert "scheduled" in history


@pytest.mark.integration
@pytest.mark.asyncio
class TestApprovalWorkflow:
    """Integration tests for approval workflows"""

    async def test_submit_approve_workflow(self, mcp_client):
        """Test: Submit for approval -> Approve -> Publish"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Submit post for approval
            mock_client.post_with_approval.return_value = MagicMock(
                id="approval-post-123",
                status="awaiting_approval",
                refId="ref-approval",
                errors=None,
                warnings=None,
            )

            submit_result = await mcp_client.call_tool(
                "submit_post_for_approval",
                {
                    "post_text": "Sensitive announcement requiring approval",
                    "platforms": ["facebook", "twitter", "linkedin"],
                    "notes": "Please review for brand compliance",
                },
            )

            assert submit_result["status"] == "success"
            assert submit_result["post_status"] == "awaiting_approval"
            post_id = submit_result["post_id"]

            # Step 2: Approve post
            mock_client.approve_post.return_value = MagicMock(
                id=post_id,
                status="approved",
                refId="ref-approved",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            approve_result = await mcp_client.call_tool(
                "approve_post",
                {"post_id": post_id},
            )

            assert approve_result["status"] == "success"
            assert approve_result["approved"] is True

    async def test_submit_update_approve_workflow(self, mcp_client):
        """Test: Submit -> Update content -> Approve"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Submit post
            mock_client.post_with_approval.return_value = MagicMock(
                id="update-approval-456",
                status="awaiting_approval",
                refId="ref-update",
                errors=None,
                warnings=None,
            )

            submit_result = await mcp_client.call_tool(
                "submit_post_for_approval",
                {
                    "post_text": "Original content",
                    "platforms": ["facebook"],
                },
            )

            post_id = submit_result["post_id"]

            # Step 2: Update content before approval
            mock_client.update_post.return_value = MagicMock(
                id=post_id,
                status="awaiting_approval",
                refId="ref-updated",
                errors=None,
                warnings=None,
            )

            update_result = await mcp_client.call_tool(
                "update_post",
                {
                    "post_id": post_id,
                    "post_text": "Updated content after review",
                },
            )

            assert update_result["status"] == "success"

            # Step 3: Approve updated post
            mock_client.approve_post.return_value = MagicMock(
                id=post_id,
                status="approved",
                refId="ref-final",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            approve_result = await mcp_client.call_tool(
                "approve_post",
                {"post_id": post_id},
            )

            assert approve_result["status"] == "success"


@pytest.mark.integration
@pytest.mark.asyncio
class TestAnalyticsWorkflow:
    """Integration tests for analytics workflows"""

    async def test_comprehensive_analytics_workflow(self, mcp_client):
        """Test: Get profile analytics -> Social analytics -> Post analytics"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Get profile analytics
            mock_client.get_analytics_profile.return_value = MagicMock(
                data={
                    "total_followers": 15320,
                    "follower_growth": 234,
                }
            )

            profile_result = await mcp_client.call_tool(
                "get_profile_analytics",
                {},
            )

            assert profile_result["status"] == "success"
            assert profile_result["analytics"]["total_followers"] == 15320

            # Step 2: Get social network analytics
            mock_client.get_analytics_social.return_value = MagicMock(
                data={
                    "facebook": {"followers": 5420, "engagement_rate": 0.045},
                    "twitter": {"followers": 3210, "engagement_rate": 0.038},
                }
            )

            social_result = await mcp_client.call_tool(
                "get_social_analytics",
                {"platforms": ["facebook", "twitter"]},
            )

            assert social_result["status"] == "success"
            assert "analytics" in social_result

            # Step 3: Get specific post analytics
            mock_client.get_analytics_post.return_value = MagicMock(
                data={
                    "likes": 450,
                    "shares": 78,
                    "comments": 23,
                }
            )
            mock_get_client.return_value = mock_client

            post_result = await mcp_client.call_tool(
                "get_post_analytics",
                {"post_id": "top-post-123"},
            )

            assert post_result["status"] == "success"
            assert post_result["analytics"]["likes"] == 450


@pytest.mark.integration
@pytest.mark.asyncio
class TestResourcesWorkflow:
    """Integration tests for resource-based workflows"""

    async def test_history_platforms_workflow(self, mcp_client):
        """Test: Check platforms -> View history -> Create post"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Step 1: Check connected platforms
            mock_client.get_profiles.return_value = [
                {
                    "title": "Main Account",
                    "profileKey": "main-key",
                    "connectedAccounts": [
                        {"platform": "facebook", "account": "Page", "status": "active"},
                        {"platform": "twitter", "account": "@user", "status": "active"},
                    ],
                }
            ]

            platforms_resource = await mcp_client.read_resource("ayrshare://platforms")

            assert "facebook" in platforms_resource
            assert "twitter" in platforms_resource

            # Step 2: View recent history
            mock_client.get_history.return_value = [
                {
                    "id": "recent-post-1",
                    "post": "Recent post content",
                    "status": "published",
                    "platforms": ["facebook"],
                    "created": "2024-01-15T10:00:00Z",
                }
            ]

            history_resource = await mcp_client.read_resource("ayrshare://history")

            assert "recent-post-1" in history_resource

            # Step 3: Create new post to connected platforms
            mock_client.post.return_value = MagicMock(
                id="new-post-789",
                status="success",
                refId="ref-new",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            post_result = await mcp_client.call_tool(
                "post_to_social",
                {
                    "post_text": "New post to connected platforms",
                    "platforms": ["facebook", "twitter"],
                },
            )

            assert post_result["status"] == "success"


@pytest.mark.integration
@pytest.mark.asyncio
class TestAdvancedFeatures:
    """Integration tests for advanced feature combinations"""

    async def test_auto_hashtags_first_comment_workflow(self, mcp_client):
        """Test: Post with auto hashtags + first comment"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()

            # Create post with auto hashtags
            mock_client.post_with_auto_hashtag.return_value = MagicMock(
                id="hashtag-comment-123",
                status="success",
                refId="ref-combo",
                errors=None,
                warnings=None,
            )

            hashtag_result = await mcp_client.call_tool(
                "post_with_auto_hashtags",
                {
                    "post_text": "Exciting product launch announcement",
                    "platforms": ["instagram", "twitter"],
                    "max_hashtags": 5,
                },
            )

            assert hashtag_result["status"] == "success"

            # Add first comment to the post
            mock_client.post_with_first_comment.return_value = MagicMock(
                id="comment-added-456",
                status="success",
                refId="ref-comment",
                errors=None,
                warnings=None,
            )
            mock_get_client.return_value = mock_client

            comment_result = await mcp_client.call_tool(
                "post_with_first_comment",
                {
                    "post_text": "Another post with comment",
                    "platforms": ["facebook"],
                    "first_comment": "Learn more at our website",
                },
            )

            assert comment_result["status"] == "success"
            assert comment_result["first_comment_added"] is True
