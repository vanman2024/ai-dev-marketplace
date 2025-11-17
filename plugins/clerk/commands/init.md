---
description: Initialize Clerk authentication in existing project - install SDK, configure environment, setup provider
argument-hint: none
allowed-tools: Task, Read, AskUserQuestion, Bash
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

## Security: API Key Handling

**CRITICAL:** Read comprehensive security rules:

@docs/security/SECURITY-RULES.md

**Never hardcode API keys, passwords, or secrets in any generated files.**

When generating configuration or code:
- ❌ NEVER use real API keys or credentials
- ✅ ALWAYS use placeholders: `your_clerk_key_here`
- ✅ Format: `clerk_{env}_your_key_here` for multi-environment
- ✅ Read from environment variables in code
- ✅ Add `.env*` to `.gitignore` (except `.env.example`)
- ✅ Document how to obtain real keys from Clerk Dashboard

Goal: Initialize Clerk authentication in an existing project with complete SDK installation, environment configuration, and provider setup using placeholder credentials.

Core Principles:
- Detect framework before installation (Next.js, React, Node.js)
- Ask user for provider preferences early
- Delegate complete setup to specialized agent
- Verify installation and environment security

Phase 1: Framework Detection
Goal: Identify project framework and existing configuration

Actions:
- Check if package.json exists to determine project type
- Example: !{bash test -f package.json && echo "Node.js project detected" || echo "No package.json found"}
- Read package.json to detect framework:
  - Next.js (has "next" dependency)
  - React (has "react" without "next")
  - Node.js backend (has "express" or neither)
- Check if Clerk is already installed
- Example: !{bash grep -q "@clerk" package.json 2>/dev/null && echo "Clerk found" || echo "Clerk not installed"}

Phase 2: Gather Requirements
Goal: Understand user's authentication needs and preferences

Actions:
- If framework is unclear or unsupported, use AskUserQuestion to confirm:
  - What framework/stack are you using?
  - Is this Next.js App Router, Pages Router, React SPA, or Node.js?
- Ask about authentication provider preferences:
  - Which providers do you want? (Google, GitHub, Email, etc.)
  - Do you need middleware for protected routes?
  - Do you need custom sign-in/sign-up pages?
- Confirm environment setup approach:
  - Development mode (test keys) or production mode?
  - Multi-environment setup needed?

Phase 3: Setup Execution
Goal: Initialize Clerk with complete SDK installation and configuration

Actions:

Task(description="Initialize Clerk authentication", subagent_type="clerk:clerk-setup-agent", prompt="You are the clerk-setup-agent. Initialize Clerk authentication in this project.

Framework detected: [Framework from Phase 1]
User preferences from Phase 2:
- Authentication providers: [List from Phase 2]
- Middleware needed: [Yes/No from Phase 2]
- Custom auth pages: [Yes/No from Phase 2]
- Environment mode: [Development/Production from Phase 2]

Requirements:
- Install correct Clerk package based on framework
- Generate .env.local with placeholder keys (NEVER use real keys)
- Generate .env.example with same structure
- Configure ClerkProvider in root component
- Add middleware if requested (Next.js only)
- Update .gitignore to exclude .env files (except .env.example)
- Document how to obtain real Clerk keys from dashboard

Expected deliverables:
1. Installed Clerk SDK package
2. .env.local with placeholder values only
3. .env.example with documentation
4. ClerkProvider configuration
5. Middleware setup (if applicable)
6. Setup documentation explaining key acquisition
7. Verification that no real keys are hardcoded

Security requirement: ALL environment files must use placeholders in format 'clerk_{env}_your_key_here'. NEVER hardcode actual API keys.")

Phase 4: Verification
Goal: Confirm successful installation and security compliance

Actions:
- Verify Clerk package appears in package.json dependencies
- Example: !{bash grep "@clerk" package.json}
- Check .env.local exists with placeholder keys
- Verify .env.example is created
- Confirm .gitignore excludes .env files
- Example: !{bash grep -q ".env*" .gitignore && echo "Protected" || echo "WARNING: .gitignore missing .env protection"}
- Validate no real API keys are present in any files
- Run TypeScript check if applicable
- Example: !{bash command -v tsc &>/dev/null && npx tsc --noEmit || echo "TypeScript not available"}

Phase 5: Summary
Goal: Document setup completion and next steps

Actions:
- Summarize what was installed:
  - Clerk package version
  - Environment files created
  - Provider configuration location
  - Middleware setup (if added)
- Highlight critical next steps:
  - Get Clerk keys from https://dashboard.clerk.com
  - Add real keys to .env.local (NEVER commit this file)
  - Configure authentication providers in Clerk Dashboard
  - Test sign-in/sign-up flows
- Provide quick start commands:
  - npm run dev (or appropriate dev command)
  - Navigate to /sign-in to test authentication
- Security reminder:
  - NEVER commit .env.local to git
  - ONLY commit .env.example with placeholders
  - Keep Clerk secret keys secure and private
