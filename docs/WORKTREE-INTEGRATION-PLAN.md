# Worktree Integration Plan for ai-tech-stack-1

## Current Understanding

### How Supervisor Worktrees Work

**From dev-lifecycle-marketplace's supervisor plugin:**

```
/supervisor:init <spec-name>
  ↓
  Reads: specs/<spec-name>/agent-tasks/layered-tasks.md
  ↓
  Invokes: worktree-coordinator agent
  ↓
  For each agent in layered-tasks.md:
    1. Creates branch: agent-{agent-name}-{spec-num}
    2. Creates worktree: ../{project}-{spec-num}-{agent-name}
    3. Registers in Mem0:
       - Worktree location
       - Agent assignments
       - Task list
       - Dependencies (Frontend → Backend)
  ↓
  Agents query Mem0: "Where does frontend-agent work on spec 001?"
  ↓
  Result: Path to worktree
```

**Key Benefits:**
- ✅ **Parallel work without conflicts** - Each agent has isolated directory
- ✅ **Mem0 coordination** - Agents know where others work
- ✅ **Dependency tracking** - Frontend knows Backend must finish API first
- ✅ **Clean merges** - Work isolated, merge when ready

### When Worktrees Are Created (Current Flow)

**Lifecycle Plugin Flow:**
```
Phase 1: /planning:init-project <description>
  └─ Creates: specs/001-feature/, specs/002-feature/, etc.

Phase 2: /planning:spec <action> [spec-name]
  └─ Creates: spec.md, plan.md, tasks.md

Phase 3: MANUAL - User runs /supervisor:init <spec-name>
  └─ Creates: git worktrees for agents in that spec

Phase 4: Agents work in parallel in their worktrees
```

**Problem:** Step 3 is manual and per-spec

---

## Integration with ai-tech-stack-1

### Current ai-tech-stack-1 Flow

```
Phase 0: Dev Lifecycle Foundation
  - /planning:init-project (creates specs/)
  - /foundation:detect
  - /foundation:env-check
  - Sets up git hooks

Phase 1: Foundation
  - /nextjs-frontend:build-full-stack
  - /fastapi-backend:init-ai-app
  - /supabase:init-ai-app

Phase 2: AI Features
  - /openrouter:*
  - /vercel-ai-sdk:*
  - /mem0:*

Phase 3: Integration
  - Wire services
  - Add UI components
  - Deployment configs

Phases 4-9: Testing, deployment, RAG, voice, etc.
```

### Where to Add Worktree Creation

**Option A: Phase 0 (After specs created)**
```
Phase 0:
  1. /planning:init-project <description>
     └─ Creates all specs

  2. For each spec created:
     /supervisor:init <spec-name>
     └─ Creates worktrees for agents in that spec

  3. Continue with /foundation:detect, etc.
```

**Option B: Phase 1 (Before building)**
```
Phase 1:
  1. Load config

  2. For each spec in specs/:
     /supervisor:init <spec-name>
     └─ Creates worktrees for agents

  3. Build foundation (agents work in worktrees)
```

**Option C: On-Demand (Per feature)**
```
When user requests feature:
  1. Check if spec exists
  2. If spec has layered-tasks.md:
     - Run /supervisor:init <spec>
  3. Build feature (agents use worktrees)
```

---

## Recommended Approach: Option A (Phase 0)

### Why Phase 0?

1. **Specs are finalized** - All features defined, agents known
2. **Before any coding** - Worktrees ready when agents need them
3. **Atomic setup** - All infrastructure ready at once
4. **No mid-build disruption** - Don't create worktrees during active development

### Implementation: Update build-full-stack-phase-0.md

**Add after `/planning:init-project` completes:**

```markdown
Phase 4: Worktree Setup (NEW)
Goal: Create git worktrees for parallel agent development

Actions:
- Glob all specs: specs/*/agent-tasks/layered-tasks.md
- For each spec found:
  - Extract spec name from path
  - Execute: !{slashcommand /supervisor:init $SPEC_NAME}
  - Wait for completion
  - Verify worktrees created
- List all worktrees: !{bash git worktree list}
- Store worktree info in .ai-stack-config.json:
  !{bash jq '.worktrees = true | .worktreeCount = '$(git worktree list | wc -l)'' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
```

**Benefits:**
- ✅ Automated - No manual /supervisor:init per spec
- ✅ Complete - All worktrees ready before Phase 1
- ✅ Verified - Can check worktree count in config
- ✅ Mem0 registered - Agents can query locations

---

## Required Changes

### 1. Update build-full-stack-phase-0.md

**Add new Phase 4:**
```markdown
Phase 4: Worktree Setup for Parallel Development
Goal: Create isolated git worktrees for each agent to enable parallel work

Actions:
- Find all specs with agent assignments:
  !{bash find specs -name "layered-tasks.md" -type f}

- For each spec found, create worktrees:
  !{bash
    for spec_tasks in specs/*/agent-tasks/layered-tasks.md; do
      spec_dir=$(dirname $(dirname "$spec_tasks"))
      spec_name=$(basename "$spec_dir")
      echo "Creating worktrees for $spec_name..."
      # Run supervisor init
      !{slashcommand /supervisor:init $spec_name}
    done
  }

- Verify worktrees created:
  !{bash git worktree list}

- Count worktrees:
  !{bash git worktree list | grep -c "agent-"}

- Update config:
  !{bash jq '.worktreesSetup = true | .worktreeCount = '$(git worktree list | grep -c "agent-")' | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}

Display:
- "✅ Worktrees created for X specs"
- "📁 Agents can work in parallel without conflicts"
- "🔍 Agents query Mem0 for worktree locations"
```

### 2. Update Agent Instructions

**All agents should check for worktree in Phase 1:**

```markdown
### 1. Discovery & Working Directory

**Check if worktree exists for this agent:**

```bash
# Query Mem0 for worktree location
python plugins/planning/skills/doc-sync/scripts/register-worktree.py query \
  --query "where does {agent-name} work on spec {spec-num}"
```

**If worktree exists:**
- Change to worktree directory: `cd {worktree-path}`
- Work in isolation (no conflicts with other agents)
- Commit changes to agent branch

**If no worktree:**
- Work in main repository (traditional flow)
- Be careful of conflicts with other agents
```

### 3. Add to ai-stack-config.json Schema

**New fields:**
```json
{
  "phase": 0,
  "phase0Complete": true,
  "worktreesSetup": true,
  "worktreeCount": 6,
  "specs": [
    {
      "name": "001-user-authentication",
      "worktrees": [
        {
          "agent": "nextjs-frontend-agent",
          "path": "../myapp-001-nextjs-frontend-agent",
          "branch": "agent-nextjs-frontend-agent-001"
        },
        {
          "agent": "fastapi-backend-agent",
          "path": "../myapp-001-fastapi-backend-agent",
          "branch": "agent-fastapi-backend-agent-001"
        }
      ]
    }
  ]
}
```

---

## Testing Plan

### Test Scenario 1: Simple App with One Spec

```bash
# Phase 0
/ai-tech-stack-1:build-full-stack-phase-0 "Simple todo app with user auth"

# Expected:
# - specs/001-todo-app/ created
# - specs/001-todo-app/agent-tasks/layered-tasks.md created
# - /supervisor:init 001-todo-app executed
# - Worktrees created:
#   - ../myapp-001-frontend
#   - ../myapp-001-backend
#   - ../myapp-001-database
# - Registered in Mem0
# - .ai-stack-config.json updated with worktreeCount: 3

# Verify
git worktree list  # Should show 3 new worktrees
```

### Test Scenario 2: Complex App with Multiple Specs

```bash
# Phase 0
/ai-tech-stack-1:build-full-stack-phase-0 "Social media app with posts, comments, likes, and notifications"

# Expected:
# - specs/001-posts/ (5 agents → 5 worktrees)
# - specs/002-comments/ (4 agents → 4 worktrees)
# - specs/003-likes/ (3 agents → 3 worktrees)
# - specs/004-notifications/ (6 agents → 6 worktrees)
# - Total: 18 worktrees created
# - .ai-stack-config.json: worktreeCount: 18

# Verify
git worktree list | wc -l  # Should show 19 (main + 18 agents)
```

### Test Scenario 3: Agent Queries Mem0

```python
# Agent asks: "Where do I work on spec 001?"
python register-worktree.py query --query "where does nextjs-frontend-agent work on spec 001"

# Expected response:
# "nextjs-frontend-agent works in ../myapp-001-nextjs-frontend-agent on branch agent-nextjs-frontend-agent-001"
```

---

## Decision Points

### Should We Always Use Worktrees?

**YES - if specs have layered-tasks.md with multiple agents**
- Parallel development without conflicts
- Clean isolation per agent
- Mem0 coordination

**NO - if simple single-agent work**
- Overhead not worth it
- Main repo sufficient

**Conditional Logic:**
```bash
# Check if layered-tasks.md exists and has multiple agents
if [ -f "specs/$SPEC/agent-tasks/layered-tasks.md" ]; then
  agent_count=$(grep -c "@agent" "specs/$SPEC/agent-tasks/layered-tasks.md")
  if [ "$agent_count" -gt 1 ]; then
    echo "Multiple agents - creating worktrees"
    /supervisor:init $SPEC
  else
    echo "Single agent - using main repo"
  fi
fi
```

### When to Merge Worktrees Back?

**After Phase completion:**
```
Phase 3 Complete → /supervisor:end 001-todo-app
  ↓
  Validates all tasks complete
  ↓
  Generates PR command
  ↓
  User runs: gh pr create --base main --head agent-frontend-001
  ↓
  After merge: git worktree remove ../myapp-001-frontend
```

---

## Summary

### Current State
- ✅ Supervisor plugin exists in dev-lifecycle-marketplace
- ✅ Worktree creation works via /supervisor:init
- ✅ Mem0 registration works
- ✅ Agents can query Mem0 for locations
- ❌ Not integrated into ai-tech-stack-1 orchestrator

### Proposed Changes
1. **Phase 0**: Add worktree creation after specs generated
2. **Agents**: Add worktree detection in Phase 1
3. **Config**: Track worktree count and locations
4. **Conditional**: Only create if multiple agents per spec

### Implementation Priority
1. **HIGH**: Update build-full-stack-phase-0.md to create worktrees
2. **MEDIUM**: Add worktree detection to frontend/backend agents
3. **LOW**: Track worktrees in .ai-stack-config.json schema
4. **FUTURE**: Automatic merge/cleanup after phase completion

### Next Steps
1. Update build-full-stack-phase-0.md with Phase 4
2. Test with simple spec (1-2 agents)
3. Test with complex spec (5+ agents)
4. Verify Mem0 coordination works
5. Document worktree workflow for users

---

**Decision:** Add worktree creation to Phase 0, make it conditional on layered-tasks.md existence, and let agents query Mem0 for their working directory.
