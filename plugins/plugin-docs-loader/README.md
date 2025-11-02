# Plugin Documentation Loader

Universal documentation loading system with intelligent link extraction and parallel WebFetch for all plugins in the AI Dev Marketplace.

## Purpose

Provides on-demand documentation loading for all plugins without bloating context at initialization. Intelligently extracts external links from local markdown documentation and fetches them in priority-based batches.

## Components

### Agent: doc-loader-agent

Intelligent documentation loading agent that:
- Extracts external URLs from markdown documentation
- Categorizes links by priority (P0/P1/P2)
- Executes parallel WebFetch in batches
- Handles errors gracefully
- Returns context-optimized documentation summaries

### Skill: doc-templates

Reusable template for generating load-docs commands:
- `template-doc-loader-command.md` - Template for creating `/plugin:load-docs` commands

## Features

- **On-Demand Loading** - Load documentation only when needed
- **Fresh Documentation** - WebFetch ensures latest docs from official sources
- **Intelligent Batching** - Priority-based loading optimizes context usage
- **Flexible Scope** - Core, feature-specific, or comprehensive loading
- **Parallel Fetching** - Multiple URLs fetched concurrently for speed
- **Error Resilient** - Handles WebFetch failures gracefully

## Usage

Each plugin in the marketplace has a `/plugin-name:load-docs` command that uses this system:

```bash
# Load core documentation (essential only)
/claude-agent-sdk:load-docs
/vercel-ai-sdk:load-docs core

# Load all documentation (comprehensive)
/mem0:load-docs all

# Load feature-specific documentation
/fastapi-backend:load-docs websocket
/nextjs-frontend:load-docs routing
```

## Scope Options

- **core** (default) - Essential P0 documentation (~5-10K tokens)
- **all** - Comprehensive P0+P1+P2 documentation (~20-30K tokens)
- **{feature-name}** - Core + specific feature documentation (~10-15K tokens)

## Context Impact

| Scope | Token Usage | Best For |
|-------|-------------|----------|
| core | 5-10K | Quick reference, getting started |
| feature-specific | 10-15K | Implementing specific features |
| all | 20-30K | Comprehensive understanding, complex implementations |

## Integration

This plugin provides infrastructure for all other plugins. The doc-loader-agent is invoked by individual plugin load-docs commands via the Task tool.

## Version

1.0.0

## Author

AI Dev Marketplace
