---
description: Setup hosted Mem0 Platform with API keys and quick configuration
argument-hint: [project-name]
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

Goal: Setup Mem0 Platform (hosted mode) with API key configuration and quick start code.

Core Principles:
- Quick setup with minimal configuration
- Platform handles infrastructure
- Enterprise features ready to use
- Provide usage examples

Phase 1: Package Installation
Goal: Install Mem0 Platform client

Actions:
- Detect language (Python or JavaScript/TypeScript)
- Install correct package:
  - Python: pip install mem0ai
  - JavaScript/TypeScript: npm install mem0ai
- Verify installation successful
- Check package versions

Phase 2: API Key Configuration
Goal: Setup environment variables

Actions:
- Create or update .env file with MEM0_API_KEY placeholder
- Add .env to .gitignore if not already present
- Create .env.example for documentation
- Explain how to get API key from https://app.mem0.ai

Phase 3: Client Code Generation
Goal: Create memory client initialization code

Actions:

Launch the mem0-integrator agent to generate Platform client code.

Provide the agent with:
- Mode: Platform (hosted)
- Language: [Detected from Phase 1]
- Requirements:
  - Generate MemoryClient initialization code
  - Add example memory operations (add, search, get, update, delete)
  - Include error handling
  - Add TypeScript types (if applicable)
- Expected output: Working memory client code with examples

Phase 4: Verification
Goal: Test Platform connection

Actions:
- Test client initialization (will fail without API key, but validates code)
- Show sample usage code
- Verify environment setup is correct

Phase 5: Summary
Goal: Show setup results and instructions

Actions:
- Display what was configured:
  - Package installed: mem0ai@version
  - Client code created: [file path]
  - Environment template: .env.example
- Show next steps:
  1. Get API key from https://app.mem0.ai
  2. Add key to .env file: MEM0_API_KEY=your-key-here
  3. Test with sample code
  4. Use /mem0:add-conversation-memory to integrate with chat
  5. Use /mem0:configure for advanced settings
- Provide documentation link: https://docs.mem0.ai/platform/quickstart
