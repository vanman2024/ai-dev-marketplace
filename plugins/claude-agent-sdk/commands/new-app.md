---
description: Create and setup a new Claude Agent SDK application
argument-hint: [project-name]
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

!{skill skill-name}

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

Goal: Create and setup a new Claude Agent SDK application with TypeScript or Python support

Core Principles:
- Ask before acting - gather language preference and requirements first
- Use latest SDK versions - check npm/PyPI for current releases
- Verify code works - run type checking before completing

Phase 1: Discovery
Goal: Gather project requirements and preferences

Actions:
- Parse $ARGUMENTS for project name (if provided)
- Use AskUserQuestion to gather:
  - Language preference: TypeScript or Python?
  - Project name (if not in $ARGUMENTS)
  - Agent type/purpose
  - Starting point preference (minimal, basic, or specific example)
  - Package manager preference (npm/yarn/pnpm for TS, pip/poetry for Python)

Phase 2: Analysis
Goal: Load SDK documentation and determine setup approach

Actions:
- Read SDK documentation: ~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/claude-agent-sdk/docs/sdk-documentation.md
- Check for latest SDK versions
- Identify required dependencies based on language choice
- Determine project structure needs

Phase 3: Planning
Goal: Design the project setup approach

Actions:
- Outline project structure:
  - TypeScript: package.json, tsconfig.json, src/index.ts, .env.example
  - Python: requirements.txt, main.py, .env.example
- Plan SDK installation command
- Identify starter code to generate
- Confirm approach with user

Phase 4: Implementation
Goal: Execute project setup with specialized agent

Actions:

Task(description="Setup Claude Agent SDK project", subagent_type="claude-agent-sdk:claude-agent-setup", prompt="You are the claude-agent-setup agent. Create a new Claude Agent SDK project for $ARGUMENTS.

Context from user discovery:
- Language: [TypeScript or Python from Phase 1]
- Project name: $ARGUMENTS
- Agent type: [Purpose from Phase 1]
- Package manager: [Preference from Phase 1]

Create the complete project:
- Project directory structure
- Initialize package manager (npm/pip)
- Install Claude Agent SDK with latest version
- Generate starter code with proper SDK usage
- Create .env.example with API key placeholder
- Add .gitignore for security
- Create README.md with setup instructions

Expected output: Fully initialized project ready to run")

Phase 5: Verification
Goal: Validate the setup is correct

Actions:

Based on language choice from Phase 1:

**If TypeScript:**

Task(description="Verify TypeScript setup", subagent_type="claude-agent-sdk:claude-agent-verifier-ts", prompt="Verify the TypeScript Claude Agent SDK setup at $ARGUMENTS.

Check:
- Package.json has correct SDK dependency
- tsconfig.json is properly configured
- Starter code follows SDK patterns
- .env.example exists with placeholders
- .gitignore protects secrets

Report any issues found.")

Run type checking:
!{bash cd $ARGUMENTS && npx tsc --noEmit}

**If Python:**

Task(description="Verify Python setup", subagent_type="claude-agent-sdk:claude-agent-verifier-py", prompt="Verify the Python Claude Agent SDK setup at $ARGUMENTS.

Check:
- requirements.txt has correct SDK package (claude-agent-sdk)
- Starter code follows SDK patterns
- .env.example exists with placeholders
- .gitignore protects secrets
- Virtual environment is set up

Report any issues found.")

Address any issues found before proceeding

Phase 6: Summary
Goal: Provide next steps to user

Actions:
- Summarize what was created:
  - Project structure
  - SDK version installed
  - Files generated
- Provide instructions:
  - How to set API key in .env
  - How to run the agent
  - Links to SDK documentation
- Suggest next steps:
  - Customize system prompt
  - Add custom tools via MCP
  - Create subagents
- Point to examples:
  - Basic usage: `examples/python/basic-query.py`
  - FastMCP Cloud: `examples/python/fastmcp-cloud-http.py`
- Common pitfalls to avoid:
  - ✅ Use `claude-agent-sdk` NOT `anthropic-agent-sdk`
  - ✅ Use `"type": "http"` for FastMCP Cloud, NOT `"sse"`
  - ✅ Pass API keys via `env` parameter in `ClaudeAgentOptions`
