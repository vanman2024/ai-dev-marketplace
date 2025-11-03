---
description: "Phase 0: Dev Lifecycle Foundation - Project detection, specs, environment setup, git hooks"
argument-hint: [app-name]
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*)
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

Goal: Establish dev lifecycle foundation BEFORE implementation - detect project, create specs, verify environment, setup git hooks.

Core Principles:
- Detect existing project structure or start from scratch
- Create/validate specifications
- Verify development environment
- Setup git hooks for security
- Prepare for implementation phases

Phase 1: Project Detection
Goal: Detect existing project structure and tech stack

Actions:
- Update .ai-stack-config.json to track phase 0
- Execute project detection immediately:
  !{slashcommand /foundation:detect $ARGUMENTS}
- This populates .claude/project.json with detected stack
- Verify: !{bash test -f .claude/project.json && echo "✅ Project detected" || echo "⚠️  New project"}
- Mark detection complete

Phase 2: Specification Management
Goal: Create or validate project specifications

Actions:
- Check for existing specs: !{bash test -d specs && echo "Found" || echo "Creating"}
- If no specs exist:
  - Execute spec creation: !{slashcommand /planning:spec create $ARGUMENTS}
  - This creates specs/ directory and initial spec
- If specs exist:
  - Execute spec list: !{slashcommand /planning:spec list}
  - Display existing specs
  - Ask user which spec to use for this build
- Load selected spec into context
- Store spec-id in .ai-stack-config.json
- Mark specs complete

Phase 3: Environment Verification
Goal: Verify all required development tools are installed

Actions:
- Execute environment check: !{slashcommand /foundation:env-check --fix}
- This verifies:
  - Node.js (v18+ for Next.js 15)
  - Python (v3.9+ for FastAPI)
  - npm/pip package managers
  - Git
  - Required CLIs (vercel, fly, supabase)
- If tools missing: Install them automatically with --fix flag
- Verify: !{bash node --version && python --version && npm --version && echo "✅ Environment ready" || echo "❌ Missing tools"}
- Mark environment complete

Phase 4: Git Hooks Setup
Goal: Install security and validation git hooks

Actions:
- Execute git hooks setup: !{slashcommand /foundation:hooks-setup}
- This installs:
  - pre-commit: Secret scanning (prevents .env commits)
  - commit-msg: Commit message validation
  - pre-push: Security checks
- Verify: !{bash test -d .git/hooks && echo "✅ Hooks installed" || echo "❌ No git repo"}
- Mark git hooks complete

Phase 5: MCP Configuration Note
Goal: Document MCP server approach

Actions:
- Note in .ai-stack-config.json:
  - MCP servers pre-configured in plugin .mcp.json files
  - Users add API keys per-project in .env files
  - No dynamic MCP server creation during orchestration
  - Plugins used: nextjs-frontend, supabase, mem0 (have .mcp.json)
- Document required environment variables:
  - SUPABASE_URL (required)
  - SUPABASE_ANON_KEY (required)
  - MEM0_API_KEY (optional)
  - CONTEXT7_API_KEY (optional)
  - FIGMA_ACCESS_TOKEN (optional)
- Create .env.example with placeholders
- Mark MCP note complete

Phase 6: Summary Phase 0
Goal: Save state and prepare for Phase 1

Actions:
- Update .ai-stack-config.json:
  - phase0Complete: true
  - phase: 0
  - appName: $ARGUMENTS
  - timestamp: current time
  - nextPhase: "Phase 1 - Foundation (Next.js + FastAPI + Supabase)"
- Display summary:
  ✅ Phase 0 Complete: Dev Lifecycle Foundation

  - Project detected/initialized
  - Specs created/validated
  - Environment verified (Node, Python, tools)
  - Git hooks installed (security, validation)
  - MCP servers documented (configured in plugins)

  Ready for Phase 1: Implementation
  Run: /ai-tech-stack-1:build-full-stack-phase-1

  Time: ~10 minutes

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 0
