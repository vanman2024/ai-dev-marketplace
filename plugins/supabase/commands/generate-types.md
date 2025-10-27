---
description: Generate TypeScript types from database schema
argument-hint: [--output=types/supabase.ts]
allowed-tools: Task(supabase-database-executor), Bash
---

**Arguments**: $ARGUMENTS

Goal: Generate TypeScript types from current schema

Actions:
- Use supabase-database-executor to fetch schema via MCP
- Generate TypeScript types from schema
- Write types to specified output file
- Display generated types location
