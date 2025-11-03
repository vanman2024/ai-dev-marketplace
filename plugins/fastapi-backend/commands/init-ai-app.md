---
description: Initialize complete AI backend with Mem0, PostgreSQL, and async SQLAlchemy
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion, TodoWrite, WebFetch, Skill
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

Goal: Create production-ready FastAPI backend with Mem0 memory, PostgreSQL, and async SQLAlchemy

Core Principles:
- Fetch latest documentation before building
- Ask clarifying questions early
- Validate environment before setup
- Track progress with todos

Phase 1: Architecture Detection
Goal: Check if architecture docs exist and load backend requirements

Actions:
- Create todo list using TodoWrite
- Parse project name from $ARGUMENTS
- Check for architecture docs: !{bash test -f docs/architecture/backend.md && echo "spec-driven" || echo "interactive"}

- If spec-driven (architecture docs exist):
  - Load backend architecture: @docs/architecture/backend.md
  - Load data architecture: @docs/architecture/data.md
  - Load AI architecture: @docs/architecture/ai.md
  - Extract from architecture:
    - API endpoints and routes (from backend.md)
    - Database models and schema (from data.md)
    - AI provider requirements (from ai.md)
    - Authentication requirements (from backend.md)
  - Display: "📋 Building from docs/architecture/*.md"
  - Store architecture context for agent

- If interactive (no architecture docs):
  - Ask: "AI provider? (OpenAI/Anthropic/Google/Multiple)"
  - Ask: "Deployment target? (Vercel/Railway/Render/Docker/Local)"
  - Use defaults for structure

- Validate Python: !{bash python3 --version}
- Check directory: !{bash test -d "$ARGUMENTS" && echo "exists" || echo "new"}

Phase 2: Documentation
Goal: Fetch latest setup guides

Actions:
Use WebFetch to load documentation in parallel:
- https://docs.mem0.ai/getting-started
- https://docs.mem0.ai/api-reference
- https://fastapi.tiangolo.com/tutorial/sql-databases/
- https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
- https://docs.pydantic.dev/latest/concepts/pydantic_settings/

Wait for all to complete. Update todos.

Phase 3: Implementation
Goal: Build complete FastAPI AI backend

Actions:

Task(description="Build FastAPI AI backend", subagent_type="fastapi-backend-builder", prompt="You are the fastapi-backend-builder agent. Create a complete FastAPI backend with Mem0, PostgreSQL, and async SQLAlchemy for $ARGUMENTS.

ARCHITECTURE CONTEXT:
- If docs/architecture/backend.md exists: Read and implement API endpoints, services, and routes from architecture
- If docs/architecture/data.md exists: Read and implement database models and schema from architecture
- If docs/architecture/ai.md exists: Read and implement AI integrations from architecture

Based on architecture documentation (if available) and fetched API documentation, implement:

1. Project Structure:
   - Create $ARGUMENTS directory with src/app layout
   - requirements.txt with: fastapi[all], uvicorn[standard], sqlalchemy[asyncio], asyncpg, pydantic-settings, mem0ai, python-dotenv, alembic, pytest

2. Database (src/app/db/):
   - database.py: async engine, AsyncSession factory
   - models.py: Base, example User/Conversation models
   - deps.py: get_db dependency

3. Mem0 Integration (src/app/memory/):
   - mem0_client.py: Mem0 initialization
   - memory_manager.py: add/get/search/delete operations
   - schemas.py: Memory Pydantic models

4. API Structure (src/app/):
   - main.py: FastAPI app, CORS, lifecycle events, health endpoint
   - api/v1/router.py: aggregate routes
   - api/v1/endpoints/memory.py: POST/GET/DELETE memory endpoints
   - api/v1/endpoints/chat.py: POST /chat with memory context
   - config.py: Pydantic Settings for env vars

5. Configuration:
   - .env.example: DATABASE_URL, MEM0_API_KEY, AI provider keys, server settings
   - docker-compose.yml: PostgreSQL service
   - alembic.ini: async migration config
   - pytest.ini: test configuration

6. Development Tools:
   - Makefile: dev, migrate, test, format commands
   - tests/conftest.py: fixtures
   - .gitignore: Python/FastAPI standard

7. Documentation:
   - README.md: setup, quickstart, API docs, deployment

Follow async/await patterns from SQLAlchemy docs. Use Pydantic v2 for all models. Include error handling and type hints.

Deliverable: Complete working FastAPI backend with all files created and documented.")

Phase 4: Validation
Goal: Verify setup is complete and functional

Actions:
- Verify structure: !{bash ls -la $ARGUMENTS/src/app}
- Check dependencies: !{bash test -f $ARGUMENTS/requirements.txt && wc -l $ARGUMENTS/requirements.txt}
- Validate Python syntax: !{bash python3 -m py_compile $ARGUMENTS/src/app/main.py}
- Test imports: !{bash cd $ARGUMENTS && python3 -c "from src.app.main import app; print('OK')"}
- Update todos marking validation complete

Phase 5: Summary
Goal: Present setup information and next steps

Actions:
Display:
- Project created at $ARGUMENTS/
- FastAPI + Mem0 + PostgreSQL + SQLAlchemy configured
- Key files: main.py, db/, memory/, api/v1/

Next Steps:
1. cd $ARGUMENTS
2. pip install -r requirements.txt
3. Configure .env from .env.example
4. Get Mem0 API key: https://mem0.ai
5. docker-compose up -d (PostgreSQL)
6. alembic upgrade head (migrations)
7. uvicorn src.app.main:app --reload
8. Visit http://localhost:8000/docs

Mark all todos complete.

Resources:
- Mem0: https://docs.mem0.ai
- FastAPI: https://fastapi.tiangolo.com
- SQLAlchemy Async: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
