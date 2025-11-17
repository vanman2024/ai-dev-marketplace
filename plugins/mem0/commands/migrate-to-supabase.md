---
description: Migrate from Mem0 Platform to Open Source with Supabase backend
argument-hint: none
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---

## Available Skills

This commands has access to the following skills from the mem0 plugin:

- **memory-design-patterns**: Best practices for memory architecture design including user vs agent vs session memory patterns, vector vs graph memory tradeoffs, retention strategies, and performance optimization. Use when designing memory systems, architecting AI memory layers, choosing memory types, planning retention strategies, or when user mentions memory architecture, user memory, agent memory, session memory, memory patterns, vector storage, graph memory, or Mem0 architecture.
- **memory-optimization**: Performance optimization patterns for Mem0 memory operations including query optimization, caching strategies, embedding efficiency, database tuning, batch operations, and cost reduction for both Platform and OSS deployments. Use when optimizing memory performance, reducing costs, improving query speed, implementing caching, tuning database performance, analyzing bottlenecks, or when user mentions memory optimization, performance tuning, cost reduction, slow queries, caching, or Mem0 optimization.
- **supabase-integration**: Complete Supabase setup for Mem0 OSS including PostgreSQL schema with pgvector for embeddings, memory_relationships tables for graph memory, RLS policies for user/tenant isolation, performance indexes, connection pooling, and backup/migration strategies. Use when setting up Mem0 with Supabase, configuring OSS memory backend, implementing memory persistence, migrating from Platform to OSS, or when user mentions Mem0 Supabase, memory database, pgvector for Mem0, memory isolation, or Mem0 backup.

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

Goal: Migrate from Mem0 Platform (hosted) to Mem0 OSS (self-hosted with Supabase), preserving all memories and relationships.

Core Principles:
- Export data safely from Platform
- Setup OSS infrastructure
- Import data to Supabase
- Verify data integrity
- Update application code

Phase 1: Pre-Migration Validation
Goal: Ensure migration is feasible

Actions:
- Verify currently using Mem0 Platform
- Check memory count and size
- Estimate migration time
- Warn about potential downtime
- Use AskUserQuestion to confirm:
  - "Ready to migrate from Platform to OSS? This will require downtime."
  - "Do you have Supabase account ready?"

Phase 2: Data Export
Goal: Export all memories from Platform

Actions:
- Use Mem0 Platform export API
- Export memories with metadata
- Export relationships (if graph memory enabled)
- Export user and agent data
- Save exports to local files
- Verify export completeness
- Create backup of exports

Phase 3: OSS Setup
Goal: Initialize Mem0 OSS with Supabase

Actions:
- Run /supabase:init if not already setup
- Run /mem0:init-oss to setup OSS mode
- Wait for setup to complete
- Verify Supabase tables are created
- Verify pgvector extension is enabled

Phase 4: Data Import
Goal: Import memories to Supabase

Actions:

Launch the mem0-integrator agent to import data.

Provide the agent with:
- Export files: [From Phase 2]
- Target: Supabase OSS setup
- Requirements:
  - Import all memories to Supabase tables
  - Preserve memory IDs and metadata
  - Import relationships (if graph memory)
  - Maintain user/agent associations
  - Verify vector embeddings
  - Handle import errors gracefully
  - Provide progress updates
- Expected output: Complete data migration to Supabase

Phase 5: Application Updates
Goal: Update code to use OSS instead of Platform

Actions:
- Update memory client from Platform to OSS configuration
- Change from MemoryClient to Memory with Supabase config
- Update environment variables
- Remove Platform API key
- Add Supabase connection variables
- Test memory operations work with new setup

Phase 6: Verification
Goal: Validate migration was successful

Actions:
- Run /mem0:test to validate OSS setup
- Compare memory counts (Platform export vs Supabase import)
- Test sample memory queries return correct results
- Verify relationships preserved (if graph memory)
- Check user isolation still works
- Test application functionality end-to-end

Phase 7: Summary
Goal: Document migration results

Actions:
- Display migration summary:
  - Memories exported from Platform: [Count]
  - Memories imported to Supabase: [Count]
  - Relationships migrated: [Count]
  - Data integrity: [Verified/Issues]
  - Application updated: [Files modified]
- Show post-migration tasks:
  - Cancel Platform subscription (if desired)
  - Monitor OSS performance
  - Setup backups for Supabase
  - Configure retention policies
- Provide next steps:
  - Optimize OSS performance
  - Setup monitoring
  - Configure auto-backups
  - Use /mem0:configure for OSS tuning
- Provide documentation:
  - OSS configuration: https://docs.mem0.ai/open-source/configuration
  - Supabase best practices: https://supabase.com/docs/guides/database
