---
description: "Phase 2: AI Features - Vercel AI SDK, Mem0, Claude Agent SDK, MCP servers"
argument-hint: none
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*), Grep
---

**Arguments**: $ARGUMENTS

Goal: Add AI capabilities (Vercel AI SDK + Mem0 + Claude Agent SDK + MCP) with progressive context management.

Core Principles:
- Add streaming AI to frontend
- Configure memory persistence
- Integrate Claude Agent SDK
- Setup MCP servers (use existing, don't create new)
- Progressive context limits apply

Phase 1: Load State
Goal: Read Phase 1 config and determine app details

CONTEXT: Mid-conversation - limit to 2 agents

Actions:
- Check .ai-stack-config.json exists:
  !{bash test -f .ai-stack-config.json && echo "Found" || echo "Not found"}
- If not found: Error and STOP
- Load config: @.ai-stack-config.json
- Verify phase1Complete is true
- Extract appName and features
- Create Phase 2 todo list

Phase 2: Vercel AI SDK Frontend
Goal: Add AI SDK streaming to Next.js

CONTEXT: Mid - 2 agents max

Actions:
- Update .ai-stack-config.json phase to 2
- Change to frontend: !{bash cd "$APP_NAME"}
- SlashCommand: /vercel-ai-sdk:add-streaming
- Wait for completion before proceeding
- This adds:
  - ai package
  - app/api/chat/route.ts
  - Chat UI components
  - Streaming hooks
- If multi-model selected:
  - SlashCommand: /vercel-ai-sdk:add-provider openai
  - Wait for completion
  - SlashCommand: /vercel-ai-sdk:add-provider google
  - Wait for completion
- Verify: !{bash test -f "$APP_NAME/app/api/chat/route.ts" && echo "✅ AI SDK added" || echo "❌ Failed"}
- Mark AI SDK complete

Phase 3: Vercel AI SDK Backend
Goal: Add AI SDK to FastAPI backend

CONTEXT: Mid - 2 agents max

Actions:
- Change to backend: !{bash cd "$APP_NAME-backend"}
- Add dependencies:
  !{bash echo "anthropic\nopenai\ngoogle-generativeai" >> requirements.txt}
  !{bash pip install -r requirements.txt}
- Create routers/ai.py with AI endpoints
- Add chat endpoint that mirrors frontend API
- Add cost tracking utilities
- Verify: !{bash grep -q "anthropic" "$APP_NAME-backend/requirements.txt" && echo "✅ Backend AI ready" || echo "❌ Failed"}
- Mark Backend AI complete

Phase 4: Mem0 Memory
Goal: Configure Mem0 with Supabase backend

CONTEXT: Mid - 2 agents max

Actions:
- Update .ai-stack-config.json phase to 4
- Change to frontend: !{bash cd "$APP_NAME"}
- SlashCommand: /mem0:init-oss
- Wait for completion before proceeding
- This adds:
  - Mem0 OSS package
  - Supabase memory tables
  - Memory operations (add, search, update)
  - User/agent/session memory schemas
- Copy Mem0 setup to backend:
  !{bash cp -r "$APP_NAME/lib/mem0" "$APP_NAME-backend/lib/" 2>/dev/null || echo "Copy memory utils"}
- Verify: !{bash grep -q "mem0" "$APP_NAME/package.json" && echo "✅ Mem0 configured" || echo "❌ Failed"}
- Mark Memory complete

Phase 5: Claude Agent SDK
Goal: Integrate Agent SDK for orchestration

CONTEXT: Late - 1 agent only

Actions:
- Update .ai-stack-config.json phase to 5
- Change to backend: !{bash cd "$APP_NAME-backend"}
- SlashCommand: /claude-agent-sdk:add-custom-tools "$APP_NAME-backend"
- Wait for completion before proceeding
- This adds:
  - Claude Agent SDK
  - Custom tool definitions
  - Subagent configuration
  - Tool orchestration
- Create agents/ directory with specialized agents
- Verify: !{bash grep -q "claude-agent-sdk" "$APP_NAME-backend/requirements.txt" && echo "✅ Agent SDK added" || echo "❌ Failed"}
- Mark Agent SDK complete

Phase 6: MCP Server Configuration
Goal: Configure existing MCP servers (don't create new)

CONTEXT: Late - 1 agent only

Actions:
- Update .ai-stack-config.json phase to 6
- Create .mcp.json in backend with pre-configured servers:
  !{bash cat > "$APP_NAME-backend/.mcp.json" << 'EOF'
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-supabase"],
      "env": {
        "SUPABASE_URL": "${SUPABASE_URL}",
        "SUPABASE_KEY": "${SUPABASE_ANON_KEY}"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem"],
      "env": {
        "ALLOWED_DIRECTORIES": ["./data", "./uploads"]
      }
    }
  }
}
EOF
}
- Copy to frontend: !{bash cp "$APP_NAME-backend/.mcp.json" "$APP_NAME/.mcp.json"}
- Verify: !{bash test -f "$APP_NAME-backend/.mcp.json" && echo "✅ MCP configured" || echo "❌ Failed"}
- Mark MCP complete

Phase 7: Summary Phase 2
Goal: Save state and prepare for Phase 3

Actions:
- Mark all Phase 2 todos complete
- Update .ai-stack-config.json:
  !{bash jq '.phase = 2 | .phase2Complete = true | .completedAt = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > .ai-stack-config.tmp && mv .ai-stack-config.tmp .ai-stack-config.json}

- Write PHASE-2-SUMMARY.md:
  - Vercel AI SDK: Frontend + Backend
  - Mem0: Memory persistence configured
  - Claude Agent SDK: Orchestration ready
  - MCP Servers: supabase, memory, filesystem
  - Status: Ready for Phase 3 (Integration)

- Display: @PHASE-2-SUMMARY.md

- Instruct user: "Phase 2 complete! Run /ai-tech-stack-1:build-full-stack-phase-3 to continue"

## What Phase 2 Adds

**Frontend AI:**
- Vercel AI SDK with streaming
- Chat UI components
- Multi-model support
- Mem0 memory client

**Backend AI:**
- AI provider clients (Anthropic, OpenAI, Google)
- Chat endpoints
- Cost tracking
- Claude Agent SDK
- Custom tools
- Subagent orchestration

**Infrastructure:**
- Mem0 memory tables in Supabase
- MCP server configurations
- Memory operations

**Total Time:** ~25 minutes
