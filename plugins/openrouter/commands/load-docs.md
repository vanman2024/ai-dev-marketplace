---
description: Load OpenRouter documentation on-demand with intelligent link extraction and parallel WebFetch
argument-hint: [feature-name|core|all]
allowed-tools: Task, Read, Bash
---

# Load OpenRouter Documentation

**Purpose:** Load fresh OpenRouter documentation on-demand by extracting external links from local docs and fetching them in priority-based batches.

## Command Arguments

**Syntax:** `/openrouter:load-docs [argument]`

**Arguments:**
- **Empty/No argument** - Load core documentation only (P0 essential links)
- **`core`** - Explicitly load only core documentation (same as empty)
- **`all`** - Load all documentation (P0 + P1 + P2) - comprehensive but uses more context
- **`{feature-name}`** - Load core + specific feature documentation (e.g., "streaming", "models", "providers")

**Examples:**
```bash
/openrouter:load-docs              # Load core documentation
/openrouter:load-docs all          # Load all documentation
/openrouter:load-docs streaming    # Load core + streaming feature
```

## Workflow

### Phase 1: Parse Arguments

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
    echo "Loading core + feature: $SCOPE"
    ;;
esac
}

### Phase 2: Invoke Documentation Loader Agent

Invoke the doc-loader-agent with the determined scope:

```markdown
Task(
  description="Load OpenRouter documentation",
  subagent_type="doc-loader-agent",
  prompt="Load documentation for OpenRouter with the following parameters:

  **Plugin Information:**
  - Plugin Name: OpenRouter
  - Documentation Path: plugins/openrouter/docs/
  - Loading Scope: $SCOPE

  **Instructions:**
  1. Find all markdown documentation files in plugins/openrouter/docs/
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

### Phase 3: Display Results

Present documentation to user with summary:

```markdown
## OpenRouter Documentation Loaded

**Scope:** {scope}
**Documentation Path:** plugins/openrouter/docs/
**Status:** Complete

{Agent output with formatted documentation}

---

## Usage Tips

**To reload with different scope:**
- `/openrouter:load-docs core` - Essentials only
- `/openrouter:load-docs all` - Everything
- `/openrouter:load-docs {feature}` - Specific feature

**To build features:**
- `/openrouter:new-app` - Initialize new project
- `/openrouter:add-{feature}` - Add specific features
```

## Features

- On-Demand Loading - Load only when needed, not during initialization
- Fresh Documentation - WebFetch ensures latest documentation
- Intelligent Batching - Priority-based loading optimizes context
- Flexible Scope - Core, feature-specific, or comprehensive loading
- Parallel Fetching - Multiple URLs fetched concurrently for speed
- Error Resilient - Handles WebFetch failures gracefully

## Context Impact

**Estimated Token Usage:**
- **Core (default):** ~5-10K tokens (essential documentation)
- **Feature-specific:** ~10-15K tokens (core + targeted feature)
- **All:** ~20-30K tokens (comprehensive documentation)

**Recommendation:** Use `core` or `feature-name` for most workflows. Use `all` only when comprehensive reference needed.
