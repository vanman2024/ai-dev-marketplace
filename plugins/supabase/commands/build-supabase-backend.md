---
description: Build complete Supabase backend - initializes project if needed, then runs all specialized agents in parallel for schema design, auth, realtime, security, and deployment
argument-hint: <project-name> [--from-spec <spec-path>]
---

# Build Complete Supabase Backend

**Goal:** Create a production-ready Supabase backend by orchestrating all specialized agents in parallel.

**This command handles everything** - from project initialization to full implementation with auth, RLS, realtime, and AI features.

## Stack (Always Use Latest Versions)

- **Supabase** - Latest with Auth, Database, Realtime, Storage, Edge Functions
- **PostgreSQL** - Latest with pgvector extension
- **PostgREST** - Latest for auto-generated APIs
- **GoTrue** - Latest for auth
- **Realtime** - Latest for websocket subscriptions

**IMPORTANT:** Always check for and use the most recent stable versions. Use Supabase CLI `supabase --version` and check docs for current features.

## Arguments

- `$ARGUMENTS` - Project name and optional spec path
- `--from-spec <path>` - Build from architecture specification

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and spec path
2. Check if Supabase project exists or needs creation
3. Discover architecture documentation:
   ```
   !{glob docs/architecture/**/*.md}
   !{glob specs/*/spec.md}
   ```
4. Create execution plan based on what's found

### Phase 2: Project Initialization (if needed)

**If no project exists, run setup:**

```
Task("Initialize Supabase project", @supabase-project-manager, {
  prompt: "Initialize Supabase project named '$PROJECT_NAME':
    - Run supabase init
    - Configure local development
    - Set up environment variables
    - Link to Supabase cloud project if credentials exist
    Create proper project structure."
})
```

**Wait for setup to complete before proceeding.**

### Phase 3: Parallel Agent Execution

**Launch ALL specialized agents simultaneously using Task():**

```
// Agent 1: Schema Architecture
Task("Design database schema", @supabase-architect, {
  prompt: "Design complete database schema from architecture docs:
    - Create optimal table structures
    - Define relationships and foreign keys
    - Add proper indexes for performance
    - Include timestamps, soft deletes, audit fields
    Generate migration files in supabase/migrations/."
})

// Agent 2: Security Implementation
Task("Implement security layer", @supabase-security-specialist, {
  prompt: "Implement complete security:
    - Row Level Security (RLS) policies for all tables
    - Auth configuration (OAuth providers if specified)
    - Role-based access control
    - API security policies
    Follow architecture docs for permission requirements."
})

// Agent 3: AI Features (if needed)
Task("Setup AI features", @supabase-ai-specialist, {
  prompt: "Implement AI/vector features if specified in architecture:
    - Enable pgvector extension
    - Create embedding tables with proper dimensions
    - Implement similarity search functions
    - Add Edge Functions for AI processing
    Skip if no AI features in architecture docs."
})

// Agent 4: Realtime Features (if needed)  
Task("Setup realtime features", @supabase-realtime-builder, {
  prompt: "Implement realtime features if specified in architecture:
    - Enable realtime for required tables
    - Configure presence channels
    - Set up broadcast messaging
    - Create subscription patterns
    Skip if no realtime features in architecture docs."
})

// Agent 5: UI Components
Task("Generate UI integration", @supabase-ui-generator, {
  prompt: "Generate client integration code:
    - TypeScript types from schema
    - React hooks for auth
    - Realtime subscription hooks
    - Storage upload components
    Output to src/lib/supabase/."
})
```

### Phase 4: Validation & Security Audit

**After parallel execution completes:**

```
// Validate schema
Task("Validate schema", @supabase-schema-validator, {
  prompt: "Validate all migrations and schema:
    - Check SQL syntax
    - Verify naming conventions
    - Validate constraints and indexes
    - Check RLS policy coverage
    Report any issues."
})

// Security audit
Task("Audit security", @supabase-security-auditor, {
  prompt: "Perform security audit:
    - Verify all tables have RLS enabled
    - Check for policy gaps
    - Validate auth configuration
    - Test permission boundaries
    Report vulnerabilities."
})
```

### Phase 5: Final Output

**Provide summary:**
- List all migrations created
- Show RLS policies implemented
- Provide deployment commands:
  ```bash
  # Local development
  supabase start
  
  # Deploy migrations
  supabase db push
  
  # Generate types
  supabase gen types typescript --local > src/types/supabase.ts
  ```
- Note any manual steps needed

## Utility Commands

For individual tasks, use these commands instead:
- `/supabase:create-schema` - Create database schema only
- `/supabase:add-auth` - Add authentication configuration
- `/supabase:add-rls` - Add Row Level Security policies
- `/supabase:add-realtime` - Enable realtime features
- `/supabase:add-storage` - Configure storage buckets
- `/supabase:setup-pgvector` - Enable AI/vector features
- `/supabase:deploy-migration` - Deploy migrations to cloud
- `/supabase:generate-types` - Generate TypeScript types
