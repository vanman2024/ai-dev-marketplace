---
description: Setup authentication for Vercel AI SDK applications using Clerk
argument-hint: none
allowed-tools: Task, Read, AskUserQuestion, Bash, Glob, Grep
---

**Arguments**: $ARGUMENTS

Goal: Integrate Clerk authentication with Vercel AI SDK applications to protect AI routes and provide user context.

Core Principles:
- Detect existing setup before making changes
- Protect all AI routes with authentication
- Provide user context to AI interactions
- Use placeholders for all API keys
- Follow Next.js App Router patterns

Phase 1: Discovery
Goal: Understand the current project setup and requirements

Actions:
- Check if project uses Vercel AI SDK and Clerk
- Load package.json to verify dependencies: @package.json
- Detect framework version: !{bash cat package.json | grep -E '"next"|"@clerk/nextjs"|"ai"' || echo "Dependencies not found"}
- Check for existing middleware: !{bash test -f middleware.ts && echo "Found" || echo "Not found"}
- Ask user about integration requirements if unclear:
  - Which AI provider are you using (OpenAI, Anthropic, other)?
  - Do you need role-based access for AI features?
  - Should AI conversations be stored per user?

Phase 2: Analysis
Goal: Assess current authentication and AI SDK configuration

Actions:
- Find all AI routes that need protection: !{bash find app/api -name "route.ts" 2>/dev/null | head -20 || echo "No routes found"}
- Search for existing AI SDK usage
- Check for Clerk provider setup
- Identify authentication gaps in AI endpoints
- Verify environment configuration

Phase 3: Planning
Goal: Design the authentication integration approach

Actions:
- Outline required changes:
  - Middleware configuration for AI route protection
  - Authentication helpers for route handlers
  - User context injection into AI calls
  - Error handling for unauthenticated requests
- Identify files to create or modify:
  - middleware.ts (route protection)
  - app/api/chat/route.ts (auth wrapper)
  - lib/auth.ts (helper utilities)
  - .env.example (Clerk key placeholders)
- Confirm approach with user before proceeding

Phase 4: Implementation
Goal: Execute Vercel AI SDK + Clerk integration

Actions:

Task(description="Integrate Clerk with Vercel AI SDK", subagent_type="clerk:clerk-vercel-ai-integrator", prompt="You are the clerk-vercel-ai-integrator agent. Integrate Clerk authentication with Vercel AI SDK for this project.

Context: This project uses Vercel AI SDK and needs Clerk authentication integration.

Requirements:
- Protect all AI routes (app/api/chat, etc.) with Clerk middleware
- Add auth() checks in AI route handlers
- Pass authenticated user context to AI providers
- Handle streaming responses with proper auth error handling
- Implement getAuthenticatedUserId() helper function
- Set up environment variables with placeholders only
- Add .env.local to .gitignore if not already present
- Create .env.example with clear Clerk key placeholders

Expected output:
- Updated middleware.ts protecting AI routes
- AI route handlers with authentication checks
- Helper utilities in lib/auth.ts
- Environment configuration with placeholders
- TypeScript compilation passing
- Complete integration ready for testing")

Phase 5: Review
Goal: Verify the integration works correctly

Actions:
- Check TypeScript compilation: !{bash npx tsc --noEmit 2>&1 | head -50 || echo "Type check complete"}
- Verify all AI routes are protected
- Confirm environment variables use placeholders only
- Check that .env.local is in .gitignore
- Validate error handling covers edge cases

Phase 6: Summary
Goal: Document what was accomplished

Actions:
- Summarize changes made:
  - Files created or modified
  - AI routes now protected
  - User context integration points
  - Environment setup completed
- Highlight next steps:
  - Add actual Clerk keys to .env.local
  - Test authentication flow with real users
  - Configure rate limiting if needed
  - Set up conversation history storage
- Provide setup instructions for Clerk Dashboard
