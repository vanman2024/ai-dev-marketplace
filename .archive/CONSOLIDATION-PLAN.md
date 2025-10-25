# Project Automation - Plugin Consolidation Plan

## Goal
Consolidate 28 scattered plugins → 6 lifecycle-ordered plugins that work together systematically.

**Pattern:** Each plugin follows orchestrator + granular commands + skills structure.

**Related Documentation:** See `LIFECYCLE-PLUGIN-GUIDE.md` in multiagent-build-system for HOW to build these plugins.

---

## Plugin Architecture Pattern

Every lifecycle plugin follows this structure:

### 1. Orchestrator Command
- **Purpose:** Single entry point that chains granular commands
- **Example:** `/develop` (chains /feature, /component, /api, /mcp-build based on what's being built)
- **Pattern:** Detects context → runs appropriate command chain

### 2. Granular Commands
- **Purpose:** Focused, standalone tasks that can run independently or be chained
- **Example:** `/feature`, `/component`, `/api`, `/mcp-build`
- **Pattern:** Each command does ONE thing well

### 3. Skills
- **Purpose:** Auto-invoked resources (templates, scripts, patterns) that Claude loads based on description matching
- **Example:** MCP Development skill auto-loads when building MCP servers
- **Pattern:** Provide supporting resources, not duplicate command functionality

### 4. Infrastructure
- **MCP Servers:** Marketplace-wide services (like memory-api)
- **Shared Resources:** Cross-plugin utilities

---

## Current State: 28 Plugins in multiagent-marketplace

1. multiagent-ai-infrastructure
2. multiagent-backend
3. multiagent-build-system (KEEP SEPARATE - build tooling)
4. multiagent-compliance
5. multiagent-core
6. multiagent-cto
7. multiagent-deployment
8. multiagent-docs
9. multiagent-enhancement
10. multiagent-frontend
11. multiagent-git
12. multiagent-github
13. multiagent-idea
14. multiagent-implementation
15. multiagent-iterate
16. multiagent-mcp
17. multiagent-memory
18. multiagent-notes
19. multiagent-observability
20. multiagent-performance
21. multiagent-profile
22. multiagent-refactoring
23. multiagent-reliability
24. multiagent-security
25. multiagent-supervisor
26. multiagent-validation
27. multiagent-version
28. multiagent-website-builder (KEEP SEPARATE - specialized tool)

---

## New Structure: 6 Lifecycle Plugins

### 1. **core** (Foundation & Setup)
**Purpose:** Initialize projects, detect stack, set up version control, configure MCP environment

**Consolidates:**
- multiagent-core → detection, initialization
- multiagent-git → git setup and workflows
- multiagent-github → GitHub integration
- multiagent-version → versioning strategy
- multiagent-mcp → MCP environment setup/configuration ONLY (not building)

**Orchestrator Command:**
- `/core` - Initialize complete project foundation (chains init → detect → git-setup → mcp-setup based on project state)

**Granular Commands:**
- `/init` - Initialize project (detect OR bootstrap)
- `/detect` - Analyze existing project structure
- `/git-setup` - Configure git workflows
- `/version` - Manage semantic versioning
- `/mcp-setup` - Configure MCP API keys (setup/config only)
- `/mcp-manage` - Manage MCP server configs (add/remove servers)
- `/mcp-info` - List available MCP servers
- `/mcp-clear` - Clear MCP server configs

**Skills:**
- Project detection (framework/stack analysis)
- Git workflow patterns
- MCP configuration templates

**Estimated Size:** 1 orchestrator + 8 granular commands, 3 skills

---

### 2. **planning** (Spec → Architecture)
**Purpose:** Create specs, plans, architecture, documentation

**Consolidates:**
- multiagent-docs → documentation generation
- multiagent-notes → note-taking and organization
- multiagent-idea → idea capture and refinement
- multiagent-cto → technical decision-making

**Orchestrator Command:**
- `/planning` - Full planning workflow (chains spec → architecture → plan → roadmap)

**Granular Commands:**
- `/spec` - Create specifications (works with spec-kit)
- `/plan` - Generate development plans
- `/architecture` - Design system architecture
- `/roadmap` - Create project roadmap
- `/notes` - Capture technical notes
- `/decide` - Make technical decisions (CTO-level)

**Skills:**
- Spec management patterns
- Architecture pattern library
- Decision tracking templates

**Estimated Size:** 1 orchestrator + 6 granular commands, 3 skills

---

### 3. **develop** (Code Generation & Implementation)
**Purpose:** Build features, scaffold code, implement functionality, create MCP servers

**Consolidates:**
- multiagent-frontend → React/Vue/Svelte components
- multiagent-backend → API/server code
- multiagent-implementation → general implementation
- multiagent-ai-infrastructure → AI/LLM integration
- multiagent-mcp → MCP server BUILDING commands + skill (not setup/config)

**Orchestrator Command:**
- `/develop` - Build any feature/component/API/MCP server (detects what's being built → chains appropriate commands)

**Granular Commands:**
- `/feature` - Add new feature (reads specs)
- `/component` - Generate UI component
- `/api` - Create API endpoint
- `/scaffold` - Scaffold entire module
- `/ai-integration` - Add AI capabilities
- `/mcp-build` - Build complete FastMCP server (references .claude/commands/mcp/build-complete-fastmcp-server.md)
- `/mcp-test` - Test MCP servers (references .claude/commands/mcp/mcp-comprehensive-testing.md)

**Skills:**
- Code generation patterns (20+ frameworks)
- Component library templates
- API pattern library
- **MCP Development** - FastMCP templates, patterns, testing (from multiagent-mcp)

**Estimated Size:** 1 orchestrator + 7 granular commands, 4 skills

**Note:** MCP building is development work, just like building APIs or components. Setup/config stays in core.

---

### 4. **iterate** (Refinement & Adjustment)
**Purpose:** Modify, refactor, enhance, sync during active development

**Consolidates:**
- multiagent-iterate → /adjust, /sync, /tasks + task-layering agent
- multiagent-supervisor → /start, /mid, /end (worktree management)
- multiagent-refactoring → code refactoring
- multiagent-enhancement → feature enhancements

**Orchestrator Command:**
- `/iterate` - Full iteration workflow (chains tasks → start → [development] → mid → end)

**Granular Commands:**
- `/tasks` - Task layering (invokes task-layering agent)
- `/start` - Setup worktrees for parallel work
- `/mid` - Check progress during development
- `/end` - Validate completion
- `/adjust` - Modify features mid-development
- `/sync` - Sync changes across agents
- `/refactor` - Refactor code
- `/enhance` - Enhance existing features

**Skills:**
- Iteration tracking patterns
- Worktree management scripts (from multiagent-supervisor)
- Task layering scripts (from multiagent-iterate)
- Code refactoring patterns

**Estimated Size:** 1 orchestrator + 8 granular commands, 4 skills

**Critical:** Task-layering agent (reads spec tasks.md → creates layered-tasks.md) must be preserved

---

### 5. **quality** (Testing & Validation)
**Purpose:** Test, validate, secure, optimize, ensure compliance

**Consolidates:**
- multiagent-validation → testing and validation
- multiagent-security → security scanning
- multiagent-reliability → reliability checks
- multiagent-performance → performance optimization
- multiagent-compliance → compliance checks

**Orchestrator Command:**
- `/quality` - Full quality check (chains test → security → performance → validate → compliance)

**Granular Commands:**
- `/test` - Run tests (detects framework's test tools)
- `/test-generate` - Generate tests from specs
- `/security` - Security audit
- `/performance` - Performance profiling
- `/validate` - Validate against specs
- `/compliance` - Check compliance (GDPR, accessibility, etc.)

**Skills:**
- Test framework integration (Jest, Pytest, Go test, etc.)
- Security scanning patterns
- Performance monitoring tools

**Estimated Size:** 1 orchestrator + 6 granular commands, 3 skills

---

### 6. **deploy** (Deployment & Monitoring)
**Purpose:** Deploy to production, monitor, observe

**Consolidates:**
- multiagent-deployment → deployment workflows (ALREADY GOOD!)
- multiagent-observability → monitoring and logging

**Orchestrator Command:**
- `/deploy` - Full deployment workflow (chains prepare → validate → deploy → monitor)

**Granular Commands:**
- `/deploy-prepare` - Prepare deployment
- `/deploy-validate` - Validate deployment readiness
- `/deploy-run` - Execute deployment
- `/monitor` - Set up monitoring
- `/logs` - View/analyze logs

**Skills:**
- Platform detection (Vercel, AWS, Railway, etc.)
- Monitoring integration (Sentry, DataDog, etc.)

**Estimated Size:** 1 orchestrator + 5 granular commands, 2 skills

---

## Marketplace Infrastructure

### MCP Servers (Marketplace-Wide)

These services are available to ALL plugins via MCP protocol:

#### memory-api
**Source:** multiagent-memory plugin → converted to standalone MCP server
**Purpose:** Persistent memory and knowledge management across all plugins
**Technology:** FastMCP + SQLite (metadata) + ChromaDB (vector search)
**Location:** Bundle with marketplace OR deploy as standalone service

**Capabilities:**
- Store conversation memories
- Search project knowledge
- Cross-plugin context sharing
- Agent knowledge persistence

**Why MCP Server (not plugin):**
- All plugins need memory access
- Reduces duplication (no /memory-search, /memory-store in each plugin)
- Centralized knowledge graph
- Protocol-level integration

**Configuration:**
```json
// marketplace.json or ~/.claude.json
{
  "mcpServers": {
    "memory-api": {
      "type": "stdio",
      "command": "python",
      "args": ["-m", "memory_api.server"]
    }
  }
}
```

**Usage in Plugins:**
- Plugins use via MCP protocol calls
- No need for memory-specific commands in each plugin
- Automatic context enrichment during workflows

---

## Plugins to KEEP SEPARATE:

### **multiagent-build-system**
**Why:** Builds other plugins - meta-tooling
**Keep as-is** with new `/lifecycle` master command

### **multiagent-website-builder**
**Why:** Specialized for landing pages/marketing sites
**Decision:** Keep separate - distinct workflow from app development

### **multiagent-deployment**
**Why:** Already has working /deploy commands
**Decision:** Keep as-is OR merge into deploy lifecycle plugin

---

## Unused/Unclear Plugins:

- **multiagent-profile** - What does this do? Archive?

---

## Size Analysis:

**Every plugin follows the same pattern:**
- 1 orchestrator command (entry point)
- 5-8 granular commands (focused, chainable tasks)
- 2-4 skills (auto-invoked resources)

**Actual sizes:**
- ✅ core: 1 orchestrator + 8 granular = manageable
- ✅ planning: 1 orchestrator + 6 granular = good
- ✅ develop: 1 orchestrator + 7 granular = good
- ✅ iterate: 1 orchestrator + 8 granular = manageable
- ✅ quality: 1 orchestrator + 6 granular = good
- ✅ deploy: 1 orchestrator + 5 granular = perfect

**Why this works:**
- Users can call orchestrator OR granular commands
- Orchestrator chains granular commands based on context
- Skills auto-load to provide supporting resources
- Each command has clear, focused purpose

---

## Build Order (Using /lifecycle command):

1. **develop** - Most needed for actual coding work
2. **iterate** - Task layering + refactoring (consolidates multiagent-iterate, multiagent-supervisor, multiagent-refactoring, multiagent-enhancement)
3. **quality** - Testing and validation
4. **deploy** - Deployment workflows (or keep multiagent-deployment as-is)
5. **planning** - Spec creation and architecture
6. **core** - Foundation, detection, memory, MCP setup (consolidates multiagent-core, multiagent-git, multiagent-memory, multiagent-mcp)

**Strategy:**
- Build from existing working code when possible
- multiagent-iterate already has task-layering agent ✅ → copy to new iterate plugin
- multiagent-supervisor already has worktree scripts ✅ → copy to new iterate plugin
- multiagent-memory already has memory system ✅ → copy to new core plugin
- multiagent-deployment already has deploy commands ✅ → copy to new deploy plugin OR keep separate

---

## Success Criteria:

Each plugin must:
- ✅ Have 1 orchestrator command (entry point)
- ✅ Have 5-8 granular commands (focused, chainable)
- ✅ Have 2-4 skills (auto-invoked resources with scripts)
- ✅ Read from `.claude/project.json` for framework detection
- ✅ Work with spec-kit OR standalone
- ✅ Chain commands (orchestrator chains granular commands)
- ✅ Be buildable via `/lifecycle` command
- ✅ Follow patterns documented in LIFECYCLE-PLUGIN-GUIDE.md

**Infrastructure:**
- ✅ memory-api MCP server available marketplace-wide
- ✅ All plugins can use memory via MCP protocol
- ✅ No /memory-* commands in individual plugins

**No more consolidation after this. We build, test, use.**
