---
description: Test RLS policy enforcement - validates Row Level Security policies work correctly
argument-hint: <table1,table2,...>
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

Goal: Test RLS policies using security-auditor agent

Actions:
- Invoke supabase-security-auditor with table list
- Agent uses rls-test-patterns skill to test policies
- Display test results showing user isolation, policy coverage, vulnerabilities
