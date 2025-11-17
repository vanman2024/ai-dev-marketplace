---
description: Validate API schema, endpoints, and security
argument-hint: [api-directory]
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

Goal: Validate FastAPI schema, endpoints, and security using parallel validation agents.

Core Principles:
- Detect API structure and configuration
- Fetch FastAPI OpenAPI/security docs
- Run parallel validation: schema, endpoints, security
- Provide actionable validation report

Phase 1: Discovery
Goal: Understand API structure

Actions:
- Parse $ARGUMENTS for API directory (default: current directory)
- Verify directory exists: !{bash test -d "$ARGUMENTS" && echo "Found" || echo "Not found"}
- If not found: Use current directory !{bash pwd}
- Detect FastAPI files: !{bash find "$ARGUMENTS" -name "main.py" -o -name "app.py" -type f 2>/dev/null | head -5}
- Load key files: @$ARGUMENTS/main.py or @$ARGUMENTS/app.py
- Check for requirements.txt or pyproject.toml
- Create validation todo list

Phase 2: Fetch Documentation
Goal: Get FastAPI validation docs

Actions:
Fetch these docs in parallel:

1. WebFetch: https://fastapi.tiangolo.com/reference/openapi/
2. WebFetch: https://fastapi.tiangolo.com/advanced/security/
3. WebFetch: https://fastapi.tiangolo.com/tutorial/metadata/

Phase 3: Parallel Validation
Goal: Run independent validation checks simultaneously

Actions:

Launch three validation agents in parallel:

Task(description="Validate API schema", subagent_type="general-purpose", prompt="You are a schema validation specialist. Validate the FastAPI schema for $ARGUMENTS.

Check:
- OpenAPI schema generation (app.openapi())
- Response models use Pydantic properly
- Request validation schemas defined
- Field validators and constraints
- Enum usage for fixed values
- Optional vs Required fields correct

Use fetched OpenAPI documentation.

Deliverable: Schema validation report with issues found.")

Task(description="Validate API endpoints", subagent_type="general-purpose", prompt="You are an endpoint validation specialist. Validate FastAPI endpoints for $ARGUMENTS.

Check:
- Route naming conventions (REST best practices)
- HTTP methods match operations (GET/POST/PUT/DELETE/PATCH)
- Path parameters properly typed
- Query parameters with defaults
- Status codes appropriate for operations
- Error responses defined
- Dependency injection usage
- CORS configuration if needed

Deliverable: Endpoint validation report with issues found.")

Task(description="Validate API security", subagent_type="general-purpose", prompt="You are a security validation specialist. Validate FastAPI security for $ARGUMENTS.

Check:
- Authentication schemes defined (OAuth2, API key, JWT)
- Security dependencies applied to protected routes
- HTTPS/SSL configuration recommendations
- CORS properly restricted
- Rate limiting considerations
- SQL injection protection (ORM usage)
- Input sanitization
- Secret management (no hardcoded keys)
- Environment variables for sensitive data

Use fetched security documentation.

Deliverable: Security validation report with issues and recommendations.")

Wait for all three agents to complete before proceeding.

Phase 4: Verification
Goal: Run automated checks

Actions:
- Python syntax check: !{bash cd "$ARGUMENTS" && python -m py_compile *.py 2>&1}
- Generate OpenAPI schema: !{bash cd "$ARGUMENTS" && python -c "from main import app; import json; print(json.dumps(app.openapi(), indent=2))" 2>&1 | head -50}
- Check dependencies installed: !{bash test -f "$ARGUMENTS/requirements.txt" && pip freeze | grep -f "$ARGUMENTS/requirements.txt" || echo "No requirements.txt"}
- Mark verification complete

Phase 5: Consolidated Report
Goal: Combine all validation results

Actions:
- Aggregate findings from all three agents
- Write VALIDATION-REPORT.md with sections:
  * Schema Validation Results
  * Endpoint Validation Results
  * Security Validation Results
  * Automated Checks
  * Priority Issues (High/Medium/Low)
  * Recommendations
  * Next Steps

- Display: @VALIDATION-REPORT.md

- Status summary:
  * All passed: "✅ API Validation PASSED"
  * Minor issues: "⚠️ Validation passed with warnings"
  * Critical issues: "❌ Validation FAILED - Fix critical issues"

- Mark all todos complete

Important Notes:
- Three agents run in parallel for speed
- Adapts to main.py or app.py entry points
- Uses FastAPI official docs for validation rules
- Produces actionable report with prioritized fixes
- Checks both code quality and security

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


## Usage

/fastapi-backend:validate-api
/fastapi-backend:validate-api ./backend
/fastapi-backend:validate-api /path/to/api
