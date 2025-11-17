---
description: Configure Supabase Storage - creates buckets, sets up RLS policies for file access
argument-hint: <bucket-name> [public|private]
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

Goal: Set up storage buckets with proper security policies

Actions:
- Parse bucket name and visibility from arguments
- Use database-executor to create storage bucket via MCP
- Configure RLS policies for bucket access
- Display bucket URL and usage examples
