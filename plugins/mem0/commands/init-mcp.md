---
description: Setup Mem0 with OpenMemory MCP server for local-first AI memory
argument-hint: none
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

Goal: Initialize Mem0 using the official OpenMemory MCP server for private, local-first memory management.

Core Principles:
- Local-first approach (no cloud sync)
- MCP protocol for cross-tool compatibility
- Load API keys from environment (~/.bashrc)
- Validate MCP server connectivity
- Test memory operations

Phase 1: Prerequisites Check
Goal: Verify requirements for OpenMemory MCP

Actions:
- Check if MEM0_API_KEY exists in ~/.bashrc
- Check if OPENAI_API_KEY exists in environment
- Verify Docker is installed (required for OpenMemory)
- Check if port 8765 is available
- Display prerequisites status

If missing keys:
- Show instructions to add to ~/.bashrc:
  ```bash
  export MEM0_API_KEY="your-key-here"
  export OPENAI_API_KEY="your-openai-key"
  ```

Phase 2: OpenMemory Installation
Goal: Install and start OpenMemory MCP server

Actions:
- Use AskUserQuestion to confirm installation:
  - "Install OpenMemory MCP server? This will use Docker to run locally."
  - Options: "Install now", "Already installed", "Skip"

If "Install now":
- Run: `curl -sL https://raw.githubusercontent.com/mem0ai/mem0/main/openmemory/run.sh | bash`
- Wait for Docker containers to start
- Verify server is running on http://localhost:8765

If "Already installed":
- Check if server is running
- If not running, provide start command

Phase 3: MCP Configuration
Goal: Configure project to use OpenMemory MCP

Actions:

Launch the mem0-integrator agent to configure MCP integration.

Provide the agent with:
- Deployment mode: MCP (OpenMemory)
- MCP endpoint: http://localhost:8765/mcp/claude-code/sse/default
- API key source: ~/.bashrc (MEM0_API_KEY)
- Requirements:
  - Configure MCP client connection
  - Test MCP server connectivity
  - Verify memory operations work
  - Setup error handling
  - Configure user ID for memory isolation
  - Document MCP endpoints
- Expected output: Working MCP integration with tested memory operations

Phase 4: Verification
Goal: Validate OpenMemory MCP is working

Actions:
- Test MCP server is responding at http://localhost:8765
- Check MCP API docs at http://localhost:8765/docs
- Test memory add operation via MCP
- Test memory search operation via MCP
- Verify UI is accessible at http://localhost:8765
- Show memory operation examples

Phase 5: Summary
Goal: Provide MCP setup documentation

Actions:
- Display setup summary:
  - OpenMemory MCP status: [Running/Not running]
  - MCP endpoint: http://localhost:8765
  - UI dashboard: http://localhost:8765
  - API docs: http://localhost:8765/docs
  - Configuration: [Files modified]
- Show MCP features:
  - Local-first (no cloud sync)
  - Cross-tool memory sharing
  - Private and secure
  - Built-in UI for memory management
- Provide usage instructions:
  - How to start/stop OpenMemory
  - How to view memories in UI
  - How to use MCP tools in code
  - How to configure user isolation
- Provide next steps:
  - Add conversation memory: /mem0:add-conversation-memory
  - Add user memory: /mem0:add-user-memory
  - Enable graph memory: /mem0:add-graph-memory
  - Test setup: /mem0:test
- Show comparison with other modes:
  - MCP: Local-first, private, cross-tool
  - Platform: Managed, enterprise, cloud
  - OSS: Self-hosted, full control, Supabase
- Provide documentation:
  - OpenMemory docs: https://docs.mem0.ai/openmemory
  - MCP protocol: https://modelcontextprotocol.io
  - GitHub: https://github.com/mem0ai/mem0-mcp
