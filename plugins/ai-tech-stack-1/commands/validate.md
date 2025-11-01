---
description: Validate complete AI Tech Stack 1 deployment using lifecycle commands
argument-hint: [app-directory]
allowed-tools: SlashCommand, Read, Write, Bash(*), TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Validate AI Tech Stack 1 deployment using dev-lifecycle-marketplace commands.

Core Principles:
- Use lifecycle commands for comprehensive validation
- Detect project structure automatically
- Run full test suite
- Check security
- Validate deployment if deployed

Phase 1: Project Detection
Goal: Detect project structure and tech stack

Actions:
- Parse $ARGUMENTS for app directory (default: current directory)
- Verify exists: !{bash test -d "$ARGUMENTS" && echo "Found" || echo "Not found"}
- If not found: STOP
- Create todo list for validation
- Run project detection:
  SlashCommand: /foundation:detect $ARGUMENTS
- Wait for completion
- Load detected stack from .claude/project.json
- Verify it matches AI Tech Stack 1 components
- Mark detection complete

Phase 2: Comprehensive Testing
Goal: Run full test suite (API + E2E + Security)

Actions:
- Run Newman API tests:
  SlashCommand: /quality:test newman
- Wait for completion
- Display API test results
- Mark API tests complete

- Run Playwright E2E tests:
  SlashCommand: /quality:test playwright
- Wait for completion
- Display E2E test results
- Mark E2E tests complete

- Run security scans:
  SlashCommand: /quality:security
- Wait for completion
- Display security scan results
- Mark security complete

Phase 3: Deployment Validation (If Deployed)
Goal: Validate deployment health if app is deployed

Actions:
- Check if deployed: !{bash test -f .ai-stack-config.json && jq -e '.deployed == true' .ai-stack-config.json}
- If deployed:
  - Load URLs from .ai-stack-config.json
  - Validate frontend:
    SlashCommand: /deployment:validate $FRONTEND_URL
  - Wait for completion
  - Validate backend:
    SlashCommand: /deployment:validate $BACKEND_URL
  - Wait for completion
  - Display deployment health results
  - Mark deployment validation complete
- If not deployed:
  - Skip deployment validation
  - Note: "App not deployed yet"

Phase 4: Summary
Goal: Report comprehensive validation results

Actions:
- Mark all todos complete

- Display validation summary:
  ✅ AI Tech Stack 1 Validation Report

  Project Detection: [STATUS]
  - Tech stack matches AI Tech Stack 1

  Testing:
  - Newman API Tests: [STATUS]
  - Playwright E2E Tests: [STATUS]
  - Security Scans: [STATUS]

  Deployment: [STATUS / Not deployed]
  - Frontend Health: [STATUS]
  - Backend Health: [STATUS]

  Overall: [PASSED / FAILED / WARNINGS]

- Status:
  - All passed: "✅ Validation PASSED"
  - Warnings: "⚠️  Passed with warnings"
  - Failed: "❌ Validation FAILED - Fix issues before deployment"

## Usage

Validate current directory:
/ai-tech-stack-1:validate

Validate specific app:
/ai-tech-stack-1:validate my-ai-app
