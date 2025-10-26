# Settings Sync Guide

## Purpose
All plugin slash commands MUST be registered in `.claude/settings.local.json` to be invocable. This guide explains the automated sync system.

## Quick Start

### Sync All Commands to Settings
```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh
```

This will:
1. Find ALL plugins in `plugins/` directory
2. Extract all command files (`*.md`) from each plugin's `commands/` directory
3. Generate SlashCommand permissions for each
4. Update `.claude/settings.local.json` with complete list
5. Create backup at `.claude/settings.local.json.backup`

## Current State

### Registered Plugins (4 total, 53 permissions)

#### claude-agent-sdk (15 commands)
- `/claude-agent-sdk:*` (wildcard)
- `/claude-agent-sdk:add-cost-tracking`
- `/claude-agent-sdk:add-custom-tools`
- `/claude-agent-sdk:add-hosting`
- `/claude-agent-sdk:add-mcp`
- `/claude-agent-sdk:add-permissions`
- `/claude-agent-sdk:add-plugins`
- `/claude-agent-sdk:add-sessions`
- `/claude-agent-sdk:add-skills`
- `/claude-agent-sdk:add-slash-commands`
- `/claude-agent-sdk:add-streaming`
- `/claude-agent-sdk:add-subagents`
- `/claude-agent-sdk:add-system-prompts`
- `/claude-agent-sdk:add-todo-tracking`
- `/claude-agent-sdk:build-full-app`
- `/claude-agent-sdk:new-app`

#### domain-plugin-builder (5 commands)
- `/domain-plugin-builder:*` (wildcard)
- `/domain-plugin-builder:agents-create`
- `/domain-plugin-builder:build-plugin`
- `/domain-plugin-builder:plugin-create`
- `/domain-plugin-builder:skills-create`
- `/domain-plugin-builder:slash-commands-create`

#### fastmcp (8 commands)
- `/fastmcp:*` (wildcard)
- `/fastmcp:add-api-wrapper`
- `/fastmcp:add-auth`
- `/fastmcp:add-components`
- `/fastmcp:add-deployment`
- `/fastmcp:add-integration`
- `/fastmcp:build-full-server`
- `/fastmcp:new-client`
- `/fastmcp:new-server`

#### vercel-ai-sdk (10 commands)
- `/vercel-ai-sdk:*` (wildcard)
- `/vercel-ai-sdk:add-advanced`
- `/vercel-ai-sdk:add-chat`
- `/vercel-ai-sdk:add-data-features`
- `/vercel-ai-sdk:add-production`
- `/vercel-ai-sdk:add-provider`
- `/vercel-ai-sdk:add-streaming`
- `/vercel-ai-sdk:add-tools`
- `/vercel-ai-sdk:add-ui-features`
- `/vercel-ai-sdk:build-full-stack`
- `/vercel-ai-sdk:new-app`

### Base Tools (11 tools)
- `Bash`
- `Write`
- `Read`
- `Edit`
- `WebFetch`
- `WebSearch`
- `AskUserQuestion`
- `Glob`
- `Grep`
- `Task`
- `Skill`

### MCP Servers (4 servers)
- `filesystem`
- `playwright`
- `context7`
- `postman`

## Validation

### Validate Individual Plugin
```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-plugin.sh plugins/PLUGIN_NAME
```

This checks:
1. Plugin structure is valid
2. `plugin.json` exists and is valid
3. Commands are registered in settings.local.json
4. Component directories are in correct location

### Validate All Plugins
```bash
for plugin in plugins/*/; do
  bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-plugin.sh "$plugin"
done
```

## When to Sync

### Automatically Run After:
1. Creating a new plugin
2. Adding commands to existing plugin
3. Cloning the repository (first time setup)

### Manual Triggers:
1. Commands not being recognized
2. "Unknown slash command" errors
3. After pulling updates from git
4. After switching branches

## Workflow Integration

### Plugin Builder Integration

The `plugin-builder` agent should automatically run sync after creating a plugin:

```markdown
### Phase 7: Validation & Registration

**Actions:**
1. Run validation scripts
2. Sync commands to settings.local.json
3. Verify all commands are invocable
4. Test one command to confirm

```bash
# After building plugin
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh

# Validate registration
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-plugin.sh plugins/NEW_PLUGIN
```
```

### Command Creation Integration

The `slash-commands-create` command should remind user to sync:

```markdown
## Step 7: Register Command in Settings

**IMPORTANT:** New commands must be registered in settings.local.json

Run sync script:
```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh
```

Or add manually to `.claude/settings.local.json`:
```json
"SlashCommand(/PLUGIN:COMMAND_NAME)"
```
```

## Troubleshooting

### Command Not Found
```
Error: Unknown slash command: /fastmcp:new-server
```

**Solution:**
```bash
# Re-sync all commands
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh

# Verify it's now registered
grep "fastmcp:new-server" .claude/settings.local.json
```

### Settings File Corrupted
```bash
# Restore from backup
cp .claude/settings.local.json.backup .claude/settings.local.json

# Or regenerate from scratch
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh
```

### New Plugin Not Recognized
```bash
# Check plugin structure
ls -la plugins/NEW_PLUGIN/

# Expected structure:
# plugins/NEW_PLUGIN/
# ├── .claude-plugin/
# │   └── plugin.json
# ├── commands/
# │   └── some-command.md
# ├── agents/
# └── skills/

# Sync settings
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh
```

## Best Practices

### 1. Always Sync After Plugin Changes
```bash
# After creating plugin
/domain-plugin-builder:plugin-create my-plugin
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh

# After adding command
/domain-plugin-builder:slash-commands-create my-plugin new-cmd "Description"
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh
```

### 2. Validate Before Committing
```bash
# Before git commit
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh
git add .claude/settings.local.json
git commit -m "feat: Update plugin permissions"
```

### 3. Include in CI/CD
```yaml
# .github/workflows/validate.yml
- name: Validate Plugin Registration
  run: |
    bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh
    git diff --exit-code .claude/settings.local.json
```

## Architecture

### How It Works

```
┌─────────────────────────────────────────┐
│  Plugin Directory Structure              │
│                                          │
│  plugins/                                │
│  ├── plugin1/                            │
│  │   ├── commands/                       │
│  │   │   ├── cmd1.md                     │
│  │   │   └── cmd2.md                     │
│  │   └── .claude-plugin/plugin.json     │
│  └── plugin2/                            │
│      ├── commands/                       │
│      │   └── cmd3.md                     │
│      └── .claude-plugin/plugin.json     │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  sync-settings-permissions.sh            │
│  1. Find all plugins/*/                  │
│  2. For each plugin:                     │
│     - Get plugin name                    │
│     - Find commands/*.md                 │
│     - Generate permissions               │
│  3. Build complete JSON                  │
│  4. Write to settings.local.json        │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  .claude/settings.local.json             │
│  {                                       │
│    "permissions": {                      │
│      "allow": [                          │
│        "SlashCommand(/plugin1:*)",       │
│        "SlashCommand(/plugin1:cmd1)",    │
│        "SlashCommand(/plugin1:cmd2)",    │
│        "SlashCommand(/plugin2:*)",       │
│        "SlashCommand(/plugin2:cmd3)",    │
│        ...                               │
│      ]                                   │
│    }                                     │
│  }                                       │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Claude Code Extension                   │
│  - Reads settings.local.json            │
│  - Allows registered commands            │
│  - Blocks unregistered commands          │
└─────────────────────────────────────────┘
```

## Future Enhancements

### Auto-Sync on Plugin Creation
Add to plugin-builder agent Phase 8:
```bash
# Automatically sync after plugin creation
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh
```

### Pre-Commit Hook
```bash
# .git/hooks/pre-commit
#!/bin/bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh
git add .claude/settings.local.json
```

### Watch Mode
```bash
# Auto-sync when plugin files change
inotifywait -m -r plugins/ -e create,modify |
while read; do
  bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh
done
```
