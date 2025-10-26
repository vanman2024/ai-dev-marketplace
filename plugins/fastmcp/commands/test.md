---
description: Generate and run comprehensive test suite for FastMCP server using in-memory client testing. Creates pytest-based tests following FastMCP best practices.
argument-hint: [--server-path=path] [--run] [--coverage]
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*)
---

# FastMCP Server Testing Command

**Arguments**: $ARGUMENTS

**Goal**: Generate comprehensive test suite for FastMCP server and optionally run tests with coverage reporting.

## Phase 1: Discovery

**Goal**: Analyze server structure and determine testing strategy

**Actions**:
- Parse $ARGUMENTS for:
  - `--server-path=<path>` (default: current directory)
  - `--run` flag (run tests after generation)
  - `--coverage` flag (include coverage reporting)
- Find server.py or main.py file
- Check if tests/ directory exists
- Check if toolset pattern is used (multiple toolset_*.py files)
- Count total tools, resources, prompts

**Architecture Detection**:
- If toolsets detected: Plan one test file per toolset
- If simple server: Plan single test_server.py
- If resources present: Include resource testing
- If prompts present: Include prompt testing

**Implementation**:
1. Use Glob to find Python files: `**/*.py`
2. Use Grep to find FastMCP patterns:
   - Tool decorators: `@mcp.tool()`
   - Resource decorators: `@mcp.resource()`
   - Prompt decorators: `@mcp.prompt()`
3. Identify architecture:
   - Check for toolset_*.py pattern
   - Count decorators per file
   - Detect async vs sync patterns
4. Document findings in todo list

## Phase 2: Planning

**Goal**: Present testing strategy to user

**Actions**:
- Show detected structure:
  - Server type (simple vs toolsets)
  - Tool count by toolset (if applicable)
  - Resources count
  - Prompts count
- Show test files to be generated:
  - conftest.py (shared fixtures)
  - test_*.py files (one per toolset/module)
  - pytest.ini (configuration)
- Show dependencies to add:
  - pytest>=8.0.0
  - pytest-asyncio>=0.23.0
  - inline-snapshot>=0.13.0
  - dirty-equals>=0.7.0
  - pytest-cov (if --coverage flag)
- Confirm before generating

**Implementation**:
1. Create summary report:
```
FastMCP Server Analysis
=======================
Server Type: [Simple|Toolsets]
Architecture: [Single file|Multi-file with toolsets]

Components Found:
- Tools: X (across Y files)
- Resources: X
- Prompts: X

Test Files to Generate:
- tests/conftest.py (shared fixtures)
- tests/test_toolset_name.py (for each toolset)
- tests/pytest.ini (configuration)

Dependencies Required:
- pytest>=8.0.0
- pytest-asyncio>=0.23.0
- inline-snapshot>=0.13.0
- dirty-equals>=0.7.0
- pytest-cov>=4.1.0 (if --coverage)

Proceed with test generation? (y/n)
```

2. Wait for user confirmation
3. If confirmed, proceed to Phase 3
4. If not, exit with summary

## Phase 3: Test Generation

**Goal**: Generate comprehensive test suite

**Invoke the fastmcp-tester agent** to create test files.

**Provide the agent with**:
- Server structure analysis from Phase 1
- List of toolsets and tool counts
- Resources and prompts information
- Testing strategy (parametrized, error handling, etc.)
- Expected output: Complete tests/ directory

**Agent Instructions**:
```
You are tasked with generating a comprehensive test suite for a FastMCP server.

Server Structure:
{structure_analysis}

Your tasks:
1. Create tests/ directory if not exists
2. Generate conftest.py with mcp_client fixture using FastMCP in-memory testing pattern
3. Generate test_*.py files for each toolset/module with:
   - Parametrized tests for multiple scenarios
   - Error handling tests (invalid inputs, missing params)
   - Type validation tests
   - Async execution tests
   - Inline snapshots for complex data structures
4. Create pytest.ini with proper asyncio configuration
5. Update requirements.txt or pyproject.toml with test dependencies

Testing Pattern (conftest.py):
```python
import pytest
from fastmcp import FastMCP

@pytest.fixture
async def mcp_client():
    """Create in-memory MCP client for testing."""
    mcp = FastMCP("Test Server")

    # Import and register tools/resources
    from server import register_tools
    register_tools(mcp)

    # Create test client
    async with mcp.client() as client:
        yield client
```

Test Structure (test_*.py):
```python
import pytest
from inline_snapshot import snapshot
from dirty_equals import IsPositive, IsStr

@pytest.mark.asyncio
async def test_tool_name_success(mcp_client):
    """Test successful tool execution."""
    result = await mcp_client.call_tool("tool_name", {"param": "value"})
    assert result == snapshot({"expected": "result"})

@pytest.mark.asyncio
@pytest.mark.parametrize("invalid_input", [
    {},  # Missing required param
    {"param": ""},  # Empty value
    {"param": None},  # Null value
])
async def test_tool_name_error_handling(mcp_client, invalid_input):
    """Test error handling with invalid inputs."""
    with pytest.raises(Exception) as exc_info:
        await mcp_client.call_tool("tool_name", invalid_input)
    assert "error message" in str(exc_info.value).lower()
```

Success Criteria:
- All tests are syntax-valid Python
- conftest.py has working mcp_client fixture
- Each tool/resource/prompt has at least 2 tests (success + error)
- Parametrized tests cover edge cases
- Async tests properly decorated
- Dependencies documented
```

**The agent should**:
- Create tests/ directory if not exists
- Generate conftest.py with mcp_client fixture
- Generate test_*.py files for each toolset/module
- Include parametrized tests for multiple scenarios
- Include error handling tests
- Add inline snapshots for complex data
- Create pytest.ini with proper configuration
- Update requirements.txt or pyproject.toml

## Phase 4: Verification

**Goal**: Verify tests can run

**Actions**:
1. Check syntax: `python -m py_compile tests/*.py`
2. Verify imports: `python -c "from tests.conftest import mcp_client"`
3. Check pytest can collect tests: `pytest --collect-only`
4. If any issues, fix them before proceeding

**Implementation**:
```bash
# Syntax check
echo "Checking Python syntax..."
for file in tests/*.py; do
    python -m py_compile "$file" || exit 1
done

# Import check
echo "Verifying imports..."
python -c "from tests.conftest import mcp_client" || exit 1

# Collection check
echo "Collecting tests..."
pytest tests/ --collect-only || exit 1

echo "Verification complete. All tests are valid."
```

**Error Handling**:
- If syntax errors: Show file and line, ask agent to fix
- If import errors: Check dependencies, show missing modules
- If collection errors: Show pytest output, ask agent to fix

## Phase 5: Execution (Optional)

**Goal**: Run tests and report results

**If `--run` flag provided**:

1. Install dependencies if needed:
```bash
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
elif [ -f "pyproject.toml" ]; then
    pip install -e ".[test]"
fi
```

2. Run tests:
```bash
if [ "$COVERAGE" = "true" ]; then
    pytest tests/ -v --cov=. --cov-report=html --cov-report=term
else
    pytest tests/ -v
fi
```

3. Show results:
```
Test Results
============
Total: X tests
Passed: X
Failed: X
Skipped: X
Duration: X.Xs

Coverage: XX% (if --coverage)
HTML Report: htmlcov/index.html (if --coverage)
```

**Implementation**:
1. Parse --run flag from $ARGUMENTS
2. If present, install dependencies
3. Run pytest with appropriate flags
4. Parse output for summary
5. Display formatted results
6. If --coverage, show link to HTML report

## Phase 6: Documentation

**Goal**: Document testing approach

**Actions**:
- Create or update TESTING.md with:
  - How to run tests
  - Test structure explanation
  - Adding new tests guide
  - CI/CD integration examples
- Update README.md with testing section

**TESTING.md Template**:
```markdown
# Testing Guide

## Running Tests

```bash
# Run all tests
pytest tests/

# Run with verbose output
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=. --cov-report=html

# Run specific test file
pytest tests/test_toolset_name.py

# Run specific test
pytest tests/test_toolset_name.py::test_tool_name_success
```

## Test Structure

```
tests/
├── conftest.py          # Shared fixtures (mcp_client)
├── pytest.ini           # Pytest configuration
├── test_toolset_a.py    # Tests for toolset A
└── test_toolset_b.py    # Tests for toolset B
```

## Adding New Tests

When adding a new tool/resource/prompt:

1. Add success test:
```python
@pytest.mark.asyncio
async def test_new_tool_success(mcp_client):
    result = await mcp_client.call_tool("new_tool", {"param": "value"})
    assert result == snapshot({"expected": "result"})
```

2. Add error handling test:
```python
@pytest.mark.asyncio
async def test_new_tool_error(mcp_client):
    with pytest.raises(Exception):
        await mcp_client.call_tool("new_tool", {})
```

3. Run tests: `pytest tests/ -v`

## CI/CD Integration

### GitHub Actions

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install -r requirements.txt
      - run: pytest tests/ --cov=. --cov-report=xml
      - uses: codecov/codecov-action@v3
```

## Testing Best Practices

1. Use parametrized tests for multiple scenarios
2. Test error handling with invalid inputs
3. Use inline snapshots for complex data
4. Keep tests focused and isolated
5. Use descriptive test names
6. Mock external dependencies
```

**README.md Addition**:
```markdown
## Testing

```bash
# Run tests
pytest tests/

# Run with coverage
pytest tests/ --cov=. --cov-report=html
```

See [TESTING.md](TESTING.md) for detailed testing guide.
```

## Success Criteria

- tests/ directory with complete test suite
- conftest.py with working fixture
- All tools/resources/prompts covered
- pytest.ini configured
- Dependencies documented
- Tests syntax-valid and runnable
- (If --run) All tests passing or documented failures
- TESTING.md created with comprehensive guide
- README.md updated with testing section

## Example Usage

```bash
# Generate tests only
/fastmcp:test

# Generate and run tests
/fastmcp:test --run

# Generate, run, and show coverage
/fastmcp:test --run --coverage

# Test specific server
/fastmcp:test --server-path=./my-server --run
```

## Error Handling

**Common Issues**:

1. **No server.py found**:
   - Error: "Cannot find FastMCP server file (server.py or main.py)"
   - Solution: Specify path with --server-path

2. **No tools found**:
   - Error: "No FastMCP tools/resources/prompts detected"
   - Solution: Verify server file has @mcp.tool() decorators

3. **Import errors during verification**:
   - Error: "Cannot import conftest: ModuleNotFoundError"
   - Solution: Install dependencies with pip install -r requirements.txt

4. **Test failures**:
   - Error: "X tests failed"
   - Solution: Review pytest output, update snapshots if needed

## Notes

- Uses in-memory FastMCP client testing pattern (no HTTP server needed)
- Generates pytest-based tests following FastMCP best practices
- Supports both simple servers and toolset-based architecture
- Uses inline-snapshot for snapshot testing
- Uses dirty-equals for flexible assertions
- Automatically detects async vs sync patterns
- Creates parametrized tests for edge cases
