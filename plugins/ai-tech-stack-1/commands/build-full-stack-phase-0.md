---
description: "Phase 0: Dev Lifecycle Foundation - Project detection, specs, environment setup, git hooks"
argument-hint: [app-name]
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

Goal: Establish dev lifecycle foundation BEFORE implementation - read wizard output (requirements, architecture, specs), verify environment, setup git hooks.

Core Principles:
- Read wizard planning output (docs/requirements/, docs/architecture/, docs/ROADMAP.md, specs/)
- Verify development environment
- Setup git hooks for security
- Prepare for implementation phases
- NO planning/clarification here - wizard handles that

Phase 1: Read Wizard Output
Goal: Load planning documentation created by /planning:wizard

Actions:
- Update .ai-stack-config.json to track phase 0
- Check for wizard output: !{bash test -d docs/requirements && test -d docs/architecture && test -f docs/ROADMAP.md && echo "wizard-complete" || echo "run-wizard-first"}
- If wizard output exists:
  - Read requirements: @docs/requirements/*/01-initial-request.md
  - Read extracted data: @docs/requirements/*/.wizard/extracted-requirements.json
  - Read Q&A: @docs/requirements/*/02-wizard-qa.md
  - Read architecture: @docs/architecture/README.md
  - Read roadmap: @docs/ROADMAP.md
  - Count specs: !{bash ls -d specs/features/*/ 2>/dev/null | wc -l || echo "0"}
  - Mark wizard output loaded
- If wizard output missing:
  - Display: "❌ Run /planning:wizard first to create requirements, architecture, and specs"
  - Exit: Cannot proceed without wizard output

Phase 2: Validate All Specs
Goal: Ensure all specs are complete before worktree creation

Actions:
- Execute spec validation: !{slashcommand /planning:analyze-project}
- This launches spec-analyzer agents in parallel for each spec
- Outputs: gaps-analysis.json with completeness scores and recommendations
- Verify validation completed: !{bash test -f gaps-analysis.json && echo "✅ Validation complete" || echo "❌ Validation failed"}
- Display results: !{bash cat gaps-analysis.json | jq '{total_specs, avg_completeness, critical_gaps, incomplete_specs}'}
- Mark validation complete

Phase 3: Bulk Worktree Creation + Mem0 Registration
Goal: Create isolated git worktrees for ALL agents across ALL specs and register in Mem0

Actions:
- Count specs: !{bash ls -d specs/*/ | wc -l}
- Display: "Creating worktrees for X specs..."

- FOR EACH spec in specs/, run supervisor:
  Example for 5 specs:
  !{slashcommand /supervisor:init 001-user-auth}
  !{slashcommand /supervisor:init 002-product-catalog}
  !{slashcommand /supervisor:init 003-shopping-cart}
  !{slashcommand /supervisor:init 004-checkout-flow}
  !{slashcommand /supervisor:init 005-order-tracking}

- Each /supervisor:init call:
  - Reads layered-tasks.md for that spec
  - Creates worktrees for all agents (@claude, @copilot, @qwen, @gemini, @codex)
  - Registers in Mem0 "worktrees" collection automatically
  - Stores: worktree paths, branches, agent assignments, dependencies

- Verify creation: !{bash git worktree list}
- Count worktrees: !{bash git worktree list | grep -c "agent-"}
- Update config: !{bash jq '.worktreesSetup = true | .worktreeCount = '$(git worktree list | grep -c "agent-")'' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Display: "✅ X worktrees created and registered in Mem0"
- Mark worktree setup complete

Phase 4: Project Detection (Existing Projects Only)
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

Phase 5: Environment Verification
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

Phase 6: GitHub Repository Initialization
Goal: Create GitHub repository with comprehensive security configuration

Actions:
- Execute GitHub init: !{slashcommand /foundation:github-init $ARGUMENTS --private}
- This creates and configures:
  - GitHub repository (private by default)
  - Comprehensive .gitignore (protects .mcp.json, .env, secrets, keys)
  - Issue and PR templates
  - Branch protection rules (require PR reviews, block force push)
  - Git hooks (pre-commit, commit-msg, pre-push)
  - GitHub Actions security workflow
- CRITICAL: .gitignore template protects:
  - .mcp.json (all variants - CAN CONTAIN API KEYS)
  - .env* (all environment files)
  - credentials.json, secrets/, service-account*.json
  - *.key, *.pem (private keys)
- Verify: !{bash gh repo view --json nameWithOwner,url}
- Mark GitHub init complete

Phase 7: Verify Git Hooks Installed
Goal: Confirm git hooks from GitHub init are active

Actions:
- Verify hooks: !{bash test -x .git/hooks/pre-commit && test -x .git/hooks/commit-msg && echo "✅ Hooks active" || echo "❌ Hooks missing"}
- Verify workflow: !{bash test -f .github/workflows/security-scan.yml && echo "✅ Security workflow ready" || echo "❌ Workflow missing"}
- Mark verification complete

Phase 8: MCP Configuration Note
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

Phase 9: Doppler Secret Management Setup
Goal: Setup Doppler for centralized secret management and key rotation

Actions:
- Execute Doppler setup: !{slashcommand /foundation:doppler-setup $ARGUMENTS}
- This will:
  - Check if Doppler CLI installed, install if needed
  - Authenticate user (prompt for browser login if needed)
  - Create Doppler project: $ARGUMENTS
  - Create environments: dev, dev_personal, stg, prd
  - Import existing .env secrets to Doppler dev environment
  - Create bidirectional sync script: doppler-sync.sh
  - Add npm/package.json scripts for Doppler integration
  - Generate DOPPLER.md documentation
- Display: "✓ Doppler setup complete"
- Show quick commands:
  - `doppler run -- npm run dev` (run with Doppler secrets)
  - `doppler secrets` (view all secrets)
  - `./doppler-sync.sh from-doppler dev` (sync Doppler → .env)
  - `./doppler-sync.sh to-doppler dev` (sync .env → Doppler)
  - Dashboard: https://dashboard.doppler.com
- Update .ai-stack-config.json:
  - dopplerEnabled: true
  - dopplerProject: $ARGUMENTS
- Mark Doppler setup complete

Phase 10: Summary Phase 0
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

  Wizard Output Loaded:
  - Requirements: docs/requirements/ (project description, extracted requirements, Q&A)
  - Architecture: docs/architecture/ (frontend, backend, data, AI, security, integrations)
  - ADRs: docs/adr/ (architectural decision records)
  - Roadmap: docs/ROADMAP.md (timeline, milestones, priorities)
  - Specs: specs/features/ (custom feature specifications)

  Infrastructure Setup:
  - Specs validated for completeness (gaps-analysis.json)
  - Worktrees created for parallel agent development (git worktree list)
  - Agents registered in Mem0 for coordination (~/.claude/mem0-chroma/)
  - Project detected/initialized (.claude/project.json)
  - Environment verified (Node, Python, tools)
  - GitHub repository created with security templates ✓
  - Comprehensive .gitignore (protects .mcp.json, .env, secrets) ✓
  - Git hooks installed (pre-commit, commit-msg, pre-push) ✓
  - GitHub Actions security scanning enabled ✓
  - Branch protection rules configured ✓
  - MCP servers documented (configured in plugins)
  - Secret management: Doppler enabled ✓

  Ready for Phase 1: Implementation
  Run: /ai-tech-stack-1:build-full-stack-phase-1

  Note: Run /planning:wizard FIRST if you haven't created requirements/architecture yet

  Agent Coordination:
  - Query Mem0 for worktree locations: python register-worktree.py query --query "where does copilot work?"

  Doppler Commands:
  - Run with secrets: doppler run -- npm run dev
  - View secrets: doppler secrets
  - Sync to .env: ./doppler-sync.sh from-doppler dev
  - Sync from .env: ./doppler-sync.sh to-doppler dev
  - Dashboard: https://dashboard.doppler.com/workplace/projects/$ARGUMENTS

  Time: ~10-15 minutes (reads wizard output + infrastructure setup)

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 0
