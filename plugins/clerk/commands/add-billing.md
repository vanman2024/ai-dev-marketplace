---
description: Integrate Clerk Billing for subscriptions, pricing plans, and payment webhooks
argument-hint: none
allowed-tools: Task, AskUserQuestion, Read
---

**Arguments**: $ARGUMENTS

Goal: Integrate Clerk Billing with subscription management, pricing plans, and payment webhooks

Core Principles:
- Ask about pricing model before implementation
- Follow Clerk Billing best practices
- Integrate with existing authentication setup
- Ensure webhook security and validation

Phase 1: Discovery
Goal: Understand project structure and billing requirements

Actions:
- Check for existing Clerk configuration
- Identify framework (Next.js, React, etc.)
- Load relevant configuration files
- Example: @package.json

Phase 2: Requirements Gathering
Goal: Understand billing needs and pricing model

Actions:

Use AskUserQuestion to gather:

Question 1: "What pricing model do you want to implement?"
Options:
- "Subscription-based" - Monthly/yearly recurring billing
- "Usage-based" - Pay-per-use or metered billing
- "Hybrid" - Combination of subscription + usage
- "One-time" - Single payment purchases

Question 2: "Which payment provider are you using?"
Options:
- "Stripe" - Most common, full feature set
- "Other" - Specify your provider

Question 3: "Do you need webhook handling?"
Options:
- "Yes" - Handle subscription events, payment updates
- "No" - Just basic billing integration

Phase 3: Implementation
Goal: Integrate Clerk Billing with agent

Actions:

Task(description="Integrate Clerk Billing", subagent_type="clerk:clerk-billing-integrator", prompt="You are the clerk-billing-integrator agent. Integrate Clerk Billing for this project.

Pricing Model: [Answer from Question 1]
Payment Provider: [Answer from Question 2]
Webhook Handling: [Answer from Question 3]

Requirements:
- Set up Clerk Billing configuration
- Implement pricing plans and subscription logic
- Configure payment webhooks if requested
- Add billing UI components (pricing page, subscription management)
- Implement subscription check middleware/guards
- Set up webhook endpoint for payment events
- Add proper error handling and validation
- Follow security best practices for payment data
- Integrate with existing Clerk authentication

Expected output:
- Billing configuration files
- Pricing plan definitions
- Subscription management components
- Webhook handlers (if enabled)
- Middleware for subscription checks
- Documentation for setup and usage")

Phase 4: Summary
Goal: Confirm integration and provide next steps

Actions:
- Summarize what was integrated
- List files created/modified
- Provide setup instructions:
  - Environment variables needed
  - Clerk Dashboard configuration steps
  - Payment provider setup (Stripe, etc.)
- Highlight key features:
  - Pricing plans configured
  - Subscription management UI
  - Webhook endpoints (if enabled)
- Suggest next steps:
  - Test subscription flows
  - Configure production payment provider
  - Set up webhook endpoints in Clerk Dashboard
