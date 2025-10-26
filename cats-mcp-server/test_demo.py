"""
Demonstration test showing FastMCP in-memory testing pattern works with CATS server.
This validates the testing infrastructure before generating the full test suite.
"""

import pytest
from fastmcp.client import Client
from fastmcp.client.transports import FastMCPTransport

# Import CATS server's mcp instance
from server import mcp


@pytest.fixture
async def mcp_client():
    """In-memory test client for CATS MCP server."""
    async with Client(transport=mcp) as client:
        yield client


async def test_server_connection(mcp_client: Client[FastMCPTransport]):
    """Test that we can connect to the CATS server via in-memory client."""
    # If this passes, the in-memory testing pattern works!
    assert mcp_client is not None


async def test_list_tools_default(mcp_client: Client[FastMCPTransport]):
    """Test that default toolsets load and register tools."""
    tools = await mcp_client.list_tools()
    tool_names = [t.name for t in tools]

    # Should have default toolset tools
    assert len(tools) > 0, "No tools loaded - check toolset loading"

    # Check for a known default tool
    assert "list_candidates" in tool_names, "Candidates toolset not loaded"
    assert "list_jobs" in tool_names, "Jobs toolset not loaded"
    assert "list_pipelines" in tool_names, "Pipelines toolset not loaded"


async def test_tool_execution_mock(mcp_client: Client[FastMCPTransport]):
    """
    Test tool execution pattern (would need API key for real execution).
    This demonstrates the pattern - real tests would mock make_request().
    """
    tools = await mcp_client.list_tools()
    assert any(t.name == "get_site" for t in tools), "get_site tool not found"

    # Note: Actually calling the tool would require valid CATS_API_KEY
    # Real test suite would mock the make_request() function
    # Example pattern:
    # from unittest.mock import patch
    # with patch('server.make_request') as mock_request:
    #     mock_request.return_value = {"id": 123, "name": "Test Site"}
    #     result = await mcp_client.call_tool(name="get_site", arguments={})
    #     assert result.data["name"] == "Test Site"
