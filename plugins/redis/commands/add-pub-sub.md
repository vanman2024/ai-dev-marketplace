---
description: Add pub/sub messaging for real-time features
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS
**Security**: @~/.claude/plugins/marketplaces/dev-lifecycle-marketplace/docs/security/SECURITY-RULES.md

**Goal**: Add Redis pub/sub for real-time messaging.

**Phase 1**: Detect framework and WebSocket support
**Phase 2**: Ask for messaging use case (chat, notifications, events)
**Phase 3**: Task(subagent_type="redis:pub-sub-specialist") to implement
**Phase 4**: Test pub/sub messaging
**Phase 5**: Summary with channel configuration
