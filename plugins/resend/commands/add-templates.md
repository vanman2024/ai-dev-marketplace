---
description: Add email template management with React Email integration
argument-hint: [--react-email]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Add comprehensive email template management to Resend plugin with React Email component-based templates, versioning support, and publish/duplicate functionality.

Core Principles:
- Build template management service following existing patterns
- Integrate React Email for component-based template development
- Support template versioning and publish workflows
- Include template duplication and metadata management

Phase 1: Discovery
Goal: Understand existing Resend plugin structure and template patterns

Actions:
- Examine current service architecture
- Example: !{bash find /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/resend -name "*.ts" -o -name "*.md" | head -20}
- Load existing services to understand patterns: @/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/resend/src/services

Phase 2: Analysis
Goal: Identify template integration points and React Email requirements

Actions:
- Review existing Resend service implementations
- Check for template patterns in email services
- Identify where React Email components fit
- Look for versioning mechanisms
- Create todo list for template implementation:

TodoWrite:
- status: in_progress
- content: Discover template patterns and integration points
- activeForm: Discovering template patterns
- status: pending
- content: Design React Email component structure
- activeForm: Designing React Email component structure
- status: pending
- content: Implement template management service
- activeForm: Implementing template management service
- status: pending
- content: Add versioning support
- activeForm: Adding versioning support
- status: pending
- content: Implement publish and duplicate functionality
- activeForm: Implementing publish and duplicate functionality
- status: pending
- content: Validate template implementation
- activeForm: Validating template implementation

Phase 3: Implementation
Goal: Build template functionality with agent guidance

Actions:

Task(description="Build template management", subagent_type="resend-templates-agent", prompt="You are the resend-templates-agent. Add comprehensive email template management to the Resend plugin for $ARGUMENTS.

Requirements:
- Create template management service with CRUD operations
- Integrate React Email for component-based templates
- Implement template versioning with version history
- Support template publishing workflows
- Add template duplication with metadata management
- Include template preview capabilities
- Support dynamic variable substitution in templates
- Integrate with existing Resend patterns

Deliverable: Complete template service implementation with types, repository patterns, React Email integration, and integration ready for use.")

Phase 4: Review and Summary
Goal: Validate and document template implementation

Actions:
- Review generated template service code
- Verify React Email component integration
- Check versioning and publish workflows
- Confirm duplication and metadata handling
- Summarize: Template management added with React Email integration, versioning, and publish/duplicate functionality
