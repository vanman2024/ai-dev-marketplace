---
description: Load plugin documentation on-demand with intelligent link extraction and parallel WebFetch for any plugin in the marketplace
argument-hint: <plugin-name> [scope]
allowed-tools: Task, Read, Bash, Grep
---

# Load Plugin Documentation

**Purpose:** Load fresh documentation for any plugin by extracting external links from local docs and fetching them in priority-based batches.

## Command Arguments

**Syntax:** `/plugin-docs-loader:load-docs <plugin-name> [scope]`

**Required:**
- `<plugin-name>` - Name of the plugin (e.g., "claude-agent-sdk", "vercel-ai-sdk", "mem0")

**Optional:**
- `[scope]` - What to load:
  - **Empty/core** - Load essential P0 documentation (~5-10K tokens)
  - **all** - Load comprehensive P0+P1+P2 documentation (~20-30K tokens)
  - **{feature-name}** - Load core + specific feature documentation (~10-15K tokens)

**Examples:**
```bash
# Load core documentation for Claude Agent SDK
/plugin-docs-loader:load-docs claude-agent-sdk

# Load all documentation for Vercel AI SDK
/plugin-docs-loader:load-docs vercel-ai-sdk all

# Load streaming feature documentation for FastAPI Backend
/plugin-docs-loader:load-docs fastapi-backend streaming

# Load tool calling documentation for Vercel AI SDK
/plugin-docs-loader:load-docs vercel-ai-sdk tools
```

## Workflow

### Phase 1: Parse Arguments

**Extract plugin name and scope from $ARGUMENTS:**

!{bash
# Parse arguments
PLUGIN_NAME=$(echo "$ARGUMENTS" | awk '{print $1}')
SCOPE=$(echo "$ARGUMENTS" | awk '{print $2}')

# Validate plugin name
if [ -z "$PLUGIN_NAME" ]; then
  echo "❌ Error: Plugin name is required"
  echo "Usage: /plugin-docs-loader:load-docs <plugin-name> [scope]"
  exit 1
fi

# Default scope to "core" if empty
if [ -z "$SCOPE" ]; then
  SCOPE="core"
fi

# Verify plugin exists
PLUGIN_PATH="plugins/$PLUGIN_NAME"
if [ ! -d "$PLUGIN_PATH" ]; then
  echo "❌ Error: Plugin '$PLUGIN_NAME' not found at $PLUGIN_PATH"
  echo ""
  echo "Available plugins:"
  ls -1 plugins/ | grep -v "plugin-docs-loader"
  exit 1
fi

# Verify docs directory exists
DOCS_PATH="$PLUGIN_PATH/docs"
if [ ! -d "$DOCS_PATH" ]; then
  echo "❌ Error: No docs directory found at $DOCS_PATH"
  exit 1
fi

echo "📚 Loading documentation for: $PLUGIN_NAME"
echo "📂 Documentation path: $DOCS_PATH"
echo "🎯 Scope: $SCOPE"
echo ""
}

### Phase 2: Invoke Documentation Loader Agent

**Load documentation via doc-loader-agent:**

The agent will handle:
- Finding all markdown files in the docs directory
- Extracting all external links (could be 60-100+ URLs)
- Categorizing links by priority (P0/P1/P2)
- Fetching documentation in parallel batches
- Returning formatted documentation summary

Task(
  description="Load $PLUGIN_NAME documentation with scope $SCOPE",
  subagent_type="doc-loader-agent",
  prompt="Load documentation for $PLUGIN_NAME plugin with the following parameters:

  **Plugin Information:**
  - Plugin Name: $PLUGIN_NAME
  - Documentation Path: $DOCS_PATH
  - Loading Scope: $SCOPE

  **Instructions:**
  1. Find all markdown documentation files in $DOCS_PATH
  2. Extract ALL external links (URLs) from these files - there could be 60-100+ links
  3. Categorize links by priority:
     - P0 (Essential): overview, introduction, quickstart, getting-started
     - P1 (Features): feature-specific documentation matching scope
     - P2 (Advanced): advanced topics, reference, migration
  4. Fetch documentation in parallel batches based on scope:
     - If scope is 'core': Load P0 only (4-6 URLs)
     - If scope is 'all': Load P0 + P1 + P2 (up to 20-30 URLs in batches)
     - If scope is feature name: Load P0 + P1 URLs matching feature (10-15 URLs)
  5. Execute WebFetch in parallel (4-6 URLs per batch)
  6. Handle errors gracefully - if WebFetch fails, note it but continue
  7. Return formatted documentation summary with all loaded content

  **Deliverable:**
  Return comprehensive documentation summary including:
  - List of URLs fetched by priority
  - Documentation content organized by topic
  - Total URLs processed
  - Any errors encountered
  - Estimated token usage

  **Important:** You MUST process all links found in the documentation. This is critical because other agents need access to ALL the documentation, not just a subset. Use parallel batching to handle large numbers of links efficiently."
)

### Phase 3: Display Results

**Present loaded documentation to user:**

The agent will return:
- ✅ Documentation content organized by priority
- ✅ List of all URLs fetched
- ✅ Total link count and token usage
- ✅ Any errors or warnings

**Next Steps:**
- Review the loaded documentation
- Use it to inform your work with other agents
- Re-run with different scope if needed

## Scope Recommendations

**Use `core` when:**
- Quick reference needed
- Getting started with a plugin
- Understanding basic concepts
- Working on simple tasks

**Use `{feature-name}` when:**
- Implementing specific feature
- Need detailed feature documentation
- Working on feature-specific code
- Example: `streaming`, `tools`, `auth`, etc.

**Use `all` when:**
- Comprehensive understanding needed
- Complex implementation work
- Need access to ALL documentation
- Working with multiple features
- Another agent needs full context (⚠️ uses 20-30K tokens)

## Notes

- The agent handles parallel WebFetch automatically
- Large numbers of links (60-100+) are processed in batches
- Fresh documentation is always fetched from official sources
- Context usage scales with scope selection
- Documentation is formatted for easy consumption by other agents
