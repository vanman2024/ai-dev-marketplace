# Domain Plugin Builder - Critical Rules & Patterns

This file contains CRITICAL rules for building plugins correctly. Follow these EXACTLY.

---

## 🚨 CRITICAL: Slash Command Execution Rules

### DO NOT Run Slash Commands in Parallel

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

- Slash commands DO NOT execute in parallel
- They sit in queue and don't run
- You MUST wait for each command to complete before running the next
- Takes longer but is more consistent

### Exception: Task Tool for Parallel Agents

You CAN run agents in parallel using Task() tool:

```
Task(description="Scan code", subagent_type="code-scanner", prompt="Scan for $ARGUMENTS")
Task(description="Run tests", subagent_type="test-runner", prompt="Test $ARGUMENTS")
Task(description="Security audit", subagent_type="security-checker", prompt="Audit $ARGUMENTS")

Wait for ALL agents to complete before proceeding.
```

This is for AGENTS, not slash commands!

---

## 🛠️ Tool Formatting Rules

### Agent Tools (agents/*.md)

**CORRECT Format:**
```yaml
---
name: agent-name
tools: Bash, Read, Write, Edit, mcp__supabase
---
```

**WRONG Formats:**
```yaml
# ❌ JSON array with quotes
tools: ["Bash", "Read", "Write"]

# ❌ Vertical list
tools:
  - Bash
  - Read
  - Write

# ❌ Wildcards on MCP
tools: Bash, Read, mcp__github__*

# ❌ Task with wildcards
tools: Bash, Task(mcp__*)

# ❌ Brackets without restrictions
tools: Bash(*), Read(*), Task(*)
```

### Command Tools (commands/*.md)

**CORRECT Format:**
```yaml
---
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---
```

**Rules:**
- Commands need MORE than just Task
- Include: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
- Use `Bash(git add:*)` for Bash restrictions ONLY
- Never use `Task(agent-name)` - just `Task`
- Never use wildcards with MCP tools

### MCP Tool Rules

**CORRECT:**
- `mcp__github` - Approves ALL tools from github server
- `mcp__github__get_issue` - Approves specific tool only

**WRONG:**
- `mcp__github__*` - Wildcards NOT supported
- `Task(mcp__*)` - No wildcards in Task
- `mcp__servername` - Replace with actual server name

### Bash Restrictions

**When to use:**
```yaml
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git push:*)
```

**When NOT to use:**
```yaml
# ❌ Wrong - don't restrict all bash
allowed-tools: Bash(*)

# ✅ Correct - no restrictions needed
allowed-tools: Bash
```

---

## 📝 Command Pattern Rules

### Pattern 1: Simple (No Agents)
Use for: Mechanical tasks, file operations, git commands

**Template:**
```markdown
---
allowed-tools: Read, Write, Bash, Glob, Grep
---

Phase 1: Discovery
- Parse $ARGUMENTS
- Detect project type

Phase 2: Execution
- !{bash npm run build}

Phase 3: Summary
- Display results
```

### Pattern 2: Single Agent
Use for: One AI capability needed

**Template:**
```markdown
---
allowed-tools: Task, Read, Write, Edit, Bash
---

Phase 1: Discovery
- Gather context

Phase 2: Implementation

Task(description="Build feature", subagent_type="feature-builder", prompt="You are the feature-builder agent. Build $ARGUMENTS...")

Phase 3: Verification
- Check output
```

### Pattern 3: Sequential Slash Commands
Use for: Multi-phase workflows with dependencies

**Template:**
```markdown
---
allowed-tools: SlashCommand, Task, Read, Write, Bash
---

Phase 1: Setup
Run /plugin:init $ARGUMENTS
(Wait for completion)

Phase 2: Configuration
Run /plugin:configure
(Wait for completion)

Phase 3: Validation
Run /plugin:validate
```

**CRITICAL:** Each command must COMPLETE before running next!

### Pattern 4: Parallel Agents
Use for: Independent validation tasks

**Template:**
```markdown
---
allowed-tools: Task, Read, Write, Bash, TodoWrite
---

Phase 1: Discovery
- Parse target

Phase 2: Parallel Execution

Run the following agents IN PARALLEL (all at once):

Task(description="Security check", subagent_type="security-checker", prompt="Audit $ARGUMENTS")
Task(description="Code scan", subagent_type="code-scanner", prompt="Scan $ARGUMENTS")
Task(description="Performance test", subagent_type="perf-analyzer", prompt="Analyze $ARGUMENTS")

Wait for ALL agents to complete before proceeding.

Phase 3: Consolidation
- Review all outputs
```

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

---

## 🏗️ Plugin Building Workflow

### Correct Order (plugin-create command)

```
1. Verify location (pwd check)
2. Gather requirements (AskUserQuestion)
3. Create directory structure
4. Build commands (ONE AT A TIME):
   - Run /slash-commands-create command1
   - Wait for completion
   - Run /slash-commands-create command2
   - Wait for completion
5. Build agents (ONE AT A TIME):
   - Run /agents-create agent1
   - Wait for completion
   - Run /agents-create agent2
   - Wait for completion
6. Build skills (can be parallel via Task):
   - Task() for skill1
   - Task() for skill2
   - Task() for skill3
   - Wait for all
7. Validate all components
8. Update marketplace.json
9. Register in settings.local.json
10. Git commit and push
11. Display summary
```

**CRITICAL:** Steps 4-5 must run sequentially, one command at a time!

---

## 📚 Documentation Rules

### Documentation Location

**Each plugin should have its own docs:**
```
plugins/{plugin-name}/
├── docs/
│   ├── getting-started.md
│   ├── commands.md
│   ├── agents.md
│   ├── skills.md
│   └── api-reference.md
```

**Root docs/ is ONLY for:**
- Cross-plugin documentation
- Framework documentation
- Architecture documentation

**SDK documentation stays in:**
```
plugins/domain-plugin-builder/docs/sdks/
├── fastmcp-documentation.md
├── vercel-ai-sdk-documentation.md
├── supabase-documentation.md
└── elevenlabs-documentation.md
```

### WebFetch Pattern

Commands and agents should use WebFetch for latest docs:
```
Phase 1: Load Documentation
- Load SDK docs: @plugins/domain-plugin-builder/docs/sdks/{sdk}-documentation.md
- WebFetch latest API changes from official docs
```

---

## ✅ Validation Requirements

### Before ANY commit:

1. **Command Validation:**
   ```bash
   bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-command.sh
   ```

2. **Agent Validation:**
   ```bash
   bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-agent.sh
   ```

3. **Skill Validation:**
   ```bash
   bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-skill.sh
   ```

4. **Complete Plugin Validation:**
   ```bash
   bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-plugin.sh plugins/{name}
   ```

### Auto-Fix Tools

**Fix tool formatting:**
```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/fix-tool-formatting.sh
```

**Fix plugin manifest:**
```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-plugin-manifest.sh {plugin} --fix
```

---

## 🎯 Agent Invocation in Commands

### WRONG (Natural Language):
```
Launch the security-specialist agent to audit authentication.

Provide the agent with:
- Provider list: [providers]
- Focus: RLS policies, OAuth config
```

This doesn't work! Natural language doesn't execute Task() calls.

### CORRECT (Task Tool Syntax):
```
Task(description="Audit authentication", subagent_type="security-specialist", prompt="You are the security-specialist agent. Audit authentication for $ARGUMENTS.

Provider list: [providers]
Focus: RLS policies, OAuth config
Deliverable: Security audit report")
```

---

## 🔍 Common Mistakes to Avoid

1. **Running slash commands in parallel** - They don't execute
2. **Using Task(agent-name) in allowed-tools** - Should just be `Task`
3. **Forgetting git push** - Work gets lost
4. **Using wildcards with MCP tools** - Not supported
5. **Vertical tool lists** - Use horizontal comma-separated
6. **JSON array tools** - Use plain comma-separated
7. **Missing basic tools in commands** - Need Read, Write, Bash, etc.
8. **Not waiting for command completion** - Sequential commands fail
9. **Natural language agent invocation** - Use Task() syntax
10. **Commands with only Task tool** - Need full tool set

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
3. Sequential - Multiple slash commands (wait between each)
4. Parallel - Multiple Task() calls (all at once)

### Git Workflow
1. Create/modify
2. Validate
3. `git add`
4. `git commit`
5. **`git push`** ← MANDATORY!

---

**Last Updated:** 2025-10-31
**Maintained By:** domain-plugin-builder team
