---
description: Integrate React Email for building beautiful email templates with components
argument-hint: [template-name]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Set up React Email integration with Resend for building and managing professional email templates with reusable React components.

Core Principles:
- Automate dependency installation and directory setup
- Provide example templates demonstrating best practices
- Enable preview server for template development
- Integrate seamlessly with Resend API for sending

Phase 1: Discovery
Goal: Understand project context and requirements

Actions:
- Check if $ARGUMENTS contains template name or is empty
- Detect if project is Node.js: !{bash test -f package.json && echo "Node.js project" || echo "Not found"}
- Load package.json to understand existing dependencies: @package.json

Phase 2: Planning
Goal: Design the React Email setup approach

Actions:
- Determine if project has existing email setup: !{bash ls -la src/emails/ emails/ 2>/dev/null || echo "No email directory found"}
- Verify Node.js version supports React Email: !{bash node -v}
- Plan directory structure: emails/ for components, emails/templates/ for template exports
- Identify integration points with Resend API

Phase 3: Setup
Goal: Execute React Email integration setup

Actions:

Task(description="Setup React Email integration", subagent_type="resend-templates-agent", prompt="You are the resend-templates-agent. Set up React Email integration for $ARGUMENTS.

Context: This is a fresh React Email setup for building professional email templates.

Requirements:
- Install @react-email/components and related dependencies
- Create emails/ directory structure with subdirectories (components, templates, previews)
- Generate 3 example templates: welcome email, password reset, notification
- Create preview server configuration for email development
- Add npm scripts for preview server and template building
- Document React Email component usage and Resend integration

Each template should demonstrate:
- React Email component structure
- Variable placeholders for dynamic content
- Responsive design patterns
- Email client compatibility

Expected output: Complete React Email setup with working examples and documentation")

Phase 4: Verification
Goal: Confirm setup completed successfully

Actions:
- Check emails directory was created: !{bash test -d emails && echo "Success: emails directory created" || echo "Error: directory not found"}
- List generated template files: !{bash ls -la emails/templates/ 2>/dev/null || echo "Templates not found"}
- Verify dependencies installed: !{bash npm list @react-email/components 2>/dev/null | head -3}

Phase 5: Summary
Goal: Document what was accomplished

Actions:
- List all created files and directories
- Display preview server startup instructions
- Show example template locations and usage
- Document next steps for creating additional templates
- Suggest integration with Resend send API
