---
description: Build complete FastAPI backend application - initializes project if needed, then runs all specialized agents in parallel for database setup, endpoints, auth, and deployment
argument-hint: <project-name> [--from-spec <spec-path>]
---

# Build Complete FastAPI Backend

**Goal:** Create a production-ready FastAPI backend by orchestrating all specialized agents in parallel.

**This command handles everything** - from initialization to full build. If no project exists, it creates one. If a project exists, it enhances it.

## Stack (Always Use Latest Versions)

- **FastAPI** - Latest with async/await, dependency injection
- **Python** - Latest stable (3.12+)
- **Pydantic** - Latest v2 with settings management
- **SQLAlchemy** - Latest async 2.0+ with Alembic migrations
- **PostgreSQL/Supabase** - Latest for database
- **Uvicorn** - Latest ASGI server
- **Docker** - Latest for containerization

**IMPORTANT:** Always check for and use the most recent stable versions of all dependencies. Use `pip index versions <package>` or check PyPI for current versions.

## Arguments

- `$ARGUMENTS` - Project name and optional spec path
- `--from-spec <path>` - Build from architecture specification

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and spec path
2. Check if project exists or needs creation
3. Discover architecture documentation:
   ```
   !{glob docs/architecture/**/*.md}
   !{glob specs/*/spec.md}
   ```
4. Create execution plan based on what's found

### Phase 2: Project Initialization (if needed)

**If no project exists, run setup agent:**

```
Task("Initialize FastAPI project", @fastapi-setup-agent, {
  prompt: "Initialize FastAPI project named '$PROJECT_NAME' with:
    - Modern async/await patterns (latest Python)
    - Pydantic v2 settings management
    - Proper project structure (app/, tests/, alembic/)
    - Environment variable templates (.env.example)
    - pyproject.toml with latest dependencies
    Create complete project scaffold."
})
```

**Wait for setup to complete before proceeding.**

### Phase 3: Parallel Agent Execution

**Launch ALL specialized agents simultaneously using Task():**

```
// Agent 1: Database Architecture
Task("Setup database layer", @database-architect-agent, {
  prompt: "Configure complete database layer:
    - Async SQLAlchemy with latest 2.0+ patterns
    - Connection pooling and session management
    - Alembic migration setup
    - Base models with timestamps, soft delete
    - PostgreSQL/Supabase integration
    Follow architecture docs for schema design."
})

// Agent 2: Endpoint Generation
Task("Build all API endpoints", @endpoint-generator-agent, {
  prompt: "Generate ALL API endpoints from architecture docs:
    - Discover docs/architecture/**/api.md
    - Extract complete endpoint list
    - Create all routes with Pydantic validation
    - Implement proper error handling
    - Add OpenAPI documentation
    Build endpoints concurrently."
})

// Agent 3: Deployment Configuration
Task("Configure deployment", @deployment-architect-agent, {
  prompt: "Set up production deployment:
    - Multi-stage Dockerfile (optimized)
    - Docker Compose for local dev
    - Health check endpoints
    - Environment variable management
    - Railway/DigitalOcean deployment configs
    Follow deployment patterns from architecture."
})
```

### Phase 4: Integration & Validation

**After parallel execution completes:**

```
// Validate the complete API
Task("Validate API implementation", @endpoint-generator-agent, {
  prompt: "Validate the complete FastAPI implementation:
    - Check all endpoints are documented
    - Verify Pydantic models are complete
    - Test database connections
    - Validate authentication flows
    - Check CORS configuration
    Report any issues found."
})
```

### Phase 5: Final Output

**Provide summary:**

- List all created files
- Show project structure
- Provide run commands:

  ```bash
  # Development
  uvicorn app.main:app --reload

  # With Docker
  docker-compose up -d
  ```

- Note any manual steps needed (database migrations, env vars)

## Utility Commands

For individual tasks, use these commands instead:

- `/fastapi-backend:add-endpoint` - Add single API endpoint
- `/fastapi-backend:add-auth` - Add authentication to existing project
- `/fastapi-backend:setup-database` - Configure database only
- `/fastapi-backend:setup-deployment` - Configure deployment only
- `/fastapi-backend:add-testing` - Generate test suite
- `/fastapi-backend:integrate-mem0` - Add Mem0 memory layer
