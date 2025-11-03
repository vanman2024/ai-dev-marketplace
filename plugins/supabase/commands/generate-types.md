---
description: Generate TypeScript types from database schema
argument-hint: [--output=types/supabase.ts]
allowed-tools: Task, Bash
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

Goal: Generate TypeScript types from current schema

Actions:
- Use supabase-database-executor to fetch schema via MCP
- Generate TypeScript types from schema
- Write types to specified output file
- Display generated types location
