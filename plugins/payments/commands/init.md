---
description: Initialize payment infrastructure with Stripe SDK, environment variables, database schemas
argument-hint: "[project-path]"
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite, Skill
---

**Arguments**: $ARGUMENTS

Goal: Set up complete payment infrastructure with Stripe SDK, secure environment configuration, database schemas, and local webhook testing

Core Principles:
- NEVER hardcode API keys or secrets - use placeholders only
- Detect project structure before making changes
- Create secure environment templates with clear documentation
- Validate setup without requiring actual API keys

Phase 1: Discovery
Goal: Understand project structure and existing configuration

Actions:
- Parse $ARGUMENTS for project path (default to current directory)
- Detect backend framework (FastAPI, Express, etc.)
- Detect frontend framework (Next.js, React, Vue, etc.)
- Check for existing payment infrastructure
- Locate or identify where environment files should live
- Example: !{bash ls package.json pyproject.toml requirements.txt 2>/dev/null}

Phase 2: Environment Configuration
Goal: Create secure environment templates with placeholder values

**SECURITY CRITICAL**: All API keys MUST use placeholders

Actions:
- Create .env.example with Stripe placeholders (sk_test_your_key_here, pk_test_your_key_here, whsec_your_secret_here)
- Update .gitignore to protect .env files (exclude .env.example)
- Document how to obtain Stripe API keys from dashboard
- NEVER include actual API key values

Phase 3: Backend SDK Setup
Goal: Install and configure Stripe SDK for backend

Actions:
- Detect backend language (Python/Node.js)
- Python: Install stripe package, create payment service reading from os.getenv()
- Node.js: Install stripe package, create payment service reading from process.env
- Create payment endpoint stubs (create-payment-intent, webhooks)
- All code MUST read from environment variables, never hardcode keys

Phase 4: Frontend SDK Setup
Goal: Install and configure Stripe Elements for frontend

Actions:
- Detect frontend framework
- Install Stripe packages: @stripe/stripe-js and @stripe/react-stripe-js
- Create Stripe provider component reading from NEXT_PUBLIC_ or equivalent env vars
- Create payment form component template
- Create example checkout page/component
- Ensure all publishable keys read from environment

Phase 5: Database Schema Setup
Goal: Generate Supabase schemas for payment tracking

Actions:
- Create migration for customers table:
  - id (uuid, primary key)
  - stripe_customer_id (text, unique)
  - email (text)
  - created_at (timestamp)
- Create migration for subscriptions table:
  - id (uuid, primary key)
  - customer_id (uuid, foreign key)
  - stripe_subscription_id (text, unique)
  - status (text)
  - price_id (text)
  - current_period_end (timestamp)
- Create migration for payments table:
  - id (uuid, primary key)
  - customer_id (uuid, foreign key)
  - stripe_payment_intent_id (text, unique)
  - amount (integer)
  - currency (text)
  - status (text)
  - created_at (timestamp)
- Add RLS policies for each table
- Document schema in README

Phase 6: Stripe CLI Setup
Goal: Configure local webhook testing environment

Actions:
- Check if Stripe CLI is installed: !{bash which stripe}
- Provide installation instructions for macOS/Linux/Windows
- Create webhook testing script (listen mode, forward to localhost, event logging)
- Document webhook testing workflow
- NEVER include actual webhook secrets

Phase 7: Validation
Goal: Verify setup completeness without requiring actual keys

Actions:
- Check required files exist (env.example, gitignore, payment service, components, migrations)
- Validate placeholder format in .env.example
- Verify no hardcoded API keys in code
- Check all API key references use environment variables
- Run type checking if applicable: !{bash npm run typecheck || true}
- Verify dependencies installed

Phase 8: Documentation
Goal: Create comprehensive setup guide

Actions:
- Generate PAYMENT_SETUP.md with:
  - How to get Stripe API keys (test and live)
  - Environment variable configuration steps
  - Database migration instructions
  - Stripe CLI setup and usage
  - Testing payment flow locally
  - Webhook event handling guide
  - Security best practices
  - Common troubleshooting
- Include links to Stripe documentation
- Add example payment flow diagrams
- Document test card numbers

Phase 9: Summary
Goal: Report setup completion and next steps

Actions:
- Display comprehensive summary:
  - All files created
  - Environment variables that need configuration
  - Database migrations ready to apply
  - Stripe CLI commands for testing
  - Link to PAYMENT_SETUP.md
- Next steps:
  1. Copy .env.example to .env
  2. Get Stripe API keys from dashboard
  3. Fill in actual keys in .env (never commit!)
  4. Apply database migrations
  5. Install Stripe CLI for webhook testing
  6. Test payment flow with test cards
- Security reminder: NEVER commit .env with actual keys
