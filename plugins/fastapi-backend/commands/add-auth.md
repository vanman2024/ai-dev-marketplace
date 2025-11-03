---
description: Integrate authentication (JWT, OAuth2, Supabase) into FastAPI project
argument-hint: auth-type
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
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
