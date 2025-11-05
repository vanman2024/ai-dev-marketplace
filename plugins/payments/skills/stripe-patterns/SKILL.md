---
name: stripe-patterns
description: Stripe integration templates with reusable code for Checkout, Payment Intents, and Subscriptions. Use when implementing Stripe payments, building checkout flows, handling subscriptions, or integrating payment processing.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Stripe Integration Patterns

Comprehensive Stripe integration templates for FastAPI backends and Next.js frontends, including Checkout Sessions, Payment Intents, and Subscription billing.

## Use When

- Implementing Stripe payment processing in applications
- Building checkout flows for one-time or recurring payments
- Integrating subscription billing systems
- Setting up webhook handlers for payment events
- Creating secure payment forms with Stripe Elements
- Validating Stripe API configuration

## Security Requirements

**CRITICAL: All templates follow strict security rules:**

- All API keys use placeholders: `your_stripe_key_here`
- Code reads from environment variables only
- `.env.example` templates provided with placeholders
- `.gitignore` protects secret files
- Documentation explains how to obtain Stripe keys

**NEVER hardcode actual Stripe API keys in any files!**

## Integration Patterns

### 1. Checkout Sessions (Redirect Flow)

**Best for:** Quick integration, hosted payment pages, minimal frontend code

**Flow:**
1. Create Checkout Session on backend with line items and success URL
2. Redirect customer to Stripe-hosted checkout page
3. Handle `checkout.session.completed` webhook for fulfillment

**Use:** `scripts/setup-stripe-checkout.sh` and `templates/checkout_session.py`

### 2. Payment Intents (Custom UI)

**Best for:** Custom payment forms, direct card collection, advanced UX control

**Flow:**
1. Create PaymentIntent on backend when checkout begins
2. Pass client secret to frontend
3. Collect payment details with Stripe Elements
4. Confirm payment on client side
5. Monitor webhooks for payment success/failure

**Use:** `scripts/setup-payment-intents.sh` and `templates/payment_intent.py`

### 3. Subscriptions (Recurring Billing)

**Best for:** Recurring revenue, subscription services, membership access

**Flow:**
1. Create or retrieve Customer object
2. Attach payment method to customer
3. Create Subscription with pricing and billing cycle
4. Handle subscription lifecycle events via webhooks

**Use:** `scripts/setup-subscriptions.sh` and `templates/subscription.py`

## Available Scripts

### setup-stripe-checkout.sh
Creates complete Checkout Session implementation with FastAPI endpoint, webhook handler, and success/cancel pages.

```bash
bash scripts/setup-stripe-checkout.sh
```

### setup-payment-intents.sh
Sets up Payment Intent workflow with client secret handling, Stripe Elements integration, and payment confirmation.

```bash
bash scripts/setup-payment-intents.sh
```

### setup-subscriptions.sh
Implements subscription billing with customer management, subscription creation, and lifecycle webhook handlers.

```bash
bash scripts/setup-subscriptions.sh
```

### validate-stripe-config.sh
Validates Stripe configuration including API keys, webhook secrets, environment setup, and .gitignore protection.

```bash
bash scripts/validate-stripe-config.sh
```

## Available Templates

### Backend Templates (Python/FastAPI)

**checkout_session.py** - Complete Checkout Session endpoint
- Creates session with line items
- Handles success/cancel redirects
- Returns session ID for redirect

**payment_intent.py** - Payment Intent workflow
- Creates PaymentIntent with amount/currency
- Returns client secret for frontend
- Handles payment confirmation

**subscription.py** - Subscription management
- Customer creation and retrieval
- Payment method attachment
- Subscription creation with pricing

### Frontend Templates (TypeScript/Next.js)

**stripe_elements.tsx** - Stripe Elements component
- Card input with validation
- Payment Intent confirmation
- Error handling and status updates

**checkout_page.tsx** - Complete checkout page
- Product display with pricing
- Checkout Session redirect flow
- Success/cancel page handling

## Available Examples

### fastapi-checkout-example.py
Complete working example with:
- FastAPI application setup
- Checkout Session creation endpoint
- Webhook handler for fulfillment
- Environment configuration
- Error handling

### nextjs-payment-form-example.tsx
Full payment form implementation:
- Stripe Elements integration
- Payment Intent confirmation
- Loading states and error display
- Success/failure handling

### subscription-flow-example.py
End-to-end subscription workflow:
- Customer creation
- Payment method collection
- Subscription creation
- Webhook event processing
- Subscription lifecycle management

## Setup Instructions

### 1. Obtain Stripe Keys

**Test Mode** (for development):
1. Visit https://dashboard.stripe.com/test/apikeys
2. Copy "Publishable key" and "Secret key"
3. Use test card: `4242 4242 4242 4242`

**Live Mode** (for production):
1. Complete account verification
2. Visit https://dashboard.stripe.com/apikeys
3. Copy production keys
4. **NEVER commit live keys to git!**

### 2. Configure Environment

Create `.env` file (use `.env.example` as template):

```bash
# .env (NEVER commit this file)
STRIPE_SECRET_KEY=your_stripe_secret_key_here
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here
STRIPE_WEBHOOK_SECRET=your_webhook_secret_here
```

Add to `.gitignore`:

```
.env
.env.local
.env.development
.env.production
!.env.example
```

### 3. Install Dependencies

**Backend (Python):**
```bash
pip install stripe fastapi uvicorn python-dotenv
```

**Frontend (Next.js):**
```bash
npm install @stripe/stripe-js @stripe/react-stripe-js
```

### 4. Set Up Webhooks

**Local Development:**
1. Install Stripe CLI: https://stripe.com/docs/stripe-cli
2. Run `stripe login`
3. Forward events: `stripe listen --forward-to localhost:8000/webhook`
4. Copy webhook signing secret to `.env`

**Production:**
1. Add endpoint in Stripe Dashboard
2. Select events to listen for
3. Copy webhook signing secret

## Best Practices

### Security
- Always use environment variables for API keys
- Validate webhook signatures to prevent tampering
- Use HTTPS in production for all endpoints
- Never log sensitive payment information
- Implement proper error handling without exposing keys

### Payment Flow
- Create PaymentIntent as early as possible (when amount is known)
- Store PaymentIntent ID for retrieval on page refresh
- Use idempotency keys for safe retries
- Handle all possible payment statuses
- Implement proper loading states in UI

### Subscriptions
- Use `default_incomplete` payment behavior
- Collect payment method before creating subscription
- Handle trial periods correctly
- Monitor subscription status changes via webhooks
- Implement proper cancellation and upgrade flows

### Testing
- Use Stripe test cards: https://stripe.com/docs/testing
- Test webhook events with Stripe CLI
- Verify error handling for declined cards
- Test 3D Secure authentication flows
- Validate success and failure paths

## Common Use Cases

### One-Time Payment
Use **Checkout Sessions** for simplicity or **Payment Intents** for custom UI.

### Recurring Billing
Use **Subscriptions** with automatic invoice generation.

### Free Trial
Create subscription with `trial_period_days` parameter.

### Usage-Based Billing
Use Subscriptions with metered billing and usage reports.

### Multiple Payment Methods
Store payment methods on Customer object and set default.

## Troubleshooting

### Payment Fails Silently
- Check webhook endpoint is accessible
- Verify webhook signature validation
- Review Stripe Dashboard event logs

### Checkout Session Expires
- Sessions expire after 24 hours
- Create new session for retry

### Subscription Status Stuck
- Check for failed payments in Dashboard
- Verify payment method is valid
- Review subscription payment settings

### CORS Errors
- Configure CORS middleware in FastAPI
- Allow Stripe.js origins in production

## References

- Stripe Checkout: https://docs.stripe.com/payments/checkout
- Payment Intents: https://docs.stripe.com/payments/payment-intents
- Subscriptions: https://docs.stripe.com/billing/subscriptions
- Webhooks: https://docs.stripe.com/webhooks
- Testing: https://docs.stripe.com/testing
