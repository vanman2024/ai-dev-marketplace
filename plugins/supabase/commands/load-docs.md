---
description: Load Supabase documentation on-demand with intelligent link extraction and parallel WebFetch
argument-hint: [feature-name|core|all]
allowed-tools: Task, Read, Bash
---

# Load Supabase Documentation

**Purpose:** Load fresh Supabase documentation on-demand by extracting external links from local docs and fetching them in priority-based batches.

## Command Arguments

**Syntax:** `/supabase:load-docs [argument]`

**Arguments:**
- **Empty/No argument** - Load core documentation only (P0 essential links)
- **`core`** - Explicitly load only core documentation (same as empty)
- **`all`** - Load all documentation (P0 + P1 + P2) - comprehensive but uses more context
- **`{feature-name}`** - Load core + specific feature documentation (e.g., "streaming", "sessions", "tools")

**Examples:**
- `/supabase:load-docs` - Load core documentation
- `/supabase:load-docs all` - Load all documentation
- `/supabase:load-docs auth` - Load auth-specific docs

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

Task(description="Load Supabase documentation", subagent_type="doc-loader-agent", prompt="Load documentation for Supabase.

Plugin: Supabase
Docs Path: plugins/supabase/docs/
Scope: $SCOPE

Instructions:
1. Find markdown files in plugins/supabase/docs/
2. Extract external URLs
3. Categorize by priority (P0: essential, P1: features, P2: advanced)
4. Fetch based on scope (core=P0, all=P0+P1+P2, feature=P0+matching)
5. Return formatted summary with URLs and key info")

### Phase 3: Display Results

Display the doc-loader-agent output with summary:

## Supabase Documentation Loaded

Scope: $SCOPE
Path: plugins/supabase/docs/
Status: Complete

[Agent output]

Usage Tips:
- Reload with different scope: `/supabase:load-docs [core|all|feature]`
- Build features: `/supabase:init`, `/supabase:add-auth`, etc.

## Features

- On-demand documentation loading with intelligent batching
- Priority-based loading (P0 core, P1 features, P2 advanced)
- Parallel WebFetch for speed
- Flexible scope: core, all, or feature-specific
- Token-efficient (5-10K core, 10-15K feature, 20-30K all)

## Related Commands

- `/supabase:init` - Initialize new project
- `/supabase:add-auth` - Add authentication
- `/supabase:add-storage` - Add file storage
- `/supabase:add-realtime` - Add realtime features
