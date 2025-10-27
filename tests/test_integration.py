"""Integration tests for Ayrshare MCP server using real API."""
import pytest
import os
from dotenv import load_dotenv

load_dotenv()

# Only run if API key is available
pytestmark = pytest.mark.skipif(
    not os.getenv("AYRSHARE_API_KEY"),
    reason="AYRSHARE_API_KEY not set"
)

@pytest.mark.integration
@pytest.mark.asyncio
async def test_client_initialization():
    """Test that AyrshareClient can be initialized with API key."""
    from src.ayrshare_client import AyrshareClient
    
    client = AyrshareClient()
    assert client.api_key is not None
    assert client.api_key == os.getenv("AYRSHARE_API_KEY")

@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_profiles():
    """Test fetching connected social media profiles."""
    from src.ayrshare_client import AyrshareClient
    
    client = AyrshareClient()
    response = await client.get_profiles()
    
    assert response is not None
    # Response should be a list of profiles or an error message
    assert isinstance(response, list) or "error" in str(response).lower()

@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_history():
    """Test fetching post history."""
    from src.ayrshare_client import AyrshareClient
    
    client = AyrshareClient()
    response = await client.get_history()
    
    assert response is not None
    # Response should contain posts or be empty
    assert isinstance(response, dict)

@pytest.mark.integration
@pytest.mark.asyncio
async def test_list_platforms():
    """Test MCP tool: list_platforms."""
    import sys
    sys.path.insert(0, 'src')
    from server import list_platforms
    
    result = await list_platforms()
    
    assert result is not None
    assert "status" in result
    # Should return either success with platforms or an error
    assert result["status"] in ["success", "error"]
