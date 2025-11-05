---
description: Add subscription billing with plans, upgrades, downgrades, and lifecycle management
argument-hint: "[subscription-type]"
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode Stripe API keys or secrets
- Use placeholders: your_stripe_key_here, your_stripe_webhook_secret_here
- Protect .env files with .gitignore
- Create .env.example with placeholders only

**Arguments**: $ARGUMENTS

Goal: Add complete subscription billing system with Stripe integration, plan management, and customer portal

Phase 1: Discovery and Planning

Actions:
- Parse $ARGUMENTS to determine subscription type (SaaS tiers, usage-based, hybrid)
- Detect backend framework: @package.json or @requirements.txt
- Detect frontend framework: Check for Next.js, React, Vue in package.json
- Identify database: Supabase, PostgreSQL, MySQL
- Check for existing Stripe integration
- Create TodoWrite list for tracking subscription implementation phases

Phase 2: Stripe Product Setup

Actions:
Task(description="Configure Stripe products and pricing", subagent_type="payments:subscription-manager-agent", prompt="You are the subscription-manager-agent. Set up Stripe subscription products and pricing for $ARGUMENTS subscription type.

SECURITY CRITICAL: Use placeholders for ALL Stripe keys. Never include actual API keys. Create .env.example with placeholder keys only.

Create config/stripe-products.json with 3 tiers (Starter, Professional, Enterprise) including name, description, monthly price, trial days, and feature list.

Create scripts/setup-stripe-products script (js or py based on detected framework) to read config and create products in Stripe using API.

Add to .env.example: STRIPE_SECRET_KEY, STRIPE_PUBLISHABLE_KEY, STRIPE_WEBHOOK_SECRET with placeholder values.

Update .gitignore to protect .env files.")

Phase 3: Database Schema

Actions:
Task(description="Create subscription database schema", subagent_type="payments:payments-architect", prompt="You are the payments-architect agent. Create database schema for subscription management.

Tables needed:
1. subscriptions: id, user_id, stripe_customer_id, stripe_subscription_id, stripe_price_id, status (active/canceled/past_due/trialing/incomplete), current_period_start, current_period_end, cancel_at_period_end, trial_end, created_at, updated_at

2. subscription_items: id, subscription_id, stripe_subscription_item_id, stripe_price_id, quantity, created_at

3. invoices: id, user_id, subscription_id, stripe_invoice_id, amount_paid, currency, status (paid/open/void/uncollectible), invoice_pdf, created_at

Create migration file based on detected database (Supabase SQL, Alembic for Python, Prisma for Node.js).

Add indexes on user_id, stripe_customer_id, stripe_subscription_id, and status.")

Phase 4: Backend API

Actions:
Task(description="Build subscription API endpoints", subagent_type="payments:subscription-manager-agent", prompt="You are the subscription-manager-agent. Build backend API endpoints for subscription management.

SECURITY: Read Stripe keys from environment variables only. Validate webhook signatures. Never expose secret keys to frontend.

Create endpoints:
- POST /api/subscriptions/create: Create subscription with trial
- POST /api/subscriptions/upgrade: Upgrade with proration
- POST /api/subscriptions/downgrade: Downgrade at period end
- POST /api/subscriptions/cancel: Cancel subscription
- POST /api/subscriptions/reactivate: Reactivate canceled subscription
- GET /api/subscriptions/current: Get user's subscription
- POST /api/webhooks/stripe: Handle webhooks (subscription.created/updated/deleted, invoice.paid/payment_failed, trial_will_end)

Implement based on detected framework (FastAPI with Pydantic, Express with middleware, or Next.js API routes).

Include error handling and logging.")

Phase 5: Frontend Components

Actions:
Task(description="Build subscription UI components", subagent_type="payments:subscription-manager-agent", prompt="You are the subscription-manager-agent. Build frontend components for subscription management.

SECURITY: Use Stripe publishable key only (safe for frontend). Load from environment variable.

Create components:
- PricingTable: Display plans with features, trial info, CTA buttons
- SubscriptionManager: Show current plan, status, billing cycle, cancel/reactivate buttons, portal link
- UpgradeFlow: Show proration, confirm upgrade
- DowngradeFlow: Explain period end change, confirm
- BillingHistory: List invoices with PDF downloads
- SubscriptionStatus: Status badge (active/trialing/past_due/canceled)

Use Stripe Elements for payment. Handle loading and error states. Responsive with Tailwind CSS.

Framework-specific: Next.js App Router with server components, React hooks, or Vue Composition API.")

Phase 6: Customer Portal

Actions:
Task(description="Integrate Stripe Customer Portal", subagent_type="payments:subscription-manager-agent", prompt="You are the subscription-manager-agent. Integrate Stripe Customer Portal for self-service management.

SECURITY: Create portal sessions server-side only. Validate user authentication. Use secret key server-side only.

Create POST /api/subscriptions/portal endpoint that creates Stripe billing portal session and returns URL.

Add Manage Billing button in account settings that calls portal endpoint and redirects user.

Create docs/stripe-portal-setup.md with instructions for configuring portal in Stripe Dashboard (enable payment methods, invoices, subscription cancellation, set branding).")

Phase 7: Testing

Actions:
- Run database migrations: !{bash npm run migrate} or !{bash alembic upgrade head}
- Test Stripe product creation script
- Verify webhook endpoint: !{bash stripe listen --forward-to localhost:3000/api/webhooks/stripe}
- Check environment variables loaded correctly
- Verify components render
- Test subscription flows: create, upgrade, downgrade, cancel, reactivate
- Verify webhook handling updates database
- Test customer portal access

Phase 8: Documentation

Actions:
- Create docs/subscriptions-setup.md with Stripe configuration steps, webhook setup, database migration commands, product creation script usage, test card numbers, production checklist, and subscription lifecycle explanation
- Display summary: Files created, database tables, API endpoints, frontend components, setup instructions, next steps for testing

Update TodoWrite: Mark all phases complete
