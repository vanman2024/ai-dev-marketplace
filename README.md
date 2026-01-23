# AI Development Marketplace

**Central repository of 21 Claude Code plugins for AI-powered development - agents, SDKs, frontends, backends, and infrastructure.**

> **Note**: The `domain-plugin-builder` has been moved to its own standalone repository: https://github.com/vanman2024/domain-plugin-builder

---

## What This Is

The **ai-dev-marketplace** is a collection of Claude Code plugins that provide slash commands, specialized agents, and skills for building AI applications. Each plugin targets a specific technology and can be used independently or combined into full-stack solutions.

---

## Plugins (21 Total)

### AI Agent Frameworks

| Plugin | Description |
|--------|-------------|
| `claude-agent-sdk` | Build AI agents with Claude's Agent SDK (TypeScript/Python) |
| `google-adk` | Google Agent Development Kit - Python, TypeScript, Go, Java |
| `a2a-protocol` | Agent-to-Agent Protocol for multi-agent interoperability |

### AI SDKs & Model Access

| Plugin | Description |
|--------|-------------|
| `vercel-ai-sdk` | Modular Vercel AI SDK with streaming, tool-calling, and multi-provider support |
| `openrouter` | Unified interface for 500+ LLM models with intelligent routing and cost optimization |
| `elevenlabs` | AI audio - TTS, STT, voice cloning, and Vercel AI SDK integration |

### AI Memory & RAG

| Plugin | Description |
|--------|-------------|
| `mem0` | AI memory management - Platform (hosted), Open Source (Supabase), MCP (OpenMemory) |
| `rag-pipeline` | RAG toolkit with LlamaIndex, LangChain, pgvector, Pinecone, Chroma |

### Machine Learning

| Plugin | Description |
|--------|-------------|
| `ml-training` | ML training/inference on cloud GPUs (Modal, Lambda Labs, RunPod) with HuggingFace |

### Frontend

| Plugin | Description |
|--------|-------------|
| `nextjs-frontend` | Next.js 15 App Router with AI SDK, Supabase, shadcn/ui, SEO, marketing tools |
| `sveltekit-frontend` | SvelteKit with Tailwind CSS v4, shadcn-svelte, Bun, HTML-to-Svelte migration |
| `mobile` | React Native/Expo, PWA, responsive design, EAS Build, app store deployment |
| `website-builder` | AI-powered sites with Astro, MDX, content-image-generation MCP, Supabase CMS |

### Backend

| Plugin | Description |
|--------|-------------|
| `fastapi-backend` | Production FastAPI with async/await, Mem0, SQLAlchemy, PostgreSQL |
| `celery` | Distributed task queue - workers, beat scheduling, Flower monitoring |

### Data & Infrastructure

| Plugin | Description |
|--------|-------------|
| `supabase` | Database, auth, storage, realtime, pgvector for AI apps |
| `redis` | Caching, sessions, rate limiting, pub/sub, AI embedding cache |

### Auth & Payments

| Plugin | Description |
|--------|-------------|
| `clerk` | Authentication with OAuth, organizations, and billing |
| `payments` | Stripe integration - checkout, subscriptions, webhooks with FastAPI/Next.js/Supabase |

### Communication

| Plugin | Description |
|--------|-------------|
| `resend` | Email API - transactional, contacts, broadcasts, templates, webhooks |

### Utilities

| Plugin | Description |
|--------|-------------|
| `plugin-docs-loader` | Universal documentation loading with link extraction and parallel WebFetch |

---

## Installation

### Clone the Repository

```bash
git clone https://github.com/vanman2024/ai-dev-marketplace.git
cd ai-dev-marketplace
```

### Install a Plugin

```bash
# From local clone
claude plugin install vercel-ai-sdk --project

# From GitHub directly
claude plugin install vercel-ai-sdk \
  --source github:vanman2024/ai-dev-marketplace/plugins/vercel-ai-sdk
```

### Register as Marketplace

```bash
claude marketplace add ai-dev-marketplace \
  --source github:vanman2024/ai-dev-marketplace

claude marketplace list ai-dev-marketplace
```

---

## Plugin Structure

Each plugin follows a consistent structure:

```
plugins/{name}/
├── .claude-plugin/
│   └── plugin.json          # Manifest (name, version, description)
├── commands/                # Slash commands (/plugin:command)
├── agents/                  # Specialized AI agents
├── skills/                  # Reusable knowledge/templates
├── docs/                    # Static documentation
└── README.md
```

---

## Example Stacks

Combine plugins for complete solutions:

**AI Chatbot:**
```
vercel-ai-sdk + mem0 + supabase + nextjs-frontend + clerk
```

**SaaS Platform:**
```
nextjs-frontend + supabase + clerk + payments + redis + resend
```

**Multi-Agent System:**
```
claude-agent-sdk + a2a-protocol + celery + redis + supabase
```

**Mobile App:**
```
mobile + supabase + clerk + fastapi-backend
```

**ML Pipeline:**
```
ml-training + rag-pipeline + redis + fastapi-backend + supabase
```

---

## Building New Plugins

Use the [domain-plugin-builder](https://github.com/vanman2024/domain-plugin-builder):

```bash
/domain-plugin-builder:build-plugin my-plugin
```

This creates the full plugin structure with commands, agents, and skills.

---

## Related Repositories

- **[domain-plugin-builder](https://github.com/vanman2024/domain-plugin-builder)** - Tool for building new plugins
- **[dev-lifecycle-marketplace](https://github.com/vanman2024/dev-lifecycle-marketplace)** - Lifecycle plugins (init, plan, test, deploy)

---

## License

MIT
