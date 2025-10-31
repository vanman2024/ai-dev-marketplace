---
description: Add authentication - OAuth providers, email auth, RLS policies with parallel validation
argument-hint: [provider1,provider2,...] (e.g., google,github,discord)
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

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
