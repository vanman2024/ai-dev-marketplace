---
description: Validate Supabase setup - MCP connectivity, configuration, security, schema (parallel validation)
argument-hint: [--production] [--suite=all|mcp|schema|security|performance]
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
Goal: Parse validation requirements

Actions:

Parse arguments:
- `--production` - Enable production-level checks (stricter requirements)
- `--suite` - Validation suite selection:
  - `all` (default) - All validation checks
  - `mcp` - MCP connectivity and configuration only
  - `schema` - Database schema validation only
  - `security` - Security and RLS validation only
  - `performance` - Performance checks only

Verify environment variables:
- $SUPABASE_PROJECT_REF
- $SUPABASE_ACCESS_TOKEN
- $SUPABASE_DB_URL

Set validation level:
- Development: Warnings allowed, some checks optional
- Production: Zero warnings, all checks mandatory

# Phase 2: Parallel Validation Execution
Goal: Run comprehensive validation checks in parallel

Actions:

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


## Suite: all (default)

Launch the following validation agents IN PARALLEL (all at once):

**Agent 1 - MCP & Configuration Validation:**
Invoke the supabase-validator agent to validate MCP and project configuration.
Focus on: MCP connectivity, environment variables, API keys, database URL, Supabase CLI
Validation level: $PRODUCTION_FLAG
Deliverable: MCP connectivity report

**Agent 2 - Schema Validation:**
Invoke the supabase-schema-validator agent to validate database schema.
Focus on: SQL syntax, naming conventions, constraints, indexes, foreign keys, primary keys
Validation level: $PRODUCTION_FLAG
Deliverable: Schema validation report

**Agent 3 - Security Validation:**
Invoke the supabase-security-auditor agent to audit security configuration.
Focus on: RLS coverage, user isolation, multi-tenant isolation, role-based access, vulnerabilities
Validation level: $PRODUCTION_FLAG
Deliverable: Security audit report

**Agent 4 - E2E Workflow Validation:**
Invoke the supabase-tester agent to test critical workflows.
Focus on: Database ops, auth flows, realtime, vector search, storage, Edge Functions
Validation level: $PRODUCTION_FLAG
Deliverable: E2E workflow test results

Wait for ALL validation agents to complete before proceeding.

## Suite-Specific Validation

For suite-specific validation (mcp, schema, security, performance), launch only relevant agents based on the selected suite.

# Phase 3: Results Aggregation
Goal: Collect and analyze validation results

Actions:

Aggregate results from all validation agents:

Display overall status: PASS | FAIL | WARNING

Show validation results:
- MCP & Configuration: connectivity status, environment variables, issues found
- Schema Validation: tables validated, syntax errors, naming violations, constraint issues
- Security Validation: RLS coverage, tables without RLS, vulnerabilities, critical issues
- Workflow Validation: database ops, auth workflows, realtime, vector search, storage

# Phase 4: Issue Categorization
Goal: Categorize issues by severity

Actions:

Categorize all issues:

**CRITICAL** (must fix for production):
- MCP connectivity failures
- RLS policies missing on user data tables
- SQL syntax errors
- Missing primary keys
- Auth configuration failures

**HIGH** (should fix before production):
- Missing indexes on foreign keys
- Naming convention violations
- Incomplete RLS coverage
- Performance bottlenecks

**MEDIUM** (recommended fixes):
- Optimization opportunities
- Documentation gaps
- Test coverage improvements

**LOW** (nice to have):
- Code style suggestions
- Minor optimizations

# Phase 5: Production Readiness Assessment
Goal: Determine production readiness

Actions:

If --production flag is set:

Calculate production readiness score:
- MCP & Configuration: score/100
- Schema Quality: score/100
- Security: score/100
- Workflow Reliability: score/100
- Overall Score: average/100

Production Readiness: READY | NOT READY

Requirements for production:
- Zero critical issues
- Zero high-priority security issues
- 100% RLS coverage on user tables
- All auth workflows passing
- All migrations validated
- Performance benchmarks met
- MCP connectivity stable

If NOT READY, display blocking issues and remediation steps.

# Phase 6: Remediation Guidance
Goal: Provide actionable fix instructions

Actions:

For each issue category, provide:
- Issue description
- Location (file:line or table/policy name)
- Impact explanation
- Step-by-step fix instructions
- Verification method

Display next steps:
1. Fix all CRITICAL issues immediately
2. Address HIGH priority issues before production
3. Review and implement MEDIUM priority fixes
4. Consider LOW priority optimizations
5. Re-run validation: `/supabase:validate-setup --production`
6. Review production readiness checklist
7. Deploy when all checks pass

Save validation reports to:
- `supabase-validation-report-{timestamp}.json`
- `supabase-validation-report-{timestamp}.md`

If production ready, display congratulations and deployment instructions.
