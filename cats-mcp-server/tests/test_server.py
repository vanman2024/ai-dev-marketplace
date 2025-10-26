"""
Tests for CATS MCP Server

Run with: pytest tests/
"""

import pytest
from unittest.mock import AsyncMock, patch


@pytest.mark.asyncio
async def test_server_imports():
    """Test that server module can be imported"""
    import server
    assert server.mcp is not None
    assert server.mcp.name == "CATS API Server"


@pytest.mark.asyncio
async def test_health_check_without_config():
    """Test health_check tool when API is not configured"""
    import server

    # Access the actual function from the decorated tool
    health_check_fn = server.health_check.fn

    with patch("server.CATS_API_URL", ""), patch("server.CATS_API_KEY", ""):
        result = await health_check_fn()
        assert result["status"] in ["unhealthy", "error"]


@pytest.mark.asyncio
async def test_make_cats_request_missing_config():
    """Test that make_cats_request raises error when config is missing"""
    from server import make_cats_request, CATSAPIError

    with patch("server.CATS_API_URL", ""), patch("server.CATS_API_KEY", ""):
        with pytest.raises(CATSAPIError) as exc_info:
            await make_cats_request("GET", "/test")
        assert "not configured" in str(exc_info.value).lower()


def test_server_configuration():
    """Test server configuration resource"""
    import server

    # Access the actual function from the decorated resource
    get_server_settings_fn = server.get_server_settings.fn

    settings = get_server_settings_fn()
    assert settings["server_name"] == "CATS API Server"
    assert settings["version"] == "0.1.0"
    assert settings["transport"] == "HTTP"
    assert "health_check" in settings["tools"]
    assert "list_candidates" in settings["tools"]
    assert "get_job" in settings["tools"]


def test_decorated_functions_exist():
    """Test that decorated functions are registered"""
    import server

    # Verify decorated tools exist and have the .fn attribute
    assert hasattr(server, 'health_check')
    assert hasattr(server.health_check, 'fn')

    assert hasattr(server, 'list_candidates')
    assert hasattr(server.list_candidates, 'fn')

    assert hasattr(server, 'get_job')
    assert hasattr(server.get_job, 'fn')

    # Verify decorated resource exists
    assert hasattr(server, 'get_server_settings')
    assert hasattr(server.get_server_settings, 'fn')


def test_server_has_required_constants():
    """Test that server has required configuration constants"""
    import server

    assert hasattr(server, 'CATS_API_URL')
    assert hasattr(server, 'CATS_API_KEY')
    assert hasattr(server, 'mcp')
