---
description: Add Stripe Checkout flow with payment intents and success/cancel pages
argument-hint: "[checkout-type]"
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite, Skill
---

**Arguments**: $ARGUMENTS

Goal: Implement complete Stripe Checkout flow with payment intents, session creation, success/cancel pages, and Supabase payment records

Core Principles:
- Never hardcode Stripe API keys - use placeholders only
- Follow security best practices for payment handling
- Implement proper error handling for payment failures
- Store payment records securely in Supabase
- Follow existing codebase patterns

## Security: API Key Handling

**CRITICAL:** When generating any configuration files or code:

❌ NEVER hardcode actual API keys or secrets
❌ NEVER include real Stripe keys in examples
❌ NEVER commit sensitive values to git

✅ ALWAYS use placeholders: `your_stripe_key_here`
✅ ALWAYS create `.env.example` with placeholders only
✅ ALWAYS add `.env*` to `.gitignore` (except `.env.example`)
✅ ALWAYS read from environment variables in code
✅ ALWAYS document where to obtain Stripe keys

**Placeholder format:** `stripe_{env}_your_key_here`

Phase 1: Discovery
Goal: Understand project structure and existing payment setup

Actions:
- Create todo list with TodoWrite for tracking progress
- Parse $ARGUMENTS for checkout type (one-time, subscription, custom)
- Detect project structure: !{bash ls -la | grep -E "(package.json|requirements.txt)"}
- Find payment files: !{bash find . -name "*payment*" 2>/dev/null | head -10}
- Load configuration: @.env.example
- Search payment schemas with Glob
- Update todos

Phase 2: Backend Implementation
Goal: Create Stripe Checkout session endpoint in FastAPI

Actions:

Task(description="Implement Stripe Checkout backend", subagent_type="payments:stripe-integration-agent", prompt="You are the stripe-integration-agent. Implement Stripe Checkout backend for $ARGUMENTS.

SECURITY CRITICAL: Use placeholder keys only, read from environment, never hardcode.

Requirements:
- FastAPI endpoint POST /api/checkout/create-session
- Payment intent creation with error handling
- Webhook endpoint POST /api/checkout/webhook
- Supabase payment table migration
- Session metadata storage in database
- Success/cancel redirect URLs
- CORS configuration
- Pydantic request validation

Environment: Create .env.example with placeholders, update .gitignore, document key setup.

Deliverables: checkout.py, webhooks.py, payment.py model, migrations, .env.example, updated requirements.txt")

Wait for agent to complete.
Update todos.

Phase 3: Frontend Implementation
Goal: Build Next.js checkout page with Stripe Elements

Actions:

Task(description="Implement Stripe Checkout frontend", subagent_type="payments:stripe-integration-agent", prompt="You are the stripe-integration-agent. Build Next.js checkout page for $ARGUMENTS.

SECURITY CRITICAL: Use placeholder publishable key, read from environment, never hardcode.

Requirements:
- Checkout page app/checkout/page.tsx
- Integrate @stripe/stripe-js and @stripe/react-stripe-js
- Payment form with CardElement or Payment Element
- Client-side validation and error handling
- Loading states
- Success page app/checkout/success/page.tsx
- Cancel page app/checkout/cancel/page.tsx
- TypeScript types for Stripe
- Follow shadcn/ui design system
- Form accessibility

Environment: Add NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY to .env.example, document setup.

Deliverables: page.tsx files, lib/stripe.ts, types/stripe.ts, updated .env.example and package.json")

Wait for agent to complete.
Update todos.

Phase 4: Integration & Testing
Goal: Wire up backend and frontend, verify error handling

Actions:
- Verify backend endpoints accessible from frontend
- Check CORS configuration
- Test checkout flow: !{bash curl -X POST localhost:8000/api/checkout/create-session || echo "Test"}
- Verify Supabase connection and payment table
- Review error handling frontend and backend
- Confirm webhook signature verification
- Update todos

Phase 5: Documentation & Security Review
Goal: Document setup and verify security compliance

Actions:
- Create setup guide: Stripe key acquisition, webhook config, testing
- Security checklist: No hardcoded keys, .gitignore protection, placeholder .env.example, environment reads only, webhook verification, HTTPS, server validation, safe errors
- Generate README.md setup section
- Update todos

Phase 6: Summary
Goal: Report completion and next steps

Actions:
- Mark all todos complete
- Display summary: Files created, Checkout flow, environment variables, setup steps, testing
- Next steps: Stripe account setup, webhook dashboard config, test cards, production deployment
- Confirm security compliance
