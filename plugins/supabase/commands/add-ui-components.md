---
description: Install Supabase UI components - adds auth, realtime, file upload React components
argument-hint: [component1,component2,...]
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

Goal: Integrate Supabase UI components using ui-generator agent

Actions:
- Invoke supabase-ui-generator with component list
- Agent installs and configures UI components
- Display integration examples
