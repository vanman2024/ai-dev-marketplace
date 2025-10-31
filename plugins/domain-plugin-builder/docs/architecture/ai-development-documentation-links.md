# AI Development Documentation Links
*Comprehensive collection of up-to-date documentation for building AI applications*

Generated on: December 26, 2024

> **📝 Note**: For Claude Agent SDK documentation, see the dedicated [Claude Agent SDK Documentation](./claude-agent-sdk-documentation.md) file.
> 
> **📝 Note**: For comprehensive Mem0 documentation including MCP integration, see the dedicated [Mem0 Documentation](./mem0-documentation.md) file.

---

## 🏗️ Architectural Decision Guide

When building AI applications with this tech stack, understanding when to use which tool is critical for success.

### Memory Solutions: Claude Memory Tool vs Mem0

#### Claude Memory Tool (API Feature)
**Type:** File-based tool calls (client-side implementation)  
**Best For:** Task progress tracking and workflow persistence

**✅ Use When:**
- Tracking multi-step task progress across sessions
- Storing structured project data (specs, requirements, decisions)
- Long-running workflows that may be interrupted
- Need file-like organization (/memories/project_specs.xml)
- Building agents that resume work after context window resets
- Working with Claude API or Agent SDK directly

**Key Characteristics:**
- **Storage:** You implement (filesystem, database, cloud, encrypted)
- **Access Pattern:** Explicit file reads/writes via tool calls
- **Structure:** Files and directories
- **Integration:** Beta feature requiring `context-management-2025-06-27` header
- **Semantic Search:** ❌ No (file path-based only)

**Example Use Case:**
```python
# Claude creates memory files to track refactoring progress
/memories/
  ├── refactoring_progress.xml  # What's been done
  ├── pending_changes.xml        # What's next
  └── decisions.xml              # Architectural decisions
```

#### Mem0 (Dedicated Memory Service)
**Type:** Semantic memory layer with vector search  
**Best For:** User personalization and knowledge persistence

**✅ Use When:**
- Learning user preferences over time
- Personalizing responses based on conversation history
- Building customer support agents that remember users
- Creating AI tutors that adapt to learning styles
- Cross-conversation knowledge accumulation
- Need semantic search ("What did user say about preferences?")

**Key Characteristics:**
- **Storage:** Managed Platform OR self-hosted with vector DB
- **Access Pattern:** Automatic semantic retrieval
- **Structure:** Memories with metadata and embeddings
- **Integration:** Python/Node SDK or REST API
- **Semantic Search:** ✅ Yes (similarity-based retrieval)

**Example Use Case:**
```python
from mem0 import Memory
memory = Memory()

# Automatically stores and retrieves user preferences
memory.add("I love sci-fi movies", user_id="john")
results = memory.search("movie preferences", user_id="john")
# Returns: "User loves sci-fi movies"
```

#### 🎯 Decision Matrix

| Need | Claude Memory Tool | Mem0 |
|------|-------------------|------|
| Track task progress | ✅ Perfect | ❌ Overkill |
| Store structured specs | ✅ Perfect | ❌ Wrong tool |
| Learn user preferences | ❌ Manual | ✅ Perfect |
| Semantic search | ❌ Not supported | ✅ Built-in |
| Resume interrupted work | ✅ Designed for this | ❌ Wrong use case |
| Personalize responses | ❌ Manual lookup | ✅ Automatic |
| Cross-session context | ✅ Via files | ✅ Via semantic memory |

#### 💡 Can You Use Both? YES!

**Recommended Pattern:**
```python
# Mem0 for user personalization
from mem0 import Memory
user_memory = Memory()
user_prefs = user_memory.search("preferences", user_id="john")

# Claude Memory Tool for task tracking
response = client.messages.create(
    model="claude-sonnet-4-5"
    messages=[{
        "role": "user"
        "content": f"User context: {user_prefs}\n\nTask: Build dashboard"
    }]
    tools=[{"type": "memory_20250818", "name": "memory"}],  # For progress
    betas=["context-management-2025-06-27"]
)
```

### When to Use Each Tech in the Stack

#### Vercel AI SDK
**Use For:** Frontend-focused AI applications
- ✅ React/Next.js chatbots with streaming
- ✅ Real-time UI updates during generation
- ✅ Framework integrations (Svelte, Vue, React Native)
- ✅ Rapid prototyping with hooks (useChat, useCompletion)

#### Claude Agent SDK
**Use For:** Backend agentic workflows
- ✅ Building autonomous agents with tools
- ✅ Complex multi-step reasoning tasks
- ✅ Agent Skills for specialized capabilities
- ✅ Subagents for domain-specific work

#### Firecrawl
**Use For:** Web data extraction
- ✅ Scraping documentation for RAG
- ✅ Lead enrichment and data collection
- ✅ SEO analysis and monitoring
- ✅ Deep web research for agents

#### Context7
**Use For:** Real-time library documentation
- ✅ Getting latest SDK documentation
- ✅ Resolving library versions and APIs
- ✅ Building code generation tools
- ✅ Keeping agents updated on frameworks

---

## 🤖 Vercel AI SDK - Complete Documentation

### Main Resources
- **Official Website**: https://ai-sdk.dev/
- **GitHub Repository**: https://github.com/vercel/ai
- **GitHub Discussions**: https://github.com/vercel/ai/discussions
- **API Reference**: https://ai-sdk.dev/docs/reference
- **Playground**: https://ai-sdk.dev/playground

### Core Documentation
- **Introduction**: https://ai-sdk.dev/docs/introduction
- **Getting Started**: https://ai-sdk.dev/docs/getting-started
- **Foundations Overview**: https://ai-sdk.dev/docs/foundations/overview
- **Providers and Models**: https://ai-sdk.dev/docs/foundations/providers-and-models
- **Prompts**: https://ai-sdk.dev/docs/foundations/prompts
- **Tools**: https://ai-sdk.dev/docs/foundations/tools
- **Streaming**: https://ai-sdk.dev/docs/foundations/streaming

### Framework-Specific Guides
- **Next.js App Router**: https://ai-sdk.dev/docs/getting-started/nextjs-app-router
- **Next.js Pages Router**: https://ai-sdk.dev/docs/getting-started/nextjs-pages-router
- **Svelte**: https://ai-sdk.dev/docs/getting-started/svelte
- **Vue.js (Nuxt)**: https://ai-sdk.dev/docs/getting-started/nuxt
- **Node.js**: https://ai-sdk.dev/docs/getting-started/nodejs
- **Expo**: https://ai-sdk.dev/docs/getting-started/expo

### AI SDK Core
- **Overview**: https://ai-sdk.dev/docs/ai-sdk-core/overview
- **Generating Text**: https://ai-sdk.dev/docs/ai-sdk-core/generating-text
- **Generating Structured Data**: https://ai-sdk.dev/docs/ai-sdk-core/generating-structured-data
- **Tool Calling**: https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling
- **Model Context Protocol (MCP) Tools**: https://ai-sdk.dev/docs/ai-sdk-core/mcp-tools
- **Prompt Engineering**: https://ai-sdk.dev/docs/ai-sdk-core/prompt-engineering
- **Settings**: https://ai-sdk.dev/docs/ai-sdk-core/settings
- **Embeddings**: https://ai-sdk.dev/docs/ai-sdk-core/embeddings
- **Image Generation**: https://ai-sdk.dev/docs/ai-sdk-core/image-generation
- **Transcription**: https://ai-sdk.dev/docs/ai-sdk-core/transcription
- **Speech**: https://ai-sdk.dev/docs/ai-sdk-core/speech
- **Language Model Middleware**: https://ai-sdk.dev/docs/ai-sdk-core/middleware
- **Provider & Model Management**: https://ai-sdk.dev/docs/ai-sdk-core/provider-management
- **Error Handling**: https://ai-sdk.dev/docs/ai-sdk-core/error-handling
- **Testing**: https://ai-sdk.dev/docs/ai-sdk-core/testing
- **Telemetry**: https://ai-sdk.dev/docs/ai-sdk-core/telemetry

### AI SDK UI
- **Overview**: https://ai-sdk.dev/docs/ai-sdk-ui/overview
- **Chatbot**: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot
- **Chatbot Message Persistence**: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-message-persistence
- **Chatbot Resume Streams**: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-resume-streams
- **Chatbot Tool Usage**: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-tool-usage
- **Generative User Interfaces**: https://ai-sdk.dev/docs/ai-sdk-ui/generative-user-interfaces
- **Completion**: https://ai-sdk.dev/docs/ai-sdk-ui/completion
- **Object Generation**: https://ai-sdk.dev/docs/ai-sdk-ui/object-generation
- **Streaming Custom Data**: https://ai-sdk.dev/docs/ai-sdk-ui/streaming-data
- **Error Handling**: https://ai-sdk.dev/docs/ai-sdk-ui/error-handling
- **Transport**: https://ai-sdk.dev/docs/ai-sdk-ui/transport
- **Reading UIMessage Streams**: https://ai-sdk.dev/docs/ai-sdk-ui/reading-ui-message-streams
- **Message Metadata**: https://ai-sdk.dev/docs/ai-sdk-ui/message-metadata
- **Stream Protocols**: https://ai-sdk.dev/docs/ai-sdk-ui/stream-protocol

### AI SDK RSC
- **AI SDK RSC**: https://ai-sdk.dev/docs/ai-sdk-rsc

### Advanced Features
- **Advanced**: https://ai-sdk.dev/docs/advanced
- **Why Streaming**: https://ai-sdk.dev/docs/advanced/why-streaming

### Agents
- **Agents Overview**: https://ai-sdk.dev/docs/agents/overview
- **Building Agents**: https://ai-sdk.dev/docs/agents/building-agents
- **Workflow Patterns**: https://ai-sdk.dev/docs/agents/workflows
- **Loop Control**: https://ai-sdk.dev/docs/agents/loop-control

### References
- **AI SDK Core Reference**: https://ai-sdk.dev/docs/reference/ai-sdk-core
- **AI SDK UI Reference**: https://ai-sdk.dev/docs/reference/ai-sdk-ui
- **AI SDK RSC Reference**: https://ai-sdk.dev/docs/reference/ai-sdk-rsc
- **Stream Helpers Reference**: https://ai-sdk.dev/docs/reference/stream-helpers
- **AI SDK Errors Reference**: https://ai-sdk.dev/docs/reference/ai-sdk-errors

### Migration & Troubleshooting
- **Migration Guides**: https://ai-sdk.dev/docs/migration-guides
- **Troubleshooting**: https://ai-sdk.dev/docs/troubleshooting

### Cookbook & Examples
- **Cookbook**: https://ai-sdk.dev/cookbook
- **Guides**: https://ai-sdk.dev/cookbook/guides
- **RAG Agent**: https://ai-sdk.dev/cookbook/guides/rag-chatbot
- **SQL Agent**: https://ai-sdk.dev/cookbook/guides/natural-language-postgres
- **Computer Use Agent**: https://ai-sdk.dev/cookbook/guides/computer-use
- **Slackbot Agent**: https://ai-sdk.dev/cookbook/guides/slackbot
- **Multi-Modal Agent**: https://ai-sdk.dev/cookbook/guides/multi-modal-chatbot

### Provider Documentation
- **Providers Overview**: https://ai-sdk.dev/providers
- **xAI Grok**: https://ai-sdk.dev/providers/ai-sdk-providers/xai
- **OpenAI**: https://ai-sdk.dev/providers/ai-sdk-providers/openai
- **Azure**: https://ai-sdk.dev/providers/ai-sdk-providers/azure
- **Anthropic**: https://ai-sdk.dev/providers/ai-sdk-providers/anthropic
- **Amazon Bedrock**: https://ai-sdk.dev/providers/ai-sdk-providers/amazon-bedrock
- **Groq**: https://ai-sdk.dev/providers/ai-sdk-providers/groq
- **Google Generative AI**: https://ai-sdk.dev/providers/ai-sdk-providers/google-generative-ai
- **Google Vertex AI**: https://ai-sdk.dev/providers/ai-sdk-providers/google-vertex
- **Mistral**: https://ai-sdk.dev/providers/ai-sdk-providers/mistral
- **DeepSeek**: https://ai-sdk.dev/providers/ai-sdk-providers/deepseek
- **Cohere**: https://ai-sdk.dev/providers/ai-sdk-providers/cohere
- **Fireworks**: https://ai-sdk.dev/providers/ai-sdk-providers/fireworks

### Templates & Starter Kits
- **Templates**: https://vercel.com/templates?type=ai
- **Chatbot Starter**: https://vercel.com/templates/next.js/nextjs-ai-chatbot
- **Internal Knowledge Base (RAG)**: https://vercel.com/templates/next.js/ai-sdk-internal-knowledge-base
- **Multi-Modal Chat**: https://vercel.com/templates/next.js/multi-modal-chatbot
- **Semantic Image Search**: https://vercel.com/templates/next.js/semantic-image-search
- **Natural Language PostgreSQL**: https://vercel.com/templates/next.js/natural-language-postgres

### Special Resources
- **LLMs.txt (for AI Assistants)**: https://ai-sdk.dev/llms.txt
- **Showcase**: https://ai-sdk.dev/showcase

---

## 🔥 Firecrawl - Web Scraping & Data Extraction

### Main Resources
- **Official Website**: https://firecrawl.dev
- **Documentation**: https://docs.firecrawl.dev/introduction
- **GitHub Repository**: https://github.com/firecrawl/firecrawl
- **API Keys**: https://www.firecrawl.dev/app/api-keys
- **Playground**: https://firecrawl.dev/playground
- **Status Page**: https://firecrawl.betteruptime.com
- **Support**: mailto:help@firecrawl.com

### Core Documentation
- **Quickstart**: https://docs.firecrawl.dev/introduction
- **API Reference**: https://docs.firecrawl.dev/api-reference/v2-introduction
- **Rate Limits**: https://docs.firecrawl.dev/rate-limits
- **Advanced Scraping Guide**: https://docs.firecrawl.dev/advanced-scraping-guide
- **Migration from v1 to v2**: https://docs.firecrawl.dev/migrate-to-v2

### Features
- **Scrape**: https://docs.firecrawl.dev/features/scrape
- **Search**: https://docs.firecrawl.dev/features/search
- **Map**: https://docs.firecrawl.dev/features/map
- **Crawl**: https://docs.firecrawl.dev/features/crawl
- **Extract**: https://docs.firecrawl.dev/features/extract

### SDKs
- **SDKs Overview**: https://docs.firecrawl.dev/sdks/overview
- **Python SDK**: https://docs.firecrawl.dev/sdks/python
- **Node.js SDK**: https://docs.firecrawl.dev/sdks/node
- **Go SDK**: https://docs.firecrawl.dev/sdks/go
- **Rust SDK**: https://docs.firecrawl.dev/sdks/rust

### Model Context Protocol (MCP)
- **Firecrawl MCP Server**: https://docs.firecrawl.dev/mcp-server
- **MCP GitHub Repository**: https://github.com/mendableai/firecrawl-mcp-server
- **NPM Package**: https://www.npmjs.com/package/firecrawl-mcp
- **Remote MCP URL**: https://mcp.firecrawl.dev/{FIRECRAWL_API_KEY}/v2/mcp

### API Reference
- **v2 Introduction**: https://docs.firecrawl.dev/api-reference/v2-introduction
- **Search Endpoint**: https://docs.firecrawl.dev/api-reference/endpoint/search

### Webhooks
- **Overview**: https://docs.firecrawl.dev/webhooks/overview
- **Event Types**: https://docs.firecrawl.dev/webhooks/events
- **Security**: https://docs.firecrawl.dev/webhooks/security
- **Testing & Debugging**: https://docs.firecrawl.dev/webhooks/testing

### Developer Guides
- **Full-Stack Templates**: https://docs.firecrawl.dev/developer-guides/examples

### Use Cases
- **Overview**: https://docs.firecrawl.dev/use-cases/overview
- **AI Platforms**: https://docs.firecrawl.dev/use-cases/ai-platforms
- **Lead Enrichment**: https://docs.firecrawl.dev/use-cases/lead-enrichment
- **SEO Platforms**: https://docs.firecrawl.dev/use-cases/seo-platforms
- **Deep Research**: https://docs.firecrawl.dev/use-cases/deep-research

### Contributing
- **Open Source vs Cloud**: https://docs.firecrawl.dev/contributing/open-source-or-cloud
- **Running Locally**: https://docs.firecrawl.dev/contributing/guide
- **Self-hosting**: https://docs.firecrawl.dev/contributing/self-host

### Social & Community
- **X/Twitter**: https://x.com/firecrawl_dev
- **LinkedIn**: https://www.linkedin.com/company/firecrawl
- **Discord**: https://discord.gg/gSmWdAkdwd
- **Blog**: https://firecrawl.dev/blog
- **Changelog**: https://firecrawl.dev/changelog

---

## 🎯 Context7 - Up-to-Date Documentation for AI

### Main Resources
- **Official Website**: https://context7.com
- **NPM Package**: https://www.npmjs.com/package/@upstash/context7-mcp
- **GitHub Repository**: https://github.com/upstash/context7
- **Dashboard/API Keys**: https://context7.com/dashboard
- **Smithery Page**: https://smithery.ai/server/@upstash/context7-mcp

### Installation & Setup
- **VS Code NPX Install**: https://insiders.vscode.dev/redirect?url=vscode%3Amcp%2Finstall%3F%7B%22name%22%3A%22context7%22%2C%22command%22%3A%22npx%22%2C%22args%22%3A%5B%22-y%22%2C%22%40upstash%2Fcontext7-mcp%40latest%22%5D%7D
- **Cursor Install**: https://cursor.com/en/install-mcp?name=context7&config=eyJ1cmwiOiJodHRwczovL21jcC5jb250ZXh0Ny5jb20vbWNwIn0%3D

### Documentation (Multiple Languages)
- **English (Main)**: https://github.com/upstash/context7/blob/HEAD/README.md
- **繁體中文**: https://github.com/upstash/context7/blob/HEAD/docs/README.zh-TW.md
- **简体中文**: https://github.com/upstash/context7/blob/HEAD/docs/README.zh-CN.md
- **日本語**: https://github.com/upstash/context7/blob/HEAD/docs/README.ja.md
- **한국어**: https://github.com/upstash/context7/blob/HEAD/docs/README.ko.md
- **Español**: https://github.com/upstash/context7/blob/HEAD/docs/README.es.md
- **Français**: https://github.com/upstash/context7/blob/HEAD/docs/README.fr.md
- **Português (Brasil)**: https://github.com/upstash/context7/blob/HEAD/docs/README.pt-BR.md
- **Italiano**: https://github.com/upstash/context7/blob/HEAD/docs/README.it.md
- **Bahasa Indonesia**: https://github.com/upstash/context7/blob/HEAD/docs/README.id-ID.md
- **Deutsch**: https://github.com/upstash/context7/blob/HEAD/docs/README.de.md
- **Русский**: https://github.com/upstash/context7/blob/HEAD/docs/README.ru.md
- **Українська**: https://github.com/upstash/context7/blob/HEAD/docs/README.uk.md
- **Türkçe**: https://github.com/upstash/context7/blob/HEAD/docs/README.tr.md
- **العربية**: https://github.com/upstash/context7/blob/HEAD/docs/README.ar.md
- **Tiếng Việt**: https://github.com/upstash/context7/blob/HEAD/docs/README.vi.md

### Project Addition
- **Adding Projects Guide**: https://github.com/upstash/context7/blob/HEAD/docs/adding-projects.md

### Social & Community
- **X/Twitter**: https://x.com/context7ai
- **Discord**: https://upstash.com/discord
- **Star History**: https://www.star-history.com/#upstash/context7&Date

### License
- **MIT License**: https://github.com/upstash/context7/blob/HEAD/LICENSE

---

## 🌐 Integration Resources

### LLM Frameworks & Libraries
- **LangChain Python**: https://python.langchain.com/docs/integrations/document_loaders/firecrawl/
- **LangChain JavaScript**: https://js.langchain.com/docs/integrations/document_loaders/web_loaders/firecrawl
- **LlamaIndex**: https://docs.llamaindex.ai/en/latest/examples/data_connectors/WebPageDemo/#using-firecrawl-reader
- **Crew.ai**: https://docs.crewai.com/
- **Composio**: https://composio.dev/tools/firecrawl/all
- **PraisonAI**: https://docs.praison.ai/firecrawl/
- **Superinterface**: https://superinterface.ai/docs/assistants/functions/firecrawl
- **Vectorize**: https://docs.vectorize.io/integrations/source-connectors/firecrawl

### Low-Code Platforms
- **Dify**: https://dify.ai/blog/dify-ai-blog-integrated-with-firecrawl
- **Langflow**: https://docs.langflow.org/
- **Flowise AI**: https://docs.flowiseai.com/integrations/langchain/document-loaders/firecrawl
- **Cargo**: https://docs.getcargo.io/integration/firecrawl
- **Pipedream**: https://pipedream.com/apps/firecrawl/

### Automation Platforms
- **Zapier**: https://zapier.com/apps/firecrawl/integrations
- **Pabbly Connect**: https://www.pabbly.com/connect/integrations/firecrawl/

---

## 🚀 Quick Start Commands

### Installing Vercel AI SDK
```bash
npm install ai
```

### Installing Firecrawl
```bash
# Python
pip install firecrawl-py

# Node.js
npm install firecrawl
```

### Installing Context7 MCP
```bash
# With NPX
npx -y @upstash/context7-mcp

# Global Install
npm install -g @upstash/context7-mcp
```

---

## 📝 Notes

### API Keys Required
- **Vercel AI SDK**: Various provider API keys (OpenAI, Anthropic, etc.)
- **Firecrawl**: Get from https://www.firecrawl.dev/app/api-keys
- **Context7**: Optional, get from https://context7.com/dashboard for higher rate limits

### Recommended Usage Patterns
1. **For AI Chat/Generation**: Start with Vercel AI SDK
2. **For Web Scraping**: Use Firecrawl for reliable content extraction
3. **For Up-to-Date Documentation**: Integrate Context7 MCP for real-time library docs

### Common Integration Patterns
- **RAG Applications**: Firecrawl + Vercel AI SDK + Vector Database
- **Code Generation**: Context7 + AI SDK for up-to-date library usage
- **Web Research**: Firecrawl Search + AI SDK for content analysis
- **Multi-Modal AI**: AI SDK UI + provider-specific image/audio APIs

---

*Last Updated: October 24, 2025*
*Generated using Playwright browser automation to ensure up-to-date links*