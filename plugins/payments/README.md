# Payments Plugin

> Stripe integration for payments and subscriptions with FastAPI backend, Next.js frontend, and Supabase database

## Overview

The **payments** plugin provides comprehensive Stripe integration for building payment and subscription features in your AI applications. It seamlessly integrates with the existing AI Dev Marketplace stack (FastAPI, Next.js, Supabase).

## Features

- **Stripe Integration**: Complete Stripe SDK integration for both frontend and backend
- **Payment Processing**: One-time payments, checkout sessions, payment intents
- **Subscription Management**: Recurring billing, subscription lifecycle, upgrades/downgrades
- **Webhook Handling**: Secure webhook verification and event processing
- **Customer Portal**: Self-service subscription management for customers
- **Database Integration**: Supabase schemas for customers, subscriptions, and payments
- **Type Safety**: Full TypeScript support with Stripe type definitions

## Plugin Type

**SDK Integration** - Integrates Stripe payment processing into the AI Dev Marketplace stack

## Stack Integration

- **FastAPI Backend**: Stripe API integration, webhook endpoints, subscription management
- **Next.js Frontend**: Stripe Elements, checkout UI, customer portal
- **Supabase Database**: Payment schemas, customer data, subscription tracking

## Installation

This plugin is part of the AI Dev Marketplace. No additional installation required.

## Usage

### Commands

Use slash commands to add payment features to your application:

```bash
# Initialize payment infrastructure
/payments:init

# Add Stripe checkout
/payments:add-checkout

# Add subscription billing
/payments:add-subscriptions

# Setup webhook handlers
/payments:add-webhooks
```

### Agents

The plugin includes specialized agents for payment implementation:

- **payments-architect**: Design payment system architecture
- **stripe-integration-agent**: Implement Stripe SDK integration
- **webhook-handler-agent**: Build secure webhook processing
- **subscription-manager-agent**: Manage subscription lifecycle

### Skills

Reusable resources for payment implementation:

- **stripe-patterns**: Stripe integration templates and examples
- **webhook-security**: Webhook signature verification patterns
- **subscription-schemas**: Supabase database schemas for billing
- **checkout-components**: Next.js checkout UI components

## Security

**CRITICAL**: This plugin follows strict security rules for API key management:

❌ **NEVER** hardcode Stripe API keys in code
✅ **ALWAYS** use environment variables
✅ **ALWAYS** use `.env.example` with placeholders
✅ **ALWAYS** verify webhook signatures

See `@docs/security/SECURITY-RULES.md` for complete security guidelines.

## Environment Variables

```bash
# .env.example
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
```

Get your Stripe keys at: https://dashboard.stripe.com/apikeys

## Documentation

- [Stripe Documentation](https://stripe.com/docs)
- [Stripe CLI](https://stripe.com/docs/stripe-cli)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)

## Version

**1.0.0** - Initial release

## License

MIT License - see [LICENSE](./LICENSE) file for details

## Contributing

This plugin follows the AI Dev Marketplace plugin development standards. See the domain-plugin-builder documentation for contribution guidelines.
