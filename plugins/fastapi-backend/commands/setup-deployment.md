---
description: Configure deployment for FastAPI (Docker, Railway, DigitalOcean)
argument-hint: <platform> (docker|railway|digitalocean|all)
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, mcp__context7
---

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
