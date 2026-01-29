---
description: Add a specific feature to an existing payments project. Features include checkout, subscription, webhook, portal, metered.
argument-hint: <feature> [options]
---

# Add Payments Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Checkout Features

**If `$0` = "checkout":**

```
Task(stripe-integration-agent) Add CHECKOUT flow.

Requirements:
- Checkout type: $1 (hosted, embedded, custom - default: hosted)
- Payment types: $2 (one-time, subscription, both - default: both)
- Create checkout session
- Configure success/cancel URLs
- Add price selection
- Handle completion
```

### Subscription Features

**If `$0` = "subscription":**

```
Task(subscription-manager-agent) Add SUBSCRIPTION plan.

Requirements:
- Plan name: $1 (required)
- Billing: $2 (monthly, yearly, both - default: both)
- Create product/price
- Configure plan limits
- Add to checkout flow
- Set up entitlements
```

**If `$0` = "portal":**

```
Task(subscription-manager-agent) Add BILLING PORTAL.

Requirements:
- Features: $1 (all, payments, subscriptions - default: all)
- Configure portal settings
- Create portal session
- Add portal link
- Configure branding
```

**If `$0` = "metered":**

```
Task(subscription-manager-agent) Add METERED billing.

Requirements:
- Usage type: $1 (api-calls, tokens, storage - required)
- Create metered price
- Set up usage reporting
- Configure limits
- Add overage handling
```

### Webhook Features

**If `$0` = "webhook":**

```
Task(webhook-handler-agent) Add WEBHOOK handler.

Requirements:
- Event type: $1 (checkout, subscription, invoice, all - default: all)
- Create webhook endpoint
- Add signature verification
- Handle events
- Add error recovery
```

### Integration Features

**If `$0` = "database":**

```
Task(payments-architect) Add DATABASE sync.

Requirements:
- Database: $1 (supabase, postgres, prisma - default: supabase)
- Create subscription tables
- Set up customer sync
- Add event logging
- Configure indexes
```

---

## Usage Examples

```bash
# Checkout
/payments:add checkout hosted subscription
/payments:add checkout embedded one-time
/payments:add checkout custom both

# Subscriptions
/payments:add subscription pro monthly
/payments:add subscription enterprise yearly
/payments:add portal all

# Metered billing
/payments:add metered api-calls
/payments:add metered tokens

# Webhooks
/payments:add webhook subscription
/payments:add webhook all

# Database
/payments:add database supabase
```

---

## Feature Reference

| Feature        | Agent                | $1 Options                    | Description       |
| -------------- | -------------------- | ----------------------------- | ----------------- |
| `checkout`     | stripe-integration   | hosted/embedded/custom        | Checkout flow     |
| `subscription` | subscription-manager | plan-name (required)          | Subscription plan |
| `portal`       | subscription-manager | all/payments/subscriptions    | Billing portal    |
| `metered`      | subscription-manager | api-calls/tokens/storage      | Metered billing   |
| `webhook`      | webhook-handler      | checkout/subscription/invoice | Webhook handler   |
| `database`     | payments-architect   | supabase/postgres/prisma      | Database sync     |
