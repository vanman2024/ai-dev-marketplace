---
description: Test RLS policy enforcement - validates Row Level Security policies work correctly
argument-hint: <table1,table2,...>
allowed-tools: Task(supabase-security-auditor), Skill(rls-test-patterns)
---

**Arguments**: $ARGUMENTS

Goal: Test RLS policies using security-auditor agent

Actions:
- Invoke supabase-security-auditor with table list
- Agent uses rls-test-patterns skill to test policies
- Display test results showing user isolation, policy coverage, vulnerabilities
