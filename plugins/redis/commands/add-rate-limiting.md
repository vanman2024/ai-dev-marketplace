---
description: Add rate limiting for APIs
argument-hint: [requests-per-minute]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS
**Security**: @~/.claude/plugins/marketplaces/dev-lifecycle-marketplace/docs/security/SECURITY-RULES.md

**Goal**: Add rate limiting to protect APIs.

**Phase 1**: Detect API framework
**Phase 2**: Ask for rate limit strategy (per-user, per-IP, per-key)
**Phase 3**: Task(subagent_type="redis:rate-limiter-specialist") to implement
**Phase 4**: Test rate limiting, verify 429 responses
**Phase 5**: Summary with rate limit configuration
