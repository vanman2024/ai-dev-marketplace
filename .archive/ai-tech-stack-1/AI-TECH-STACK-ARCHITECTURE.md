# AI Tech Stack Architecture

## The Kitchen vs Appliances Philosophy

**Kitchen (93% - Foundation)**: AI Tech Stack 1
**Appliances (7% - Domain-Specific)**: Domain plugins

## Stack 1: The Foundation (AI Applications)

### Complete Technology Stack
- **Frontend**: Next.js 15 (App Router, Server Components, TypeScript)
- **AI Framework**: Vercel AI SDK (streaming, multi-model, tools)
- **Database**: Supabase (PostgreSQL, RLS, Auth, Realtime)
- **Memory**: Mem0 (user/agent/session memory, pgvector)
- **MCP Integration**: FastMCP (custom tools, resources, prompts)
- **Agent Framework**: Claude Agent SDK (orchestration, subagents)

### What It's For
- **AI Applications** (chatbots, assistants, platforms)
- **Full-Stack Apps** with AI capabilities
- **Complex Multi-Model Systems**
- **Production-Ready Deployments**

### Example: Red AI
Red AI is the validation use case for AI Tech Stack 1:
- Multi-model orchestration (Claude + OpenAI + Gemini)
- Cost tracking across providers
- Prompt management with A/B testing
- User memory persistence
- Real-time collaboration
- Authentication (email + OAuth)
- Deployment (Vercel + Fly.io)

**Red AI = Proof that Stack 1 handles ANY AI application**

## website-builder: Marketing Sites Only

### Technology Stack
- **Framework**: Astro (static site generator)
- **CMS**: Supabase (optional, for dynamic content)
- **AI Content**: content-image-generation MCP (optional)
- **Styling**: Tailwind CSS
- **Components**: React (for islands architecture)

### What It's For
- **Marketing websites** (product pages, landing pages)
- **Blogs** (content-focused, RSS feeds)
- **Documentation sites** (technical docs, guides)
- **Static content** (brochure sites)

### What It's NOT For
- ❌ Full-stack applications
- ❌ AI chat applications
- ❌ Real-time collaboration tools
- ❌ Complex backend logic

### Correct Command Names
- `/website-builder:init` - Initialize Astro project
- `/website-builder:add-page` - Add static page
- `/website-builder:add-blog` - Add blog structure
- `/website-builder:integrate-supabase-cms` - Add dynamic CMS
- `/website-builder:generate-content` - AI content generation
- `/website-builder:deploy` - Deploy to Vercel/Netlify/Cloudflare
- **RENAME**: `/website-builder:deploy-full-stack` → `/website-builder:deploy-marketing-site`

## nextjs-frontend: Application Frontends

### Technology Stack
- **Framework**: Next.js 15 (App Router)
- **Rendering**: Server Components + Client Islands
- **Styling**: Tailwind CSS
- **Components**: shadcn/ui
- **State**: React hooks + Server Actions

### What It's For
- **Application frontends** (dashboards, admin panels)
- **Interactive UIs** (forms, real-time updates)
- **Full-stack apps** (paired with backend)
- **AI interfaces** (chat, completions, streaming)

### Integration Commands
- `/nextjs-frontend:init` - Create Next.js 15 project
- `/nextjs-frontend:integrate-supabase` - Add Supabase client
- `/nextjs-frontend:integrate-ai-sdk` - Add Vercel AI SDK
- `/nextjs-frontend:add-component` - Add shadcn/Tailwind UI components
- `/nextjs-frontend:add-page` - Create app routes

## The Orchestrators

### ai-tech-stack-1: Full-Stack AI Applications

**Purpose**: Deploy complete AI application stack with ONE command

**Technology Orchestration**:
1. Next.js 15 frontend (via `/nextjs-frontend:*`)
2. Vercel AI SDK (via `/vercel-ai-sdk:*`)
3. Supabase database (via `/supabase:*`)
4. Mem0 memory (via `/mem0:*`)
5. FastMCP tools (via `/fastmcp:*`)
6. Claude Agent SDK (via `/claude-agent-sdk:*`)

**Main Command**: `/ai-tech-stack-1:build-full-stack <app-name>`

**Use Cases**:
- Red AI (multi-pillar AI platform)
- AI chatbots with memory
- Multi-model applications
- RAG systems with Supabase
- Complex AI agents

**Target Deployment Time**: 60-90 minutes (slow but reliable)

### website-builder: Marketing Site Deployment

**Purpose**: Deploy static marketing site with optional AI content

**Technology Orchestration**:
1. Astro static site
2. Supabase CMS (optional)
3. content-image-generation MCP (optional)
4. SEO optimization
5. Static deployment

**Main Command**: `/website-builder:deploy-marketing-site <site-name>` (RENAMED)

**Use Cases**:
- Product marketing sites
- Company blogs
- Documentation portals
- Landing pages

**Target Deployment Time**: 30-40 minutes

## Decision Tree

```
User wants to build...

├─ AI Application?
│  ├─ YES → Use ai-tech-stack-1
│  │        Examples: Red AI, chatbot, AI assistant, RAG system
│  │        Stack: Next.js + Vercel AI SDK + Supabase + Mem0 + FastMCP
│  │
│  └─ NO → Continue...
│
├─ Marketing/Content Site?
│  ├─ YES → Use website-builder
│  │        Examples: Product site, blog, docs, landing page
│  │        Stack: Astro + optional Supabase CMS + optional AI content
│  │
│  └─ NO → Continue...
│
└─ Custom Application?
   └─ Use base plugins individually:
      - /nextjs-frontend:init (for frontend)
      - /supabase:init (for database)
      - /vercel-ai-sdk:new-app (for AI features)
      - etc.
```

## Plugin Composition Pattern

### Base Plugins (Technology-Specific)
- `nextjs-frontend` - Next.js 15 setup and configuration
- `vercel-ai-sdk` - AI streaming, models, tools
- `supabase` - Database, auth, realtime, pgvector
- `mem0` - Memory persistence (Platform/OSS/MCP)
- `fastmcp` - Custom MCP servers
- `claude-agent-sdk` - Agent orchestration
- `website-builder` - Astro static sites

### Orchestrator Plugins (Stack-Specific)
- `ai-tech-stack-1` - Orchestrates base plugins for AI apps
- `website-builder` - Orchestrates Astro for marketing sites

### Command Invocation Pattern

**Orchestrator commands invoke base plugin commands:**

```markdown
/ai-tech-stack-1:build-full-stack my-app

Phase 1: Discovery (5 min)
- Ask all questions upfront
- Determine requirements

Phase 2: Frontend (10 min)
- SlashCommand: /nextjs-frontend:init my-app
- Wait for completion before proceeding
- Verify project structure

Phase 3: Database (10 min)
- SlashCommand: /supabase:init-ai-app
- Wait for completion before proceeding
- Verify schema creation

Phase 4: AI Integration (15 min)
- SlashCommand: /vercel-ai-sdk:add-streaming
- SlashCommand: /vercel-ai-sdk:add-tools
- Wait for both to complete
- Verify AI routes

Phase 5: Memory (10 min)
- SlashCommand: /mem0:init-oss
- Wait for completion
- Verify memory operations

[... continues through all phases]
```

## Execution Control Philosophy

### "Slow but Reliable" > "Fast but Chaotic"

**User Requirement**: "I'm not looking for speed, just thorough execution"

**Problem**: AI tries to run everything in parallel → build destruction

**Solution**: Sequential phases with explicit control

### Control Mechanisms

1. **Explicit Wait Statements**
   ```markdown
   - SlashCommand: /nextjs-frontend:init
   - Wait for completion before proceeding  ← Hard barrier
   ```

2. **Phase Boundaries**
   ```markdown
   Phase 2: Frontend (ONLY after Phase 1 complete)
   ```

3. **TodoWrite Checkpoints**
   ```markdown
   - TodoWrite: Mark frontend setup complete ✅
   ```

4. **Validation Gates**
   ```markdown
   - Verify package.json exists
   - If missing: STOP, do NOT proceed to Phase 3
   ```

5. **Limited Parallelism**
   ```markdown
   ❌ Don't: Run 15 commands in parallel
   ✅ Do: Max 3-4 agents per phase
   ```

6. **Single Orchestrator Context**
   ```markdown
   ❌ Don't: Launch 6 Claude Code terminals
   ✅ Do: One orchestrator command with sequential phases
   ```

## Global Command Registration

All orchestrator commands registered in `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "SlashCommand(/ai-tech-stack-1:*)",
      "SlashCommand(/ai-tech-stack-1:build-full-stack)",
      "SlashCommand(/ai-tech-stack-1:add-frontend)",
      "SlashCommand(/ai-tech-stack-1:add-backend)",
      "SlashCommand(/ai-tech-stack-1:add-database)",
      "SlashCommand(/ai-tech-stack-1:add-ai-features)",
      "SlashCommand(/ai-tech-stack-1:deploy)",

      "SlashCommand(/website-builder:*)",
      "SlashCommand(/website-builder:deploy-marketing-site)",

      "SlashCommand(/nextjs-frontend:*)",
      "SlashCommand(/supabase:*)",
      "SlashCommand(/vercel-ai-sdk:*)",
      "SlashCommand(/mem0:*)",
      "SlashCommand(/fastmcp:*)",
      "SlashCommand(/claude-agent-sdk:*)"
    ]
  },
  "enabledPlugins": {
    "ai-tech-stack-1@ai-dev-marketplace": true,
    "website-builder@ai-dev-marketplace": true,
    "nextjs-frontend@ai-dev-marketplace": true,
    "supabase@ai-dev-marketplace": true,
    "vercel-ai-sdk@ai-dev-marketplace": true,
    "mem0@ai-dev-marketplace": true,
    "fastmcp@ai-dev-marketplace": true,
    "claude-agent-sdk@ai-dev-marketplace": true
  }
}
```

**Benefits**:
- Commands work from ANY directory
- No need to copy commands to each project
- One central registry
- Cross-plugin orchestration enabled

## Summary

| Plugin | Purpose | Stack | Output | Time |
|--------|---------|-------|--------|------|
| **ai-tech-stack-1** | AI Applications | Next.js + AI SDK + Supabase + Mem0 + MCP | Full-stack app | 60-90 min |
| **website-builder** | Marketing Sites | Astro + optional CMS/AI | Static site | 30-40 min |
| **nextjs-frontend** | App Frontends | Next.js 15 only | Frontend only | 10 min |
| **supabase** | Database | Supabase only | Database only | 10 min |
| **vercel-ai-sdk** | AI Features | Vercel AI SDK only | AI routes only | 15 min |

**Red AI Validation**: ai-tech-stack-1 must handle ALL Red AI requirements to prove it works for any AI application.
