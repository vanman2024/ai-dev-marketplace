---
description: Add skills to Claude Agent SDK application
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, Skill
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

Goal: Add skill definitions to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for skill patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK skills documentation:
  @claude-agent-sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files
- Ask user what skills to add

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if skills are already defined
- Identify query() function configuration
- Determine language (TypeScript or Python)

Phase 3: Planning
Goal: Design skills

Actions:
- Define skill names and capabilities
- Plan skill implementation logic
- Determine skill invocation patterns
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add skills with agent

Actions:

Invoke the claude-agent-features agent to add skills.

The agent should:
- Fetch skills documentation: https://docs.claude.com/en/api/agent-sdk/skills
- Create skill definitions
- Implement skill handler functions
- Add skill registration in query() calls
- Add proper error handling for skills

Provide the agent with:
- Context: Project language, structure, and desired skills
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with skill definitions

Phase 5: Review
Goal: Verify skills work correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that skill patterns match SDK documentation
- Verify skills can be invoked properly

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize skills added
- Show example skill usage
- Link to SDK skills documentation
- Suggest testing with skill invocations
