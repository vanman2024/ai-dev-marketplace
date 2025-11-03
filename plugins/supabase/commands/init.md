---
description: Initialize Supabase in your project - sets up MCP configuration, creates .env, and prepares project for Supabase integration
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Edit, Bash, Skill
---
## Available Skills

This commands has access to the following skills from the supabase plugin:

- **auth-configs**: Configure Supabase authentication providers (OAuth, JWT, email). Use when setting up authentication, configuring OAuth providers (Google/GitHub/Discord), implementing auth flows, configuring JWT settings, or when user mentions Supabase auth, social login, authentication setup, or auth configuration.\n- **e2e-test-scenarios**: End-to-end testing scenarios for Supabase - complete workflow tests from project creation to AI features, validation scripts, and comprehensive test suites. Use when testing Supabase integrations, validating AI workflows, running E2E tests, verifying production readiness, or when user mentions Supabase testing, E2E tests, integration testing, pgvector testing, auth testing, or test automation.\n- **pgvector-setup**: Configure pgvector extension for vector search in Supabase - includes embedding storage, HNSW/IVFFlat indexes, hybrid search setup, and AI-optimized query patterns. Use when setting up vector search, building RAG systems, configuring semantic search, creating embedding storage, or when user mentions pgvector, vector database, embeddings, semantic search, or hybrid search.\n- **rls-templates**: Row Level Security policy templates for Supabase - multi-tenant patterns, user isolation, role-based access, and secure-by-default configurations. Use when securing Supabase tables, implementing RLS policies, building multi-tenant AI apps, protecting user data, creating chat/RAG systems, or when user mentions row level security, RLS, Supabase security, tenant isolation, or data access policies.\n- **rls-test-patterns**: RLS policy testing patterns for Supabase - automated test cases for Row Level Security enforcement, user isolation verification, multi-tenant security, and comprehensive security audit scripts. Use when testing RLS policies, validating user isolation, auditing Supabase security, verifying tenant isolation, testing row level security, running security tests, or when user mentions RLS testing, security validation, policy testing, or data leak prevention.\n- **schema-patterns**: Production-ready database schema patterns for AI applications including chat/conversation schemas, RAG document storage with pgvector, multi-tenant organization models, user management, and AI usage tracking. Use when building AI applications, creating database schemas, setting up chat systems, implementing RAG, designing multi-tenant databases, or when user mentions supabase schemas, chat database, RAG storage, pgvector, embeddings, conversation history, or AI application database.\n- **schema-validation**: Database schema validation tools - SQL syntax checking, constraint validation, naming convention enforcement, and schema integrity verification. Use when validating database schemas, checking migrations, enforcing naming conventions, verifying constraints, or when user mentions schema validation, migration checks, database best practices, or PostgreSQL validation.\n
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
