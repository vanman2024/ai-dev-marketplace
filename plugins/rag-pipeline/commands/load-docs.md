---
description: Load RAG Pipeline documentation on-demand with intelligent link extraction and parallel WebFetch
argument-hint: [feature-name|core|all]
allowed-tools: Task, Read, Bash
---

# Load RAG Pipeline Documentation

**Purpose:** Load fresh RAG Pipeline documentation on-demand by extracting external links from local docs and fetching them in priority-based batches.

## Command Arguments

**Syntax:** `/rag-pipeline:load-docs [argument]`

**Arguments:**
- **Empty/No argument** - Load core documentation only (P0 essential links)
- **`core`** - Explicitly load only core documentation (same as empty)
- **`all`** - Load all documentation (P0 + P1 + P2) - comprehensive but uses more context
- **`{feature-name}`** - Load core + specific feature documentation (e.g., "streaming", "sessions", "tools")

**Examples:**
- `/rag-pipeline:load-docs` - Load core documentation (essential only)
- `/rag-pipeline:load-docs core` - Load core documentation explicitly
- `/rag-pipeline:load-docs all` - Load all documentation (comprehensive)
- `/rag-pipeline:load-docs streaming` - Load documentation for specific feature

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

Task(description="Load RAG Pipeline documentation", subagent_type="doc-loader-agent", prompt="Load documentation for RAG Pipeline with scope: $SCOPE

Plugin: RAG Pipeline
Docs Path: plugins/rag-pipeline/docs/

Instructions:
1. Find markdown files in plugins/rag-pipeline/docs/
2. Extract external links (URLs)
3. Categorize by priority: P0 (Essential), P1 (Features), P2 (Advanced)
4. Fetch based on scope: core=P0 only, all=P0+P1+P2, feature=P0+matching P1
5. Return formatted documentation summary with source URLs")

Wait for agent to complete and return results.

### Phase 3: Display Results

**Present Documentation to User:**

The doc-loader-agent will return formatted documentation. Display it with a summary showing scope, documentation path, and status. Include usage tips for reloading with different scopes and building features using relevant slash commands.

## Features

- On-Demand Loading: Load only when needed, not during initialization
- Fresh Documentation: WebFetch ensures latest documentation
- Intelligent Batching: Priority-based loading optimizes context
- Flexible Scope: Core, feature-specific, or comprehensive loading
- Parallel Fetching: Multiple URLs fetched concurrently for speed
- Error Resilient: Handles WebFetch failures gracefully

## Context Impact

Estimated Token Usage:
- Core (default): ~5-10K tokens (essential documentation)
- Feature-specific: ~10-15K tokens (core + targeted feature)
- All: ~20-30K tokens (comprehensive documentation)

Recommendation: Use core or feature-name for most workflows. Use all only when comprehensive reference needed.

## Error Handling

The agent handles three scenarios gracefully:
1. No documentation found - Suggests checking plugin installation
2. No external links found - Recommends using local documentation
3. WebFetch failures - Reports successful/failed URLs and suggests retry

## Related Commands

This command works in conjunction with /rag-pipeline:init and /rag-pipeline:add-{feature} commands.

Workflow Pattern:
1. Load documentation with /rag-pipeline:load-docs {feature}
2. Review documentation for implementation approach
3. Build feature with /rag-pipeline:add-{feature}
