---
description: Deploy database migration - applies migration files safely with rollback capability
argument-hint: <migration-file>
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

Goal: Deploy migration safely using migration-applier agent

Actions:
- Invoke code-reviewer to validate migration first
- If validation passes, invoke migration-applier to deploy
- Display migration results and rollback instructions if needed
