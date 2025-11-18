---
description: Add AI embedding cache for cost optimization
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS
**Security**: @~/.claude/plugins/marketplaces/dev-lifecycle-marketplace/docs/security/SECURITY-RULES.md

**Goal**: Add embedding cache to reduce AI API costs by 50%+.

**Phase 1**: Detect AI framework (LangChain, LlamaIndex, custom)
**Phase 2**: Ask for AI provider (OpenAI, Anthropic, Cohere)
**Phase 3**: Task(subagent_type="redis:vector-cache-specialist") to implement
**Phase 4**: Measure cache hit rates and cost savings
**Phase 5**: Summary with optimization tips
