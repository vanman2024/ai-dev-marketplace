---
allowed-tools: Read(*), Write(*), Edit(*), Bash(*), Grep(*), Glob(*), AskUserQuestion(*)
description: Create new slash command following standardized structure
argument-hint: <command-name> "<description>" [--plugin=name] [--mcp=server1,server2] [agent1] [agent2] [agent3]
---

**Arguments**: $ARGUMENTS

## Step 1: Gather Information

If arguments are missing or incomplete, use AskUserQuestion to gather:

1. **Command name** - What should the command be called?
2. **Description** - What does this command do?
3. **Command scope** - Global command or plugin-specific?
   - If plugin: Which plugin?
4. **Agent delegation** - Does this command use agents?
   - None (Pattern 1 - simple command)
   - Single agent (Pattern 2 - which agent?)
   - Multiple agents sequential (Pattern 3 - which agents in order?)
   - Multiple agents parallel (Pattern 4 - which agents run together?)
   - Fallback: Use general-purpose agent if no specific agent needed
5. **Execution mode** - For multi-agent commands:
   - Sequential (one after another)
   - Parallel (all at once)
   - Hybrid (some parallel, then next group)
6. **Script usage** - Will this execute scripts? (Bash, Python, Node.js)
   - Location: Use shared scripts in skills/build-assistant/scripts/
7. **MCP integration** - Does this need MCP server tools?
   - Which MCP servers? (puppeteer, browserbase, github, etc.)
8. **Tool restrictions** - Any specific tool limitations?
   - Bash restrictions (git:*, npm:*, docker:*)
   - Other tool constraints

Parse provided arguments:
- **Command name**: First argument
- **Description**: Second argument in quotes
- **--plugin=name**: Plugin flag
- **--mcp=server1,server2**: MCP servers comma-separated
- **Agent names**: Remaining arguments for multi-agent commands

## Available Agents

Use Bash tool to load current agent list for context:
- Run: `bash plugins/domain-plugin-builder/skills/build-assistant/scripts/list-agents.sh`

## Context Files (MUST Read Before Building)

**CRITICAL - Read the master template file FIRST using Read tool:**
Path: plugins/domain-plugin-builder/skills/build-assistant/templates/commands/template-command-patterns.md

This master template is REQUIRED reading and contains:
- Pattern selection guide (4 patterns: Simple, Single Agent, Sequential, Parallel)
- Complete templates for all 4 patterns with Goal/Actions/Phase structure
- Natural language agent invocation (NOT Task() syntax)
- Syntax reference ($ARGUMENTS, @files, !{bash}, etc.)
- When to use agents vs inline code

**SDK Documentation Loading (for SDK plugin commands):**

If building a command for an SDK plugin (detected from --plugin flag or plugin name):

1. Check if SDK documentation exists:
   - Path: plugins/domain-plugin-builder/docs/sdks/<sdk-name>-documentation.md
2. If exists: Use Read tool to load it
   - This provides SDK features, WebFetch URLs, and context
3. In the command you create, add Phase 1 action to load this documentation:
   ```markdown
   Phase 1: Discovery
   Actions:
   - Load SDK documentation:
     @plugins/domain-plugin-builder/docs/sdks/<sdk-name>-documentation.md
   ```
4. Extract WebFetch URLs from docs for use in agents (Phase 4)

Example:
- Building: /claude-agent-sdk:add-streaming
- Loads: @plugins/domain-plugin-builder/docs/sdks/claude-agent-sdk-documentation.md
- Provides agent WebFetch URL: https://docs.claude.com/en/api/agent-sdk/streaming

## CRITICAL: Project-Agnostic Design

**All commands MUST follow these principles:**
- ❌ NEVER hardcode frameworks (Next.js, React, Django, etc.) - DETECT them
- ❌ NEVER assume project structure - ANALYZE it
- ❌ NEVER force conventions - ADAPT to existing patterns
- ✅ DO detect what exists (package.json, requirements.txt, Cargo.toml, etc.)
- ✅ DO adapt behavior based on findings
- ✅ DO work in ANY project type (frontend, backend, monorepo, etc.)

## Command Patterns Reference

**Pattern 1: Simple (No Agents)** - Bash/script execution with $ARGUMENTS

**Pattern 2: Single Agent** - One Task() call with agent or a general-purpose agent.

**Pattern 3: Sequential** - Multiple phases with dependencies, one after another

**Pattern 4: Multi-Agent Parallel** - Run multiple independent agents at the same time

**SlashCommand Usage** - Invoke other slash commands (add SlashCommand(*) to allowed-tools)

Example showing 3 agents running together (natural language):

Launch the following agents IN PARALLEL (all at once):
- Launch the code-scanner agent to scan for issues in $ARGUMENTS
- Launch the test-runner agent to test $ARGUMENTS
- Launch the security-checker agent to audit $ARGUMENTS

Wait for ALL agents to complete before proceeding.

## Key Features

Bash Execution: !{git status}
Script Execution: !{bash script.sh $ARGUMENTS}
File Loading: @package.json
Shared Scripts: skills/build-assistant/scripts/
SlashCommand Invocation: SlashCommand: /command-name args

Allowed Tools: Task(*), Read(*), Write(*), Edit(*), Bash(*), Grep(*), Glob(*), AskUserQuestion(*), SlashCommand(*), mcp__servername
Arguments: Always $ARGUMENTS (never $1/$2/$3)

**CRITICAL - SlashCommand Anti-Pattern:**
When invoking slash commands:
- Use SlashCommand tool ONLY - do not type command in response text
- Never mention the command before invoking (causes double execution)
- Invoke silently, report results after completion

## File Locations

Global command: ~/.claude/commands/COMMAND_NAME.md
Plugin command: ~/.claude/marketplaces/MARKETPLACE/plugins/PLUGIN_NAME/commands/COMMAND_NAME.md
Register in: ~/.claude/marketplaces/MARKETPLACE/plugins/PLUGIN_NAME/.claude-plugin/plugin.json

## Pattern Selection Decision Tree

**Use this to determine which pattern to use:**

**Step 1: Does this task require AI decision-making or complex analysis?**

**NO → Pattern 1 (Simple - No Agents)**
- Mechanical tasks: version bumping, file operations, config updates
- Script execution: running tests, builds, deployments (without decision-making)
- File manipulation: copying, moving, renaming
- Simple checks: file existence, git status
- Examples: `/version`, `/git-setup`, `/mcp-clear`

**YES → Step 2: How many specialized capabilities does it need?**

**ONE specialized capability → Pattern 2 (Single Agent)**
- Project analysis: framework detection, stack analysis
- Code generation: single component, single feature
- Architecture: designing one system aspect
- Refactoring: optimizing specific code area
- Check available agents list for specialized match
- Fallback: Use general-purpose agent if no specialist exists
- Examples: `/detect` (uses project-detector), `/init` (uses project-detector)

**MULTIPLE capabilities, must run in sequence → Pattern 3 (Sequential with SlashCommands)**
- **PREFERRED for orchestrators:** Chain slash commands, don't invoke agents directly
- Dependencies between steps (output of step 1 feeds step 2)
- Multi-phase workflows: build → test → deploy
- Orchestrator pattern: SlashCommand: /init → SlashCommand: /git-setup → SlashCommand: /mcp-setup
- Each slash command completes before next starts
- Each granular command handles its own agent delegation if needed
- Examples: `/core` orchestrator (chains /init, /git-setup, /mcp-setup), `/deploy` (chains build, upload, verify)
- **Why this is better than multiple agents:** Granular commands are reusable, testable, composable

**MULTIPLE capabilities, can run simultaneously → Pattern 4 (Parallel Agents)**
- **Use ONLY for parallel agent execution** (not slash commands - unknown if SlashCommands can run concurrently)
- Independent validation tasks: lint + test + security
- No dependencies between tasks
- All agents start together, results collected at the end
- Faster execution by running concurrently
- Syntax: Multiple Task() calls in single step, then "Wait for ALL agents to complete"
- Examples: `/validate` (lint agent + test agent + security agent all at once)
- **Note:** If unsure whether SlashCommands can run in parallel, use Pattern 3 (sequential) instead

**Pattern 3 vs Pattern 4 Decision:**
- If Task B needs output from Task A → Sequential (Pattern 3)
- If Task A and Task B are independent → Parallel (Pattern 4)

## Workflow (Beginning → Middle → End → Review)

**Phase 1: BEGINNING (Understand & Select Pattern)**
1. Read the master template: @plugins/domain-plugin-builder/skills/build-assistant/templates/commands/template-command-patterns.md
2. Understand what the command should accomplish from $ARGUMENTS and description
3. **Auto-detect which pattern to use** based on Pattern Selection guide in master template:
   - Simple mechanical task? → Pattern 1
   - One AI capability needed? → Pattern 2
   - Multi-phase with dependencies? → Pattern 3
   - Independent parallel checks? → Pattern 4
4. If arguments missing, use AskUserQuestion to gather info
5. Build allowed-tools based on pattern needs

**Phase 2: MIDDLE (Create Command Using Template)**
6. Use the appropriate pattern template from template-command-patterns.md
7. Create command file following the Goal → Actions → Phase structure
8. Use natural language for agent invocation (not Task() syntax)
9. Use proper syntax: $ARGUMENTS only, !{bash command} for execution, @filename for loading

**Phase 3: END (Validate)**
6. Use Bash tool to run validation: `bash skills/build-assistant/scripts/validate-command.sh COMMAND_FILE`
7. If validation fails, fix errors and re-validate until passing

**Phase 4: REVIEW (Finalize & Commit)**
8. Register in plugin.json if --plugin flag provided
9. **CRITICAL: Git commit and push immediately**
   - Add the new command file to git
   - Add marketplace.json if it was updated
   - Commit with descriptive message
   - Push to origin/master
10. Display summary with file path and usage

**Git Commit Steps:**

!{bash git add COMMAND_FILE_PATH}
!{bash git add .claude-plugin/marketplace.json} (if plugin command)

!{bash git commit -m "$(cat <<'EOF'
feat: Add /COMMAND_NAME command

COMMAND_DESCRIPTION

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"}

!{bash git push origin master}

## Success Criteria (ALL Required)

- ✅ Interactive mode works, valid frontmatter, correct pattern (1/2/3/4)
- ✅ Uses $ARGUMENTS (never $1/$2/$3)
- ✅ Proper allowed-tools with MCP, ! prefix for bash, @ for files
- ✅ No backticks, scripts in shared directory, under 150 lines
- ✅ **VALIDATION PASSES** - validate-command.sh returns ✅
- ✅ Registered in plugin.json if --plugin flag
- ✅ Summary displayed with file path and usage

## Usage Examples

Interactive (recommended):
/build-system:framework-slash-command

With arguments:
/build-system:framework-slash-command deploy "Deploy to production" --plugin=deployment deployment-manager

Parallel agents:
/build-system:framework-slash-command audit "Security audit" --parallel scanner validator reporter
