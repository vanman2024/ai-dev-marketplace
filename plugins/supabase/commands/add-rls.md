---
description: Add Row Level Security policies - generates and applies RLS policies for tables
argument-hint: <table1,table2,...> [--pattern=user-isolation|multi-tenant|role-based]
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

Goal: Apply RLS policies using security-specialist agent

Actions:
- Invoke supabase-security-specialist with table list and pattern
- Agent uses rls-templates skill to generate policies
- Apply policies via database-executor
- Display applied policies
