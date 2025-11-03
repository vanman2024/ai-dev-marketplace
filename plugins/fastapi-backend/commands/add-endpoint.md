---
description: Generate new API endpoint with validation and documentation
argument-hint: endpoint-path
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch, Skill
---
## Available Skills

This commands has access to the following skills from the fastapi-backend plugin:

- **async-sqlalchemy-patterns**: Async SQLAlchemy 2.0+ database patterns for FastAPI including session management, connection pooling, Alembic migrations, relationship loading strategies, and query optimization. Use when implementing database models, configuring async sessions, setting up migrations, optimizing queries, managing relationships, or when user mentions SQLAlchemy, async database, ORM, Alembic, database performance, or connection pooling.
- **fastapi-api-patterns**: REST API design and implementation patterns for FastAPI endpoints including CRUD operations, pagination, filtering, error handling, and request/response models. Use when building FastAPI endpoints, creating REST APIs, implementing CRUD operations, adding pagination, designing API routes, handling API errors, or when user mentions FastAPI patterns, REST API design, endpoint structure, API best practices, or HTTP endpoints.
- **fastapi-auth-patterns**: Implement and validate FastAPI authentication strategies including JWT tokens, OAuth2 password flows, OAuth2 scopes for permissions, and Supabase integration. Use when implementing authentication, securing endpoints, handling user login/signup, managing permissions, integrating OAuth providers, or when user mentions JWT, OAuth2, Supabase auth, protected routes, access control, role-based permissions, or authentication errors.
- **fastapi-deployment-config**: Configure multi-platform deployment for FastAPI applications including Docker containerization, Railway, DigitalOcean App Platform, and AWS deployment. Use when deploying FastAPI apps, setting up production environments, containerizing applications, configuring cloud platforms, implementing health checks, managing environment variables, setting up reverse proxies, or when user mentions Docker, Railway, DigitalOcean, AWS, deployment configuration, production setup, or container orchestration.
- **fastapi-project-structure**: Production-ready FastAPI project scaffolding templates including directory structure, configuration files, settings management, dependency injection, MCP server integration, and development/production setup patterns. Use when creating FastAPI projects, setting up project structure, configuring FastAPI applications, implementing settings management, adding MCP integration, or when user mentions FastAPI setup, project scaffold, app configuration, environment management, or backend structure.
- **mem0-fastapi-integration**: Memory layer integration patterns for FastAPI with Mem0 including client setup, memory service patterns, user tracking, conversation persistence, and background task integration. Use when implementing AI memory, adding Mem0 to FastAPI, building chat with memory, or when user mentions Mem0, conversation history, user context, or memory layer.

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

Goal: Create a complete FastAPI endpoint with request/response models, validation, documentation, and tests following best practices.

Core Principles:
- Understand existing patterns before generating new code
- Follow FastAPI best practices and conventions
- Generate complete endpoints with proper validation
- Include comprehensive documentation and tests

Phase 1: Discovery
Goal: Gather endpoint requirements and understand project structure

Actions:
- Parse $ARGUMENTS for endpoint path (e.g., "/api/v1/users")
- If $ARGUMENTS is unclear, use AskUserQuestion to gather:
  - What is the endpoint path?
  - What HTTP method(s)? (GET, POST, PUT, DELETE, PATCH)
  - What does this endpoint do?
  - Request/response data structure?
  - Authentication required?
- Detect FastAPI project structure
- Example: !{bash find . -name "main.py" -o -name "app.py" | head -5}
- Locate existing routers and models
- Example: !{bash find . -type f -name "*.py" | grep -E "(router|route|api)" | head -10}

Phase 2: Analysis
Goal: Understand existing code patterns and architecture

Actions:
- Load main application file to understand structure
- Read existing router files to understand patterns
- Read existing model files (Pydantic schemas)
- Identify where new endpoint should be placed
- Check for existing authentication/authorization patterns
- Example: !{bash grep -r "APIRouter\|@router\|@app" --include="*.py" | head -20}

Phase 3: Planning
Goal: Design the endpoint implementation approach

Actions:
- Outline implementation plan:
  - Router location (new or existing file)
  - Request/response models structure
  - Validation requirements
  - Error handling approach
  - Documentation strategy
- Identify dependencies needed
- Present plan to user for confirmation

Phase 4: Reference Documentation
Goal: Load FastAPI best practices and patterns

Actions:
- Load FastAPI documentation for reference:
- WebFetch: https://fastapi.tiangolo.com/tutorial/path-params/
- WebFetch: https://fastapi.tiangolo.com/tutorial/body/
- WebFetch: https://fastapi.tiangolo.com/tutorial/response-model/

Phase 5: Implementation
Goal: Generate complete endpoint with agent

Actions:

Task(description="Generate FastAPI endpoint", subagent_type="endpoint-generator", prompt="You are the endpoint-generator agent. Generate a complete FastAPI endpoint for $ARGUMENTS.

Context:
- Endpoint path: [from $ARGUMENTS]
- HTTP method(s): [from requirements]
- Purpose: [from requirements]
- Project structure: [identified structure]

Requirements:
- Create/update router file in appropriate location
- Generate Pydantic request model with validation
- Generate Pydantic response model
- Include comprehensive docstrings
- Add proper error handling (HTTPException)
- Include example values in schema
- Add OpenAPI tags and metadata
- Follow existing code patterns and conventions
- Use proper typing annotations
- Include input validation (constraints, regex, etc.)

Authentication:
- [Apply auth requirements if specified]

Expected output:
- Router file with endpoint implementation
- Model files with request/response schemas
- Proper imports and dependencies
- Clear inline documentation")

Phase 6: Verification
Goal: Validate the generated endpoint

Actions:
- Check generated files exist
- Example: !{bash find . -name "*.py" -newer /tmp -type f}
- Verify syntax is valid
- Example: !{bash python -m py_compile [generated-file]}
- Check if FastAPI can import the module
- Run linting if configured
- Example: !{bash which ruff && ruff check [generated-file] || echo "Linting skipped"}

Phase 7: Summary
Goal: Document what was accomplished

Actions:
- Summarize changes:
  - Files created/modified
  - Endpoint path and methods
  - Request/response models
  - Validation rules applied
  - Authentication requirements
- Show example usage:
  - cURL command example
  - Expected request/response format
- Suggest next steps:
  - Add unit tests
  - Add integration tests
  - Update API documentation
  - Test with Swagger UI at /docs
