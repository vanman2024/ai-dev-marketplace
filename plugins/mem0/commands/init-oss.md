---
description: Setup self-hosted Mem0 OSS with Supabase backend and pgvector
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, SlashCommand, Skill
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

Goal: Setup Mem0 Open Source (self-hosted) with Supabase PostgreSQL + pgvector backend.

Core Principles:
- Full control over infrastructure
- Supabase provides database, auth, storage
- pgvector for embeddings storage
- Cost-effective for production

Phase 1: Supabase Validation
Goal: Ensure Supabase is initialized

Actions:
- Check if Supabase is already initialized:
  - Look for .mcp.json with supabase server
  - Check for SUPABASE_* environment variables
- If not initialized:
  - Run /supabase:init to setup Supabase
  - Wait for completion
  - Verify Supabase MCP connectivity

Phase 2: Package Installation
Goal: Install Mem0 OSS with all dependencies

Actions:
- Detect language (Python or JavaScript/TypeScript)
- Install correct package with full dependencies:
  - Python: pip install "mem0ai[all]"
  - JavaScript/TypeScript: npm install mem0ai pg @supabase/supabase-js
- Verify installation successful

Phase 3: Database Setup
Goal: Create memory tables in Supabase

Actions:

Launch the mem0-integrator agent to setup OSS database.

Provide the agent with:
- Mode: Open Source (self-hosted)
- Backend: Supabase PostgreSQL + pgvector
- Requirements:
  - Enable pgvector extension
  - Create memories table with embedding vector column
  - Create memory_relationships table (for graph memory)
  - Setup indexes for performance
  - Create RLS policies for security
  - Configure connection pooling
- Expected output: Complete database schema with tables created

Phase 4: Client Configuration
Goal: Configure Mem0 to use Supabase

Actions:
- Generate memory client configuration
- Configure vector store to use PostgreSQL
- Setup embedding model (OpenAI or custom)
- Add environment variables for Supabase connection
- Create client initialization code with Supabase config

Phase 5: Verification
Goal: Test OSS setup with Supabase

Actions:
- Test database connection
- Verify pgvector extension is enabled
- Test memory operations (add, search)
- Check RLS policies are active
- Validate embeddings storage

Phase 6: Summary
Goal: Show setup results and next steps

Actions:
- Display what was configured:
  - Supabase: Initialized with pgvector
  - Database: Memory tables created
  - Package: mem0ai[all]@version
  - Client: Configured for PostgreSQL backend
- Show next steps:
  1. Configure embedding model in .env
  2. Test memory operations
  3. Use /mem0:add-conversation-memory for chat integration
  4. Use /mem0:add-graph-memory for relationships
  5. Run /mem0:test for complete validation
- Provide documentation links:
  - OSS: https://docs.mem0.ai/open-source/overview
  - Supabase integration: https://docs.mem0.ai/open-source/configuration
