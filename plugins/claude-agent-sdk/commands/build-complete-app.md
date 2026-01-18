---
description: Build a complete Claude Agent SDK application with ALL features in one command
argument-hint: <project-name>
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite, AskUserQuestion, Skill
---

**Arguments**: $ARGUMENTS

**Goal**: Build a fully-featured Claude Agent SDK app with all capabilities enabled.

---

## Phase 1: Gather Requirements

Use AskUserQuestion to collect preferences:

```
AskUserQuestion([
  {
    question: "Which programming language?",
    header: "Language",
    options: [
      { label: "TypeScript (Recommended)", description: "Full type safety, npm ecosystem" },
      { label: "Python", description: "Simple syntax, pip ecosystem" }
    ],
    multiSelect: false
  },
  {
    question: "Which features do you need?",
    header: "Features",
    options: [
      { label: "All features (Recommended)", description: "Complete SDK with everything enabled" },
      { label: "Core only", description: "Streaming, tools, sessions, system prompts" },
      { label: "Let me pick", description: "Choose specific features to include" }
    ],
    multiSelect: false
  }
])
```

If "Let me pick", ask:
```
AskUserQuestion([
  {
    question: "Select features to include:",
    header: "Select",
    options: [
      { label: "MCP + Subagents", description: "MCP servers, subagent orchestration" },
      { label: "Skills + Plugins", description: "Skill system, plugin architecture" },
      { label: "Memory + Sessions", description: "Claude Memory Tool, session persistence" },
      { label: "Monitoring", description: "Cost tracking, todo tracking, permissions" }
    ],
    multiSelect: true
  }
])
```

---

## Phase 2: Create Base App

Run: `/claude-agent-sdk:new-app $ARGUMENTS`

**WAIT** for completion before proceeding.

---

## Phase 3: Add Features Sequentially

**CRITICAL**: Run each command ONE AT A TIME. Wait for completion before the next.

**Core Features** (always included):
```
/claude-agent-sdk:add-streaming $ARGUMENTS
/claude-agent-sdk:add-system-prompts $ARGUMENTS
/claude-agent-sdk:add-custom-tools $ARGUMENTS
/claude-agent-sdk:add-sessions $ARGUMENTS
```

**MCP + Subagents** (if selected or "All"):
```
/claude-agent-sdk:add-mcp $ARGUMENTS
/claude-agent-sdk:add-mcp-code-execution $ARGUMENTS
/claude-agent-sdk:add-subagents $ARGUMENTS
```

**Skills + Plugins** (if selected or "All"):
```
/claude-agent-sdk:add-skills $ARGUMENTS
/claude-agent-sdk:add-plugins $ARGUMENTS
/claude-agent-sdk:add-slash-commands $ARGUMENTS
```

**Memory + Sessions** (if selected or "All"):
```
/claude-agent-sdk:add-memory $ARGUMENTS
```

**Monitoring** (if selected or "All"):
```
/claude-agent-sdk:add-permissions $ARGUMENTS
/claude-agent-sdk:add-cost-tracking $ARGUMENTS
/claude-agent-sdk:add-todo-tracking $ARGUMENTS
```

**Deployment** (optional - ask user):
```
/claude-agent-sdk:add-hosting $ARGUMENTS
```

---

## Phase 4: Verify

Based on language, invoke verifier:

**TypeScript:**
```
Task(description="Verify TS app", subagent_type="claude-agent-sdk:claude-agent-verifier-ts", prompt="Verify complete SDK app at $ARGUMENTS. Check all features are properly integrated.")
```

**Python:**
```
Task(description="Verify PY app", subagent_type="claude-agent-sdk:claude-agent-verifier-py", prompt="Verify complete SDK app at $ARGUMENTS. Check all features are properly integrated.")
```

Run type check:
- TS: `cd $ARGUMENTS && npx tsc --noEmit`
- PY: `cd $ARGUMENTS && python -m py_compile *.py`

---

## Phase 5: Summary

Display:
```
✅ Complete Claude Agent SDK App Built: $ARGUMENTS

Features:
- Base: Streaming, System Prompts, Custom Tools, Sessions
- MCP: Server integration, Code execution pattern
- Agents: Subagent orchestration
- Extensions: Skills, Plugins, Slash Commands
- Memory: Claude Memory Tool integration
- Monitoring: Permissions, Cost tracking, Todo tracking

Quick Start:
  cp .env.example .env  # Add ANTHROPIC_API_KEY
  [npm run dev | python main.py]

Docs: https://docs.claude.com/en/api/agent-sdk/overview
```

---

## Execution Rules

1. **SEQUENTIAL ONLY** - Run one `/claude-agent-sdk:*` command at a time
2. **WAIT** for each to complete before starting next
3. If any fails, stop and report error
4. Use TodoWrite to track progress through phases
