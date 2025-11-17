---
description: Setup API authentication with JWT middleware and backend SDK
argument-hint: none
allowed-tools: Task, Read, AskUserQuestion, Bash, Glob
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


**Arguments**: $ARGUMENTS

Goal: Setup backend API authentication with Clerk JWT middleware and SDK integration

Core Principles:
- Ask about backend framework before proceeding
- Detect existing backend setup when possible
- Follow framework-specific patterns for JWT middleware
- Provide clear integration instructions

## Security: API Key Handling

**CRITICAL:** When generating configuration or integration code:

❌ NEVER hardcode actual API keys or secrets
❌ NEVER include real Clerk publishable or secret keys

✅ ALWAYS use placeholders: `clerk_your_publishable_key_here`, `clerk_your_secret_key_here`
✅ ALWAYS read from environment variables in code
✅ ALWAYS add `.env*` to `.gitignore` (except `.env.example`)
✅ ALWAYS document where to obtain real keys from Clerk Dashboard

Phase 1: Discovery
Goal: Understand backend framework and current setup

Actions:
- Check if backend framework can be detected from project files
- Look for existing backend configuration:
  - !{bash ls -la package.json pyproject.toml requirements.txt Cargo.toml go.mod 2>/dev/null | head -5}
- If detected, note framework type (Express, FastAPI, Django, etc.)

Phase 2: Gather Requirements
Goal: Understand specific integration needs

Actions:
- Use AskUserQuestion to ask about:
  - Which backend framework? (Express, FastAPI, Django, Flask, Next.js API routes, etc.)
  - What endpoints need authentication? (All routes, specific endpoints, custom logic)
  - Session or JWT validation? (stateless JWT recommended)
  - Any existing auth middleware to replace?

Phase 3: Implementation
Goal: Setup Clerk authentication in backend

Actions:

Task(description="Setup backend API authentication", subagent_type="clerk:clerk-api-builder", prompt="You are the clerk-api-builder agent. Setup backend API authentication with Clerk for this project.

Backend Framework: [Framework from user answers]
Endpoints to Protect: [From user answers]
Authentication Type: JWT validation (stateless)

Requirements:
- Install Clerk backend SDK for the framework
- Configure JWT verification middleware
- Add environment variables with PLACEHOLDER values (clerk_your_publishable_key_here, clerk_your_secret_key_here)
- Protect specified routes/endpoints with auth middleware
- Add user context to requests (req.auth, request.user, etc.)
- Provide error handling for invalid/missing tokens
- Create example protected endpoint showing user data access

Framework-Specific Integration:
- Express: Use @clerk/express or @clerk/clerk-sdk-node with middleware
- FastAPI: Use clerk-backend-api with dependency injection
- Django: Use clerk-backend-api with middleware and decorators
- Flask: Use clerk-backend-api with decorators
- Next.js API routes: Use @clerk/nextjs getAuth() helper

Security Rules:
- Use placeholder API keys only
- Read keys from environment variables
- Add .env to .gitignore
- Include .env.example with placeholders

Expected output:
- Installed SDK packages
- JWT middleware configured
- Environment variables setup with placeholders
- Protected routes/endpoints
- Example usage showing authenticated requests
- Documentation on obtaining real keys from Clerk Dashboard")

Phase 4: Verification
Goal: Ensure integration is complete and documented

Actions:
- Verify middleware setup is framework-appropriate
- Check environment variables use placeholders
- Confirm .gitignore protects .env files
- Validate example protected endpoint exists
- Review documentation for clarity

Phase 5: Summary
Goal: Provide clear next steps

Actions:
- Summarize what was configured:
  - Backend framework
  - SDK installed
  - Middleware setup
  - Protected endpoints
- Document how to obtain real API keys from Clerk Dashboard
- Provide testing instructions for authenticated requests
- Suggest next steps (frontend integration, custom claims, organizations)
