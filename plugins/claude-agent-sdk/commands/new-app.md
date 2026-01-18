---
description: Create and setup a new Claude Agent SDK application
argument-hint: [project-name]
---

---
**EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- The phases below are YOUR execution checklist
- YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- Complete ALL phases before considering this command done
- DON't wait for "the command to complete" - YOU complete it by executing the phases
- DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---

## Available Skills

This commands has access to the following skills from the claude-agent-sdk plugin:

- **fastmcp-integration**: Examples and patterns for integrating FastMCP Cloud servers with Claude Agent SDK using HTTP transport
- **sdk-config-validator**: Validates Claude Agent SDK configuration files, environment setup, dependencies, and project structure
- **integration-templates**: Templates for integrating Claude Agent SDK into existing projects

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

Goal: Create and setup a new Claude Agent SDK application OR integrate into an existing project

Core Principles:
- Ask before acting - determine new app vs integration first
- Use latest SDK versions - check npm/PyPI for current releases
- Verify code works - run type checking before completing

---

## Phase 0: Mode Selection

Goal: Determine if user wants a new standalone app or integration into existing project

Actions:
- Use AskUserQuestion to ask:

```
What would you like to do?

Options:
1. Create new standalone app - Creates a fresh project directory with Claude Agent SDK
2. Integrate into existing project - Adds Claude Agent SDK as a service to your current project
```

**Store the answer as MODE (either "new" or "integrate")**

---

## Phase 1: Discovery

Goal: Gather project requirements and preferences

### If MODE = "new" (New Standalone App):

Actions:
- Parse $ARGUMENTS for project name (if provided)
- Use AskUserQuestion to gather:
  - Language preference: TypeScript or Python?
  - Project name (if not in $ARGUMENTS)
  - Agent type/purpose
  - Starting point preference (minimal, basic, or specific example)
  - Package manager preference (npm/yarn/pnpm for TS, pip/poetry for Python)

### If MODE = "integrate" (Existing Project Integration):

Actions:
- Run project detection script to analyze current directory:
  ```bash
  bash ~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/claude-agent-sdk/skills/integration-templates/scripts/detect-project.sh
  ```

- Parse detection output to get:
  - LANGUAGE (typescript/python)
  - FRAMEWORK (bun/express/nextjs/fastapi/etc.)
  - SERVICES_DIR (where services live)
  - ROUTES_DIR (where routes live)
  - CODE_STYLE (functional/class-based)
  - HAS_BARREL (true/false)
  - ENTRY_POINT (server entry file)

- Present findings to user:
  ```
  Project Analysis:
    Language: [LANGUAGE]
    Framework: [FRAMEWORK]
    Services Directory: [SERVICES_DIR]
    Routes Directory: [ROUTES_DIR]
    Code Style: [CODE_STYLE]
    Entry Point: [ENTRY_POINT]

  Is this correct? If not, please specify the correct paths.
  ```

- Use AskUserQuestion to gather:
  - Service name (default: claude-agent)
  - Which features to include:
    - [ ] Core (execute, types)
    - [ ] Streaming support
    - [ ] Session persistence
  - Confirm or override detected paths

---

## Phase 2: Analysis

Goal: Load SDK documentation and determine setup approach

### For Both Modes:

Actions:
- Read SDK documentation: ~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/claude-agent-sdk/docs/sdk-documentation.md
- Check for latest SDK versions
- Identify required dependencies based on language choice

### Additional for Integration Mode:

- Load integration templates skill:
  ```
  !{skill claude-agent-sdk:integration-templates}
  ```

- Read 1-2 existing service files in SERVICES_DIR to understand coding patterns
- Read 1-2 existing route files in ROUTES_DIR to understand route patterns

---

## Phase 3: Planning

Goal: Design the project setup approach

### If MODE = "new":

Actions:
- Outline project structure:
  - TypeScript: package.json, tsconfig.json, src/index.ts, .env.example
  - Python: requirements.txt, main.py, .env.example
- Plan SDK installation command
- Identify starter code to generate
- Confirm approach with user

### If MODE = "integrate":

Actions:
- Outline files to create:
  ```
  Files to Create:
    [SERVICES_DIR]/[service-name]/
      index.ts (or service.py)    - Main service with execute/stream functions
      types.ts (or schemas.py)    - Request/Response types

    [ROUTES_DIR]/[service-name].ts (or .py) - HTTP endpoints

  Files to Modify:
    package.json (or requirements.txt) - Add SDK dependency
    .env.example - Append ANTHROPIC_API_KEY
    [SERVICES_DIR]/index.ts - Add export (if barrel exists)
  ```

- Select template based on CODE_STYLE:
  - functional → agent-service-functional.ts.template
  - class-based → agent-service-class.ts.template

- Select route template based on FRAMEWORK:
  - bun/hono → agent-routes-bun.ts.template
  - express → agent-routes-express.ts.template
  - fastapi → agent_routes_fastapi.py.template

- Confirm plan with user before proceeding

---

## Phase 4: Implementation

Goal: Execute project setup

### If MODE = "new":

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

### If MODE = "integrate":

Task(description="Integrate Claude Agent SDK into existing project", subagent_type="claude-agent-sdk:project-integrator", prompt="You are the project-integrator agent. Add Claude Agent SDK as a service to the current project.

Detection Results:
- Language: [LANGUAGE]
- Framework: [FRAMEWORK]
- Services Directory: [SERVICES_DIR]
- Routes Directory: [ROUTES_DIR]
- Code Style: [CODE_STYLE]
- Has Barrel Exports: [HAS_BARREL]
- Entry Point: [ENTRY_POINT]

User Preferences:
- Service Name: [service-name from Phase 1]
- Features: [selected features]

Integration Requirements:
1. Add SDK dependency to package.json or requirements.txt
2. Create service files at [SERVICES_DIR]/[service-name]/
3. Create route file at [ROUTES_DIR]/[service-name]
4. Append ANTHROPIC_API_KEY to .env.example (don't overwrite)
5. Update barrel export if HAS_BARREL=true
6. Match existing code patterns exactly

Templates to use (from skills/integration-templates/):
- Service: [selected template based on CODE_STYLE]
- Routes: [selected template based on FRAMEWORK]
- Types: agent-types.ts.template or agent_schemas.py.template

DO NOT modify the entry point file. User will wire routes manually.

Expected output: Service and routes files created, dependency added, ready for manual wiring")

---

## Phase 5: Verification

Goal: Validate the setup is correct

### If MODE = "new":

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

### If MODE = "integrate":

Actions:
- Verify created files exist:
  ```bash
  ls -la [SERVICES_DIR]/[service-name]/
  ls -la [ROUTES_DIR]/[service-name].*
  ```

- Run type checking:
  ```bash
  # TypeScript
  npx tsc --noEmit
  # or
  bun run typecheck

  # Python
  mypy [SERVICES_DIR]/[service-name]/
  ```

- Verify .env.example was updated (not overwritten):
  ```bash
  grep "ANTHROPIC_API_KEY" .env.example
  ```

- Address any type errors before proceeding

---

## Phase 6: Summary

Goal: Provide next steps to user

### If MODE = "new":

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
  - Use `claude-agent-sdk` NOT `anthropic-agent-sdk`
  - Use `"type": "http"` for FastMCP Cloud, NOT `"sse"`
  - Pass API keys via `env` parameter in `ClaudeAgentOptions`

### If MODE = "integrate":

Actions:
- Summarize what was created:
  ```
  Integration Complete!

  Created Files:
    - [SERVICES_DIR]/[service-name]/index.ts
    - [SERVICES_DIR]/[service-name]/types.ts
    - [ROUTES_DIR]/[service-name].ts

  Modified Files:
    - package.json (added @anthropic-ai/claude-agent-sdk)
    - .env.example (added ANTHROPIC_API_KEY)
    - [SERVICES_DIR]/index.ts (added export) [if applicable]
  ```

- Provide wiring instructions:
  ```
  To complete setup:

  1. Install dependencies:
     bun install  # or npm install / pip install -r requirements.txt

  2. Add API key to .env:
     ANTHROPIC_API_KEY=your_key_here

  3. Wire routes in [ENTRY_POINT]:

     // TypeScript (Bun/Hono example):
     import { claudeAgentRoutes } from './routes/[service-name]';
     app.route('/api/agent', claudeAgentRoutes);

     // TypeScript (Express example):
     import { claudeAgentRouter } from './routes/[service-name]';
     app.use('/api/agent', claudeAgentRouter);

     // Python (FastAPI example):
     from api.routes.[service_name] import router as claude_agent_router
     app.include_router(claude_agent_router, prefix="/api/agent", tags=["agent"])

  4. Test the endpoint:
     curl -X POST http://localhost:3000/api/agent/execute \
       -H "Content-Type: application/json" \
       -d '{"prompt": "Hello, agent!"}'
  ```

- Suggest next steps:
  - Add MCP integration: `/claude-agent-sdk:add-mcp`
  - Add streaming: `/claude-agent-sdk:add-streaming`
  - Add sessions: `/claude-agent-sdk:add-sessions`

- Common pitfalls to avoid:
  - Use `claude-agent-sdk` NOT `anthropic-agent-sdk`
  - Use `"type": "http"` for FastMCP Cloud, NOT `"sse"`
  - Remember to wire routes - they're not auto-registered
