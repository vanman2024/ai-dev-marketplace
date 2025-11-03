---
description: Generate new API endpoint with validation and documentation
argument-hint: endpoint-path
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch
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

Goal: Create a complete FastAPI endpoint with request/response models, validation, documentation, and tests following best practices.

Core Principles:
- Understand existing patterns before generating new code
- Follow FastAPI best practices and conventions
- Generate complete endpoints with proper validation
- Include comprehensive documentation and tests

Phase 1: Discovery
Goal: Gather endpoint requirements and understand project structure

Actions:
- Parse $ARGUMENTS for endpoint path (e.g., "/api/v1/users")
- If $ARGUMENTS is unclear, use AskUserQuestion to gather:
  - What is the endpoint path?
  - What HTTP method(s)? (GET, POST, PUT, DELETE, PATCH)
  - What does this endpoint do?
  - Request/response data structure?
  - Authentication required?
- Detect FastAPI project structure
- Example: !{bash find . -name "main.py" -o -name "app.py" | head -5}
- Locate existing routers and models
- Example: !{bash find . -type f -name "*.py" | grep -E "(router|route|api)" | head -10}

Phase 2: Analysis
Goal: Understand existing code patterns and architecture

Actions:
- Load main application file to understand structure
- Read existing router files to understand patterns
- Read existing model files (Pydantic schemas)
- Identify where new endpoint should be placed
- Check for existing authentication/authorization patterns
- Example: !{bash grep -r "APIRouter\|@router\|@app" --include="*.py" | head -20}

Phase 3: Planning
Goal: Design the endpoint implementation approach

Actions:
- Outline implementation plan:
  - Router location (new or existing file)
  - Request/response models structure
  - Validation requirements
  - Error handling approach
  - Documentation strategy
- Identify dependencies needed
- Present plan to user for confirmation

Phase 4: Reference Documentation
Goal: Load FastAPI best practices and patterns

Actions:
- Load FastAPI documentation for reference:
- WebFetch: https://fastapi.tiangolo.com/tutorial/path-params/
- WebFetch: https://fastapi.tiangolo.com/tutorial/body/
- WebFetch: https://fastapi.tiangolo.com/tutorial/response-model/

Phase 5: Implementation
Goal: Generate complete endpoint with agent

Actions:

Task(description="Generate FastAPI endpoint", subagent_type="endpoint-generator", prompt="You are the endpoint-generator agent. Generate a complete FastAPI endpoint for $ARGUMENTS.

Context:
- Endpoint path: [from $ARGUMENTS]
- HTTP method(s): [from requirements]
- Purpose: [from requirements]
- Project structure: [identified structure]

Requirements:
- Create/update router file in appropriate location
- Generate Pydantic request model with validation
- Generate Pydantic response model
- Include comprehensive docstrings
- Add proper error handling (HTTPException)
- Include example values in schema
- Add OpenAPI tags and metadata
- Follow existing code patterns and conventions
- Use proper typing annotations
- Include input validation (constraints, regex, etc.)

Authentication:
- [Apply auth requirements if specified]

Expected output:
- Router file with endpoint implementation
- Model files with request/response schemas
- Proper imports and dependencies
- Clear inline documentation")

Phase 6: Verification
Goal: Validate the generated endpoint

Actions:
- Check generated files exist
- Example: !{bash find . -name "*.py" -newer /tmp -type f}
- Verify syntax is valid
- Example: !{bash python -m py_compile [generated-file]}
- Check if FastAPI can import the module
- Run linting if configured
- Example: !{bash which ruff && ruff check [generated-file] || echo "Linting skipped"}

Phase 7: Summary
Goal: Document what was accomplished

Actions:
- Summarize changes:
  - Files created/modified
  - Endpoint path and methods
  - Request/response models
  - Validation rules applied
  - Authentication requirements
- Show example usage:
  - cURL command example
  - Expected request/response format
- Suggest next steps:
  - Add unit tests
  - Add integration tests
  - Update API documentation
  - Test with Swagger UI at /docs
