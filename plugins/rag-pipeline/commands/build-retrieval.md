---
description: Build retrieval pipeline (simple, hybrid, rerank)
argument-hint: [retrieval-type]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch, Skill
---
## Available Skills

This commands has access to the following skills from the rag-pipeline plugin:

- **chunking-strategies**: Document chunking implementations and benchmarking tools for RAG pipelines including fixed-size, semantic, recursive, and sentence-based strategies. Use when implementing document processing, optimizing chunk sizes, comparing chunking approaches, benchmarking retrieval performance, or when user mentions chunking, text splitting, document segmentation, RAG optimization, or chunk evaluation.
- **document-parsers**: Multi-format document parsing tools for PDF, DOCX, HTML, and Markdown with support for LlamaParse, Unstructured.io, PyPDF2, PDFPlumber, and python-docx. Use when parsing documents, extracting text from PDFs, processing Word documents, converting HTML to text, extracting tables from documents, building RAG pipelines, chunking documents, or when user mentions document parsing, PDF extraction, DOCX processing, table extraction, OCR, LlamaParse, Unstructured.io, or document ingestion.
- **embedding-models**: Embedding model configurations and cost calculators
- **langchain-patterns**: LangChain implementation patterns with templates, scripts, and examples for RAG pipelines
- **llamaindex-patterns**: LlamaIndex implementation patterns with templates, scripts, and examples for building RAG applications. Use when implementing LlamaIndex, building RAG pipelines, creating vector indices, setting up query engines, implementing chat engines, integrating LlamaCloud, or when user mentions LlamaIndex, RAG, VectorStoreIndex, document indexing, semantic search, or question answering systems.
- **retrieval-patterns**: Search and retrieval strategies including semantic, hybrid, and reranking for RAG systems. Use when implementing retrieval mechanisms, optimizing search performance, comparing retrieval approaches, or when user mentions semantic search, hybrid search, reranking, BM25, or retrieval optimization.
- **vector-database-configs**: Vector database configuration and setup for pgvector, Chroma, Pinecone, Weaviate, Qdrant, and FAISS with comparison guide and migration helpers
- **web-scraping-tools**: Web scraping templates, scripts, and patterns for documentation and content collection using Playwright, BeautifulSoup, and Scrapy. Includes rate limiting, error handling, and extraction patterns. Use when scraping documentation, collecting web content, extracting structured data, building RAG knowledge bases, harvesting articles, crawling websites, or when user mentions web scraping, documentation collection, content extraction, Playwright scraping, BeautifulSoup parsing, or Scrapy spiders.

**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

---



## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Build a production-ready retrieval pipeline with support for simple semantic search, hybrid search, and reranking capabilities.

Core Principles:
- Ask clarifying questions to understand requirements
- Fetch minimal documentation (3-4 URLs)
- Implement retrieval strategy based on user needs
- Add metadata filtering and query optimization
- Validate with sample queries

Phase 1: Discovery
Goal: Understand retrieval requirements and existing setup

Actions:
- Parse $ARGUMENTS to check if retrieval type is specified
- Detect existing RAG setup: Check for vector database config, existing embeddings
- Load existing configuration: @config files, @embedding setup
- Identify available vector store: Pinecone, Chroma, PGVector, etc.

If retrieval type is not clear from $ARGUMENTS, use AskUserQuestion to gather:
- What retrieval strategy do you need?
  * Simple semantic search (vector similarity only)
  * Hybrid search (vector + keyword/BM25)
  * With reranking (cross-encoder or LLM-based)
- Do you need metadata filtering? (filter by date, category, source, etc.)
- What's your expected query complexity? (simple questions vs complex analytical queries)
- Which framework are you using? (LlamaIndex, LangChain, or both)

Phase 2: Load Retrieval Documentation
Goal: Fetch framework-specific retrieval docs

Actions:
Fetch these docs in parallel (4 URLs max):

1. WebFetch: https://docs.llamaindex.ai/en/stable/module_guides/querying/retriever/
2. WebFetch: https://docs.llamaindex.ai/en/stable/examples/retrievers/auto_vs_recursive_retriever/
3. WebFetch: https://python.langchain.com/docs/modules/data_connection/retrievers/
4. WebFetch: https://python.langchain.com/docs/modules/data_connection/retrievers/ensemble/ (if hybrid search)

Phase 3: Generate Retrieval Configuration
Goal: Create retrieval pipeline configuration

Actions:

Invoke the **general-purpose** agent to implement retrieval configuration:

The agent should:
- Create retrieval configuration based on selected strategy
- For simple semantic: Configure VectorStoreRetriever with similarity settings
- For hybrid: Set up ensemble retriever combining vector + BM25/keyword search
- For reranking: Add reranker model (Cohere, cross-encoder, or LLM-based)
- Configure retrieval parameters: top_k, similarity_threshold, alpha (for hybrid)
- Add error handling and fallback strategies

Provide the agent with:
- Context: Detected vector store and framework
- Strategy: Simple, hybrid, or reranking based on user input
- Framework preference: LlamaIndex, LangChain, or both
- Expected output: Retrieval configuration file with proper imports

Phase 4: Implement Query Optimization
Goal: Add query preprocessing and optimization

Actions:

Continue with the **general-purpose** agent:

The agent should:
- Add query transformation layer: Expand, decompose, or rephrase queries
- Implement query routing: Route to appropriate retrieval strategy
- Add hypothetical document embeddings (HyDE) if beneficial
- Configure query caching to avoid redundant retrievals
- Add logging and telemetry for query analysis
- Include examples of query optimization patterns

Phase 5: Add Metadata Filtering Support
Goal: Enable filtering by metadata fields

Actions:

Continue with the **general-purpose** agent:

The agent should:
- Define metadata schema: date ranges, categories, sources, custom fields
- Implement filter builders for common patterns
- Add pre-filter and post-filter strategies
- Support complex filter logic: AND, OR, NOT operations
- Create filter validation utilities
- Add examples showing metadata filtering usage

Phase 6: Test Retrieval Quality
Goal: Validate retrieval with sample queries

Actions:

Create test file with sample queries:
- Simple factual questions
- Complex analytical queries
- Edge cases (no results, ambiguous queries)
- Queries requiring metadata filtering

Invoke the **general-purpose** agent to create test suite:

The agent should:
- Create retrieval testing script
- Run sample queries through the pipeline
- Measure retrieval metrics: precision@k, recall@k, MRR
- Test metadata filtering works correctly
- Verify reranking improves results (if enabled)
- Generate retrieval quality report

Phase 7: Summary
Goal: Document the retrieval pipeline

Actions:
Provide comprehensive summary:
- Retrieval strategy implemented (simple/hybrid/reranking)
- Configuration files created
- Query optimization features added
- Metadata filtering capabilities
- Test results and quality metrics
- Files modified/created
- Example usage code showing:
  * Basic retrieval
  * Retrieval with metadata filters
  * Query optimization usage
  * Reranking (if enabled)
- Performance tuning recommendations
- Next steps: Consider adding /rag-pipeline:optimize-chunks for better chunking

Important Notes:
- Adapts to existing vector store setup
- Supports both LlamaIndex and LangChain
- Fetches minimal docs (4 URLs)
- Uses general-purpose agent for all implementation
- Includes quality testing and validation
- Focused on retrieval pipeline only
