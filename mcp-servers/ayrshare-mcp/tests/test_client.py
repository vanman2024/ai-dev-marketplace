"""
Tests for AyrshareClient class

Unit tests for the Ayrshare API client including:
- Authentication and configuration
- HTTP request handling
- Error handling and validation
- All client methods
"""

import pytest
import httpx
from unittest.mock import AsyncMock, patch, MagicMock
from src.ayrshare_client import (
    AyrshareClient,
    AyrshareError,
    AyrshareAuthError,
    AyrshareValidationError,
    PostResponse,
    AnalyticsResponse,
)


@pytest.mark.client
@pytest.mark.unit
class TestAyrshareClientInit:
    """Tests for AyrshareClient initialization"""

    def test_init_with_api_key(self, mock_env):
        """Test client initialization with API key"""
        client = AyrshareClient(api_key="test-key-123")
        assert client.api_key == "test-key-123"
        assert client.profile_key is not None  # From mock_env

    def test_init_with_env_var(self, mock_env):
        """Test client initialization from environment variable"""
        client = AyrshareClient()
        assert client.api_key == "test-api-key-12345"  # From mock_env fixture

    def test_init_missing_api_key(self, monkeypatch):
        """Test client initialization fails without API key"""
        monkeypatch.delenv("AYRSHARE_API_KEY", raising=False)

        with pytest.raises(AyrshareAuthError) as exc_info:
            AyrshareClient()

        assert "API key required" in str(exc_info.value)

    def test_init_with_profile_key(self, mock_env):
        """Test client initialization with profile key"""
        client = AyrshareClient(profile_key="custom-profile-key")
        assert client.profile_key == "custom-profile-key"

    def test_headers_basic(self, mock_env):
        """Test basic request headers"""
        client = AyrshareClient(api_key="test-key")
        headers = client._get_headers()

        assert headers["Authorization"] == "Bearer test-key"
        assert headers["Content-Type"] == "application/json"

    def test_headers_with_profile_key(self, mock_env):
        """Test headers with profile key"""
        client = AyrshareClient(api_key="test-key", profile_key="profile-123")
        headers = client._get_headers()

        assert headers["Profile-Key"] == "profile-123"


@pytest.mark.client
@pytest.mark.unit
@pytest.mark.asyncio
class TestAyrshareClientRequests:
    """Tests for AyrshareClient HTTP request handling"""

    async def test_request_success(self, mock_env):
        """Test successful API request"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client.client, "request") as mock_request:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.text = '{"result": "success"}'
            mock_response.json.return_value = {"result": "success"}
            mock_request.return_value = mock_response

            result = await client._request("GET", "/test")

            assert result == {"result": "success"}
            mock_request.assert_called_once()

    async def test_request_401_auth_error(self, mock_env):
        """Test 401 authentication error"""
        client = AyrshareClient(api_key="invalid-key")

        with patch.object(client.client, "request") as mock_request:
            mock_response = MagicMock()
            mock_response.status_code = 401
            mock_request.return_value = mock_response

            with pytest.raises(AyrshareAuthError) as exc_info:
                await client._request("GET", "/test")

            assert "Invalid API key" in str(exc_info.value)

    async def test_request_400_validation_error(self, mock_env):
        """Test 400 validation error"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client.client, "request") as mock_request:
            mock_response = MagicMock()
            mock_response.status_code = 400
            mock_response.text = '{"message": "Missing required field"}'
            mock_response.json.return_value = {"message": "Missing required field"}
            mock_request.return_value = mock_response

            with pytest.raises(AyrshareValidationError) as exc_info:
                await client._request("POST", "/post", data={})

            assert "Invalid request" in str(exc_info.value)
            assert "Missing required field" in str(exc_info.value)

    async def test_request_500_server_error(self, mock_env):
        """Test 500 server error"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client.client, "request") as mock_request:
            mock_response = MagicMock()
            mock_response.status_code = 500
            mock_response.text = '{"message": "Internal server error"}'
            mock_response.json.return_value = {"message": "Internal server error"}
            mock_request.return_value = mock_response

            with pytest.raises(AyrshareError) as exc_info:
                await client._request("GET", "/test")

            assert "API error (500)" in str(exc_info.value)

    async def test_request_http_error(self, mock_env):
        """Test HTTP connection error"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client.client, "request") as mock_request:
            mock_request.side_effect = httpx.HTTPError("Connection failed")

            with pytest.raises(AyrshareError) as exc_info:
                await client._request("GET", "/test")

            assert "HTTP request failed" in str(exc_info.value)


@pytest.mark.client
@pytest.mark.unit
@pytest.mark.asyncio
class TestAyrshareClientPost:
    """Tests for post-related client methods"""

    async def test_post_basic(self, mock_env):
        """Test basic post creation"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "post-123",
                "status": "success",
                "refId": "ref-456",
            }

            result = await client.post(
                post_text="Test post",
                platforms=["facebook", "twitter"],
            )

            assert isinstance(result, PostResponse)
            assert result.id == "post-123"
            assert result.status == "success"

    async def test_post_with_media(self, mock_env):
        """Test post with media URLs"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "post-media-789",
                "status": "success",
            }

            await client.post(
                post_text="Post with image",
                platforms=["instagram"],
                media_urls=["https://example.com/image.jpg"],
            )

            call_args = mock_request.call_args
            assert "mediaUrls" in call_args[1]["data"]

    async def test_post_scheduled(self, mock_env):
        """Test scheduled post"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "scheduled-post",
                "status": "scheduled",
            }

            await client.post(
                post_text="Future post",
                platforms=["linkedin"],
                scheduled_date="2025-12-25T10:00:00Z",
            )

            call_args = mock_request.call_args
            assert "scheduleDate" in call_args[1]["data"]

    async def test_get_post(self, mock_env):
        """Test getting post details"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {"id": "post-123", "status": "published"}

            result = await client.get_post("post-123")

            assert result["id"] == "post-123"
            mock_request.assert_called_with("GET", "/post/post-123")

    async def test_delete_post(self, mock_env):
        """Test deleting a post"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {"deleted": True}

            await client.delete_post("post-123", platforms=["facebook"])

            call_args = mock_request.call_args
            assert call_args[1]["data"]["id"] == "post-123"
            assert "facebook" in call_args[1]["data"]["platforms"]

    async def test_update_post(self, mock_env):
        """Test updating a post"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "post-123",
                "status": "updated",
            }

            result = await client.update_post(
                post_id="post-123",
                post_text="Updated text",
            )

            assert isinstance(result, PostResponse)
            assert result.status == "updated"


@pytest.mark.client
@pytest.mark.unit
@pytest.mark.asyncio
class TestAyrshareClientAnalytics:
    """Tests for analytics-related client methods"""

    async def test_get_analytics_post(self, mock_env):
        """Test getting post analytics"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "likes": 100,
                "shares": 20,
                "comments": 5,
            }

            result = await client.get_analytics_post("post-123")

            assert isinstance(result, AnalyticsResponse)
            assert result.data["likes"] == 100

    async def test_get_analytics_social(self, mock_env):
        """Test getting social analytics"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "facebook": {"followers": 5000},
                "twitter": {"followers": 3000},
            }

            result = await client.get_analytics_social(["facebook", "twitter"])

            assert isinstance(result, AnalyticsResponse)
            assert result.platforms == ["facebook", "twitter"]

    async def test_get_analytics_profile(self, mock_env):
        """Test getting profile analytics"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "total_followers": 15000,
                "follower_growth": 250,
            }

            result = await client.get_analytics_profile()

            assert isinstance(result, AnalyticsResponse)
            assert result.data["total_followers"] == 15000


@pytest.mark.client
@pytest.mark.unit
@pytest.mark.asyncio
class TestAyrshareClientAdvanced:
    """Tests for advanced client methods"""

    async def test_retry_post(self, mock_env):
        """Test retrying a failed post"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "post-123",
                "status": "success",
            }

            result = await client.retry_post("post-123")

            assert isinstance(result, PostResponse)
            mock_request.assert_called_with("PUT", "/post", data={"id": "post-123"})

    async def test_copy_post(self, mock_env):
        """Test copying a post"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "copy-post-456",
                "status": "success",
            }

            result = await client.copy_post(
                post_id="post-123",
                platforms=["linkedin"],
                scheduled_date="2025-12-26T15:00:00Z",
            )

            assert isinstance(result, PostResponse)
            assert result.id == "copy-post-456"

    async def test_bulk_post(self, mock_env):
        """Test bulk posting"""
        client = AyrshareClient(api_key="test-key")

        posts = [
            {"post": "Post 1", "platforms": ["facebook"]},
            {"post": "Post 2", "platforms": ["twitter"]},
        ]

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "posts": [
                    {"id": "bulk-1", "status": "success"},
                    {"id": "bulk-2", "status": "success"},
                ]
            }

            result = await client.bulk_post(posts)

            assert len(result["posts"]) == 2

    async def test_get_history(self, mock_env):
        """Test getting post history"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "posts": [
                    {"id": "post-1", "status": "published"},
                    {"id": "post-2", "status": "scheduled"},
                ]
            }

            result = await client.get_history(last_days=30)

            assert len(result) == 2
            assert result[0]["id"] == "post-1"

    async def test_upload_media(self, mock_env):
        """Test uploading media"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "url": "https://cdn.ayrshare.com/media/uploaded.jpg",
                "status": "uploaded",
            }

            result = await client.upload_media(
                file_url="https://example.com/source.jpg",
                file_name="custom-name.jpg",
            )

            assert result["url"].startswith("https://cdn.ayrshare.com")

    async def test_validate_media_url(self, mock_env):
        """Test validating media URL"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {"valid": True, "issues": []}

            result = await client.validate_media_url("https://example.com/image.jpg")

            assert result["valid"] is True

    async def test_get_unsplash_image(self, mock_env):
        """Test getting Unsplash image"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "url": "https://images.unsplash.com/photo-test",
                "id": "test-id",
                "photographer": "Test Photographer",
            }

            result = await client.get_unsplash_image(query="nature")

            assert "unsplash.com" in result["url"]

    async def test_post_with_auto_hashtag(self, mock_env):
        """Test posting with auto hashtags"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "hashtag-post",
                "status": "success",
            }

            result = await client.post_with_auto_hashtag(
                post_text="Test post",
                platforms=["instagram"],
                max_hashtags=5,
                position="end",
            )

            assert isinstance(result, PostResponse)
            call_args = mock_request.call_args
            assert "autoHashtag" in call_args[1]["data"]

    async def test_post_evergreen(self, mock_env):
        """Test creating evergreen post"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "evergreen-post",
                "status": "scheduled",
            }

            result = await client.post_evergreen(
                post_text="Evergreen content",
                platforms=["facebook"],
                repeat=5,
                days_between=7,
            )

            assert isinstance(result, PostResponse)
            call_args = mock_request.call_args
            assert "autoRepost" in call_args[1]["data"]

    async def test_post_with_first_comment(self, mock_env):
        """Test posting with first comment"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "comment-post",
                "status": "success",
            }

            result = await client.post_with_first_comment(
                post_text="Main post",
                platforms=["facebook"],
                first_comment="First comment text",
            )

            assert isinstance(result, PostResponse)
            call_args = mock_request.call_args
            assert "firstComment" in call_args[1]["data"]

    async def test_post_with_approval(self, mock_env):
        """Test posting with approval required"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "approval-post",
                "status": "awaiting_approval",
            }

            result = await client.post_with_approval(
                post_text="Needs approval",
                platforms=["facebook"],
                notes="Please review",
            )

            assert isinstance(result, PostResponse)
            call_args = mock_request.call_args
            assert call_args[1]["data"]["requiresApproval"] is True

    async def test_approve_post(self, mock_env):
        """Test approving a post"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "id": "post-123",
                "status": "approved",
            }

            result = await client.approve_post("post-123")

            assert isinstance(result, PostResponse)
            call_args = mock_request.call_args
            assert call_args[1]["data"]["approved"] is True

    async def test_get_profiles(self, mock_env):
        """Test getting user profiles"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client, "_request") as mock_request:
            mock_request.return_value = {
                "profiles": [
                    {"title": "Profile 1", "profileKey": "key-1"},
                    {"title": "Profile 2", "profileKey": "key-2"},
                ]
            }

            result = await client.get_profiles()

            assert len(result) == 2
            assert result[0]["title"] == "Profile 1"


@pytest.mark.client
@pytest.mark.unit
@pytest.mark.asyncio
class TestAyrshareClientContextManager:
    """Tests for client context manager"""

    async def test_context_manager(self, mock_env):
        """Test client as async context manager"""
        async with AyrshareClient(api_key="test-key") as client:
            assert client.api_key == "test-key"
            assert client.client is not None

    async def test_context_manager_closes(self, mock_env):
        """Test client closes on context exit"""
        client = AyrshareClient(api_key="test-key")

        with patch.object(client.client, "aclose") as mock_close:
            async with client:
                pass

            mock_close.assert_called_once()
