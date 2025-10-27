"""
Tests for MCP resource functions

Comprehensive tests for 2 Ayrshare MCP resources:
- ayrshare://history
- ayrshare://platforms
"""

import pytest
from unittest.mock import AsyncMock, patch
from src.ayrshare_client import AyrshareError


@pytest.mark.resources
@pytest.mark.asyncio
class TestHistoryResource:
    """Tests for ayrshare://history resource"""

    async def test_history_with_posts(self, mcp_client):
        """Test retrieving post history with data"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_history.return_value = [
                {
                    "id": "post-1",
                    "post": "First test post with some content about products",
                    "status": "published",
                    "platforms": ["facebook", "twitter"],
                    "created": "2024-01-15T10:00:00Z",
                },
                {
                    "id": "post-2",
                    "post": "Second test post scheduled for future",
                    "status": "scheduled",
                    "platforms": ["linkedin"],
                    "created": "2024-01-16T10:00:00Z",
                    "scheduled": "2024-01-20T15:00:00Z",
                },
            ]
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://history")

            assert "Post History (Last 30 Days)" in result
            assert "post-1" in result
            assert "post-2" in result
            assert "facebook, twitter" in result
            assert "scheduled" in result

    async def test_history_empty(self, mcp_client):
        """Test retrieving empty post history"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_history.return_value = []
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://history")

            assert "No posts found in the last 30 days" in result

    async def test_history_with_long_content(self, mcp_client):
        """Test history with long post content (truncated)"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            long_content = "A" * 200  # Longer than 100 chars
            mock_client.get_history.return_value = [
                {
                    "id": "long-post",
                    "post": long_content,
                    "status": "published",
                    "platforms": ["facebook"],
                    "created": "2024-01-15T10:00:00Z",
                }
            ]
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://history")

            # Content should be truncated to 100 chars with ellipsis
            assert long_content[:100] in result
            assert "..." in result

    async def test_history_error_handling(self, mcp_client):
        """Test error handling in history resource"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_history.side_effect = AyrshareError("API error occurred")
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://history")

            assert "Error fetching history" in result
            assert "API error occurred" in result

    async def test_history_formatting(self, mcp_client):
        """Test history output formatting"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_history.return_value = [
                {
                    "id": "format-test",
                    "post": "Test post content",
                    "status": "published",
                    "platforms": ["facebook", "twitter", "linkedin"],
                    "created": "2024-01-15T10:00:00Z",
                }
            ]
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://history")

            # Check markdown formatting
            assert "## Post ID: format-test" in result
            assert "Status: published" in result
            assert "Platforms: facebook, twitter, linkedin" in result
            assert "Created: 2024-01-15T10:00:00Z" in result
            assert "Content: Test post content..." in result


@pytest.mark.resources
@pytest.mark.asyncio
class TestPlatformsResource:
    """Tests for ayrshare://platforms resource"""

    async def test_platforms_with_connections(self, mcp_client):
        """Test retrieving connected platforms with accounts"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_profiles.return_value = [
                {
                    "title": "Main Account",
                    "profileKey": "main-profile-123",
                    "connectedAccounts": [
                        {
                            "platform": "facebook",
                            "account": "Test Business Page",
                            "status": "active",
                        },
                        {
                            "platform": "twitter",
                            "account": "@testcompany",
                            "status": "active",
                        },
                        {
                            "platform": "linkedin",
                            "account": "Test Company LLC",
                            "status": "active",
                        },
                    ],
                }
            ]
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://platforms")

            assert "Connected Social Media Profiles" in result
            assert "Main Account" in result
            assert "main-profile-123" in result
            assert "facebook: Test Business Page (active)" in result
            assert "twitter: @testcompany (active)" in result
            assert "linkedin: Test Company LLC (active)" in result

    async def test_platforms_multiple_profiles(self, mcp_client):
        """Test multiple profiles with different connections"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_profiles.return_value = [
                {
                    "title": "Personal Profile",
                    "profileKey": "personal-key",
                    "connectedAccounts": [
                        {"platform": "twitter", "account": "@personal", "status": "active"}
                    ],
                },
                {
                    "title": "Business Profile",
                    "profileKey": "business-key",
                    "connectedAccounts": [
                        {"platform": "facebook", "account": "Business Page", "status": "active"},
                        {"platform": "linkedin", "account": "Company", "status": "active"},
                    ],
                },
            ]
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://platforms")

            assert "Personal Profile" in result
            assert "Business Profile" in result
            assert "personal-key" in result
            assert "business-key" in result
            assert result.count("## Profile:") == 2

    async def test_platforms_no_connections(self, mcp_client):
        """Test profile with no connected platforms"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_profiles.return_value = [
                {
                    "title": "Empty Profile",
                    "profileKey": "empty-key",
                    "connectedAccounts": [],
                }
            ]
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://platforms")

            assert "Empty Profile" in result
            assert "No platforms connected to this profile" in result

    async def test_platforms_empty_profiles(self, mcp_client):
        """Test when no profiles exist"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_profiles.return_value = []
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://platforms")

            assert "No connected profiles found" in result
            assert "Ayrshare dashboard" in result

    async def test_platforms_error_handling(self, mcp_client):
        """Test error handling in platforms resource"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_profiles.side_effect = AyrshareError("Failed to fetch profiles")
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://platforms")

            assert "Error fetching profiles" in result
            assert "Failed to fetch profiles" in result

    async def test_platforms_formatting(self, mcp_client):
        """Test platforms output formatting"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_profiles.return_value = [
                {
                    "title": "Format Test Profile",
                    "profileKey": "format-key-456",
                    "connectedAccounts": [
                        {"platform": "instagram", "account": "test_insta", "status": "active"},
                        {"platform": "tiktok", "account": "@test_tiktok", "status": "pending"},
                    ],
                }
            ]
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://platforms")

            # Check markdown formatting
            assert "## Profile: Format Test Profile" in result
            assert "Profile Key: format-key-456" in result
            assert "Connected Platforms (2):" in result
            assert "  - instagram: test_insta (active)" in result
            assert "  - tiktok: @test_tiktok (pending)" in result

    async def test_platforms_missing_fields(self, mcp_client):
        """Test handling of profiles with missing fields"""
        with patch("src.server.get_client") as mock_get_client:
            mock_client = AsyncMock()
            mock_client.get_profiles.return_value = [
                {
                    # Missing title
                    "profileKey": "incomplete-key",
                    "connectedAccounts": [
                        {
                            # Missing account name
                            "platform": "facebook",
                            "status": "active",
                        }
                    ],
                }
            ]
            mock_get_client.return_value = mock_client

            result = await mcp_client.read_resource("ayrshare://platforms")

            # Should handle missing fields gracefully
            assert "Unnamed Profile" in result
            assert "incomplete-key" in result
            assert "facebook:  (active)" in result  # Empty account name
