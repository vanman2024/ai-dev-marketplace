---
description: Build complete Supabase backend for new or existing projects with database, auth, realtime, and storage
argument-hint: [project-name] [--existing]
---

# Build Supabase Backend

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(supabase-architect) Analyze project for Supabase setup.

Detect: Framework (Next.js, React, etc.), existing database
Check: Auth requirements, data schema needs
Output: Supabase strategy
```

---

## Phase 2: Project Setup

**Goal:** Set up Supabase project

**Actions:**

```
Task(supabase-project-manager) Set up Supabase project.

Requirements:
- Create/connect Supabase project
- Configure environment variables
- Set up client (server/browser)
- Configure TypeScript types
- Test connection
```

---

## Phase 3: Database Schema

**Goal:** Create database schema

**Actions:**

```
Task(supabase-database-executor) Set up database.

Requirements:
- Design schema
- Create tables
- Set up relationships
- Add indexes
- Configure RLS policies
```

---

## Phase 4: Authentication

**Goal:** Set up authentication

**Actions:**

```
Task(supabase-auth-pages-builder) Configure authentication.

Requirements:
- Set up auth providers
- Create auth pages (login, signup)
- Configure session handling
- Add protected routes
- Set up middleware
```

---

## Phase 5: Row Level Security

**Goal:** Configure RLS policies

**Actions:**

```
Task(supabase-security-specialist) Set up RLS.

Requirements:
- Design access patterns
- Create RLS policies
- Test policy enforcement
- Add helper functions
```

---

## Phase 6: Realtime

**Goal:** Add realtime features

**Actions:**

```
Task(supabase-realtime-builder) Configure realtime.

Requirements:
- Set up subscriptions
- Configure broadcast
- Add presence features
- Create realtime hooks
```

---

## Phase 7: Validation & Testing

**Goal:** Validate setup

**Actions:**

```
Task(supabase-validator) Validate Supabase setup.

Requirements:
- Test database operations
- Verify auth flows
- Check RLS policies
- Test realtime
```

---

## Summary

**Output:**

```
✅ Supabase Backend Complete

To add features:
  /supabase:add table <name>           # Database table
  /supabase:add auth <provider>        # Auth provider
  /supabase:add rls <table>            # RLS policy
  /supabase:add realtime <feature>     # Realtime feature
  /supabase:add storage                # File storage
  /supabase:add ai                     # AI/Embeddings

To run:
  npx supabase start (local)
```
