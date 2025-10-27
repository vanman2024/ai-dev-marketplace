# Testing Guide

## Overview

The Ayrshare MCP server includes integration tests that validate the API client and server functionality.

## Test Structure

```
tests/
├── conftest.py          # Pytest configuration and fixtures
├── test_live_api.py     # Live API integration tests
└── pytest.ini           # Pytest settings (in project root)
```

## Running Tests

### 1. Install Test Dependencies

```bash
pip install pytest pytest-asyncio pytest-cov
```

### 2. Configure API Key

Tests use the `.env` file in the project root:

```bash
# .env
AYRSHARE_API_KEY=your_api_key_here
```

### 3. Run Tests

**Run all tests:**
```bash
pytest tests/ -v
```

**Run with output:**
```bash
pytest tests/ -v -s
```

**Run specific test:**
```bash
pytest tests/test_live_api.py::test_api_key_valid -v
```

**Run with coverage:**
```bash
pytest tests/ -v --cov=src --cov-report=html
```

## Test Results

Current test status (2025-10-27):

```
✓ test_api_key_valid          - API key properly loaded
✓ test_post_endpoint_format   - Request headers formatted correctly  
✓ test_user_endpoint          - Live API connection working
```

### API Response Sample

The `/user` endpoint returns:
- **Active Social Accounts**: Facebook, GMB, LinkedIn, YouTube
- **Monthly Quota**: 20 posts (0 used)
- **API Calls**: 2 this month
- **Connected Profiles**: Full profile details with usernames and URLs

## API Limitations

Some endpoints require Business Plan:
- `/profiles` - Multi-tenant profile management (403 Forbidden on Free plan)
- `/history` with certain parameters may be limited

The server is designed to handle these gracefully with proper error messages.

## Test Coverage

**Current Coverage:**
- ✓ API client initialization
- ✓ Authentication headers
- ✓ Live API connectivity
- ✓ Error handling for plan limitations

**Future Tests:**
- [ ] MCP tool execution
- [ ] MCP resource access
- [ ] MCP prompt generation
- [ ] Mock tests for all 19 tools
- [ ] Rate limiting behavior
- [ ] Profile key multi-tenancy

## Adding New Tests

Create new test files in `tests/`:

```python
"""tests/test_new_feature.py"""
import pytest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

@pytest.mark.asyncio
async def test_something():
    from ayrshare_client import AyrshareClient
    from dotenv import load_dotenv
    
    load_dotenv()
    client = AyrshareClient()
    
    # Your test code here
    assert True
```

## CI/CD Integration

For automated testing:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install -r requirements.txt pytest pytest-asyncio
      - run: pytest tests/ -v
        env:
          AYRSHARE_API_KEY: ${{ secrets.AYRSHARE_API_KEY }}
```

## Troubleshooting

**Module not found errors:**
```bash
# Clear pytest cache
pytest --cache-clear

# Reinstall dependencies
pip install -r requirements.txt
```

**API errors:**
- Check `.env` file exists with valid `AYRSHARE_API_KEY`
- Verify API key at https://app.ayrshare.com/api-key
- Some endpoints require Business Plan subscription

**Import errors:**
```bash
# Ensure src/ is in Python path
export PYTHONPATH="${PYTHONPATH}:$(pwd)/src"
```

## Next Steps

1. Add mock tests for all 19 MCP tools
2. Test MCP resource URIs (`ayrshare://history`, `ayrshare://platforms`)
3. Test MCP prompts (optimize_for_platform, generate_hashtags, schedule_campaign)
4. Add performance tests
5. Add security tests for API key handling
6. Set up continuous integration

## Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [Ayrshare API Docs](https://www.ayrshare.com/docs)
- [FastMCP Testing Guide](https://github.com/jlowin/fastmcp#testing)
