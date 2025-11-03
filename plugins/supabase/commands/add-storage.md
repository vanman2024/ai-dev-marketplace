---
description: Configure Supabase Storage - creates buckets, sets up RLS policies for file access
argument-hint: <bucket-name> [public|private]
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

Goal: Set up storage buckets with proper security policies

Actions:
- Parse bucket name and visibility from arguments
- Use database-executor to create storage bucket via MCP
- Configure RLS policies for bucket access
- Display bucket URL and usage examples
