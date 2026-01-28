---
description: Build complete Stripe payments integration - initializes if needed, then runs all specialized agents for checkout, subscriptions, and webhooks
argument-hint: <project-name> [--framework <fastapi|nextjs>]
---

# Build Complete Payments Integration

**Goal:** Create a production-ready Stripe payments integration by orchestrating all specialized agents.

**This command handles everything** - from setup to full integration with checkout, subscriptions, customer portal, and webhooks.

## Stack (Always Use Latest Versions)

- **Stripe** - Latest API version
- **stripe-python** / **stripe-node** - Latest SDK
- **Stripe CLI** - Latest for local testing

**IMPORTANT:** Always use the latest Stripe API version. Check `stripe --version` and Stripe dashboard for current API version.

## Arguments

- `$ARGUMENTS` - Project name and optional framework
- `--framework <name>` - Target framework (fastapi, nextjs)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and framework
2. Auto-detect framework if not specified
3. Discover architecture documentation for pricing/plans
4. Create execution plan based on features needed

### Phase 2: Stripe Setup (if needed)

```
Task("Initialize Stripe", @stripe-integration-agent, {
  prompt: "Initialize Stripe integration:
    - Install Stripe SDK (latest version)
    - Configure API keys from environment
    - Set up Stripe client singleton
    - Create webhook endpoint configuration
    Detect framework and configure appropriately."
})
```

### Phase 3: Parallel Agent Execution

```
// Agent 1: Payment Architecture
Task("Design payment flow", @payments-architect, {
  prompt: "Design complete payment architecture:
    - Define products and pricing from architecture docs
    - Design checkout flow (one-time, subscription)
    - Plan customer portal integration
    - Define usage-based billing if needed
    Create Stripe product/price configuration."
})

// Agent 2: Subscription Management
Task("Build subscriptions", @subscription-manager-agent, {
  prompt: "Implement subscription management:
    - Create subscription checkout sessions
    - Handle plan upgrades/downgrades
    - Implement usage tracking if metered
    - Add customer portal for self-service
    Follow pricing from architecture docs."
})

// Agent 3: Webhook Handling
Task("Setup webhooks", @webhook-handler-agent, {
  prompt: "Implement webhook handlers:
    - Signature verification
    - Handle checkout.session.completed
    - Handle subscription lifecycle events
    - Handle payment_intent events
    - Handle invoice events
    Add proper error handling and idempotency."
})
```

### Phase 4: Final Output

**Provide summary:**

- List all payment features implemented
- Show Stripe products/prices to create
- Provide test commands:

  ```bash
  # Start webhook listener
  stripe listen --forward-to localhost:8000/webhooks/stripe

  # Test checkout
  stripe trigger checkout.session.completed
  ```

## Utility Commands

- `/payments:add-checkout` - Add checkout flow only
- `/payments:add-subscriptions` - Add subscription management
- `/payments:add-webhooks` - Add webhook handlers
