---
description: Add session management with Redis
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS
**Security**: @~/.claude/plugins/marketplaces/dev-lifecycle-marketplace/docs/security/SECURITY-RULES.md

**Goal**: Add secure session storage with Redis.

**Phase 1**: Detect framework (FastAPI, Next.js, Express, Django)
**Phase 2**: Ask about auth requirements (OAuth, JWT, custom)
**Phase 3**: Task(subagent_type="redis:session-manager") to implement
**Phase 4**: Test session create/read/delete, verify security
**Phase 5**: Summary with session configuration details
