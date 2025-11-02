---
description: Load Next.js Frontend documentation on-demand with intelligent link extraction and parallel WebFetch
argument-hint: [feature-name|core|all]
allowed-tools: Task, Read, Bash
---

# Load Next.js Frontend Documentation

**Purpose:** Load fresh Next.js Frontend documentation on-demand by extracting external links from local docs and fetching them in priority-based batches.

## Command Arguments

**Syntax:** `/nextjs-frontend:load-docs [argument]`

**Arguments:**
- Empty/No argument - Load core documentation only (P0 essential links)
- core - Explicitly load only core documentation (same as empty)
- all - Load all documentation (P0 + P1 + P2) - comprehensive but uses more context
- feature-name - Load core + specific feature documentation (e.g., routing, data-fetching, components)

**Examples:**
- /nextjs-frontend:load-docs (core only)
- /nextjs-frontend:load-docs core
- /nextjs-frontend:load-docs all
- /nextjs-frontend:load-docs routing

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

Extract scope and display to user.

### Phase 2: Invoke Documentation Loader Agent

Invoke the doc-loader-agent with the determined scope:

Task(description="Load Next.js Frontend documentation", subagent_type="doc-loader-agent", prompt="Load documentation for Next.js Frontend with the following parameters:

**Plugin Information:**
- Plugin Name: Next.js Frontend
- Documentation Path: plugins/nextjs-frontend/docs/
- Loading Scope: $SCOPE

**Instructions:**
1. Find all markdown documentation files in plugins/nextjs-frontend/docs/
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
Provide a comprehensive summary of the loaded documentation, organized by priority level, with source URLs and key information extracted from each page.")

Wait for agent to complete and return results.

### Phase 3: Display Results

The doc-loader-agent will return formatted documentation. Display it to the user with a summary:

**Next.js Frontend Documentation Loaded**

Scope: {scope}
Documentation Path: plugins/nextjs-frontend/docs/
Status: Complete

{Agent output with formatted documentation}

---

**Usage Tips:**

To reload with different scope:
- /nextjs-frontend:load-docs core - Essentials only
- /nextjs-frontend:load-docs all - Everything
- /nextjs-frontend:load-docs {feature} - Specific feature

To build features:
- /nextjs-frontend:init - Initialize new Next.js project
- /nextjs-frontend:add-page - Add new pages
- /nextjs-frontend:add-component - Add UI components
- /nextjs-frontend:integrate-supabase - Integrate Supabase
- /nextjs-frontend:integrate-ai-sdk - Integrate Vercel AI SDK

## Configuration

**Plugin Variables:**
- Plugin Name: Next.js Frontend
- Command Prefix: nextjs-frontend
- Plugin Path: nextjs-frontend
- Documentation Path: plugins/nextjs-frontend/docs/

## Features

On-Demand Loading - Load only when needed, not during initialization
Fresh Documentation - WebFetch ensures latest documentation
Intelligent Batching - Priority-based loading optimizes context
Flexible Scope - Core, feature-specific, or comprehensive loading
Parallel Fetching - Multiple URLs fetched concurrently for speed
Error Resilient - Handles WebFetch failures gracefully

## Context Impact

**Estimated Token Usage:**
- Core (default): ~5-10K tokens (essential documentation)
- Feature-specific: ~10-15K tokens (core + targeted feature)
- All: ~20-30K tokens (comprehensive documentation)

**Recommendation:**
Use core or feature-name for most workflows. Use all only when comprehensive reference needed. Reload as needed rather than loading everything upfront.

## Error Handling

**No documentation found:** Check that the plugin has documentation installed in plugins/nextjs-frontend/docs/

**No external links found:** The plugin may only have local documentation. Refer to files in plugins/nextjs-frontend/docs/ directly.

**WebFetch failures:** Check network connectivity or try again later. Agent will report successful vs failed URLs.

## Related Commands

This command works in conjunction with:
- /nextjs-frontend:init - Initialize Next.js project
- /nextjs-frontend:add-page - Add new pages
- /nextjs-frontend:add-component - Add UI components
- /nextjs-frontend:integrate-supabase - Integrate Supabase
- /nextjs-frontend:integrate-ai-sdk - Integrate AI SDK

**Workflow Pattern:**
1. Load documentation with /nextjs-frontend:load-docs {feature}
2. Review documentation for implementation approach
3. Build feature with appropriate command

---

**Template Version:** 1.0.0
**Template Author:** domain-plugin-builder
