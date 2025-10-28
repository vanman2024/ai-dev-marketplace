#!/usr/bin/env python3
"""
Tailwind UI Components MCP Server

This FastMCP server provides natural language access to 490+ Tailwind UI components
stored in a Supabase database. It uses the Supabase MCP server tools to query the
database without direct SQL connections.

Component Registry Details:
- Total Components: 490+ Tailwind UI components
- Categories: Application UI, Marketing, Ecommerce, Page Examples
- Storage: Supabase (Project ID: wsmhiiharnhqupdniwgw)
- Table: sections
- Access Method: Via Supabase MCP tools (mcp__supabase__execute_sql)

Usage:
    Local STDIO: python server.py
    HTTP Server: python server.py --transport http
    Custom Port: python server.py --transport http --port 8001
"""

import os
from typing import Optional
from dotenv import load_dotenv
from fastmcp import FastMCP

# Load environment variables from .env file
load_dotenv()

# Initialize FastMCP server
mcp = FastMCP("Tailwind UI Components")

# Configuration
SUPABASE_PROJECT_ID = os.getenv("SUPABASE_PROJECT_ID", "wsmhiiharnhqupdniwgw")


# ============================================================================
# IMPORTANT: Tool Implementation Notes
# ============================================================================
# This server is designed to work with the Supabase MCP server.
# All database queries should be executed using the Supabase MCP tool:
#   - Tool name: mcp__supabase__execute_sql
#   - Parameters: {sql: "SELECT ...", project_id: "wsmhiiharnhqupdniwgw"}
#
# Tools will be added separately using the /fastmcp:add-components pattern.
# This file provides the base server infrastructure.
#
# Database Schema (sections table):
#   - name: Component name
#   - description: Component description
#   - category: Primary category
#   - tailwind_ui_category: Tailwind UI specific category
#   - tailwind_ui_subcategory: Tailwind UI subcategory
#   - react_template: React/JSX code
#   - html_code: Raw HTML code
#   - tags: Array of searchable tags
#   - dependencies: JSON object of required dependencies
#   - css_classes: Array of Tailwind CSS classes used
# ============================================================================


@mcp.tool()
def server_info() -> dict:
    """
    Get information about this Tailwind UI Components MCP server.

    Returns server metadata, database configuration, and available component statistics.
    This is a diagnostic tool to verify the server is running correctly.

    Returns:
        dict: Server information including:
            - server_name: Name of the MCP server
            - version: Server version
            - database: Supabase project information
            - component_count: Approximate number of components
            - categories: Available component categories
    """
    return {
        "server_name": "Tailwind UI Components",
        "version": "0.1.0",
        "description": "Natural language access to 490+ Tailwind UI components",
        "database": {
            "type": "Supabase",
            "project_id": SUPABASE_PROJECT_ID,
            "table": "sections",
            "access_method": "Supabase MCP Tools (mcp__supabase__execute_sql)"
        },
        "component_count": "490+",
        "categories": [
            "Application UI",
            "Marketing",
            "Ecommerce",
            "Page Examples",
            "Layout",
            "Navigation",
            "Forms",
            "Data Display",
            "Overlays",
            "Elements"
        ],
        "available_tools": [
            "server_info (this tool)",
            "Additional tools will be added via /fastmcp:add-components"
        ],
        "notes": [
            "This server uses Supabase MCP tools for database queries",
            "No direct SQL connection required",
            "All queries go through mcp__supabase__execute_sql",
            "Components include React, HTML, and dependency information"
        ]
    }


@mcp.tool()
def list_tailwind_categories() -> dict:
    """
    List all available Tailwind UI component categories with counts.

    Browse all component categories organized by Tailwind UI's classification system.
    Shows category, subcategory, and count of components in each.

    Returns:
        dict: SQL query to execute via Supabase MCP that returns:
            - project_id: Supabase project to query
            - query: SQL to execute
            - description: What this query does
            - expected_format: Expected result structure

    Example Usage:
        - "List all Tailwind UI categories"
        - "Show me what components are available"
        - "What categories do you have?"
    """
    sql_query = """
    SELECT
        category,
        tailwind_ui_category,
        tailwind_ui_subcategory,
        COUNT(*) as count
    FROM sections
    WHERE react_template IS NOT NULL
    GROUP BY category, tailwind_ui_category, tailwind_ui_subcategory
    ORDER BY count DESC
    """

    return {
        "project_id": SUPABASE_PROJECT_ID,
        "query": sql_query.strip(),
        "description": "Lists all component categories with counts",
        "tool_to_use": "mcp__supabase__execute_sql",
        "expected_format": {
            "total_categories": "Number of unique category combinations",
            "categories": [
                {
                    "category": "application-ui",
                    "tailwind_ui_category": "Forms",
                    "tailwind_ui_subcategory": "Input_Groups",
                    "count": 21
                }
            ]
        }
    }


@mcp.tool()
def search_tailwind_components(
    query: str,
    category: Optional[str] = None,
    limit: int = 20
) -> dict:
    """
    Search for Tailwind UI components by keyword, category, or tag.

    Searches component names, descriptions, and tags for the provided query string.
    Optionally filter by category and limit results.

    Args:
        query: Search term to find in component names, descriptions, or tags
        category: Optional category filter (e.g., 'application-ui', 'marketing')
        limit: Maximum number of results to return (default: 20, max: 100)

    Returns:
        dict: SQL query to execute via Supabase MCP that searches components

    Example Usage:
        - "Search for button components"
        - "Find all pricing sections"
        - "Show me navbar components"
        - "Search for forms with validation"
    """
    # Sanitize inputs for SQL (basic protection, Supabase will do full sanitization)
    query_safe = query.replace("'", "''")
    limit_safe = min(max(1, limit), 100)  # Clamp between 1 and 100

    # Build WHERE clause
    where_clauses = [
        "react_template IS NOT NULL",
        f"(name ILIKE '%{query_safe}%' OR description ILIKE '%{query_safe}%' OR '{query_safe}' = ANY(tags))"
    ]

    if category:
        category_safe = category.replace("'", "''")
        where_clauses.append(f"category = '{category_safe}'")

    where_clause = " AND ".join(where_clauses)

    sql_query = f"""
    SELECT
        name,
        category,
        tailwind_ui_category,
        tailwind_ui_subcategory,
        description,
        tags,
        LENGTH(react_template) as code_length,
        block_type
    FROM sections
    WHERE {where_clause}
    ORDER BY name
    LIMIT {limit_safe}
    """

    return {
        "project_id": SUPABASE_PROJECT_ID,
        "query": sql_query.strip(),
        "description": f"Search for '{query}'" + (f" in category '{category}'" if category else ""),
        "tool_to_use": "mcp__supabase__execute_sql",
        "parameters_used": {
            "query": query,
            "category": category,
            "limit": limit_safe
        }
    }


@mcp.tool()
def list_components_in_category(
    category: Optional[str] = None,
    tailwind_ui_category: Optional[str] = None,
    tailwind_ui_subcategory: Optional[str] = None,
    limit: int = 50
) -> dict:
    """
    Get all components in a specific category or subcategory.

    Filter components by main category, Tailwind UI category, or subcategory.
    At least one filter parameter should be provided for meaningful results.

    Args:
        category: Main category (e.g., 'application-ui', 'marketing')
        tailwind_ui_category: Tailwind UI category (e.g., 'Forms', 'Elements')
        tailwind_ui_subcategory: Subcategory (e.g., 'Input_Groups', 'Buttons')
        limit: Maximum number of results (default: 50)

    Returns:
        dict: SQL query to execute via Supabase MCP that lists category components

    Example Usage:
        - "Show all Form components"
        - "List components in Elements > Buttons"
        - "Get all Navigation components"
    """
    # Build WHERE clause dynamically
    where_clauses = ["react_template IS NOT NULL"]

    if category:
        category_safe = category.replace("'", "''")
        where_clauses.append(f"category = '{category_safe}'")

    if tailwind_ui_category:
        cat_safe = tailwind_ui_category.replace("'", "''")
        where_clauses.append(f"tailwind_ui_category = '{cat_safe}'")

    if tailwind_ui_subcategory:
        subcat_safe = tailwind_ui_subcategory.replace("'", "''")
        where_clauses.append(f"tailwind_ui_subcategory = '{subcat_safe}'")

    where_clause = " AND ".join(where_clauses)
    limit_safe = min(max(1, limit), 200)

    sql_query = f"""
    SELECT
        name,
        description,
        tailwind_ui_category,
        tailwind_ui_subcategory,
        tags,
        LENGTH(react_template) as code_length
    FROM sections
    WHERE {where_clause}
    ORDER BY name
    LIMIT {limit_safe}
    """

    return {
        "project_id": SUPABASE_PROJECT_ID,
        "query": sql_query.strip(),
        "description": "List components in category",
        "tool_to_use": "mcp__supabase__execute_sql",
        "filters_applied": {
            "category": category,
            "tailwind_ui_category": tailwind_ui_category,
            "tailwind_ui_subcategory": tailwind_ui_subcategory
        },
        "limit": limit_safe
    }


@mcp.tool()
def view_component_details(component_names: list[str]) -> dict:
    """
    Get complete details for one or more specific components.

    Retrieves full information including code, dependencies, tags, and metadata
    for the specified component(s).

    Args:
        component_names: List of component names to retrieve details for

    Returns:
        dict: SQL query to execute via Supabase MCP that returns full component details

    Example Usage:
        - "Show me details for Elements - Buttons - Example"
        - "Get info about the pricing section"
        - "View component Forms - Radio_Groups - SimpleList"
    """
    if not component_names:
        return {
            "error": "No component names provided",
            "usage": "Provide at least one component name to view details"
        }

    # Build ARRAY for SQL IN clause
    names_list = []
    for name in component_names:
        safe_name = name.replace("'", "''")
        names_list.append(f"'{safe_name}'")
    names_array = ", ".join(names_list)

    sql_query = f"""
    SELECT
        name,
        description,
        category,
        tailwind_ui_category,
        tailwind_ui_subcategory,
        react_template,
        html_code,
        dependencies,
        tags,
        css_classes,
        block_type,
        app_type,
        LENGTH(react_template) as code_length
    FROM sections
    WHERE name = ANY(ARRAY[{names_array}])
        AND react_template IS NOT NULL
    """

    return {
        "project_id": SUPABASE_PROJECT_ID,
        "query": sql_query.strip(),
        "description": f"View details for {len(component_names)} component(s)",
        "tool_to_use": "mcp__supabase__execute_sql",
        "components_requested": component_names
    }


@mcp.tool()
def get_component_code(
    component_name: str,
    format: str = "react"
) -> dict:
    """
    Get ONLY the code for a component - ready to copy and paste.

    Retrieves just the code (React or HTML) without metadata, perfect for
    direct use in your project.

    Args:
        component_name: Name of the component to get code for
        format: Code format to return - "react" (default) or "html"

    Returns:
        dict: SQL query to execute via Supabase MCP that returns component code

    Example Usage:
        - "Get the code for Elements - Buttons - Example"
        - "Give me the React code for navbar component"
        - "Show code for pricing section"
    """
    if format not in ["react", "html"]:
        format = "react"

    component_safe = component_name.replace("'", "''")

    sql_query = f"""
    SELECT
        name,
        react_template,
        html_code
    FROM sections
    WHERE name = '{component_safe}'
        AND react_template IS NOT NULL
    LIMIT 1
    """

    return {
        "project_id": SUPABASE_PROJECT_ID,
        "query": sql_query.strip(),
        "description": f"Get {format.upper()} code for '{component_name}'",
        "tool_to_use": "mcp__supabase__execute_sql",
        "component_name": component_name,
        "format_requested": format,
        "note": "Extract 'react_template' field for React code, 'html_code' field for HTML"
    }


@mcp.tool()
def get_add_instructions(component_name: str) -> dict:
    """
    Get installation and usage instructions for a component.

    Provides step-by-step instructions for adding the component to your project,
    including dependencies, Tailwind classes used, and usage examples.

    Args:
        component_name: Name of the component to get instructions for

    Returns:
        dict: SQL query to execute via Supabase MCP that returns component instructions

    Example Usage:
        - "How do I use the button component?"
        - "Give me instructions for adding the navbar"
        - "How to install Elements - Buttons - Example"
    """
    component_safe = component_name.replace("'", "''")

    sql_query = f"""
    SELECT
        name,
        description,
        dependencies,
        tailwind_ui_category,
        tailwind_ui_subcategory,
        css_classes,
        react_template
    FROM sections
    WHERE name = '{component_safe}'
    LIMIT 1
    """

    return {
        "project_id": SUPABASE_PROJECT_ID,
        "query": sql_query.strip(),
        "description": f"Get installation instructions for '{component_name}'",
        "tool_to_use": "mcp__supabase__execute_sql",
        "component_name": component_name,
        "instructions_template": {
            "step1": "Copy the component code from react_template field",
            "step2": "Paste into your React component file",
            "step3": "Ensure Tailwind CSS is configured in your project",
            "step4": "Install any dependencies listed in the dependencies field",
            "note": "Check css_classes field for Tailwind classes used"
        }
    }


# ============================================================================
# Server Entry Point
# ============================================================================

if __name__ == "__main__":
    import sys

    # Default to STDIO transport (for Claude Desktop/Code)
    transport = "stdio"
    port = 8000

    # Parse command line arguments
    if "--transport" in sys.argv:
        idx = sys.argv.index("--transport")
        if idx + 1 < len(sys.argv):
            transport = sys.argv[idx + 1]

    if "--port" in sys.argv:
        idx = sys.argv.index("--port")
        if idx + 1 < len(sys.argv):
            port = int(sys.argv[idx + 1])

    # Run the server
    if transport == "http":
        print(f"Starting Tailwind UI Components MCP Server on HTTP port {port}")
        mcp.run(transport="http", port=port)
    else:
        print("Starting Tailwind UI Components MCP Server on STDIO")
        mcp.run()
