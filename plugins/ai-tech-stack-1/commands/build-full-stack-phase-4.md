---
description: "Phase 4: Testing & Quality Assurance - Newman API tests, Playwright E2E, security scans"
argument-hint: none
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*), Skill
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

Goal: Run comprehensive testing before deployment.

Phase 1: Load State
- Load .ai-stack-config.json
- Verify phase3Complete is true
- Extract appName, paths
- Create Phase 4 todo list

Phase 2: Newman API Testing
- Execute immediately: !{slashcommand /quality:test newman}
- After completion, parse test results
- If failures: STOP and return error

Phase 3: Playwright E2E Testing
- Execute immediately: !{slashcommand /quality:test playwright}
- After completion, parse test results
- If failures: STOP and return error

Phase 4: Security Scans
- Execute immediately: !{slashcommand /quality:security}
- After completion, parse security report
- If critical issues: STOP and return error

Phase 5: Task Sync
- Execute immediately: !{slashcommand /iterate:sync test-results}
- After completion, mark test tracking complete

Phase 6: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 4 | .phase4Complete = true | .testsPassedNewman = true | .testsPassedPlaywright = true | .securityPassed = true | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display: "✅ Phase 4 Complete - All tests passed"

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 4
