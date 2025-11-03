# AI Tech Stack Phase Metadata

This directory contains scripts and metadata for analyzing the AI Tech Stack 1 deployment phases.

## Files

### Scripts

- **`extract-comprehensive-metadata.sh`** - Comprehensive extraction script that recursively traces ALL nested slash commands across all marketplaces
  - Searches across multiple marketplaces (ai-dev-marketplace, dev-lifecycle-marketplace, mcp-servers-marketplace, domain-plugin-builder)
  - Handles plugin name aliases (e.g., `agent-sdk-dev` → `claude-agent-sdk`)
  - Recursively traces command chains up to depth 5
  - Extracts agents and skills used in each phase
  - Generates JSON with complete command dependency tree

### Generated Metadata

- **`phases-metadata-complete.json`** - Complete metadata for all 6 phases (0-5)
  - Generated timestamp
  - All commands with depth tracking (0 = direct, 1+ = nested)
  - Agents used per phase
  - Command counts

- **`phases-metadata-summary.json`** - Summary view with totals
  - Total phases analyzed: 6
  - Total commands across all phases: 46
  - Breakdown by phase with command counts

## Phase Breakdown

### Phase 0: Dev Lifecycle Foundation
**Commands:** 7 (all depth 0)
- `/foundation:detect`
- `/foundation:env-check`
- `/foundation:hooks-setup`
- `/planning:architecture`
- `/planning:decide`
- `/planning:init-project`
- `/planning:roadmap`

### Phase 1: Foundation (Next.js + FastAPI + Supabase)
**Commands:** 4 (3 depth 0, 1 depth 1)
- Depth 0:
  - `/fastapi-backend:init-ai-app`
  - `/nextjs-frontend:build-full-stack` (orchestrator)
  - `/supabase:init-ai-app`
- Depth 1 (called by orchestrators):
  - `/nextjs-frontend:init`

### Phase 2: AI Features (Vercel AI SDK + Mem0 + Claude Agent SDK)
**Commands:** 28 (6 depth 0, 22 depth 1)
- Depth 0:
  - `/claude-agent-sdk:build-full-app` (orchestrator)
  - `/mem0:add-conversation-memory`
  - `/mem0:add-user-memory`
  - `/mem0:init-oss`
  - `/mem0:test`
  - `/vercel-ai-sdk:build-full-stack` (orchestrator)
- Depth 1 (called by `/claude-agent-sdk:build-full-app`):
  - 14 commands: `new-app`, `add-streaming`, `add-sessions`, `add-mcp`, `add-custom-tools`, `add-subagents`, `add-permissions`, `add-hosting`, `add-system-prompts`, `add-slash-commands`, `add-skills`, `add-plugins`, `add-cost-tracking`, `add-todo-tracking`
- Depth 1 (called by `/vercel-ai-sdk:build-full-stack`):
  - 8 commands: `new-app`, `add-streaming`, `add-tools`, `add-chat`, `add-ui-features`, `add-data-features`, `add-production`, `add-advanced`

### Phase 3: Integration
**Commands:** 2 (all depth 0)
- `/nextjs-frontend:add-component`
- `/nextjs-frontend:search-components`

### Phase 4: Testing & Quality Assurance
**Commands:** 2 (all depth 0)
- `/quality:security`
- `/quality:test`

### Phase 5: Production Deployment
**Commands:** 3 (all depth 0)
- `/deployment:deploy`
- `/deployment:prepare`
- `/deployment:validate`

## Command Patterns

### Orchestrator Commands
Commands that call multiple other commands sequentially:
- `/nextjs-frontend:build-full-stack` (Phase 1)
- `/claude-agent-sdk:build-full-app` (Phase 2)
- `/vercel-ai-sdk:build-full-stack` (Phase 2)

### Leaf Commands
Commands that use Task() to invoke agents instead of calling other slash commands:
- Most commands at depth 1 are leaf commands
- They invoke specialized agents to perform work

## Usage

### Generate New Metadata
```bash
cd scripts/
bash extract-comprehensive-metadata.sh > phases-metadata-complete.json 2>/dev/null
```

### Query Metadata
```bash
# Get summary
jq '.summary' phases-metadata-summary.json

# Get commands for a specific phase
jq '.phases[2]' phases-metadata-complete.json

# Count depth-0 vs depth-1 commands
jq '.phases[2].allCommands | group_by(.depth) | map({depth: .[0].depth, count: length})' phases-metadata-complete.json
```

## Agent Analysis Results

Based on parallel agent analysis of all plugins:

**Total Commands Found Across ALL Plugins:** ~131
- Group 1 (claude-agent-sdk, elevenlabs, fastapi-backend, mem0, ml-training): 65 commands
- Group 2 (nextjs-frontend, openrouter, rag-pipeline): 28 commands
- Group 3 (supabase, vercel-ai-sdk, website-builder, lifecycle): 38 commands

**Commands Used in Phases 0-5:** 46 (35% of total available)

**Missing from Phases:**
- ALL openrouter commands (5 commands)
- ALL rag-pipeline commands (15 commands)
- ALL website-builder commands (11 commands)
- ALL elevenlabs commands (9 commands)
- ALL ml-training commands (17 commands)
- Many supabase commands (9 commands)
- Many fastapi-backend commands (8 commands)
- Several mem0 commands (4 commands)

## Plugin Alias Mapping

The extraction script handles plugin name aliases:

| Slash Command Prefix | Actual Plugin Directory |
|---------------------|-------------------------|
| `/agent-sdk-dev:*`  | `claude-agent-sdk`      |

Add more aliases to the script as needed.

## Marketplace Search Paths

The script searches for commands in these marketplaces (in order):
1. `ai-dev-marketplace`
2. `dev-lifecycle-marketplace`
3. `mcp-servers-marketplace`
4. `domain-plugin-builder`

## Notes

- **Depth 0** = Commands called directly from phase files
- **Depth 1** = Commands called by depth-0 orchestrator commands
- **Depth 2+** = Further nested commands (rare, as most commands use agents instead)
- **Max Depth**: Script recurses up to depth 5 to prevent infinite loops

## Future Enhancements

Potential additions to phases based on missing commands:

**Phase 6: Advanced Features** (could include):
- RAG pipeline commands
- OpenRouter model routing
- ElevenLabs voice capabilities
- ML training workflows
- Website builder integration

**Expand Existing Phases:**
- Phase 1: Add more supabase commands (RLS, storage, pgvector)
- Phase 2: Add mem0 graph memory, OpenRouter integration
- Phase 3: Add more integration commands
- Phase 4: Add more comprehensive testing commands
