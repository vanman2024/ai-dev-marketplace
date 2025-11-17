---
description: Integrate Clerk Billing for subscriptions, pricing plans, and payment webhooks
argument-hint: none
allowed-tools: Task, AskUserQuestion, Read
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
