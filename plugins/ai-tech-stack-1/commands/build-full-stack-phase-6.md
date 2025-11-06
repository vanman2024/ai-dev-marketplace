---
description: "Phase 6: Versioning & Release - Breaking change detection, release notes, approval workflow, GitHub release"
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

Phase 3: Breaking Change Detection
- Execute immediately: !{slashcommand /versioning:analyze-breaking --detailed}
- After completion, analyze API contracts and database schemas
- Determine correct version bump (major for breaking, minor for features, patch for fixes)
- Display recommended version bump with reasoning
- Store breaking change report for migration guide

Phase 4: Version Bump
- Use recommended version from Phase 3
- Execute immediately: !{slashcommand /versioning:bump [major|minor|patch]}
- After completion, capture new version number
- Create git tag with version
- Update package.json/pyproject.toml

Phase 5: Generate Release Notes
- Execute immediately: !{slashcommand /versioning:generate-release-notes $VERSION}
- After completion, create AI-powered release notes with:
  * User-facing changelog (grouped by feature/fix/breaking)
  * Migration guide for breaking changes
  * Deprecation notices
  * Technical details
- Store in RELEASE-NOTES-$VERSION.md

Phase 6: Documentation Sync
- Execute immediately: !{slashcommand /iterate:sync}
- After completion, verify docs updated

Phase 7: Release Approval Workflow
- Execute immediately: !{slashcommand /versioning:approve-release $VERSION}
- After completion, coordinate multi-stakeholder approval:
  * Technical Lead approval (architecture review)
  * Product Owner approval (feature completeness)
  * QA approval (testing sign-off)
- Track approval status in GitHub Issues
- Send Slack notifications to stakeholders
- Wait for all approvals before publishing
- Display approval status and timeline

Phase 8: GitHub Release Publishing
- Once all approvals received:
- Create GitHub release with tag $VERSION
- Attach release notes (RELEASE-NOTES-$VERSION.md)
- Attach breaking change migration guide
- Mark as production release (not pre-release)
- Display: "✓ GitHub release published: https://github.com/org/repo/releases/tag/$VERSION"

Phase 9: Generate Summary
- Create DEPLOYMENT-COMPLETE.md with:
  - Production URLs
  - Stack components
  - Version information
  - Deployment validation results
  - Testing results
  - Breaking changes and migration guide
  - Release approval timeline
  - Environment variables
  - Next steps
- Display comprehensive summary

Phase 10: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 6 | .phase6Complete = true | .allPhasesComplete = true | .version = "'$VERSION'" | .breakingChangesAnalyzed = true | .releaseNotesGenerated = true | .approvalWorkflowComplete = true | .githubReleasePublished = true | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display final summary:
  ```
  🎉 All 6 Phases Complete - Production-Ready AI Application

  Version: $VERSION
  Release: https://github.com/org/repo/releases/tag/$VERSION

  Deployment:
  - Frontend: $FRONTEND_URL ✓
  - Backend: $BACKEND_URL ✓
  - All health checks passing ✓

  Versioning:
  - Breaking Changes: Analyzed with migration guide
  - Release Notes: AI-generated with technical details
  - Approval Workflow: All stakeholders approved
  - GitHub Release: Published with attachments

  Production Infrastructure:
  - Observability: Sentry + DataDog ✓
  - Feature Flags: LaunchDarkly ✓
  - Auto-Rollback: Active monitoring ✓
  - Performance: Baselines captured ✓

  Documentation:
  - DEPLOYMENT-COMPLETE.md ✓
  - RELEASE-NOTES-$VERSION.md ✓
  - Migration guides (if breaking changes) ✓
  - Spec sync complete ✓

  Next Steps:
  - Monitor dashboards (Sentry, DataDog, LaunchDarkly)
  - Review release approval timeline
  - Plan next iteration or hotfixes
  - Announce release to stakeholders
  ```

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 6
