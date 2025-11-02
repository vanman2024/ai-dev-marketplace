---
description: Load FastAPI Backend documentation on-demand with intelligent link extraction and parallel WebFetch
argument-hint: [feature-name|core|all]
allowed-tools: Task, Read, Bash
---

# Load FastAPI Backend Documentation

Load fresh FastAPI Backend documentation on-demand by extracting external links from local docs and fetching them in priority-based batches.

## Arguments

- Empty/No argument - Load core documentation only (P0 essential links)
- core - Explicitly load only core documentation
- all - Load all documentation (P0 + P1 + P2)
- {feature-name} - Load core + specific feature (e.g., streaming, auth, websocket)

## Workflow

### Phase 1: Parse Arguments

Parse $ARGUMENTS to extract scope parameter:

!{bash
SCOPE="$ARGUMENTS"
if [ -z "$SCOPE" ]; then
  SCOPE="core"
fi
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

Task(
  description="Load FastAPI Backend documentation",
  subagent_type="doc-loader-agent",
  prompt="Load documentation for FastAPI Backend with the following parameters:

  Plugin Information:
  - Plugin Name: FastAPI Backend
  - Documentation Path: plugins/fastapi-backend/docs/
  - Loading Scope: $SCOPE

  Instructions:
  1. Find all markdown documentation files in plugins/fastapi-backend/docs/
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

  Deliverable:
  Provide a comprehensive summary of the loaded documentation, organized by priority level, with source URLs and key information extracted from each page."
)

Wait for agent to complete and return results.

### Phase 3: Display Results

Present documentation to user with summary:

FastAPI Backend Documentation Loaded

Scope: {scope}
Documentation Path: plugins/fastapi-backend/docs/
Status: Complete

{Agent output with formatted documentation}

Usage Tips:
- Review core documentation for essential concepts
- Reference feature-specific sections as needed
- Use source URLs for more detailed information

Reload with different scope:
- /fastapi-backend:load-docs core - Essentials only
- /fastapi-backend:load-docs all - Everything
- /fastapi-backend:load-docs {feature} - Specific feature

Build features:
- /fastapi-backend:init - Initialize new project
- /fastapi-backend:add-{feature} - Add specific features

## Features

- On-Demand Loading - Load only when needed
- Fresh Documentation - WebFetch ensures latest docs
- Intelligent Batching - Priority-based loading
- Flexible Scope - Core, feature-specific, or comprehensive
- Parallel Fetching - Multiple URLs fetched concurrently
- Error Resilient - Handles WebFetch failures gracefully

## Context Impact

Estimated Token Usage:
- Core (default): ~5-10K tokens (essential documentation)
- Feature-specific: ~10-15K tokens (core + targeted feature)
- All: ~20-30K tokens (comprehensive documentation)

Recommendation: Use core or feature-name for most workflows. Use all only when comprehensive reference needed.
