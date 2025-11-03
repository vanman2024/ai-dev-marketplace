---
description: Validate Supabase setup - MCP connectivity, configuration, security, schema (parallel validation)
argument-hint: [--production] [--suite=all|mcp|schema|security|performance]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
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
