---
description: Validate Clerk configuration, test auth flows, and audit security
argument-hint: none
allowed-tools: Task, Read, Bash
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

Goal: Validate complete Clerk authentication setup including configuration, security, and auth flows

Core Principles:
- Validate configuration completeness
- Test authentication flows
- Audit security implementation
- Provide actionable recommendations

Phase 1: Discovery
Goal: Identify Clerk configuration and project structure

Actions:
- Detect project type and framework
- Locate Clerk configuration files
- Identify environment variables
- Example: !{bash ls .env* package.json next.config.js 2>/dev/null}

Phase 2: Configuration Check
Goal: Verify Clerk setup exists

Actions:
- Check for Clerk provider configuration
- Verify environment variables are defined
- Locate auth-related components
- Load key configuration files for context

Phase 3: Validation
Goal: Execute comprehensive Clerk validation

Actions:

Task(description="Validate Clerk setup", subagent_type="clerk:clerk-validator", prompt="You are the clerk-validator agent. Validate the complete Clerk authentication setup.

Context: Project detected at current directory

Validation Focus:
- Configuration completeness (API keys, environment variables)
- Component implementation (ClerkProvider, auth components)
- Security implementation (middleware, route protection, RLS)
- Auth flow testing (sign in, sign up, webhooks)
- Best practices compliance

Expected output:
1. Configuration validation report (pass/fail for each check)
2. Security audit findings with severity levels
3. Auth flow test results
4. List of issues with specific file locations and line numbers
5. Actionable recommendations for fixes

Deliverable: Comprehensive validation report with prioritized action items")

Wait for validation to complete.

Phase 4: Summary
Goal: Present validation results

Actions:
- Display validation report organized by:
  - CRITICAL issues (security vulnerabilities, broken auth)
  - WARNINGS (incomplete configuration, missing best practices)
  - INFO (optimization suggestions, documentation gaps)
- Highlight specific files and lines that need attention
- Provide next steps for resolving issues
- Suggest running specific fix commands if available
