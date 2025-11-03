---
description: Search and add FastAPI examples/patterns to your project
argument-hint: <topic>
allowed-tools: Read, Write, Bash, Glob, Grep, WebFetch, Skill
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

Goal: Search FastAPI documentation and examples for specific patterns/topics and provide code examples that can be added to the project.

Core Principles:
- Fetch examples from official FastAPI documentation
- Provide production-ready code patterns
- Include multiple implementation options when available
- Show best practices and common use cases

Phase 1: Parse Request
Goal: Understand what examples are being requested

Actions:
- Parse $ARGUMENTS for the topic/pattern to search
- Identify search category (routing, database, auth, middleware, testing, etc.)
- Set search scope based on topic keywords

Example topics:
- "authentication" → OAuth2, JWT, API keys
- "database" → SQLAlchemy, async ORM, migrations
- "validation" → Pydantic models, request validation
- "middleware" → CORS, authentication, logging
- "websockets" → WebSocket endpoints, broadcasting
- "testing" → pytest, async testing, fixtures
- "deployment" → Docker, uvicorn, production config
- "background" → background tasks, Celery
- "file upload" → file handling, multipart forms
- "dependencies" → dependency injection patterns

Phase 2: Load Documentation
Goal: Fetch relevant FastAPI documentation and examples

Actions:
- Based on topic, load appropriate documentation sections
- Fetch official FastAPI examples from GitHub
- Load best practice guides

**Authentication & Security Examples:**
WebFetch: https://fastapi.tiangolo.com/tutorial/security/
WebFetch: https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/

**Database Integration Examples:**
WebFetch: https://fastapi.tiangolo.com/tutorial/sql-databases/
WebFetch: https://fastapi.tiangolo.com/advanced/async-sql-databases/

**Request Validation & Pydantic:**
WebFetch: https://fastapi.tiangolo.com/tutorial/body/
WebFetch: https://fastapi.tiangolo.com/tutorial/body-multiple-params/

**Middleware & CORS:**
WebFetch: https://fastapi.tiangolo.com/tutorial/cors/
WebFetch: https://fastapi.tiangolo.com/advanced/middleware/

**WebSocket Examples:**
WebFetch: https://fastapi.tiangolo.com/advanced/websockets/

**Background Tasks:**
WebFetch: https://fastapi.tiangolo.com/tutorial/background-tasks/

**Testing Examples:**
WebFetch: https://fastapi.tiangolo.com/tutorial/testing/

**Deployment Guides:**
WebFetch: https://fastapi.tiangolo.com/deployment/docker/
WebFetch: https://fastapi.tiangolo.com/deployment/server-workers/

Phase 3: Find Matching Examples
Goal: Identify and extract relevant code examples

Actions:
- Review fetched documentation for topic match
- Extract complete, runnable code examples
- Identify dependencies and imports needed
- Note any configuration requirements

Phase 4: Analyze Project Context
Goal: Understand how to integrate examples into current project

Actions:
- Check if project exists in current directory:
  !{bash test -f main.py && echo "FastAPI project found" || echo "No main.py found"}
- Look for existing patterns:
  !{bash test -d app && ls app/*.py 2>/dev/null || echo "No app directory"}
- Check for requirements.txt or pyproject.toml:
  !{bash ls requirements.txt pyproject.toml 2>/dev/null}
- Identify project structure (flat vs app directory)

Phase 5: Present Examples
Goal: Display examples with integration guidance

Actions:
- Show 2-3 most relevant code examples for the topic
- Include complete code with imports
- Explain each example's use case
- List required dependencies
- Provide integration steps:
  1. Required pip packages
  2. Where to add the code (file structure)
  3. Configuration needed
  4. How to test the implementation

**Output Format for Each Topic:**

Topic: $ARGUMENTS

Example 1: [Pattern Name]
- Use case: [When to use this pattern]
- Dependencies: [pip packages needed]
- Complete code example with imports
- Integration: Add to app/[module].py
- Install: pip install [packages]
- Configure: [any settings needed]

Example 2: [Alternative Pattern]
- Repeat format above

Best Practices:
- [Key consideration 1]
- [Key consideration 2]
- [Key consideration 3]

Next Steps:
- Review examples and choose appropriate pattern
- Install dependencies: pip install [packages]
- Implement in your project structure
- Run tests to verify

Phase 6: Summary
Goal: Provide clear next steps

Actions:
- Summarize examples provided
- List all dependencies needed
- Suggest which example to start with based on project context
- Offer to implement the chosen example if user requests
- Reference official docs for deeper dive
