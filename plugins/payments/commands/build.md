---
description: Build complete payment system with Stripe for new or existing projects with subscriptions, webhooks, and billing management
argument-hint: [project-name] [--existing]
---

# Build Payment System

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(payments-architect) Analyze project for payments setup.

Detect: Framework (Next.js, FastAPI), existing auth
Check: Database, user management
Output: Payments strategy
```

---

## Phase 2: Stripe Setup

**Goal:** Set up Stripe integration

**Actions:**

```
Task(stripe-integration-agent) Set up Stripe core.

Requirements:
- Configure API keys (test/live)
- Set up Stripe client
- Configure products/prices
- Create checkout flow
- Add customer management
```

---

## Phase 3: Subscription Management

**Goal:** Add subscription features

**Actions:**

```
Task(subscription-manager-agent) Set up subscriptions.

Requirements:
- Create subscription plans
- Set up billing portal
- Add plan switching
- Configure trials
- Handle cancellations
```

---

## Phase 4: Webhooks

**Goal:** Set up webhook handling

**Actions:**

```
Task(webhook-handler-agent) Configure webhooks.

Requirements:
- Create webhook endpoint
- Verify webhook signatures
- Handle subscription events
- Handle payment events
- Add error recovery
```

---

## Phase 5: Database Integration

**Goal:** Sync with database

**Actions:**

```
Task(payments-architect) Configure database sync.

Requirements:
- Create subscription tables
- Sync customer data
- Track payment history
- Handle plan changes
- Add usage tracking
```

---

## Summary

**Output:**

```
✅ Payment System Complete

To add features:
  /payments:add checkout <type>        # Checkout flow
  /payments:add subscription <plan>    # Subscription plan
  /payments:add webhook <event>        # Webhook handler
  /payments:add billing-portal         # Customer portal

To test:
  Use Stripe test mode
```
