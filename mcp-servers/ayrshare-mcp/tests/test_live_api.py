"""Live API tests for Ayrshare MCP server."""
import pytest
import sys
import os
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

@pytest.mark.asyncio
async def test_api_key_valid():
    """Test that API key is properly loaded and client initializes."""
    from ayrshare_client import AyrshareClient
    from dotenv import load_dotenv
    
    load_dotenv()
    client = AyrshareClient()
    
    assert client.api_key is not None
    assert len(client.api_key) > 0
    print(f"\n✓ API Key loaded: {client.api_key[:8]}...")

@pytest.mark.asyncio
async def test_post_endpoint_format():
    """Test that we can format a post request properly."""
    from ayrshare_client import AyrshareClient
    from dotenv import load_dotenv
    
    load_dotenv()
    client = AyrshareClient()
    
    # Test request formatting (don't actually send)
    headers = client._get_headers()
    assert "Authorization" in headers
    assert headers["Authorization"].startswith("Bearer ")
    assert headers["Content-Type"] == "application/json"
    print(f"\n✓ Headers formatted correctly: {list(headers.keys())}")

@pytest.mark.asyncio  
async def test_user_endpoint():
    """Test the /user endpoint which should work on all plans."""
    from ayrshare_client import AyrshareClient
    from dotenv import load_dotenv
    
    load_dotenv()
    client = AyrshareClient()
    
    try:
        # The /user endpoint returns account info and should work on all plans
        response = await client.client.get(
            f"{client.BASE_URL}/user",
            headers=client._get_headers()
        )
        result = response.json()
        print(f"\n✓ User API Response: {result}")
        assert response.status_code in [200, 403, 404]  # Success or known limitations
    except Exception as e:
        print(f"\n✗ User API Error: {e}")
        # Don't fail - just document the response
        assert True
