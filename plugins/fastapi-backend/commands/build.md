---
description: Build complete FastAPI backend for new or existing projects with endpoints, authentication, database, and deployment
argument-hint: [project-name] [--existing]
---

# Build FastAPI Backend

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(fastapi-setup-agent) Analyze project for FastAPI setup.

Detect: Existing Python project, database, auth
Check: Requirements.txt, pyproject.toml
Output: Setup strategy
```

---

## Phase 2: Core Setup

**Goal:** Set up FastAPI application

**Actions:**

```
Task(fastapi-setup-agent) Set up FastAPI core.

Requirements:
- Create FastAPI application
- Configure CORS
- Set up exception handlers
- Add request validation
- Create base router structure
```

---

## Phase 3: Database Setup

**Goal:** Configure database layer

**Actions:**

```
Task(database-architect-agent) Set up database.

Requirements:
- Database type: PostgreSQL (default) or SQLite
- Configure SQLAlchemy or SQLModel
- Create base models
- Set up migrations (Alembic)
- Add connection pooling
```

---

## Phase 4: Authentication

**Goal:** Add authentication system

**Actions:**

```
Task(endpoint-generator-agent) Set up authentication.

Requirements:
- Auth type: JWT (default)
- Create auth routes (login, register, refresh)
- Add password hashing
- Configure OAuth2 scheme
- Set up protected route decorator
```

---

## Phase 5: API Endpoints

**Goal:** Create base API structure

**Actions:**

```
Task(endpoint-generator-agent) Create base endpoints.

Requirements:
- Health check endpoint
- User CRUD endpoints
- API versioning (v1)
- OpenAPI documentation
- Response models
```

---

## Phase 6: Deployment

**Goal:** Prepare for production

**Actions:**

```
Task(deployment-architect-agent) Configure deployment.

Requirements:
- Create Dockerfile
- Set up docker-compose
- Configure environment variables
- Add Gunicorn/Uvicorn config
- Create deployment scripts
```

---

## Summary

**Output:**

```
✅ FastAPI Backend Complete

To add features:
  /fastapi-backend:add endpoint <name>  # Add API endpoint
  /fastapi-backend:add auth <type>      # Add authentication
  /fastapi-backend:add database <type>  # Database setup
  /fastapi-backend:add deploy <platform># Deployment config

To run:
  uvicorn main:app --reload
```
