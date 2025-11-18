---
description: Add AI query result caching with semantic similarity
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS
**Security**: @~/.claude/plugins/marketplaces/dev-lifecycle-marketplace/docs/security/SECURITY-RULES.md

**Goal**: Add semantic caching for AI query results.

**Phase 1**: Detect AI usage in project
**Phase 2**: Ask for similarity threshold (0.85-0.95)
**Phase 3**: Task(subagent_type="redis:semantic-cache-specialist") to implement
**Phase 4**: Tune similarity threshold, measure savings
**Phase 5**: Summary with cost reduction metrics
