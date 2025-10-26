# Plugin Marketplaces - Complete Guide

> Create and manage plugin marketplaces to distribute Claude Code extensions across teams and communities.

**Reference**: https://docs.claude.com/en/docs/claude-code/plugin-marketplaces

---

## Overview

Plugin marketplaces are catalogs of available plugins that make it easy to discover, install, and manage Claude Code extensions. Marketplaces provide:

- **Centralized discovery**: Browse plugins from multiple sources in one place
- **Version management**: Track and update plugin versions automatically
- **Team distribution**: Share required plugins across your organization
- **Flexible sources**: Support for git repositories, GitHub repos, local paths, and package managers

### Prerequisites

- Claude Code installed and running
- Basic familiarity with JSON file format
- For creating marketplaces: Git repository or local development environment

---

## Plugin Installation Scoping

**CRITICAL**: Understand where plugins are installed and available:

### Global Installation (Default)

```shell
# Installs to: ~/.claude/marketplaces/{marketplace}/plugins/{plugin}/
/plugin marketplace add owner/repo
/plugin install plugin-name@marketplace-name
```

**Result**: Plugin available in **ALL projects** globally.

### Project-Scoped Installation

```shell
# Installs to: ./.claude/marketplaces/{marketplace}/plugins/{plugin}/
# First, add marketplace at project level
cd /path/to/your/project
/plugin marketplace add owner/repo --project

# Then install plugin at project level
/plugin install plugin-name@marketplace-name --project
```

**Result**: Plugin **ONLY** available in this specific project.

### Selective Installation Workflow

To install plugins one-by-one per project (recommended for control):

1. **Add marketplace globally** (for discovery):
   ```shell
   /plugin marketplace add your-org/plugins
   ```

2. **Install plugins selectively per project**:
   ```shell
   cd /path/to/project-a
   /plugin install deployment-tools@your-org-plugins --project

   cd /path/to/project-b
   /plugin install ai-infrastructure@your-org-plugins --project
   ```

**Result**: Each project has only the plugins it needs.

---

## Add and Use Marketplaces

### Add GitHub Marketplaces

```shell
# Global installation
/plugin marketplace add owner/repo

# Project-scoped installation
/plugin marketplace add owner/repo --project
```

### Add Git Repositories

```shell
/plugin marketplace add https://gitlab.com/company/plugins.git
```

### Add Local Marketplaces for Development

```shell
# Add local directory containing .claude-plugin/marketplace.json
/plugin marketplace add ./my-marketplace

# Add direct path to marketplace.json file
/plugin marketplace add ./path/to/marketplace.json

# Add remote marketplace.json via URL
/plugin marketplace add https://url.of/marketplace.json
```

### Install Plugins from Marketplaces

```shell
# Global installation
/plugin install plugin-name@marketplace-name

# Project-scoped installation
/plugin install plugin-name@marketplace-name --project

# Browse available plugins interactively
/plugin
```

### Verify Marketplace Installation

1. **List marketplaces**: `/plugin marketplace list`
2. **Browse plugins**: `/plugin` (interactive menu)
3. **Test installation**: Try installing a plugin

---

## Create Your Own Marketplace

### Prerequisites for Marketplace Creation

- Git repository (GitHub, GitLab, or other git hosting)
- Understanding of JSON file format
- One or more plugins to distribute

### Create the Marketplace File

Create `.claude-plugin/marketplace.json` in your repository root:

```json
{
  "name": "company-tools",
  "owner": {
    "name": "DevTools Team",
    "email": "devtools@company.com"
  },
  "plugins": [
    {
      "name": "code-formatter",
      "source": "./plugins/formatter",
      "description": "Automatic code formatting on save",
      "version": "2.1.0",
      "author": {
        "name": "DevTools Team"
      }
    },
    {
      "name": "deployment-tools",
      "source": {
        "source": "github",
        "repo": "company/deploy-plugin"
      },
      "description": "Deployment automation tools"
    }
  ]
}
```

### Marketplace Schema

#### Required Fields

| Field     | Type   | Description                                    |
|:----------|:-------|:-----------------------------------------------|
| `name`    | string | Marketplace identifier (kebab-case, no spaces) |
| `owner`   | object | Marketplace maintainer information             |
| `plugins` | array  | List of available plugins                      |

#### Optional Metadata

| Field                  | Type   | Description                           |
|:-----------------------|:-------|:--------------------------------------|
| `metadata.description` | string | Brief marketplace description         |
| `metadata.version`     | string | Marketplace version                   |
| `metadata.pluginRoot`  | string | Base path for relative plugin sources |

### Plugin Entries

**Required Fields:**

| Field    | Type           | Description                               |
|:---------|:---------------|:------------------------------------------|
| `name`   | string         | Plugin identifier (kebab-case, no spaces) |
| `source` | string\|object | Where to fetch the plugin from            |

#### Optional Plugin Fields

**Standard Metadata Fields:**

| Field         | Type    | Description                                                       |
|:--------------|:--------|:------------------------------------------------------------------|
| `description` | string  | Brief plugin description                                          |
| `version`     | string  | Plugin version                                                    |
| `author`      | object  | Plugin author information                                         |
| `homepage`    | string  | Plugin homepage or documentation URL                              |
| `repository`  | string  | Source code repository URL                                        |
| `license`     | string  | SPDX license identifier (e.g., MIT, Apache-2.0)                   |
| `keywords`    | array   | Tags for plugin discovery and categorization                      |
| `category`    | string  | Plugin category for organization                                  |
| `tags`        | array   | Tags for searchability                                            |
| `strict`      | boolean | Require plugin.json in plugin folder (default: true)              |

**Component Configuration Fields:**

| Field        | Type           | Description                                      |
|:-------------|:---------------|:-------------------------------------------------|
| `commands`   | string\|array  | Custom paths to command files or directories     |
| `agents`     | string\|array  | Custom paths to agent files                      |
| `hooks`      | string\|object | Custom hooks configuration or path to hooks file |
| `mcpServers` | string\|object | MCP server configurations or path to MCP config  |

**Note**: When `strict: true` (default), the plugin must include a `plugin.json` manifest file. When `strict: false`, the plugin.json is optional, and the marketplace entry serves as the complete plugin manifest.

### Plugin Sources

#### Relative Paths

For plugins in the same repository:

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin"
}
```

#### GitHub Repositories

```json
{
  "name": "github-plugin",
  "source": {
    "source": "github",
    "repo": "owner/plugin-repo"
  }
}
```

#### Git Repositories

```json
{
  "name": "git-plugin",
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git"
  }
}
```

#### Advanced Plugin Entries

Plugin entries can override default component locations and provide additional metadata. `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin's installation directory:

```json
{
  "name": "enterprise-tools",
  "source": {
    "source": "github",
    "repo": "company/enterprise-plugin"
  },
  "description": "Enterprise workflow automation tools",
  "version": "2.1.0",
  "author": {
    "name": "Enterprise Team",
    "email": "enterprise@company.com"
  },
  "homepage": "https://docs.company.com/plugins/enterprise-tools",
  "repository": "https://github.com/company/enterprise-plugin",
  "license": "MIT",
  "keywords": ["enterprise", "workflow", "automation"],
  "category": "productivity",
  "commands": [
    "./commands/core/",
    "./commands/enterprise/",
    "./commands/experimental/preview.md"
  ],
  "agents": [
    "./agents/security-reviewer.md",
    "./agents/compliance-checker.md"
  ],
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh"}]
      }
    ]
  },
  "mcpServers": {
    "enterprise-db": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  },
  "strict": false
}
```

---

## Configure Team Marketplaces

Set up automatic marketplace installation for team projects by specifying required marketplaces in `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "team-tools": {
      "source": {
        "source": "github",
        "repo": "your-org/claude-plugins"
      }
    },
    "project-specific": {
      "source": {
        "source": "git",
        "url": "https://git.company.com/project-plugins.git"
      }
    }
  }
}
```

When team members trust the repository folder, Claude Code automatically installs these marketplaces and any plugins specified in the `enabledPlugins` field.

---

## Host and Distribute Marketplaces

### Host on GitHub (Recommended)

1. **Create a repository**: Set up a new repository for your marketplace
2. **Add marketplace file**: Create `.claude-plugin/marketplace.json` with your plugin definitions
3. **Add plugin directories**: Include all plugin code in the repository
4. **Push to GitHub**: Make repository public or grant team access
5. **Share with teams**: Team members add with `/plugin marketplace add owner/repo`

**Benefits**: Built-in version control, issue tracking, and team collaboration features.

### Host on Other Git Services

Any git hosting service works for marketplace distribution:

```shell
/plugin marketplace add https://gitlab.com/company/plugins.git
```

### Use Local Marketplaces for Development

Test your marketplace locally before distribution:

```shell
# Add local marketplace for testing
/plugin marketplace add ./my-local-marketplace

# Test plugin installation
/plugin install test-plugin@my-local-marketplace
```

---

## Manage Marketplace Operations

### List Known Marketplaces

```shell
/plugin marketplace list
```

Shows all configured marketplaces with their sources and status.

### Update Marketplace Metadata

```shell
/plugin marketplace update marketplace-name
```

Refreshes plugin listings and metadata from the marketplace source.

### Remove a Marketplace

```shell
/plugin marketplace remove marketplace-name
```

**WARNING**: Removing a marketplace will uninstall any plugins you installed from it.

---

## Troubleshooting Marketplaces

### Common Marketplace Issues

#### Marketplace Not Loading

**Symptoms**: Can't add marketplace or see plugins from it

**Solutions**:
- Verify the marketplace URL is accessible
- Check that `.claude-plugin/marketplace.json` exists at the specified path
- Ensure JSON syntax is valid using `claude plugin validate`
- For private repositories, confirm you have access permissions

#### Plugin Installation Failures

**Symptoms**: Marketplace appears but plugin installation fails

**Solutions**:
- Verify plugin source URLs are accessible
- Check that plugin directories contain required files
- For GitHub sources, ensure repositories are public or you have access
- Test plugin sources manually by cloning/downloading

### Validation and Testing

Test your marketplace before sharing:

```bash
# Validate marketplace JSON syntax
claude plugin validate .

# Add marketplace for testing
/plugin marketplace add ./path/to/marketplace

# Install test plugin
/plugin install test-plugin@marketplace-name
```

---

## Publishing Workflow: Step-by-Step

### 1. Prepare Your Marketplace

```bash
cd ~/.claude/marketplaces/multiagent-dev

# Verify structure
ls -la .claude-plugin/
# Should show: marketplace.json

ls -la plugins/
# Should show: multiagent-core/, multiagent-deployment/, etc.
```

### 2. Create GitHub Repository

```bash
# On GitHub, create new repository: your-username/multiagent-marketplace

# Add remote to your local marketplace
git remote add origin https://github.com/your-username/multiagent-marketplace.git

# Push to GitHub
git push -u origin main
```

### 3. Install on Other Computers

```bash
# Add marketplace
/plugin marketplace add your-username/multiagent-marketplace

# Install specific plugins (project-scoped)
cd /path/to/your/project
/plugin install multiagent-core@multiagent-marketplace --project
/plugin install multiagent-deployment@multiagent-marketplace --project
```

---

## Best Practices

### For Marketplace Users

- **Use project-scoped installation** to avoid global plugin pollution
- **Verify plugin sources** before installation
- **Keep marketplaces updated** with `/plugin marketplace update`

### For Marketplace Creators

- **Use semantic versioning** for plugins and marketplace
- **Document all plugins** with clear descriptions
- **Test locally first** before publishing
- **Use `${CLAUDE_PLUGIN_ROOT}`** for all internal paths
- **Keep `marketplace.json` updated** when adding/removing plugins

### For Organizations

- **Private marketplaces** for proprietary tools
- **Governance policies** for plugin approval and security review
- **Training resources** to help teams discover and adopt plugins

---

## See Also

- [Plugins](/en/docs/claude-code/plugins) - Installing and using plugins
- [Plugins Reference](/en/docs/claude-code/plugins-reference) - Complete technical specifications
- [Plugin Development](/en/docs/claude-code/plugins#develop-more-complex-plugins) - Creating your own plugins
- [Settings](/en/docs/claude-code/settings#plugin-configuration) - Plugin configuration options

---

**Source**: Claude Code Official Documentation
**Purpose**: Complete guide for marketplace creation and plugin distribution
**Load when**: Publishing or installing plugins via marketplaces
