---
description: "Phase 4: Testing & Quality Assurance - Newman API tests, Playwright E2E, security scans"
argument-hint: none
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*)
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

Goal: Run comprehensive testing and quality assurance BEFORE deployment - API tests, E2E tests, security scans.

Core Principles:
- Test EVERYTHING before deploying
- Use dev-lifecycle-marketplace quality commands
- Block deployment if tests fail
- Generate comprehensive test reports

Phase 1: Load State
Goal: Read Phase 3 config

Actions:
- Check .ai-stack-config.json exists
- Load config: @.ai-stack-config.json
- Verify phase3Complete is true
- Extract appName, frontend path, backend path
- Create Phase 4 todo list

Phase 2: Newman API Testing
Goal: Test all backend API endpoints

Actions:
- Update .ai-stack-config.json phase to 4
- Run Newman API tests on backend:
  Execute immediately: !{slashcommand /quality:test newman}
- This tests:
  - All REST API endpoints
  - Authentication flows
  - Database operations
  - Error handling
  - Response formats
- Parse test results
- If failures detected:
  - Display failing tests
  - STOP and return error
  - User must fix before continuing
- If all pass:
  - Display test summary
  - Mark Newman complete
- Time: ~10 minutes

Phase 3: Playwright E2E Testing
Goal: Test full application workflows

Actions:
- Run Playwright E2E tests on frontend:
  Execute immediately: !{slashcommand /quality:test playwright}
- This tests:
  - Page navigation
  - UI component interactions
  - Chat functionality
  - Authentication flows
  - Frontend ↔ Backend integration
  - Memory persistence (if Mem0 enabled)
- Parse test results
- If failures detected:
  - Display failing tests
  - Take screenshots of failures
  - STOP and return error
- If all pass:
  - Display test summary
  - Mark Playwright complete
- Time: ~15 minutes

Phase 4: Security Vulnerability Scanning
Goal: Scan for security issues

Actions:
- Run security scans:
  Execute immediately: !{slashcommand /quality:security}
- This scans for:
  - Dependency vulnerabilities (npm audit, pip check)
  - Exposed secrets in code
  - SQL injection vulnerabilities
  - XSS vulnerabilities
  - Insecure authentication
  - Missing security headers
- Parse security report
- If critical issues found:
  - Display critical vulnerabilities
  - STOP and return error
- If warnings only:
  - Display warnings
  - Allow user to proceed or fix
- If all clear:
  - Display security summary
  - Mark security complete
- Time: ~5 minutes

Phase 5: Summary Phase 4
Goal: Save state and prepare for Phase 5 (Deployment)

Actions:
- Update .ai-stack-config.json:
  - phase4Complete: true
  - phase: 4
  - testsPassedNewman: true/false
  - testsPassedPlaywright: true/false
  - securityPassed: true/false
  - timestamp: current time
  - nextPhase: "Phase 5 - Production Deployment"

- If ALL tests passed:
  - Display success summary:
    ✅ Phase 4 Complete: Testing & Quality Assurance

    Newman API Tests: ✅ PASSED
    Playwright E2E Tests: ✅ PASSED
    Security Scans: ✅ PASSED

    Ready for Phase 5: Production Deployment
    Run: /ai-tech-stack-1:build-full-stack-phase-5

    Time: ~30 minutes

- If ANY tests failed:
  - Display failure summary:
    ❌ Phase 4 FAILED: Testing & Quality Assurance

    Newman API Tests: [STATUS]
    Playwright E2E Tests: [STATUS]
    Security Scans: [STATUS]

    Fix failing tests before deployment!
    Re-run: /ai-tech-stack-1:build-full-stack-phase-4

  - STOP execution
  - DO NOT proceed to Phase 5

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 4
