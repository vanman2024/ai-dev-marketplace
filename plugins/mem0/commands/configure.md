---
description: Configure Mem0 settings (memory types, retention, embeddings, rerankers, webhooks)
argument-hint: [setting-name]
allowed-tools: Task, Read, Write, Edit, Bash(*), AskUserQuestion, Skill
---
## Available Skills

This commands has access to the following skills from the mem0 plugin:

- **memory-design-patterns**: Best practices for memory architecture design including user vs agent vs session memory patterns, vector vs graph memory tradeoffs, retention strategies, and performance optimization. Use when designing memory systems, architecting AI memory layers, choosing memory types, planning retention strategies, or when user mentions memory architecture, user memory, agent memory, session memory, memory patterns, vector storage, graph memory, or Mem0 architecture.\n- **memory-optimization**: Performance optimization patterns for Mem0 memory operations including query optimization, caching strategies, embedding efficiency, database tuning, batch operations, and cost reduction for both Platform and OSS deployments. Use when optimizing memory performance, reducing costs, improving query speed, implementing caching, tuning database performance, analyzing bottlenecks, or when user mentions memory optimization, performance tuning, cost reduction, slow queries, caching, or Mem0 optimization.\n- **supabase-integration**: Complete Supabase setup for Mem0 OSS including PostgreSQL schema with pgvector for embeddings, memory_relationships tables for graph memory, RLS policies for user/tenant isolation, performance indexes, connection pooling, and backup/migration strategies. Use when setting up Mem0 with Supabase, configuring OSS memory backend, implementing memory persistence, migrating from Platform to OSS, or when user mentions Mem0 Supabase, memory database, pgvector for Mem0, memory isolation, or Mem0 backup.\n
**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

---



## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Configure Mem0 settings for memory types, retention policies, embedding models, rerankers, webhooks, and custom categories.

Core Principles:
- Interactive configuration
- Explain options and tradeoffs
- Validate settings before applying
- Document configuration choices

Phase 1: Configuration Discovery
Goal: Determine what to configure

Actions:
- If $ARGUMENTS specifies setting, focus on that
- Otherwise, show configuration menu with options:
  - Memory types (user/agent/session)
  - Retention policies (expiration, archival)
  - Embedding models (OpenAI, HuggingFace, etc.)
  - Rerankers (for better retrieval)
  - Webhooks (memory events)
  - Custom categories
  - Graph memory settings
- Load current configuration
- Check deployment mode (Platform or OSS)

Phase 2: Configuration Planning
Goal: Gather configuration preferences

Actions:
- Use AskUserQuestion to ask about configuration:
  - "Which setting do you want to configure?" (if not specified)
  - Based on selection, ask specific questions:
    - Retention: "How long should memories persist?"
    - Embeddings: "Which embedding model do you want?"
    - Rerankers: "Enable reranker for better search?"
    - Webhooks: "Configure webhooks for memory events?"
- Explain tradeoffs for each option
- Recommend defaults for common use cases

Phase 3: Implementation
Goal: Apply configuration changes

Actions:

Launch the mem0-integrator agent to apply configuration.

Provide the agent with:
- Configuration target: [Selected setting]
- New values: [From Phase 2]
- Deployment mode: [Platform or OSS]
- Requirements:
  - Update configuration files
  - Modify environment variables if needed
  - Add necessary imports/dependencies
  - Update memory client initialization
  - Add validation for new settings
  - Document configuration in comments
- Expected output: Updated configuration with settings applied

Phase 4: Verification
Goal: Validate configuration works

Actions:
- Test new configuration loads correctly
- If embeddings changed: Test embedding generation
- If reranker enabled: Test search quality improvement
- If webhooks: Test webhook delivery
- Verify no breaking changes

Phase 5: Summary
Goal: Document what was configured

Actions:
- Display configuration changes:
  - Setting: [Name]
  - Old value: [Previous]
  - New value: [Current]
  - Files modified: [List]
- Show impact of changes
- Provide recommendations:
  - When to adjust settings
  - How to monitor performance
  - Related configuration options
- Provide next steps:
  - Run /mem0:test to validate
  - Monitor memory operations
  - Adjust based on usage patterns
- Provide documentation:
  - Platform features: https://docs.mem0.ai/platform/features/platform-overview
  - OSS configuration: https://docs.mem0.ai/open-source/configuration
