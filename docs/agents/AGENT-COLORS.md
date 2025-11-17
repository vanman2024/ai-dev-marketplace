# Agent Color Assignments by Domain

**Last Updated:** 2025-11-03

This document shows how agent colors are assigned based on their domain/plugin type in the AI Dev Marketplace.

---

## Color Scheme

| Color | Domain | Count | Plugins |
|-------|--------|-------|---------|
| 🟢 **Green** | Database Operations | 14 | Supabase |
| 🟡 **Yellow** | RAG & ML Operations | 24 | RAG Pipeline, ML Training |
| 🔵 **Blue** | Frontend Builders | 12 | Next.js Frontend, Website Builder |
| 🟠 **Orange** | Backend API Builders | 4 | FastAPI Backend |
| 🟣 **Purple** | AI SDK Integration & LLM APIs | 12 | Vercel AI SDK, Claude Agent SDK, OpenRouter |
| 🩷 **Pink** | Voice/Audio Operations | 6 | ElevenLabs |
| 🔵 **Cyan** | Memory & Documentation | 4 | Mem0, Plugin Docs Loader |

**Total Agents:** 76

---

## 🟢 Green - Database Operations (Supabase)

**Purpose:** All database-related operations - schemas, migrations, queries, RLS, realtime

**Agents (14):**
- supabase-architect
- supabase-migration-applier
- supabase-database-executor
- supabase-schema-validator
- supabase-security-auditor
- supabase-security-specialist
- supabase-performance-analyzer
- supabase-code-reviewer
- supabase-project-manager
- supabase-realtime-builder
- supabase-ai-specialist
- supabase-ui-generator
- supabase-validator
- supabase-tester

---

## 🟡 Yellow - RAG & ML Operations

**Purpose:** RAG pipelines, ML training, embeddings, retrieval, vector databases

### RAG Pipeline Agents (10):
- document-processor
- embedding-specialist
- retrieval-optimizer
- vector-db-engineer
- rag-architect
- web-scraper-agent
- llamaindex-specialist
- langchain-specialist
- rag-deployment-agent
- rag-tester

### ML Training Agents (14):
- ml-architect
- training-architect
- data-engineer
- data-specialist
- training-monitor
- peft-specialist
- distributed-training-specialist
- inference-deployer
- cost-optimizer
- integration-specialist
- lambda-specialist
- modal-specialist
- runpod-specialist
- ml-tester

**Total Yellow:** 24 agents

---

## 🔵 Blue - Frontend Builders

**Purpose:** Frontend code generation - Next.js, Astro, components, pages

### Next.js Frontend Agents (7):
- nextjs-setup-agent
- component-builder-agent
- page-generator-agent
- ai-sdk-integration-agent
- supabase-integration-agent
- design-enforcer-agent
- ui-search-agent

### Website Builder Agents (5):
- website-setup
- website-architect
- website-content
- website-ai-generator
- website-verifier

**Total Blue:** 12 agents

---

## 🟠 Orange - Backend API Builders

**Purpose:** Backend API generation - FastAPI, endpoints, database integration

**Agents (4):**
- fastapi-setup-agent
- endpoint-generator-agent
- database-architect-agent
- deployment-architect-agent

---

## 🟣 Purple - AI SDK Integration & LLM APIs

**Purpose:** AI SDK integration, LLM provider setup, multi-model routing

### Vercel AI SDK Agents (7):
- vercel-ai-advanced-agent
- vercel-ai-data-agent
- vercel-ai-production-agent
- vercel-ai-ui-agent
- vercel-ai-verifier-js
- vercel-ai-verifier-py
- vercel-ai-verifier-ts

### Claude Agent SDK Agents (4):
- claude-agent-setup
- claude-agent-features
- claude-agent-verifier-py
- claude-agent-verifier-ts

### OpenRouter Agents (4):
- openrouter-setup-agent
- openrouter-routing-agent
- openrouter-langchain-agent
- openrouter-vercel-integration-agent

**Total Purple:** 15 agents

---

## 🩷 Pink - Voice/Audio Operations

**Purpose:** Text-to-speech, speech-to-text, voice agents, audio processing

**Agents (6):**
- elevenlabs-setup
- elevenlabs-tts-integrator
- elevenlabs-stt-integrator
- elevenlabs-voice-manager
- elevenlabs-agents-builder
- elevenlabs-production-agent

---

## 🔵 Cyan - Memory & Documentation

**Purpose:** Memory management, documentation loading, analysis

### Mem0 Agents (3):
- mem0-integrator
- mem0-memory-architect
- mem0-verifier

### Plugin Docs Loader (1):
- doc-loader-agent

**Total Cyan:** 4 agents

---

## Quick Reference by Plugin

```
supabase/          → 🟢 Green  (14 agents) - DATABASE
rag-pipeline/      → 🟡 Yellow (10 agents) - RAG
ml-training/       → 🟡 Yellow (14 agents) - ML/RAG
nextjs-frontend/   → 🔵 Blue   (7 agents)  - FRONTEND
website-builder/   → 🔵 Blue   (5 agents)  - FRONTEND
fastapi-backend/   → 🟠 Orange (4 agents)  - BACKEND
vercel-ai-sdk/     → 🟣 Purple (7 agents)  - AI-SDK
claude-agent-sdk/  → 🟣 Purple (4 agents)  - AI-SDK
openrouter/        → 🟣 Purple (4 agents)  - LLM-API
elevenlabs/        → 🩷 Pink   (6 agents)  - VOICE
mem0/              → 🔵 Cyan   (3 agents)  - MEMORY
plugin-docs-loader/→ 🔵 Cyan   (1 agent)   - DOCS
```

---

## Rationale

### Green for Database
- All database operations unified under one color
- Easy to identify Supabase/database agents at a glance
- Matches the "data/storage" semantic meaning of green

### Yellow for RAG & ML
- Both involve data processing pipelines
- Both work with embeddings and vector operations
- Similar architectural patterns (ingest → process → store → retrieve)
- ML training often includes RAG components

### Blue for Frontend
- Traditional "build/create" color for component generation
- Clear visual separation from backend (orange)

### Orange for Backend
- Warm color for backend API servers
- Distinct from frontend blue

### Purple for AI SDK Integration
- Premium/advanced color for AI capabilities
- Unifies all LLM provider integrations

### Pink for Voice
- Unique domain deserves unique color
- Audio/speech operations are specialized

### Cyan for Memory & Docs
- Analysis and information retrieval
- Documentation and memory are related (both store/retrieve info)

---

## Update Script

To update agent colors in the future:

```bash
bash /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/scripts/update-agent-colors.sh
```

This script automatically assigns colors based on plugin directory.
