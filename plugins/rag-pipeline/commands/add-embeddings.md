---
description: Configure embedding models (OpenAI, HuggingFace, Cohere, Voyage)
argument-hint: [model-provider]
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

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

Goal: Configure embedding models for RAG pipeline with FREE HuggingFace or paid providers (OpenAI, Cohere, Voyage).

Core Principles:
- Highlight FREE HuggingFace models first
- Test embeddings before completing
- Calculate cost estimates for paid providers
- Provide clear next steps

Phase 1: Provider Selection
Goal: Determine which embedding provider to configure

Actions:
- Parse $ARGUMENTS to check if provider specified
- If $ARGUMENTS empty, use AskUserQuestion:
  "Which embedding provider?
   1. HuggingFace (FREE local - recommended for testing)
   2. OpenAI (Paid - high quality embeddings)
   3. Cohere (Paid - multilingual support)
   4. Voyage (Paid - specialized for retrieval)

   Recommendation: Start with FREE HuggingFace, upgrade later if needed."
- Display provider info (pricing, models, requirements)

Phase 2: Environment Detection
Goal: Understand project setup

Actions:
- Check config files: !{bash ls -la requirements.txt pyproject.toml package.json 2>/dev/null}
- Detect Python/Node.js environment
- Check .env exists: !{bash test -f .env && echo "exists" || echo "not found"}
- Identify package manager (pip, poetry, npm)

Phase 3: Installation & Configuration
Goal: Install dependencies and configure provider

Actions:

Task(description="Install and configure embeddings", subagent_type="rag-pipeline:embedding-specialist", prompt="You are the embedding-specialist agent. Install and configure $ARGUMENTS embedding provider.

Provider Details:

HuggingFace (FREE): Install sentence-transformers, torch. Popular models: all-MiniLM-L6-v2 (384d, fast), all-mpnet-base-v2 (768d, quality). Docs: https://huggingface.co/models?pipeline_tag=sentence-similarity. No API key needed.

OpenAI: Install openai package. Models: text-embedding-ada-002, text-embedding-3-small/large. Docs: https://platform.openai.com/docs/guides/embeddings. Needs OPENAI_API_KEY.

Cohere: Install cohere package. Models: embed-english-v3.0, embed-multilingual-v3.0. Docs: https://docs.cohere.com/docs/embeddings. Needs COHERE_API_KEY.

Voyage: Install voyageai package. Models: voyage-2, voyage-code-2. Docs: https://docs.voyageai.com/. Needs VOYAGE_API_KEY.

Tasks:
1. Install appropriate packages for detected environment
2. For paid providers: Ask user for API key using AskUserQuestion, add to .env file
3. For HuggingFace: Skip API key (local processing)
4. Create embeddings_config.yaml with: provider, model, dimensions, pricing (if paid), device settings
5. Verify installation with test import
6. Report installed packages and versions

Expected output: Configuration file path, installed packages, API key status")

Phase 4: Testing & Validation
Goal: Verify embeddings work correctly

Actions:

Task(description="Test embedding generation", subagent_type="rag-pipeline:embedding-specialist", prompt="You are the embedding-specialist agent. Test embedding generation for $ARGUMENTS provider.

Create test_embeddings script that:
1. Loads config from Phase 3
2. Generates embeddings for sample text: 'RAG pipeline test document'
3. Validates output: correct dimensions, numeric values, proper shape
4. Measures: generation time, tokens processed, cost estimate (if paid)

For HuggingFace: Test model loading, check GPU/CPU usage, verify cache location
For Paid APIs: Validate API key, test connection, verify response format

Expected output: Test script path, results (pass/fail), sample vector (first 5 values), performance metrics")

Phase 5: Cost Analysis
Goal: Calculate and display cost estimates

Actions:
- Read test results from Phase 4
- If HuggingFace: Display "Cost: FREE (local)", show compute requirements
- If paid: Calculate costs for 1K, 10K, 100K documents (~500 words each)
- Display pricing breakdown and monthly estimates
- Compare to FREE HuggingFace option
- Provide cost optimization tips

Phase 6: Summary
Goal: Document setup and next steps

Actions:
- Summarize: Provider, model, dimensions, cost, location (local/cloud)
- List created files: config file, test script, .env status
- Explain trade-offs: cost vs quality vs speed
- Next steps:
  * Run test: python test_embeddings.py
  * Add vector database: /rag-pipeline:add-vectorstore
  * Batch process existing documents
- Provide documentation links and troubleshooting resources
