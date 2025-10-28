# Tailwind UI MCP Server - Tool Development Guide

Guide for adding the 6 planned tools to the FastMCP server.

## Current Status

**Implemented Tools:**
- `server_info` - Server metadata and diagnostics
- `get_example_query` - Example SQL queries and patterns

**Planned Tools (To Be Added):**
1. `search_components` - Natural language component search
2. `get_component_code` - Retrieve full component code
3. `list_categories` - Browse available categories
4. `filter_by_tags` - Find components with specific features
5. `get_dependencies` - Get component dependencies
6. `browse_by_category` - Explore components in a category

## Tool Implementation Pattern

All tools will use the Supabase MCP server for database queries. Here's the pattern:

```python
@mcp.tool()
async def tool_name(param: type) -> dict:
    """
    Tool description for AI to understand when to use this.

    Args:
        param: Parameter description

    Returns:
        dict: Response structure
    """
    # Generate SQL query
    sql = "SELECT ... FROM sections WHERE ..."

    # NOTE: The actual execution will be done by calling the Supabase MCP tool
    # This tool returns the query and context for the AI to execute

    return {
        "query": sql,
        "project_id": SUPABASE_PROJECT_ID,
        "tool_to_use": "mcp__supabase__execute_sql",
        "description": "What this query does"
    }
```

## Tool Specifications

### 1. search_components

**Purpose:** Natural language search across all components

**Parameters:**
- `query` (str): Search term (searches name, description, category)
- `limit` (int, optional): Maximum results (default: 20)

**SQL Pattern:**
```sql
SELECT
    name,
    description,
    category,
    tailwind_ui_category,
    tailwind_ui_subcategory,
    tags
FROM sections
WHERE
    name ILIKE '%{query}%' OR
    description ILIKE '%{query}%' OR
    category ILIKE '%{query}%'
LIMIT {limit}
```

**Example Usage:**
```
User: "Find button components"
Tool: search_components(query="button", limit=20)
Returns: List of button components with descriptions
```

### 2. get_component_code

**Purpose:** Retrieve full code for a specific component

**Parameters:**
- `name` (str): Exact component name
- `code_type` (str, optional): 'react' or 'html' (default: 'react')

**SQL Pattern:**
```sql
SELECT
    name,
    description,
    react_template,
    html_code,
    dependencies,
    css_classes,
    tags
FROM sections
WHERE name = '{name}'
LIMIT 1
```

**Example Usage:**
```
User: "Get the code for Simple Contact Form"
Tool: get_component_code(name="Simple Contact Form")
Returns: Full React code, HTML code, dependencies
```

### 3. list_categories

**Purpose:** Browse all available component categories

**Parameters:**
- `include_count` (bool, optional): Include component count per category

**SQL Pattern:**
```sql
SELECT
    category,
    tailwind_ui_category,
    COUNT(*) as component_count
FROM sections
GROUP BY category, tailwind_ui_category
ORDER BY component_count DESC
```

**Example Usage:**
```
User: "What categories are available?"
Tool: list_categories(include_count=True)
Returns: All categories with component counts
```

### 4. filter_by_tags

**Purpose:** Find components with specific tags/features

**Parameters:**
- `tags` (list[str]): Tags to filter by
- `match_all` (bool, optional): Require all tags (AND) vs any tag (OR)
- `limit` (int, optional): Maximum results

**SQL Pattern (match_all=True):**
```sql
SELECT
    name,
    description,
    category,
    tags
FROM sections
WHERE tags @> ARRAY['{tag1}', '{tag2}']
LIMIT {limit}
```

**SQL Pattern (match_all=False):**
```sql
SELECT
    name,
    description,
    category,
    tags
FROM sections
WHERE tags && ARRAY['{tag1}', '{tag2}']
LIMIT {limit}
```

**Example Usage:**
```
User: "Find components with dark mode and responsive design"
Tool: filter_by_tags(tags=["dark-mode", "responsive"], match_all=True)
Returns: Components with both features
```

### 5. get_dependencies

**Purpose:** Get dependency information for a component

**Parameters:**
- `name` (str): Component name

**SQL Pattern:**
```sql
SELECT
    name,
    dependencies,
    css_classes
FROM sections
WHERE name = '{name}'
LIMIT 1
```

**Example Usage:**
```
User: "What dependencies does the Dashboard Layout need?"
Tool: get_dependencies(name="Dashboard Layout")
Returns: Required libraries, CSS classes
```

### 6. browse_by_category

**Purpose:** Explore all components in a specific category

**Parameters:**
- `category` (str): Category name
- `subcategory` (str, optional): Subcategory filter
- `limit` (int, optional): Maximum results

**SQL Pattern:**
```sql
SELECT
    name,
    description,
    tailwind_ui_subcategory,
    tags
FROM sections
WHERE
    category = '{category}'
    AND ('{subcategory}' IS NULL OR tailwind_ui_subcategory = '{subcategory}')
ORDER BY name
LIMIT {limit}
```

**Example Usage:**
```
User: "Show me all form components"
Tool: browse_by_category(category="forms")
Returns: All form components organized by subcategory
```

## Implementation Steps

### Step 1: Add Tool Function to server.py

```python
@mcp.tool()
async def search_components(query: str, limit: int = 20) -> dict:
    """
    Search Tailwind UI components by name, description, or category.

    Use this tool when the user wants to find components matching
    a search term or keyword.

    Args:
        query: Search term to match against component names, descriptions, and categories
        limit: Maximum number of results to return (default: 20)

    Returns:
        dict: SQL query and execution details for the Supabase MCP server
    """
    # Build SQL query
    sql = f"""
    SELECT
        name,
        description,
        category,
        tailwind_ui_category,
        tailwind_ui_subcategory,
        tags
    FROM sections
    WHERE
        name ILIKE '%{query}%' OR
        description ILIKE '%{query}%' OR
        category ILIKE '%{query}%'
    LIMIT {limit}
    """

    return {
        "tool_to_use": "mcp__supabase__execute_sql",
        "project_id": SUPABASE_PROJECT_ID,
        "query": sql.strip(),
        "description": f"Search for components matching: {query}",
        "expected_results": f"Up to {limit} components matching '{query}'",
        "next_steps": [
            "Review the returned components",
            "Use get_component_code() to retrieve full code for any component",
            "Use filter_by_tags() to refine search by features"
        ]
    }
```

### Step 2: Test the Tool

```bash
# Start server
python server.py

# In Claude Desktop/Code, test:
# "Find button components"
# Should trigger search_components tool
```

### Step 3: Document in README

Update README_PYTHON.md with the new tool documentation.

### Step 4: Repeat for Each Tool

Follow the same pattern for all 6 tools.

## Query Building Best Practices

### 1. Parameterization
Always use parameterized queries when possible:
```python
# Good - Safe from SQL injection
sql = "SELECT * FROM sections WHERE name = %s"
params = [component_name]

# Avoid - Vulnerable to SQL injection
sql = f"SELECT * FROM sections WHERE name = '{component_name}'"
```

### 2. ILIKE for Case-Insensitive Search
```sql
-- Case-insensitive
WHERE name ILIKE '%button%'

-- Case-sensitive (avoid)
WHERE name LIKE '%button%'
```

### 3. Array Operations for Tags
```sql
-- Contains all tags (AND)
WHERE tags @> ARRAY['dark-mode', 'responsive']

-- Contains any tag (OR)
WHERE tags && ARRAY['dark-mode', 'responsive']
```

### 4. Proper LIMIT and OFFSET
```sql
-- Good - Always include LIMIT
SELECT * FROM sections LIMIT 20

-- For pagination
SELECT * FROM sections LIMIT 20 OFFSET 40
```

### 5. Use Indexes for Performance
The database should have these indexes:
```sql
CREATE INDEX idx_sections_name ON sections(name);
CREATE INDEX idx_sections_category ON sections(category);
CREATE INDEX idx_sections_tags ON sections USING GIN(tags);
CREATE INDEX idx_sections_search ON sections USING GIN(
    to_tsvector('english', name || ' ' || description)
);
```

## Error Handling

Each tool should handle common errors:

```python
@mcp.tool()
async def search_components(query: str, limit: int = 20) -> dict:
    """Search components"""

    # Validate inputs
    if not query or not query.strip():
        return {
            "error": "Query cannot be empty",
            "suggestion": "Provide a search term like 'button', 'form', or 'navigation'"
        }

    if limit < 1 or limit > 100:
        return {
            "error": "Limit must be between 1 and 100",
            "suggestion": f"You requested {limit}, please use a value in range 1-100"
        }

    # Build query
    sql = f"SELECT ... WHERE ... LIMIT {limit}"

    return {
        "tool_to_use": "mcp__supabase__execute_sql",
        "project_id": SUPABASE_PROJECT_ID,
        "query": sql
    }
```

## Testing Tools

### Manual Testing with Claude

```
Test 1: search_components
User: "Find all button components"
Expected: Returns list of buttons from database

Test 2: get_component_code
User: "Get the code for Simple Hero Section"
Expected: Returns React code, HTML, dependencies

Test 3: list_categories
User: "What component categories exist?"
Expected: List of categories with counts

Test 4: filter_by_tags
User: "Find responsive components with dark mode"
Expected: Components with both tags

Test 5: get_dependencies
User: "What does the Dashboard Layout need?"
Expected: Dependency list and CSS classes

Test 6: browse_by_category
User: "Show all navigation components"
Expected: All nav components organized by subcategory
```

### Automated Testing

Create `tests/test_tools.py`:

```python
import pytest
from server import search_components, get_component_code, list_categories

@pytest.mark.asyncio
async def test_search_components():
    result = await search_components(query="button", limit=10)
    assert "query" in result
    assert "SELECT" in result["query"]
    assert "button" in result["query"].lower()

@pytest.mark.asyncio
async def test_get_component_code():
    result = await get_component_code(name="Test Component")
    assert "query" in result
    assert "react_template" in result["query"]

@pytest.mark.asyncio
async def test_list_categories():
    result = await list_categories(include_count=True)
    assert "query" in result
    assert "COUNT" in result["query"]
```

Run tests:
```bash
pytest tests/test_tools.py
```

## Tool Response Format

All tools should return consistent structure:

```python
{
    "tool_to_use": "mcp__supabase__execute_sql",
    "project_id": "wsmhiiharnhqupdniwgw",
    "query": "SELECT ... FROM sections WHERE ...",
    "description": "What this query does",
    "expected_results": "What data will be returned",
    "next_steps": [
        "Suggested actions after getting results"
    ],
    "metadata": {
        "search_term": "button",
        "filters_applied": ["category", "tags"],
        "result_limit": 20
    }
}
```

## Common SQL Patterns

### Full-Text Search
```sql
SELECT * FROM sections
WHERE to_tsvector('english', name || ' ' || description)
@@ plainto_tsquery('english', 'search term');
```

### Fuzzy Matching
```sql
SELECT * FROM sections
WHERE similarity(name, 'serch term') > 0.3
ORDER BY similarity(name, 'serch term') DESC;
```

### JSON Field Queries
```sql
-- Get components with specific dependency
SELECT * FROM sections
WHERE dependencies->>'react' IS NOT NULL;

-- Get components using specific library
SELECT * FROM sections
WHERE dependencies @> '{"headlessui": ">=1.0.0"}';
```

## Performance Considerations

1. **Always use LIMIT**: Prevent returning huge result sets
2. **Use indexes**: Ensure database has proper indexes
3. **Avoid SELECT \***: Only select needed columns
4. **Cache common queries**: Store frequent results
5. **Pagination**: Use OFFSET for large result sets

## Next Steps

1. Implement `search_components` first (most commonly used)
2. Add `get_component_code` second (complements search)
3. Implement `list_categories` third (exploration)
4. Add remaining tools based on usage patterns

## Resources

- **FastMCP Decorators**: https://gofastmcp.com/concepts/tools
- **PostgreSQL Arrays**: https://www.postgresql.org/docs/current/arrays.html
- **Supabase Queries**: https://supabase.com/docs/guides/database/full-text-search
- **MCP Tool Spec**: https://modelcontextprotocol.io/docs/concepts/tools

---

**Ready to add tools?** Start with `search_components` and test thoroughly before adding the rest.
