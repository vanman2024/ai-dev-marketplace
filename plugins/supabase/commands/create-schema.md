---
description: Generate database schema for AI applications - creates tables, relationships, indexes based on app type
argument-hint: <schema-type> [chat|rag|multi-tenant|complete]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite, Skill
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

Goal: Design and create database schema using supabase-architect agent

Actions:
- Invoke supabase-architect with schema type
- Agent uses schema-patterns skill to generate optimal schema
- Display schema SQL and apply via database-executor
