# Changelog

All notable changes to the RAG Pipeline plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-06-17

### Changed

- **BREAKING**: Complete redesign for Google File Search API
- Dropped all vector database support (Pinecone, Qdrant, Chroma, pgvector, FAISS, Weaviate)
- Dropped LlamaIndex and LangChain framework support
- Now uses Google's fully managed RAG service

### Removed

- Agents: langchain-specialist, llamaindex-specialist, vector-db-engineer, embedding-specialist, retrieval-optimizer, web-scraper-agent, rag-architect, rag-deployment-agent, rag-tester
- Skills: vector-database-configs, langchain-patterns, llamaindex-patterns, embedding-models, retrieval-patterns, web-scraping-tools
- Commands: All old commands replaced with single `/rag-pipeline:build`

### Added

- `@google-file-search-specialist` agent - Google File Search API implementation
- `@document-processor` agent - Multi-format document parsing
- `google-file-search` skill - Store, upload, search, RAG patterns
- `/rag-pipeline:build` command - Build complete Google File Search RAG

### Why This Change?

Google File Search provides a fully managed RAG solution:

- No vector database infrastructure to manage
- Automatic embeddings and chunking
- Native Gemini integration with grounding
- Built-in citations and source attribution
- Simpler, more reliable, lower maintenance

## [1.0.0] - 2025-10-31

### Added

- Initial release of RAG Pipeline plugin
- 15 slash commands for complete RAG workflow
  - `/rag-pipeline:init` - Initialize RAG projects
  - `/rag-pipeline:add-vector-db` - Configure vector databases
  - `/rag-pipeline:add-embeddings` - Setup embedding models
  - `/rag-pipeline:add-chunking` - Implement chunking strategies
  - `/rag-pipeline:add-parser` - Add document parsers
  - `/rag-pipeline:add-scraper` - Add web scraping
  - `/rag-pipeline:build-ingestion` - Build ingestion pipeline
  - `/rag-pipeline:build-retrieval` - Build retrieval pipeline
  - `/rag-pipeline:build-generation` - Build generation pipeline
  - `/rag-pipeline:add-hybrid-search` - Implement hybrid search
  - `/rag-pipeline:add-metadata` - Add metadata filtering
  - `/rag-pipeline:add-monitoring` - Setup monitoring
  - `/rag-pipeline:test` - Run comprehensive tests
  - `/rag-pipeline:optimize` - Optimize performance and costs
  - `/rag-pipeline:deploy` - Deploy to production
- 10 specialized agents
  - rag-architect - High-level system design
  - llamaindex-specialist - LlamaIndex implementation
  - langchain-specialist - LangChain implementation
  - document-processor - Document parsing and chunking
  - embedding-specialist - Embedding configuration
  - vector-db-engineer - Vector database setup
  - retrieval-optimizer - Search optimization
  - rag-tester - Testing and evaluation
  - web-scraper-agent - Web scraping automation
  - rag-deployment-agent - Deployment orchestration
- 8 comprehensive skills with functional scripts
  - llamaindex-patterns - LlamaIndex templates and examples
  - langchain-patterns - LangChain templates and examples
  - vector-database-configs - 6 vector DB configurations
  - chunking-strategies - Multiple chunking approaches
  - embedding-models - Embedding provider configs
  - retrieval-patterns - Retrieval optimization templates
  - document-parsers - Multi-format parsing tools
  - web-scraping-tools - Web scraping utilities
- Support for LlamaIndex and LangChain frameworks
- Support for 6 vector databases (pgvector, Chroma, Pinecone, Weaviate, Qdrant, FAISS)
- Support for 4 embedding providers (OpenAI, HuggingFace, Cohere, Voyage AI)
- FREE options highlighted (HuggingFace embeddings, Groq LLMs, Chroma DB)
- Complete documentation with links to official docs
- Production-ready deployment configurations

### Documentation

- Comprehensive README.md with getting started guide
- Skill documentation with usage examples
- Integration guides for all supported frameworks
- Cost optimization strategies

[1.0.0]: https://github.com/ai-dev-marketplace/rag-pipeline/releases/tag/v1.0.0
