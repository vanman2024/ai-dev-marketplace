---
description: Initialize Redis in project with framework detection
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite, AskUserQuestion
---

🚨 **EXECUTION NOTICE FOR CLAUDE**
[Standard execution notice - see CLAUDE.md]

## Security Requirements
@~/.claude/plugins/marketplaces/dev-lifecycle-marketplace/docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

**Goal**: Initialize Redis in a project with automatic framework detection and production-ready configuration.

**Core Principles**:
- Auto-detect framework before configuration
- Environment variables for all credentials
- Never hardcode passwords or connection strings
- Verify setup before completion

**Phase 0: Create Todo List**
TodoWrite: Track all initialization phases

**Phase 1: Discovery**
Goal: Detect framework and project structure

Actions:
- Parse $ARGUMENTS for project path (default: current directory)
- Detect framework:
  - Read package.json → Node.js (Next.js, Express)
  - Read requirements.txt/pyproject.toml → Python (FastAPI, Django, Flask)
- Check for existing Redis configuration
- Ask about deployment target (local Docker, Redis Cloud, self-hosted)

**Phase 2: Load Documentation**
Goal: Fetch framework-specific Redis docs

Actions:
- WebFetch: https://redis.io/docs/latest/develop/connect/clients/
- Based on framework:
  - If Python: WebFetch https://redis.io/docs/latest/develop/clients/redis-py/
  - If Node.js: WebFetch https://redis.io/docs/latest/develop/clients/node-redis/

**Phase 3: Implementation**
Goal: Set up Redis client and configuration

Actions:
Task(description="Initialize Redis", subagent_type="redis:redis-setup-agent", prompt="Initialize Redis for detected framework.

Framework: [detected framework]
Deployment target: [user selected]

Deliverables:
- Install Redis client library
- Create .env.example with placeholders
- Create .env.development for local Docker
- Configure Redis client with connection pooling
- Add to framework (lifespan events, singleton, middleware)
- Create docker-compose.yml if needed
- Add .gitignore rules for .env files
- Test connection with ping")

**Phase 4: Verification**
Goal: Test Redis setup

Actions:
- Run connection test
- Verify .env files created correctly
- Check .gitignore protects secrets
- Validate no hardcoded credentials

**Phase 5: Summary**
Goal: Display setup results

Actions:
- Show what was configured
- Display .env.example content
- Next steps (add caching, sessions, etc.)
- Security reminders
