---
description: "Phase 5: Production Deployment - Deploy to Vercel + Fly.io, validate deployment health"
argument-hint: none
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*), Skill
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

Goal: Deploy to production and validate deployment health.

Phase 1: Load State
- Load .ai-stack-config.json
- Verify phase4Complete is true
- Verify all tests passed
- If tests failed: STOP with error
- Extract appName, paths
- Create Phase 5 todo list

Phase 2: Environment Check
- Execute immediately: !{slashcommand /foundation:env-check}
- After completion, verify deployment tools ready

Phase 3: Pre-Flight Checks
- Execute immediately: !{slashcommand /deployment:prepare}
- After completion, parse pre-flight results
- If checks failed: STOP and return error

Phase 4: Deploy to Production
- Execute immediately: !{slashcommand /deployment:deploy}
- After completion, capture deployment URLs
- If deployment failed: STOP and return error

Phase 5: Validate Deployment
- Execute immediately: !{slashcommand /deployment:validate $FRONTEND_URL}
- After completion, execute immediately: !{slashcommand /deployment:validate $BACKEND_URL}
- After completion, parse validation results
- If validation failed: Mark as "deployed with warnings"

Phase 6: Deployment Sync
- Execute immediately: !{slashcommand /iterate:sync deployment-status}
- After completion, mark deployment tasks complete

Phase 7: Smoke Tests
- Execute immediately: !{slashcommand /quality:test newman --env=production --collection=smoke-tests}
- After completion, verify critical paths work

Phase 8: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 5 | .phase5Complete = true | .deployed = true | .frontendUrl = "'$FRONTEND_URL'" | .backendUrl = "'$BACKEND_URL'" | .validationPassed = true | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display: "✅ Phase 5 Complete - Deployed to production"

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 5
