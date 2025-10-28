"""
Tests for the server_info tool.

This module tests the server metadata and diagnostic functionality.
"""

import pytest


@pytest.mark.asyncio
async def test_server_info_returns_dict(call_tool):
    """Test that server_info returns a dictionary."""
    result = await call_tool("server_info", {})
    assert isinstance(result, dict)


@pytest.mark.asyncio
async def test_server_info_has_required_fields(call_tool):
    """Test that server_info contains all required fields."""
    result = await call_tool("server_info", {})

    required_fields = [
        "server_name",
        "version",
        "description",
        "database",
        "component_count",
        "categories",
        "available_tools",
        "notes"
    ]

    for field in required_fields:
        assert field in result, f"Missing required field: {field}"


@pytest.mark.asyncio
async def test_server_info_server_name(call_tool):
    """Test that server name is correct."""
    result = await call_tool("server_info", {})
    assert result["server_name"] == "Tailwind UI Components"


@pytest.mark.asyncio
async def test_server_info_version(call_tool):
    """Test that version is present and valid."""
    result = await call_tool("server_info", {})
    assert "version" in result
    assert isinstance(result["version"], str)
    assert len(result["version"]) > 0


@pytest.mark.asyncio
async def test_server_info_database_structure(call_tool):
    """Test that database info has correct structure."""
    result = await call_tool("server_info", {})

    database = result["database"]
    assert isinstance(database, dict)
    assert database["type"] == "Supabase"
    assert database["table"] == "sections"
    assert "project_id" in database
    assert "access_method" in database


@pytest.mark.asyncio
async def test_server_info_database_project_id(call_tool, expected_project_id):
    """Test that database project_id matches expected value."""
    result = await call_tool("server_info", {})
    assert result["database"]["project_id"] == expected_project_id


@pytest.mark.asyncio
async def test_server_info_categories_list(call_tool):
    """Test that categories is a non-empty list."""
    result = await call_tool("server_info", {})

    categories = result["categories"]
    assert isinstance(categories, list)
    assert len(categories) > 0


@pytest.mark.asyncio
async def test_server_info_categories_content(call_tool):
    """Test that categories contain expected values."""
    result = await call_tool("server_info", {})

    categories = result["categories"]
    expected_categories = [
        "Application UI",
        "Marketing",
        "Ecommerce",
        "Forms",
        "Navigation"
    ]

    for expected_cat in expected_categories:
        assert expected_cat in categories, f"Missing category: {expected_cat}"


@pytest.mark.asyncio
async def test_server_info_component_count(call_tool):
    """Test that component count is present and reasonable."""
    result = await call_tool("server_info", {})

    component_count = result["component_count"]
    assert isinstance(component_count, str)
    assert "490" in component_count or "+" in component_count


@pytest.mark.asyncio
async def test_server_info_available_tools(call_tool):
    """Test that available_tools is a list."""
    result = await call_tool("server_info", {})

    available_tools = result["available_tools"]
    assert isinstance(available_tools, list)
    assert len(available_tools) > 0


@pytest.mark.asyncio
async def test_server_info_notes(call_tool):
    """Test that notes field is present and non-empty."""
    result = await call_tool("server_info", {})

    notes = result["notes"]
    assert isinstance(notes, list)
    assert len(notes) > 0
    assert any("Supabase MCP" in note for note in notes)
