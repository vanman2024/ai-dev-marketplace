# Claude Code Plugin Components: Decision Framework

> **Comprehensive guide for choosing the right component type when building Claude Code plugins**

**Use this when:** Building plugins, creating skills, designing agents, or deciding "what kind of component should this be?"

---

## Overview

Claude Code plugins bundle five component types:
- **Skills** - Reusable domain knowledge + executable tools (model-invoked)
- **Agents** - Autonomous specialists for complex multi-step workflows
- **Commands** - User-invoked orchestration workflows (slash commands)
- **Hooks** - Event-triggered automation (background processing)
- **MCP Servers** - External tool integrations (API wrappers)

**This document answers:** "When do I use which component type?"

---

## Quick Decision Tree

Start with your intent:

```
What are you building?

├─ Reusable knowledge + tools agents can use?
│  └─ CREATE A SKILL
│     Examples: provider-config-validator, pgvector-setup, auth-configs
│
├─ Multi-step expert workflow with decision-making?
│  └─ CREATE AN AGENT
│     Examples: vercel-ai-ui-agent, supabase-schema-architect, mem0-integrator
│
├─ User-invoked workflow they trigger directly?
│  └─ CREATE A COMMAND
│     Examples: /vercel-ai-sdk:add-ui-features, /supabase:create-schema
│
├─ Automated response to events (no user trigger)?
│  └─ CREATE A HOOK
│     Examples: auto-save on edit, cost tracking, compliance checks
│
└─ External API/service integration?
   └─ CREATE AN MCP SERVER
      Examples: google-vertex-ai-mcp, supabase-mcp, github-mcp
```

---

## Component Types Deep Dive

### 1. Skills: Reusable Knowledge + Tools

**What are skills?**
- Organized folders of instructions, scripts, templates, and resources
- Invoked BY agents (not directly by users)
- Provide domain expertise and executable tools
- Follow progressive disclosure pattern (load only what's needed)

**When to create a skill:**
- ✅ Adding domain-specific expertise to agents
- ✅ Providing reusable templates/scripts across multiple agents
- ✅ Packaging best practices and patterns
- ✅ Creating troubleshooting/validation capabilities
- ✅ Encapsulating knowledge that doesn't require decision-making

**Structure:**
```
skills/
  my-skill/
    SKILL.md              # Core instructions
    scripts/              # Executable scripts
      setup.sh
      validate.sh
    templates/            # Code/config templates
      config.yaml
      schema.sql
    examples/             # Usage examples
      tutorial.md
```

**How agents use skills:**
```markdown
# Agent uses skill scripts
Bash: bash plugins/my-plugin/skills/my-skill/scripts/setup.sh

# Agent reads skill templates
Read: plugins/my-plugin/skills/my-skill/templates/config.yaml

# Agent loads skill examples
Read: plugins/my-plugin/skills/my-skill/examples/tutorial.md
```

**Real-world examples:**

**provider-config-validator (vercel-ai-sdk):**
- Scripts: `validate-provider.sh`, `check-model-compatibility.sh`, `generate-fix.sh`
- Templates: `.env`, error handler code
- Examples: Troubleshooting guide with 10+ scenarios
- Used by: Multiple agents when setting up AI providers

**pgvector-setup (supabase):**
- Scripts: `setup-pgvector.sh`, `create-indexes.sh`, `test-vector-search.sh`
- Templates: `embedding-table-schema.sql`, `hnsw-index.sql`
- Examples: Semantic search usage, RAG implementation guide
- Used by: Agents implementing vector search

---

### 2. Agents: Autonomous Specialists

**What are agents?**
- Autonomous specialists for complex multi-step workflows
- Make decisions, fetch documentation dynamically (WebFetch)
- Orchestrate multiple tools and skills
- Invoked by commands (not directly by users)

**When to create an agent:**
- ✅ Multi-step workflows requiring decision-making
- ✅ Complex implementation tasks with branching logic
- ✅ Need to fetch latest documentation dynamically
- ✅ Stateful coordination across multiple operations
- ✅ Domain expertise requiring autonomous reasoning

**Structure:**
```markdown
---
name: my-agent
description: Does complex multi-step workflow
tools: Bash, Read, Write, Edit, WebFetch
---

You are a specialist in [domain].

## Phase 1: Discovery
- WebFetch: https://docs.example.com/latest
- Analyze requirements

## Phase 2: Implementation
- Use skills for reusable tasks
- Make autonomous decisions
- Generate code/configs

## Phase 3: Validation
- Test implementations
- Fix issues
```

**How commands use agents:**
```markdown
# Command invokes agent
Phase 3: Implementation

Launch the vercel-ai-ui-agent to implement UI features.

Provide the agent with:
- Feature requirements from Phase 1
- Project context from Phase 2
```

**Real-world examples:**

**vercel-ai-ui-agent:**
- Purpose: Implement Vercel AI SDK UI features (generative UI, useObject, etc.)
- Fetches: Latest SDK documentation via WebFetch
- Decides: Which patterns to use based on requirements
- Uses: Could use ui-patterns skill for templates (doesn't exist yet)

**supabase-schema-architect:**
- Purpose: Design database schemas for AI applications
- Fetches: Latest Supabase patterns and best practices
- Decides: Table structure, relationships, indexes
- Uses: schema-patterns skill for templates

---

### 3. Commands: User-Invoked Workflows

**What are commands?**
- Slash commands users type directly (`/plugin:command-name`)
- Orchestrate agents and tools
- Ask clarifying questions (AskUserQuestion)
- Return structured output to user

**When to create a command:**
- ✅ User needs to trigger a workflow directly
- ✅ Orchestrating multiple agents/tools sequentially or in parallel
- ✅ Need to ask user questions before proceeding
- ✅ Entry point for complex plugin functionality
- ✅ Providing clear user-facing interface

**Structure:**
```markdown
---
description: User-facing description of what command does
argument-hint: <arg1> [optional-arg]
allowed-tools: Task, Read(*), AskUserQuestion(*)
---

**Arguments**: $ARGUMENTS

Goal: What this command accomplishes

Phase 1: Discovery
- Ask user questions
- Detect project context

Phase 2: Planning
- Determine approach

Phase 3: Implementation
Launch the my-agent to implement feature.

Phase 4: Summary
- Display results
- Show next steps
```

**Real-world examples:**

**/vercel-ai-sdk:add-ui-features:**
- User types: `/vercel-ai-sdk:add-ui-features`
- Asks: Which features? (generative UI, useObject, etc.)
- Invokes: `vercel-ai-ui-agent` to implement
- Returns: Summary of files created, next steps

**/supabase:create-schema chat:**
- User types: `/supabase:create-schema chat`
- Asks: Multi-tenant? User isolation type?
- Invokes: `supabase-schema-architect` agent
- Returns: SQL files, migration steps

---

### 4. Hooks: Event-Triggered Automation

**What are hooks?**
- Background automation triggered by events
- No direct user invocation
- Process events like PreToolUse, PostToolUse, SessionStart, etc.
- Run scripts or commands automatically

**When to create a hook:**
- ✅ Automated response to specific events
- ✅ Background processing (logging, tracking, validation)
- ✅ Enforcing policies or compliance
- ✅ Automatic cleanup or optimization
- ✅ Event-driven workflows

**Structure:**
```json
{
  "PreToolUse": [{
    "name": "cost-tracker"
    "hooks": [{
      "type": "command"
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/track-cost.sh"
    }]
  }]
  "PostToolUse": [{
    "name": "auto-save"
    "hooks": [{
      "type": "command"
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/save-state.sh"
    }]
  }]
}
```

**Available events:**
- `PreToolUse` - Before any tool execution
- `PostToolUse` - After any tool execution
- `UserPromptSubmit` - When user submits message
- `SessionStart` - When session begins
- `SessionEnd` - When session ends
- `PreCompact` - Before context window compaction

**Real-world examples:**

**Cost Tracking Hook:**
- Event: `PreToolUse` (before API calls)
- Action: Log API usage, track token costs
- No user interaction, runs automatically

**Auto-Save Hook:**
- Event: `PostToolUse` (after file edits)
- Action: Save progress to disk
- Ensures work isn't lost

---

### 5. MCP Servers: External Tool Integration

**What are MCP servers?**
- External processes that provide tools/resources/prompts
- Wrap external APIs or services
- Used by agents and commands via tool calls
- Live separately from plugin (can be shared across plugins)

**When to create an MCP server:**
- ✅ Wrapping external APIs (REST, GraphQL, etc.)
- ✅ Integrating third-party services
- ✅ Providing tools that require persistent connections
- ✅ Complex authentication flows (OAuth, JWT)
- ✅ Resource-intensive operations (database queries, file systems)

**Structure:**
```python
from fastmcp import FastMCP

mcp = FastMCP("My MCP Server")

@mcp.tool()
async def call_external_api(param: str) -> str:
    """Tool description"""
    # Call external API
    return result

@mcp.resource("config://settings")
async def get_settings() -> str:
    """Resource description"""
    return config_data
```

**How agents use MCP servers:**
```markdown
# Agent calls MCP tool
Use the mcp__my_server__call_external_api tool to fetch data

# Agent reads MCP resource
Read the mcp__my_server__config://settings resource
```

**Real-world examples:**

**google-vertex-ai-mcp:**
- Purpose: Wrap Imagen 3 and Veo 2 APIs
- Tools: `generate_image_imagen3`, `generate_video_veo2`
- Used by: image-generator agent, video-generator agent

**supabase-mcp:**
- Purpose: Database operations (SQL execution, migrations)
- Tools: `execute_sql`, `apply_migration`, `get_schema`
- Used by: All Supabase plugin agents for database work

---

## Component Boundaries

### Skills vs Agents

| Aspect | Skill | Agent |
|--------|-------|-------|
| **Autonomy** | Passive (invoked by agents) | Autonomous (makes decisions) |
| **Scope** | Single focused capability | Multi-step workflow |
| **Doc Fetching** | Static docs in skill directory | Dynamic WebFetch at runtime |
| **Scripts** | Yes (functional scripts) | No (delegates to skills) |
| **Templates** | Yes (reusable code/config) | No (uses skills' templates) |
| **Decision-Making** | Minimal (scripts execute) | Complex (reasoning required) |
| **Invocation** | Via Bash/Read tools | Via Task tool from commands |

**Example:**
- **Skill:** `provider-config-validator` has scripts that validate API keys
- **Agent:** `vercel-ai-setup` uses that skill when setting up providers

### Commands vs Agents

| Aspect | Command | Agent |
|--------|---------|-------|
| **Invocation** | User types `/command` | Command invokes via Task tool |
| **Orchestration** | Yes (manages workflow) | No (performs work) |
| **User Interaction** | Yes (AskUserQuestion) | No (receives context from command) |
| **Decision-Making** | Minimal (routing logic) | Complex (implementation decisions) |
| **Visibility** | User-facing | Internal to command |

**Example:**
- **Command:** `/vercel-ai-sdk:add-ui-features` asks which features to add
- **Agent:** `vercel-ai-ui-agent` implements those features autonomously

### Skills vs MCP Servers

| Aspect | Skill | MCP Server |
|--------|-------|------------|
| **Location** | Plugin directory | External process |
| **Purpose** | Domain knowledge + tools | API integration |
| **Provides** | Scripts, templates, examples | Tools, resources, prompts |
| **Reusability** | Within plugin ecosystem | Across all Claude apps |
| **Complexity** | Simple (bash scripts) | Complex (API clients, auth) |
| **State** | Stateless | Can maintain connections |

**Example:**
- **Skill:** `pgvector-setup` has SQL templates for vector search
- **MCP Server:** `supabase-mcp` executes those SQL templates on database

### Hooks vs Commands

| Aspect | Hook | Command |
|--------|------|---------|
| **Trigger** | Event-driven (automatic) | User-driven (manual) |
| **User Interaction** | None | Yes (slash command) |
| **Timing** | Background/during events | On-demand |
| **Visibility** | Hidden from user | Explicit user action |

**Example:**
- **Hook:** Auto-saves on file edit (PostToolUse event)
- **Command:** `/save-state` manually saves state when user requests

---

## Component Interaction Patterns

### Pattern 1: Command → Agent → Skill

**Most common pattern for feature implementation**

```
User: /vercel-ai-sdk:add-ui-features
  ↓
Command: add-ui-features.md
  - Asks clarifying questions (AskUserQuestion)
  - Detects project context (Read package.json)
  - Invokes agent
  ↓
Agent: vercel-ai-ui-agent
  - Fetches latest docs (WebFetch)
  - Makes implementation decisions
  - Uses skills for reusable tasks
  ↓
Skill: ui-patterns (hypothetical)
  - Provides templates (Read templates/)
  - Runs validation scripts (Bash scripts/)
```

### Pattern 2: Command → Agent → MCP Server

**When external APIs are involved**

```
User: /google-vertex-ai:generate-image "sunset over mountains"
  ↓
Command: generate-image.md
  - Validates inputs
  - Prepares context
  - Invokes agent
  ↓
Agent: image-generator
  - Optimizes prompt
  - Calls MCP tool
  - Post-processes result
  ↓
MCP Server: google-vertex-ai-mcp
  - Authenticates with Google
  - Calls Imagen 3 API
  - Returns image URL
```

### Pattern 3: Command → Skill (Direct)

**Simple validation/utility tasks that don't need agents**

```
User: /vercel-ai-sdk:validate-provider openai
  ↓
Command: validate-provider.md
  - Delegates directly to skill
  ↓
Skill: provider-config-validator
  - Runs validate-provider.sh script
  - Returns diagnostics
```

### Pattern 4: Hook → Skill → MCP Server

**Automated background processing**

```
Event: PostToolUse (after API call)
  ↓
Hook: cost-tracker
  - Invokes skill script
  ↓
Skill: usage-tracking
  - Parses tool usage
  - Formats data
  - Calls MCP tool
  ↓
MCP Server: analytics-mcp
  - Stores usage data
  - Updates dashboards
```

---

## Real-World Plugin Examples

### Example 1: Vercel AI SDK Plugin

**Current Architecture:**

**Commands (11):**
- `new-app` - Create new AI app
- `add-streaming`, `add-tools`, `add-chat`, `add-provider` - Core features
- `add-ui-features`, `add-data-features`, `add-production`, `add-advanced` - Feature bundles
- `build-full-stack` - Complete orchestrator

**Agents (7):**
- `vercel-ai-verifier-ts/js/py` - Validation specialists
- `vercel-ai-ui-agent` - UI feature implementation
- `vercel-ai-data-agent` - RAG/embeddings implementation
- `vercel-ai-production-agent` - Telemetry/testing implementation
- `vercel-ai-advanced-agent` - Agents/MCP/multi-modal implementation

**Skills (1):**
- `provider-config-validator` - Provider troubleshooting

**Potential New Skills:**
- `generative-ui-patterns` - AI RSC templates and examples
- `rag-implementation` - Vector DB schemas, embedding strategies
- `production-setup` - Telemetry configs, rate limiting templates

**Analysis:**
✅ Well-architected: Commands orchestrate, agents implement, skill provides validation
🔄 Could expand: More skills for reusable patterns (templates, boilerplate)

### Example 2: Supabase Plugin

**Current Architecture:**

**Commands (16):**
- `init`, `create-schema`, `setup-pgvector`, `add-auth`, etc.

**Agents (11):**
- `supabase-schema-architect` - Database design
- `supabase-ai-specialist` - AI feature implementation
- `supabase-security-specialist` - Auth and RLS
- Validators, executors, testers, etc.

**Skills (4):**
- `pgvector-setup` - Vector search scripts/templates
- `auth-configs` - OAuth provider setup
- `rls-templates` - Row Level Security patterns
- `schema-patterns` - Database schema templates

**MCP Server:**
- `supabase-mcp` - Database operations via MCP

**Analysis:**
✅ Excellent architecture: Clear separation, rich skill library
✅ Skills provide reusable capabilities agents consume
✅ MCP server handles database operations consistently

### Example 3: Mem0 Plugin

**Current Architecture:**

**Commands (9):**
- `init`, `add-conversation-memory`, `add-user-memory`, `configure`, etc.

**Agents (3):**
- `mem0-integrator` - Memory integration implementation
- `mem0-memory-architect` - Memory system design
- `mem0-verifier` - Setup validation

**Skills (1):**
- `memory-design-patterns` - Retention policies, cost analysis

**Analysis:**
✅ Good separation: Commands route, agents implement, skill provides patterns
🔄 Could expand: More skills for integration templates

---

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Logic in Commands

**Problem:** Commands should orchestrate, not implement

```markdown
<!-- BAD: Command does everything -->
Phase 3: Implementation
Actions:
- Install packages: npm install ai
- Create files: Write src/chat.ts
- Configure settings: Edit package.json
- Run migrations: Bash npx migrate
- (100+ lines of implementation logic)
```

```markdown
<!-- GOOD: Command delegates to agent -->
Phase 3: Implementation
Actions:

Launch the vercel-ai-ui-agent to implement UI features.

Provide the agent with:
- Feature selections from Phase 2
- Project context from Phase 1
```

### ❌ Anti-Pattern 2: Agents for Simple Tasks

**Problem:** Agents are for complex workflows, not simple scripts

```markdown
<!-- BAD: Agent for trivial task -->
---
name: file-mover
description: Moves files from source to destination
---

Move files using the mv command.
```

```markdown
<!-- GOOD: Skill for simple task -->
skills/file-operations/
  SKILL.md
  scripts/
    move-files.sh
    copy-files.sh
```

### ❌ Anti-Pattern 3: Hardcoded API Calls in Skills

**Problem:** Skills are for knowledge, MCP servers for APIs

```bash
# BAD: API call in skill script
# skills/image-gen/scripts/generate.sh
curl -X POST https://api.imagen.com/generate \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"prompt": "sunset"}'
```

```python
# GOOD: MCP server for API
# imagen-mcp/server.py
@mcp.tool()
async def generate_image_imagen3(prompt: str) -> str:
    """Generate image using Imagen 3 API"""
    return await call_imagen_api(prompt)
```

### ❌ Anti-Pattern 4: Duplicate Skills and Agents

**Problem:** Functionality exists in both skill and agent

```
❌ BAD:
skills/auth-setup/scripts/setup-oauth.sh
agents/auth-setup-agent.md (does same thing)

✅ GOOD:
skills/auth-configs/scripts/setup-oauth.sh
agents/auth-specialist.md (uses the skill)
```

### ❌ Anti-Pattern 5: Commands Without Arguments

**Problem:** Every workflow needs different command

```markdown
<!-- BAD: Separate command for each provider -->
/vercel-ai-sdk:add-openai
/vercel-ai-sdk:add-anthropic
/vercel-ai-sdk:add-google
(50+ commands for every provider)
```

```markdown
<!-- GOOD: Single command with arguments -->
/vercel-ai-sdk:add-provider openai
/vercel-ai-sdk:add-provider anthropic
/vercel-ai-sdk:add-provider google
```

---

## When in Doubt: Decision Checklist

### 🚨 CRITICAL: Start with Commands, Not Skills

**The Prompt is the Primitive**

Before creating ANY other component type, ask: "Can I do this with a slash command?"

**Default Hierarchy (ALWAYS follow this order):**
1. **Start with a COMMAND (slash command)** - The primitive, closest to bare metal
2. **Add SUB AGENT** if you need parallelization or context isolation
3. **Add SKILL** only when you need to MANAGE multiple related commands
4. **Add MCP SERVER** if external APIs are involved
5. **Add HOOKS** if you need deterministic automation

### The "One-Off vs Management" Test

**Ask:** "Is this a one-off task or am I managing a problem space?"

**One-Off Task:**
```
✅ CREATE: /create-worktree red-tree
❌ DON'T: Build a skill for single worktree creation
```

**Management Problem:**
```
❌ BAD: Multiple separate commands
  /create-worktree
  /remove-worktree
  /list-worktrees
  /merge-worktree

✅ GOOD: Single skill that manages worktrees
  skills/worktree-manager/
    - Uses /create-worktree command internally
    - Uses /remove-worktree command internally
    - Agents invoke skill to manage entire worktree lifecycle
```

### Critical Questions Before Creating a Skill

**Ask these questions in order:**

#### 1. Can I solve this with a slash command?
- ✅ **YES** → Use a command (don't create skill)
- ❌ **NO** → Continue to question 2

#### 2. Do I need to MANAGE multiple related operations?
- Examples:
  - Managing git worktrees (create, remove, list, merge)
  - Managing PDFs (extract, process, analyze, convert)
  - Managing database schemas (create, validate, migrate, rollback)
- ✅ **YES** → Skill might be appropriate, continue to question 3
- ❌ **NO** → Use a command or sub agent instead

#### 3. Will agents invoke this automatically?
- Does this run without user explicitly calling it?
- Should agents decide when to use this?
- ✅ **YES** → Skill is appropriate
- ❌ **NO** → Use a command instead (manual invocation)

#### 4. Do I need multiple commands/scripts composed together?
- Multiple bash scripts for different operations?
- Multiple templates for different scenarios?
- Multiple examples for different use cases?
- ✅ **YES** → Skill is appropriate
- ❌ **NO** → Simple command is sufficient

### Composition Hierarchy

**Commands are compositional primitives:**

```
Skill (highest level - MANAGES problem space)
  └─ Uses Command 1 (via SlashCommand tool)
  └─ Uses Command 2 (via SlashCommand tool)
  └─ Uses Sub Agent (for parallel work)
      └─ Uses Command 3 (sub agent invokes command)
  └─ Uses MCP Server (for external APIs)

Command (primitive - SOLVES specific task)
  └─ Can invoke agents
  └─ Can use MCP servers
  └─ Can call other commands
```

**Key Insight:** Skills use commands, not the other way around!

### Real-World Example: Git Worktrees

**WRONG Approach:**
```
❌ Create git-worktree skill first
   - Skill for creating worktrees
   - Agents invoke it for single task
   - Overkill for one operation
```

**RIGHT Approach:**
```
✅ Step 1: Create /create-worktree command
   - Solves specific problem
   - User can invoke manually
   - Works perfectly for one-off tasks

✅ Step 2: Create /create-worktree sub agent (if needed)
   - For parallel worktree creation
   - Invokes the command internally
   - Context isolation

✅ Step 3: Create worktree-manager skill (only when needed)
   - MANAGES entire worktree lifecycle
   - Uses /create-worktree command internally
   - Uses /remove-worktree command internally
   - Uses /list-worktrees command internally
   - Uses /merge-worktree command internally
   - Agents invoke skill to manage worktrees holistically
```

### Ask Yourself These 5 Core Questions

#### 1. Is this reusable knowledge or tools FOR MANAGING a problem space?
- **Scripts** that agents can execute?
- **Templates** that agents can customize?
- **Examples** showing best practices?
- **MANAGES** multiple related operations?
- **If YES → MIGHT BE A SKILL** (check other questions)
- **If NO → USE A COMMAND**

#### 2. Does it require autonomous decision-making?
- **Multi-step** reasoning needed?
- **Dynamic documentation** fetching required?
- **Complex implementation** with branching logic?
- **If YES → CREATE AN AGENT**

#### 3. Does the user invoke it directly OR is it a one-off task?
- Users **type a command** to trigger it?
- Needs to **ask questions** before proceeding?
- **One-time operation** that doesn't require management?
- **If YES → CREATE A COMMAND**

#### 4. Is it triggered by an event?
- Runs **automatically** in background?
- No **user interaction** needed?
- Responds to **specific events** (save, edit, etc.)?
- **If YES → CREATE A HOOK**

#### 5. Does it wrap an external API?
- Calls **third-party services**?
- Requires **authentication/connection management**?
- Provides **tools/resources** to agents?
- **If YES → CREATE AN MCP SERVER**

### When NOT to Create a Skill

❌ **Don't create a skill if:**
- You only need to do something ONCE
- A single command solves the problem
- You're not managing multiple related operations
- Agents don't need to invoke it automatically
- Users will manually trigger it every time

✅ **Use a command instead:**
- Simpler
- More explicit
- Easier to debug
- Mastering commands = mastering prompts = foundation of AI engineering

### Master the Fundamentals

**The Core 4 of Agentic Coding:**
1. **Context** - What information is available
2. **Model** - Which AI model to use
3. **Prompt** - Instructions (THE PRIMITIVE)
4. **Tools** - Available capabilities

**Everything builds on The Core 4:**
- Commands = Prompts with tool access
- Agents = Commands with autonomy
- Skills = Managed command collections
- Sub Agents = Isolated command execution
- MCP Servers = External tool providers
- Hooks = Automated command execution

**If you don't master prompts (commands), you can't master anything else.**

---

## References

### Official Documentation
- [Agent Skills Engineering Blog](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Claude Code Skills Docs](https://docs.claude.com/en/docs/claude-code/skills)
- [Claude Code Plugins Docs](https://docs.claude.com/en/docs/claude-code/plugins)
- [Claude Code Commands Docs](https://docs.claude.com/en/docs/claude-code/slash-commands)

### Related Framework Docs
- [Agent Skills Architecture](./agent-skills-architecture.md) - Deep dive on skills
- [Claude Code Plugin Structure](../plugins/claude-code-plugin-structure.md) - Plugin manifest and directories
- [Claude Code README](./README.md) - Cross-framework concepts

---

**Last Updated:** October 27, 2025
**Purpose:** Architectural decision guide for plugin builders
**Audience:** Plugin developers, skills-builder agents, command creators
