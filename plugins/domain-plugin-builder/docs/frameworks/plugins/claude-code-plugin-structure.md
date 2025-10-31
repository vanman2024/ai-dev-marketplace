# Claude Code Plugins - Reference Documentation

> Official reference for building Claude Code plugins. Use this when creating plugin templates and builders.

**Reference Link**: https://docs.claude.com/en/docs/claude-code/plugins

---

## Purpose

This document provides comprehensive reference for:
- Building plugin manifest (plugin.json)
- Understanding plugin directory structure
- Bundling commands, skills, hooks, and MCP servers
- Distributing plugins via marketplaces
- Team plugin workflows

**Load this document when**: Creating `/build:plugin` templates or plugin-builder agents

---

## Overview

Plugins extend Claude Code with custom functionality that can be shared across projects and teams. They bundle:

- **Slash commands** - User-invoked workflows
- **Agent Skills** - Model-invoked capabilities
- **Hooks** - Event-triggered automation
- **MCP servers** - External tool integration
- **Agents** - Specialized subagents (optional)

**Distribution**: Via marketplaces (Git repos, local directories)

---

## Plugin Structure

### Complete Plugin Layout

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Required: plugin manifest
├── commands/                 # Slash commands (optional)
│   └── deploy.md
├── agents/                   # Agent definitions (optional)
│   └── reviewer.md
├── skills/                   # Agent Skills (optional)
│   └── code-reviewer/
│       └── SKILL.md
├── hooks/                    # Hook configurations (optional)
│   └── hooks.json
├── .mcp.json                # MCP servers (optional)
├── scripts/                 # Utility scripts (optional)
│   └── validate.sh
└── README.md                # Plugin documentation
```

**Critical**: Directories are at **plugin root**, not inside `.claude-plugin/`

---

## Plugin Manifest: plugin.json

### Required Location

**`.claude-plugin/plugin.json`** - Must be in this exact location

### Complete Schema

```json
{
  "name": "plugin-name"
  "version": "1.2.0"
  "description": "Brief plugin description"
  "author": {
    "name": "Author Name"
    "email": "author@example.com"
  }
  "homepage": "https://docs.example.com/plugin"
  "repository": "https://github.com/author/plugin"
  "license": "MIT"
  "keywords": ["keyword1", "keyword2"]
}
```

### Required Fields

| Field | Type | Description | Example |
|:------|:-----|:------------|:--------|
| `name` | string | Unique identifier (kebab-case) | `"deployment-tools"` |

### Metadata Fields

| Field | Type | Description | Example |
|:------|:-----|:------------|:--------|
| `version` | string | Semantic version | `"2.1.0"` |
| `description` | string | Plugin purpose | `"Deployment automation"` |
| `author` | object | Author info | `{"name": "Dev Team"}` |
| `license` | string | License identifier | `"MIT"`, `"Apache-2.0"` |

### Component Path Fields (IMPORTANT!)

**CRITICAL**: Only use these fields for **CUSTOM/NON-STANDARD** locations within your plugin!

| Field | Type | Purpose | When to Use |
|:------|:-----|:--------|:------------|
| `commands` | string\|array | Custom command paths | When commands are NOT in `commands/` directory |
| `agents` | string\|array | Custom agent paths | When agents are NOT in `agents/` directory |
| `skills` | string\|array | Custom skill paths | When skills are NOT in `skills/` directory |

**Auto-Discovery Behavior**:
- If `commands/` directory exists → all `.md` files auto-discovered
- If `agents/` directory exists → all `.md` files auto-discovered
- If `skills/` directory exists → all `SKILL.md` files auto-discovered

**When fields SUPPLEMENT (not replace) auto-discovery**:

```json
{
  "name": "my-plugin"
  // DON'T include if using default directories!
  // ONLY use for additional custom locations:
  "commands": ["./custom-location/special.md"]
  "agents": ["./specialized/ai-agent.md"]
}
```

**Example - Correct Usage**:
```
my-plugin/
├── commands/               ← Auto-discovered (don't list in plugin.json)
│   └── basic.md
├── advanced-commands/      ← MUST list in plugin.json
│   └── deploy.md
└── agents/                 ← Auto-discovered (don't list in plugin.json)
    └── helper.md
```

```json
{
  "name": "my-plugin"
  "commands": ["./advanced-commands/deploy.md"]
  // Note: NO agents field because they're in default agents/ directory
}
```

**⚠️ COMMON MISTAKE**:
```json
{
  // ❌ WRONG - causes duplicate loading!
  "agents": [
    "./agents/agent1.md",  // Already auto-discovered from agents/
    "./agents/agent2.md"   // Will be loaded TWICE!
  ]
}
```

**✅ CORRECT**:
```json
{
  // Agents in agents/ directory auto-discovered - no field needed!
}
```

### Environment Variables

**`${CLAUDE_PLUGIN_ROOT}`**: Absolute path to plugin directory

Use in hooks, MCP servers, scripts to ensure correct paths:

```json
{
  "hooks": {
    "PostToolUse": [{
      "hooks": [{
        "type": "command"
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/process.sh"
      }]
    }]
  }
}
```

---

## Plugin Components

### 1. Slash Commands

**Location**: `commands/` directory

**Invocation**:
```shell
# Direct (no conflicts)
/command-name

# Plugin-prefixed (disambiguation)
/plugin-name:command-name
```

See: [Slash Commands Documentation](./01-claude-code-slash-commands.md)

### 2. Agent Skills

**Location**: `skills/` directory

**Structure**:
```
skills/
├── pdf-processor/
│   └── SKILL.md
└── code-reviewer/
    └── SKILL.md
```

See: [Skills Documentation](./02-claude-code-skills.md)

### 3. Hooks

**Location**: `hooks/hooks.json`

**Available events**:
- `PreToolUse`, `PostToolUse`
- `UserPromptSubmit`
- `SessionStart`, `SessionEnd`
- `PreCompact`

### 4. MCP Servers

**Location**: `.mcp.json`

**Integration**: Auto-start when plugin enabled

---

## Creating Plugins

### Minimal Plugin

```
hello-plugin/
├── .claude-plugin/
│   └── plugin.json
└── commands/
    └── hello.md
```

**plugin.json**:
```json
{
  "name": "hello-plugin"
  "version": "1.0.0"
  "description": "Simple greeting plugin"
}
```

---

## Distributing Plugins

### Via Marketplace

1. Create marketplace directory
2. Add plugin subdirectory
3. Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-marketplace"
  "owner": {"name": "Organization"}
  "plugins": [{
    "name": "my-plugin"
    "source": "./my-plugin"
    "description": "Plugin description"
  }]
}
```

4. Distribute via Git or local directory

### Installing Plugins

```shell
/plugin marketplace add your-org/claude-plugins
/plugin install my-plugin@marketplace-name
```

---

## Best Practices

### ✅ DO

- Clear plugin name (kebab-case, descriptive)
- Semantic versioning
- Complete metadata (author, repository, license)
- Use `${CLAUDE_PLUGIN_ROOT}` for paths
- Test locally before distribution
- Include README with usage instructions

### ❌ DON'T

- Hardcode absolute paths
- Skip documentation
- Forget metadata in plugin.json
- Put directories inside `.claude-plugin/`
- Break semver in minor/patch versions

---

## Full Documentation

See complete documentation at: https://docs.claude.com/en/docs/claude-code/plugins

---

**Source**: Claude Code Official Documentation
**Purpose**: Reference for build system plugin templates
**Load when**: Creating plugin templates or `/build:plugin`
