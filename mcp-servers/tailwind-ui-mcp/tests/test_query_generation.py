"""
Tests for SQL query generation tools.

This module tests that all tools correctly generate SQL queries with the
proper structure for the Supabase MCP two-server pattern.
"""

import pytest


@pytest.mark.asyncio
async def test_list_categories_returns_query_dict(call_tool):
    """Test that list_tailwind_categories returns a query dictionary."""
    result = await call_tool("list_tailwind_categories", {})

    assert isinstance(result, dict)
    assert "query" in result
    assert "project_id" in result
    assert "tool_to_use" in result


@pytest.mark.asyncio
async def test_list_categories_query_structure(call_tool, expected_project_id):
    """Test the structure of list_tailwind_categories query."""
    result = await call_tool("list_tailwind_categories", {})

    assert result["project_id"] == expected_project_id
    assert result["tool_to_use"] == "mcp__supabase__execute_sql"
    assert "description" in result
    assert isinstance(result["query"], str)


@pytest.mark.asyncio
async def test_list_categories_sql_contains_required_fields(call_tool):
    """Test that list_tailwind_categories SQL contains required fields."""
    result = await call_tool("list_tailwind_categories", {})

    sql = result["query"]
    assert "SELECT" in sql.upper()
    assert "category" in sql
    assert "tailwind_ui_category" in sql
    assert "tailwind_ui_subcategory" in sql
    assert "COUNT(*)" in sql
    assert "FROM sections" in sql
    assert "GROUP BY" in sql
    assert "ORDER BY" in sql


@pytest.mark.asyncio
async def test_search_components_basic(call_tool):
    """Test basic search_tailwind_components functionality."""
    result = await call_tool("search_tailwind_components", {
        "query": "button"
    })

    assert isinstance(result, dict)
    assert "query" in result
    assert "project_id" in result
    assert "tool_to_use" in result


@pytest.mark.asyncio
@pytest.mark.parametrize("search_query", [
    "button",
    "form",
    "navbar",
    "pricing",
    "card",
    "hero section"
])
async def test_search_components_various_queries(call_tool, search_query):
    """Test search_tailwind_components with various search queries."""
    result = await call_tool("search_tailwind_components", {
        "query": search_query
    })

    assert isinstance(result, dict)
    sql = result["query"]

    # Search term should be in SQL (escaped)
    assert "ILIKE" in sql
    assert "SELECT" in sql.upper()
    assert "FROM sections" in sql


@pytest.mark.asyncio
async def test_search_components_with_category(call_tool):
    """Test search_tailwind_components with category filter."""
    result = await call_tool("search_tailwind_components", {
        "query": "button",
        "category": "application-ui"
    })

    sql = result["query"]
    assert "category = 'application-ui'" in sql


@pytest.mark.asyncio
async def test_search_components_with_limit(call_tool):
    """Test search_tailwind_components with custom limit."""
    result = await call_tool("search_tailwind_components", {
        "query": "button",
        "limit": 10
    })

    sql = result["query"]
    assert "LIMIT 10" in sql


@pytest.mark.asyncio
async def test_search_components_limit_clamping_high(call_tool):
    """Test that search limit is clamped to maximum of 100."""
    result = await call_tool("search_tailwind_components", {
        "query": "button",
        "limit": 500
    })

    sql = result["query"]
    assert "LIMIT 100" in sql


@pytest.mark.asyncio
async def test_search_components_limit_clamping_low(call_tool):
    """Test that search limit is clamped to minimum of 1."""
    result = await call_tool("search_tailwind_components", {
        "query": "button",
        "limit": 0
    })

    sql = result["query"]
    assert "LIMIT 1" in sql


@pytest.mark.asyncio
async def test_search_components_limit_negative(call_tool):
    """Test that negative limits are clamped to 1."""
    result = await call_tool("search_tailwind_components", {
        "query": "button",
        "limit": -10
    })

    sql = result["query"]
    assert "LIMIT 1" in sql


@pytest.mark.asyncio
async def test_list_components_in_category_basic(call_tool):
    """Test basic list_components_in_category functionality."""
    result = await call_tool("list_components_in_category", {
        "category": "application-ui"
    })

    assert isinstance(result, dict)
    assert "query" in result
    assert "project_id" in result
    sql = result["query"]
    assert "category = 'application-ui'" in sql


@pytest.mark.asyncio
async def test_list_components_with_tailwind_ui_category(call_tool):
    """Test list_components_in_category with tailwind_ui_category."""
    result = await call_tool("list_components_in_category", {
        "tailwind_ui_category": "Forms"
    })

    sql = result["query"]
    assert "tailwind_ui_category = 'Forms'" in sql


@pytest.mark.asyncio
async def test_list_components_with_subcategory(call_tool):
    """Test list_components_in_category with subcategory."""
    result = await call_tool("list_components_in_category", {
        "tailwind_ui_subcategory": "Input_Groups"
    })

    sql = result["query"]
    assert "tailwind_ui_subcategory = 'Input_Groups'" in sql


@pytest.mark.asyncio
async def test_list_components_all_filters(call_tool):
    """Test list_components_in_category with all filter parameters."""
    result = await call_tool("list_components_in_category", {
        "category": "application-ui",
        "tailwind_ui_category": "Forms",
        "tailwind_ui_subcategory": "Input_Groups"
    })

    sql = result["query"]
    assert "category = 'application-ui'" in sql
    assert "tailwind_ui_category = 'Forms'" in sql
    assert "tailwind_ui_subcategory = 'Input_Groups'" in sql
    assert "AND" in sql  # Multiple filters should be ANDed together


@pytest.mark.asyncio
async def test_list_components_limit_default(call_tool):
    """Test list_components_in_category uses default limit."""
    result = await call_tool("list_components_in_category", {
        "category": "application-ui"
    })

    sql = result["query"]
    assert "LIMIT 50" in sql


@pytest.mark.asyncio
async def test_list_components_custom_limit(call_tool):
    """Test list_components_in_category with custom limit."""
    result = await call_tool("list_components_in_category", {
        "category": "application-ui",
        "limit": 25
    })

    sql = result["query"]
    assert "LIMIT 25" in sql


@pytest.mark.asyncio
async def test_list_components_limit_max(call_tool):
    """Test that list_components limit is clamped to 200."""
    result = await call_tool("list_components_in_category", {
        "category": "application-ui",
        "limit": 500
    })

    sql = result["query"]
    assert "LIMIT 200" in sql


@pytest.mark.asyncio
async def test_view_component_details_single(call_tool):
    """Test view_component_details with single component."""
    result = await call_tool("view_component_details", {
        "component_names": ["Elements - Buttons - Example"]
    })

    assert isinstance(result, dict)
    assert "query" in result
    sql = result["query"]
    assert "SELECT" in sql.upper()
    assert "FROM sections" in sql
    assert "WHERE name = ANY(ARRAY[" in sql


@pytest.mark.asyncio
async def test_view_component_details_multiple(call_tool, sample_component_names):
    """Test view_component_details with multiple components."""
    result = await call_tool("view_component_details", {
        "component_names": sample_component_names
    })

    sql = result["query"]
    assert "WHERE name = ANY(ARRAY[" in sql
    # Should contain all component names
    for name in sample_component_names:
        assert name.replace("'", "''") in sql


@pytest.mark.asyncio
async def test_view_component_details_empty_list(call_tool):
    """Test view_component_details with empty component list."""
    result = await call_tool("view_component_details", {
        "component_names": []
    })

    assert "error" in result
    assert "No component names provided" in result["error"]


@pytest.mark.asyncio
async def test_view_component_details_includes_all_fields(call_tool):
    """Test that view_component_details SQL includes all important fields."""
    result = await call_tool("view_component_details", {
        "component_names": ["Elements - Buttons - Example"]
    })

    sql = result["query"]
    required_fields = [
        "name",
        "description",
        "category",
        "react_template",
        "html_code",
        "dependencies",
        "tags",
        "css_classes"
    ]

    for field in required_fields:
        assert field in sql, f"Missing field in SQL: {field}"


@pytest.mark.asyncio
async def test_get_component_code_default_format(call_tool):
    """Test get_component_code with default format (react)."""
    result = await call_tool("get_component_code", {
        "component_name": "Elements - Buttons - Example"
    })

    assert isinstance(result, dict)
    assert result["format_requested"] == "react"
    sql = result["query"]
    assert "react_template" in sql
    assert "html_code" in sql


@pytest.mark.asyncio
@pytest.mark.parametrize("format_type", ["react", "html"])
async def test_get_component_code_formats(call_tool, format_type):
    """Test get_component_code with different formats."""
    result = await call_tool("get_component_code", {
        "component_name": "Elements - Buttons - Example",
        "format": format_type
    })

    assert result["format_requested"] == format_type
    sql = result["query"]
    assert "FROM sections" in sql
    assert "LIMIT 1" in sql


@pytest.mark.asyncio
async def test_get_component_code_invalid_format(call_tool):
    """Test that invalid format defaults to react."""
    result = await call_tool("get_component_code", {
        "component_name": "Elements - Buttons - Example",
        "format": "invalid"
    })

    assert result["format_requested"] == "react"


@pytest.mark.asyncio
async def test_get_add_instructions_basic(call_tool):
    """Test get_add_instructions basic functionality."""
    result = await call_tool("get_add_instructions", {
        "component_name": "Elements - Buttons - Example"
    })

    assert isinstance(result, dict)
    assert "query" in result
    assert "instructions_template" in result
    sql = result["query"]
    assert "FROM sections" in sql
    assert "LIMIT 1" in sql


@pytest.mark.asyncio
async def test_get_add_instructions_includes_required_fields(call_tool):
    """Test that get_add_instructions SQL includes required fields."""
    result = await call_tool("get_add_instructions", {
        "component_name": "Elements - Buttons - Example"
    })

    sql = result["query"]
    required_fields = [
        "name",
        "description",
        "dependencies",
        "css_classes",
        "react_template"
    ]

    for field in required_fields:
        assert field in sql, f"Missing field in SQL: {field}"


@pytest.mark.asyncio
async def test_get_add_instructions_has_template(call_tool):
    """Test that get_add_instructions includes instructions template."""
    result = await call_tool("get_add_instructions", {
        "component_name": "Elements - Buttons - Example"
    })

    template = result["instructions_template"]
    assert isinstance(template, dict)
    assert "step1" in template
    assert "step2" in template
    assert "step3" in template
    assert "step4" in template
