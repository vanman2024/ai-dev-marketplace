---
description: Configure Supabase Storage - creates buckets, sets up RLS policies for file access
argument-hint: <bucket-name> [public|private]
allowed-tools: Task
---

**Arguments**: $ARGUMENTS

Goal: Set up storage buckets with proper security policies

Actions:
- Parse bucket name and visibility from arguments
- Use database-executor to create storage bucket via MCP
- Configure RLS policies for bucket access
- Display bucket URL and usage examples
