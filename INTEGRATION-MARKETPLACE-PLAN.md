# Integration Marketplace - Planning Document

**Created**: 2025-11-01
**Purpose**: Plan for building the integration-marketplace with programmatic workflow automation via MCP servers and APIs

---

## Overview

The **integration-marketplace** will focus on **programmatically controlling automation platforms** (N8N, Make.com, Zapier) via their MCP servers and APIs, enabling users to build complete workflows entirely from Claude Code without touching any UI.

### Key Principle
**Everything via API/MCP - No UI Required**

Users will create, configure, deploy, and manage automation workflows entirely through slash commands in Claude Code.

---

## Marketplace Structure

```
~/.claude/plugins/marketplaces/
├── dev-lifecycle-marketplace/      # Universal foundation
├── ai-tech-stack-marketplace/      # Renamed from ai-dev-marketplace
└── integration-marketplace/        # NEW - Programmatic automation
    ├── .claude-plugin/
    │   └── marketplace.json
    ├── plugins/
    │   ├── n8n/                   # Priority 1 - Best API support
    │   ├── zapier/                # Priority 2 - Good API support
    │   ├── make/                  # Priority 3 - Limited API
    │   └── integration-orchestrator/  # Orchestrates common patterns
    └── README.md
```

---

## Marketplace vs AI Tech Stack

### ai-tech-stack-marketplace
**Purpose**: Build NEW AI applications from scratch

**Use Cases**:
- Build a trading classifier from scratch
- Create a voice-enabled chatbot
- Build a RAG-powered knowledge base
- Train custom ML models

**Example Commands**:
```bash
/ml-training:init my-classifier
/nextjs-frontend:init dashboard
/fastapi-backend:add-endpoint /predict
```

### integration-marketplace
**Purpose**: Connect EXISTING applications via programmatic workflows

**Use Cases**:
- Connect Airtable → AI → Notion (via N8N)
- Email automation with LLM enrichment (via Zapier)
- Data pipelines with AI processing (via Make.com)
- Multi-system integrations without code

**Example Commands**:
```bash
/n8n:create-workflow airtable-to-notion
/n8n:add-ai-node llm-enrichment
/zapier:create-zap email-processor
```

### Cross-Marketplace Integration
When you need BOTH (connecting integrations to AI tech stack):

```bash
# Build AI infrastructure (ai-tech-stack-marketplace)
/ml-training:deploy-inference
# Returns: https://modal-app-abc.modal.run/classify

# Create workflow (integration-marketplace)
/n8n:create-workflow trade-automation
/n8n:add-node http-request url=https://modal-app-abc.modal.run/classify

# Workflow calls your custom ML model!
```

---

## Plugin Overview

### Priority 1: n8n Plugin

**Why First**:
- ✅ Self-hosted = full API control
- ✅ Can create entire workflows via API
- ✅ No UI required
- ✅ Most flexible for AI integration
- ✅ Open source, well-documented API

**Commands** (18 planned):
```bash
# Setup
/n8n:init [self-hosted|cloud]
/n8n:setup-credentials <service> <config>

# Workflow Management
/n8n:create-workflow <name>
/n8n:list-workflows
/n8n:update-workflow <id>
/n8n:delete-workflow <id>
/n8n:duplicate-workflow <id> <new-name>

# Node Management
/n8n:add-node <type> <config>
/n8n:configure-node <node-id> <settings>
/n8n:connect-nodes <from-id> <to-id>
/n8n:remove-node <node-id>

# AI Integration
/n8n:add-ai-node <type>  # Special: LLM, RAG, ML inference
/n8n:add-database-node <type>  # Supabase, PostgreSQL, MongoDB
/n8n:add-webhook <path>

# Deployment & Execution
/n8n:deploy-workflow <id>
/n8n:execute-workflow <id> [payload]
/n8n:test-workflow <id>
/n8n:monitor-workflow <id>

# Templates
/n8n:load-template <template-name>
```

**Agents** (8 planned):
- `n8n-workflow-architect` - Designs workflow structure and logic
- `n8n-api-specialist` - Handles N8N REST API calls
- `n8n-node-configurator` - Configures individual node settings
- `n8n-ai-integrator` - Integrates with ai-tech-stack plugins
- `n8n-credential-manager` - Manages API credentials securely
- `n8n-deployer` - Deploys workflows to N8N instances
- `n8n-monitor` - Monitors workflow execution and errors
- `n8n-template-builder` - Creates reusable workflow templates

**Skills** (5 planned):
- `workflow-templates/` - Pre-built workflow patterns
  - AI data enrichment
  - Multi-system sync
  - Event-driven automation
  - Scheduled tasks
- `node-configs/` - Node configuration templates
  - HTTP Request nodes
  - Database nodes
  - AI processing nodes
  - Webhook triggers
- `api-helpers/` - N8N API wrapper scripts
- `credential-templates/` - Service credential configs
- `example-workflows/` - Complete workflow examples

**MCP Integration**:
```json
{
  "mcpServers": {
    "n8n": {
      "type": "http",
      "url": "http://localhost:5678/api/v1",
      "description": "N8N workflow automation API"
    },
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp",
      "description": "Supabase for workflow data storage"
    }
  }
}
```

**Cross-Marketplace Dependencies**:
```json
{
  "name": "n8n",
  "version": "1.0.0",
  "optionalDependencies": {
    "ai-tech-stack-marketplace": [
      "ml-training",
      "supabase",
      "vercel-ai-sdk",
      "rag-pipeline",
      "fastapi-backend"
    ]
  }
}
```

---

### Priority 2: zapier Plugin

**Why Second**:
- ✅ Good API support (Platform API)
- ✅ Can create Zaps programmatically
- ✅ Extensive app ecosystem (5000+ apps)
- ⚠️ Cloud-only, no self-hosting

**Commands** (15 planned):
```bash
# Setup
/zapier:init
/zapier:authenticate

# Zap Management
/zapier:create-zap <name>
/zapier:list-zaps
/zapier:update-zap <id>
/zapier:delete-zap <id>

# Step Configuration
/zapier:add-trigger <app> <event>
/zapier:add-action <app> <action>
/zapier:configure-step <step-id> <config>
/zapier:add-filter <condition>
/zapier:add-formatter <type>

# Deployment
/zapier:enable-zap <id>
/zapier:disable-zap <id>
/zapier:test-zap <id>

# Templates
/zapier:use-template <template-id>
/zapier:create-template
```

**Agents** (6 planned):
- `zapier-zap-builder` - Creates Zaps programmatically
- `zapier-app-configurator` - Configures app connections
- `zapier-platform-specialist` - Handles Zapier Platform API
- `zapier-ai-integrator` - Integrates with AI services
- `zapier-deployer` - Deploys and enables Zaps
- `zapier-monitor` - Monitors Zap execution

**Skills** (4 planned):
- `zap-templates/` - Pre-built Zap patterns
- `app-configs/` - App connection configs
- `filter-patterns/` - Common filter logic
- `example-zaps/` - Complete Zap examples

**API Documentation**:
- Platform API: https://platform.zapier.com/reference/cli
- REST API: https://zapier.com/developer/documentation/v2/

---

### Priority 3: make Plugin

**Why Third**:
- ⚠️ Limited API for scenario creation
- ✅ Can execute scenarios via API
- ✅ Can list and manage scenarios
- ❌ Complex scenarios may require UI

**Commands** (12 planned):
```bash
# Setup
/make:init
/make:authenticate

# Scenario Management
/make:list-scenarios
/make:run-scenario <id>
/make:clone-scenario <template-id>
/make:rename-scenario <id> <name>

# Limited Creation (API constraints)
/make:create-simple-scenario <config>
/make:add-module <type> <config>

# Deployment
/make:enable-scenario <id>
/make:disable-scenario <id>
/make:test-scenario <id>

# Templates
/make:use-template <template-id>
/make:export-scenario <id>
```

**Agents** (5 planned):
- `make-scenario-builder` - Creates scenarios (limited by API)
- `make-api-specialist` - Handles Make.com API
- `make-executor` - Runs and monitors scenarios
- `make-template-manager` - Manages scenario templates
- `make-ai-integrator` - Integrates with AI services

**Skills** (3 planned):
- `scenario-templates/` - Pre-built scenario templates
- `module-configs/` - Module configuration templates
- `example-scenarios/` - Complete scenario examples

**API Documentation**:
- API Reference: https://www.make.com/en/api-documentation

**Note**: Make.com API is more limited. Focus on:
- Template-based scenarios
- Execution and monitoring
- Simple workflow creation
- May require UI for complex scenarios

---

### Priority 4: integration-orchestrator Plugin

**Purpose**: Orchestrate common integration patterns across platforms

**Commands** (10 planned):
```bash
# Pattern-Based Workflows
/integration-orchestrator:ai-data-enrichment <source> <ai-model> <destination>
/integration-orchestrator:multi-system-sync <systems[]>
/integration-orchestrator:event-processor <trigger> <actions[]>
/integration-orchestrator:scheduled-task <cron> <workflow>

# Platform Selection
/integration-orchestrator:recommend-platform <use-case>
/integration-orchestrator:compare-platforms

# Cross-Platform
/integration-orchestrator:migrate-workflow <from-platform> <to-platform>
/integration-orchestrator:duplicate-workflow <platform> <workflow-id>

# AI Integration Patterns
/integration-orchestrator:add-llm-enrichment <workflow>
/integration-orchestrator:add-vector-search <workflow>
```

**Agents** (4 planned):
- `integration-architect` - Designs cross-platform integrations
- `platform-selector` - Recommends best platform for use case
- `workflow-migrator` - Migrates workflows between platforms
- `ai-integration-specialist` - Adds AI to any workflow

**Skills** (3 planned):
- `integration-patterns/` - Common integration patterns
- `platform-comparisons/` - Platform selection guides
- `ai-enrichment-templates/` - AI integration templates

---

## API & MCP Server Requirements

### N8N
**API Type**: REST API
**Authentication**: API Key
**Base URL**: `http://localhost:5678/api/v1` (self-hosted) or cloud URL
**Documentation**: https://docs.n8n.io/api/

**Key Endpoints**:
- `GET /workflows` - List workflows
- `POST /workflows` - Create workflow
- `PUT /workflows/:id` - Update workflow
- `DELETE /workflows/:id` - Delete workflow
- `POST /workflows/:id/execute` - Execute workflow
- `GET /credentials` - List credentials
- `POST /credentials` - Create credentials

**MCP Server Status**:
- ⚠️ Need to check if exists
- 🔧 May need to build custom MCP wrapper

### Zapier
**API Type**: Platform API (REST)
**Authentication**: OAuth 2.0
**Base URL**: `https://api.zapier.com/v1/`
**Documentation**: https://platform.zapier.com/reference/cli

**Key Endpoints**:
- `GET /zaps` - List Zaps
- `POST /zaps` - Create Zap
- `PUT /zaps/:id` - Update Zap
- `DELETE /zaps/:id` - Delete Zap
- `POST /zaps/:id/enable` - Enable Zap
- `POST /zaps/:id/test` - Test Zap

**MCP Server Status**:
- ⚠️ Need to check if exists
- 🔧 May need to build custom MCP wrapper

### Make.com
**API Type**: REST API (limited)
**Authentication**: API Key
**Base URL**: `https://api.make.com/v2/`
**Documentation**: https://www.make.com/en/api-documentation

**Key Endpoints**:
- `GET /scenarios` - List scenarios
- `POST /scenarios/:id/run` - Run scenario
- `POST /scenarios/:id/clone` - Clone scenario
- `PATCH /scenarios/:id` - Update scenario
- Limited scenario creation via API

**MCP Server Status**:
- ⚠️ Need to check if exists
- 🔧 May need to build custom MCP wrapper

---

## Example Workflows (No UI Required)

### Example 1: AI-Powered Email Automation

**Using N8N:**
```bash
# 1. Deploy AI infrastructure
/ml-training:init email-classifier
/ml-training:deploy-inference
# Returns: https://modal-app-xyz.modal.run/classify-email

# 2. Create N8N workflow
/n8n:init self-hosted
/n8n:create-workflow email-automation

# 3. Add nodes programmatically
/n8n:add-webhook /incoming-email
/n8n:add-node http-request url=https://modal-app-xyz.modal.run/classify-email
/n8n:add-node if-condition field=category value=urgent
/n8n:add-node send-email template=urgent-response
/n8n:add-node notion-create-page workspace=support

# 4. Deploy (no UI touched!)
/n8n:deploy-workflow email-automation
```

**Using Zapier:**
```bash
# 1. Create Zap
/zapier:create-zap email-ai-processor

# 2. Configure steps
/zapier:add-trigger gmail new-email
/zapier:add-action webhooks post url=https://modal-app-xyz.modal.run/classify-email
/zapier:add-filter category equals urgent
/zapier:add-action gmail send-email template=urgent-response
/zapier:add-action notion create-page workspace=support

# 3. Enable
/zapier:enable-zap email-ai-processor
```

### Example 2: Red AI Trade Classification Pipeline

**Using N8N + AI Tech Stack:**
```bash
# 1. Build AI infrastructure (ai-tech-stack-marketplace)
/ml-training:init red-ai-classifier
/ml-training:add-dataset supabase table=trade_data
/ml-training:add-peft
/ml-training:deploy-inference
# Returns: https://modal-redai.modal.run/classify

/supabase:create-schema trades predictions

# 2. Create N8N workflow (integration-marketplace)
/n8n:create-workflow red-ai-automation

# 3. Add nodes programmatically
/n8n:add-webhook /incoming-trade
/n8n:add-node supabase-insert table=trades
/n8n:add-node http-request url=https://modal-redai.modal.run/classify
/n8n:add-node supabase-insert table=predictions
/n8n:add-node if-condition field=confidence value=>0.8
/n8n:add-node http-request url=fastapi-backend/execute-trade

# 4. Deploy
/n8n:deploy-workflow red-ai-automation

# All done without touching N8N UI!
```

### Example 3: Multi-System Data Sync with AI Enrichment

**Using integration-orchestrator:**
```bash
# High-level orchestration
/integration-orchestrator:ai-data-enrichment \
  source=airtable:leads \
  ai-model=claude-3-5-sonnet \
  destination=notion:crm

# Behind the scenes, creates N8N workflow:
# 1. Fetch from Airtable
# 2. Call Vercel AI SDK for enrichment
# 3. Store in Supabase
# 4. Sync to Notion
```

---

## Cross-Marketplace Integration Patterns

### Pattern 1: AI Tech Stack → Integration Platform

**Scenario**: Deploy ML model, then create workflow to use it

```bash
# Step 1: Build AI (ai-tech-stack-marketplace)
/ml-training:init sentiment-analyzer
/ml-training:deploy-inference
# Returns: https://modal-sentiment.modal.run/analyze

# Step 2: Create workflow (integration-marketplace)
/n8n:create-workflow sentiment-pipeline
/n8n:add-ai-node custom-ml url=https://modal-sentiment.modal.run/analyze
```

### Pattern 2: Integration Platform ↔ AI Tech Stack

**Scenario**: Workflow triggers AI, AI stores in database, workflow continues

```bash
# N8N workflow that uses multiple AI tech stack components
/n8n:create-workflow complex-ai-pipeline
/n8n:add-webhook /data-ingestion
/n8n:add-node http-request url=ml-training-inference  # Custom ML
/n8n:add-node http-request url=rag-pipeline-search     # Vector search
/n8n:add-node supabase-insert table=results            # Storage
/n8n:add-node http-request url=vercel-ai-sdk-chat      # LLM processing
```

### Pattern 3: Full Orchestration

**Scenario**: Orchestrator builds everything

```bash
# Single command deploys AI + workflows
/integration-orchestrator:ai-data-enrichment \
  source=webhook \
  ai-stack=ml-training+rag-pipeline+vercel-ai-sdk \
  destination=supabase+notion

# Creates:
# 1. ML inference endpoint
# 2. RAG search endpoint
# 3. N8N workflow connecting everything
# 4. Supabase tables
# 5. Notion database
```

---

## Plugin Dependencies

### integration-marketplace plugins depend on:

**From ai-tech-stack-marketplace (optional):**
- `ml-training` - Custom ML model endpoints
- `supabase` - Database storage
- `vercel-ai-sdk` - LLM API calls
- `rag-pipeline` - Vector search
- `fastapi-backend` - Custom API endpoints
- `mem0` - Memory for workflows

**From dev-lifecycle-marketplace (required):**
- `foundation` - Environment setup
- `deployment` - Deploy workflows
- `quality` - Test workflows

**plugin.json example:**
```json
{
  "name": "n8n",
  "version": "1.0.0",
  "description": "Programmatic N8N workflow automation",
  "optionalDependencies": {
    "ai-tech-stack-marketplace": [
      "ml-training",
      "supabase",
      "vercel-ai-sdk",
      "rag-pipeline",
      "fastapi-backend"
    ]
  },
  "requiredDependencies": {
    "dev-lifecycle-marketplace": [
      "foundation"
    ]
  }
}
```

---

## Platform Comparison

| Feature | N8N | Zapier | Make.com |
|---------|-----|--------|----------|
| **Self-hosted** | ✅ Yes | ❌ No | ❌ No |
| **API - Create Workflows** | ✅ Full | ✅ Good | ⚠️ Limited |
| **API - Execute Workflows** | ✅ Yes | ✅ Yes | ✅ Yes |
| **API - Manage Credentials** | ✅ Yes | ✅ Yes | ✅ Yes |
| **MCP Server Available** | ❓ TBD | ❓ TBD | ❓ TBD |
| **Programmatic Node Config** | ✅ Full | ✅ Good | ⚠️ Limited |
| **Free Tier** | ✅ Unlimited (self-hosted) | ⚠️ Limited | ⚠️ Limited |
| **App Ecosystem** | ✅ 400+ | ✅ 5000+ | ✅ 1500+ |
| **Best For** | Complex AI workflows | Simple automations | Visual workflows |
| **Claude Code Integration** | 🌟 Best | ✅ Good | ⚠️ Moderate |

**Recommendation**: Start with **N8N** for best programmatic control.

---

## Development Roadmap

### Phase 1: N8N Plugin (Weeks 1-2)
- [ ] Research N8N API and check for existing MCP server
- [ ] Design plugin structure (commands, agents, skills)
- [ ] Build core commands (init, create-workflow, add-node)
- [ ] Build workflow-architect and api-specialist agents
- [ ] Create workflow-templates skill
- [ ] Test with simple workflow creation
- [ ] Test AI integration (call ML model from workflow)

### Phase 2: Zapier Plugin (Weeks 3-4)
- [ ] Research Zapier Platform API
- [ ] Design plugin structure
- [ ] Build core commands (create-zap, add-trigger, add-action)
- [ ] Build zap-builder and platform-specialist agents
- [ ] Create zap-templates skill
- [ ] Test with simple Zap creation
- [ ] Test AI integration

### Phase 3: Integration Orchestrator (Week 5)
- [ ] Design common integration patterns
- [ ] Build orchestrator commands
- [ ] Build integration-architect agent
- [ ] Create integration-patterns skill
- [ ] Test cross-platform workflows

### Phase 4: Make.com Plugin (Week 6)
- [ ] Research Make.com API limitations
- [ ] Design plugin structure (template-focused)
- [ ] Build core commands (list, run, clone scenarios)
- [ ] Build scenario-builder agent
- [ ] Create scenario-templates skill
- [ ] Test with template-based scenarios

### Phase 5: Documentation & Testing (Week 7)
- [ ] Complete integration-marketplace README
- [ ] Document all cross-marketplace patterns
- [ ] Build example workflows (5-10 examples)
- [ ] Test all plugins together
- [ ] Create video tutorials

### Phase 6: Advanced Features (Week 8+)
- [ ] Build custom MCP servers if needed
- [ ] Add monitoring and logging
- [ ] Create advanced AI integration patterns
- [ ] Build migration tools (Zapier → N8N, etc.)
- [ ] Community templates and sharing

---

## Success Metrics

### For N8N Plugin
- ✅ Create complete workflow without touching UI
- ✅ Add AI processing node (ML model or LLM)
- ✅ Connect to Supabase for data storage
- ✅ Deploy and execute workflow programmatically
- ✅ Monitor workflow execution
- ✅ Build 5+ template workflows

### For Integration Marketplace
- ✅ Support 3+ automation platforms (N8N, Zapier, Make)
- ✅ Enable cross-marketplace integration (AI tech stack + integrations)
- ✅ Build 10+ example workflows
- ✅ Zero UI interaction required for common patterns
- ✅ Full programmatic control via slash commands

---

## Technical Requirements

### MCP Server Development (If Needed)

If MCP servers don't exist for N8N/Zapier/Make, we'll build them:

**n8n-mcp-server** (Python/TypeScript):
```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";

const server = new Server({
  name: "n8n-mcp",
  version: "1.0.0"
});

// Tools
server.tool("create_workflow", { name: "string" }, async (args) => {
  // Call N8N API
  const response = await fetch("http://localhost:5678/api/v1/workflows", {
    method: "POST",
    body: JSON.stringify({ name: args.name })
  });
  return response.json();
});

server.tool("add_node", { workflowId: "string", nodeType: "string" }, async (args) => {
  // Call N8N API to add node
});

// Resources
server.resource("workflow://{id}", async (uri) => {
  // Fetch workflow details
});
```

**zapier-platform-mcp** (Python/TypeScript):
```python
from mcp.server import Server

server = Server("zapier-platform-mcp")

@server.tool()
async def create_zap(name: str):
    """Create a new Zap via Zapier Platform API"""
    # Call Zapier API
    pass

@server.tool()
async def add_trigger(zap_id: str, app: str, event: str):
    """Add trigger to Zap"""
    # Call Zapier API
    pass
```

---

## Questions to Research

### N8N
- [ ] Does n8n-mcp-server exist in MCP ecosystem?
- [ ] What's the best authentication method for self-hosted instances?
- [ ] Can we auto-deploy N8N via Docker for users?
- [ ] What node types are most important for AI workflows?

### Zapier
- [ ] Does zapier-platform-mcp exist?
- [ ] What are Platform API rate limits?
- [ ] Can we use Zapier CLI programmatically?
- [ ] How to handle OAuth for user apps?

### Make.com
- [ ] What exactly can be created via API?
- [ ] Are there undocumented API endpoints?
- [ ] Can we reverse-engineer scenario creation?
- [ ] Template marketplace integration possible?

### General
- [ ] How to handle credential storage securely?
- [ ] Best practices for workflow versioning?
- [ ] Error handling and retry strategies?
- [ ] Workflow testing and validation?

---

## Security Considerations

### Credential Management
- **N8N**: Store API keys in `.env` files (not committed)
- **Zapier**: OAuth tokens stored securely
- **Make.com**: API keys encrypted at rest
- **MCP servers**: Credentials passed securely via MCP protocol

### Best Practices
- ✅ Never commit API keys or tokens
- ✅ Use environment variables for all credentials
- ✅ Encrypt sensitive data in transit
- ✅ Validate all webhook payloads
- ✅ Rate limit API calls
- ✅ Log all workflow executions for audit

---

## Future Enhancements

### Additional Platforms
- **Integrately** - If API becomes available
- **Pipedream** - Open source, programmatic workflows
- **Tray.io** - Enterprise automation
- **Workato** - Enterprise iPaaS

### Advanced Features
- **Workflow AI Designer** - LLM designs workflows from natural language
- **Cross-platform Migration** - Move workflows between platforms
- **Workflow Marketplace** - Share and discover templates
- **AI-Powered Debugging** - AI suggests fixes for failed workflows
- **Cost Optimization** - AI recommends cheapest platform for use case

### Integration Patterns
- **Event-Driven Architectures** - Webhook → AI → Multiple destinations
- **ETL Pipelines** - Extract, AI transform, Load
- **Real-time Sync** - Bi-directional data sync with AI enrichment
- **Scheduled AI Tasks** - Cron-based AI processing
- **Multi-stage AI Pipelines** - RAG → LLM → ML → Storage

---

## References

### N8N
- **Docs**: https://docs.n8n.io/
- **API**: https://docs.n8n.io/api/
- **GitHub**: https://github.com/n8n-io/n8n
- **Community**: https://community.n8n.io/

### Zapier
- **Platform API**: https://platform.zapier.com/reference/cli
- **REST API**: https://zapier.com/developer/documentation/v2/
- **App Directory**: https://zapier.com/apps

### Make.com
- **API Docs**: https://www.make.com/en/api-documentation
- **Help Center**: https://www.make.com/en/help
- **Templates**: https://www.make.com/en/templates

### MCP Protocol
- **Spec**: https://modelcontextprotocol.io/
- **SDK**: https://github.com/modelcontextprotocol/sdk
- **Examples**: https://github.com/modelcontextprotocol/servers

---

## Notes

- This document will evolve as we research APIs and build plugins
- Priority order may change based on API capabilities discovered
- MCP server development may be required if none exist
- Cross-marketplace integration is a key differentiator
- Focus on "zero UI" experience - everything via Claude Code

---

**Last Updated**: 2025-11-01
**Status**: Planning Phase
**Next Action**: Research N8N API and check for existing MCP servers
