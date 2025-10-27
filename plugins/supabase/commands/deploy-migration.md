---
description: Deploy database migration - applies migration files safely with rollback capability
argument-hint: <migration-file>
allowed-tools: Task(supabase-migration-applier,supabase-code-reviewer)
---

**Arguments**: $ARGUMENTS

Goal: Deploy migration safely using migration-applier agent

Actions:
- Invoke code-reviewer to validate migration first
- If validation passes, invoke migration-applier to deploy
- Display migration results and rollback instructions if needed
