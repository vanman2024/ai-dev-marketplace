---
description: Add caching layer with strategy selection
argument-hint: [cache-type]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS
**Security**: @~/.claude/plugins/marketplaces/dev-lifecycle-marketplace/docs/security/SECURITY-RULES.md

**Goal**: Add caching layer with chosen strategy (cache-aside, write-through, write-behind).

**Phase 1**: Detect framework and existing Redis setup
**Phase 2**: Ask user for caching strategy and use case
**Phase 3**: Task(subagent_type="redis:cache-architect") to implement
**Phase 4**: Verify caching works, measure hit rates
**Phase 5**: Display summary and monitoring guidance
