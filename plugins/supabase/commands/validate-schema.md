---
description: Validate database schema integrity - checks constraints, indexes, naming conventions
argument-hint: [schema-file.sql|--live]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Validate schema using schema-validator agent

Actions:
- Invoke supabase-schema-validator with schema file or live database flag
- Agent uses schema-validation skill to check integrity
- Display validation report with issues and recommendations
