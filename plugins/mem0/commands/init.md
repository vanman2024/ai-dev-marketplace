---
description: Initialize Mem0 (Platform, OSS, or MCP) - intelligent router that asks deployment mode and routes to appropriate init command
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, Skill
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

Goal: Initialize Mem0 in the current project by detecting existing setup and asking user for Platform (hosted), Open Source (self-hosted with Supabase), or MCP (local OpenMemory) deployment mode.

Core Principles:
- Ask user for deployment preference (Platform vs OSS vs MCP)
- Detect existing frameworks and adapt integration
- Verify setup works before completing
- Provide clear next steps

Phase 1: Discovery
Goal: Understand project context and requirements

Actions:
- Detect project type and language:
  - Check for package.json (Node.js/TypeScript)
  - Check for requirements.txt or pyproject.toml (Python)
  - Check for existing AI frameworks (Vercel AI SDK, LangChain, etc.)
- Check if Mem0 is already installed:
  - Look for mem0ai in dependencies
  - Check for existing memory configuration
- Check if Supabase is initialized:
  - Look for .mcp.json with supabase server
  - Check for SUPABASE_* environment variables
- Check if OpenMemory MCP is running:
  - Test connection to http://localhost:8765
  - Check MEM0_API_KEY in ~/.bashrc

Phase 2: Deployment Mode Selection
Goal: Ask user how they want to deploy Mem0

Actions:
- Use AskUserQuestion to ask:
  - "Which deployment mode do you want?"
    - MCP (Local): Private, local-first, cross-tool memory (OpenMemory)
    - Platform (Hosted): Managed by Mem0, quick setup, enterprise features
    - Open Source (Self-hosted): Full control, Supabase backend, unlimited usage
- If user selects MCP:
  - Check if MEM0_API_KEY exists in ~/.bashrc
  - Check if OpenMemory is running
  - Route to /mem0:init-mcp
- If user selects Platform:
  - Proceed to Phase 3 with Platform mode
  - Route to /mem0:init-platform
- If user selects OSS:
  - Check if Supabase is initialized
  - If not, warn that Supabase is required for OSS mode
  - Suggest running /supabase:init first
  - Proceed to Phase 3 with OSS mode
  - Route to /mem0:init-oss

Phase 3: Integration Planning
Goal: Determine what needs to be integrated

Actions:
- Based on detected frameworks, plan integration approach
- Identify where memory operations should be added
- Check for existing memory patterns in codebase
- Determine if graph memory is needed (ask user if unclear)

Phase 4: Implementation
Goal: Setup Mem0 with chosen deployment mode

Actions:

Launch the mem0-integrator agent to initialize Mem0.

Provide the agent with:
- Deployment mode: [Platform or OSS from Phase 2]
- Project type: [Detected language and frameworks]
- Supabase status: [Initialized or not]
- Integration targets: [Frameworks that need memory integration]
- Requirements:
  - Install correct packages (mem0ai or mem0ai[all])
  - Configure environment variables
  - Create memory client configuration
  - Generate integration code for detected frameworks
  - If OSS mode: Setup Supabase tables and pgvector
  - Test memory operations work correctly
- Expected output: Complete Mem0 setup with working memory operations

Phase 5: Verification
Goal: Ensure setup is correct

Actions:
- Test Mem0 client initialization
- Run a simple memory operation (add and search)
- Verify environment variables are set
- Check Supabase connection (if OSS mode)
- Confirm integration code is correct

Phase 6: Summary
Goal: Show what was accomplished and next steps

Actions:
- Display setup results:
  - Deployment mode: [Platform or OSS]
  - Installed packages: [List]
  - Configuration files created: [List]
  - Environment variables needed: [List]
  - Integration code added: [List]
- Show next steps:
  - Set API keys in .env file (Platform mode)
  - Run /mem0:add-conversation-memory to integrate with chat
  - Run /mem0:add-user-memory to track user preferences
  - Run /mem0:configure to customize memory settings
  - Run /mem0:test to validate complete setup
- Provide links to documentation:
  - Platform: https://docs.mem0.ai/platform/quickstart
  - OSS: https://docs.mem0.ai/open-source/overview
