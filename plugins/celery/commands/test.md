---
description: Generate test suite for Celery tasks
argument-hint: task-name-or-path
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---


**Arguments**: $ARGUMENTS

Goal: Generate comprehensive pytest test suite for Celery tasks with mocking, fixtures, and async testing

Core Principles:
- Detect don't assume task structure
- Generate tests following pytest best practices
- Mock Celery internals for unit testing
- Include tests for retries, failures, and edge cases

Phase 1: Discovery
Goal: Find tasks and understand project structure

Actions:
- Parse $ARGUMENTS for specific task name or path
- Detect project testing framework and structure
- Example: !{bash ls pytest.ini setup.cfg pyproject.toml conftest.py 2>/dev/null}
- Find existing Celery tasks to test
- Example: !{bash find . -name "*tasks*.py" -type f 2>/dev/null | head -10}
- Check for existing test directory structure
- Example: !{bash find . -type d -name "tests" -o -name "test" 2>/dev/null}

Phase 2: Task Analysis
Goal: Load and understand task implementations

Actions:
- If $ARGUMENTS specifies task file, load it: @[task_file]
- Otherwise, find and load all task files
- Parse task decorators and configurations
- Identify task parameters, return types, and error handling
- Note retry policies and exception handling
- Example: !{bash grep -n "@task\|@shared_task\|@app.task" [task_files]}

Phase 3: Test Structure Setup
Goal: Prepare test directory and configuration

Actions:
- Determine test file location following project conventions
- Check if conftest.py exists for fixtures
- Verify pytest and pytest-celery are installed
- Example: !{bash pip list | grep pytest}
- Create test directory if needed
- Example: !{bash mkdir -p tests/tasks 2>/dev/null}

Phase 4: Test Generation
Goal: Generate comprehensive test cases

Actions:
- For each task found, generate test suite including:
  - Test successful execution
  - Test with valid inputs
  - Test with invalid inputs (validation)
  - Test retry behavior on failure
  - Test exception handling
  - Test task state (PENDING, SUCCESS, FAILURE, RETRY)
  - Mock external dependencies
  - Test async behavior if applicable
- Include pytest fixtures for Celery app and mocked dependencies
- Add docstrings explaining what each test validates
- Follow naming convention: test_[task_name]_[scenario]

Phase 5: Test File Creation
Goal: Write test files to appropriate locations

Actions:
- Write test file for each task module
- Create conftest.py with shared fixtures if not present
- Add __init__.py to test directories if needed
- Include imports for pytest, pytest-celery, and mocks
- Follow pytest conventions with fixtures and parametrized tests
- Include test for task success, failures, retries, and validation

Phase 6: Validation
Goal: Verify tests are syntactically correct

Actions:
- Check Python syntax of generated test files
- Example: !{bash python -m py_compile tests/test_*.py}
- Verify pytest can discover tests
- Example: !{bash pytest --collect-only tests/}
- Check for missing imports or dependencies

Phase 7: Summary
Goal: Report what was created and how to run tests

Actions:
- Display generated test files and locations
- Show test count per task
- Provide command to run tests:
  - All tests: pytest tests/
  - Specific task: pytest tests/test_[task_name].py
  - With coverage: pytest --cov=tasks tests/
  - Verbose: pytest -v tests/
- List test coverage areas:
  - Success cases
  - Error handling
  - Retry logic
  - Input validation
- Suggest next steps:
  - Install pytest-celery if not present
  - Configure Celery for testing (task_always_eager)
  - Add CI integration
  - Generate coverage report
