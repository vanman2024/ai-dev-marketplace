# AI Dev Marketplace Agent Audit Report
Generated: November 6, 2025
Marketplace: `/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace`

## Summary Statistics
- **Total plugins analyzed**: 13
- **Total agents analyzed**: 86
- **Agents with slash commands**: 86 (100.0%)
- **Agents with MCP servers**: 23 (26.7%)
- **Agents with skills**: 0 (0.0%)
- **Agents with tools section**: 86 (100.0%)

## By Plugin Analysis

### Claude Agent Sdk
- **Agents**: 4
- **Slash command coverage**: 4/4 (100%)
- **MCP server coverage**: 0/4 (0%)
- **Skills integration**: 0/4 (0%)

**Agents**:
- **claude-agent-features** (238 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **claude-agent-setup** (292 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **claude-agent-verifier-py** (165 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **claude-agent-verifier-ts** (172 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**

### Elevenlabs
- **Agents**: 6
- **Slash command coverage**: 6/6 (100%)
- **MCP server coverage**: 0/6 (0%)
- **Skills integration**: 0/6 (0%)

**Agents**:
- **elevenlabs-agents-builder** (118 lines)
- **elevenlabs-production-agent** (119 lines)
- **elevenlabs-setup** (190 lines)
- **elevenlabs-stt-integrator** (112 lines)
- **elevenlabs-tts-integrator** (110 lines)
- **elevenlabs-voice-manager** (110 lines)

### Fastapi Backend
- **Agents**: 4
- **Slash command coverage**: 4/4 (100%)
- **MCP server coverage**: 0/4 (0%)
- **Skills integration**: 0/4 (0%)

**Agents**:
- **database-architect-agent** (226 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **deployment-architect-agent** (218 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **endpoint-generator-agent** (234 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **fastapi-setup-agent** (273 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**

### Mem0
- **Agents**: 3
- **Slash command coverage**: 3/3 (100%)
- **MCP server coverage**: 0/3 (0%)
- **Skills integration**: 0/3 (0%)

**Agents**:
- **mem0-integrator** (216 lines)
  - Slash commands: localhost, supabase
- **mem0-memory-architect** (205 lines)
- **mem0-verifier** (224 lines)

### Ml Training
- **Agents**: 16
- **Slash command coverage**: 16/16 (100%)
- **MCP server coverage**: 2/16 (12%)
- **Skills integration**: 0/16 (0%)

**Agents**:
- **cost-optimizer** (220 lines)
- **data-engineer** (207 lines)
  - MCP servers: mcp__supabase
- **data-specialist** (198 lines)
- **distributed-training-specialist** (258 lines)
- **google-bigquery-ml-specialist** (232 lines)
- **google-vertex-specialist** (246 lines)
- **inference-deployer** (235 lines)
- **integration-specialist** (237 lines)
  - MCP servers: mcp__supabase
- **lambda-specialist** (206 lines)
- **ml-architect** (250 lines)
  - Slash commands: LoRA
- **ml-tester** (248 lines)
- **modal-specialist** (211 lines)
- **peft-specialist** (203 lines)
- **runpod-specialist** (210 lines)
- **training-architect** (213 lines)
- **training-monitor** (255 lines)

### Nextjs Frontend
- **Agents**: 8
- **Slash command coverage**: 8/8 (100%)
- **MCP server coverage**: 3/8 (38%)
- **Skills integration**: 0/8 (0%)

**Agents**:
- **ai-sdk-integration-agent** (213 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **component-builder-agent** (285 lines)
  - MCP servers: mcp__plugin_nextjs
- **component-builder-agent** (296 lines)
  - Slash commands: nextjs-frontend, ui
  - MCP servers: mcp__plugin_nextjs
- **design-enforcer-agent** (263 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **nextjs-setup-agent** (240 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **page-generator-agent** (293 lines)
  - MCP servers: mcp__plugin_nextjs
- **supabase-integration-agent** (204 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **ui-search-agent** (217 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**

### Openrouter
- **Agents**: 4
- **Slash command coverage**: 4/4 (100%)
- **MCP server coverage**: 0/4 (0%)
- **Skills integration**: 0/4 (0%)

**Agents**:
- **openrouter-langchain-agent** (200 lines)
- **openrouter-routing-agent** (217 lines)
- **openrouter-setup-agent** (192 lines)
  - Slash commands: JavaScript
- **openrouter-vercel-integration-agent** (204 lines)

### Payments
- **Agents**: 4
- **Slash command coverage**: 4/4 (100%)
- **MCP server coverage**: 4/4 (100%)
- **Skills integration**: 0/4 (0%)

**Agents**:
- **payments-architect** (212 lines)
  - Slash commands: payments
  - MCP servers: mcp__github, mcp__plugin_supabase_supabase
- **stripe-integration-agent** (240 lines)
  - Slash commands: payments
  - MCP servers: mcp__github, mcp__plugin_supabase_supabase
- **subscription-manager-agent** (192 lines)
  - Slash commands: downgrades, payments
  - MCP servers: mcp__github, mcp__plugin_supabase_supabase
- **webhook-handler-agent** (270 lines)
  - Slash commands: payments
  - MCP servers: mcp__github, mcp__plugin_supabase_supabase, mcp__plugin_supabase_supabase__apply_migration, mcp__plugin_supabase_supabase__execute_sql, mcp__plugin_supabase_supabase__list_tables

### Plugin Docs Loader
- **Agents**: 1
- **Slash command coverage**: 1/1 (100%)
- **MCP server coverage**: 0/1 (0%)
- **Skills integration**: 0/1 (0%)

**Agents**:
- **doc-loader-agent** (425 lines)
  - Slash commands: Core, Reference

### Rag Pipeline
- **Agents**: 10
- **Slash command coverage**: 10/10 (100%)
- **MCP server coverage**: 2/10 (20%)
- **Skills integration**: 0/10 (0%)

**Agents**:
- **document-processor** (217 lines)
  - MCP servers: mcp__playwright
- **embedding-specialist** (199 lines)
- **langchain-specialist** (233 lines)
  - Slash commands: LCEL
- **llamaindex-specialist** (211 lines)
- **rag-architect** (264 lines)
  - Slash commands: development
- **rag-deployment-agent** (208 lines)
- **rag-tester** (234 lines)
- **retrieval-optimizer** (240 lines)
- **vector-db-engineer** (229 lines)
  - MCP servers: mcp__supabase
- **web-scraper-agent** (213 lines)

### Supabase
- **Agents**: 14
- **Slash command coverage**: 14/14 (100%)
- **MCP server coverage**: 10/14 (71%)
- **Skills integration**: 0/14 (0%)

**Agents**:
- **supabase-ai-specialist** (356 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **supabase-architect** (350 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **supabase-code-reviewer** (163 lines)
  - MCP servers: mcp__plugin_supabase_supabase
- **supabase-database-executor** (215 lines)
  - MCP servers: mcp__plugin_supabase_supabase
- **supabase-migration-applier** (182 lines)
  - MCP servers: mcp__plugin_supabase_supabase
- **supabase-performance-analyzer** (170 lines)
  - MCP servers: mcp__plugin_supabase_supabase
- **supabase-project-manager** (167 lines)
  - MCP servers: mcp__plugin_supabase_supabase
- **supabase-realtime-builder** (177 lines)
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **supabase-schema-validator** (146 lines)
  - MCP servers: mcp__plugin_supabase_supabase
- **supabase-security-auditor** (146 lines)
  - MCP servers: mcp__plugin_supabase_supabase
- **supabase-security-specialist** (386 lines)
  - Slash commands: localhost
  - **⚠️ Domain-specific plugin but no MCP servers documented**
- **supabase-tester** (149 lines)
  - MCP servers: mcp__plugin_supabase_supabase
- **supabase-ui-generator** (167 lines)
  - MCP servers: mcp__plugin_supabase_supabase
- **supabase-validator** (169 lines)
  - MCP servers: mcp__plugin_supabase_supabase

### Vercel Ai Sdk
- **Agents**: 7
- **Slash command coverage**: 7/7 (100%)
- **MCP server coverage**: 0/7 (0%)
- **Skills integration**: 0/7 (0%)

**Agents**:
- **vercel-ai-advanced-agent** (268 lines)
- **vercel-ai-data-agent** (231 lines)
- **vercel-ai-production-agent** (251 lines)
- **vercel-ai-ui-agent** (220 lines)
- **vercel-ai-verifier-js** (130 lines)
- **vercel-ai-verifier-py** (130 lines)
- **vercel-ai-verifier-ts** (175 lines)

### Website Builder
- **Agents**: 5
- **Slash command coverage**: 5/5 (100%)
- **MCP server coverage**: 2/5 (40%)
- **Skills integration**: 0/5 (0%)

**Agents**:
- **website-ai-generator** (281 lines)
  - Slash commands: website-builder
  - MCP servers: mcp__content
- **website-architect** (241 lines)
  - Slash commands: planning
- **website-content** (291 lines)
  - Slash commands: website-builder
  - MCP servers: mcp__content
- **website-setup** (298 lines)
  - Slash commands: website-builder
- **website-verifier** (229 lines)
  - Slash commands: quality

## Issues by Severity

### Critical Issues
- fastapi-backend/database-architect-agent: No MCP servers (expected No direct MCP but needs documentation)
- fastapi-backend/deployment-architect-agent: No MCP servers (expected No direct MCP but needs documentation)
- fastapi-backend/endpoint-generator-agent: No MCP servers (expected No direct MCP but needs documentation)
- fastapi-backend/fastapi-setup-agent: No MCP servers (expected No direct MCP but needs documentation)
- nextjs-frontend/ai-sdk-integration-agent: No MCP servers (expected mcp__plugin_nextjs)
- nextjs-frontend/design-enforcer-agent: No MCP servers (expected mcp__plugin_nextjs)
- nextjs-frontend/nextjs-setup-agent: No MCP servers (expected mcp__plugin_nextjs)
- nextjs-frontend/supabase-integration-agent: No MCP servers (expected mcp__plugin_nextjs)
- nextjs-frontend/ui-search-agent: No MCP servers (expected mcp__plugin_nextjs)
- supabase/supabase-ai-specialist: No MCP servers (expected mcp__plugin_supabase)
- supabase/supabase-architect: No MCP servers (expected mcp__plugin_supabase)
- supabase/supabase-realtime-builder: No MCP servers (expected mcp__plugin_supabase)
- supabase/supabase-security-specialist: No MCP servers (expected mcp__plugin_supabase)

**Total Critical**: 13

### Medium Priority Issues
- fastapi-backend/database-architect-agent: No skills referenced for domain-specific agent
- fastapi-backend/deployment-architect-agent: No skills referenced for domain-specific agent
- fastapi-backend/endpoint-generator-agent: No skills referenced for domain-specific agent
- fastapi-backend/fastapi-setup-agent: No skills referenced for domain-specific agent
- nextjs-frontend/ai-sdk-integration-agent: No skills referenced for domain-specific agent
- nextjs-frontend/component-builder-agent: No skills referenced for domain-specific agent
- nextjs-frontend/component-builder-agent: No skills referenced for domain-specific agent
- nextjs-frontend/design-enforcer-agent: No skills referenced for domain-specific agent
- nextjs-frontend/nextjs-setup-agent: No skills referenced for domain-specific agent
- nextjs-frontend/page-generator-agent: No skills referenced for domain-specific agent
- nextjs-frontend/supabase-integration-agent: No skills referenced for domain-specific agent
- nextjs-frontend/ui-search-agent: No skills referenced for domain-specific agent
- supabase/supabase-ai-specialist: No skills referenced for domain-specific agent
- supabase/supabase-architect: No skills referenced for domain-specific agent
- supabase/supabase-code-reviewer: No skills referenced for domain-specific agent
- supabase/supabase-database-executor: No skills referenced for domain-specific agent
- supabase/supabase-migration-applier: No skills referenced for domain-specific agent
- supabase/supabase-performance-analyzer: No skills referenced for domain-specific agent
- supabase/supabase-project-manager: No skills referenced for domain-specific agent
- supabase/supabase-realtime-builder: No skills referenced for domain-specific agent
- ... and 6 more

**Total Medium**: 26

## Recommendations

### Critical Fixes Required
1. **Supabase Plugin**: Add `mcp__plugin_supabase` server documentation to all agents
2. **NextJS Frontend Plugin**: Add `mcp__plugin_nextjs` server documentation to component-related agents
3. **Claude Agent SDK**: Add MCP server documentation for integration agents

### High Priority Improvements
1. **Skills Integration**: 0 agents currently reference skills - add 'Available Skills' section to domain-specific agents
2. **Command Documentation**: Standardize 'Available Tools & Resources' section across all agents
3. **Script/Template Usage**: Document available scripts and templates from plugin skills directory

### Medium Priority Improvements
1. **Cross-Plugin Commands**: Ensure agents document commands from related plugins
2. **MCP Server Coverage**: Increase from 26.7% to target 60%+ for SDK/integration agents
3. **Skills Coverage**: Implement skills reference pattern for at least 30% of agents

## Plugin Coverage Table

| Plugin | Agents | Commands | MCP | Skills | Status |
|--------|--------|----------|-----|--------|--------|
| payments | 4 | 100% | 100% | 0% | 🟢 Good |
| supabase | 14 | 100% | 71% | 0% | 🟢 Good |
| website-builder | 5 | 100% | 40% | 0% | 🟡 Incomplete |
| nextjs-frontend | 8 | 100% | 37% | 0% | 🟡 Incomplete |
| rag-pipeline | 10 | 100% | 20% | 0% | 🟡 Incomplete |
| ml-training | 16 | 100% | 12% | 0% | 🟡 Incomplete |
| claude-agent-sdk | 4 | 100% | 0% | 0% | ⚠️ Needs MCP/Skills |
| elevenlabs | 6 | 100% | 0% | 0% | ⚠️ Needs MCP/Skills |
| fastapi-backend | 4 | 100% | 0% | 0% | ⚠️ Needs MCP/Skills |
| mem0 | 3 | 100% | 0% | 0% | ⚠️ Needs MCP/Skills |
| openrouter | 4 | 100% | 0% | 0% | ⚠️ Needs MCP/Skills |
| plugin-docs-loader | 1 | 100% | 0% | 0% | ⚠️ Needs MCP/Skills |
| vercel-ai-sdk | 7 | 100% | 0% | 0% | ⚠️ Needs MCP/Skills |

## Legend
- **Commands**: Agents documenting slash commands (100% = all agents have command refs)
- **MCP**: Agents documenting MCP servers (should be 100% for domain-specific plugins)
- **Skills**: Agents referencing plugin skills (currently 0% across all agents)
- **Status**: Overall agent integration quality

