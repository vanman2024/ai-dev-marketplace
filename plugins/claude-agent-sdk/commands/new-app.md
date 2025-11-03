---
description: Create and setup a new Claude Agent SDK application
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, Skill
---
## Available Skills

This commands has access to the following skills from the claude-agent-sdk plugin:

- **fastmcp-integration**: Examples and patterns for integrating FastMCP Cloud servers with Claude Agent SDK using HTTP transport\n- **sdk-config-validator**: Validates Claude Agent SDK configuration files, environment setup, dependencies, and project structure\n
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
- Load Claude Agent SDK documentation for reference:
  @claude-agent-sdk-documentation.md
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

Invoke the claude-agent-setup agent to create the project.

The agent should:
- Create project directory structure
- Initialize package manager (npm/pip)
- Install Claude Agent SDK with latest version
- Generate starter code with proper SDK usage
- Create .env.example with API key placeholder
- Add .gitignore for security

Provide the agent with:
- Context: User's language choice, project name, agent type
- Target: $ARGUMENTS (project name)
- Expected output: Fully initialized project ready to run

Phase 5: Verification
Goal: Validate the setup is correct

Actions:
- Invoke the appropriate verifier agent based on language:
  - TypeScript: Invoke the claude-agent-verifier-ts agent
  - Python: Invoke the claude-agent-verifier-py agent
- Check verifier output for any issues
- If TypeScript: Run type checking
  !{bash cd $ARGUMENTS && npx tsc --noEmit}
- Address any issues found

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
