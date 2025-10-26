# Claude Agent SDK Plugin - Expansion Design

**Based on:** vercel-ai-sdk plugin pattern
**Date:** 2025-10-25
**Purpose:** Expand agent-sdk-dev from basic scaffolding to comprehensive SDK development tool

---

## Current State Analysis

### Existing agent-sdk-dev Plugin
- **Commands:** 1 command (`new-sdk-app`)
- **Agents:** 2 verifier agents (TypeScript, Python)
- **Scope:** Basic project scaffolding only
- **Limitation:** Doesn't leverage comprehensive SDK features

### Target Pattern (vercel-ai-sdk)
- **Commands:** 10 commands (core + bundles)
  - Core: `new-app`, `add-streaming`, `add-tools`, `add-chat`, `add-provider`
  - Bundles: `add-ui-features`, `add-data-features`, `add-production`, `add-advanced`
  - Full: `build-full-stack`
- **Agents:** 7 specialized agents (3 verifiers + 4 feature agents)
- **Documentation:** Progressive loading via Context7 MCP

---

## Command Structure Design

### Core Commands (Foundation)

#### 1. `/claude-agent-sdk:new-app`
**Purpose:** Initialize new Claude Agent SDK project
**Replaces:** Current `new-sdk-app`
**Features:**
- Choose language (TypeScript/Python)
- Project structure setup
- Install SDK dependencies
- Basic query() example
- Environment setup (.env with API keys)

**Docs Used:**
- Overview: https://docs.claude.com/en/api/agent-sdk/overview
- TypeScript SDK: https://docs.claude.com/en/api/agent-sdk/typescript
- Python SDK: https://docs.claude.com/en/api/agent-sdk/python

---

#### 2. `/claude-agent-sdk:add-streaming`
**Purpose:** Implement streaming input/output
**Features:**
- Streaming vs single mode handling
- Real-time response processing
- Progress indicators
- Cancellation handling

**Docs Used:**
- Streaming Input: https://docs.claude.com/en/api/agent-sdk/streaming-vs-single-mode

---

#### 3. `/claude-agent-sdk:add-tools`
**Purpose:** Add custom tool integration
**Features:**
- Tool schema definition
- Custom tool implementation
- Tool permission management
- Built-in tools configuration (Bash, Web, Code, File)

**Docs Used:**
- Custom Tools: https://docs.claude.com/en/api/agent-sdk/custom-tools
- Handling Permissions: https://docs.claude.com/en/api/agent-sdk/permissions

---

#### 4. `/claude-agent-sdk:add-sessions`
**Purpose:** Implement session management
**Features:**
- User session handling
- State persistence
- Conversation continuity
- Session storage (memory/database)

**Docs Used:**
- Session Management: https://docs.claude.com/en/api/agent-sdk/sessions

---

#### 5. `/claude-agent-sdk:add-mcp`
**Purpose:** Integrate MCP server capabilities
**Features:**
- MCP server integration
- createSdkMcpServer() implementation
- Resource providers
- Prompt templates

**Docs Used:**
- MCP in the SDK: https://docs.claude.com/en/api/agent-sdk/mcp

---

### Feature Bundle Commands

#### 6. `/claude-agent-sdk:add-agent-features`
**Purpose:** Advanced agent capabilities bundle
**Combines:**
- Subagents
- Slash commands
- Agent skills
- System prompt customization

**Docs Used:**
- Subagents in the SDK: https://docs.claude.com/en/api/agent-sdk/subagents
- Slash Commands in the SDK: https://docs.claude.com/en/api/agent-sdk/slash-commands
- Agent Skills in the SDK: https://docs.claude.com/en/api/agent-sdk/skills
- Agent Skills Overview: https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview
- Agent Skills Quickstart: https://docs.claude.com/en/docs/agents-and-tools/agent-skills/quickstart
- Agent Skills Best Practices: https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices
- Modifying System Prompts: https://docs.claude.com/en/api/agent-sdk/modifying-system-prompts

**Agent:** `claude-agent-features-agent`

---

#### 7. `/claude-agent-sdk:add-plugin-system`
**Purpose:** Plugin development and management
**Features:**
- Plugin structure setup
- Custom command creation
- Plugin loading configuration
- Plugin distribution

**Docs Used:**
- Plugins in the SDK: https://docs.claude.com/en/api/agent-sdk/plugins

**Agent:** `claude-agent-plugin-agent`

---

#### 8. `/claude-agent-sdk:add-production`
**Purpose:** Production-ready features
**Combines:**
- Cost tracking
- Todo tracking
- Error handling
- Logging/monitoring
- Performance optimization
- Hosting setup

**Docs Used:**
- Tracking Costs and Usage: https://docs.claude.com/en/api/agent-sdk/cost-tracking
- Todo Lists: https://docs.claude.com/en/api/agent-sdk/todo-tracking
- Hosting the Agent SDK: https://docs.claude.com/en/api/agent-sdk/hosting

**Agent:** `claude-agent-production-agent`

---

#### 9. `/claude-agent-sdk:add-migration`
**Purpose:** Migrate existing projects to Agent SDK
**Features:**
- Migration from Claude API direct usage
- Migration from other agent frameworks
- Version upgrade assistance
- Breaking change handling

**Docs Used:**
- Migration Guide: https://docs.claude.com/en/docs/claude-code/sdk/migration-guide

**Agent:** `claude-agent-migration-agent`

---

### Full Stack Command

#### 10. `/claude-agent-sdk:build-complete`
**Purpose:** Build complete Agent SDK application
**Combines:** All commands in sequence
1. new-app
2. add-streaming
3. add-tools
4. add-sessions
5. add-mcp
6. add-agent-features
7. add-plugin-system
8. add-production

**Use case:** Rapid prototyping, learning examples

---

## Specialized Agents Design

### 1. claude-agent-verifier-ts
**Type:** Verifier
**Purpose:** Validate TypeScript Agent SDK implementations
**Scope:** TypeScript-specific verification
**Tools:** Read, Bash, Grep

---

### 2. claude-agent-verifier-py
**Type:** Verifier
**Purpose:** Validate Python Agent SDK implementations
**Scope:** Python-specific verification
**Tools:** Read, Bash, Grep

---

### 3. claude-agent-features-agent
**Type:** Feature Implementation
**Purpose:** Implement advanced agent capabilities
**Scope:**
- Subagent creation
- Slash command implementation
- Agent skill development
- System prompt customization

**Tools:** Read, Write, Edit, Bash, WebFetch
**Context7 Topics:** "subagents", "slash commands", "agent skills", "system prompts"

---

### 4. claude-agent-plugin-agent
**Type:** Feature Implementation
**Purpose:** Build and manage plugins
**Scope:**
- Plugin structure
- Custom commands
- Plugin configuration
- Distribution setup

**Tools:** Read, Write, Edit, Bash, WebFetch
**Context7 Topics:** "plugins", "custom commands"

---

### 5. claude-agent-production-agent
**Type:** Feature Implementation
**Purpose:** Production readiness features
**Scope:**
- Cost tracking implementation
- Todo list integration
- Error handling patterns
- Monitoring setup
- Hosting configuration

**Tools:** Read, Write, Edit, Bash, WebFetch
**Context7 Topics:** "cost tracking", "todo tracking", "hosting"

---

### 6. claude-agent-migration-agent
**Type:** Feature Implementation
**Purpose:** Migration assistance
**Scope:**
- Analyze existing code
- Generate migration plan
- Implement changes
- Validate migration

**Tools:** Read, Write, Edit, Bash, Grep, WebFetch
**Context7 Topics:** "migration guide"

---

## Documentation Strategy

### Phase-Based Loading (Following vercel-ai-sdk Pattern)

#### Phase 1: Initialization
**Commands:** `new-app`
**Docs:** Static from claude-agent-sdk-documentation.md
- Quick start examples
- Installation instructions
- Basic concepts

#### Phase 2: Core Features
**Commands:** `add-streaming`, `add-tools`, `add-sessions`, `add-mcp`
**Docs:** Context7 MCP on-demand
- Specific feature implementation details
- Latest API changes
- Code examples

#### Phase 3: Advanced Features
**Commands:** `add-agent-features`, `add-plugin-system`
**Docs:** Context7 MCP on-demand
- Complex patterns
- Best practices
- Advanced examples

#### Phase 4: Production
**Commands:** `add-production`, `add-migration`
**Docs:** Context7 MCP on-demand
- Deployment guides
- Migration strategies
- Production patterns

---

## Command Template Structure

### Core Command Pattern
```markdown
# /claude-agent-sdk:add-{feature}

## Goal
Add {feature} to Claude Agent SDK project

## Actions
1. Verify SDK project exists
2. Check language (TypeScript/Python)
3. Fetch latest docs via Context7 for "{topic}"
4. Implement {feature} pattern
5. Add tests
6. Update project docs

## Phase 1: Validation
- Check for SDK installation
- Verify project structure
- Confirm language

## Phase 2: Documentation
- Use Context7 to fetch: /anthropic/claude-agent-sdk
- Topic: "{specific-topic}"
- Extract implementation patterns

## Phase 3: Implementation
- Generate code based on language
- Follow SDK best practices
- Integrate with existing code

## Phase 4: Verification
- Run SDK verifier agent
- Validate implementation
- Test functionality
```

---

## Feature Mapping from Documentation

### From claude-agent-sdk-documentation.md

| SDK Feature | Command | Agent | Priority |
|-------------|---------|-------|----------|
| Basic setup | new-app | verifier-ts/py | P0 |
| Streaming | add-streaming | - | P0 |
| Permissions | add-tools | - | P0 |
| Sessions | add-sessions | - | P0 |
| MCP integration | add-mcp | - | P1 |
| System prompts | add-agent-features | features-agent | P1 |
| Custom tools | add-tools | - | P0 |
| Subagents | add-agent-features | features-agent | P1 |
| Slash commands | add-agent-features | features-agent | P1 |
| Agent skills | add-agent-features | features-agent | P1 |
| Plugins | add-plugin-system | plugin-agent | P1 |
| Cost tracking | add-production | production-agent | P2 |
| Todo lists | add-production | production-agent | P2 |
| Hosting | add-production | production-agent | P2 |
| Migration | add-migration | migration-agent | P2 |

---

## Implementation Plan

### Step 1: Create Command Files
Use `/domain-plugin-builder:slash-commands-create` for each command:
1. new-app
2. add-streaming
3. add-tools
4. add-sessions
5. add-mcp
6. add-agent-features
7. add-plugin-system
8. add-production
9. add-migration
10. build-complete

### Step 2: Create Agent Files
Use `/domain-plugin-builder:agents-create` for each agent:
1. claude-agent-verifier-ts
2. claude-agent-verifier-py
3. claude-agent-features-agent
4. claude-agent-plugin-agent
5. claude-agent-production-agent
6. claude-agent-migration-agent

### Step 3: Move Documentation
Copy `claude-agent-sdk-documentation.md` from:
- `domain-plugin-builder/docs/sdks/`

To:
- `claude-agent-sdk/docs/` (new plugin structure)

### Step 4: Update Plugin Manifest
Update `.claude-plugin/plugin.json`:
- Name: "claude-agent-sdk"
- Description: Include "modular", "feature bundles", "specialized agents"
- Keywords: Add all relevant SDK features

### Step 5: Create MCP Integration
Add `.mcp.json` for Context7 integration:
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@uptime-tools/context7"],
      "disabled": false
    }
  }
}
```

---

## Success Criteria

### Feature Completeness
- ✅ 10 commands matching vercel-ai-sdk pattern
- ✅ 6 specialized agents
- ✅ All SDK features covered
- ✅ Progressive documentation loading

### Code Quality
- ✅ TypeScript and Python support
- ✅ Tests for each command
- ✅ Verifier agents validate implementations
- ✅ Error handling patterns

### Documentation
- ✅ Static docs for quick reference
- ✅ Context7 integration for latest API
- ✅ Examples for each feature
- ✅ Migration guides

### User Experience
- ✅ Incremental feature addition
- ✅ Complete app builder option
- ✅ Clear command naming
- ✅ Helpful error messages

---

## Comparison: Current vs Expanded

| Aspect | Current agent-sdk-dev | Expanded claude-agent-sdk |
|--------|----------------------|---------------------------|
| Commands | 1 (new-sdk-app) | 10 (core + bundles + full) |
| Agents | 2 (verifiers only) | 6 (verifiers + feature agents) |
| Features | Basic scaffolding | All SDK features |
| Docs | Static only | Hybrid (static + Context7) |
| Languages | TS, Python | TS, Python |
| Use Cases | Project init | Full development lifecycle |

---

## Next Steps

1. **Review this design** - Confirm approach aligns with vision
2. **Build commands** - Use domain-plugin-builder to create command files
3. **Build agents** - Use domain-plugin-builder to create agent files
4. **Move docs** - Relocate SDK documentation
5. **Test implementation** - Build example project using new commands
6. **Update marketplace** - Add expanded plugin to ai-dev-marketplace

---

**Version:** 1.0.0
**Last Updated:** 2025-10-25
**Maintained by:** ai-dev-marketplace team
