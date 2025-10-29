---
description: "Phase 3: Integration - Wire services, add UI components, deploy to Vercel + Fly.io"
argument-hint: none
allowed-tools: SlashCommand(*), TodoWrite(*), Read(*), Write(*), Bash(*), Grep(*)
---

**Arguments**: $ARGUMENTS

Goal: Wire all services together, add UI components, deploy to production.

Core Principles:
- Connect frontend ↔ backend
- Add shadcn/Tailwind UI components
- Configure deployments
- Validate complete stack
- Progressive context (very late - minimal agents)

Phase 1: Load State
Goal: Read Phase 2 config

CONTEXT: Late conversation - 1 agent max

Actions:
- Check .ai-stack-config.json exists
- Load config: @.ai-stack-config.json
- Verify phase2Complete is true
- Extract appName
- Create Phase 3 todo list

Phase 2: Frontend-Backend Connection
Goal: Wire Next.js frontend to FastAPI backend

CONTEXT: Late - 1 agent only

Actions:
- Update .ai-stack-config.json phase to 3
- Create API client in frontend:
  !{bash mkdir -p "$APP_NAME/lib"}
- Write lib/api-client.ts that connects to FastAPI backend
- Configure CORS in backend:
  !{bash cd "$APP_NAME-backend" && pip install fastapi-cors}
- Add CORS middleware to main.py allowing frontend origin
- Add backend URL to frontend .env.local:
  !{bash echo "NEXT_PUBLIC_BACKEND_URL=http://localhost:8000" >> "$APP_NAME/.env.local"}
- Verify: !{bash test -f "$APP_NAME/lib/api-client.ts" && echo "✅ Connected" || echo "❌ Failed"}
- Mark Connection complete

Phase 3: UI Components
Goal: Add shadcn and Tailwind UI components

CONTEXT: Late - 1 agent only

Actions:
- Change to frontend: !{bash cd "$APP_NAME"}
- Add shadcn components for chat:
  - SlashCommand: /nextjs-frontend:add-component button
  - Wait for completion
  - SlashCommand: /nextjs-frontend:add-component input
  - Wait for completion
  - SlashCommand: /nextjs-frontend:add-component card
  - Wait for completion
  - SlashCommand: /nextjs-frontend:add-component avatar
  - Wait for completion
- Search for chat UI:
  - SlashCommand: /nextjs-frontend:search-components "chat"
- Add chat interface components
- Verify: !{bash test -d "$APP_NAME/components/ui" && echo "✅ UI components added" || echo "❌ Failed"}
- Mark UI complete

Phase 4: Backend Deployment Config
Goal: Setup Fly.io deployment for FastAPI

CONTEXT: Very late - NO agents

Actions:
- Update .ai-stack-config.json phase to 4
- Change to backend: !{bash cd "$APP_NAME-backend"}
- Create fly.toml:
  !{bash cat > fly.toml << 'EOF'
app = "$APP_NAME-backend"
primary_region = "iad"

[build]
  builder = "paketobuildpacks/builder:base"

[env]
  PORT = "8000"

[[services]]
  internal_port = 8000
  protocol = "tcp"

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]
EOF
}
- Create .dockerignore
- Verify: !{bash test -f "$APP_NAME-backend/fly.toml" && echo "✅ Fly.io configured" || echo "❌ Failed"}
- Mark Backend Deploy complete

Phase 5: Frontend Deployment Config
Goal: Setup Vercel deployment for Next.js

CONTEXT: Very late - NO agents

Actions:
- Change to frontend: !{bash cd "$APP_NAME"}
- Create vercel.json:
  !{bash cat > vercel.json << 'EOF'
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": "nextjs",
  "outputDirectory": ".next"
}
EOF
}
- Update .env.local with production backend URL placeholder:
  !{bash echo "# Production: NEXT_PUBLIC_BACKEND_URL=https://$APP_NAME-backend.fly.dev" >> .env.local}
- Create .env.example documenting all variables
- Verify: !{bash test -f "$APP_NAME/vercel.json" && echo "✅ Vercel configured" || echo "❌ Failed"}
- Mark Frontend Deploy complete

Phase 6: Environment Documentation
Goal: Document all required environment variables

CONTEXT: Very late - NO agents

Actions:
- Create ENVIRONMENT.md in root:
  - List all env vars for frontend
  - List all env vars for backend
  - Deployment instructions
  - Local development setup
- Create .env.example in both frontend and backend
- Verify: !{bash test -f ENVIRONMENT.md && echo "✅ Documented" || echo "❌ Failed"}
- Mark Documentation complete

Phase 7: Final Validation
Goal: Verify complete stack works

CONTEXT: Very late - NO agents

Actions:
- Update .ai-stack-config.json phase to 7
- Frontend validation:
  !{bash cd "$APP_NAME" && npm run typecheck 2>&1 | head -20}
  !{bash cd "$APP_NAME" && npm run build 2>&1 | tail -30}
- Backend validation:
  !{bash cd "$APP_NAME-backend" && python -m pytest || echo "No tests yet"}
  !{bash cd "$APP_NAME-backend" && python -c "import main; print('✅ Backend imports work')"}
- If validation fails: Write validation-errors.txt and STOP
- Mark Validation complete

Phase 8: Final Summary
Goal: Complete deployment summary

Actions:
- Mark all Phase 3 todos complete
- Update .ai-stack-config.json:
  !{bash jq '.phase = 3 | .phase3Complete = true | .allPhasesComplete = true | .completedAt = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > .ai-stack-config.tmp && mv .ai-stack-config.tmp .ai-stack-config.json}

- Write DEPLOYMENT-COMPLETE.md:
  ```
  # AI Tech Stack 1 Deployment Complete

  ## Project: $APP_NAME

  ### Frontend ($APP_NAME/)
  - Next.js 15 with App Router
  - Vercel AI SDK with streaming
  - Mem0 memory client
  - shadcn/Tailwind UI components
  - Ready for Vercel deployment

  ### Backend ($APP_NAME-backend/)
  - FastAPI REST API
  - AI providers (Claude, OpenAI, Google)
  - Mem0 memory operations
  - Claude Agent SDK
  - Supabase client
  - Ready for Fly.io deployment

  ### Database
  - Supabase PostgreSQL
  - Auth configured
  - RLS policies
  - pgvector for embeddings
  - Memory tables

  ### MCP Servers Configured
  - supabase
  - memory
  - filesystem

  ### Environment Variables Needed
  See ENVIRONMENT.md for complete list

  ### Next Steps

  **Local Development:**
  1. Frontend: cd $APP_NAME && npm run dev
  2. Backend: cd $APP_NAME-backend && uvicorn main:app --reload
  3. Visit: http://localhost:3000

  **Deploy to Production:**
  1. Frontend to Vercel:
     cd $APP_NAME && vercel --prod

  2. Backend to Fly.io:
     cd $APP_NAME-backend && fly deploy

  3. Update frontend env with production backend URL

  ### Validation Results
  ✅ Frontend build successful
  ✅ Backend imports working
  ✅ All services connected
  ✅ Ready for deployment

  ### Total Deployment Time
  Phase 1: ~20 min
  Phase 2: ~25 min
  Phase 3: ~25 min
  Total: ~70 minutes

  🎉 Complete AI application stack ready!
  ```

- Display: @DEPLOYMENT-COMPLETE.md

## What Phase 3 Creates

**Integrations:**
- Frontend ↔ Backend API connection
- Backend ↔ Supabase connection
- All services wired together

**UI Components:**
- shadcn/ui components
- Chat interface
- Forms and inputs

**Deployment:**
- Vercel config (frontend)
- Fly.io config (backend)
- Environment documentation
- Production-ready

**Total Time:** ~25 minutes
