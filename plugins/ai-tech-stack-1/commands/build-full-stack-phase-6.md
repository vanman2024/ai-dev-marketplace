---
description: "Phase 6: Versioning & Final Summary - Version bump, changelog, complete documentation"
argument-hint: none
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*), Skill
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

Goal: Generate version, changelog, and final summary.

Phase 1: Load State
- Load .ai-stack-config.json
- Verify phase5Complete is true
- Verify deployed is true
- If deployment failed: STOP with error
- Extract appName, URLs
- Create Phase 6 todo list

Phase 2: Final Spec Report
- Execute immediately: !{slashcommand /planning:analyze-project}
- After completion, export spec coverage metrics

Phase 3: Version Bump
- Execute immediately: !{slashcommand /versioning:bump patch}
- After completion, capture new version number

Phase 4: Documentation Sync
- Execute immediately: !{slashcommand /iterate:sync}
- After completion, verify docs updated

Phase 5: Generate Summary
- Create DEPLOYMENT-COMPLETE.md with:
  - Production URLs
  - Stack components
  - Deployment validation results
  - Testing results
  - Environment variables
  - Next steps
- Display summary

Phase 6: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 6 | .phase6Complete = true | .allPhasesComplete = true | .version = "'$VERSION'" | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display: "🎉 All 6 Phases Complete - AI application live!"

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 6
