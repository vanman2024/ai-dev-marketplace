---
description: Enable multi-tenant organizations with RBAC and organization switching
argument-hint: none
allowed-tools: Task, AskUserQuestion, Read, Bash, Glob
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---


**Arguments**: $ARGUMENTS

Goal: Enable Clerk Organizations with role-based access control (RBAC) and organization switching for multi-tenant applications.

Core Principles:
- Ask about RBAC requirements before implementation
- Detect existing project structure
- Follow Clerk best practices for organizations
- Provide complete organization management

Phase 1: Discovery
Goal: Understand project structure and organization requirements

Actions:
- Detect project framework and structure
- Check for existing Clerk setup
- Example: !{bash ls -la app/ src/ pages/ 2>/dev/null | head -20}
- Verify Clerk is already configured
- Example: !{bash grep -r "ClerkProvider" . --include="*.tsx" --include="*.ts" 2>/dev/null | head -5}

Phase 2: Requirements Gathering
Goal: Understand RBAC and organization needs

Actions:

Use AskUserQuestion to gather:

1. **RBAC Requirements**:
   - What roles do you need? (e.g., admin, member, billing)
   - What permissions per role? (e.g., admin can invite, member read-only)
   - Any custom permissions beyond standard roles?

2. **Organization Features**:
   - Enable organization switching UI?
   - Enable member invitation flows?
   - Enable role management UI?
   - Enable organization settings page?

3. **Integration Points**:
   - Database backend? (Supabase, Prisma, Drizzle)
   - API routes need organization context?
   - Any organization-specific data models?

Phase 3: Validation
Goal: Verify Clerk setup exists

Actions:
- Read Clerk configuration files
- Verify environment variables are set
- Example: !{bash grep "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" .env.local .env 2>/dev/null}
- Check middleware configuration
- Example: @middleware.ts

Phase 4: Implementation
Goal: Enable organizations with RBAC

Actions:

Task(description="Enable Clerk organizations with RBAC", subagent_type="clerk:clerk-organization-builder", prompt="You are the clerk-organization-builder agent. Enable Clerk Organizations with RBAC for this project based on the requirements gathered.

Requirements from user:
- Roles: [roles specified]
- Permissions: [permissions specified]
- Features: [features requested]
- Database: [database backend if specified]
- API integration: [if needed]

Project context:
- Framework: [detected framework]
- Existing Clerk setup: [configuration found]

Implementation scope:
1. Enable organizations in Clerk dashboard settings
2. Update ClerkProvider with organization props
3. Create organization UI components:
   - Organization switcher
   - Member management (if requested)
   - Role assignment UI (if requested)
   - Organization settings (if requested)
4. Add organization middleware and guards
5. Implement RBAC helpers and hooks
6. Add API route protection with org context
7. Database integration (if specified)
8. Add example organization flows

Expected output:
- Complete organization implementation
- RBAC utilities and hooks
- UI components for org management
- Documentation for organization features
- Example usage in key areas")

Phase 5: Verification
Goal: Verify organization setup

Actions:
- Check that organization components exist
- Example: !{bash ls -la components/organizations/ app/organizations/ 2>/dev/null}
- Verify RBAC utilities are present
- Example: !{bash grep -r "useOrganization\|useRole" . --include="*.tsx" --include="*.ts" 2>/dev/null | head -5}
- Run type checking if TypeScript
- Example: !{bash npm run typecheck 2>/dev/null || npx tsc --noEmit 2>/dev/null || echo "No TypeScript check available"}

Phase 6: Summary
Goal: Document organization setup

Actions:
- Summarize changes made:
  - Organization components created
  - RBAC implementation details
  - Roles and permissions configured
  - Database integration (if added)
- Next steps:
  - Configure organization settings in Clerk dashboard
  - Test organization creation flow
  - Test role assignment and permissions
  - Set up production organization domains (if needed)
- Documentation references:
  - Clerk Organizations: https://clerk.com/docs/organizations/overview
  - RBAC Guide: https://clerk.com/docs/organizations/roles-permissions
