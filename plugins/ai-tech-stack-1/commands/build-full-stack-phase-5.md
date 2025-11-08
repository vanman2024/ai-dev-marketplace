---
description: "Phase 5: Production Deployment - Deploy with observability, feature flags, auto-rollback, and performance baselines"
argument-hint: none
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

Phase 8: Performance Baseline Capture
- Execute immediately: !{slashcommand /deployment:capture-baseline $FRONTEND_URL}
- After completion, capture baseline metrics (Lighthouse, API latency)
- Store baselines in .ai-stack-config.json for future regression detection
- Display: "✓ Performance baselines captured"

Phase 9: Observability Setup
- Execute immediately: !{slashcommand /deployment:setup-monitoring sentry}
- After completion, configure Sentry error tracking
- Execute immediately: !{slashcommand /deployment:setup-monitoring datadog}
- After completion, configure DataDog APM
- Verify monitoring dashboards accessible
- Display: "✓ Observability configured (Sentry + DataDog)"

Phase 10: Feature Flag Infrastructure
- Execute immediately: !{slashcommand /deployment:feature-flags-setup launchdarkly}
- After completion, setup LaunchDarkly SDK and environment config
- Execute immediately: !{slashcommand /deployment:verify-feature-flags}
- After completion, validate feature flag integration
- Display: "✓ Feature flags ready (LaunchDarkly)"

Phase 11: Automated Rollback Setup
- Execute immediately: !{slashcommand /deployment:rollback-automated --error-threshold=1% --window=5m}
- After completion, configure auto-rollback triggers
- Setup monitors for: error rate >1%, latency >2s, 5xx responses >5%
- Integrate with Sentry/DataDog alerts
- Display: "✓ Auto-rollback monitoring active"

Phase 12: Deployment History Tracking
- Execute immediately: !{slashcommand /versioning:record-deployment production $FRONTEND_URL}
- After completion, track deployment in version history
- Record: version → environment → URL → timestamp
- Create audit trail for rollback reference
- Display: "✓ Deployment recorded in version history"

Phase 13: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 5 | .phase5Complete = true | .deployed = true | .frontendUrl = "'$FRONTEND_URL'" | .backendUrl = "'$BACKEND_URL'" | .validationPassed = true | .observabilityEnabled = true | .featureFlagsEnabled = true | .autoRollbackEnabled = true | .performanceBaselinesCaptured = true | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display summary:
  ```
  ✅ Phase 5 Complete - Production Deployment with Observability

  Deployment:
  - Frontend: $FRONTEND_URL (Vercel)
  - Backend: $BACKEND_URL (Fly.io/Railway)
  - Validation: ✓ All health checks passed
  - Smoke Tests: ✓ Critical paths verified

  Production Infrastructure:
  - Performance Baselines: ✓ Lighthouse + API latency captured
  - Observability: ✓ Sentry (errors) + DataDog (APM)
  - Feature Flags: ✓ LaunchDarkly integrated
  - Auto-Rollback: ✓ Monitoring error rate >1%, latency >2s
  - Deployment History: ✓ Tracked in version registry

  Monitoring Dashboards:
  - Sentry: https://sentry.io/organizations/your-org/
  - DataDog: https://app.datadoghq.com/
  - LaunchDarkly: https://app.launchdarkly.com/

  Next: Run /ai-tech-stack-1:build-full-stack-phase-6 for versioning
  ```

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 5
