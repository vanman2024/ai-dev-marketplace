"""
Tests for input validation and parameter handling.

This module tests that tools properly validate inputs, handle edge cases,
and sanitize parameters before generating SQL queries.
"""

import pytest


@pytest.mark.asyncio
async def test_search_empty_query(call_tool):
    """Test search with empty query string."""
    result = await call_tool("search_tailwind_components", {
        "query": ""
    })

    # Should still generate valid SQL
    assert isinstance(result, dict)
    assert "query" in result
    sql = result["query"]
    assert "SELECT" in sql.upper()


@pytest.mark.asyncio
async def test_search_whitespace_query(call_tool):
    """Test search with whitespace-only query."""
    result = await call_tool("search_tailwind_components", {
        "query": "   "
    })

    assert isinstance(result, dict)
    sql = result["query"]
    assert "ILIKE" in sql


@pytest.mark.asyncio
async def test_search_unicode_characters(call_tool):
    """Test search with unicode characters."""
    result = await call_tool("search_tailwind_components", {
        "query": "button🎨"
    })

    assert isinstance(result, dict)
    assert "query" in result


@pytest.mark.asyncio
async def test_search_special_characters(call_tool):
    """Test search with special characters."""
    special_chars = ["@", "#", "$", "%", "&", "*"]

    for char in special_chars:
        result = await call_tool("search_tailwind_components", {
            "query": f"button{char}"
        })
        assert isinstance(result, dict)
        assert "query" in result


@pytest.mark.asyncio
async def test_search_long_query(call_tool):
    """Test search with very long query string."""
    long_query = "button " * 100

    result = await call_tool("search_tailwind_components", {
        "query": long_query
    })

    assert isinstance(result, dict)
    assert "query" in result


@pytest.mark.asyncio
async def test_component_code_empty_name(call_tool):
    """Test get_component_code with empty component name."""
    result = await call_tool("get_component_code", {
        "component_name": ""
    })

    assert isinstance(result, dict)
    sql = result["query"]
    assert "WHERE name = ''" in sql


@pytest.mark.asyncio
async def test_component_code_whitespace_name(call_tool):
    """Test get_component_code with whitespace component name."""
    result = await call_tool("get_component_code", {
        "component_name": "   "
    })

    assert isinstance(result, dict)


@pytest.mark.asyncio
async def test_component_code_special_characters_in_name(call_tool):
    """Test get_component_code with special characters in name."""
    result = await call_tool("get_component_code", {
        "component_name": "Elements - Buttons & Forms"
    })

    assert isinstance(result, dict)
    assert "query" in result


@pytest.mark.asyncio
async def test_list_category_empty_filters(call_tool):
    """Test list_components_in_category with no filters."""
    result = await call_tool("list_components_in_category", {})

    # Should still work, just returns all components (with react_template)
    assert isinstance(result, dict)
    sql = result["query"]
    assert "react_template IS NOT NULL" in sql


@pytest.mark.asyncio
async def test_list_category_empty_string_category(call_tool):
    """Test list_components_in_category with empty string category."""
    result = await call_tool("list_components_in_category", {
        "category": ""
    })

    assert isinstance(result, dict)
    sql = result["query"]
    # Empty string is falsy in Python, so no category filter will be added
    assert "react_template IS NOT NULL" in sql
    # Category filter should not be added for empty string
    assert sql.count("category =") == 0


@pytest.mark.asyncio
async def test_list_category_none_values(call_tool):
    """Test list_components_in_category with None values."""
    result = await call_tool("list_components_in_category", {
        "category": None,
        "tailwind_ui_category": None,
        "tailwind_ui_subcategory": None
    })

    assert isinstance(result, dict)
    sql = result["query"]
    # Should only have the base WHERE clause
    assert "react_template IS NOT NULL" in sql


@pytest.mark.asyncio
async def test_view_component_details_single_item_list(call_tool):
    """Test view_component_details with single-item list."""
    result = await call_tool("view_component_details", {
        "component_names": ["Single Component"]
    })

    assert isinstance(result, dict)
    sql = result["query"]
    assert "WHERE name = ANY(ARRAY['Single Component'])" in sql


@pytest.mark.asyncio
async def test_view_component_details_large_list(call_tool):
    """Test view_component_details with large component list."""
    component_names = [f"Component {i}" for i in range(50)]

    result = await call_tool("view_component_details", {
        "component_names": component_names
    })

    assert isinstance(result, dict)
    sql = result["query"]
    assert "WHERE name = ANY(ARRAY[" in sql


@pytest.mark.asyncio
async def test_view_component_details_duplicate_names(call_tool):
    """Test view_component_details with duplicate component names."""
    result = await call_tool("view_component_details", {
        "component_names": ["Component A", "Component A", "Component B"]
    })

    assert isinstance(result, dict)
    # Should still generate valid SQL (database will deduplicate)
    sql = result["query"]
    assert "WHERE name = ANY(ARRAY[" in sql


@pytest.mark.asyncio
async def test_limit_boundary_values(call_tool):
    """Test limit parameter with boundary values."""
    test_cases = [
        (0, 1),    # Below minimum
        (1, 1),    # Minimum
        (50, 50),  # Normal
        (100, 100),  # Maximum
        (101, 100),  # Above maximum
        (1000, 100),  # Far above maximum
        (-1, 1),   # Negative
        (-100, 1)  # Large negative
    ]

    for input_limit, expected_limit in test_cases:
        result = await call_tool("search_tailwind_components", {
            "query": "button",
            "limit": input_limit
        })

        sql = result["query"]
        assert f"LIMIT {expected_limit}" in sql


@pytest.mark.asyncio
async def test_category_limit_boundary_values(call_tool):
    """Test list_components_in_category limit with boundary values."""
    test_cases = [
        (0, 1),     # Below minimum
        (1, 1),     # Minimum
        (100, 100),  # Normal
        (200, 200),  # Maximum
        (201, 200),  # Above maximum
        (500, 200),  # Far above maximum
        (-1, 1),    # Negative
    ]

    for input_limit, expected_limit in test_cases:
        result = await call_tool("list_components_in_category", {
            "category": "application-ui",
            "limit": input_limit
        })

        sql = result["query"]
        assert f"LIMIT {expected_limit}" in sql


@pytest.mark.asyncio
async def test_format_case_sensitivity(call_tool):
    """Test that format parameter handles different cases."""
    test_cases = ["react", "REACT", "React", "html", "HTML", "Html"]

    for format_input in test_cases:
        result = await call_tool("get_component_code", {
            "component_name": "Test Component",
            "format": format_input
        })

        assert isinstance(result, dict)
        # Should normalize to lowercase
        assert result["format_requested"] in ["react", "html"]


@pytest.mark.asyncio
async def test_component_name_with_numbers(call_tool):
    """Test component name with numbers."""
    result = await call_tool("get_component_code", {
        "component_name": "Button v2.0"
    })

    assert isinstance(result, dict)
    sql = result["query"]
    assert "Button v2.0" in sql


@pytest.mark.asyncio
async def test_component_name_with_hyphens(call_tool):
    """Test component name with hyphens."""
    result = await call_tool("get_component_code", {
        "component_name": "my-component-name"
    })

    assert isinstance(result, dict)
    sql = result["query"]
    assert "my-component-name" in sql


@pytest.mark.asyncio
async def test_component_name_with_underscores(call_tool):
    """Test component name with underscores."""
    result = await call_tool("get_component_code", {
        "component_name": "my_component_name"
    })

    assert isinstance(result, dict)
    sql = result["query"]
    assert "my_component_name" in sql


@pytest.mark.asyncio
async def test_category_with_hyphens(call_tool):
    """Test category parameter with hyphens."""
    result = await call_tool("search_tailwind_components", {
        "query": "button",
        "category": "application-ui"
    })

    sql = result["query"]
    assert "category = 'application-ui'" in sql


@pytest.mark.asyncio
async def test_category_with_spaces(call_tool):
    """Test category parameter with spaces."""
    result = await call_tool("list_components_in_category", {
        "category": "Page Examples"
    })

    sql = result["query"]
    assert "category = 'Page Examples'" in sql


@pytest.mark.asyncio
async def test_parameters_used_field(call_tool):
    """Test that search_tailwind_components includes parameters_used field."""
    result = await call_tool("search_tailwind_components", {
        "query": "button",
        "category": "application-ui",
        "limit": 25
    })

    assert "parameters_used" in result
    params = result["parameters_used"]
    assert params["query"] == "button"
    assert params["category"] == "application-ui"
    assert params["limit"] == 25


@pytest.mark.asyncio
async def test_filters_applied_field(call_tool):
    """Test that list_components_in_category includes filters_applied field."""
    result = await call_tool("list_components_in_category", {
        "category": "application-ui",
        "tailwind_ui_category": "Forms"
    })

    assert "filters_applied" in result
    filters = result["filters_applied"]
    assert filters["category"] == "application-ui"
    assert filters["tailwind_ui_category"] == "Forms"


@pytest.mark.asyncio
async def test_components_requested_field(call_tool):
    """Test that view_component_details includes components_requested field."""
    components = ["Component A", "Component B"]
    result = await call_tool("view_component_details", {
        "component_names": components
    })

    assert "components_requested" in result
    assert result["components_requested"] == components
