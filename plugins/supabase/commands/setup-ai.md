---
description: Complete AI setup - pgvector, embeddings, schemas, RLS, validation (parallel multi-agent)
argument-hint: [--app-type=chat|rag|multi-tenant]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite, Skill
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

# Phase 1: Requirements Gathering
Goal: Understand AI application requirements

Actions:

Parse application type from arguments (default: rag):
- `chat` - Chat application with conversation history
- `rag` - RAG system with document embeddings
- `multi-tenant` - Multi-tenant AI platform

Detect required environment variables:
- $SUPABASE_PROJECT_REF
- $SUPABASE_ACCESS_TOKEN
- $SUPABASE_DB_URL

If any missing, display setup instructions and exit.

# Phase 2: Parallel AI Setup
Goal: Configure AI features, schema, and security simultaneously

Actions:

Launch the following agents IN PARALLEL (all at once):

**Agent 1 - AI Features Configuration:**
Invoke the supabase-ai-specialist agent to configure all AI features.
Focus on: pgvector setup, embedding tables, HNSW/IVFFlat indexes, hybrid search, AI Edge Functions
Target: $SUPABASE_DB_URL, $SUPABASE_PROJECT_REF
Deliverable: Fully configured pgvector with indexes and search capabilities

**Agent 2 - Schema Design:**
Invoke the supabase-architect agent to design AI-optimized database schema.
Focus on: App-specific schema (chat/RAG/multi-tenant), relationships, foreign keys, index strategy, auth integration
Target: Application type from $ARGUMENTS
Deliverable: Complete schema migration file ready for deployment

**Agent 3 - Security Configuration:**
Invoke the supabase-security-specialist agent to implement RLS policies.
Focus on: User isolation, multi-tenant isolation, role-based access, auth integration, anonymous restrictions
Target: All schema tables
Deliverable: Comprehensive RLS policies for all tables

Wait for ALL agents to complete before proceeding.

Collect outputs:
- AI specialist: pgvector configuration, index details
- Architect: Schema file path, table summary
- Security specialist: RLS policy count, coverage report

# Phase 3: Schema Deployment
Goal: Apply generated schema and policies

Actions:

Display schema summary from architect output.

Ask user for confirmation to deploy:
- Table count, index count, RLS policies
- Migration file path

If confirmed:
- Execute migration using schema deployment
- Verify tables, indexes, and RLS policies created

If deployment fails, display error and rollback instructions.

# Phase 4: Parallel Validation
Goal: Validate all configurations

Actions:

Launch the following validation agents IN PARALLEL (all at once):

**Agent 1 - Schema Validation:**
Invoke the supabase-schema-validator agent to validate deployed schema.
Focus on: SQL syntax, naming conventions, constraints, index coverage, RLS presence
Deliverable: Schema validation report

**Agent 2 - Security Audit:**
Invoke the supabase-security-auditor agent to audit security configuration.
Focus on: RLS testing, user isolation, multi-tenant isolation, role permissions, vulnerabilities, coverage
Deliverable: Security audit report

**Agent 3 - E2E Testing:**
Invoke the supabase-tester agent to run AI feature tests.
Focus on: Vector search, embedding insertion/retrieval, hybrid search, AI Edge Functions, E2E AI workflows
Deliverable: E2E test results

Wait for ALL validation agents to complete before proceeding.

# Phase 5: Results Summary
Goal: Present comprehensive setup report

Actions:

Aggregate results from all agents:

**AI Features:**
- pgvector extension: [status]
- Embedding tables: [names]
- Vector indexes: [HNSW/IVFFlat details]
- Hybrid search: [status]
- Edge Functions: [names]

**Database Schema:**
- Tables created: [count and names]
- Indexes created: [count and types]
- Foreign keys: [count]
- Migration file: [path]

**Security:**
- RLS policies: [count]
- Policy coverage: [percentage]
- Auth integration: [status]

**Validation Results:**
- Schema validation: [PASS/FAIL]
- Security audit: [PASS/FAIL]
- E2E tests: [X passed, Y failed]

**Next Steps:**
1. Review validation issues if any
2. Test AI features with sample data
3. Configure Edge Functions for production
4. Set up monitoring and logging
5. Deploy to production

Display integration code examples for TypeScript and Python.

If any validation failed, display remediation steps.
