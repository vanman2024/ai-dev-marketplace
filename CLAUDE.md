# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🚨 CRITICAL: Security Rules - NO HARDCODED API KEYS

**This is the HIGHEST PRIORITY security rule for ALL plugins in this marketplace.**

### Absolute Prohibition

❌ **NEVER EVER** hardcode API keys, secrets, or credentials in:
- Agent prompts (`.md` files in `agents/`)
- Command prompts (`.md` files in `commands/`)
- Skill documentation (`.md` files in `skills/`)
- Example code in any plugin
- Template files
- Scripts (`.sh`, `.py`, `.js`, `.ts`)
- Configuration files committed to git
- README files
- Documentation

### What Counts as "Hardcoded"

Any actual value for:
- API keys (`ANTHROPIC_API_KEY=sk-ant-...`, `OPENAI_API_KEY=sk-...`)
- Database credentials (`password=actual_password`)
- Authentication tokens (`Bearer abc123xyz...`)
- OAuth secrets (`client_secret=real_secret`)
- Webhook secrets
- Service account credentials
- Connection strings with passwords
- Any real sensitive value

### Required Practice - ALWAYS Use Placeholders

✅ **CORRECT placeholders:**
```bash
# .env.example (safe to commit)
ANTHROPIC_API_KEY=your_anthropic_key_here
OPENAI_API_KEY=your_openai_key_here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
DATABASE_PASSWORD=your_database_password
```

✅ **CORRECT in code - read from environment:**
```python
import os
api_key = os.getenv("ANTHROPIC_API_KEY")
if not api_key:
    raise ValueError("ANTHROPIC_API_KEY not set")
```

✅ **CORRECT multi-environment placeholders:**
```bash
# .env.development
ANTHROPIC_API_KEY=projectname_dev_your_key_here

# .env.production
ANTHROPIC_API_KEY=projectname_prod_your_key_here
```

### Enforcement in All Plugin Components

**Every agent MUST include this section:**
```markdown
## Security: API Key Handling

**CRITICAL:** When generating any configuration files or code:

❌ NEVER hardcode actual API keys or secrets
❌ NEVER include real credentials in examples
❌ NEVER commit sensitive values to git

✅ ALWAYS use placeholders: `your_service_key_here`
✅ ALWAYS create `.env.example` with placeholders only
✅ ALWAYS add `.env*` to `.gitignore` (except `.env.example`)
✅ ALWAYS read from environment variables in code
✅ ALWAYS document where to obtain keys

**Placeholder format:** `{service}_{env}_your_key_here`
```

**Every command that handles environment setup MUST check:**
- All generated `.env` files use placeholders only
- `.gitignore` protects `.env` files
- `.env.example` exists with clear placeholders
- Setup documentation explains how to obtain real keys

**Every skill MUST state in its SKILL.md:**
```markdown
## Security Compliance

This skill follows strict security rules:
- All code examples use placeholder values only
- No real API keys, passwords, or secrets
- Environment variable references in all code
- `.gitignore` protection documented
```

### Validation

See `@docs/SECURITY-RULES.md` for full validation checklist and comprehensive security guidelines.

**Before ANY commit to this marketplace:**
- [ ] No real API keys in any file
- [ ] All examples use obvious placeholders
- [ ] `.gitignore` protects secrets
- [ ] Setup docs explain key acquisition

**Violations = Immediate fix required before merge**

---

## 🚨 CRITICAL: Slash Command Execution Rules

### DO NOT Run Slash Commands in Parallel

**The most important rule learned from extensive testing:**

Slash commands CANNOT execute in parallel. They sit in queue and don't run.

**WRONG:**
```
Invoke /slash-commands-create command1
Invoke /agents-create agent1
Invoke /skills-create skill1

Wait for all to complete
```

**CORRECT:**
```
Run /slash-commands-create command1
(Wait for it to finish)

Run /agents-create agent1
(Wait for it to finish)

Run /skills-create skill1
(Wait for it to finish)
```

### Why This Matters

- Slash commands execute ONE AT A TIME sequentially
- Running multiple at once causes them to sit in queue
- You MUST wait for each command to complete before running the next
- Takes longer but is the only consistent way that works

### Exception: Task Tool for Parallel Agents

You CAN run agents in parallel using the Task() tool:

```
Task(description="Scan code", subagent_type="code-scanner", prompt="Scan for $ARGUMENTS")
Task(description="Run tests", subagent_type="test-runner", prompt="Test $ARGUMENTS")
Task(description="Security audit", subagent_type="security-checker", prompt="Audit $ARGUMENTS")

Wait for ALL agents to complete before proceeding.
```

This is for AGENTS, not slash commands!

---

## 🚨 CRITICAL: How to Build Plugins - CORRECT WORKFLOW

**IF YOU NEED TO BUILD A NEW PLUGIN:**

Use ONLY this command as the TOP-LEVEL ORCHESTRATOR:
```bash
/domain-plugin-builder:build-plugin <plugin-name>
```

**The CORRECT hierarchy:**
```
/domain-plugin-builder:build-plugin (TOP-LEVEL ORCHESTRATOR)
  └─ Calls /domain-plugin-builder:plugin-create
      └─ Which creates directory structure
      └─ Builds commands sequentially (ONE AT A TIME)
      └─ Builds agents sequentially (ONE AT A TIME)
      └─ Builds skills in parallel
      └─ Syncs to marketplace.json
      └─ Registers commands in settings.local.json
      └─ Creates .mcp.json
  └─ Validates entire plugin with plugin-validator agent
  └─ Commits and pushes to GitHub
```

**DO NOT:**
- ❌ Try to build plugins manually
- ❌ Call `/domain-plugin-builder:plugin-create` directly (use build-plugin instead)
- ❌ Call `/domain-plugin-builder:slash-commands-create` directly for new plugins
- ❌ Call `/domain-plugin-builder:agents-create` directly for new plugins
- ❌ Call `/domain-plugin-builder:skills-create` directly for new plugins
- ❌ Invoke agents via Task tool to build plugin components
- ❌ Skip the build-plugin orchestrator and try to piece things together

**What `/domain-plugin-builder:build-plugin` does:**
1. Loads framework documentation
2. Creates TodoWrite list for tracking
3. Invokes `/domain-plugin-builder:plugin-create` which:
   - Asks interactive questions about the plugin
   - Creates complete directory structure
   - **Automatically invokes** the other commands sequentially (ONE AT A TIME):
     * `/domain-plugin-builder:slash-commands-create` (for each command - waits for completion)
     * `/domain-plugin-builder:agents-create` (for each agent - waits for completion)
     * `/domain-plugin-builder:skills-create` (for all skills in parallel)
   - Validates plugin manifest
   - Syncs to marketplace.json
   - Registers ALL commands in settings.local.json
   - Creates .mcp.json file
   - Generates README.md
4. Validates entire plugin with plugin-validator agent
5. Commits and pushes to GitHub
6. Displays comprehensive summary

**Critical files created by the workflow:**
- ✅ `.claude-plugin/plugin.json` - Plugin manifest
- ✅ `.mcp.json` - MCP server configuration (even if empty)
- ✅ Commands registered in `.claude/settings.local.json`
- ✅ Plugin registered in `.claude-plugin/marketplace.json`
- ✅ README.md generated
- ✅ All committed and pushed to GitHub

**Only use the individual commands** (`slash-commands-create`, `agents-create`, `skills-create`) when **adding to an EXISTING plugin**, never when building a new plugin from scratch.

### Quick Reference Decision Tree

```
Need to build something?
│
├─ Building a NEW plugin?
│  └─ ✅ /domain-plugin-builder:plugin-create <name>
│     (It handles everything else automatically)
│
└─ Modifying EXISTING plugin?
   ├─ Adding command?
   │  └─ ✅ /domain-plugin-builder:slash-commands-create <name> "desc" --plugin=<plugin>
   │
   ├─ Adding agent?
   │  └─ ✅ /domain-plugin-builder:agents-create <name> "desc" "tools"
   │
   └─ Adding skill?
      └─ ✅ /domain-plugin-builder:skills-create <name> "desc"
```

**Remember: plugin-create is your starting point for ALL new plugins!**

---

## 🛠️ CRITICAL: Correct Tool Format

**When defining tools in agents and commands, use the correct format:**

### ✅ CORRECT Format

**For Agents** (`tools:` field):
```yaml
tools: Bash, Read, Write, Edit, Grep, Glob
tools: Bash, Read, WebFetch, mcp__github
```

**For Commands** (`allowed-tools:` field):
```yaml
allowed-tools: Task, Read, Write, Bash, Grep, Glob
allowed-tools: Task, Read, Write, Bash, mcp__github
```

### ❌ WRONG Format

```yaml
# NO JSON arrays
tools: ["Bash", "Read", "Write"]

# NO vertical lists
tools:
  - Bash
  - Read
  - Write

# NO wildcards in parentheses
tools: Bash(*), Task(mcp__*)

# NO trailing underscores
tools: mcp__context7__

# NO wildcards in MCP tool names
tools: mcp__github__*
```

### MCP Tool Rules

- ✅ `mcp__github` - Approves ALL tools from github server
- ✅ `mcp__github__get_issue` - Approves specific tool only
- ❌ `mcp__github__*` - Wildcards NOT supported
- ❌ `mcp__context7__` - No trailing underscores

### Bash Restrictions (Optional)

```yaml
# Restrict to specific commands
allowed-tools: Bash(git add:*), Bash(git commit:*)

# Allow all bash commands
allowed-tools: Bash
```

### Commands Need MORE Than Just Task

**WRONG:**
```yaml
allowed-tools: Task
```

**CORRECT:**
```yaml
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
```

Commands need access to multiple tools, not just Task!

---

## 📋 $ARGUMENTS Usage Rules

### NEVER Use Numbered Arguments

**WRONG:**
```markdown
Run command with $1, $2, $3
```

**CORRECT:**
```markdown
Run command with $ARGUMENTS
Parse $ARGUMENTS to extract individual values
```

### How to Parse Arguments

Use bash to parse $ARGUMENTS:

```bash
!{bash echo "$ARGUMENTS" | grep -oE '<[^>]+>' | wc -l}
```

Then extract values based on count and use them.

**Never use $1, $2, $3 - Always use $ARGUMENTS!**

---

## 🎯 Agent Invocation in Commands

### Natural Language DOES NOT WORK

**WRONG (Natural Language):**
```markdown
Launch the security-specialist agent to audit authentication.

Provide the agent with:
- Provider list: [providers]
- Focus: RLS policies, OAuth config
```

This doesn't work! Natural language doesn't execute Task() calls.

### CORRECT (Task Tool Syntax):
```markdown
Task(description="Audit authentication", subagent_type="security-specialist", prompt="You are the security-specialist agent. Audit authentication for $ARGUMENTS.

Provider list: [providers]
Focus: RLS policies, OAuth config
Deliverable: Security audit report")
```

**Always use proper Task() syntax, never natural language!**

---

## 📚 Template Loading Requirements

### Commands MUST Load Templates

Before building components, commands MUST load relevant templates:

**Example for slash command creation:**
```markdown
Phase 1: Load Templates

@plugins/domain-plugin-builder/skills/build-assistant/templates/commands/template-command-patterns.md
@plugins/domain-plugin-builder/docs/frameworks/claude/component-decision-framework.md
```

**Example for agent creation:**
```markdown
Phase 1: Load Agent Templates

@plugins/domain-plugin-builder/skills/build-assistant/templates/agents/agent-with-phased-webfetch.md
@plugins/domain-plugin-builder/docs/frameworks/claude/component-decision-framework.md
```

**Never build without loading templates first!**

---

## 📐 Agent Length Best Practice

### Keep Agents Under 300 Lines

**Problem:** Agents with 400-500 lines don't work well

**Solution:** Use WebFetch for documentation instead of inline code

**WRONG (Inline Code Examples):**
```python
# Python example
if __name__ == "__main__":
    import uvicorn
    mcp.run(transport="http", port=8000)
```

**CORRECT (WebFetch References):**
```markdown
Phase 2: Load Documentation

WebFetch: https://docs.example.com/deployment/http-configuration
WebFetch: https://docs.example.com/deployment/cors

**Configure Transport Based on Fetched Docs**:
- HTTP: Configure uvicorn/server for remote access
- CORS: Set up origins and headers
```

**Target: Under 300 lines using progressive documentation loading**

---

## 🔄 Git Workflow Rules

### MANDATORY Git Commit and Push

**ALL plugin builder commands MUST:**
1. Create/modify files
2. Validate files
3. Stage files: `git add <files>`
4. Commit: `git commit -m "message"`
5. **IMMEDIATELY PUSH**: `git push origin master`

**Example:**
```bash
!{bash git add plugins/$PLUGIN_NAME}
!{bash git commit -m "feat: Add $PLUGIN_NAME plugin

Complete plugin with commands, agents, skills.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"}

!{bash git push origin master}
```

### Why This Matters

- Work is NEVER lost if always pushed
- Prevents catastrophic data loss
- GitHub is source of truth
- Local directory can be deleted/recreated

**CRITICAL: Always push immediately after committing!**

---

## 🏗️ Command Pattern Rules

### Four Command Patterns

Commands follow one of four patterns based on complexity:

**Pattern 1: Simple (No Agents)**
- Mechanical tasks: version bumping, file operations, config updates
- Direct script execution without AI decision-making
- Examples: `/version`, `/git-setup`, `/mcp-clear`

**Pattern 2: Single Agent**
- One AI capability needed (analysis, generation, refactoring)
- Use Task() tool to invoke one agent
- Examples: `/detect` (uses project-detector), `/init`

**Pattern 3: Sequential Slash Commands**
- **PREFERRED for orchestrators** - Chain slash commands sequentially
- Each slash command handles its own agent delegation
- **CRITICAL: Wait for each command to complete before running next!**
- Examples: `/core` (chains /init → /git-setup → /mcp-setup)
- **Why better**: Granular commands are reusable, testable, composable

**Pattern 4: Parallel Agents**
- **ONLY for parallel agent execution** (not slash commands)
- Independent validation tasks that can run simultaneously
- All agents start together via multiple Task tool calls in ONE message
- Examples: `/validate` (lint + test + security all at once)

### Orchestration Best Practices

**DO:**
- ✅ Orchestrate by invoking slash commands: `/command-1` → `/command-2` → `/command-3`
- ✅ Let each command handle its own agent delegation
- ✅ Use Task tool when a command needs an agent
- ✅ Launch multiple agents in parallel with multiple Task calls in ONE message
- ✅ **WAIT for each slash command to complete before running the next**

**DON'T:**
- ❌ Call agents directly from orchestrator commands
- ❌ Hardcode frameworks (Next.js, React) - DETECT them
- ❌ Assume project structure - ANALYZE it
- ❌ Send separate messages for each parallel agent (breaks parallelism)
- ❌ Try to run multiple slash commands at once (they won't execute)

---

## ✅ Validation Requirements

### Before ANY Commit

**Run validation scripts:**

1. **Command Validation:**
   ```bash
   bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-command.sh plugins/{plugin}/commands/{command}.md
   ```

2. **Agent Validation:**
   ```bash
   bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-agent.sh plugins/{plugin}/agents/{agent}.md
   ```

3. **Skill Validation:**
   ```bash
   bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-skill.sh plugins/{plugin}/skills/{skill}
   ```

4. **Complete Plugin Validation:**
   ```bash
   bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-plugin.sh plugins/{plugin}
   ```

### Validation is Critical

- Always validate before committing
- Fix validation errors immediately
- Don't commit plugins with validation failures
- Validation scripts auto-correct many issues

**100% validation compliance required!**

---

## 📝 Plugin Building Workflow

### Correct Order (plugin-create command)

```
1. Verify location (pwd check)
2. Gather requirements (AskUserQuestion)
3. Load framework documentation
4. Create directory structure
5. Build commands (ONE AT A TIME):
   - Run /slash-commands-create command1
   - WAIT FOR COMPLETION
   - Run /slash-commands-create command2
   - WAIT FOR COMPLETION
6. Build agents (ONE AT A TIME):
   - Run /agents-create agent1
   - WAIT FOR COMPLETION
   - Run /agents-create agent2
   - WAIT FOR COMPLETION
7. Build skills (can be parallel via Task):
   - Task() for skill1
   - Task() for skill2
   - Task() for skill3
   - Wait for all
8. Validate all components
9. Update marketplace.json
10. Register in settings.local.json
11. Git commit and push
12. Display summary
```

**CRITICAL:** Steps 5-6 must run sequentially, ONE command at a time with waits between each!

---

## 🔍 Common Mistakes to Avoid

1. **Running slash commands in parallel** - They queue up and don't execute
2. **Using Task(agent-name) in allowed-tools** - Should just be `Task`
3. **Forgetting git push** - Work gets lost
4. **Using wildcards with MCP tools** - Not supported
5. **Vertical tool lists** - Use horizontal comma-separated
6. **JSON array tools** - Use plain comma-separated
7. **Missing basic tools in commands** - Need Read, Write, Bash, etc.
8. **Not waiting for slash command completion** - Sequential commands fail
9. **Natural language agent invocation** - Use Task() syntax
10. **Commands with only Task tool** - Need full tool set
11. **Using $1, $2, $3** - Always use $ARGUMENTS
12. **Not loading templates** - Must load before building
13. **Agents over 300 lines** - Use WebFetch instead of inline docs
14. **Skipping validation** - Run validation scripts before committing

---

## 📋 Quick Reference

### Plugin Structure
```
plugins/{plugin-name}/
├── .claude-plugin/
│   └── plugin.json
├── commands/
├── agents/
├── skills/
├── docs/
└── README.md
```

### Tool Formats
- **Agents:** `tools: Bash, Read, Write, Edit, mcp__server`
- **Commands:** `allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite`
- **Bash restrict:** `Bash(git add:*)`
- **MCP all tools:** `mcp__github`
- **MCP specific:** `mcp__github__get_issue`

### Command Patterns
1. Simple - No agents
2. Single Agent - One Task()
3. Sequential - Multiple slash commands (**wait between each!**)
4. Parallel - Multiple Task() calls (all at once)

### Argument Usage
- ✅ `$ARGUMENTS` - Always use this
- ❌ `$1, $2, $3` - Never use these

### Git Workflow
1. Create/modify
2. Validate
3. `git add`
4. `git commit`
5. **`git push`** ← MANDATORY!

### Agent Best Practices
- Keep under 300 lines
- Use WebFetch for documentation
- Load templates before building
- Follow phased approach

### Slash Command Execution
- **NEVER** run in parallel
- **ALWAYS** wait for completion
- Run ONE AT A TIME sequentially

---

**Last Updated:** 2025-10-31
**Source:** Extracted from extensive conversation history in /home/gotime2022/.claude/history.jsonl

This document represents lessons learned through extensive testing and iteration. Follow these rules exactly!
