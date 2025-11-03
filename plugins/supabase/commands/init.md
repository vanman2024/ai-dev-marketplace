---
description: Initialize Supabase in your project - sets up MCP configuration, creates .env, and prepares project for Supabase integration
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Edit, Bash, Skill
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

# Phase 1: Verify Project Context
Goal: Check existing project setup

Actions:

Check project files:
- package.json exists (determine project type)
- .mcp.json exists
- .env file exists

Ask user for Supabase project details if needed:
- Project reference (from Supabase dashboard)
- Access token (from Supabase dashboard)

# Phase 2: Configure MCP Server
Goal: Add Supabase MCP server to project

Actions:

If .mcp.json doesn't exist, create it with Supabase server configuration.

If .mcp.json exists, merge Supabase server configuration:
- Server type: http
- URL: https://mcp.supabase.com/mcp?project_ref=${SUPABASE_PROJECT_REF}
- Headers: Authorization with Bearer ${SUPABASE_ACCESS_TOKEN}

# Phase 3: Setup Environment Variables
Goal: Create or update .env file

Actions:

Create or update .env file with Supabase credentials:
- SUPABASE_PROJECT_REF
- SUPABASE_ACCESS_TOKEN
- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY

Ensure .env is in .gitignore.

# Phase 4: Verify Configuration
Goal: Validate setup using agent

Actions:

Invoke the supabase-project-manager agent to:
- Verify MCP connectivity
- Validate project access
- Confirm configuration is correct

# Phase 5: Summary
Goal: Display initialization results

Actions:

Display initialization results:
- MCP server configured: [status]
- Environment variables set: [count]
- Project connection verified: [status]

Show next steps:
- Use /supabase:create-schema to design your database
- Use /supabase:add-auth to set up authentication
- Use /supabase:setup-ai for AI features
- Use /supabase:validate-setup to check configuration
