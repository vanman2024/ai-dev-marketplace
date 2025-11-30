---
description: Add email sending functionality with templates and attachments support
argument-hint: [--batch] [--scheduled]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Implement complete email sending functionality with template support, batch processing, attachments, and scheduling capabilities

Core Principles:
- Support single and batch email sending
- Provide flexible template system
- Handle attachments securely
- Include scheduling capabilities
- Robust error handling and logging

Phase 1: Discovery
Goal: Gather context and requirements

Actions:
- Parse $ARGUMENTS for flags (--batch, --scheduled)
- Load existing Resend plugin structure to understand current implementation
- Example: !{bash find /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/resend -type f -name "*.md" -o -name "*.ts" -o -name "*.js" | head -20}
- Check if services directory exists
- Load any existing email utilities or configurations

Phase 2: Analysis
Goal: Understand existing patterns and integration points

Actions:
- Read plugin README to understand scope
- Check existing agents and skills for patterns
- Identify where email service should integrate
- Determine TypeScript/JavaScript target
- Example: !{bash ls -la /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/resend/}

Phase 3: Planning
Goal: Design the email sending implementation

Actions:
- Outline structure needed:
  - Email service with send(), sendBatch(), sendScheduled() methods
  - Template engine with variable substitution
  - Attachment handler with validation
  - Error handling and retry logic
  - Scheduling system integration
- Identify configuration requirements
- Plan integration with existing plugin structure

Phase 4: Implementation
Goal: Generate email functionality with agent

Actions:

Task(description="Create email sending service", subagent_type="resend-email-agent", prompt="You are the resend-email-agent. Create comprehensive email sending functionality for the Resend plugin.

Requirements:
- Create email.service.ts with:
  - send(to, from, subject, html, text?) method for single emails
  - sendBatch(emails[]) for batch operations with concurrency control
  - sendScheduled(email, scheduledFor) for scheduled sending
  - Proper Resend API integration with error handling

- Create templates.ts with:
  - Template interface: {id, subject, html, variables}
  - renderTemplate(template, variables) function
  - template registry/loader

- Create attachments.ts with:
  - Attachment validation (size, type)
  - File attachment handler
  - Buffer attachment support

- Create scheduler.ts with:
  - Schedule management
  - Retry logic with exponential backoff
  - Job persistence

- Add error handling:
  - RateLimitError, ValidationError, SendError
  - Retry mechanism with backoff
  - Detailed error logging

- Export clean API from index.ts
- Include TypeScript types for all interfaces
- Add JSDoc comments for public methods

Generated files should be in proper directory structure ready for integration.

Expected output: Complete, production-ready email service module with all files")

Phase 5: Review
Goal: Verify the generated implementation

Actions:
- Check generated files exist and are properly structured
- Verify TypeScript compilation succeeds
- Example: !{bash cd /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/resend && npx tsc --noEmit 2>&1 | head -20}
- Validate templates and attachments handling
- Confirm error handling patterns

Phase 6: Summary
Goal: Document what was accomplished

Actions:
- Summarize features implemented:
  - Single email sending with Resend API
  - Batch processing with concurrency control
  - Scheduling support with retry logic
  - Template system with variable substitution
  - Attachment handling with validation
  - Comprehensive error handling
- Highlight key files created
- Note any configuration needed in project setup
- Suggest next steps (testing, integration examples, documentation)
