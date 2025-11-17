---
description: Implement comprehensive error handling and retry strategies for Celery tasks
argument-hint: [task-name]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Add robust error handling, retry logic, and exception tracking to Celery tasks

Core Principles:
- Detect existing error handling patterns
- Configure exponential backoff retries
- Implement custom error handlers
- Add logging and monitoring

Phase 1: Discovery
Goal: Understand current task implementation and error handling state

Actions:
- Parse $ARGUMENTS for task name/pattern
- Find existing Celery tasks:
  - !{bash find . -type f -name "*.py" -path "*/tasks/*" 2>/dev/null | head -20}
- Detect current error handling approaches
- Load project configuration for Celery settings

Phase 2: Analysis
Goal: Identify error-prone operations and retry requirements

Actions:
- Read identified task files to understand:
  - Current retry decorators
  - Exception handling blocks
  - Logging patterns
  - External API calls or database operations
- Check for existing Celery configuration:
  - !{bash grep -r "CELERY_" . --include="*.py" --include="settings.py" | head -10}

Phase 3: Implementation
Goal: Add comprehensive error handling via task-generator-agent

Actions:

Task(description="Implement error handling and retries", subagent_type="celery:task-generator-agent", prompt="You are the task-generator-agent. Implement comprehensive error handling and retry strategies for $ARGUMENTS.

Context:
- Task files and patterns identified in discovery
- Existing error handling approaches
- Project Celery configuration

Requirements:
- Add retry decorators with exponential backoff
- Implement custom exception handlers for specific errors
- Add structured logging for debugging
- Configure max_retries and retry_backoff parameters
- Add error callbacks for final failure handling
- Use autoretry_for for known transient errors
- Implement custom on_failure handlers
- Add error tracking integration (Sentry if available)

Error Handling Patterns:
1. Network/API errors - Retry with backoff
2. Database errors - Short retry with circuit breaker
3. Business logic errors - No retry, log and alert
4. Validation errors - No retry, immediate failure
5. Resource exhaustion - Exponential backoff

Expected Output:
- Updated task files with retry decorators
- Custom exception classes if needed
- Error handler implementations
- Celery configuration updates
- Logging configuration
- Documentation of error handling strategy")

Phase 4: Validation
Goal: Verify error handling implementation

Actions:
- Check updated task files for proper decorators
- Verify retry configuration is present
- Ensure exception handlers are implemented
- Validate logging is configured
- Run syntax check: !{bash python -m py_compile $(find . -name "tasks.py" 2>/dev/null) 2>&1 | head -20}

Phase 5: Summary
Goal: Document error handling implementation

Actions:
- List tasks updated with error handling
- Summarize retry strategies configured
- Document exception types handled
- Show error tracking integration
- Provide testing recommendations
