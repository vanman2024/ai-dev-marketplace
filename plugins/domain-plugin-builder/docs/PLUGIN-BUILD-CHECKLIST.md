# Plugin Build Checklist - Complete Workflow

> Systematized process for building, validating, and installing Claude Code plugins

---

## Overview

This checklist ensures every plugin is built correctly, validated thoroughly, and installed properly for testing. Follow these steps in order.

---

## Phase 1: Create Plugin Structure

### 1.1 Run Plugin Creation Command

```bash
/domain-plugin-builder:plugin-create <plugin-name>
```

**What it does:**
- Creates complete directory structure
- Builds all commands, agents, and skills
- Generates README and LICENSE
- Creates plugin.json manifest

### 1.2 Verify Directory Structure

```bash
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/                 # Slash commands
├── agents/                   # Specialized agents
├── skills/                   # Reusable capabilities
│   └── <skill-name>/
│       ├── SKILL.md
│       ├── scripts/          # Functional scripts
│       ├── templates/        # Template files
│       └── examples/         # Working examples
├── docs/                     # Documentation
├── README.md
├── LICENSE
└── CHANGELOG.md
```

---

## Phase 2: Validate Plugin Components

### 2.1 Run Comprehensive Validation

```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-all.sh plugins/<plugin-name>
```

**Checks performed:**
- ✅ Commands: Size limits, frontmatter, syntax
- ✅ Agents: Required fields, tools specification
- ✅ Skills: Directory structure, scripts
- ✅ Plugin: plugin.json schema, required files

### 2.2 Fix Any Validation Errors

**Common issues:**

#### Invalid plugin.json fields
```bash
# ERROR: Unrecognized keys: 'type', 'framework', 'languages'
```

**Fix:** Only use allowed fields:
- `name`, `version`, `description`
- `author` (object with name/email)
- `homepage`, `repository`, `license`
- `keywords` (array)

Move custom metadata to `keywords` array.

#### Command size exceeds limit
```bash
# ERROR: Command exceeds 172 lines (limit: 172)
```

**Fix:** Remove:
- Inline code blocks (use skills instead)
- Detailed configuration examples
- Verbose result templates
- Keep only orchestration logic

#### Missing tools field in agent
```bash
# ERROR: Agent missing required 'tools' field
```

**Fix:** Add to frontmatter:
```yaml
---
tools: Bash, Read, Write, Edit, mcp__servername
---
```

### 2.3 Re-run Validation Until All Pass

```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-all.sh plugins/<plugin-name>
```

**Expected output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ VALIDATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commands:  16/16 passed ✅
Agents:    14/14 passed ✅
Skills:     7/7  passed ✅
Plugin:     1/1  passed ✅

Total:     38/38 passed (100%) ✅
```

---

## Phase 3: Sync to Marketplace

### 3.1 Update Marketplace Metadata

```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-marketplace.sh
```

**What it does:**
- Scans all plugins in `plugins/` directory
- Reads plugin.json from each plugin
- Updates `.claude-plugin/marketplace.json`
- Registers plugin in marketplace catalog

### 3.2 Verify Marketplace Entry

```bash
cat .claude-plugin/marketplace.json | python3 -m json.tool | grep -A 20 '"name": "<plugin-name>"'
```

**Expected output:**
```json
{
  "name": "<plugin-name>"
  "description": "..."
  "version": "1.0.0"
  "author": {
    "name": "..."
    "email": "..."
  }
  "source": "./plugins/<plugin-name>"
  "category": "development"
  "keywords": [...]
}
```

---

## Phase 4: Install Plugin Locally

### 4.1 Setup Marketplace Symlink (One-Time Setup)

```bash
# Check if marketplace is already symlinked
ls -la ~/.claude/plugins/marketplaces/ai-dev-marketplace

# If NOT a symlink, replace with symlink to development directory
trash-put ~/.claude/plugins/marketplaces/ai-dev-marketplace
ln -s /home/vanman2025/Projects/ai-dev-marketplace ~/.claude/plugins/marketplaces/ai-dev-marketplace
```

**Why symlink?** Changes in development directory are immediately available without copying.

### 4.2 Install Plugin via Claude Code

```bash
/plugin install <plugin-name>@ai-dev-marketplace
```

**Expected output:**
```
✔ <plugin-name> · Installed
```

### 4.3 Verify Installation

```bash
# List installed plugins
/plugin

# Test a command from the plugin
/<plugin-name>:init

# Or any other command from your plugin
/<plugin-name>:create-schema
/<plugin-name>:add-auth
```

---

## Phase 5: Commit and Push

### 5.1 Stage All Changes

```bash
git add -A
git status
```

### 5.2 Create Commit

```bash
git commit -m "[WORKING] feat: Add <plugin-name> plugin

Complete plugin with production-ready components:
- X commands for <description>
- Y agents (architecture: ...)
- Z skills with functional scripts

Validation: All checks passing (38/38 ✅)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 5.3 Push to GitHub

```bash
git push origin master
```

---

## Phase 6: Post-Installation Testing

### 6.1 Test Core Commands

Test at least 3 commands from the plugin:

```bash
/<plugin-name>:init test-project
/<plugin-name>:add-auth google,github
/<plugin-name>:validate-setup --production
```

### 6.2 Verify Agent Orchestration

Check that agents are invoked properly:

```bash
# Look for agent invocation in command output
# Should see: "Invoking the <agent-name> agent..."
```

### 6.3 Test Skill Scripts

Verify skill scripts are functional:

```bash
bash plugins/<plugin-name>/skills/<skill-name>/scripts/example-script.sh
```

---

## Troubleshooting

### Plugin Not Found in Marketplace

**Symptom:**
```
⎿ Plugin "<plugin-name>" not found in any marketplace
```

**Solutions:**
1. Verify plugin.json exists: `cat plugins/<plugin-name>/.claude-plugin/plugin.json`
2. Re-run marketplace sync: `bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-marketplace.sh`
3. Check marketplace symlink: `ls -la ~/.claude/plugins/marketplaces/ai-dev-marketplace`
4. If symlink broken, recreate it (see Phase 4.1)

### Invalid Manifest Error

**Symptom:**
```
Plugin has an invalid manifest file
Validation errors: Unrecognized key(s) in object: 'type', 'framework'
```

**Solution:**
Remove invalid fields from plugin.json (see Phase 2.2)

### Command Not Recognized

**Symptom:**
```
/<plugin-name>:init
⎿ Command not found
```

**Solutions:**
1. Verify plugin installed: `/plugin`
2. Re-sync settings: `bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh`
3. Restart Claude Code

---

## Automated Checklist Script

Use this script to verify all steps:

```bash
#!/usr/bin/env bash
PLUGIN_NAME="${1:?Usage: $0 <plugin-name>}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Plugin Build Checklist: $PLUGIN_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Phase 1: Structure
[[ -d "plugins/$PLUGIN_NAME" ]] && echo "✅ Plugin directory exists" || echo "❌ Plugin directory missing"
[[ -f "plugins/$PLUGIN_NAME/.claude-plugin/plugin.json" ]] && echo "✅ plugin.json exists" || echo "❌ plugin.json missing"

# Phase 2: Validation
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-all.sh plugins/$PLUGIN_NAME >/dev/null 2>&1 && echo "✅ All validations passed" || echo "❌ Validation failed"

# Phase 3: Marketplace
grep -q "\"name\": \"$PLUGIN_NAME\"" .claude-plugin/marketplace.json && echo "✅ Registered in marketplace" || echo "❌ Not in marketplace"

# Phase 4: Installation
[[ -L ~/.claude/plugins/marketplaces/ai-dev-marketplace ]] && echo "✅ Marketplace symlinked" || echo "⚠️  Marketplace not symlinked"

# Phase 5: Git
git diff --quiet && echo "✅ No uncommitted changes" || echo "⚠️  Uncommitted changes present"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

---

## Quick Reference

| Task | Command |
|:-----|:--------|
| Create plugin | `/domain-plugin-builder:plugin-create <name>` |
| Validate all | `bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-all.sh plugins/<name>` |
| Sync marketplace | `bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-marketplace.sh` |
| Install plugin | `/plugin install <name>@ai-dev-marketplace` |
| Test command | `/<name>:init` |
| Commit | `git commit -m "feat: Add <name> plugin"` |

---

**Last Updated:** 2025-10-26
**Version:** 1.0.0
**Maintained By:** domain-plugin-builder plugin
