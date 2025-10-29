---
description: Resume AI stack deployment from saved state when context becomes too large
argument-hint: none
allowed-tools: SlashCommand(*), Read(*), Write(*), Bash(*), TodoWrite(*)
---

**Arguments**: $ARGUMENTS

Goal: Resume deployment from .deployment-config.json with fresh context to prevent infinite scrolling.

Core Principles:
- Read saved state from .deployment-config.json
- Continue from last completed phase
- Fresh context prevents hang
- Reuse same orchestration logic

Phase 1: Load State
Goal: Read deployment configuration and determine where to resume

Actions:
- Check if .deployment-config.json exists:
  !{bash test -f .deployment-config.json && echo "Found" || echo "Not found"}

- If not found:
  - Display error: "No deployment state found. Run /ai-tech-stack-1:build-full-stack first"
  - STOP

- Load state file:
  @.deployment-config.json

- Parse current phase and determine what's complete vs pending

Phase 2: Resume Deployment
Goal: Continue from next phase with fresh context

Actions:
- Create todo list for remaining phases using TodoWrite

- Based on phase number in state file, jump to appropriate phase:

  If phase <= 1: SlashCommand: /ai-tech-stack-1:build-full-stack (start from beginning)

  If phase == 2: Continue from Phase 3 (Database)
  - SlashCommand: /supabase:init-ai-app
  - Wait for completion
  - Then continue to Phase 4-8

  If phase == 3: Continue from Phase 4 (AI Features)
  - SlashCommand: /vercel-ai-sdk:add-streaming
  - Wait for completion
  - Then continue to Phase 5-8

  If phase == 4: Continue from Phase 5 (Memory)
  - SlashCommand: /mem0:init-oss
  - Wait for completion
  - Then continue to Phase 6-8

  If phase == 5: Continue from Phase 6 (MCP Tools)
  - If MCP selected: SlashCommand: /fastmcp:new-server
  - Wait for completion
  - Then continue to Phase 7-8

  If phase == 6: Continue from Phase 7 (Validation)
  - Run validation checks
  - Then continue to Phase 8

  If phase >= 7:
  - Display: "Deployment already complete or in final phase"
  - Show summary from DEPLOYMENT-SUMMARY.md if exists

- Update .deployment-config.json as each phase completes

Phase 3: Summary
Goal: Confirm resumption successful

Actions:
- Mark remaining todos complete
- Display: "✅ Deployment resumed successfully from Phase [X]"
- If complete: @DEPLOYMENT-SUMMARY.md

## Usage

When context becomes too large during build-full-stack:
1. State automatically saved to .deployment-config.json
2. Run: /ai-tech-stack-1:resume
3. Continues from last completed phase with fresh context
