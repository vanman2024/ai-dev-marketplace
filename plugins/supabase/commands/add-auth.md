---
description: Add authentication - OAuth providers, email auth, RLS policies with parallel validation
argument-hint: [provider1,provider2,...] (e.g., google,github,discord)
---
## Available Skills

This commands has access to the following skills from the supabase plugin:

- **auth-configs**: Configure Supabase authentication providers (OAuth, JWT, email). Use when setting up authentication, configuring OAuth providers (Google/GitHub/Discord), implementing auth flows, configuring JWT settings, or when user mentions Supabase auth, social login, authentication setup, or auth configuration.
- **e2e-test-scenarios**: End-to-end testing scenarios for Supabase - complete workflow tests from project creation to AI features, validation scripts, and comprehensive test suites. Use when testing Supabase integrations, validating AI workflows, running E2E tests, verifying production readiness, or when user mentions Supabase testing, E2E tests, integration testing, pgvector testing, auth testing, or test automation.
- **pgvector-setup**: Configure pgvector extension for vector search in Supabase - includes embedding storage, HNSW/IVFFlat indexes, hybrid search setup, and AI-optimized query patterns. Use when setting up vector search, building RAG systems, configuring semantic search, creating embedding storage, or when user mentions pgvector, vector database, embeddings, semantic search, or hybrid search.
- **rls-templates**: Row Level Security policy templates for Supabase - multi-tenant patterns, user isolation, role-based access, and secure-by-default configurations. Use when securing Supabase tables, implementing RLS policies, building multi-tenant AI apps, protecting user data, creating chat/RAG systems, or when user mentions row level security, RLS, Supabase security, tenant isolation, or data access policies.
- **rls-test-patterns**: RLS policy testing patterns for Supabase - automated test cases for Row Level Security enforcement, user isolation verification, multi-tenant security, and comprehensive security audit scripts. Use when testing RLS policies, validating user isolation, auditing Supabase security, verifying tenant isolation, testing row level security, running security tests, or when user mentions RLS testing, security validation, policy testing, or data leak prevention.
- **schema-patterns**: Production-ready database schema patterns for AI applications including chat/conversation schemas, RAG document storage with pgvector, multi-tenant organization models, user management, and AI usage tracking. Use when building AI applications, creating database schemas, setting up chat systems, implementing RAG, designing multi-tenant databases, or when user mentions supabase schemas, chat database, RAG storage, pgvector, embeddings, conversation history, or AI application database.
- **schema-validation**: Database schema validation tools - SQL syntax checking, constraint validation, naming convention enforcement, and schema integrity verification. Use when validating database schemas, checking migrations, enforcing naming conventions, verifying constraints, or when user mentions schema validation, migration checks, database best practices, or PostgreSQL validation.

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

# Phase 1: Requirements Analysis
Goal: Parse authentication requirements

Actions:

Parse provider list from arguments (comma-separated):
- OAuth providers: google, github, discord, facebook, apple, twitter
- Email auth: email (includes magic links)
- SMS auth: sms (requires Twilio)

Default if no arguments: email,google

Verify environment variables:
- $SUPABASE_PROJECT_REF
- $SUPABASE_ACCESS_TOKEN
- $SUPABASE_DB_URL

Check for OAuth credentials:
- Google: $GOOGLE_CLIENT_ID, $GOOGLE_CLIENT_SECRET
- GitHub: $GITHUB_CLIENT_ID, $GITHUB_CLIENT_SECRET
- Discord: $DISCORD_CLIENT_ID, $DISCORD_CLIENT_SECRET

If critical credentials missing, display setup guide and exit.

# Phase 2: Authentication Setup
Goal: Configure providers and RLS

Actions:

Invoke the supabase-security-specialist agent to configure authentication.

Pass context:
- Provider list: [parsed providers]
- Application type: [detect from schema or ask]
- Multi-tenant: [yes/no, detect from schema]
- Tables requiring RLS: [detect from schema]

Agent will:
- Configure OAuth providers via auth-configs skill
- Set up email authentication
- Generate RLS policies via rls-templates skill
- Apply policies to database
- Configure auth middleware

# Phase 3: Parallel Validation
Goal: Validate authentication setup

Actions:

Launch the following validation agents IN PARALLEL (all at once):

**Agent 1 - Schema Validation:**
Invoke the supabase-schema-validator agent to validate auth-related schema.
Focus on: RLS policies applied, auth integration, policy naming, no tables without RLS
Deliverable: Schema validation report

**Agent 2 - Security Audit:**
Invoke the supabase-security-auditor agent to audit authentication security.
Focus on: User isolation, multi-tenant isolation, role-based access, anonymous restrictions, RLS coverage, vulnerabilities
Deliverable: Security audit report with vulnerability scan

**Agent 3 - Auth Workflow Testing:**
Invoke the supabase-tester agent to test authentication workflows.
Focus on: OAuth flows, email auth, magic links, password reset, session management, token refresh
Deliverable: E2E auth test results

Wait for ALL validation agents to complete before proceeding.

# Phase 4: Results Summary
Goal: Present authentication setup report

Actions:

Aggregate results from all agents:

**Authentication Configuration:**
- OAuth providers configured: [list with status]
- Email auth: [enabled/disabled]
- Magic links: [enabled/disabled]
- RLS policies applied: [count]
- Tables protected: [list]

**Validation Results:**
- Schema validation: [PASS/FAIL with issues]
- Security audit: [PASS/FAIL with vulnerabilities]
- Auth workflow tests: [X passed, Y failed]

**OAuth Provider Setup:**
For each configured provider:
- Provider: [name]
- Status: [configured/failed]
- Redirect URL: [URL for provider settings]
- Required credentials: [status]

**Next Steps:**
1. Configure OAuth credentials in provider dashboards
2. Test authentication flows in development
3. Review RLS policies for business logic
4. Configure auth UI components (optional)
5. Set up auth middleware
6. Deploy to production

Display integration code examples for TypeScript and Python.

If any validation failed, display remediation steps.
