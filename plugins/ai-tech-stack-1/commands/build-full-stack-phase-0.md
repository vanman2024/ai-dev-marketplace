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

Goal: Establish dev lifecycle foundation BEFORE implementation - clarify requirements, plan architecture, create specs, verify environment, setup git hooks.

Core Principles:
- Clarify what we're building through interactive questions
- Plan architecture and roadmap before coding
- Create comprehensive specifications
- Verify development environment
- Setup git hooks for security
- Prepare for implementation phases

Phase 1: Clarification
Goal: Understand what we're building through interactive questions

Actions:
- Update .ai-stack-config.json to track phase 0
- Check if this is new or existing project: !{bash test -d specs && echo "existing" || echo "new"}
- If NEW project:
  - Ask user clarifying questions with AskUserQuestion:
    - What does $ARGUMENTS do? (main purpose)
    - Key features needed? (list 3-5 core features)
    - Target users? (who will use this)
    - Any specific requirements? (tech constraints, integrations)
  - Save clarification responses to .ai-stack-config.json
  - Mark clarification complete
- If EXISTING project:
  - Load existing specs
  - Skip to Phase 3 (Detection)

Phase 2: Planning & Architecture
Goal: Create comprehensive project plan, architecture, and specifications

Actions:
- Execute comprehensive planning immediately:
  !{slashcommand /planning:init-project $ARGUMENTS}
- This creates ALL specifications based on clarification from Phase 1:
  - Multiple feature specs in specs/ directory
  - Complete requirements documentation
  - Task breakdowns for each feature
- Execute architecture design:
  !{slashcommand /planning:architecture design $ARGUMENTS}
- This creates:
  - System architecture diagrams (mermaid)
  - Component relationships
  - Data flow documentation
  - Infrastructure design
- Execute roadmap creation:
  !{slashcommand /planning:roadmap}
- This creates:
  - Development timeline
  - Phase milestones
  - Gantt chart
- Execute decision documentation:
  !{slashcommand /planning:decide "AI Tech Stack 1 Architecture"}
- This creates ADRs for:
  - Framework choices (Next.js, FastAPI)
  - Database selection (Supabase)
  - AI SDK choices (Vercel AI SDK, Mem0)
- Verify: !{bash test -d specs && test -d docs/architecture && test -d docs/decisions && echo "✅ Planning complete" || echo "❌ Planning failed"}
- Mark planning complete

Phase 3: Project Detection (Existing Projects Only)
Goal: Detect existing project structure and tech stack

Actions:
- Check if existing project: !{bash test -f package.json -o -f requirements.txt && echo "existing" || echo "new"}
- If existing project:
  - Execute project detection: !{slashcommand /foundation:detect $ARGUMENTS}
  - This populates .claude/project.json with detected stack
  - Verify detected stack matches AI Tech Stack 1
- If new project:
  - Create .claude/project.json manually with AI Tech Stack 1 config
  - Skip detection
- Mark detection complete

Phase 4: Environment Verification
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

Phase 5: Git Hooks Setup
Goal: Install security and validation git hooks

Actions:
- Execute git hooks setup: !{slashcommand /foundation:hooks-setup}
- This installs:
  - pre-commit: Secret scanning (prevents .env commits)
  - commit-msg: Commit message validation
  - pre-push: Security checks
- Verify: !{bash test -d .git/hooks && echo "✅ Hooks installed" || echo "❌ No git repo"}
- Mark git hooks complete

Phase 6: MCP Configuration Note
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

Phase 7: Summary Phase 0
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

  - Requirements clarified through interactive questions
  - Comprehensive planning (specs, architecture, roadmap, ADRs)
  - Project detected/initialized
  - Environment verified (Node, Python, tools)
  - Git hooks installed (security, validation)
  - MCP servers documented (configured in plugins)

  Ready for Phase 1: Implementation
  Run: /ai-tech-stack-1:build-full-stack-phase-1

  Time: ~15-20 minutes

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 0
