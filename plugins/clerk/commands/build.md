---
description: Build complete Clerk authentication for new or existing projects with SSO, MFA, organizations, and user management
argument-hint: [project-name] [--existing]
---

# Build Clerk Authentication

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(clerk-framework-detector) Analyze project for Clerk integration.

Detect: Next.js (App/Pages Router), React, Express, etc.
Check: Existing auth, database setup
Output: Integration strategy
```

---

## Phase 2: Core Setup

**Goal:** Set up Clerk infrastructure

**Actions:**

```
Task(clerk-setup-agent) Set up Clerk authentication.

Requirements:
- Install @clerk/nextjs or appropriate SDK
- Configure environment variables
- Set up ClerkProvider
- Create middleware for protected routes
- Add sign-in/sign-up pages
```

---

## Phase 3: Framework Integration

**Goal:** Integrate with specific framework

**Actions:**

**If Next.js App Router:**

```
Task(clerk-nextjs-app-router-agent) Integrate with Next.js App Router.
```

**If Next.js Pages Router:**

```
Task(clerk-nextjs-pages-router-agent) Integrate with Next.js Pages Router.
```

---

## Phase 4: Auth UI

**Goal:** Add authentication UI

**Actions:**

```
Task(clerk-ui-customizer) Set up authentication UI.

Requirements:
- Create sign-in page
- Create sign-up page
- Add user profile component
- Configure appearance theme
- Add loading states
```

---

## Phase 5: API Protection

**Goal:** Protect API routes

**Actions:**

```
Task(clerk-auth-builder) Set up API authentication.

Requirements:
- Configure middleware
- Add route protection
- Set up getAuth() helpers
- Implement role-based access
```

---

## Phase 6: Verification

**Goal:** Validate setup

**Actions:**

```
Task(clerk-validator) Verify Clerk integration.

Requirements:
- Test sign-in flow
- Verify protected routes
- Check API authentication
- Validate webhook setup
```

---

## Summary

**Output:**

```
✅ Clerk Authentication Complete

To add features:
  /clerk:add mfa               # Multi-factor auth
  /clerk:add oauth <provider>  # OAuth providers
  /clerk:add organizations     # Multi-tenant orgs
  /clerk:add webhooks          # User sync webhooks
  /clerk:add billing           # Stripe billing

To run:
  npm run dev
```
