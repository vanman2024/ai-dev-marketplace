---
description: Enable graph memory for tracking relationships between memories and entities
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, Skill
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

Goal: Enable graph memory to track relationships between memories, entities, and concepts.

Core Principles:
- Relationship tracking between memories
- Entity recognition and linking
- Knowledge graph construction
- Advanced queries for connected data

Phase 1: Capability Check
Goal: Verify graph memory is available

Actions:
- Check deployment mode (Platform or OSS)
- If Platform: Graph memory available
- If OSS: Check if memory_relationships table exists
- Verify current Mem0 configuration

Phase 2: Graph Schema Planning
Goal: Design relationship structure

Actions:
- Determine what relationships to track:
  - Entity relationships (person → works at → company)
  - Memory connections (topic A → related to → topic B)
  - Temporal relationships (event A → happened before → event B)
- Plan relationship types and properties
- Design query patterns for graph traversal

Phase 3: Implementation
Goal: Enable graph memory features

Actions:

Launch the mem0-integrator agent to enable graph memory.

Provide the agent with:
- Deployment mode: [Platform or OSS]
- Relationship schema: [Designed in Phase 2]
- Requirements:
  - Enable graph memory in configuration
  - If OSS: Create/verify memory_relationships table
  - Add entity extraction from conversations
  - Store relationships automatically
  - Create helper functions for graph queries
  - Add examples for common relationship queries
- Expected output: Complete graph memory system

Phase 4: Verification
Goal: Test graph memory works

Actions:
- Test relationships are extracted and stored
- Test graph queries return connected memories
- Verify relationship types are correct
- Check performance of graph traversal

Phase 5: Summary
Goal: Show what was enabled

Actions:
- Display graph memory setup:
  - Graph memory: Enabled
  - Relationship types: [List]
  - Query helpers: [List]
  - Files modified: [List]
- Show usage examples:
  - How to query related memories
  - How to traverse the knowledge graph
  - How to visualize relationships
  - How to manually add relationships
- Provide next steps:
  - Test with entity-rich conversations
  - Build knowledge graph queries
  - Use /mem0:configure for graph thresholds
  - Use /mem0:test to validate graph operations
- Provide documentation:
  - Platform: https://docs.mem0.ai/platform/features/graph-memory
  - OSS: https://docs.mem0.ai/open-source/features/graph-memory
