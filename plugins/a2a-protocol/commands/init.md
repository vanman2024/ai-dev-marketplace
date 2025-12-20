---
description: Initialize A2A Protocol project with SDK setup and configuration
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Initialize A2A Protocol project with SDK installation, configuration files, and basic setup for agent-to-agent communication.

Core Principles:
- Detect existing project structure before assuming
- Ask clarifying questions when requirements are unclear
- Use a2a-setup agent for autonomous implementation
- Validate setup after completion

Phase 1: Discovery
Goal: Understand project context and requirements

Actions:
- Parse $ARGUMENTS for project name if provided
- Detect if this is an existing project or new project
- Check for package.json to identify Node.js/TypeScript setup
- Example: !{bash ls package.json tsconfig.json 2>/dev/null}
- Load existing configuration if present
- Example: @package.json

Phase 2: Requirements Gathering
Goal: Clarify setup preferences

Actions:
- If project details are unclear, use AskUserQuestion to gather:
  - Is this a new project or adding to existing?
  - Which programming language? (TypeScript/JavaScript/Python)
  - What type of agents will be built? (simple/complex/both)
  - Any specific A2A Protocol features needed? (authentication/encryption/discovery)
  - Deployment target? (local/cloud/both)
- Summarize understanding and confirm approach

Phase 3: Project Analysis
Goal: Understand current codebase structure

Actions:
- If existing project, analyze current structure
- Find relevant configuration files
- Example: !{bash find . -maxdepth 3 -name "*.json" -o -name "*.yaml" 2>/dev/null | head -10}
- Identify where A2A Protocol components should be added
- Check for conflicting dependencies

Phase 4: Implementation
Goal: Execute setup with a2a-setup agent

Actions:

Task(description="Initialize A2A Protocol SDK", subagent_type="a2a-setup", prompt="You are the a2a-setup agent. Initialize A2A Protocol project for $ARGUMENTS.

Project Context: Based on discovery in Phases 1-3

Requirements:
- Install A2A Protocol SDK and dependencies
- Create configuration files (.env.example, a2a.config.json)
- Set up project structure (agents/, protocols/, utils/)
- Generate example agent implementations
- Configure authentication and security settings
- Create README with setup instructions

Security Compliance:
- Use placeholders for all API keys and secrets
- Create .env.example with placeholder values only
- Add .env to .gitignore
- Document where to obtain real credentials

Expected output: Complete A2A Protocol project initialization with all configuration files, example code, and documentation.")

Phase 5: Validation
Goal: Verify setup is correct

Actions:
- Check that all expected files were created
- Example: !{bash ls -la a2a.config.json .env.example package.json 2>/dev/null}
- Verify dependencies are installed
- Example: !{bash npm list @a2a-protocol/sdk 2>/dev/null || echo "Not installed"}
- Run type checking if TypeScript project
- Example: !{bash npx tsc --noEmit 2>/dev/null || echo "No TypeScript"}

Phase 6: Summary
Goal: Report what was accomplished

Actions:
- Summarize changes made:
  - Files created
  - Dependencies installed
  - Configuration generated
- Display next steps:
  - Fill in real API keys in .env
  - Review a2a.config.json settings
  - Explore example agents
  - Run first agent with npm start
- Show helpful commands for getting started
