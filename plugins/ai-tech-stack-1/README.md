# AI Tech Stack 1 Plugin

**AI application stack orchestrator** - Deploys complete Next.js + Vercel AI SDK + Supabase + Mem0 + FastMCP applications with progressive context management.

## Overview

ai-tech-stack-1 is a lightweight orchestrator that coordinates existing plugins to deploy production-ready AI applications. It doesn't recreate functionality - it just calls the right commands in the right order with progressive context management to prevent infinite scrolling.

## What It Does

- **Orchestrates existing plugins** (nextjs-frontend, vercel-ai-sdk, supabase, mem0, fastmcp)
- **Progressive context management** (3 agents early → 2 mid → 1 late)
- **Sequential execution** with explicit waits between phases
- **Checkpoint state** for resumption if context grows too large
- **Comprehensive validation** at the end

## Installation

```bash
# Via Claude Code plugin system
/plugin install ai-tech-stack-1@ai-dev-marketplace

# Or add to ~/.claude/settings.json
{
  "enabledPlugins": {
    "ai-tech-stack-1@ai-dev-marketplace": true
  },
  "permissions": {
    "allow": [
      "SlashCommand(/ai-tech-stack-1:*)"
    ]
  }
}
```

## Commands

### `/ai-tech-stack-1:build-full-stack [app-name]`

Deploy complete AI application stack.

**What it does:**
1. Asks questions upfront (app type, features, auth, deployment)
2. Creates Next.js 15 frontend
3. Sets up Supabase database and auth
4. Integrates Vercel AI SDK for streaming
5. Configures Mem0 memory persistence
6. Optionally sets up FastMCP custom tools
7. Validates complete stack
8. Generates deployment summary

**Progressive Context Management:**
- Early phases (1-3): Up to 3 agents
- Mid phases (4-5): Limit to 2 agents
- Late phases (6-7): 1 agent only
- Very late (8): No agents

**Usage:**
```bash
/ai-tech-stack-1:build-full-stack my-ai-app
```

**Time:** 60-90 minutes (slow but reliable)

### `/ai-tech-stack-1:resume`

Resume deployment from saved state when context becomes too large.

**What it does:**
- Reads .deployment-config.json
- Continues from last completed phase
- Fresh context prevents infinite scrolling

**Usage:**
```bash
# If context becomes too large during build-full-stack
/ai-tech-stack-1:resume
```

### `/ai-tech-stack-1:validate [app-directory]`

Validate complete AI Tech Stack 1 deployment.

**What it does:**
- Checks file structure
- Verifies dependencies
- Runs build and type checks
- Generates validation report

**Usage:**
```bash
/ai-tech-stack-1:validate
/ai-tech-stack-1:validate my-ai-app
```

## Technology Stack

**Required Plugins:**
- nextjs-frontend - Next.js 15 setup
- vercel-ai-sdk - AI streaming and multi-model
- supabase - Database, auth, realtime
- mem0 - Memory persistence
- fastmcp - Custom MCP tools (optional)
- claude-agent-sdk - Agent orchestration (optional)

**Stack Components:**
- Next.js 15 (App Router, Server Components, TypeScript)
- Vercel AI SDK (streaming, multi-model, tools)
- Supabase (PostgreSQL, RLS, Auth, Realtime, pgvector)
- Mem0 (user/agent/session memory)
- FastMCP (custom tools, resources, prompts)

## Use Cases

- **Red AI** - Multi-pillar AI platform with cost tracking
- **AI Chatbots** - Conversational AI with streaming
- **RAG Systems** - Vector search with Supabase pgvector
- **Multi-Agent Systems** - Complex agent orchestration

## Context Management

The key innovation of ai-tech-stack-1 is **progressive context management**:

**Problem:** Late in conversations with lots of context, launching 4-5 agents causes infinite scrolling and hangs.

**Solution:** Progressively limit parallel agents as context grows:
- **Early (Phases 1-3):** 3 agents max - context is small
- **Mid (Phases 4-5):** 2 agents max - context growing
- **Late (Phase 6):** 1 agent only - context large
- **Very Late (Phases 7-8):** No agents - just validation

**Resumption:** If context becomes too large, state saved in .deployment-config.json for resumption with /ai-tech-stack-1:resume

## Architecture

ai-tech-stack-1 is a **pure orchestrator** - it doesn't create agents or skills, it just coordinates existing plugin commands:

```
/ai-tech-stack-1:build-full-stack
├─ Phase 1: Discovery (gather requirements)
├─ Phase 2: /nextjs-frontend:init
├─ Phase 3: /supabase:init-ai-app
├─ Phase 4: /vercel-ai-sdk:add-streaming
├─ Phase 5: /mem0:init-oss
├─ Phase 6: /fastmcp:new-server (optional)
├─ Phase 7: Validation (build, typecheck)
└─ Phase 8: Summary
```

Each phase waits for completion before proceeding. State saved between phases for resumption.

## Files Created

During deployment, the following files are created:

- `.deployment-config.json` - Deployment state for resumption
- `DEPLOYMENT-SUMMARY.md` - Comprehensive deployment summary
- `VALIDATION-REPORT.md` - Validation results
- `validation-errors.txt` - Errors if validation fails (only if failed)
- `error-log.txt` - Errors if any phase fails (only if failed)

## Deployment Targets

Supports multiple deployment options:
- **Vercel** - Frontend + serverless functions
- **Fly.io** - Backend services
- **Supabase Cloud** - Managed database
- **Self-Hosted** - Docker-based deployment

## Example: Red AI Deployment

```bash
# Start deployment
/ai-tech-stack-1:build-full-stack red-ai

# Answer questions:
# - App type: Red AI (multi-pillar platform with cost tracking)
# - Features: streaming, multi-model, cost tracking, memory, vector search
# - Auth: email, OAuth (Google, GitHub)
# - Deployment: Vercel, Fly.io, Supabase Cloud

# Wait 60-90 minutes (can walk away)

# Result: Complete Red AI foundation ready for customization
```

## Development

```bash
# Location
~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/ai-tech-stack-1/

# Structure
plugins/ai-tech-stack-1/
├── commands/
│   ├── build-full-stack.md
│   ├── resume.md
│   └── validate.md
├── .claude-plugin/
│   └── plugin.json
└── README.md
```

## Contributing

This plugin follows the domain-plugin-builder standards. To modify:

1. Edit commands in `commands/`
2. Update `plugin.json` if adding/removing commands
3. Test with validation: `/ai-tech-stack-1:validate`
4. Commit changes

## Support

- **Documentation:** This README
- **Issues:** Report at ai-dev-marketplace repository
- **Plugin Builder:** Use `/domain-plugin-builder:*` commands to modify

## License

MIT - Part of AI Dev Marketplace
