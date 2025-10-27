"""
Pytest configuration and shared fixtures for Tailwind UI MCP server tests.

This module provides fixtures for testing the FastMCP server using the
in-memory testing pattern (no HTTP server or subprocess needed).
"""

import pytest
from fastmcp import Client


@pytest.fixture
async def mcp_client():
    """
    Create an in-memory FastMCP client for testing.

    This fixture uses FastMCP's Client context manager to create a direct
    in-memory connection to the server, avoiding the need for HTTP servers
    or subprocess management.

    The client's call_tool method returns a CallToolResult object.
    Access the actual result data using the .data attribute.

    Yields:
        Client: FastMCP client instance connected to the server
    """
    from server import mcp

    async with Client(mcp) as client:
        yield client


@pytest.fixture
async def call_tool(mcp_client):
    """
    Helper fixture that wraps call_tool to return the data directly.

    This makes tests cleaner by automatically extracting .data from CallToolResult.

    Args:
        mcp_client: The FastMCP client fixture

    Returns:
        Async function that calls a tool and returns its data
    """
    async def _call_tool(tool_name: str, arguments: dict = None):
        if arguments is None:
            arguments = {}
        result = await mcp_client.call_tool(tool_name, arguments)
        return result.data

    return _call_tool


@pytest.fixture
def sample_component_names():
    """Sample component names for testing."""
    return [
        "Elements - Buttons - Example",
        "Forms - Input_Groups - Simple",
        "Application_UI - Navigation - Navbar"
    ]


@pytest.fixture
def sample_search_queries():
    """Sample search queries for parametrized testing."""
    return [
        "button",
        "form",
        "navbar",
        "pricing",
        "hero section",
        "card"
    ]


@pytest.fixture
def sample_categories():
    """Sample categories for filtering tests."""
    return [
        "application-ui",
        "marketing",
        "ecommerce",
        "page-examples"
    ]


@pytest.fixture
def expected_project_id():
    """Expected Supabase project ID."""
    return "wsmhiiharnhqupdniwgw"
