---
description: Configure deployment for FastAPI (Docker, Railway, DigitalOcean)
argument-hint: <platform> (docker|railway|digitalocean|all)
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

Goal: Configure production deployment for FastAPI backend with Docker and platform-specific configs.

Core Principles:
- Detect FastAPI structure before configuring
- Ask about deployment requirements
- Use official FastAPI deployment best practices
- Support multiple platforms with optimized configurations

Phase 1: Discovery

Actions:

Detect FastAPI structure:
!{bash if [ -f "main.py" ] || [ -f "app/main.py" ]; then echo "FastAPI detected"; else echo "No main.py"; fi}

Check existing config:
!{bash ls Dockerfile docker-compose.yml requirements.txt 2>/dev/null || echo "No config"}

Load project files:
@requirements.txt

Get Python version:
!{bash python3 --version 2>/dev/null || python --version}

Parse $ARGUMENTS for platform. If empty, ask user.

Phase 2: Requirements

Actions:

AskUserQuestion to gather:
- Platform? (docker, railway, digitalocean, all)
- Database? (postgresql, mysql, none)
- Redis needed? (yes/no)
- CORS origins? (domains or *)
- Health checks? (yes/no)

Phase 3: Configuration

Actions:

Task(description="Configure FastAPI deployment", subagent_type="fastapi-backend:deployment-architect-agent", prompt="You are the deployment-architect-agent. Configure production deployment for this FastAPI backend.

Project: [from Phase 1]
Platform: $ARGUMENTS or [from AskUserQuestion]
Database: [from user]
Redis: [from user]
CORS: [from user]
Health checks: [from user]

Tasks:
1. Dockerfile (multi-stage, slim base, non-root, Gunicorn+Uvicorn)
2. docker-compose.yml (FastAPI, DB, Redis if needed)
3. .dockerignore (exclude __pycache__, .venv, .git, tests)
4. railway.json (if Railway)
5. .env.example (all variables with comments)
6. config/production.py (HTTPS, CORS, security headers)
7. /health endpoint (if requested)
8. docs/deployment.md (platform instructions)

Reference docs:
- https://fastapi.tiangolo.com/deployment/
- https://docs.docker.com/develop/dev-best-practices/
- https://docs.gunicorn.org/en/stable/
- https://docs.railway.app/
- https://docs.digitalocean.com/products/app-platform/

Deliverable: Complete deployment files")

Wait for agent to complete.

Phase 4: Validation

Actions:

Check files created:
!{bash ls Dockerfile .dockerignore 2>/dev/null | wc -l}

Verify env template:
!{bash test -f .env.example && echo "Created" || echo "Missing"}

Check docs:
!{bash test -f docs/deployment.md && echo "Created" || echo "Missing"}

Phase 5: Summary

Actions:

Display summary:
- Platform: [platform]
- Files: Dockerfile, docker-compose.yml, .env.example, docs/deployment.md
- Next steps:
  1. Copy .env.example to .env
  2. Set DATABASE_URL and SECRET_KEY
  3. Configure CORS origins

Docker: docker-compose up --build
Railway: railway login && railway up
DigitalOcean: doctl apps create --spec

Security: Strong SECRET_KEY, HTTPS, rate limiting, monitoring
