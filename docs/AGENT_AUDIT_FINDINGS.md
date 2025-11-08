# AI Dev Marketplace Agent Audit - Detailed Findings

## Executive Summary

A comprehensive audit of 86 agents across 13 plugins in the AI Dev Marketplace reveals significant gaps in MCP server documentation and complete absence of skills integration.

**Key Metrics**:
- Total Agents Analyzed: 86
- Agents with Slash Commands: 86 (100%) ✓
- Agents with MCP Servers: 23 (26.7%) ✗ CRITICAL GAP
- Agents with Skills References: 0 (0%) ✗ CRITICAL GAP
- Agents with Available Tools Section: 86 (100%) ✓

---

## Critical Issues

### Issue #1: Zero Skills Integration (0% Coverage)
**Severity**: CRITICAL
**Impact**: Agents don't document available automation scripts, templates, and domain knowledge

No agents reference skills, even though plugins have well-developed skill directories with:
- Scripts for automation
- Templates for common configurations
- Domain-specific patterns and examples

**Example**: Supabase plugin has 4 skills (rls-policy-generator, realtime-builder, schema-validator, vector-search-setup) but no agent mentions them.

**Fix Pattern**:
```markdown
## Available Skills

This agent has access to the following skills from the [plugin] plugin:
- **skill-name**: Description

To use a skill:
!{skill skill-name}
```

---

### Issue #2: Incomplete MCP Server Documentation (26.7% Coverage)
**Severity**: CRITICAL
**Impact**: Agents can't leverage integrated tools and resources

**By Plugin**:
| Plugin | Agents | MCP Coverage | Status |
|--------|--------|--------------|--------|
| Payments | 4 | 100% | ✓ Best Practice |
| Supabase | 14 | 71% | 🟡 Needs 4 fixes |
| Website Builder | 5 | 40% | 🟡 Incomplete |
| NextJS Frontend | 8 | 37% | 🟡 Incomplete |
| RAG Pipeline | 10 | 20% | 🟡 Incomplete |
| ML Training | 16 | 12% | 🟡 Incomplete |
| Claude Agent SDK | 4 | 0% | 🔴 CRITICAL |
| FastAPI Backend | 4 | 0% | 🔴 CRITICAL |
| Vercel AI SDK | 7 | 0% | 🔴 CRITICAL |
| Elevenlabs | 6 | 0% | 🔴 CRITICAL |
| OpenRouter | 4 | 0% | 🔴 CRITICAL |
| Mem0 | 3 | 0% | 🔴 CRITICAL |
| Plugin Docs Loader | 1 | 0% | 🔴 CRITICAL |

**Total**: 23/86 agents have MCP documentation

---

## Plugin-Specific Critical Issues

### 1. FastAPI Backend (4 agents, 0% MCP)
**CRITICAL**: Domain-specific backend framework with ZERO MCP documentation

#### Missing MCP Servers
- **database-architect-agent.md** (226 lines)
  - Should document: mcp__supabase for database operations
  - Currently: No MCP, but documents 37 slash commands
  
- **deployment-architect-agent.md** (218 lines)
  - Should document: Infrastructure/deployment MCP servers
  - Currently: No MCP, 36 slash commands
  
- **endpoint-generator-agent.md** (234 lines)
  - Should document: Schema validation MCP servers
  - Currently: No MCP, 42 slash commands
  
- **fastapi-setup-agent.md** (273 lines)
  - Should document: Configuration/setup MCP servers
  - Currently: No MCP, 28 slash commands

**Fix**: Add mcp__supabase documentation to all agents, especially database-architect

---

### 2. Claude Agent SDK (4 agents, 0% MCP)
**CRITICAL**: Core SDK agents with ZERO MCP documentation

#### Missing MCP Servers
- **claude-agent-features.md** (238 lines)
  - Should document: How to use MCP servers with Agent SDK
  - Currently: No MCP documentation
  
- **claude-agent-setup.md** (292 lines)
  - Should document: SDK configuration with MCP servers
  - Currently: No MCP documentation
  
- **claude-agent-verifier-py.md** (165 lines)
  - Should document: Python SDK + MCP verification patterns
  - Currently: No MCP documentation
  
- **claude-agent-verifier-ts.md** (172 lines)
  - Should document: TypeScript SDK + MCP verification patterns
  - Currently: No MCP documentation

**Fix**: Add "Available MCP Servers" section documenting SDK integration patterns

---

### 3. Supabase (14 agents, 71% MCP) - 4 Critical Gaps
**Status**: Best coverage but 4 critical gaps

#### Agents WITHOUT MCP (Should Have It)

1. **supabase-ai-specialist.md** (356 lines - LARGEST AGENT)
   - Focus: Embeddings, vectors, RAG
   - **CRITICAL**: Needs mcp__plugin_supabase for database operations
   - Current: Extensive documentation but no MCP reference

2. **supabase-architect.md** (350 lines)
   - Focus: Schema design, migrations
   - **CRITICAL**: Needs mcp__plugin_supabase for applying migrations
   - Current: No MCP documentation

3. **supabase-realtime-builder.md** (177 lines)
   - Focus: Real-time features
   - **CRITICAL**: Needs mcp__plugin_supabase for subscription testing
   - Current: No MCP documentation

4. **supabase-security-specialist.md** (386 lines - LARGEST OVERALL)
   - Focus: Security audits, RLS policies
   - **CRITICAL**: Needs mcp__plugin_supabase for policy validation
   - Current: No MCP documentation

**Fix**: Add mcp__plugin_supabase to all 4 agents

---

### 4. NextJS Frontend (8 agents, 37% MCP)
**Status**: Only 3/8 agents have MCP documentation

#### Agents WITH MCP ✓ (3 agents)
- component-builder-agent.md (both versions): mcp__plugin_nextjs ✓
- page-generator-agent.md: mcp__plugin_nextjs ✓

#### Agents WITHOUT MCP ✗ (5 agents)
1. **ai-sdk-integration-agent.md** (213 lines)
   - Should document: mcp__plugin_nextjs for component templates
   - Current: No MCP
   
2. **design-enforcer-agent.md** (263 lines)
   - Should document: mcp__plugin_nextjs for design system access
   - Current: No MCP
   
3. **nextjs-setup-agent.md** (240 lines)
   - Should document: mcp__plugin_nextjs for setup templates
   - Current: No MCP
   
4. **supabase-integration-agent.md** (204 lines)
   - Should document: mcp__plugin_supabase (not nextjs)
   - Current: No MCP
   
5. **ui-search-agent.md** (217 lines)
   - Should document: mcp__plugin_nextjs for component library
   - Current: No MCP

**Fix**: Add mcp__plugin_nextjs to 4 agents, mcp__plugin_supabase to 1 agent

---

### 5. Vercel AI SDK (7 agents, 0% MCP)
**CRITICAL**: Integration SDK with ZERO MCP documentation

All 7 agents should document integration with:
- mcp__plugin_supabase (for data operations)
- mcp__openrouter (for model routing)
- mcp__plugin_nextjs (for frontend integration)

**Fix**: Add "Available MCP Servers" section to all agents

---

### 6. Elevenlabs (6 agents, 0% MCP)
**CRITICAL**: Audio SDK with ZERO MCP documentation

All agents should document:
- Integration endpoints
- Voice management APIs
- Real-time streaming patterns

**Fix**: Add MCP server documentation

---

### 7. OpenRouter (4 agents, 0% MCP)
**CRITICAL**: Model routing with ZERO MCP documentation

All agents should document:
- Model availability endpoints
- Routing decision-making
- Cost tracking integration

**Fix**: Add MCP server documentation

---

### 8. Mem0 (3 agents, 0% MCP)
**CRITICAL**: Memory layer with ZERO MCP documentation

All agents should document:
- Storage backend integration
- Vector database connections
- Memory retrieval patterns

**Fix**: Add MCP server documentation

---

### 9. RAG Pipeline (10 agents, 20% MCP)
**Status**: Only 2/10 agents have MCP

Agents WITH MCP:
- document-processor.md: mcp__playwright ✓
- vector-db-engineer.md: mcp__supabase ✓

Agents NEEDING MCP:
- embedding-specialist.md: Should use vector DB MCP
- langchain-specialist.md: Should use LangChain integration MCP
- llamaindex-specialist.md: Should use LLamaIndex MCP
- rag-architect.md: Should use mcp__supabase
- rag-deployment-agent.md: Should use deployment MCP
- rag-tester.md: Should use test framework MCP
- retrieval-optimizer.md: Should use mcp__supabase
- web-scraper-agent.md: Should use mcp__playwright

**Fix**: Add domain-specific MCP servers to 8 agents

---

### 10. ML Training (16 agents, 12% MCP)
**Status**: Only 2/16 agents have MCP

Agents WITH MCP:
- data-engineer.md: mcp__supabase ✓
- integration-specialist.md: mcp__supabase ✓

Agents NEEDING MCP: 14 others

**Fix**: Add domain-specific MCP servers (training platforms, cloud providers)

---

## Skills Integration Gap

### Current State: ZERO AGENTS REFERENCE SKILLS

Despite plugins having well-organized skills directories:

**Claude Agent SDK Skills**:
- fastmcp-integration
- sdk-config-validator

**NextJS Frontend Skills**:
- component-library-integrator
- design-system-enforcer
- performance-optimizer
- setup-automated-deployment

**FastAPI Backend Skills**:
- database-architect-skill
- deployment-architect-skill
- endpoint-generator-skill

**Supabase Skills**:
- rls-policy-generator
- realtime-builder
- schema-validator
- vector-search-setup

**No agents mention these skills in their prompts.**

### Example Fix

**Before** (current supabase-architect.md):
```markdown
## Available Tools & Resources
[Extensive slash commands listed]
```

**After** (proposed):
```markdown
## Available Skills

This agent has access to the following skills from the supabase plugin:
- **schema-validator**: Validates database schema against best practices
- **rls-policy-generator**: Generates Row-Level Security (RLS) policies
- **vector-search-setup**: Sets up pgvector for semantic search

To use a skill:
!{skill schema-validator}

## Available Tools & Resources
[Slash commands listed]
```

---

## Recommendations Prioritized by Impact

### PHASE 1: Critical Fixes (HIGH IMPACT, QUICK)

1. **Add MCP to 13 Critical Agents** (30 minutes work)
   - FastAPI Backend: All 4 agents
   - Claude Agent SDK: All 4 agents
   - Supabase: 4 agents (ai-specialist, architect, realtime-builder, security-specialist)
   - NextJS Frontend: 1 agent (supabase-integration)

2. **Implement Skills Sections** (1-2 hours work)
   - Add "Available Skills" section template to all 86 agents
   - Reference 2-4 domain-appropriate skills in each
   - Create consistent skill invocation pattern

### PHASE 2: Comprehensive Coverage (MEDIUM IMPACT, MODERATE TIME)

3. **Add MCP to NextJS Frontend** (3 agents)
   - ai-sdk-integration-agent
   - design-enforcer-agent
   - nextjs-setup-agent

4. **Add MCP to Vercel AI SDK** (7 agents)
   - Document integration patterns with other MCP servers
   - Show cross-plugin communication

5. **Add MCP to RAG Pipeline** (8 agents)
   - Document vector DB, LLM, and deployment MCP servers

### PHASE 3: Complete Coverage (LOW-MEDIUM IMPACT, HIGH TIME)

6. **Add MCP to Remaining Plugins** (Elevenlabs, OpenRouter, Mem0)
   - Smaller plugins, but still important for completeness

7. **Create MCP Integration Guide**
   - Document patterns for MCP server usage in agents
   - Create templates for common integration scenarios

---

## Best Practices Found (Model for Others)

### Payments Plugin (100% MCP Coverage) ✓
All 4 agents properly document:
- Stripe integration (mcp__github, mcp__plugin_supabase_supabase)
- Webhook patterns
- Multiple MCP server usage

**Pattern to Copy**:
```markdown
## Available Tools & Resources

This agent has access to the following MCP servers:
- **mcp__github**: Repository and workflow integration
- **mcp__plugin_supabase_supabase**: Database operations and migrations

To use these servers:
[Usage documentation]
```

### Supabase Plugin (71% MCP Coverage) ✓ Mostly Good
10 of 14 agents have MCP documentation.
Clear pattern of which agents use which servers.

---

## Metrics & Goals

### Current State (Baseline)
| Metric | Value | Target |
|--------|-------|--------|
| MCP Coverage | 26.7% | 80%+ |
| Skills Coverage | 0% | 50%+ |
| Command Coverage | 100% | 100% ✓ |

### 30-Day Goals
- MCP Coverage: → 60%+
- Skills Coverage: → 30%+

### 60-Day Goals
- MCP Coverage: → 85%+
- Skills Coverage: → 70%+

---

## Implementation Priority Matrix

| Plugin | Priority | MCP Agents | Skills Agents | Effort |
|--------|----------|-----------|----------------|--------|
| FastAPI Backend | CRITICAL | 4 | 4 | 1h |
| Claude Agent SDK | CRITICAL | 4 | 4 | 1h |
| Supabase | CRITICAL | 4 | 14 | 2h |
| NextJS Frontend | HIGH | 5 | 8 | 2h |
| Vercel AI SDK | HIGH | 7 | 7 | 1.5h |
| RAG Pipeline | HIGH | 8 | 10 | 2h |
| Elevenlabs | MEDIUM | 6 | 6 | 1.5h |
| OpenRouter | MEDIUM | 4 | 4 | 1h |
| Mem0 | MEDIUM | 3 | 3 | 1h |
| ML Training | MEDIUM | 14 | 16 | 2h |
| Website Builder | LOW | 3 | 5 | 1h |
| Plugin Docs Loader | LOW | 1 | 1 | 0.5h |

**Total Effort**: ~17 hours across 12 plugins

---

## File Locations for Fixes

All agent files are located in:
```
/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/[PLUGIN_NAME]/agents/
```

Quick reference for critical agents:
- `/plugins/fastapi-backend/agents/*.md` (4 agents)
- `/plugins/claude-agent-sdk/agents/*.md` (4 agents)
- `/plugins/supabase/agents/` (4 agents need fixes)
- `/plugins/nextjs-frontend/agents/` (5 agents need fixes)

---

## Appendix: Issue Checklist

### Critical Issues (13 agents)
- [ ] fastapi-backend/database-architect-agent: Add mcp__supabase
- [ ] fastapi-backend/deployment-architect-agent: Add MCP docs
- [ ] fastapi-backend/endpoint-generator-agent: Add MCP docs
- [ ] fastapi-backend/fastapi-setup-agent: Add MCP docs
- [ ] claude-agent-sdk/claude-agent-features: Add MCP patterns
- [ ] claude-agent-sdk/claude-agent-setup: Add MCP docs
- [ ] claude-agent-sdk/claude-agent-verifier-py: Add MCP docs
- [ ] claude-agent-sdk/claude-agent-verifier-ts: Add MCP docs
- [ ] supabase/supabase-ai-specialist: Add mcp__plugin_supabase
- [ ] supabase/supabase-architect: Add mcp__plugin_supabase
- [ ] supabase/supabase-realtime-builder: Add mcp__plugin_supabase
- [ ] supabase/supabase-security-specialist: Add mcp__plugin_supabase
- [ ] nextjs-frontend/supabase-integration-agent: Add mcp__plugin_supabase

### High Priority Issues (15 agents - NextJS, Vercel, RAG)
- [ ] nextjs-frontend/ai-sdk-integration-agent: Add mcp__plugin_nextjs
- [ ] nextjs-frontend/design-enforcer-agent: Add mcp__plugin_nextjs
- [ ] nextjs-frontend/nextjs-setup-agent: Add mcp__plugin_nextjs
- [ ] nextjs-frontend/ui-search-agent: Add mcp__plugin_nextjs
- [ ] vercel-ai-sdk/* (7 agents): Add integration MCP docs
- [ ] rag-pipeline/* (8 agents): Add domain MCP docs

### Global Issues (All 86 agents)
- [ ] Add "Available Skills" section to all agents
- [ ] Create consistent skill invocation documentation
- [ ] Document available scripts and templates

