---
description: Add contact management with segments, topics, and custom properties
argument-hint: [--with-segments] [--with-topics] [--bulk-import]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Implement comprehensive contact management system for Resend email campaigns with segments, topics, and custom properties

Core Principles:
- Understand contact data requirements before building
- Leverage Resend API documentation for patterns
- Include bulk import/export from the start
- Enable segment-based targeting and personalization

Phase 1: Discovery
Goal: Understand contact management requirements and current setup

Actions:
- Check package.json for framework and dependencies
- If $ARGUMENTS is unclear, use AskUserQuestion to gather:
  - What contact fields do you need to track?
  - How will contacts be imported (API, CSV, real-time)?
  - Do you need audience segmentation?
  - Will you use topic preferences for email subscriptions?
  - What custom properties will you manage?
- Load existing Resend configuration if available

Phase 2: Analysis
Goal: Determine scope and feature requirements

Actions:
- Parse $ARGUMENTS for flags (--with-segments, --with-topics, --bulk-import)
- Check for existing contact infrastructure
- Identify contact data sources and volumes
- Determine segment complexity and update frequency
- Understand existing contact properties or schema
- Example: !{bash find src -name "*contact*" -o -name "*segment*" 2>/dev/null | head -10}

Phase 3: Implementation
Goal: Build contact management system with resend-contacts-agent

Actions:

Task(description="Implement contact management system", subagent_type="resend-contacts-agent", prompt="You are the resend-contacts-agent. Implement a comprehensive contact management system for Resend for $ARGUMENTS.

Requirements from user:
- Include contact CRUD operations (create, read, update, delete)
- Add bulk import/export functionality for CSV and JSON
- Implement segment management if --with-segments flag is present
- Implement topic preferences if --with-topics flag is present
- Support custom contact properties and fields
- Ensure API key handling via environment variables

Deliverables:
1. Contact service with full CRUD operations
2. Bulk import/export handlers
3. Segment management (if requested)
4. Topic management (if requested)
5. Custom property definitions and validation
6. Error handling and logging
7. Rate limiting awareness for batch operations
8. .env.example with placeholder credentials
9. TypeScript types (if applicable)")

Phase 4: Verification
Goal: Ensure contact management system works correctly

Actions:
- Check for contact service file creation
- Verify contact CRUD operations implemented
- Confirm bulk import/export functionality
- Validate segment operations if included
- Check topic management if included
- Verify environment variable handling
- Example: !{bash find . -name "*.env.example" | grep -q . && echo "Config OK" || echo "Missing .env.example"}

Phase 5: Summary
Goal: Document what was implemented

Actions:
- Summarize contact management features added
- Highlight segments and topics (if included)
- Show next steps for integration
- Provide usage examples for contact operations
