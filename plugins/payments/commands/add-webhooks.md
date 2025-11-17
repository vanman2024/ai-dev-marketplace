---
description: Setup secure webhook handlers for payment events and subscription updates
argument-hint: "[webhook-events]"
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---


**Arguments**: $ARGUMENTS

Goal: Setup secure Stripe webhook infrastructure with signature verification, event handlers, and debugging capabilities

**SECURITY CRITICAL:**
- NEVER hardcode webhook secrets
- Use placeholder: STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
- Always implement signature verification
- Read secrets from environment variables ONLY

Core Principles:
- Security first: Always verify webhook signatures
- Never trust unverified webhook data
- Store webhook events for debugging and replay
- Implement idempotency for webhook processing

Phase 1: Project Discovery

Actions:
- Parse $ARGUMENTS to determine which events to handle
- Verify FastAPI backend: !{bash test -d backend && echo "Found" || echo "Not found"}
- Check Supabase integration: !{bash test -f backend/.env.example && grep -q "SUPABASE" backend/.env.example && echo "Configured" || echo "Missing"}
- Load existing payment routes: @backend/app/api/routes/payments.py

Phase 2: Environment Configuration

Actions:
- Update backend/.env.example with webhook placeholders
- Add STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
- Add STRIPE_WEBHOOK_TOLERANCE=300
- Verify .gitignore protects: .env, .env.local, .env.development, .env.production
- Add webhook secret to .gitignore if missing

Phase 3: Create Webhook Infrastructure

Task(description="Create webhook infrastructure", subagent_type="payments:webhook-handler-agent", prompt="You are the webhook-handler-agent. Create secure Stripe webhook infrastructure.

**SECURITY:** Use placeholder STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

Create backend/app/api/routes/webhooks.py with:
- POST /api/webhooks/stripe endpoint
- Stripe signature verification using stripe.Webhook.construct_event()
- Raw request body handling for signature verification
- Event type routing for: payment_intent.succeeded, payment_intent.payment_failed, customer.subscription.created, customer.subscription.updated, customer.subscription.deleted, invoice.payment_succeeded, invoice.payment_failed
- Return 400 for invalid signatures
- Store ALL events in webhook_events table
- Implement idempotency: check event_id, skip duplicates
- Comprehensive error handling

Deliverable: backend/app/api/routes/webhooks.py with signature verification and event routing")

Phase 4: Database Schema

Task(description="Create webhook events schema", subagent_type="payments:payments-architect", prompt="You are the payments-architect agent. Create Supabase schema for webhook event storage.

Create supabase/migrations/YYYYMMDDHHMMSS_create_webhook_events.sql with:
- webhook_events table: id uuid, event_id text unique, event_type text, payload jsonb, status text, error_message text, processed_at timestamp, created_at timestamp, updated_at timestamp
- Indexes: event_id unique, event_type, status, created_at
- RLS policies: service role full access, anon/authenticated no access
- Helper functions: get_unprocessed_events(), mark_event_processed(event_id), get_events_by_type(event_type)

Deliverable: Migration file with complete schema and indexes")

Phase 5: Event Handlers

Task(description="Implement event handlers", subagent_type="payments:webhook-handler-agent", prompt="You are the webhook-handler-agent. Create event handler functions for Stripe webhooks.

Create backend/app/services/webhook_handlers.py with handlers for:
- handle_payment_intent_succeeded: Update payment status, send confirmation, update subscription
- handle_payment_intent_failed: Update payment status, send notification, trigger retry
- handle_subscription_created: Create subscription record, update user status, send welcome email
- handle_subscription_updated: Update subscription, handle plan changes, notify user
- handle_subscription_deleted: Mark cancelled, set cancellation date, send confirmation
- handle_invoice_payment_succeeded: Record payment, update billing date, send receipt
- handle_invoice_payment_failed: Record failure, update retry schedule, send notification

Each handler must:
- Accept full Stripe event object
- Extract data safely
- Update database atomically
- Handle errors gracefully
- Return success/failure status
- Log all actions

Deliverable: webhook_handlers.py with all event handlers and error handling")

Phase 6: Testing Setup

Task(description="Setup webhook testing", subagent_type="payments:stripe-integration-agent", prompt="You are the stripe-integration-agent. Create local webhook testing infrastructure.

Create:
1. docs/webhooks/LOCAL_TESTING.md with Stripe CLI installation, webhook forwarding, testing workflow
2. backend/scripts/test-webhooks.sh to trigger all webhook events and verify processing
3. Testing checklist: signature verification, invalid signatures rejected, all event types handled, database records created, idempotency works

Include Stripe CLI commands for local testing and event triggering.

Deliverable: LOCAL_TESTING.md, test-webhooks.sh, testing checklist")

Phase 7: Production Documentation

Actions:
- Create docs/webhooks/PRODUCTION_SETUP.md documenting:
  - Webhook endpoint registration in Stripe Dashboard
  - Production webhook URL format
  - Required webhook events to enable
  - Webhook secret retrieval from Stripe
  - Environment variable configuration
  - Webhook endpoint testing in production
  - Monitoring and alerting setup
- Include security reminders: HTTPS only, never log secrets, verify all signatures, monitor patterns, alert on failures

Phase 8: Error Handling

Actions:
- Add retry logic for transient failures with exponential backoff
- Implement dead letter queue for failed webhooks
- Create admin endpoint to replay failed webhooks
- Set up alerts for repeated failures
- Document error scenarios and responses

Phase 9: Validation

Actions:
- Run webhook tests: !{bash cd backend && python -m pytest tests/test_webhooks.py -v}
- Verify signature validation works
- Test all event handlers
- Check database records created correctly
- Verify idempotency handles duplicates
- Test error scenarios: invalid signatures, malformed payloads

Phase 10: Summary

Actions:
- Display created files: webhooks.py, webhook_handlers.py, migration file, .env.example, LOCAL_TESTING.md, PRODUCTION_SETUP.md, test-webhooks.sh
- Show configuration checklist: endpoint created, signature verification implemented, event handlers created, database schema, env vars configured, testing documented, production setup documented, error handling implemented
- Provide next steps:
  1. Copy backend/.env.example to backend/.env
  2. Get webhook secret: stripe listen --print-secret
  3. Add to backend/.env: STRIPE_WEBHOOK_SECRET=whsec_...
  4. Start backend: uvicorn app.main:app --reload
  5. Forward webhooks: stripe listen --forward-to localhost:8000/api/webhooks/stripe
  6. Test events: stripe trigger payment_intent.succeeded
  7. Verify in Supabase webhook_events table
- Production deployment: register endpoint in Stripe Dashboard, add production secret, deploy backend, test webhook, monitor events
