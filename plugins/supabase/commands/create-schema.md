---
description: Generate database schema for AI applications - creates tables, relationships, indexes based on app type
argument-hint: <schema-type> [chat|rag|multi-tenant|complete]
allowed-tools: Task
---

**Arguments**: $ARGUMENTS

Goal: Design and create database schema using supabase-architect agent

Actions:
- Invoke supabase-architect with schema type
- Agent uses schema-patterns skill to generate optimal schema
- Display schema SQL and apply via database-executor
