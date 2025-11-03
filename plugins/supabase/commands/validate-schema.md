---
description: Validate database schema integrity - checks constraints, indexes, naming conventions
argument-hint: [schema-file.sql|--live]
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

Goal: Validate schema using schema-validator agent

Actions:
- Invoke supabase-schema-validator with schema file or live database flag
- Agent uses schema-validation skill to check integrity
- Display validation report with issues and recommendations
