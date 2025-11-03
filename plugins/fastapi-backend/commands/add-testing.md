---
description: Generate pytest test suite with fixtures for FastAPI endpoints
argument-hint: endpoint-or-module-path
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion, Skill
---
## Available Skills

This commands has access to the following skills from the fastapi-backend plugin:

- **async-sqlalchemy-patterns**: Async SQLAlchemy 2.0+ database patterns for FastAPI including session management, connection pooling, Alembic migrations, relationship loading strategies, and query optimization. Use when implementing database models, configuring async sessions, setting up migrations, optimizing queries, managing relationships, or when user mentions SQLAlchemy, async database, ORM, Alembic, database performance, or connection pooling.\n- **fastapi-api-patterns**: REST API design and implementation patterns for FastAPI endpoints including CRUD operations, pagination, filtering, error handling, and request/response models. Use when building FastAPI endpoints, creating REST APIs, implementing CRUD operations, adding pagination, designing API routes, handling API errors, or when user mentions FastAPI patterns, REST API design, endpoint structure, API best practices, or HTTP endpoints.\n- **fastapi-auth-patterns**: Implement and validate FastAPI authentication strategies including JWT tokens, OAuth2 password flows, OAuth2 scopes for permissions, and Supabase integration. Use when implementing authentication, securing endpoints, handling user login/signup, managing permissions, integrating OAuth providers, or when user mentions JWT, OAuth2, Supabase auth, protected routes, access control, role-based permissions, or authentication errors.\n- **fastapi-deployment-config**: Configure multi-platform deployment for FastAPI applications including Docker containerization, Railway, DigitalOcean App Platform, and AWS deployment. Use when deploying FastAPI apps, setting up production environments, containerizing applications, configuring cloud platforms, implementing health checks, managing environment variables, setting up reverse proxies, or when user mentions Docker, Railway, DigitalOcean, AWS, deployment configuration, production setup, or container orchestration.\n- **fastapi-project-structure**: Production-ready FastAPI project scaffolding templates including directory structure, configuration files, settings management, dependency injection, MCP server integration, and development/production setup patterns. Use when creating FastAPI projects, setting up project structure, configuring FastAPI applications, implementing settings management, adding MCP integration, or when user mentions FastAPI setup, project scaffold, app configuration, environment management, or backend structure.\n- **mem0-fastapi-integration**: Memory layer integration patterns for FastAPI with Mem0 including client setup, memory service patterns, user tracking, conversation persistence, and background task integration. Use when implementing AI memory, adding Mem0 to FastAPI, building chat with memory, or when user mentions Mem0, conversation history, user context, or memory layer.\n
**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

---



## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Generate comprehensive pytest test suite with proper fixtures, mocking, and async support for FastAPI endpoints

Core Principles:
- Detect existing test patterns and follow them
- Use pytest fixtures for dependencies
- Generate async tests for async endpoints
- Include both success and error test cases
- Follow FastAPI testing best practices

Phase 1: Discovery
Goal: Understand the target endpoint and existing test structure

Actions:
- Parse $ARGUMENTS to identify target (endpoint file, router, or module)
- Detect project structure and locate test directory
- Example: !{bash find . -type d -name "tests" -o -name "test" 2>/dev/null | head -5}
- Check if pytest is configured: !{bash test -f pytest.ini || test -f pyproject.toml && echo "Found" || echo "Not found"}
- Load existing test files to understand patterns
- Identify the target endpoint file to test

Phase 2: Analysis
Goal: Analyze endpoint structure and dependencies

Actions:
- Read the target endpoint file to understand:
  - Route definitions and HTTP methods
  - Request/response models (Pydantic)
  - Dependencies (Depends())
  - Database interactions
  - Authentication/authorization requirements
- Search for existing test utilities and fixtures
- Example: !{bash find tests -name "conftest.py" -o -name "fixtures.py" 2>/dev/null}
- Check for TestClient usage patterns in existing tests

Phase 3: Clarification
Goal: Gather missing requirements

Actions:
- If $ARGUMENTS is unclear or target not found, use AskUserQuestion to gather:
  - Which endpoint or module should be tested?
  - Should tests include database fixtures?
  - Are there authentication flows to test?
  - Any specific edge cases to cover?
- Confirm test file location and naming convention
- Verify which dependencies need mocking

Phase 4: Planning
Goal: Design the test suite structure

Actions:
- Plan test file structure:
  - Test class organization
  - Fixture requirements (TestClient, database, auth)
  - Mock objects needed
  - Test cases to cover (success, validation errors, auth failures)
- Identify which FastAPI testing utilities to use
- Outline fixture dependencies and scope

Phase 5: Implementation
Goal: Generate comprehensive test suite

Actions:

Task(description="Generate pytest test suite", subagent_type="test-generator", prompt="You are the test-generator agent. Generate a comprehensive pytest test suite for $ARGUMENTS.

WebFetch: https://fastapi.tiangolo.com/tutorial/testing/
WebFetch: https://docs.pytest.org/en/stable/how-to/fixtures.html

Context:
- FastAPI project with pytest
- Target: $ARGUMENTS
- Follow async/await patterns for async endpoints
- Use FastAPI TestClient for HTTP testing

Requirements:
- Create test file with descriptive name (test_*.py)
- Import pytest and FastAPI TestClient
- Define fixtures for:
  - TestClient instance
  - Database session (if needed)
  - Authentication tokens (if needed)
  - Mock dependencies
- Write test functions covering:
  - Happy path (successful requests)
  - Validation errors (invalid input)
  - Authentication/authorization failures (if applicable)
  - Edge cases and error conditions
- Use pytest parametrize for multiple test cases
- Include docstrings explaining what each test validates
- Follow naming convention: test_<method>_<endpoint>_<scenario>
- Use proper async test syntax (@pytest.mark.asyncio) if needed

Expected output:
- Complete test file with fixtures
- Clear test coverage for all endpoints
- Proper mocking of dependencies
- Follows existing project test patterns")

Phase 6: Verification
Goal: Validate the generated tests

Actions:
- Check that test file was created in correct location
- Verify syntax with Python parser: !{bash python -m py_compile tests/test_*.py 2>&1 | head -20}
- Run pytest collection to ensure tests are discovered: !{bash pytest --collect-only tests/ 2>&1 | tail -20}
- Check for common issues:
  - Missing imports
  - Incorrect fixture usage
  - Async/sync mismatches

Phase 7: Summary
Goal: Report test suite generation results

Actions:
- Display summary:
  - Test file location and name
  - Number of test cases generated
  - Fixtures created
  - Coverage areas (success cases, errors, edge cases)
- Provide command to run tests: `pytest tests/test_<name>.py -v`
- Suggest next steps:
  - Review generated tests and customize as needed
  - Add more edge cases if required
  - Update fixtures in conftest.py for reuse
  - Run tests with coverage: `pytest --cov=app tests/`
