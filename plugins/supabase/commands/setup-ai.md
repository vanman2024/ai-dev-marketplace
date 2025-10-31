---
description: Complete AI setup - pgvector, embeddings, schemas, RLS, validation (parallel multi-agent)
argument-hint: [--app-type=chat|rag|multi-tenant]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

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
