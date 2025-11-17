---
description: Interactive framework selection and setup guide with tailored Clerk configuration
argument-hint: none
allowed-tools: Task, AskUserQuestion, Read, Bash, Write
---

Goal: Guide users through complete Clerk setup with interactive questions about framework, features, and integrations, then orchestrate appropriate agents based on selections.

Core Principles:
- Ask clarifying questions early to understand user needs
- Tailor setup based on framework and feature selections
- Orchestrate specialized agents for implementation
- Provide clear next steps after setup

Phase 1: Framework Selection
Goal: Determine which framework the user is building with

Actions:
- Use AskUserQuestion to determine framework:

Which framework are you building with?

Options:
1. Next.js App Router (recommended)
2. Next.js Pages Router
3. React (Vite/CRA)
4. Remix
5. Express.js
6. Other/Not sure

- Store framework selection for Phase 4

Phase 2: Feature Requirements
Goal: Understand which Clerk features are needed

Actions:
- Use AskUserQuestion to determine features (allow multiple selections):

Which Clerk features do you need? (Select all that apply)

Options:
1. OAuth Providers (Google, GitHub, etc.)
2. Organizations (multi-tenant)
3. Billing Integration
4. Multi-factor Authentication (MFA)
5. Custom User Fields
6. Session Management
7. Webhooks

- Store feature selections for Phase 5

Phase 3: Integration Requirements
Goal: Identify third-party integrations needed

Actions:
- Use AskUserQuestion to determine integrations:

Which integrations do you need with Clerk?

Options:
1. Supabase (database + RLS)
2. Vercel AI SDK (chat history, user context)
3. Sentry (error tracking with user context)
4. None

- Store integration selections for Phase 6

Phase 4: Framework Setup
Goal: Set up Clerk for the selected framework

Actions:

Based on framework selection from Phase 1, invoke the appropriate setup agent:

Task(description="Set up Clerk for selected framework", subagent_type="clerk-setup-agent", prompt="You are the clerk-setup-agent. Set up Clerk authentication for the framework selected in Phase 1.

Framework: [Insert framework from Phase 1]

Setup requirements:
- Install Clerk SDK packages
- Configure environment variables (.env.example)
- Set up middleware/providers based on framework
- Create sign-in and sign-up pages
- Add protected route examples

Deliverable: Complete framework-specific Clerk setup with example pages")

Wait for agent to complete setup.

Phase 5: Feature Implementation
Goal: Implement selected Clerk features

Actions:

Based on feature selections from Phase 2, invoke feature-specific agents:

For OAuth Providers:
Task(description="Configure OAuth providers", subagent_type="clerk-oauth-specialist", prompt="Configure OAuth providers (Google, GitHub, etc.) for Clerk. Create provider setup documentation and .env variables.")

For Organizations:
Task(description="Add organization support", subagent_type="clerk-organization-builder", prompt="Implement Clerk organizations with role-based access control, organization switching, and member management.")

For Billing Integration:
Task(description="Set up billing integration", subagent_type="clerk-billing-integrator", prompt="Integrate Clerk with billing provider (Stripe recommended). Add subscription checks and billing portal.")

For MFA:
Task(description="Configure MFA", subagent_type="clerk-mfa-specialist", prompt="Set up multi-factor authentication with SMS and authenticator app support.")

For Custom User Fields:
Task(description="Add custom user metadata", subagent_type="clerk-setup-agent", prompt="Configure custom user fields and metadata management in Clerk using user metadata API.")

For Session Management:
Task(description="Configure session management", subagent_type="clerk-api-builder", prompt="Set up advanced session management with custom JWT claims and API authentication patterns.")

For Webhooks:
Task(description="Set up Clerk webhooks", subagent_type="clerk-api-builder", prompt="Configure Clerk webhooks for user events (user.created, user.updated, etc.) with webhook handler endpoints and signature verification.")

Wait for all feature agents to complete.

Phase 6: Integration Setup
Goal: Configure third-party integrations

Actions:

Based on integration selections from Phase 3:

For Supabase:
Task(description="Integrate Clerk with Supabase", subagent_type="clerk-supabase-integrator", prompt="Integrate Clerk authentication with Supabase. Configure RLS policies using Clerk user IDs, set up JWT integration, and create example protected database queries.")

For Vercel AI SDK:
Task(description="Integrate Clerk with Vercel AI SDK", subagent_type="clerk-vercel-ai-integrator", prompt="Integrate Clerk user context with Vercel AI SDK. Add user-specific chat history, personalized AI responses, and session management.")

For Sentry:
Task(description="Integrate Clerk with Sentry", subagent_type="clerk-api-builder", prompt="Configure Sentry error tracking with Clerk user context. Add user identification to error reports using Clerk session data.")

Wait for all integration agents to complete.

Phase 7: Summary
Goal: Present complete setup summary and next steps

Actions:
- Summarize what was configured:
  - Framework setup completed
  - Features implemented
  - Integrations configured
- Display next steps:
  - Add CLERK_PUBLISHABLE_KEY and CLERK_SECRET_KEY to .env
  - Configure OAuth providers in Clerk Dashboard
  - Test authentication flows
  - Deploy to production
- Provide links to:
  - Clerk Dashboard
  - Clerk documentation
  - Framework-specific guides
