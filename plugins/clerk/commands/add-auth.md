---
description: Add authentication to pages/routes - configure sign-in/sign-up flows and protected routes
argument-hint: none
allowed-tools: Task, Read, AskUserQuestion, Bash, Glob
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

Goal: Add Clerk authentication flows and protected routes to the application

Core Principles:
- Detect framework before implementing
- Ask about authentication requirements upfront
- Use placeholders for all API keys
- Implement complete flows with error handling

Phase 1: Discovery
Goal: Understand project structure and authentication needs

Actions:
- Detect framework and project type
- Check for existing authentication setup
- Load package.json to understand dependencies
- Example: !{bash test -f package.json && cat package.json | grep -E "(next|react|remix)" || echo "No package.json found"}

Phase 2: Requirements Gathering
Goal: Clarify authentication requirements

Actions:
- If $ARGUMENTS does not specify requirements, use AskUserQuestion to gather:
  - Which authentication methods are needed? (email/password, social OAuth, phone, passwordless)
  - Which social providers? (Google, GitHub, Microsoft, etc.)
  - Do you need multi-factor authentication (MFA)?
  - Do you need organization/team features?
  - Which routes should be protected vs public?
- Summarize requirements and confirm with user

Phase 3: Framework Detection
Goal: Identify framework and structure

Actions:
- Read package.json to determine framework
- Check for Next.js App Router vs Pages Router
- Identify existing middleware or provider files
- Find where auth components should be placed
- Example: !{bash test -d app && echo "App Router" || test -d pages && echo "Pages Router" || echo "React"}

Phase 4: Implementation
Goal: Implement authentication with clerk-auth-builder agent

Actions:

Task(description="Implement Clerk authentication", subagent_type="clerk:clerk-auth-builder", prompt="You are the clerk-auth-builder agent. Implement Clerk authentication for this project.

Requirements from user: $ARGUMENTS

Framework detected: [framework from Phase 3]

Authentication methods needed:
- [Methods from Phase 2]

Social providers:
- [Providers from Phase 2]

Additional features:
- MFA: [Yes/No from Phase 2]
- Organizations: [Yes/No from Phase 2]

Protected routes: [Routes from Phase 2]

Deliverables:
1. Install required Clerk packages
2. Create/update environment files (.env.example with placeholders)
3. Set up ClerkProvider wrapper
4. Create authentication components (SignIn, SignUp, UserButton)
5. Configure middleware for route protection
6. Implement requested authentication methods
7. Add error handling and loading states
8. Generate TypeScript types if applicable
9. Document Clerk dashboard configuration steps")

Phase 5: Verification
Goal: Validate authentication implementation

Actions:
- Check that environment files use placeholders only
- Verify TypeScript compilation (if TypeScript project)
- Example: !{bash test -f tsconfig.json && npx tsc --noEmit || echo "Not a TypeScript project"}
- Confirm Clerk components were created
- Verify middleware file exists for route protection
- Check that .env.example exists with proper placeholders

Phase 6: Summary
Goal: Document what was implemented

Actions:
- List files created or modified
- Highlight authentication methods configured
- Show which routes are now protected
- Provide next steps:
  - Sign up for Clerk account at https://clerk.com
  - Create application in Clerk dashboard
  - Configure authentication providers
  - Copy publishable and secret keys
  - Update .env.local with real keys
  - Test authentication flows
