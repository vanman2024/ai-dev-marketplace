---
description: "Phase 6: Versioning & Final Summary - Version bump, changelog, complete documentation"
argument-hint: none
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*), Skill
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

Goal: Generate final version, changelog, and comprehensive deployment summary.

Core Principles:
- Use dev-lifecycle-marketplace versioning commands
- Generate comprehensive changelog
- Sync all documentation with final state
- Create complete deployment summary
- Validate all specs satisfied

Phase 1: Load State
Goal: Read Phase 5 config and verify deployment succeeded

Actions:
- Check .ai-stack-config.json exists
- Load config: @.ai-stack-config.json
- Verify phase5Complete is true
- Verify deployed is true
- Verify validationPassed is true
- If deployment failed:
  - STOP with error: "Cannot finalize - deployment failed in Phase 5"
  - Return to Phase 5 to fix deployment
- Extract appName, URLs, paths
- Create Phase 6 todo list

Phase 2: Final Spec Status Report
Goal: Generate comprehensive spec coverage report

Actions:
- Update .ai-stack-config.json phase to 6
- Generate final spec status report:
  Execute immediately: !{slashcommand /planning:analyze-project}
- This analyzes:
  - All specs in specs/ directory
  - Implementation coverage percentage
  - Completed vs pending features
  - Missing requirements
  - Technical debt
- Export spec coverage metrics
- Document final project state
- Parse analysis results
- If coverage < 80%:
  - Display incomplete features
  - Mark as "deployed with gaps"
- If coverage >= 80%:
  - Display completion summary
  - Mark spec analysis complete
- Time: ~3 minutes

Phase 3: Version Management
Goal: Bump version and generate changelog

Actions:
- Execute version bump:
  Execute immediately: !{slashcommand /versioning:bump patch}
- This performs:
  - Semantic version increment (patch level)
  - Git tag creation
  - Changelog generation from commits
  - Version file updates (package.json, pyproject.toml)
- Parse versioning results
- Capture new version number
- Store version in .ai-stack-config.json
- If versioning failed:
  - Display versioning errors
  - Continue anyway (not blocking)
- If versioning succeeded:
  - Display version and changelog
  - Mark versioning complete
- Time: ~2 minutes

Phase 4: Documentation Sync
Goal: Update all docs with final deployment state

Actions:
- Sync documentation:
  Execute immediately: !{slashcommand /iterate:sync}
- This updates:
  - Task completion status
  - Spec implementation status
  - Documentation with deployment URLs
  - Environment variable docs
  - README files
- Parse sync results
- Verify docs updated correctly
- If sync failed:
  - Display sync errors
  - Continue anyway (not blocking)
- If sync succeeded:
  - Display sync summary
  - Mark doc sync complete
- Time: ~2 minutes

Phase 5: Final Summary Generation
Goal: Create comprehensive DEPLOYMENT-COMPLETE.md

Actions:
- Load all config data:
  !{bash cat .ai-stack-config.json | jq '.'}
- Extract key information:
  - appName
  - frontendUrl
  - backendUrl
  - databaseUrl (Supabase project)
  - version (if available)
  - timestamp
- Create DEPLOYMENT-COMPLETE.md:
  ```markdown
  # AI Tech Stack 1 Deployment Complete

  ## Project: $APP_NAME

  **Version:** $VERSION
  **Deployed:** $TIMESTAMP

  ### 🎯 Production URLs

  - **Frontend:** $FRONTEND_URL
  - **Backend:** $BACKEND_URL
  - **Database:** Supabase Cloud ($PROJECT_ID)

  ### 📦 Stack Components

  **Frontend ($APP_NAME/):**
  - Next.js 15 with App Router
  - Vercel AI SDK with streaming
  - Mem0 memory client
  - shadcn/Tailwind UI components
  - Deployed to Vercel

  **Backend ($APP_NAME-backend/):**
  - FastAPI REST API
  - AI providers (Claude, OpenAI, Google)
  - Mem0 memory operations
  - Claude Agent SDK orchestration
  - Supabase client
  - Deployed to Fly.io

  **Database:**
  - Supabase PostgreSQL
  - Auth configured (Email/OAuth)
  - RLS policies active
  - pgvector for embeddings
  - Memory tables (Mem0)
  - Realtime subscriptions

  **MCP Servers Configured:**
  - supabase (database operations)
  - memory (user/agent/session memory)
  - filesystem (file operations)

  ### ✅ Deployment Validation

  - Frontend health check: ✅ PASSED
  - Backend health check: ✅ PASSED
  - Database connectivity: ✅ PASSED
  - API endpoints: ✅ PASSED
  - Authentication: ✅ PASSED

  ### 🧪 Testing Results

  - Newman API Tests: ✅ PASSED
  - Playwright E2E Tests: ✅ PASSED
  - Security Scans: ✅ PASSED
  - Production Smoke Tests: ✅ PASSED

  ### 📋 Environment Variables

  See `ENVIRONMENT.md` for complete list of required environment variables.

  **Critical Environment Variables:**
  - `ANTHROPIC_API_KEY` - Claude API access
  - `OPENAI_API_KEY` - OpenAI API access (optional)
  - `SUPABASE_URL` - Database connection
  - `SUPABASE_ANON_KEY` - Database auth
  - `NEXT_PUBLIC_BACKEND_URL` - Frontend → Backend connection

  ### 🚀 Next Steps

  **Monitor Production:**
  1. Frontend logs: `vercel logs $APP_NAME`
  2. Backend logs: `fly logs -a $APP_NAME-backend`
  3. Database monitoring: Supabase Dashboard

  **Scale as Needed:**
  1. Frontend: Auto-scales on Vercel
  2. Backend: `fly scale count 2` (or more)
  3. Database: Upgrade Supabase plan if needed

  **Maintenance:**
  1. Monitor error rates and performance
  2. Keep dependencies updated
  3. Review security advisories
  4. Backup database regularly (Supabase handles this)

  ### 📊 Deployment Timeline

  - Phase 0 (Dev Lifecycle Foundation): ~10 minutes
  - Phase 1 (Foundation): ~20 minutes
  - Phase 2 (AI Features): ~25 minutes
  - Phase 3 (Integration): ~25 minutes
  - Phase 4 (Testing & QA): ~30 minutes
  - Phase 5 (Production Deployment): ~30 minutes
  - Phase 6 (Versioning & Summary): ~7 minutes

  **Total Deployment Time:** ~2.5 hours (complete automation, start to production)

  ### 🎉 Success!

  Your complete AI application stack is now live in production!

  Access your application at: $FRONTEND_URL
  ```

- Display: @DEPLOYMENT-COMPLETE.md
- Mark summary generation complete

Phase 6: Update Final State
Goal: Mark all phases complete in config

Actions:
- Update .ai-stack-config.json:
  !{bash jq '.phase = 6 | .phase6Complete = true | .allPhasesComplete = true | .version = "'$VERSION'" | .finalizedAt = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > .ai-stack-config.tmp && mv .ai-stack-config.tmp .ai-stack-config.json}

- Mark all Phase 6 todos complete

- Display final status:
  ```
  ✅ Phase 6 Complete: Versioning & Final Summary

  Version: $VERSION
  Changelog: ✅ Generated
  Documentation: ✅ Synced
  Final Summary: ✅ Created

  🎉 All 6 Phases Complete!

  Phase 0: Dev Lifecycle Foundation ✅
  Phase 1: Foundation (Next.js + FastAPI + Supabase) ✅
  Phase 2: AI Features (Vercel AI SDK + Mem0 + Agent SDK) ✅
  Phase 3: Integration (Services + UI Components) ✅
  Phase 4: Testing & Quality Assurance ✅
  Phase 5: Production Deployment ✅
  Phase 6: Versioning & Final Summary ✅

  Total Time: ~2.5 hours
  Production URLs: See DEPLOYMENT-COMPLETE.md

  Your AI application is live! 🚀
  ```

## What Phase 6 Creates

**Versioning:**
- Semantic version bump (patch)
- Git tag
- Changelog from commits

**Documentation:**
- Final spec coverage report
- Synced task status
- Complete DEPLOYMENT-COMPLETE.md
- Updated environment docs

**Validation:**
- Verify all specs satisfied
- Confirm deployment success
- Document any gaps

**Total Time:** ~7 minutes

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 6
