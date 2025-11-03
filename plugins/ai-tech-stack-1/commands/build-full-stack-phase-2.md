---
description: "Phase 2: AI Features - Vercel AI SDK, Mem0, Claude Agent SDK, MCP servers"
argument-hint: none
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*), Skill
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

Goal: Add AI features - Vercel AI SDK + Mem0 + Claude Agent SDK + MCP.

Phase 1: Load State
- Load .ai-stack-config.json
- Verify phase1Complete is true
- Extract appName, paths
- Create Phase 2 todo list

Phase 2: Task Orchestration
- Execute immediately: !{slashcommand /foundation:env-check}
- After completion, execute immediately: !{slashcommand /iterate:tasks phase-2-ai-features}
- After completion, save execution plan to .ai-stack-phase-2-tasks.json

Phase 3: Add Vercel AI SDK (Frontend)
- Execute immediately: !{slashcommand /nextjs-frontend:integrate-ai-sdk}
- After completion, verify: !{bash grep -q "ai" "$APP_NAME/package.json" && echo "✅" || echo "❌"}

Phase 4: Add Vercel AI SDK (Backend)
- Execute immediately: !{slashcommand /vercel-ai-sdk:add-provider openai}
- After completion, verify Backend AI SDK configured

Phase 5: Setup Mem0 Memory
- Execute immediately: !{slashcommand /mem0:init-oss}
- After completion, verify: !{bash grep -q "mem0" "$APP_NAME-backend/requirements.txt" && echo "✅" || echo "❌"}

Phase 6: Add Claude Agent SDK
- Execute immediately: !{slashcommand /claude-agent-sdk:new-app agent-orchestrator}
- After completion, verify Agent SDK configured

Phase 7: Configure MCP Servers
- Execute immediately: !{slashcommand /foundation:mcp-manage add supabase}
- After completion, execute immediately: !{slashcommand /foundation:mcp-manage add memory}
- After completion, execute immediately: !{slashcommand /foundation:mcp-manage add filesystem}
- After completion, verify: .mcp.json exists

Phase 8: Validation
- Execute immediately: !{slashcommand /planning:analyze-project}
- After completion, execute immediately: !{slashcommand /iterate:sync phase-2-complete}

Phase 9: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 2 | .phase2Complete = true | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display: "✅ Phase 2 Complete - AI features added"

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 2
