---
description: Initialize complete AI backend with Mem0, PostgreSQL, and async SQLAlchemy
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion, TodoWrite, WebFetch
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

Phase 1: Requirements
Goal: Gather project needs and validate environment

Actions:
- Create todo list using TodoWrite
- Parse project name from $ARGUMENTS
- If unclear, AskUserQuestion: "Project name for your AI backend?"
- Ask: "AI provider? (OpenAI/Anthropic/Google/Multiple)"
- Ask: "Deployment target? (Vercel/Railway/Render/Docker/Local)"
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

Based on fetched documentation, implement:

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
