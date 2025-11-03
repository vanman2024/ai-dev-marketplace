---
description: "Phase 1: Foundation - Next.js frontend, FastAPI backend, Supabase database"
argument-hint: [app-name]
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*), Skill
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

Goal: Deploy foundation layer - Next.js + FastAPI + Supabase.

Phase 1: Load State
- Check .ai-stack-config.json exists
- Load config
- Verify phase0Complete is true
- Extract appName from $ARGUMENTS or config
- Create Phase 1 todo list

Phase 2: Task Orchestration
- Execute immediately: !{slashcommand /iterate:tasks phase-1-foundation}
- After completion, save execution plan to .ai-stack-phase-1-tasks.json

Phase 3: Build Next.js Frontend
- Execute immediately: !{slashcommand /nextjs-frontend:build-full-stack $APP_NAME}
- After completion, verify: !{bash test -f "$APP_NAME/package.json" && echo "✅" || echo "❌"}

Phase 4: Build FastAPI Backend
- Execute immediately: !{slashcommand /fastapi-backend:init-ai-app "$APP_NAME-backend"}
- After completion, verify: !{bash test -f "$APP_NAME-backend/main.py" && echo "✅" || echo "❌"}

Phase 5: Setup Supabase Database
- Execute immediately: !{slashcommand /supabase:init-ai-app}
- After completion, verify: !{bash grep -q "SUPABASE" "$APP_NAME/.env.local" && echo "✅" || echo "❌"}

Phase 6: Validation
- Execute immediately: !{slashcommand /planning:analyze-project}
- After completion, execute immediately: !{slashcommand /foundation:detect}
- After completion, execute immediately: !{slashcommand /iterate:sync phase-1-complete}

Phase 7: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 1 | .phase1Complete = true | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display: "✅ Phase 1 Complete - Foundation deployed"

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 1
