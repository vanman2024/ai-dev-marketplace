# Domain Plugin Builder

**Version**: 1.0.0
**Status**: Meta-Tooling
**Purpose**: Universal builder for domain-specific Claude Code plugins (SDK, Framework, Custom)

---

## Overview

The Domain Plugin Builder creates any type of domain-specific plugin with proper structure, validation, and compliance checking. It's the **unified builder for all future plugins** in the marketplace.

**This is NOT for lifecycle plugins** (01-core, 02-planning, etc.) - those follow a different pattern.

## Plugin Types Supported

### 1. SDK Plugins
Build plugins for specific SDKs (e.g., Claude Agent SDK, Vercel AI SDK)
- Fetches SDK documentation automatically
- Creates initialization commands
- Generates verifier agents for each language
- Example: `agent-sdk-dev`, `vercel-ai-dev`

### 2. Framework Plugins
Build plugins for web frameworks (e.g., Next.js, FastAPI, Django)
- Fetches framework documentation
- Creates scaffolding commands
- Generates framework-specific helpers
- Example: `nextjs-dev`, `fastapi-dev`

### 3. Custom Plugins
Build domain-specific tooling plugins
- Custom workflow automation
- Specialized development tools
- Domain-specific helpers
- Example: `custom-analytics`, `custom-deploy`

---

## Components

### 📜 Commands (4)

1. **`/domain-plugin-builder:plugin-create`** - Universal plugin builder (main command)
2. **`/domain-plugin-builder:slash-commands-create`** - Create slash commands
3. **`/domain-plugin-builder:skills-create`** - Create skills with functional scripts
4. **`/domain-plugin-builder:agents-create`** - Create agents with proper structure

### 🤖 Agents (0)

Domain-plugin-builder uses direct execution, not agents.

### 🎯 Skills (1)

- **`build-assistant`** - Complete build infrastructure with validation scripts and templates

---

## Usage

### Create a New Plugin

**SDK Plugin:**
```bash
/domain-plugin-builder:plugin-create vercel-ai-dev
# Will ask for: Documentation source, languages supported, key features
```

**Framework Plugin:**
```bash
/domain-plugin-builder:plugin-create nextjs-dev
# Will ask for: Documentation URL, framework version, features to support
```

**Custom Plugin:**
```bash
/domain-plugin-builder:plugin-create custom-analytics
# Will ask for: Domain area, primary use cases, commands needed
```

### Create Individual Components

**Create a command:**
```bash
/domain-plugin-builder:slash-commands-create my-command "Command description" --plugin=my-plugin
```

**Create a skill:**
```bash
/domain-plugin-builder:skills-create my-skill "Skill description" --plugin=my-plugin
```

**Create an agent:**
```bash
/domain-plugin-builder:agents-create my-agent "Agent description" "Read,Write,Bash" --plugin=my-plugin
```

---

## Build Process

The builder follows this workflow:

1. **Detect Location** - Verify in ai-dev-marketplace directory
2. **Determine Type** - Ask: SDK, Framework, or Custom plugin?
3. **Gather Details** - Plugin name, description, documentation sources
4. **Fetch Documentation** - For SDK/Framework: WebFetch or Context7 MCP
5. **Create Scaffold** - Directory structure + root files
6. **Validate Structure** - Run validate-plugin.sh
7. **Create Commands** - Based on plugin type
8. **Create Agents** - With Step 0 requirement
9. **Create Skills** - With functional scripts (not just READMEs!)
10. **Generate Docs** - README.md with usage examples
11. **Run Validation** - Execute ALL validation scripts
12. **Display Summary** - Show what was created

---

## Required Files Created

Every plugin gets these root files:

- ✅ **README.md** - Plugin documentation and usage
- ✅ **LICENSE** - MIT License
- ✅ **CHANGELOG.md** - Version history
- ✅ **.mcp.json** - MCP server configuration
- ✅ **.gitignore** - Git ignore patterns
- ✅ **.claude-plugin/plugin.json** - Plugin manifest

---

## Validation Scripts

Located in `skills/build-assistant/scripts/`:

- **validate-plugin.sh** - Complete plugin structure validation
- **validate-command.sh** - Command file validation (frontmatter, arguments, patterns)
- **validate-agent.sh** - Agent validation (Step 0 requirement, frontmatter)
- **validate-skill.sh** - Skill validation (SKILL.md, scripts/, templates/)
- **scan-hardcoded-paths.sh** - Detect hardcoded paths
- **scan-legacy-references.sh** - Detect deprecated references
- **fix-hardcoded-paths.sh** - Auto-fix path issues
- **fix-legacy-references.sh** - Auto-fix legacy references
- **fix-argument-hints.sh** - Fix argument hints

**All validation scripts execute during build!**

---

## Key Patterns Enforced

### 1. Actual Tool Execution
- ✅ Use `Bash()` tool - NEVER `!{bash ...}` markup
- ✅ Use `Write()` tool for file creation
- ✅ Use `Read()` before editing
- ✅ Tools execute immediately

### 2. Validation Always Runs
- ✅ All validation scripts execute in Step 11
- ✅ Build fails if validation fails
- ✅ No incomplete plugins

### 3. Skills Have Functional Scripts
- ✅ Create ACTUAL .sh helper scripts
- ✅ Not just README placeholders
- ✅ Made executable (chmod +x)
- ✅ Templates where applicable

### 4. Agents Have Step 0
- ✅ "Step 0: Load Required Context (CRITICAL)"
- ✅ References skills/docs to load
- ✅ Explains consequences without context

### 5. Project-Agnostic Design
- ✅ No hardcoded frameworks
- ✅ No hardcoded paths
- ✅ Detect project type dynamically
- ✅ Adapt to what's found

---

## MCP Integration

This builder uses Context7 MCP for fetching SDK/Framework documentation:

```json
{
  "mcpServers": {
    "context7": {
      "tools": [
        "resolve-library-id"
        "get-library-docs"
      ]
    }
  }
}
```

Usage: Automatically fetches latest docs for SDKs/frameworks during build.

---

## Examples

### Real Plugins Built

- **agent-sdk-dev** - Claude Agent SDK plugin (SDK type)
- **vercel-ai-dev** - Vercel AI SDK plugin (SDK type)
- **05-quality** - Testing & Validation plugin (Custom type)
- **04-iterate** - Iteration & Refinement plugin (Custom type)

---

## Distribution

Add to marketplace.json:

```json
{
  "name": "domain-plugin-builder"
  "path": "plugins/domain-plugin-builder"
  "status": "meta-tooling"
  "description": "Builds domain-specific plugins"
}
```

---

## Requirements

- Claude Code CLI
- Bash (for validation scripts)
- Python 3 (for JSON validation)
- Context7 MCP (for SDK documentation fetching)

---

## Next Steps

1. Use this builder for all new plugins
2. Run validation scripts to ensure compliance
3. Add functional scripts to skills
4. Test commands after creation
5. Update marketplace.json

---

## License

MIT License - See LICENSE file for details

---

**This is THE unified plugin builder for the ai-dev-marketplace**
