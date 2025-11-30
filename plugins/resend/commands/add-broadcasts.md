---
description: Add broadcast/campaign functionality for sending to audiences
argument-hint: [broadcast-name]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Add comprehensive broadcast and campaign functionality to Resend plugin with audience targeting, scheduling, and analytics.

Core Principles:
- Build broadcast management service following existing patterns
- Support flexible audience targeting via segments
- Integrate scheduling capabilities
- Include tracking and analytics hooks for measurement

Phase 1: Discovery
Goal: Understand existing Resend plugin structure and patterns

Actions:
- Examine current service architecture
- Example: !{bash find /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/resend -name "*.ts" -o -name "*.md" | head -20}
- Load existing services to understand patterns: @/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/resend/src/services

Phase 2: Analysis
Goal: Identify integration points and required components

Actions:
- Review existing Resend service implementations
- Identify audience/segment management patterns
- Check for scheduling mechanisms
- Look for analytics hooks in email services
- Create todo list for broadcast implementation:

TodoWrite:
- status: in_progress
- content: Discover broadcast patterns and integration points
- activeForm: Discovering broadcast patterns
- status: pending
- content: Implement broadcast management service
- activeForm: Implementing broadcast management service
- status: pending
- content: Add audience targeting and segmentation
- activeForm: Adding audience targeting and segmentation
- status: pending
- content: Integrate scheduling capabilities
- activeForm: Integrating scheduling capabilities
- status: pending
- content: Add tracking and analytics hooks
- activeForm: Adding tracking and analytics hooks
- status: pending
- content: Validate broadcast implementation
- activeForm: Validating broadcast implementation

Phase 3: Implementation
Goal: Build broadcast functionality with agent guidance

Actions:

Task(description="Build broadcast functionality", subagent_type="resend-broadcasts-agent", prompt="You are the resend-broadcasts-agent. Add comprehensive broadcast and campaign functionality to the Resend plugin for $ARGUMENTS.

Requirements:
- Create broadcast management service with CRUD operations
- Support audience targeting via customer segments
- Implement campaign scheduling (immediate, delayed, recurring)
- Add delivery and engagement tracking hooks
- Include template management for campaigns
- Support A/B testing capabilities
- Integrate with existing Resend patterns

Deliverable: Complete broadcast service implementation with types, repository patterns, and integration ready for use.")

Phase 4: Review and Summary
Goal: Validate and document broadcast implementation

Actions:
- Review generated broadcast service code
- Verify integration with existing Resend patterns
- Check type safety and error handling
- Confirm scheduling and analytics hooks
- Summarize: Broadcast functionality added with audience targeting, scheduling, and analytics tracking
