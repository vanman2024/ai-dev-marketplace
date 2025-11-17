---
description: Integrate authentication (JWT, OAuth2, Supabase) into FastAPI project
argument-hint: auth-type
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

Goal: Integrate authentication into a FastAPI project with support for JWT, OAuth2, or Supabase authentication providers.

Core Principles:
- Detect existing project structure before implementing
- Ask for auth type if not specified in $ARGUMENTS
- Follow FastAPI security best practices
- Use WebFetch to load current FastAPI security documentation
- Provide complete, production-ready authentication implementation

Phase 1: Discovery
Goal: Understand project structure and authentication requirements

Actions:
- Parse $ARGUMENTS for authentication type (jwt, oauth2, supabase)
- If auth type not specified, use AskUserQuestion to ask:
  - Which authentication method? (JWT, OAuth2.0, Supabase)
  - What user storage? (PostgreSQL, MongoDB, SQLite, Supabase)
  - Need role-based access control (RBAC)?
  - OAuth providers if applicable? (Google, GitHub, Microsoft)
- Detect FastAPI project structure:
  - !{bash find . -name "main.py" -o -name "app.py" 2>/dev/null | head -5}
  - !{bash find . -name "requirements.txt" -o -name "pyproject.toml" 2>/dev/null}
- Load main application file for context

Phase 2: Analysis
Goal: Understand existing code patterns and architecture

Actions:
- Identify current project structure:
  - Main app file location
  - Route organization (routers vs single file)
  - Database setup (SQLAlchemy, raw SQL, etc.)
  - Configuration management (.env, settings.py)
- Check for existing authentication:
  - !{bash grep -r "OAuth2PasswordBearer\|HTTPBearer\|Depends" --include="*.py" . 2>/dev/null | head -10}
- Determine where to place auth module:
  - Typical: app/auth/ or src/auth/ or auth/

Phase 3: Planning
Goal: Design authentication implementation approach

Actions:
- Based on selected auth type, outline implementation:
  - **JWT**: Token generation, verification, password hashing, user model
  - **OAuth2**: Provider integration, callback handling, token exchange
  - **Supabase**: Client setup, auth middleware, RLS integration
- Identify files to create/modify:
  - Auth module (auth.py or auth/ directory)
  - User models (if needed)
  - Dependencies (security dependencies)
  - Routes (login, register, logout endpoints)
  - Configuration (secrets, OAuth credentials)
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Implement authentication with specialized agent

Actions:

Task(description="Implement FastAPI authentication", subagent_type="auth-specialist", prompt="You are the auth-specialist agent. Implement authentication for this FastAPI project.

**Authentication Type**: $ARGUMENTS

**Context from Discovery**:
- Project structure identified
- Main app location found
- Database configuration detected
- User preferences gathered

**Implementation Requirements**:
- Use WebFetch to load FastAPI security documentation:
  - https://fastapi.tiangolo.com/tutorial/security/
  - https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/
  - Provider-specific docs if OAuth2
- Follow FastAPI best practices for security
- Implement complete authentication flow:
  - Password hashing (bcrypt or passlib)
  - Token generation and validation
  - Protected route dependencies
  - User registration endpoint
  - Login endpoint
  - Current user retrieval
- Add necessary dependencies to requirements.txt or pyproject.toml
- Create .env.example with required secrets
- Use existing code patterns and structure
- Include error handling and validation
- Add type hints throughout

**Deliverables**:
1. Auth module with all security utilities
2. User model (if not exists)
3. Authentication routes
4. Protected route example
5. Updated dependencies file
6. .env.example with required variables
7. Brief documentation of usage")

Phase 5: Validation
Goal: Verify authentication implementation works

Actions:
- Check all files were created:
  - !{bash find . -path "*/auth/*" -o -name "*auth*.py" 2>/dev/null | grep -v __pycache__}
- Verify dependencies added:
  - !{bash grep -E "python-jose|passlib|bcrypt|python-multipart|supabase" requirements.txt pyproject.toml 2>/dev/null}
- Check for syntax errors:
  - !{bash python -m py_compile $(find . -name "*auth*.py" -not -path "*/.venv/*" -not -path "*/venv/*" 2>/dev/null) 2>&1 || echo "Note: Install dependencies to validate"}
- Verify .env.example exists with required secrets

Phase 6: Summary
Goal: Document what was accomplished and next steps

Actions:
- Summarize implementation:
  - Authentication type implemented
  - Files created/modified
  - Dependencies added
  - Environment variables required
- Provide usage example:
  - How to protect routes
  - How to get current user
  - How to test authentication
- Next steps:
  - Install dependencies: pip install -r requirements.txt
  - Copy .env.example to .env and fill in secrets
  - Run migrations if database changes needed
  - Test authentication endpoints
  - Consider adding refresh tokens
  - Consider adding password reset flow
