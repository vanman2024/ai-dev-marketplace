# Tailwind UI MCP Server - Test Suite

Comprehensive pytest-based test suite for the Tailwind UI FastMCP server.

## Overview

This test suite validates the Tailwind UI MCP server's functionality, security, and protocol compliance using FastMCP's in-memory testing pattern.

**Total Tests**: 100+ tests across 4 test modules
**Coverage Target**: >80%
**Testing Pattern**: FastMCP in-memory (no HTTP/subprocess needed)

## Test Structure

```
tests/
├── conftest.py                  # Shared fixtures and test configuration
├── test_server_info.py          # Server metadata tests (12 tests)
├── test_query_generation.py     # SQL query generation tests (40+ tests)
├── test_input_validation.py     # Input validation tests (30+ tests)
├── test_security.py             # SQL injection protection (25+ tests)
├── pytest.ini                   # Pytest configuration
└── README.md                    # This file
```

## Test Categories

### 1. Server Metadata Tests (`test_server_info.py`)
Tests the `server_info` tool that provides server diagnostics:
- Server name and version verification
- Database configuration validation
- Category listing validation
- Component count verification

**Key Tests**:
- `test_server_info_returns_dict` - Basic structure validation
- `test_server_info_has_required_fields` - All required fields present
- `test_server_info_database_project_id` - Correct Supabase project ID
- `test_server_info_categories_content` - Expected categories present

### 2. Query Generation Tests (`test_query_generation.py`)
Tests that all 6 query-generating tools produce valid SQL:
- `list_tailwind_categories` - Category listing queries
- `search_tailwind_components` - Search queries with filters
- `list_components_in_category` - Category filtering queries
- `view_component_details` - Component detail queries
- `get_component_code` - Code retrieval queries
- `get_add_instructions` - Installation instruction queries

**Key Tests**:
- `test_list_categories_query_structure` - Correct two-MCP pattern
- `test_search_components_various_queries` - Parametrized search tests
- `test_search_components_limit_clamping_*` - Limit boundary tests
- `test_view_component_details_multiple` - Multiple component queries
- `test_get_component_code_formats` - React/HTML format tests

### 3. Input Validation Tests (`test_input_validation.py`)
Tests parameter validation and edge case handling:
- Empty string inputs
- Whitespace-only inputs
- Unicode and special characters
- Very long inputs
- Boundary value testing for limits
- None/null value handling

**Key Tests**:
- `test_search_empty_query` - Empty search handling
- `test_limit_boundary_values` - Parametrized limit tests (0, -1, 100, 1000, etc.)
- `test_view_component_details_large_list` - Large input lists
- `test_parameters_used_field` - Metadata tracking

### 4. Security Tests (`test_security.py`)
Tests SQL injection protection and input sanitization:
- Single quote escaping (prevents SQL injection)
- SQL comment attack protection
- UNION/OR-based injection attempts
- Multi-statement injection (semicolons)
- Special character handling (null bytes, newlines, etc.)

**Key Tests**:
- `test_sql_injection_single_quote_escape` - Basic quote escaping
- `test_sql_injection_union_attack` - UNION-based injection
- `test_sql_injection_component_list` - Array injection protection
- `test_limit_is_integer_not_injectable` - Type safety for integers

## Installation

### Install Dependencies

```bash
# Install with dev dependencies
pip install -e ".[dev]"

# Or install test dependencies separately
pip install pytest>=8.0.0 pytest-asyncio>=0.23.0 pytest-cov>=4.1.0
```

## Running Tests

### Run All Tests

```bash
pytest
```

### Run Specific Test Module

```bash
pytest tests/test_server_info.py
pytest tests/test_query_generation.py
pytest tests/test_input_validation.py
pytest tests/test_security.py
```

### Run Specific Test

```bash
pytest tests/test_server_info.py::test_server_info_returns_dict
```

### Run Tests with Coverage

```bash
pytest --cov=. --cov-report=html --cov-report=term
```

Coverage report will be generated in `htmlcov/index.html`.

### Run Tests with Verbose Output

```bash
pytest -v
```

### Run Tests with Output Capture Disabled

```bash
pytest -s
```

### Run Only Security Tests

```bash
pytest -m security
```

### Run Parametrized Tests

```bash
# Run all parametrized search tests
pytest tests/test_query_generation.py::test_search_components_various_queries -v
```

## Testing Pattern

This test suite uses **FastMCP's in-memory testing pattern**, which is the recommended approach for testing FastMCP servers.

### In-Memory Testing Pattern

```python
from fastmcp import Client

@pytest.fixture
async def mcp_client():
    """Create in-memory FastMCP client."""
    from server import mcp
    async with Client(mcp) as client:
        yield client

@pytest.mark.asyncio
async def test_tool(mcp_client):
    result = await mcp_client.call_tool("tool_name", {"param": "value"})
    assert result["expected_field"] == "expected_value"
```

**Advantages**:
- No HTTP server startup/shutdown needed
- No subprocess management required
- Fast test execution
- Direct access to server internals
- Easy debugging

### Two-MCP Pattern Validation

This server uses the two-MCP pattern where it generates SQL queries that are executed by the Supabase MCP server. Tests validate that each tool returns:

```python
{
    "project_id": "wsmhiiharnhqupdniwgw",
    "query": "SELECT ...",
    "tool_to_use": "mcp__supabase__execute_sql",
    "description": "..."
}
```

## Test Fixtures

Defined in `conftest.py`:

- `mcp_client` - In-memory FastMCP client for all tests
- `sample_component_names` - Sample component names for testing
- `sample_search_queries` - Sample search queries for parametrized tests
- `sample_categories` - Sample categories for filtering tests
- `expected_project_id` - Expected Supabase project ID

## Expected Test Results

When running the full test suite, you should see:

```
=============================== test session starts ===============================
collected 100+ items

tests/test_server_info.py ............                                      [ 12%]
tests/test_query_generation.py ........................................      [ 50%]
tests/test_input_validation.py ..............................            [ 80%]
tests/test_security.py .........................                            [100%]

================================ 100+ passed in Xs ================================
```

## Common Issues & Solutions

### Import Errors

**Problem**: `ModuleNotFoundError: No module named 'server'`

**Solution**: Ensure you're running pytest from the project root directory:
```bash
cd /path/to/tailwind-ui-mcp
pytest
```

### Async Test Issues

**Problem**: `RuntimeWarning: coroutine was never awaited`

**Solution**: Ensure all async tests have `@pytest.mark.asyncio` decorator and `pytest.ini` has `asyncio_mode = auto`.

### Environment Variables

**Problem**: Tests fail due to missing `SUPABASE_PROJECT_ID`

**Solution**: The server uses a default project ID if not set. Tests should pass with the default. If testing with a different project, create a `.env` file:
```bash
SUPABASE_PROJECT_ID=your-project-id
```

## Continuous Integration

Example GitHub Actions workflow:

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      - run: pip install -e ".[dev]"
      - run: pytest --cov=. --cov-report=xml
      - uses: codecov/codecov-action@v3
```

## Test Coverage Goals

- **Overall Coverage**: >80%
- **server.py**: >90% (all tool functions should be tested)
- **Security Tests**: 100% of injection vectors covered
- **Edge Cases**: Boundary values, empty inputs, special characters

## Writing New Tests

When adding new tools to the server, follow these patterns:

### 1. Query Structure Test

```python
@pytest.mark.asyncio
async def test_new_tool_returns_query_dict(mcp_client):
    result = await mcp_client.call_tool("new_tool", {"param": "value"})
    assert isinstance(result, dict)
    assert "query" in result
    assert "project_id" in result
    assert result["tool_to_use"] == "mcp__supabase__execute_sql"
```

### 2. SQL Content Test

```python
@pytest.mark.asyncio
async def test_new_tool_sql_content(mcp_client):
    result = await mcp_client.call_tool("new_tool", {"param": "value"})
    sql = result["query"]
    assert "SELECT" in sql.upper()
    assert "FROM sections" in sql
    assert "expected_column" in sql
```

### 3. Input Validation Test

```python
@pytest.mark.asyncio
async def test_new_tool_empty_input(mcp_client):
    result = await mcp_client.call_tool("new_tool", {"param": ""})
    assert isinstance(result, dict)
    # Verify it handles empty input gracefully
```

### 4. Security Test

```python
@pytest.mark.asyncio
async def test_new_tool_sql_injection(mcp_client):
    result = await mcp_client.call_tool("new_tool", {
        "param": "'; DROP TABLE sections; --"
    })
    sql = result["query"]
    assert "''" in sql  # Quotes should be escaped
```

## Resources

- [FastMCP Testing Documentation](https://github.com/jlowin/fastmcp/blob/main/docs/testing.md)
- [Pytest Documentation](https://docs.pytest.org/)
- [Pytest-Asyncio Documentation](https://pytest-asyncio.readthedocs.io/)
- [SQL Injection Prevention](https://owasp.org/www-community/attacks/SQL_Injection)

## Maintenance

- **Update tests** when adding new tools or modifying existing ones
- **Run tests before commits** to catch regressions
- **Monitor coverage** and add tests for uncovered code paths
- **Review security tests** when changing input sanitization logic

## Questions?

For questions about the test suite, see:
- Server documentation: `/home/vanman2025/Projects/ai-dev-marketplace/tailwind-ui-mcp/README.md`
- FastMCP documentation: https://github.com/jlowin/fastmcp
- Supabase MCP: For the two-MCP pattern details
