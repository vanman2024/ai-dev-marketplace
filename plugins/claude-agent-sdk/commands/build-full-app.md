---
description: Build a complete production-ready Claude Agent SDK application from scratch by chaining all feature commands together
argument-hint: [project-name]
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

Goal: Build a complete production-ready Claude Agent SDK application from scratch with all features including streaming, sessions, MCP, tools, subagents, permissions, hosting, and tracking capabilities.

Core Principles:
- Track progress with TodoWrite throughout the build
- Ask clarifying questions early to understand requirements
- Chain commands sequentially to build incrementally
- Verify each phase before proceeding to the next

Phase 1: Discovery
Goal: Understand what needs to be built

Actions:
- Create todo list with all build phases using TodoWrite
- Parse $ARGUMENTS for project name
- If unclear or no project name provided, use AskUserQuestion to gather:
  - What's the project name?
  - Language preference? (TypeScript or Python)
  - What's the agent's purpose?
  - Which features do you want? (All or subset)

Phase 2: Scaffold Project
Goal: Create minimal project structure

Actions:

Invoke the new-app command to create the initial scaffold.

SlashCommand: /agent-sdk-dev:new-app $ARGUMENTS

Wait for scaffolding to complete before proceeding.

Phase 3: Add Core Features
Goal: Add streaming and session management

Actions:

Run these commands sequentially (one after another):

SlashCommand: /agent-sdk-dev:add-streaming

Wait for completion, then:

SlashCommand: /agent-sdk-dev:add-sessions

Update TodoWrite to mark these tasks complete.

Phase 4: Add Integration Features
Goal: Add MCP and custom tools

Actions:

SlashCommand: /agent-sdk-dev:add-mcp

Wait for completion, then:

SlashCommand: /agent-sdk-dev:add-custom-tools

Wait for completion before proceeding.

Phase 5: Add Advanced Features
Goal: Add subagents and permissions

Actions:

SlashCommand: /agent-sdk-dev:add-subagents

Wait for completion, then:

SlashCommand: /agent-sdk-dev:add-permissions

Wait for completion before proceeding.

Phase 6: Add Deployment Features
Goal: Add hosting configuration

Actions:

SlashCommand: /agent-sdk-dev:add-hosting

Wait for completion before proceeding.

Phase 7: Add Enhancement Features
Goal: Add system prompts, slash commands, skills, and plugins

Actions:

SlashCommand: /agent-sdk-dev:add-system-prompts

Wait for completion, then:

SlashCommand: /agent-sdk-dev:add-slash-commands

Wait for completion, then:

SlashCommand: /agent-sdk-dev:add-skills

Wait for completion, then:

SlashCommand: /agent-sdk-dev:add-plugins

Wait for completion before proceeding.

Phase 8: Add Tracking Features
Goal: Add cost and todo tracking

Actions:

SlashCommand: /agent-sdk-dev:add-cost-tracking

Wait for completion, then:

SlashCommand: /agent-sdk-dev:add-todo-tracking

Wait for completion before proceeding.

Phase 9: Verification
Goal: Ensure everything works together

Actions:
- Determine project language from initial setup
- If TypeScript: Run type checking
  Example: !{bash cd $ARGUMENTS && npx tsc --noEmit}
- If Python: Run type checking
  Example: !{bash cd $ARGUMENTS && python -m mypy . --ignore-missing-imports}
- Verify all features are properly integrated

Phase 10: Summary
Goal: Document the complete build

Actions:
- Mark all todos as complete using TodoWrite
- List all features implemented:
  - Core: Streaming, Sessions
  - Integration: MCP, Custom Tools
  - Advanced: Subagents, Permissions
  - Deployment: Hosting
  - Enhancement: System Prompts, Slash Commands, Skills, Plugins
  - Tracking: Cost Tracking, Todo Tracking
- Show project structure
- List environment variables needed (ANTHROPIC_API_KEY)
- Provide next steps (testing, deployment, customization)
