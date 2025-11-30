---
description: Set up webhook handlers for email events (sent, delivered, bounced, opened, clicked)
argument-hint: <webhook-url>
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Set up comprehensive webhook handlers for Resend email events with signature verification, event logging, and processing.

Core Principles:
- Secure by default: Always verify webhook signatures
- Event coverage: Support all Resend email event types
- Clear logging: Log all events for audit and debugging
- Error resilient: Handle webhook delivery failures gracefully

Phase 1: Requirements Gathering
Goal: Understand webhook needs and environment

Actions:
- Parse $ARGUMENTS to extract webhook URL
- If not provided clearly, ask for clarification:
  - Webhook URL for event delivery
  - Which events to monitor (sent, delivered, bounced, opened, clicked, complained)
  - Log destination (file, database, external service)
  - Any custom event filtering needs

Phase 2: Discovery
Goal: Understand current project structure and setup

Actions:
- Check if project has existing webhook handler: !{bash find . -type f -name "*webhook*" 2>/dev/null | head -5}
- Look for environment configuration: @.env.example
- Identify project type and framework: !{bash test -f package.json && cat package.json | grep -E '"(type|scripts)"|"(next|fastify|express)"' || echo "No Node.js project"}
- Load any existing API endpoint structure

Phase 3: Implementation
Goal: Set up webhook infrastructure with agent

Actions:

Task(description="Set up webhook handlers", subagent_type="resend-domains-webhooks-agent", prompt="You are the resend-domains-webhooks-agent. Set up comprehensive webhook handlers for Resend email events.

Webhook URL: $ARGUMENTS

Your tasks:
1. Create webhook endpoint handler supporting all event types (sent, delivered, bounced, opened, clicked, complained)
2. Implement cryptographic signature verification using Resend's webhook signing secret
3. Add event logging and processing infrastructure
4. Create error handling for failed webhook deliveries
5. Generate configuration for environment variables
6. Provide testing instructions

Deliverables:
- Complete webhook handler code
- Signature verification middleware
- Event type definitions and processors
- Error handling and retry logic
- .env configuration template
- Documentation for testing webhooks")

Phase 4: Verification
Goal: Ensure webhook setup is production-ready

Actions:
- Verify webhook handler exists: !{bash test -f webhook.ts || test -f webhook.js && echo "Handler created" || echo "Handler not found"}
- Check for signature verification code: !{bash grep -r "signature\|SIGNING" . --include="*.ts" --include="*.js" 2>/dev/null | head -3}
- Validate environment configuration: @.env.example
- Confirm all event types are handled: !{bash grep -E "sent|delivered|bounced|opened|clicked|complained" webhook.* 2>/dev/null | wc -l}

Phase 5: Summary
Goal: Document what was accomplished

Actions:
- Summarize webhook setup:
  - Handler implementation created
  - All 6 event types supported (sent, delivered, bounced, opened, clicked, complained)
  - Signature verification implemented
  - Event logging configured
- List generated files and their purposes
- Provide next steps:
  - Deploy webhook endpoint
  - Register webhook URL in Resend dashboard
  - Test event delivery with sample events
  - Monitor logs for production issues
- Note any configuration that needs manual updates
