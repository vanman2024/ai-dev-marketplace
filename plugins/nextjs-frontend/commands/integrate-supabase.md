---
description: Integrate Supabase client, auth, and database into Next.js project
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, mcp__context7, mcp__supabase
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

Goal: Integrate Supabase authentication, database, and storage capabilities into an existing Next.js project with proper client configuration, middleware, and type safety.

Core Principles:
- Detect existing Next.js structure before making changes
- Ask user about required Supabase features to avoid unnecessary complexity
- Follow Next.js App Router or Pages Router conventions based on detection
- Ensure type safety with Supabase TypeScript types

Phase 1: Discovery
Goal: Understand the Next.js project structure and user requirements

Actions:
- Detect Next.js version and routing pattern:
  !{bash if [ -d "app" ]; then echo "App Router"; elif [ -d "pages" ]; then echo "Pages Router"; else echo "Unknown"; fi}
- Check if Supabase is already configured:
  !{bash ls .env.local supabase package.json 2>/dev/null | grep -E "(supabase|SUPABASE)" || echo "No existing Supabase"}
- Load existing package.json to understand dependencies:
  @package.json
- Check for existing TypeScript configuration:
  !{bash test -f tsconfig.json && echo "TypeScript" || echo "JavaScript"}

Phase 2: Requirements Gathering
Goal: Understand which Supabase features the user needs

Actions:
- Use AskUserQuestion to gather Supabase integration requirements:
  - Which Supabase features do you need? (auth, database, storage, realtime)
  - Do you have an existing Supabase project URL and anon key?
  - Which authentication providers? (email/password, OAuth, magic link)
  - Do you need Row Level Security (RLS) policies?
  - Should we generate TypeScript types from your database schema?
- Confirm detected Next.js routing pattern (App Router vs Pages Router)
- Ask about preferred authentication flow (server-side, client-side, or hybrid)

Phase 3: Planning
Goal: Design the integration approach based on findings

Actions:
- Outline integration steps based on:
  - Detected routing pattern (App Router vs Pages Router)
  - Requested features (auth, database, storage, realtime)
  - Authentication flow preference
- Identify files to create/modify:
  - .env.local (Supabase credentials)
  - lib/supabase/* (client configuration)
  - middleware.ts (auth middleware for App Router)
  - _app.tsx or layout.tsx (session provider)
  - types/supabase.ts (generated types)
- Present plan to user for confirmation

Phase 4: Integration
Goal: Execute Supabase integration with the supabase-integration-agent

Actions:

Task(description="Integrate Supabase into Next.js project", subagent_type="supabase-integration-agent", prompt="You are the supabase-integration-agent. Integrate Supabase into this Next.js project based on user requirements.

Project Context:
- Next.js routing: [App Router or Pages Router from detection]
- TypeScript: [Yes/No from detection]
- Existing dependencies: [from package.json]

User Requirements:
- Features: $ARGUMENTS or [features from AskUserQuestion]
- Auth providers: [from user response]
- Auth flow: [server-side/client-side/hybrid from user response]
- Type generation: [Yes/No from user response]

Integration Tasks:
1. Install Supabase dependencies (@supabase/supabase-js, @supabase/ssr for App Router)
2. Create environment configuration (.env.local with NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY)
3. Set up Supabase client utilities in lib/supabase/:
   - Client-side client (for client components)
   - Server-side client (for App Router server components/actions or API routes)
   - Middleware configuration (for auth protection)
4. Configure authentication:
   - Auth middleware (middleware.ts for App Router)
   - Session provider wrapper
   - Login/signup helpers
5. If database integration requested:
   - Generate TypeScript types from schema (if credentials provided)
   - Create database query examples
6. If storage integration requested:
   - Create storage upload/download utilities
7. If realtime integration requested:
   - Set up realtime subscription helpers
8. Follow existing code style and conventions
9. Add proper TypeScript types throughout

Expected Output:
- Installed dependencies listed
- Created/modified files with full paths
- Configuration instructions for .env.local
- Example usage code for each requested feature
- Next steps for database schema setup if needed")

Phase 5: Validation
Goal: Verify the integration is complete and functional

Actions:
- Check that all required dependencies were installed:
  !{bash grep -E "@supabase/(supabase-js|ssr|auth-helpers)" package.json || echo "Missing dependencies"}
- Verify Supabase client files exist:
  !{bash find lib -name "*supabase*" -type f 2>/dev/null || find src/lib -name "*supabase*" -type f 2>/dev/null || echo "Client files not found"}
- Check environment template was created:
  !{bash test -f .env.local && echo "Environment configured" || test -f .env.example && echo "Template created" || echo "No env file"}
- Verify TypeScript types if applicable:
  !{bash test -f types/supabase.ts && echo "Types generated" || echo "No types file"}
- Run type check if TypeScript project:
  !{bash if [ -f tsconfig.json ]; then npx tsc --noEmit 2>&1 | head -20; fi}

Phase 6: Summary
Goal: Provide clear next steps and configuration instructions

Actions:
- Summarize what was integrated:
  - Dependencies installed
  - Files created/modified
  - Features configured (auth, database, storage, realtime)
- Provide configuration instructions:
  - How to add Supabase URL and anon key to .env.local
  - How to generate TypeScript types: npx supabase gen types typescript
  - How to set up database migrations if needed
- Show example usage for each integrated feature
- Suggest next steps:
  - Set up Supabase project at https://supabase.com if not done
  - Configure authentication providers in Supabase dashboard
  - Create database tables and RLS policies
  - Test authentication flow
  - Generate and update TypeScript types from schema
