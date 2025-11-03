---
description: Configure async SQLAlchemy with PostgreSQL/Supabase
argument-hint: <database-type>
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
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

Goal: Set up async SQLAlchemy database configuration with PostgreSQL or Supabase, including models, sessions, and migrations.

Core Principles:
- Detect existing project structure before creating files
- Use async/await patterns for all database operations
- Follow SQLAlchemy 2.0+ best practices
- Configure proper connection pooling and session management

Phase 1: Discovery
Goal: Understand project structure and database requirements

Actions:
- Parse $ARGUMENTS to determine database type (postgresql/supabase)
- If unclear, use AskUserQuestion to gather:
  - What database are you using? (PostgreSQL, Supabase)
  - Do you need authentication tables?
  - Any specific models to create?
- Detect existing FastAPI project structure
- Check for existing database configuration
- Example: !{bash ls -la src/ app/ 2>/dev/null | head -20}

Phase 2: Context Loading
Goal: Load relevant FastAPI files and understand current setup

Actions:
- Find main application file
- Example: !{bash find . -name "main.py" -o -name "app.py" 2>/dev/null | head -5}
- Check for existing requirements/dependencies
- Example: @requirements.txt or @pyproject.toml
- Identify where database code should live

Phase 3: Requirements Validation
Goal: Confirm database setup approach

Actions:
- Present proposed structure to user:
  - Database URL configuration (.env)
  - Models directory structure
  - Session management (dependency injection)
  - Alembic migrations setup
- Get user confirmation before proceeding

Phase 4: Implementation
Goal: Create complete async database setup

Actions:

Task(description="Setup async SQLAlchemy database", subagent_type="database-architect-agent", prompt="You are the database-architect-agent. Configure async SQLAlchemy with $ARGUMENTS database.

Context:
- FastAPI project structure detected
- Database type: $ARGUMENTS
- Need async/await patterns throughout
- SQLAlchemy 2.0+ syntax required

Requirements:
- Create database configuration module with async engine and session
- Set up proper connection pooling (pool_pre_ping, pool_size, max_overflow)
- Create base model class with common fields (id, created_at, updated_at)
- Configure session dependency for FastAPI dependency injection
- Set up Alembic for migrations
- Create .env.example with database URL template
- Add required dependencies to requirements.txt or pyproject.toml
- Include example model demonstrating relationships and async queries

For Supabase:
- Configure PostgREST compatibility
- Include Row Level Security (RLS) considerations
- Document Supabase-specific setup steps

For PostgreSQL:
- Standard asyncpg driver configuration
- Connection string format

Reference FastAPI SQL database documentation:
- WebFetch: https://fastapi.tiangolo.com/tutorial/sql-databases/
- WebFetch: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html

Expected output:
- src/database.py or app/database.py (engine, session, dependency)
- src/models/base.py (base model class)
- src/models/__init__.py (model exports)
- src/models/example.py (example model)
- alembic.ini and alembic/ directory (migrations)
- .env.example (database URL template)
- Updated dependencies file
- Brief setup instructions")

Phase 5: Verification
Goal: Validate the database setup

Actions:
- Check all required files were created
- Verify imports are correct
- Test database connection (optional)
- Example: !{bash python -m pip list | grep -i sqlalchemy}
- Review generated code for async/await consistency

Phase 6: Summary
Goal: Provide setup instructions and next steps

Actions:
- List all files created
- Provide database setup instructions:
  - Copy .env.example to .env
  - Update DATABASE_URL with credentials
  - Run migrations: alembic upgrade head
  - Create first migration: alembic revision --autogenerate -m "Initial"
- Highlight key patterns:
  - How to create new models
  - How to use database session in routes
  - How to run migrations
- Suggest next steps:
  - Create specific models for your domain
  - Set up database seeding
  - Add database testing utilities
