---
description: Integrate Clerk with Supabase - user sync, RLS policies, webhook handlers
argument-hint: none
allowed-tools: Task, Read, AskUserQuestion, Bash, Glob, Grep
---

**Arguments**: $ARGUMENTS

Goal: Integrate Clerk authentication with Supabase database for seamless user management, row-level security, and real-time synchronization.

Core Principles:
- Ask about sync strategy before implementing
- Understand project context (Supabase setup, table structure)
- Follow Clerk-Supabase integration best practices
- Implement secure webhook handling
- Configure proper RLS policies

## Security: API Key Handling

**CRITICAL:** When generating configuration files or code:

❌ NEVER hardcode actual API keys or secrets
❌ NEVER include real credentials in examples
❌ NEVER commit sensitive values to git

✅ ALWAYS use placeholders: `your_clerk_key_here`, `your_supabase_key_here`
✅ ALWAYS create `.env.example` with placeholders only
✅ ALWAYS add `.env*` to `.gitignore` (except `.env.example`)
✅ ALWAYS read from environment variables in code
✅ ALWAYS document where to obtain keys

**Placeholder format:** `clerk_{env}_your_key_here`, `supabase_{env}_your_key_here`

Phase 1: Discovery
Goal: Understand current setup and integration requirements

Actions:
- Parse $ARGUMENTS for any specific requirements
- Detect if Supabase is already configured
- Check for existing Clerk setup
- Example: !{bash test -f .env && grep -q "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" .env && echo "Clerk configured" || echo "Clerk not found"}
- Example: !{bash test -f .env && grep -q "NEXT_PUBLIC_SUPABASE_URL" .env && echo "Supabase configured" || echo "Supabase not found"}

Phase 2: Requirements Gathering
Goal: Ask user about sync strategy and integration preferences

Actions:

Use AskUserQuestion to gather:
- What sync strategy do you want?
  - Real-time sync via webhooks (recommended)
  - On-demand sync on login
  - Manual sync
- What user data should be synced?
  - Basic profile (email, name)
  - Full profile with metadata
  - Custom user fields
- Do you need RLS policies?
  - Yes, secure user data per-user
  - Yes, with team/org isolation
  - No, public access

Phase 3: Project Analysis
Goal: Understand existing Supabase schema and tables

Actions:
- List Supabase migration files to understand schema
- Example: !{bash ls -la supabase/migrations/*.sql 2>/dev/null | head -10}
- Read package.json to detect framework
- Example: @package.json
- Check if user table already exists
- Identify which tables need RLS policies

Phase 4: Implementation
Goal: Integrate Clerk with Supabase via agent

Actions:

Task(description="Integrate Clerk with Supabase", subagent_type="clerk:clerk-supabase-integrator", prompt="You are the clerk-supabase-integrator agent. Integrate Clerk authentication with Supabase for this project.

Context:
- Sync strategy: [From Phase 2 answers]
- User data scope: [From Phase 2 answers]
- RLS requirements: [From Phase 2 answers]
- Existing setup: [From Phase 1 detection]

Requirements:
- Create/update user table in Supabase with Clerk user_id
- Implement sync mechanism based on chosen strategy
- Set up webhook handlers if real-time sync selected
- Configure RLS policies if requested
- Create helper functions for user operations
- Update environment variables with placeholders
- Generate comprehensive setup documentation

Expected output:
- SQL migration files for user table and RLS
- Webhook handler implementation (if applicable)
- Environment configuration with placeholders
- Setup instructions and testing guide")

Phase 5: Verification
Goal: Verify integration is properly configured

Actions:
- Check that migration files were created
- Example: !{bash ls -la supabase/migrations/*.sql | tail -5}
- Verify environment variables are documented
- Confirm RLS policies are in place
- Check webhook endpoint is implemented (if applicable)

Phase 6: Summary
Goal: Document what was accomplished and next steps

Actions:
- Summarize integration components created:
  - User table schema and migrations
  - Sync mechanism (webhooks/on-demand)
  - RLS policies configured
  - Helper functions and utilities
- Display next steps:
  - Apply Supabase migrations: `supabase db push`
  - Configure webhook endpoint in Clerk Dashboard
  - Test user sync flow
  - Verify RLS policies work correctly
- Highlight important files:
  - Migration files location
  - Webhook handler location
  - Environment variables to configure
  - Setup documentation
