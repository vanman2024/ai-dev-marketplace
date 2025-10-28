# Vercel AI SDK Plugin - Skills Overview

This document provides a comprehensive overview of all skills in the Vercel AI SDK plugin, explaining their purpose, when to use them, and how they integrate with the plugin architecture.

## Architecture: Commands → Agents → Skills

The Vercel AI SDK plugin follows a clear architectural hierarchy:

1. **Commands** - User-invoked orchestrators (e.g., `/vercel-ai-sdk:add-ui-features`)
2. **Agents** - Implementation specialists (e.g., `vercel-ai-ui-agent`)
3. **Skills** - Reusable pattern libraries that agents invoke automatically

## All Skills

### 1. provider-config-validator

**Purpose:** Validate and debug Vercel AI SDK provider configurations

**Provides:**
- Provider setup validation scripts
- API key format verification
- Model compatibility checks
- Error diagnosis and auto-fixes
- Connection testing utilities

**Used by:** All verifier agents (vercel-ai-verifier-ts/js/py)

**Trigger keywords:** provider errors, authentication failures, API key issues, configuration debugging

**Key files:**
- `scripts/validate-provider.sh` - Comprehensive validation
- `scripts/check-model-compatibility.sh` - Model validation
- `scripts/generate-fix.sh` - Auto-fix common issues
- `templates/env-template.txt` - Environment setup
- `examples/troubleshooting-guide.md` - Complete troubleshooting reference

---

### 2. generative-ui-patterns

**Purpose:** Generative UI implementation patterns for AI SDK RSC

**Provides:**
- Server action templates for AI RSC
- Streaming component patterns
- Client-server coordination templates
- Component mapping strategies
- Dynamic UI generation patterns

**Used by:** vercel-ai-ui-agent

**Trigger keywords:** generative UI, React Server Components, AI RSC, dynamic UI generation, streaming components

**Key files:**
- `templates/server-action-pattern.tsx` - Complete server action template
- `templates/client-wrapper.tsx` - Client component wrapper
- `scripts/validate-rsc-setup.sh` - Next.js RSC validation
- `examples/chart-generator.tsx` - Dynamic chart generation example

**Best practices:**
- Always validate Next.js setup with `validate-rsc-setup.sh`
- Use server actions for security (no API keys in client)
- Implement graceful degradation with error boundaries
- Sanitize all AI-generated content

---

### 3. rag-implementation

**Purpose:** RAG (Retrieval Augmented Generation) pipeline patterns

**Provides:**
- Complete RAG pipeline templates
- Document chunking strategies (fixed, semantic, recursive)
- Vector database schemas (Pinecone, Chroma, pgvector, Weaviate)
- Retrieval patterns (semantic search, hybrid search, re-ranking)
- Embedding generation utilities

**Used by:** vercel-ai-data-agent

**Trigger keywords:** RAG, embeddings, vector database, semantic search, document chunking, knowledge retrieval

**Key files:**
- `templates/rag-pipeline.ts` - Complete RAG implementation (800+ lines)
- `templates/chunking-strategies.ts` - All chunking approaches
- `templates/retrieval-patterns.ts` - Search and re-ranking
- `templates/vector-db-schemas/` - Database-specific schemas
- `scripts/validate-rag-setup.sh` - RAG configuration validation
- `scripts/generate-embeddings.sh` - Batch embedding generation

**Best practices:**
- Start with semantic chunking (500-1000 tokens)
- Use hybrid search for better recall
- Implement re-ranking for higher accuracy
- Cache embeddings to avoid regeneration
- Monitor embedding costs (use cheaper models for prototyping)

**Supported vector databases:**
- Pinecone (fully managed, production-ready)
- Chroma (open-source, local development)
- pgvector (Postgres extension, cost-effective)
- Weaviate (advanced filtering, hybrid search)
- Qdrant (high-performance, large-scale)

---

### 4. testing-patterns

**Purpose:** Testing patterns for Vercel AI SDK applications

**Provides:**
- Mock language model providers
- Streaming response tests
- Tool calling test patterns
- Snapshot testing utilities
- Test coverage strategies

**Used by:** vercel-ai-production-agent

**Trigger keywords:** testing, mocks, test coverage, AI testing, streaming tests, tool testing

**Key files:**
- `templates/mock-provider.ts` - Complete mock provider implementations
- `templates/streaming-test.ts` - Streaming test patterns
- `templates/tool-calling-test.ts` - Tool execution tests
- `templates/snapshot-test.ts` - Snapshot testing setup
- `scripts/generate-test-suite.sh` - Test scaffold generator
- `scripts/run-coverage.sh` - Coverage analysis

**Mock provider types:**
- Basic mock (simple responses)
- Streaming mock (chunk-by-chunk streaming)
- Tool-calling mock (function calls)
- Error mock (failure scenarios)
- Configurable mock (custom behavior)
- Stateful mock (multi-turn conversations)

**Coverage goals:**
- Core functions: >90%
- Error handling: >80%
- Tool calling: 100%
- Streaming: >85%

**Supported testing frameworks:** Vitest, Jest, Node Test Runner

---

### 5. agent-workflow-patterns

**Purpose:** AI agent workflow and orchestration patterns

**Provides:**
- ReAct (Reasoning + Acting) agent templates
- Multi-agent system architectures
- Workflow orchestration patterns
- Loop control strategies
- Tool coordination patterns

**Used by:** vercel-ai-advanced-agent

**Trigger keywords:** agents, workflows, ReAct, multi-step reasoning, loop control, autonomous AI, agent orchestration

**Key files:**
- `templates/react-agent.ts` - Complete ReAct pattern (400+ lines)
- `templates/multi-agent-system.ts` - Multi-agent coordination
- `templates/workflow-orchestrator.ts` - Workflow execution
- `templates/loop-control.ts` - Iteration safeguards
- `templates/tool-coordinator.ts` - Tool orchestration
- `examples/rag-agent.ts` - Production RAG agent
- `examples/sql-agent.ts` - Natural language SQL agent

**Agent architectures:**
- ReAct agent (reasoning + acting loops)
- Multi-agent system (specialized agents)
- Workflow orchestration (pre-defined steps)
- Agentic RAG (tool-based retrieval)

**Loop control strategies:**
- Iteration limits (prevent infinite loops)
- Cost limits (prevent runaway expenses)
- Time limits (prevent long operations)
- Quality gates (ensure output quality)

**Best practices:**
- Start with simple single-tool agents
- Add complexity incrementally
- Implement comprehensive error recovery
- Monitor agent iterations and costs
- Use safeguards (rate limiting, validation)

---

## Skill Usage by Agents

### vercel-ai-ui-agent
- **Primary skill:** generative-ui-patterns
- **Also uses:** provider-config-validator (for setup validation)

### vercel-ai-data-agent
- **Primary skill:** rag-implementation
- **Also uses:** provider-config-validator (for embedding model validation)

### vercel-ai-production-agent
- **Primary skill:** testing-patterns
- **Also uses:** provider-config-validator (for CI/CD testing)

### vercel-ai-advanced-agent
- **Primary skill:** agent-workflow-patterns
- **Also uses:** rag-implementation (for agentic RAG), provider-config-validator

### vercel-ai-verifier-* agents
- **Primary skill:** provider-config-validator

---

## Why These Are Skills (Not Commands)

Each skill passes the "One-Off vs Management" test:

✅ **generative-ui-patterns** - MANAGES multiple UI patterns (RSC, streaming, dynamic generation)
✅ **rag-implementation** - MANAGES complete RAG pipeline (chunking, embedding, retrieval, generation)
✅ **testing-patterns** - MANAGES multiple testing scenarios (mocks, streaming, tools, snapshots)
✅ **agent-workflow-patterns** - MANAGES agent architectures (ReAct, multi-agent, workflows)
✅ **provider-config-validator** - MANAGES provider setup (validation, diagnosis, fixes)

They provide:
- Reusable templates that agents customize
- Executable scripts that agents invoke
- Domain knowledge packaged for agent consumption
- Multiple related operations (not one-off tasks)

---

## Progressive Disclosure Pattern

All skills follow the progressive disclosure pattern:

1. **Metadata** (name + description) → Skill discovery
2. **SKILL.md** → Core patterns and workflows
3. **Templates** → Customizable code snippets
4. **Scripts** → Validation and generation utilities
5. **Examples** → Real-world implementations

This ensures agents only load what they need, keeping context usage efficient.

---

## Validation

All skills validated using framework validation script:

```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-skill.sh <skill-path>
```

**Validation results:** All 5 skills ✅ PASSED

---

## Future Skills (Potential)

Based on plugin usage patterns, potential future skills:

- **streaming-optimization** - Advanced streaming patterns, backpressure handling
- **error-recovery-patterns** - Comprehensive error handling strategies
- **cost-optimization** - Token usage optimization, caching strategies
- **multi-modal-integration** - Image/audio/video processing patterns

---

## Contributing

When adding new skills:

1. **Verify it's a skill** (not a command) - Apply "One-Off vs Management" test
2. **Create proper structure** - SKILL.md, templates/, scripts/, examples/
3. **Write clear descriptions** - Include trigger keywords for auto-discovery
4. **Validate structure** - Use framework validation script
5. **Document usage** - Add to this overview

---

**Plugin Version:** 1.0.0
**SDK Compatibility:** Vercel AI SDK 5+
**Total Skills:** 5 (provider-config-validator, generative-ui-patterns, rag-implementation, testing-patterns, agent-workflow-patterns)

**Architectural Philosophy:** Skills provide reusable patterns that agents compose, following the progressive disclosure principle for optimal context usage.
