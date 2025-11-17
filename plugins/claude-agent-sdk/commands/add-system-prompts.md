---
description: Add system prompts configuration to Claude Agent SDK application
argument-hint: [project-path]
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

## Available Skills

This commands has access to the following skills from the claude-agent-sdk plugin:

- **fastmcp-integration**: Examples and patterns for integrating FastMCP Cloud servers with Claude Agent SDK using HTTP transport
- **sdk-config-validator**: Validates Claude Agent SDK configuration files, environment setup, dependencies, and project structure

**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

---



## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Add system prompts and agent behavior configuration to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for system prompt patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK system prompts documentation:
  Read SDK documentation: ~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/claude-agent-sdk/docs/sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files
- Ask user about agent behavior requirements

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if system prompts are already configured
- Identify query() function calls
- Determine language (TypeScript or Python)

Phase 3: Planning
Goal: Design system prompts implementation

Actions:
- Define agent personality and behavior
- Plan system prompt content
- Determine if multiple prompt templates needed
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add system prompts with agent

Actions:

Invoke the claude-agent-features agent to add system prompts.

The agent should:
- Fetch system prompts documentation: https://docs.claude.com/en/api/agent-sdk/system-prompts
- Configure system prompt in query() calls
- Add dynamic prompt generation if needed
- Implement prompt templating
- Add context injection capabilities

Provide the agent with:
- Context: Project language, structure, and behavior requirements
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with system prompt configuration

Phase 5: Review
Goal: Verify system prompts work correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that system prompt patterns match SDK documentation
- Verify prompts are properly applied

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize system prompt capabilities added
- Show example prompt configurations
- Link to SDK system prompts documentation
- Suggest testing with different prompt variations
