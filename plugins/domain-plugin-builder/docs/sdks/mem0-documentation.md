# Mem0 AI Memory Layer - Complete Documentation

> **Universal, Self-improving memory layer for LLM applications**
> 
> Mem0 provides persistent, personalized memory for AI agents and applications across conversations and sessions.

---

## 🎯 Overview

Mem0 is a memory layer that enables AI applications to remember user preferences, conversation history, and contextual information across sessions. Instead of treating every interaction as isolated, Mem0 allows your AI to build on previous conversations and adapt to individual users over time.

**Version:** v1.0.0 (Latest)
**GitHub:** https://github.com/mem0ai/mem0
**Dashboard:** https://app.mem0.ai
**Discord:** https://mem0.dev/DiD

---

## 📦 Deployment Options

### 1. Mem0 Platform (Managed)
**Production-ready in minutes with managed infrastructure**

- **Overview:** https://docs.mem0.ai/platform/overview
- **Platform vs Open Source:** https://docs.mem0.ai/platform/platform-vs-oss
- **Quickstart Guide:** https://docs.mem0.ai/platform/quickstart
- **Features Overview:** https://docs.mem0.ai/platform/features/platform-overview
- **FAQs:** https://docs.mem0.ai/platform/faqs
- **Advanced Memory Operations:** https://docs.mem0.ai/platform/advanced-memory-operations

**Platform Features:**
- Sub-50ms latency
- Automatic scaling & high availability
- SOC 2 Type II certified, GDPR compliant
- Graph memory, webhooks, multimodal support
- No vector DB setup required

### 2. Mem0 Open Source (Self-Hosted)
**Full control over infrastructure and data**

- **Overview:** https://docs.mem0.ai/open-source/overview
- **Python SDK Quickstart:** https://docs.mem0.ai/open-source/python-quickstart
- **Node SDK Quickstart:** https://docs.mem0.ai/open-source/node-quickstart
- **Configuration:** https://docs.mem0.ai/open-source/configuration

**Self-Hosting Features:**
- **Async Memory:** https://docs.mem0.ai/open-source/features/async-memory
- **OpenAI Compatibility:** https://docs.mem0.ai/open-source/features/openai_compatibility
- **Custom Fact Extraction:** https://docs.mem0.ai/open-source/features/custom-fact-extraction-prompt
- **Custom Update Memory:** https://docs.mem0.ai/open-source/features/custom-update-memory-prompt
- **Multimodal Support:** https://docs.mem0.ai/open-source/features/multimodal-support
- **REST API Server:** https://docs.mem0.ai/open-source/features/rest-api
- **Enhanced Metadata Filtering:** https://docs.mem0.ai/open-source/features/metadata-filtering
- **Reranking:** https://docs.mem0.ai/open-source/features/reranking
- **Reranker-Enhanced Search:** https://docs.mem0.ai/open-source/features/reranker-search

**Graph Memory:**
- **Overview:** https://docs.mem0.ai/open-source/graph_memory/overview
- **Features:** https://docs.mem0.ai/open-source/graph_memory/features

### 3. OpenMemory
**Workspace-based memory for teams**

- **Overview:** https://docs.mem0.ai/openmemory/overview

---

## 🧠 Core Concepts

### Memory Types
**Documentation:** https://docs.mem0.ai/core-concepts/memory-types

- **User Memories** - Personal preferences and history
- **Agent Memories** - Agent-specific context
- **Session Memories** - Temporary conversation context

### Memory Operations

#### Add Memory
- **Documentation:** https://docs.mem0.ai/core-concepts/memory-operations/add
- Store new memories from conversations and interactions

#### Search Memory
- **Documentation:** https://docs.mem0.ai/core-concepts/memory-operations/search
- Semantic search with filters and relevance scoring

#### Update Memory
- **Documentation:** https://docs.mem0.ai/core-concepts/memory-operations/update
- Modify existing memory content and metadata

#### Delete Memory
- **Documentation:** https://docs.mem0.ai/core-concepts/memory-operations/delete
- Remove specific memories or batch operations

---

## 🔌 API Reference

**Base URL:** `https://api.mem0.ai/v1/`
**Authentication:** Token-based (Bearer token in Authorization header)

### API Overview
- **Main Documentation:** https://docs.mem0.ai/api-reference
- **Organizations & Projects:** https://docs.mem0.ai/api-reference/organizations-projects
- **Get API Keys:** https://app.mem0.ai/dashboard/api-keys

### Core Memory APIs

#### Memory Operations
- **POST Add Memories:** https://docs.mem0.ai/api-reference/memory/add-memories
- **POST Search Memories:** https://docs.mem0.ai/api-reference/memory/search-memories
- **POST Get Memories:** https://docs.mem0.ai/api-reference/memory/get-memories
- **PUT Update Memory:** https://docs.mem0.ai/api-reference/memory/update-memory
- **DEL Delete Memory:** https://docs.mem0.ai/api-reference/memory/delete-memory

#### Advanced Memory APIs
- **GET Memory History:** https://docs.mem0.ai/api-reference/memory/history-memory
- **GET Get Memory:** https://docs.mem0.ai/api-reference/memory/get-memory
- **PUT Batch Update Memories:** https://docs.mem0.ai/api-reference/memory/batch-update
- **DEL Batch Delete Memories:** https://docs.mem0.ai/api-reference/memory/batch-delete
- **DEL Delete Memories:** https://docs.mem0.ai/api-reference/memory/delete-memories
- **POST Create Memory Export:** https://docs.mem0.ai/api-reference/memory/create-memory-export
- **POST Get Memory Export:** https://docs.mem0.ai/api-reference/memory/get-memory-export
- **POST Feedback:** https://docs.mem0.ai/api-reference/memory/feedback

### Entities APIs
- **GET Get Users:** https://docs.mem0.ai/api-reference/entities/get-users
- **DEL Delete User:** https://docs.mem0.ai/api-reference/entities/delete-user

### Organizations APIs
- **POST Create Organization:** https://docs.mem0.ai/api-reference/organization/create-org
- **GET Get Organizations:** https://docs.mem0.ai/api-reference/organization/get-orgs
- **GET Get Organization:** https://docs.mem0.ai/api-reference/organization/get-org
- **GET Get Members:** https://docs.mem0.ai/api-reference/organization/get-org-members
- **POST Add Member:** https://docs.mem0.ai/api-reference/organization/add-org-member
- **DEL Delete Organization:** https://docs.mem0.ai/api-reference/organization/delete-org

### Project APIs
- **POST Create Project:** https://docs.mem0.ai/api-reference/project/create-project
- **GET Get Projects:** https://docs.mem0.ai/api-reference/project/get-projects
- **GET Get Project:** https://docs.mem0.ai/api-reference/project/get-project
- **GET Get Members:** https://docs.mem0.ai/api-reference/project/get-project-members
- **POST Add Member:** https://docs.mem0.ai/api-reference/project/add-project-member
- **DEL Delete Project:** https://docs.mem0.ai/api-reference/project/delete-project

### Webhook APIs
- **POST Create Webhook:** https://docs.mem0.ai/api-reference/webhook/create-webhook
- **GET Get Webhook:** https://docs.mem0.ai/api-reference/webhook/get-webhook
- **PUT Update Webhook:** https://docs.mem0.ai/api-reference/webhook/update-webhook
- **DEL Delete Webhook:** https://docs.mem0.ai/api-reference/webhook/delete-webhook

---

## 🔗 Integrations

**Overview:** https://docs.mem0.ai/integrations

### Agent Frameworks
- **LangChain:** https://docs.mem0.ai/integrations/langchain
- **LangGraph:** https://docs.mem0.ai/integrations/langgraph
- **LlamaIndex:** https://docs.mem0.ai/integrations/llama-index
- **CrewAI:** https://docs.mem0.ai/integrations/crewai
- **AutoGen:** https://docs.mem0.ai/integrations/autogen
- **Agno:** https://docs.mem0.ai/integrations/agno
- **OpenAI Agents SDK:** https://docs.mem0.ai/integrations/openai-agents-sdk
- **Google ADK:** https://docs.mem0.ai/integrations/google-ai-adk
- **Mastra:** https://docs.mem0.ai/integrations/mastra
- **Vercel AI SDK:** https://docs.mem0.ai/integrations/vercel-ai-sdk

### Voice & Real-time
- **Livekit:** https://docs.mem0.ai/integrations/livekit
- **Pipecat:** https://docs.mem0.ai/integrations/pipecat
- **ElevenLabs:** https://docs.mem0.ai/integrations/elevenlabs

### Cloud & Infrastructure
- **AWS Bedrock:** https://docs.mem0.ai/integrations/aws-bedrock

### Developer Tools
- **Dify:** https://docs.mem0.ai/integrations/dify
- **Flowise:** https://docs.mem0.ai/integrations/flowise
- **LangChain Tools:** https://docs.mem0.ai/integrations/langchain-tools
- **AgentOps:** https://docs.mem0.ai/integrations/agentops
- **Keywords AI:** https://docs.mem0.ai/integrations/keywords
- **Raycast Extension:** https://docs.mem0.ai/integrations/raycast

---

## 🛠️ Configuration

### Component Configuration
**Base Documentation:** https://docs.mem0.ai/open-source/configuration

### LLMs (Large Language Models)
Configure your preferred LLM provider:
- OpenAI (gpt-4.1-nano-2025-04-14)
- Anthropic Claude
- Azure OpenAI
- Google Gemini
- AWS Bedrock
- Ollama (local)
- Together AI
- Groq
- Litellm

### Vector Databases
Choose your vector store:
- Qdrant (default local)
- Pinecone
- Chroma
- Milvus
- PostgreSQL with pgvector
- Azure AI Search
- Elasticsearch

### Embedding Models
Select embedding provider:
- OpenAI (text-embedding-3-small - default)
- Azure OpenAI
- Hugging Face
- Ollama
- Google AI (Gemini)
- Vertex AI
- AWS Bedrock

### Rerankers
Improve search relevance:
- Cohere Reranker
- Jina Reranker
- Cross-Encoder models

---

## 📚 Cookbooks & Examples

**Overview:** https://docs.mem0.ai/examples

### Getting Started Examples
- **Mem0 Demo:** https://docs.mem0.ai/examples/mem0-demo
- **AI Companion in Node.js:** https://docs.mem0.ai/examples/ai_companion_js
- **Mem0 with Ollama:** https://docs.mem0.ai/examples/mem0-with-ollama
- **Personalized AI Tutor:** https://docs.mem0.ai/examples/personal-ai-tutor

### Production Use Cases
- **Customer Support AI Agent:** https://docs.mem0.ai/examples/customer-support-agent
- **Personal AI Travel Assistant:** https://docs.mem0.ai/examples/personal-travel-assistant
- **Email Processing with Mem0:** https://docs.mem0.ai/examples/email_processing
- **Memory-Guided Content Writing:** https://docs.mem0.ai/examples/memory-guided-content-writing
- **Personalized Deep Research:** https://docs.mem0.ai/examples/personalized-deep-research

### Framework Integrations
- **LlamaIndex ReAct Agent:** https://docs.mem0.ai/examples/llama-index-mem0
- **LlamaIndex Multi-Agent Learning System:** https://docs.mem0.ai/examples/llamaindex-multiagent-learning-system
- **Personalized Search with Tavily:** https://docs.mem0.ai/examples/personalized-search-tavily-mem0
- **Mem0 as an Agentic Tool:** https://docs.mem0.ai/examples/mem0-agentic-tool
- **Mem0 with Mastra:** https://docs.mem0.ai/examples/mem0-mastra
- **Eliza OS Character:** https://docs.mem0.ai/examples/eliza_os

### Specialized Features
- **Multimodal Demo with Mem0:** https://docs.mem0.ai/examples/multimodal-demo
- **Mem0 with OpenAI Agents SDK for Voice:** https://docs.mem0.ai/examples/mem0-openai-voice-demo
- **Healthcare Assistant with Mem0 and Google ADK:** https://docs.mem0.ai/examples/mem0-google-adk-healthcare-assistant
- **Multi-User Collaboration with Mem0:** https://docs.mem0.ai/examples/collaborative-task-agent

### Extensions & Tools
- **Chrome Extension:** https://docs.mem0.ai/examples/chrome-extension
- **YouTube Assistant Extension:** https://docs.mem0.ai/examples/youtube-assistant
- **OpenAI Inbuilt Tools:** https://docs.mem0.ai/examples/openai-inbuilt-tools

### Cloud & Infrastructure
- **AWS Bedrock Example:** https://docs.mem0.ai/examples/aws_example
- **AWS Neptune Analytics:** https://docs.mem0.ai/examples/aws_neptune_analytics_hybrid_store

---

## 🔄 Migration & Updates

### Migration Guide
- **Migrating from v0.x to v1.0.0:** https://docs.mem0.ai/migration/v0-to-v1
- **Breaking Changes in v1.0.0:** https://docs.mem0.ai/migration/breaking-changes
- **API Reference Changes:** https://docs.mem0.ai/migration/api-changes

### Release Notes
- **Changelog:** https://docs.mem0.ai/changelog

**v1.0.0 Highlights:**
- Rerankers support
- Async by default
- Azure support
- Enhanced metadata filtering
- Improved graph memory

---

## 🧩 MCP (Model Context Protocol) Integration

### Mem0 MCP Server
**GitHub:** https://github.com/mem0ai/mem0-mcp
**Context7 Library:** /mem0ai/mem0-mcp

The Mem0 MCP server enables Model Context Protocol integration for managing coding preferences and persistent memory across AI development sessions.

**Features:**
- Persistent memory storage for AI agents
- User preference management
- Session-based context retention
- Integration with Claude Desktop and other MCP clients

**Related MCP Implementations:**
- **Template Implementation:** https://github.com/coleam00/mcp-mem0
  - Persistent memory across sessions
  - User preference tracking
  - Context-aware interactions

### Installation & Setup

```bash
# Install Mem0 MCP Server
npm install @mem0ai/mcp-server

# Or clone from GitHub
git clone https://github.com/mem0ai/mem0-mcp
cd mem0-mcp
npm install
```

### MCP Configuration

Add to your MCP settings (e.g., Claude Desktop config):

```json
{
  "mcpServers": {
    "mem0": {
      "command": "node",
      "args": ["/path/to/mem0-mcp/build/index.js"],
      "env": {
        "MEM0_API_KEY": "your-mem0-api-key"
      }
    }
  }
}
```

---

## 📦 Installation

### Python SDK

```bash
# Install Mem0 for Python
pip install mem0ai

# With specific extras
pip install mem0ai[graph]  # For graph memory
pip install mem0ai[aws]     # For AWS integration
```

### Node.js SDK

```bash
# Install Mem0 for Node.js
npm install mem0ai

# For OSS version
npm i mem0ai
```

---

## 🚀 Quick Start

### Python Example

```python
from mem0 import Memory

# Initialize Memory
memory = Memory()

# Add memories from conversation
messages = [
    {"role": "user", "content": "I love sci-fi movies"},
    {"role": "assistant", "content": "I'll remember that!"}
]
memory.add(messages, user_id="john_doe")

# Search memories
results = memory.search("movie preferences", user_id="john_doe")
print(results)

# Get all memories
all_memories = memory.get_all(user_id="john_doe")
```

### Node.js Example

```javascript
import { Memory } from 'mem0ai/oss';

const memory = new Memory();

// Add memories
const messages = [
    {role: "user", content: "I love sci-fi movies"},
    {role: "assistant", content: "I'll remember that!"}
];
await memory.add(messages, { userId: "john_doe" });

// Search memories
const results = await memory.search("movie preferences", { userId: "john_doe" });
console.log(results);
```

### REST API Example

```bash
# Add memory via REST API
curl -X POST https://api.mem0.ai/v1/memories/ \
  -H "Authorization: Token YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "I love sci-fi movies"}
    ],
    "user_id": "john_doe"
  }'

# Search memories
curl -X POST https://api.mem0.ai/v1/memories/search/ \
  -H "Authorization: Token YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "movie preferences",
    "user_id": "john_doe"
  }'
```

---

## 🏗️ Configuration Examples

### With Custom Components (Python)

```python
from mem0 import Memory
from mem0.configs.base import MemoryConfig

config = MemoryConfig(
    vector_store={
        "provider": "qdrant",
        "config": {
            "host": "localhost",
            "port": 6333,
            "collection_name": "my_memories"
        }
    },
    llm={
        "provider": "openai",
        "config": {
            "model": "gpt-4.1-nano-2025-04-14",
            "api_key": "sk-..."
        }
    },
    embedder={
        "provider": "openai",
        "config": {
            "model": "text-embedding-3-small"
        }
    }
)

memory = Memory(config)
```

### With Graph Memory (Python)

```python
config = MemoryConfig(
    graph_store={
        "provider": "neo4j",
        "config": {
            "url": "bolt://localhost:7687",
            "username": "neo4j",
            "password": "password"
        }
    }
)

memory = Memory(config)

# Add with relationship extraction
result = memory.add(
    "John works at OpenAI and is friends with Sarah",
    user_id="user123"
)
print(result["relations"])  # Graph relationships
```

---

## 🎯 Use Cases

### Personal Assistant
Remember user preferences and past requests across sessions.

### Customer Support
Recall previous customer issues and interaction history.

### Educational AI
Track student progress, learning style, and adapt lessons.

### Healthcare Assistant
Remember patient symptoms, medications, and medical history.

### Content Creation
Maintain consistent voice and context across writing sessions.

### Travel Planning
Recall travel preferences, past trips, and booking patterns.

---

## 💡 Key Features

### Platform Features (Managed)
- ✅ **Fast Setup** - 4 lines of code to production
- ✅ **Production Scale** - Automatic scaling, high availability
- ✅ **Advanced Features** - Graph memory, webhooks, multimodal
- ✅ **Enterprise Ready** - SOC 2 Type II, GDPR compliant

### Open Source Features
- ✅ **Full Control** - Host on your infrastructure
- ✅ **Customization** - Modify implementation, extend functionality
- ✅ **Local Development** - Perfect for testing and air-gapped environments
- ✅ **No Vendor Lock-in** - Own your data, choose your stack

### Common Features (Both)
- ✅ **Semantic Search** - Find relevant memories by meaning
- ✅ **Multi-Entity Support** - Users, agents, sessions
- ✅ **Metadata Filtering** - Advanced query capabilities
- ✅ **History Tracking** - View memory evolution over time
- ✅ **Batch Operations** - Efficient bulk updates/deletes
- ✅ **Export/Import** - Data portability

---

## 📖 Additional Resources

### Community & Support
- **Development Guide:** https://docs.mem0.ai/contributing/development
- **Documentation Guide:** https://docs.mem0.ai/contributing/documentation
- **Discord Community:** https://mem0.dev/DiD
- **GitHub Repository:** https://github.com/mem0ai/mem0
- **Twitter/X:** https://x.com/mem0ai
- **LinkedIn:** https://www.linkedin.com/company/mem0/

### Context7 Documentation
- **Main Library:** /mem0ai/mem0 (1954 code snippets, 8.8 trust score)
- **Website Docs:** /websites/mem0_ai (1473 code snippets, 7.5 trust score)
- **MCP Server:** /mem0ai/mem0-mcp (23 code snippets, 8.8 trust score)

---

## 🎓 Learning Path

### Beginner
1. Start with **Mem0 Demo** to understand basic operations
2. Follow **Platform Quickstart** (Platform) or **Python/Node Quickstart** (OSS)
3. Explore **Memory Types** and core operations
4. Try simple examples like **AI Companion**

### Intermediate
1. Integrate with your framework (**LangChain**, **Vercel AI SDK**, etc.)
2. Implement **Customer Support** or **AI Tutor** use case
3. Configure custom **LLMs**, **Vector DBs**, and **Embedders**
4. Explore **Metadata Filtering** and **Search** optimization

### Advanced
1. Set up **Graph Memory** for relationship tracking
2. Implement **Webhooks** for real-time notifications
3. Use **Multimodal Support** for images and text
4. Build **Multi-Agent Systems** with shared memory
5. Deploy with **AWS Bedrock** or **Azure** infrastructure

---

## 🔐 Security & Compliance

- **SOC 2 Type II Certified** (Platform)
- **GDPR Compliant** (Platform)
- **API Key Authentication**
- **Project-based Access Control**
- **Organization & Team Management**
- **Audit Logs & History Tracking**

---

## 📊 Comparison: Platform vs Open Source

| Feature | Platform | Open Source |
|---------|----------|-------------|
| Setup Time | Minutes | Hours |
| Infrastructure | Managed | Self-managed |
| Scaling | Automatic | Manual |
| Cost | Usage-based | Infrastructure cost |
| Graph Memory | ✅ Yes | ✅ Yes |
| Webhooks | ✅ Yes | ❌ No |
| Multimodal | ✅ Yes | ✅ Yes |
| Custom Components | Limited | Full control |
| Data Ownership | Mem0-hosted | Self-hosted |
| Support | Enterprise | Community |

**Choose Platform if:** You need production-ready, managed infrastructure with minimal setup.

**Choose Open Source if:** You need full control, custom deployment, or air-gapped environments.

---

## 📝 Notes for Plugin Development

### Recommended Plugin Structure

```
plugins/mem0/
├── README.md
├── agents/
│   ├── memory-architect.md      # Design memory schemas
│   ├── integration-specialist.md # Framework integrations
│   └── memory-optimizer.md       # Performance tuning
├── commands/
│   ├── mem0-init.md             # Initialize Mem0 in project
│   ├── mem0-config.md           # Configure components
│   ├── mem0-integrate.md        # Add to framework
│   └── mem0-deploy.md           # Deploy strategies
├── skills/
│   ├── memory-patterns/         # Common memory patterns
│   ├── search-optimization/     # Search best practices
│   ├── graph-modeling/          # Graph memory design
│   └── multimodal-memory/       # Image + text memory
└── docs/
    ├── QUICKSTART.md
    ├── ARCHITECTURE.md
    └── BEST-PRACTICES.md
```

### Integration Points with Vercel AI SDK

Mem0 can be integrated with Vercel AI SDK for:
- **Persistent chat history** across sessions
- **User preference memory** for personalized responses
- **Multi-agent coordination** with shared memory
- **RAG enhancement** with semantic memory search
- **Tool calling** with memory context

---

**Last Updated:** October 25, 2025
**Documentation Version:** v1.0.0
**Maintained by:** AI Dev Marketplace Team
