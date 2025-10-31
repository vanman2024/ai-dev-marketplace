---
description: Generate and run comprehensive test suite for FastMCP server using in-memory testing pattern
argument-hint: [--server-path=path] [--run] [--coverage]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep
---

**Arguments**: $ARGUMENTS

Goal: Generate comprehensive pytest-based test suite for FastMCP server and optionally run tests with coverage reporting

Core Principles:
- Detect server architecture (simple vs toolsets)
- Use FastMCP in-memory testing pattern
- Generate parametrized tests for all components
- Validate before running

Phase 1: Discovery
Goal: Analyze server structure and components

Actions:
- Parse $ARGUMENTS for:
  - `--server-path=<path>` (default: current directory)
  - `--run` flag (execute tests after generation)
  - `--coverage` flag (include coverage reporting)
- Find server file (server.py or main.py)
- Detect architecture pattern (simple vs toolsets)
- Count tools, resources, prompts using Grep:
  - !{bash grep -r "@mcp.tool()" --include="*.py" | wc -l}
  - !{bash grep -r "@mcp.resource()" --include="*.py" | wc -l}
  - !{bash grep -r "@mcp.prompt()" --include="*.py" | wc -l}

Phase 2: Analysis
Goal: Understand what needs testing

Actions:
- Identify all toolset files (toolset_*.py pattern)
- List all tools/resources/prompts by file
- Check for existing tests/ directory
- Determine test dependencies needed

Phase 3: Planning
Goal: Present testing strategy

Actions:
- Display server analysis:
  - Server type (simple/toolsets)
  - Component counts
  - Files to test
- Show test suite structure:
  - tests/conftest.py (shared fixtures)
  - tests/test_*.py (one per toolset/module)
  - tests/pytest.ini (configuration)
- List dependencies to add:
  - pytest>=8.0.0
  - pytest-asyncio>=0.23.0
  - inline-snapshot>=0.13.0
  - dirty-equals>=0.7.0
  - pytest-cov (if --coverage)
- Confirm with user before generating

Phase 4: Test Generation
Goal: Create comprehensive test suite

Actions:

Invoke the fastmcp-tester agent to generate test suite.

Provide the agent with:
- Server structure analysis from Phase 1
- Component counts and locations
- Architecture type (simple/toolsets)
- List of all tools/resources/prompts to test
- Flags: --run and --coverage status

The agent should:
- Create tests/ directory structure
- Generate conftest.py with mcp_client fixture
- Generate test_*.py for each toolset/module
- Include parametrized tests for edge cases
- Add error handling tests
- Create pytest.ini configuration
- Update requirements.txt or pyproject.toml
- Follow FastMCP in-memory testing pattern

Phase 5: Verification
Goal: Validate generated tests

Actions:
- Check test syntax: !{bash python -m py_compile tests/*.py}
- Verify imports: !{bash python -c "from tests.conftest import mcp_client"}
- Check pytest can collect: !{bash pytest tests/ --collect-only}
- If errors found, ask agent to fix

Phase 6: Execution (Optional)
Goal: Run tests if --run flag provided

Actions:
- If --run flag:
  - Install dependencies: !{bash pip install -r requirements.txt}
  - Run tests with appropriate flags
  - If --coverage: !{bash pytest tests/ -v --cov=. --cov-report=html --cov-report=term}
  - Else: !{bash pytest tests/ -v}
  - Display results summary

Phase 7: Summary
Goal: Report what was accomplished

Actions:
- List generated files
- Show test coverage (if applicable)
- Display test results (if --run)
- Provide next steps:
  - How to run tests manually
  - How to add new tests
  - Link to TESTING.md documentation
