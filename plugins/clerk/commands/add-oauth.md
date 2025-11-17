---
description: Configure OAuth providers - setup redirect URLs and test OAuth flows
argument-hint: [provider-names]
allowed-tools: Task, AskUserQuestion, Read, Write, Bash, Glob, Grep
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

Goal: Configure OAuth authentication providers in Clerk with redirect URLs and test flows

Core Principles:
- Ask for provider selection if not specified
- Detect existing Clerk configuration
- Configure providers with proper redirect URLs
- Test OAuth flows after setup

Phase 1: Discovery
Goal: Gather provider requirements and detect project setup

Actions:
- Parse $ARGUMENTS for provider names (e.g., "google github microsoft")
- If no providers specified, use AskUserQuestion to gather:
  - Which OAuth providers to configure? (Google, GitHub, Microsoft, etc.)
  - What environments? (development, production)
  - Any custom redirect URLs needed?
- Detect project type and framework:
  - !{bash ls package.json next.config.js app/ pages/ 2>/dev/null}
- Load existing Clerk configuration if present:
  - @.env.local
  - @middleware.ts or @middleware.js
  - @app/layout.tsx or @pages/_app.tsx

Phase 2: Context Analysis
Goal: Understand current authentication setup

Actions:
- Read Clerk environment configuration
- Identify configured authentication methods
- Check for existing OAuth provider setup
- Detect application routes and redirect patterns
- Example: !{bash grep -r "ClerkProvider\|SignIn\|SignUp" app/ pages/ src/ 2>/dev/null | head -20}

Phase 3: Planning
Goal: Design OAuth provider configuration approach

Actions:
- List providers to configure based on $ARGUMENTS or user input
- Determine redirect URLs based on detected framework:
  - Next.js App Router: /api/auth/callback
  - Next.js Pages Router: /api/auth/callback
  - Standard React: /auth/callback
- Plan environment variable updates
- Identify Clerk Dashboard configuration steps
- Present configuration plan to user

Phase 4: Implementation
Goal: Configure OAuth providers with Clerk specialist

Actions:

Task(description="Configure OAuth providers", subagent_type="clerk:clerk-oauth-specialist", prompt="You are the clerk-oauth-specialist agent. Configure OAuth authentication providers for this application.

Providers to configure: $ARGUMENTS (or from user input)

Context from detection:
- Project framework and structure
- Existing Clerk configuration
- Current authentication setup
- Application routes

Requirements:
- Configure each provider in Clerk Dashboard (provide step-by-step)
- Set up redirect URLs based on detected framework
- Update environment variables with provider credentials
- Configure OAuth scopes appropriately
- Add provider buttons to sign-in/sign-up components
- Test OAuth flow for each provider

Expected output:
- Environment variable updates (.env.local with placeholders)
- Component code changes for provider buttons
- Clerk Dashboard configuration steps
- Redirect URL configuration
- Testing instructions for each provider
- Security best practices checklist")

Phase 5: Verification
Goal: Validate OAuth provider configuration

Actions:
- Review generated environment variables (ensure placeholders used)
- Check that .env.local is in .gitignore
- Verify component updates follow framework patterns
- Confirm redirect URLs match detected framework
- Example: !{bash grep "CLERK_" .env.local 2>/dev/null}

Phase 6: Summary
Goal: Document OAuth provider setup completion

Actions:
- List configured providers
- Display environment variables to set (with placeholders)
- Show Clerk Dashboard configuration steps
- Provide testing instructions
- Next steps:
  - Add actual OAuth credentials from provider consoles
  - Test each OAuth flow in development
  - Configure production redirect URLs
  - Review OAuth scopes and permissions
