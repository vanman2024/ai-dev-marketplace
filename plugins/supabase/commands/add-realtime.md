---
description: Setup Supabase Realtime - enables realtime on tables, configures subscriptions, presence, broadcast
argument-hint: [table1,table2,...] [--features=subscriptions,presence,broadcast]
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

Goal: Configure realtime features using supabase-realtime-builder agent

Actions:
- Invoke supabase-realtime-builder with table list and feature flags
- Agent will enable realtime and configure features
- Display realtime configuration and usage examples
