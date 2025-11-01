# AI Development Marketplace

**Master repository for AI development plugins - your one-stop shop for tech-specific tools and frameworks.**

> **📢 NOTICE**: The `domain-plugin-builder` has been moved to its own standalone marketplace for better cross-repository compatibility. Install from: https://github.com/vanman2024/domain-plugin-builder

---

## What This Is

The **ai-dev-marketplace** is the central repository for all technology-specific plugins used in AI development workflows. This is where individual plugins live, are built, tested, and maintained.

**Key Concept:** This is a **master repository** of plugins, not a curated tech stack. Individual plugins can be installed directly from here, or referenced by curated tech stack marketplaces.

---

## Architecture: Master Plugin Repository

### What's Included

**Framework Builders:**
- ~~`domain-plugin-builder`~~ - **MOVED** to standalone marketplace: https://github.com/vanman2024/domain-plugin-builder
- `agent-sdk-dev` - Claude Agent SDK development tools

**AI SDKs & Frameworks:**
- `vercel-ai-sdk` - Modular Vercel AI SDK development with feature bundles
- `claude-agent-sdk` - Claude Agent SDK (coming soon)
- `openai-sdk` - OpenAI SDK (coming soon)
- `anthropic-sdk` - Anthropic SDK (coming soon)

**AI Memory & Context:**
- `mem0` - Memory management for AI agents (coming soon)
- `langchain` - LangChain integration (coming soon)

**Backend & Data:**
- `supabase` - Supabase integration (coming soon)
- `firebase` - Firebase integration (coming soon)
- `postgres` - PostgreSQL integration (coming soon)

**Frontend & UI:**
- `nextjs` - Next.js development (coming soon)
- `react` - React development (coming soon)
- `tailwind` - Tailwind CSS (coming soon)

**Note:** Lifecycle plugins (01-core, 02-develop, 03-planning, 04-iterate, 05-quality) have been moved to the [dev-lifecycle-marketplace](https://github.com/vanman2024/dev-lifecycle-marketplace).

---

## Three-Tier Architecture

This repository is part of a three-tier system:

```
┌─────────────────────────────────────────┐
│  dev-lifecycle-marketplace              │  ← How you develop
│  - 01-core, 02-develop, 03-planning     │    (tech-agnostic)
│  - 04-iterate, 05-quality               │
└─────────────────────────────────────────┘
              ↓ (optional)
┌─────────────────────────────────────────┐
│  ai-dev-marketplace (THIS REPO)         │  ← What you develop with
│  - domain-plugin-builder                │    (all tech plugins)
│  - vercel-ai-sdk, mem0, supabase, etc.  │
└─────────────────────────────────────────┘
              ↓ (references)
┌─────────────────────────────────────────┐
│  ai-tech-stack-N-marketplace            │  ← Curated combinations
│  References: vercel-ai-sdk + mem0       │    (opinionated stacks)
│              + supabase + nextjs        │
└─────────────────────────────────────────┘
```

### How They Work Together

**Tier 1: dev-lifecycle-marketplace** (Optional)
- Lifecycle commands like `/init`, `/plan`, `/test`, `/deploy`
- Tech-agnostic workflow automation
- Use when you want structured development phases

**Tier 2: ai-dev-marketplace** (This Repo - Foundation)
- Individual tech plugins
- Install only what you need: `claude plugin install vercel-ai-sdk`
- Mix and match plugins for your stack
- Source of truth for all plugins

**Tier 3: ai-tech-stack-N-marketplace** (Curated)
- Pre-configured combinations for specific use cases
- Example: "AI Chatbot Stack" = Vercel AI SDK + Mem0 + Supabase + Next.js
- Install entire stack at once
- Opinionated, tested configurations

---

## Use Cases

### Install Individual Plugins

```bash
# Install just what you need
claude plugin install vercel-ai-sdk --source github:vanman2024/ai-dev-marketplace

# Or install from local clone
cd /path/to/ai-dev-marketplace
claude plugin install vercel-ai-sdk --project
```

### Reference from Tech Stack Marketplaces

Tech stack marketplaces reference plugins from this repo:

```json
{
  "name": "ai-chatbot-stack-marketplace",
  "plugins": [
    {
      "name": "vercel-ai-sdk",
      "source": "github:vanman2024/ai-dev-marketplace/plugins/vercel-ai-sdk"
    },
    {
      "name": "mem0",
      "source": "github:vanman2024/ai-dev-marketplace/plugins/mem0"
    }
  ]
}
```

### Build Your Own Plugin

```bash
# Use the domain-plugin-builder
/domain-plugin-builder:plugin-create my-sdk-plugin
```

---

## Plugin Categories

### SDK Plugins
Build support for AI/ML SDKs:
- Vercel AI SDK, OpenAI SDK, Anthropic SDK, LangChain, etc.
- Pattern: `/sdk:init`, `/sdk:add-feature`, `/sdk:configure`

### Framework Plugins
Build support for web frameworks:
- Next.js, React, Svelte, FastAPI, etc.
- Pattern: `/framework:init`, `/framework:scaffold`, `/framework:deploy`

### Platform Plugins
Build support for platforms and services:
- Supabase, Firebase, Vercel, AWS, etc.
- Pattern: `/platform:init`, `/platform:configure`, `/platform:migrate`

---

## Building Plugins

All plugins in this repository are built using the **domain-plugin-builder**:

```bash
# Create a new SDK plugin
/domain-plugin-builder:plugin-create my-ai-sdk

# Create specialized components
/domain-plugin-builder:slash-commands-create my-command "description"
/domain-plugin-builder:agents-create my-agent "description" "tools"
/domain-plugin-builder:skills-create my-skill "description"
```

**Benefits:**
- Consistent structure across all plugins
- Built-in best practices
- Standardized command patterns
- Automated documentation generation

**Pattern Library:** See `plugins/domain-plugin-builder/docs/` for complete guides.

---

## Plugin Swapping

One of the key benefits of this architecture is **component swappability**:

```bash
# Scenario: You started with Vercel AI SDK, want to try OpenAI SDK

# Remove current SDK
claude plugin uninstall vercel-ai-sdk

# Install alternative
claude plugin install openai-sdk

# Your agents and commands adapt automatically
```

Tech stack marketplaces can offer multiple variants:
- `ai-chatbot-stack-vercel` (uses Vercel AI SDK)
- `ai-chatbot-stack-openai` (uses OpenAI SDK)
- `ai-chatbot-stack-langchain` (uses LangChain)

Same functionality, different implementation choices.

---

## Documentation Strategy

Plugins in this repository use a **hybrid documentation approach**:

### Static Documentation (Included)
- Conceptual guides and architecture
- Getting started tutorials
- Common patterns and examples
- Stored in `plugins/{name}/docs/`

### Dynamic Documentation (Context7)
- Latest API reference
- Up-to-date method signatures
- Breaking changes and migrations
- Fetched on-demand during feature implementation

**Pattern:**
- `/plugin:init` uses static docs (offline, stable)
- `/plugin:add-feature` uses Context7 (online, current)

See [domain-plugin-builder/docs/06-tech-stack-marketplaces.md](plugins/domain-plugin-builder/docs/06-tech-stack-marketplaces.md) for details.

---

## Development Workflow

### For Plugin Developers

1. **Build plugin** using domain-plugin-builder
2. **Test locally** with `--project` installation
3. **Document** in plugin's README and docs/
4. **Commit** to ai-dev-marketplace
5. **Tag release** for version pinning
6. **Publish** (others can reference via GitHub)

### For Plugin Users

1. **Browse marketplace** or individual plugins
2. **Install** what you need
3. **Use commands** (`/plugin:command`)
4. **Swap components** as needed
5. **Report issues** to this repo

---

## Version Management

All plugins use **semantic versioning**:

```json
{
  "name": "vercel-ai-sdk",
  "version": "1.0.0"
}
```

Tech stack marketplaces can pin specific versions:

```json
{
  "plugins": [
    {
      "name": "vercel-ai-sdk",
      "version": "1.0.0",
      "source": "github:vanman2024/ai-dev-marketplace/plugins/vercel-ai-sdk@v1.0.0"
    }
  ]
}
```

**Version Pinning Strategy:** See [06-tech-stack-marketplaces.md](plugins/domain-plugin-builder/docs/06-tech-stack-marketplaces.md#version-pinning-strategy)

---

## Optional: Add Lifecycle Plugins

This repository focuses on **tech plugins**. For lifecycle automation (init, plan, test, deploy), install the **dev-lifecycle-marketplace**:

```bash
# Add lifecycle marketplace
claude marketplace add dev-lifecycle-marketplace \
  --source github:vanman2024/dev-lifecycle-marketplace

# Now you have both:
# - Lifecycle commands (/init, /plan, /test, /deploy)
# - Tech plugins (Vercel AI SDK, Mem0, Supabase, etc.)
```

**Complete Workflow:**
```bash
/init                           # From lifecycle marketplace
/plan                           # From lifecycle marketplace
/vercel-ai-sdk:new-app my-app   # From tech plugin
/vercel-ai-sdk:add-streaming    # From tech plugin
/test                           # From lifecycle marketplace
/deploy                         # From lifecycle marketplace
```

---

## Status

**Current Plugins:**
- ✅ domain-plugin-builder (universal plugin builder)
- ✅ vercel-ai-sdk (modular AI SDK with feature bundles)
- ✅ agent-sdk-dev (Claude Agent SDK tools)

**Coming Soon:**
- mem0 (AI memory management)
- claude-agent-sdk (Agent SDK integration)
- supabase (Backend-as-a-Service)
- nextjs (Full-stack React framework)
- openai-sdk (OpenAI integration)
- langchain (LangChain integration)

**Roadmap:** Focus on AI development tools first, expand to full-stack later

---

## MCP Servers

This repository includes production-ready **Model Context Protocol (MCP) servers** that provide tools for Claude Desktop and other MCP-compatible clients:

### Available Servers

#### 1. CATS MCP Server (`mcp-servers/cats-mcp-server/`)
**Complete CATS API v3 integration** with 162 endpoints across 17 toolsets.

- **Purpose:** Applicant Tracking System automation
- **Endpoints:** Activities, Attachments, Candidates, Companies, Contacts, Events, Jobs, Pipelines, Portals, Tasks, Users, Webhooks, Work History
- **Rate Limit:** 500 requests/hour
- **Use Cases:** Recruitment automation, candidate management, job posting workflows

**Quick Start:**
```bash
cd mcp-servers/cats-mcp-server
./start.sh
```

**Documentation:** See `mcp-servers/cats-mcp-server/README.md`

#### 2. Content & Image Generation Server (`mcp-servers/content-image-generation-mcp/`)
**AI-powered content and image generation** combining Google Imagen/Veo with Claude/Gemini.

- **Purpose:** Multi-modal content and media generation
- **Features:** Image generation (Imagen), video generation (Veo), content writing (Claude/Gemini)
- **Outputs:** Marketing images, product videos, social media copy, blog content
- **Cost:** $0.20-0.50 per generation

**Quick Start:**
```bash
cd mcp-servers/content-image-generation-mcp
python server.py
```

**Documentation:** See `mcp-servers/content-image-generation-mcp/README.md`

### Integration with Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "cats-api": {
      "command": "python",
      "args": ["mcp-servers/cats-mcp-server/server.py"],
      "env": {
        "CATS_API_TOKEN": "your_token_here"
      }
    },
    "content-image-generation": {
      "command": "python",
      "args": ["mcp-servers/content-image-generation-mcp/server.py"],
      "env": {
        "GOOGLE_API_KEY": "your_key_here",
        "ANTHROPIC_API_KEY": "your_key_here"
      }
    }
  }
}
```

**Complete Setup Guide:** See `mcp-servers/README.md`

---

## Installation

### Install Entire Marketplace

```bash
# Clone repository
git clone https://github.com/vanman2024/ai-dev-marketplace.git
cd ai-dev-marketplace

# Install specific plugins
claude plugin install vercel-ai-sdk --project
claude plugin install domain-plugin-builder --project
```

### Install Individual Plugin via GitHub

```bash
# Without cloning
claude plugin install vercel-ai-sdk \
  --source github:vanman2024/ai-dev-marketplace/plugins/vercel-ai-sdk
```

### Register as Marketplace

```bash
# Add to your marketplaces
claude marketplace add ai-dev-marketplace \
  --source github:vanman2024/ai-dev-marketplace

# Browse available plugins
claude marketplace list ai-dev-marketplace
```

---

## Contributing

Contributions welcome! This repository is the central hub for AI development plugins.

**To Contribute:**

1. **Fork this repository**
2. **Create a new plugin** using domain-plugin-builder
3. **Test thoroughly** (commands, agents, documentation)
4. **Submit PR** with plugin in `plugins/` directory
5. **Update marketplace.json** to register plugin

**Guidelines:**
- Use domain-plugin-builder for consistency
- Include comprehensive documentation
- Provide examples and templates
- Test with multiple frameworks
- Follow semantic versioning

---

## Related Repositories

- **[dev-lifecycle-marketplace](https://github.com/vanman2024/dev-lifecycle-marketplace)** - Lifecycle plugins (01-core, 02-develop, etc.)
- **[ai-tech-stack-marketplaces](https://github.com/vanman2024/)** - Curated tech stack combinations

---

## Resources

- **Documentation:** See `plugins/domain-plugin-builder/docs/`
- **Pattern Library:** `plugins/domain-plugin-builder/docs/06-tech-stack-marketplaces.md`
- **Issues:** Report bugs/requests at [GitHub Issues](https://github.com/vanman2024/ai-dev-marketplace/issues)

---

## License

MIT License - See LICENSE file

---

**The master repository for AI development plugins. Build once, use everywhere.**
