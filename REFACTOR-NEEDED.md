# Skills Architecture Refactor Needed

**Date Created:** 2025-11-02
**Source:** Dan's YouTube video on Claude Code Skills Architecture
**Status:** Documentation Only (Refactor TBD)

---

## Executive Summary

After analyzing our skills infrastructure against Dan's architectural principles, we've identified that **our current approach may be backwards**. We have 55 skills defined, but many lack corresponding slash commands and proper invocation patterns.

**Current State:**
- ✅ 55 skills exist with valuable content
- ✅ All 55 registered in settings.json
- ❌ Only 1 skill actively used (`fastmcp-integration`)
- ❌ 54 skills unused (98%)
- ❌ Missing slash-command-first architecture

**Root Cause:** We built skills without establishing the foundational slash commands first.

---

## Dan's Architectural Principles

### The Fundamental Truth

> **"Everything is a prompt in the end. Tokens in, tokens out."**

**The Core 4:**
1. Context
2. Model
3. Prompt
4. Tools

**Mastery Path:**
Master fundamentals → Master composition → Master features → Master tools

### The Composition Hierarchy

```
SKILLS (Top - Compositional Manager)
  └─> Composes: Slash Commands, MCP, Sub-agents, Other Skills
  └─> Role: Domain managers (e.g., worktree-manager, deployment-manager)

SLASH COMMANDS (Primitive + Compositional)
  └─> The fundamental unit - closest to bare metal prompts
  └─> Can compose: Skills, MCP, Sub-agents
  └─> Role: Single-purpose worker tasks

SUB-AGENTS (Mid-level)
  └─> Role: Isolated context, parallelization

MCP SERVERS (Mid-level)
  └─> Role: External integrations only
```

---

## The Critical Rule: When to Use Skills

**Dan's principle:**

> **"If you can do the job with a sub-agent or custom slash command and it's a one-off job, DO NOT USE A SKILL."**

### Skills are for:
- ✅ **Managing** multiple related operations (not just one)
- ✅ Repeat solutions for specific problem domains
- ✅ When you have 3+ related slash commands to group
- ✅ Agent-invoked automatic behavior

### Example: Git Worktrees

**WRONG:**
- One skill just to create a worktree (one-off task)

**RIGHT:**
- Slash command: `/create-worktree` (simple, direct)
- OR: Skill that **manages** worktrees (create, list, remove, merge, stop)

---

## Skills COMPOSE Slash Commands (Not Replace!)

**Dan's key insight:**

Skills should **contain/invoke slash commands**, not replace them.

**Current workaround:**
```markdown
# In SKILL.md
Instructions: Use the SlashCommand tool to invoke /create-worktree
```

**The pattern:**
- Skills use SlashCommand tool to invoke other commands
- Skills provide expertise, commands do the work
- Skills are **managers**, commands are **workers**

---

## When to Use Each Feature

| Feature | Use When | Example |
|---------|----------|---------|
| **Slash Command** | One-off task, manual trigger, primitive | `/create-component`, `/deploy` |
| **Skill** | Managing domain (3+ operations), repeat solutions | `worktree-manager`, `deployment-manager` |
| **Sub-agent** | Parallelization, isolated context | Running tests at scale across features |
| **MCP** | External integrations only | Jira, database, weather API |

---

## The Progressive Approach

**Dan recommends:**

1. **Start:** Build a slash command (the primitive)
2. **If one-off:** Keep it as slash command
3. **If need parallelization:** Move to sub-agent
4. **If managing domain:** Create skill that composes slash commands

**Example Evolution:**

```
Phase 1: /create-worktree (simple command)
         ↓
Phase 2: Need to also list, remove, merge
         ↓
Phase 3: Create worktree-manager skill that:
         - Invokes /create-worktree (via SlashCommand tool)
         - Invokes /list-worktrees
         - Invokes /remove-worktree
         - Invokes /merge-worktree
```

---

## Current Problems with Our 55 Skills

### Problem 1: Skills Without Slash Commands

Many skills exist but have no corresponding slash commands to invoke.

**Example:** `nextjs-frontend:deployment-config` skill
- Contains validation scripts, templates, patterns
- **Missing:** `/deploy`, `/validate-deployment`, `/rollback` commands
- **Result:** Skill exists but cannot be properly utilized

### Problem 2: One-Off Skills

Some skills represent single operations that should be slash commands.

**Should audit:** Which skills are really just one operation?

### Problem 3: Missing Invocation Patterns

Skills aren't being invoked because:
- Commands don't have `Skill` in `allowed-tools`
- Agents don't have `Skill` in `tools`
- No invocation logic (`!{skill skill-name}`) in prompts

### Problem 4: Backwards Architecture

**Current (wrong):**
```
User → Skill (tries to do everything)
```

**Should be (Dan's way):**
```
User → Slash Command → Loads Skill → Skill uses SlashCommand tool
```

---

## Refactor Plan (Future Work)

### Phase 1: Audit (1-2 weeks)

**Goal:** Identify which skills need corresponding slash commands

**Tasks:**
1. Review all 55 skills
2. Identify skill domains (deployment, worktrees, testing, etc.)
3. Determine: Is this a manager (skill) or worker (slash command)?
4. Map: Which slash commands should exist for each skill?

**Deliverable:** `skills-to-commands-mapping.json`

### Phase 2: Create Missing Slash Commands (2-3 weeks)

**Goal:** Build the foundational slash commands

**Pattern for each skill domain:**
```
deployment-config skill needs:
  ├─> /deploy
  ├─> /validate-deployment
  ├─> /optimize-build
  └─> /rollback
```

**Tasks:**
1. Create slash commands for each skill domain
2. Commands should be simple, single-purpose
3. Test commands work independently

### Phase 3: Wire Skills to Commands (1-2 weeks)

**Goal:** Skills invoke slash commands via SlashCommand tool

**Pattern:**
```markdown
# In SKILL.md

When managing deployments:

1. Validate: Use SlashCommand tool → /validate-deployment
2. Deploy: Use SlashCommand tool → /deploy
3. Monitor: Use SlashCommand tool → /check-deployment-status
```

**Tasks:**
1. Update all skills to use SlashCommand tool
2. Skills provide expertise, commands do work
3. Test skill orchestration works

### Phase 4: Update Commands & Agents (1 week)

**Goal:** Proper tool declarations and invocation patterns

**For commands:**
```yaml
allowed-tools: Task, Read, Write, Bash, Skill  # ✅ Add Skill
```

**For agents:**
```yaml
tools: Bash, Read, Write, Edit, WebFetch, Skill  # ✅ Add Skill
```

**Add invocation logic:**
```markdown
Phase 1: Load expertise
!{skill deployment-config}

Phase 2: Execute via commands
Use SlashCommand tool with loaded patterns
```

### Phase 5: Validate & Document (1 week)

**Tasks:**
1. Test all 55 skills can be invoked
2. Test skills properly orchestrate slash commands
3. Document patterns in CLAUDE.md
4. Create examples of proper skill usage

---

## Priority Skills for Refactor

Based on impact and usage patterns:

### High Priority (Address First)

1. **nextjs-frontend:deployment-config**
   - High value, deployment critical
   - Needs: `/deploy`, `/validate`, `/rollback` commands

2. **fastapi-backend:fastapi-auth-patterns**
   - Security critical
   - Needs: `/add-auth`, `/configure-oauth`, `/test-auth` commands

3. **supabase:schema-patterns**
   - Foundation for data layer
   - Needs: `/create-schema`, `/validate-schema`, `/migrate` commands

4. **vercel-ai-sdk:rag-implementation**
   - Complex AI feature
   - Needs: `/add-rag`, `/configure-vectordb`, `/test-retrieval` commands

### Medium Priority

5. **ml-training:cloud-gpu-configs**
6. **rag-pipeline:langchain-patterns**
7. **website-builder:ai-content-generation**

### Low Priority (Later)

- Validation skills (can defer)
- Reference documentation skills
- Example/template-only skills

---

## The Correct Architecture

**Slash commands are the primitive. Skills are compositional.**

```
┌─────────────────────────────────────┐
│ USER                                │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ SLASH COMMAND (The Primitive)       │
│ - /deploy                           │
│ - /create-worktree                  │
│ - /add-component                    │
└──────────────┬──────────────────────┘
               ↓ Invokes for expertise
┌─────────────────────────────────────┐
│ SKILL (Compositional Manager)       │
│ - deployment-manager                │
│ - worktree-manager                  │
│ - component-manager                 │
│                                     │
│ Skills COMPOSE slash commands       │
│ via SlashCommand tool               │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ MCP / SUB-AGENTS (Lower level)      │
└─────────────────────────────────────┘
```

---

## Decision Tree for Future Work

**When creating new capabilities:**

```
Q: Is this a one-off task?
├─ YES → Create slash command
└─ NO → Continue...

Q: Does this manage 3+ related operations?
├─ YES → Create skill that composes slash commands
└─ NO → Create slash command

Q: Does this need to parallelize?
├─ YES → Use sub-agent
└─ NO → Use slash command

Q: Is this external integration?
├─ YES → Use MCP server
└─ NO → Use slash command
```

---

## Immediate Fixes Completed (2025-11-02)

✅ Fixed 2 skills with missing `skill_name`:
- `plugin-docs-loader:doc-templates`
- `website-builder:astro-setup`

✅ Registered all 55 skills in settings.json

✅ Created this documentation for future refactor

---

## References

- **Source:** Dan's YouTube video on Claude Code Skills
- **Key Quote:** "Everything is a prompt in the end"
- **Pattern:** Slash-command-first, skills compose commands
- **Rule:** Don't create skills for one-off tasks

---

## Next Steps

**When ready to refactor:**

1. Read this document
2. Follow refactor plan phases
3. Start with high-priority skills
4. Build slash commands first
5. Wire skills to compose commands
6. Test and validate
7. Document patterns

**Estimated Effort:** 6-8 weeks for complete refactor

**Priority:** Medium (current workarounds sufficient for now)

---

*This document represents the architectural debt identified on 2025-11-02. It should guide future refactoring efforts to align our skills infrastructure with Dan's slash-command-first principles.*
