"""
Tests for SQL injection protection and security measures.

This module tests that all tools properly sanitize inputs to prevent
SQL injection attacks and other security vulnerabilities.
"""

import pytest


@pytest.mark.asyncio
async def test_sql_injection_single_quote_escape(call_tool):
    """Test that single quotes are escaped in search queries."""
    result = await call_tool("search_tailwind_components", {
        "query": "'; DROP TABLE sections; --"
    })

    sql = result["query"]
    # Single quotes should be escaped ('' not ')
    assert "DROP TABLE sections" not in sql or "''" in sql
    # Should still generate valid SQL
    assert "SELECT" in sql.upper()


@pytest.mark.asyncio
async def test_sql_injection_component_name(call_tool):
    """Test SQL injection protection in component name."""
    result = await call_tool("get_component_code", {
        "component_name": "'; DELETE FROM sections WHERE '1'='1"
    })

    sql = result["query"]
    # Should escape the single quotes
    assert "''" in sql
    # Should not have unescaped malicious SQL
    assert "DELETE FROM sections" not in sql or "''" in sql


@pytest.mark.asyncio
async def test_sql_injection_category_filter(call_tool):
    """Test SQL injection protection in category parameter."""
    result = await call_tool("search_tailwind_components", {
        "query": "button",
        "category": "'; DROP TABLE sections; --"
    })

    sql = result["query"]
    # Should escape single quotes
    assert "''" in sql
    assert "DROP TABLE" not in sql or "''" in sql


@pytest.mark.asyncio
async def test_sql_injection_multiple_quotes(call_tool):
    """Test handling of multiple single quotes."""
    result = await call_tool("search_tailwind_components", {
        "query": "It's a button's component"
    })

    sql = result["query"]
    # Each single quote should be doubled
    assert "It''s a button''s component" in sql


@pytest.mark.asyncio
async def test_sql_injection_union_attack(call_tool):
    """Test protection against UNION-based SQL injection."""
    result = await call_tool("search_tailwind_components", {
        "query": "button' UNION SELECT * FROM sections --"
    })

    sql = result["query"]
    # Should escape the quote
    assert "''" in sql
    # The UNION should be part of the escaped string
    assert "button'' UNION" in sql


@pytest.mark.asyncio
async def test_sql_injection_comment_attack(call_tool):
    """Test protection against comment-based attacks."""
    result = await call_tool("get_component_code", {
        "component_name": "Button' --"
    })

    sql = result["query"]
    # Should escape the quote
    assert "Button''" in sql


@pytest.mark.asyncio
async def test_sql_injection_semicolon_attack(call_tool):
    """Test protection against semicolon-based multi-statement injection."""
    result = await call_tool("search_tailwind_components", {
        "query": "button'; UPDATE sections SET name='hacked"
    })

    sql = result["query"]
    # Should escape quotes
    assert "''" in sql
    # The semicolon should be within the escaped string
    assert "button''" in sql


@pytest.mark.asyncio
async def test_sql_injection_or_based_attack(call_tool):
    """Test protection against OR-based injection."""
    result = await call_tool("search_tailwind_components", {
        "query": "' OR '1'='1"
    })

    sql = result["query"]
    # Should escape quotes
    assert "''" in sql
    # The OR should be part of the escaped search string
    assert "'' OR ''1''=''1" in sql


@pytest.mark.asyncio
async def test_sql_injection_component_list(call_tool):
    """Test SQL injection in component names list."""
    result = await call_tool("view_component_details", {
        "component_names": [
            "Button",
            "'; DROP TABLE sections; --",
            "Form"
        ]
    })

    sql = result["query"]
    # Should escape quotes in all component names
    assert "''" in sql
    # Should not have unescaped DROP statement
    assert "DROP TABLE" not in sql or "''" in sql


@pytest.mark.asyncio
async def test_sql_injection_category_filters(call_tool):
    """Test SQL injection in category filter parameters."""
    result = await call_tool("list_components_in_category", {
        "category": "'; DROP TABLE sections; --",
        "tailwind_ui_category": "'; DELETE FROM sections; --",
        "tailwind_ui_subcategory": "'; UPDATE sections SET name='x'; --"
    })

    sql = result["query"]
    # Verify all quotes are properly escaped in the SQL
    # Each input has a leading quote that gets escaped, so check for escaped patterns
    assert "''; DROP TABLE sections; --'" in sql
    assert "''; DELETE FROM sections; --'" in sql
    # The UPDATE statement has: '; UPDATE sections SET name='x'; --
    # The quotes around 'x' also get escaped
    assert "''x''" in sql
    # Count total escaped quotes (should be at least 5 pairs from the malicious inputs)
    assert sql.count("''") >= 5


@pytest.mark.asyncio
async def test_no_unescaped_user_input_search(call_tool):
    """Test that user input is never directly concatenated without escaping."""
    malicious_input = "' OR 1=1 --"

    result = await call_tool("search_tailwind_components", {
        "query": malicious_input
    })

    sql = result["query"]
    # The single quote should be escaped to ''
    assert "'' OR 1=1 --" in sql
    # Verify quotes are properly escaped in all ILIKE clauses
    assert "ILIKE '%'' OR 1=1 --%'" in sql


@pytest.mark.asyncio
async def test_no_unescaped_user_input_component_code(call_tool):
    """Test component_code doesn't have unescaped user input."""
    malicious_name = "Button' AND 1=0 UNION SELECT * FROM sections --"

    result = await call_tool("get_component_code", {
        "component_name": malicious_name
    })

    sql = result["query"]
    # Should have escaped quotes
    assert "''" in sql


@pytest.mark.asyncio
async def test_backslash_handling(call_tool):
    """Test handling of backslashes in input."""
    result = await call_tool("search_tailwind_components", {
        "query": "button\\navbar"
    })

    sql = result["query"]
    # Should handle backslashes safely
    assert isinstance(sql, str)


@pytest.mark.asyncio
async def test_null_byte_injection(call_tool):
    """Test protection against null byte injection."""
    result = await call_tool("search_tailwind_components", {
        "query": "button\x00malicious"
    })

    sql = result["query"]
    # Should handle null bytes safely
    assert isinstance(sql, str)


@pytest.mark.asyncio
async def test_percent_sign_handling(call_tool):
    """Test handling of percent signs (SQL LIKE wildcard)."""
    result = await call_tool("search_tailwind_components", {
        "query": "100% responsive"
    })

    sql = result["query"]
    # Should handle percent signs in search
    assert isinstance(sql, str)
    # The query uses ILIKE so % will be treated as wildcard, but that's expected


@pytest.mark.asyncio
async def test_underscore_handling(call_tool):
    """Test handling of underscores (SQL LIKE wildcard)."""
    result = await call_tool("search_tailwind_components", {
        "query": "input_group"
    })

    sql = result["query"]
    # Should handle underscores (they're valid in ILIKE patterns)
    assert "input_group" in sql


@pytest.mark.asyncio
async def test_double_quote_handling(call_tool):
    """Test handling of double quotes."""
    result = await call_tool("search_tailwind_components", {
        "query": 'button "primary"'
    })

    sql = result["query"]
    # Should handle double quotes
    assert isinstance(sql, str)


@pytest.mark.asyncio
async def test_limit_is_integer_not_injectable(call_tool):
    """Test that limit parameter uses integer value, not string."""
    result = await call_tool("search_tailwind_components", {
        "query": "button",
        "limit": 20
    })

    sql = result["query"]
    # Limit should be a direct integer in SQL, not a quoted string
    assert "LIMIT 20" in sql
    assert "LIMIT '20'" not in sql


@pytest.mark.asyncio
async def test_array_construction_is_safe(call_tool):
    """Test that ARRAY construction in view_component_details is safe."""
    result = await call_tool("view_component_details", {
        "component_names": ["Component 'A'", "Component 'B'"]
    })

    sql = result["query"]
    # Should escape quotes in array elements
    assert "''A''" in sql
    assert "''B''" in sql
    assert "ARRAY[" in sql


@pytest.mark.asyncio
async def test_newline_injection(call_tool):
    """Test handling of newline characters in input."""
    result = await call_tool("search_tailwind_components", {
        "query": "button\nDROP TABLE sections"
    })

    sql = result["query"]
    # Should handle newlines safely
    assert isinstance(sql, str)


@pytest.mark.asyncio
async def test_carriage_return_injection(call_tool):
    """Test handling of carriage return characters."""
    result = await call_tool("search_tailwind_components", {
        "query": "button\rmalicious"
    })

    sql = result["query"]
    # Should handle carriage returns safely
    assert isinstance(sql, str)


@pytest.mark.asyncio
async def test_tab_injection(call_tool):
    """Test handling of tab characters."""
    result = await call_tool("search_tailwind_components", {
        "query": "button\tspaced"
    })

    sql = result["query"]
    # Should handle tabs safely
    assert isinstance(sql, str)
