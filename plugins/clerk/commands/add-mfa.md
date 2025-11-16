---
description: Configure multi-factor authentication with TOTP/SMS and backup codes
argument-hint: none
allowed-tools: Task, AskUserQuestion, Read
---

**Arguments**: $ARGUMENTS

Goal: Configure multi-factor authentication (MFA) with TOTP, SMS, and backup codes

Core Principles:
- Ask about MFA methods before implementation
- Follow Clerk MFA best practices
- Integrate with existing authentication setup
- Ensure secure session handling

Phase 1: Discovery
Goal: Understand project structure and existing authentication

Actions:
- Check for existing Clerk configuration
- Identify framework (Next.js, React, etc.)
- Load relevant configuration files
- Example: @package.json
- Verify Clerk packages are installed

Phase 2: Requirements Gathering
Goal: Understand MFA needs and preferences

Actions:

Use AskUserQuestion to gather:

Question 1: "Which MFA methods do you want to support?"
Options:
- "TOTP only" - Time-based one-time passwords (authenticator apps)
- "SMS only" - SMS-based verification codes
- "Both TOTP and SMS" - Give users choice of methods
- "TOTP with SMS fallback" - Preferred method with backup

Question 2: "Should MFA be optional or enforced?"
Options:
- "Optional" - Users can choose to enable MFA
- "Enforced for all users" - Required for account security
- "Enforced for admin users only" - Role-based requirement

Question 3: "Do you need backup codes for account recovery?"
Options:
- "Yes" - Generate recovery codes for MFA bypass
- "No" - Skip backup codes feature

Question 4: "What UI framework are you using?"
Options:
- "shadcn/ui" - Use shadcn/ui components
- "Custom CSS" - Build custom styled components
- "Tailwind CSS" - Use Tailwind utility classes
- "Other" - Specify your framework

Phase 3: Implementation
Goal: Configure MFA with specialist agent

Actions:

Task(description="Configure MFA", subagent_type="clerk:clerk-mfa-specialist", prompt="You are the clerk-mfa-specialist agent. Configure multi-factor authentication for this project.

MFA Methods: [Answer from Question 1]
Enforcement Policy: [Answer from Question 2]
Backup Codes: [Answer from Question 3]
UI Framework: [Answer from Question 4]

Requirements:
- Set up TOTP authentication if requested (QR codes, manual entry)
- Configure SMS authentication if requested (phone verification)
- Implement backup code generation and storage if requested
- Create MFA enrollment UI components
- Build MFA verification flow components
- Add MFA settings management page
- Implement session security with MFA
- Configure enforcement policies based on requirements
- Add proper error handling and validation
- Follow Clerk MFA best practices
- Integrate with existing Clerk authentication

Expected output:
- MFA configuration files
- TOTP/SMS setup components
- MFA verification components
- Settings management UI
- Backup code generation and display
- Documentation for setup and usage")

Phase 4: Summary
Goal: Confirm integration and provide next steps

Actions:
- Summarize what was configured
- List files created/modified
- Provide setup instructions:
  - Environment variables needed (if any)
  - Clerk Dashboard configuration steps
  - MFA provider setup (SMS service, etc.)
- Highlight key features:
  - MFA methods enabled
  - Enforcement policy configured
  - UI components created
  - Backup codes (if enabled)
- Suggest next steps:
  - Test MFA enrollment flow
  - Test MFA verification flow
  - Test backup code recovery (if enabled)
  - Configure production SMS provider (if using SMS)
  - Review security settings in Clerk Dashboard
