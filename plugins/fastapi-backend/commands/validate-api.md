---
description: Validate API schema, endpoints, and security
argument-hint: [api-directory]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, TodoWrite, WebFetch
---

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

## Usage

/fastapi-backend:validate-api
/fastapi-backend:validate-api ./backend
/fastapi-backend:validate-api /path/to/api
