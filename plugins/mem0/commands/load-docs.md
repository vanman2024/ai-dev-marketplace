---
description: Load Mem0 documentation on-demand with intelligent link extraction and parallel WebFetch
argument-hint: [feature-name|core|all]
allowed-tools: Task, Read, Bash
---

# Load Mem0 Documentation

**Purpose:** Load fresh Mem0 documentation on-demand by extracting external links from local docs and fetching them in priority-based batches.

## Command Arguments

**Syntax:** `/mem0:load-docs [argument]`

**Arguments:**
- **Empty/No argument** - Load core documentation only (P0 essential links)
- **`core`** - Explicitly load only core documentation (same as empty)
- **`all`** - Load all documentation (P0 + P1 + P2) - comprehensive but uses more context
- **`{feature-name}`** - Load core + specific feature documentation (e.g., "streaming", "sessions", "tools")

**Examples:**
```bash
# Load core documentation (essential only)
/mem0:load-docs

# Load core documentation explicitly
/mem0:load-docs core

# Load all documentation (comprehensive)
/mem0:load-docs all

# Load documentation for specific feature
/mem0:load-docs streaming
/mem0:load-docs tools
/mem0:load-docs providers
```

## Workflow

### Phase 1: Parse Arguments

**Determine Loading Scope:**

Parse $ARGUMENTS to extract scope parameter:

!{bash
SCOPE="$ARGUMENTS"

# Default to "core" if empty
if [ -z "$SCOPE" ]; then
  SCOPE="core"
fi

# Validate scope
case "$SCOPE" in
  core|all)
    echo "Loading scope: $SCOPE"
    ;;
  *)
    # Treat as feature name
    echo "Loading core + feature: $SCOPE"
    ;;
esac
}

Extract:
- `scope`: What documentation to load (core, all, or feature name)
- Display scope to user

### Phase 2: Invoke Documentation Loader Agent

**Load Documentation via Task Tool:**

Invoke the doc-loader-agent with the determined scope:

```markdown
Task(
  description="Load Mem0 documentation",
  subagent_type="doc-loader-agent",
  prompt="Load documentation for Mem0 with the following parameters:

  **Plugin Information:**
  - Plugin Name: Mem0
  - Documentation Path: plugins/mem0/docs/
  - Loading Scope: $SCOPE

  **Instructions:**
  1. Find all markdown documentation files in plugins/mem0/docs/
  2. Extract all external links (URLs) from these files
  3. Categorize links by priority:
     - P0 (Essential): overview, quickstart, getting-started
     - P1 (Features): feature-specific documentation
     - P2 (Advanced): advanced topics, reference, migration
  4. Fetch documentation in batches based on scope:
     - If scope is 'core': Load P0 only (4-6 URLs)
     - If scope is 'all': Load P0 + P1 + P2 (up to 15-20 URLs)
     - If scope is feature name: Load P0 + P1 URLs matching feature
  5. Return formatted documentation summary

  **Deliverable:**
  Provide a comprehensive summary of the loaded documentation, organized by priority level, with source URLs and key information extracted from each page."
)
```

**Wait for agent to complete and return results.**

### Phase 3: Display Results

**Present Documentation to User:**

The doc-loader-agent will return formatted documentation. Display it to the user with a summary:

```markdown
## Mem0 Documentation Loaded

**Scope:** {scope}
**Documentation Path:** plugins/mem0/docs/
**Status:** Complete

{Agent output with formatted documentation}

---

## Usage Tips

**To use this documentation:**
1. Review the core documentation for essential concepts
2. Reference feature-specific sections as needed
3. Use the source URLs for more detailed information

**To reload with different scope:**
- `/mem0:load-docs core` - Essentials only
- `/mem0:load-docs all` - Everything
- `/mem0:load-docs {feature}` - Specific feature

**To build features:**
Use the relevant slash commands:
- `/mem0:init` - Initialize new project
- `/mem0:add-{feature}` - Add specific features
```

## Configuration

**Plugin Variables (Replace when deploying):**
- `Mem0` → Human-readable plugin name
- `mem0` → Command prefix
- `mem0` → Plugin directory path

**Documentation Path:**
- Default: `plugins/mem0/docs/`
- Override if documentation is in different location

## Features

✅ **On-Demand Loading** - Load only when needed, not during initialization
✅ **Fresh Documentation** - WebFetch ensures latest documentation
✅ **Intelligent Batching** - Priority-based loading optimizes context
✅ **Flexible Scope** - Core, feature-specific, or comprehensive loading
✅ **Parallel Fetching** - Multiple URLs fetched concurrently for speed
✅ **Error Resilient** - Handles WebFetch failures gracefully

## Context Impact

**Estimated Token Usage:**
- **Core (default):** ~5-10K tokens (essential documentation)
- **Feature-specific:** ~10-15K tokens (core + targeted feature)
- **All:** ~20-30K tokens (comprehensive documentation)

**Recommendation:**
- Use `core` or `feature-name` for most workflows
- Use `all` only when comprehensive reference needed
- Reload as needed rather than loading everything upfront

## Error Handling

**Scenario 1: No documentation found**
```
Error: No markdown files found in plugins/mem0/docs/

Suggestion: Check that the plugin has documentation installed.
```

**Scenario 2: No external links found**
```
Warning: No external links found in documentation.

The plugin may only have local documentation.
Refer to files in plugins/mem0/docs/ directly.
```

**Scenario 3: WebFetch failures**
```
Warning: Some documentation failed to load.

Successful: {X}/{Y} URLs
Failed URLs: [list]

Suggestion: Check network connectivity or try again later.
```

## Implementation Checklist

When deploying this template to a plugin:

- [x] Replace `{PLUGIN_NAME}` with plugin display name
- [x] Replace `{PLUGIN_COMMAND_PREFIX}` with plugin command prefix
- [x] Replace `{PLUGIN_PATH}` with plugin directory name
- [x] Verify documentation path is correct
- [ ] Test with `core` scope
- [ ] Test with `all` scope
- [ ] Test with specific feature name
- [ ] Register command in `.claude/settings.local.json`
- [ ] Validate command with validation script

## Related Commands

This command works in conjunction with:
- Plugin-specific build commands (e.g., `/mem0:init`)
- Plugin-specific feature commands (e.g., `/mem0:add-{feature}`)
- General documentation tools

**Workflow Pattern:**
1. Load documentation with `/mem0:load-docs {feature}`
2. Review documentation for implementation approach
3. Build feature with `/mem0:add-{feature}`

---

**Template Version:** 1.0.0
**Template Author:** domain-plugin-builder
**Usage:** This template is used to generate load-docs commands for all plugins
