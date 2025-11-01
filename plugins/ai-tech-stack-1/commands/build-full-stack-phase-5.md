---
description: "Phase 5: Production Deployment - Deploy to Vercel + Fly.io, validate deployment health"
argument-hint: none
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*)
---

**Arguments**: $ARGUMENTS

Goal: Deploy to production (Vercel + Fly.io) and validate deployment health.

Core Principles:
- Use dev-lifecycle-marketplace deployment commands
- Pre-flight checks before deploying
- Actual deployment execution
- Post-deployment health validation
- Capture deployment URLs

Phase 1: Load State
Goal: Read Phase 4 config and verify tests passed

Actions:
- Check .ai-stack-config.json exists
- Load config: @.ai-stack-config.json
- Verify phase4Complete is true
- Verify testsPassedNewman, testsPassedPlaywright, securityPassed all true
- If any tests failed:
  - STOP with error: "Cannot deploy - tests failed in Phase 4"
  - Return to Phase 4 to fix tests
- Extract appName, paths
- Create Phase 5 todo list

Phase 2: Pre-Flight Checks
Goal: Verify deployment readiness

Actions:
- Update .ai-stack-config.json phase to 5
- Run pre-flight checks:
  SlashCommand: /deployment:prepare
- Wait for completion
- This verifies:
  - Build tools installed (vercel CLI, fly CLI)
  - Authentication configured (vercel token, fly token)
  - Environment variables documented
  - Dependencies up to date
  - No blockers to deployment
- Parse pre-flight results
- If checks failed:
  - Display missing requirements
  - STOP and return error
- If checks passed:
  - Display readiness summary
  - Mark pre-flight complete
- Time: ~5 minutes

Phase 3: Deploy to Production
Goal: Execute actual deployment

Actions:
- Deploy applications:
  SlashCommand: /deployment:deploy
- Wait for completion
- This deploys:
  - Frontend to Vercel (auto-detected Next.js)
  - Backend to Fly.io (auto-detected FastAPI)
  - Database already on Supabase Cloud
- Deployment process:
  - Detects project types automatically
  - Runs build commands
  - Uploads to platforms
  - Configures environment variables
  - Sets up domains/URLs
- Capture deployment outputs:
  - Frontend URL: https://$APP_NAME.vercel.app
  - Backend URL: https://$APP_NAME-backend.fly.dev
  - Database URL: From Supabase project
- If deployment failed:
  - Display deployment errors
  - STOP and return error
- If deployment succeeded:
  - Store URLs in .ai-stack-config.json
  - Mark deployment complete
- Time: ~20 minutes

Phase 4: Validate Deployment Health
Goal: Run post-deployment health checks

Actions:
- Validate frontend deployment:
  SlashCommand: /deployment:validate $FRONTEND_URL
- Wait for completion
- This checks:
  - URL accessible (200 status)
  - Page loads correctly
  - No JavaScript errors
  - Assets loading
  - API connectivity
- Validate backend deployment:
  SlashCommand: /deployment:validate $BACKEND_URL
- Wait for completion
- This checks:
  - API health endpoint responding
  - Database connectivity
  - Authentication working
  - No critical errors in logs
- Parse validation results
- If validation failed:
  - Display health check errors
  - Deployment succeeded but has issues
  - Mark as "deployed with warnings"
- If validation passed:
  - Display health check success
  - Mark validation complete
- Time: ~5 minutes

Phase 5: Summary Phase 5
Goal: Save deployment state and prepare for Phase 6

Actions:
- Update .ai-stack-config.json:
  - phase5Complete: true
  - phase: 5
  - deployed: true
  - frontendUrl: $FRONTEND_URL
  - backendUrl: $BACKEND_URL
  - deploymentTimestamp: current time
  - validationPassed: true/false
  - nextPhase: "Phase 6 - Versioning & Summary"

- Display deployment summary:
  ✅ Phase 5 Complete: Production Deployment

  Frontend: https://$APP_NAME.vercel.app ✅
  Backend: https://$APP_NAME-backend.fly.dev ✅
  Database: Supabase Cloud ✅

  Health Checks: ✅ PASSED

  Ready for Phase 6: Versioning & Summary
  Run: /ai-tech-stack-1:build-full-stack (continues automatically)

  Time: ~30 minutes

- If deployment or validation failed:
  - Display failure details
  - Provide troubleshooting steps
  - STOP execution

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 5
