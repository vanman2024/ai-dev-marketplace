---
description: Build document ingestion pipeline (load, parse, chunk, embed, store)
argument-hint: none
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

Goal: Build complete document ingestion pipeline with loading, parsing, chunking, embedding, and vector storage

Core Principles:
- Detect existing configurations
- Fetch minimal documentation
- Generate unified ingestion script with batch processing, error handling, and progress tracking

Phase 1: Discovery and Documentation
Goal: Understand RAG infrastructure and fetch ingestion docs

Actions:
- Detect project: Check for package.json, requirements.txt, pyproject.toml
- Load configs: @config.yaml, @.env for chunking, embedding, vector DB settings
- Example: !{bash grep -r "chunk_size\|embedding\|vector" . --include="*.py" --include="*.json" --include="*.yaml" 2>/dev/null | head -10}

Fetch docs in parallel:
1. WebFetch: https://docs.llamaindex.ai/en/stable/understanding/loading/loading/
2. WebFetch: https://docs.llamaindex.ai/en/stable/module_guides/loading/ingestion_pipeline/
3. WebFetch: https://python.langchain.com/docs/modules/data_connection/document_loaders/
4. WebFetch: https://python.langchain.com/docs/modules/data_connection/document_transformers/

Phase 2: Implementation
Goal: Generate unified ingestion pipeline with all stages

Actions:

Task(description="Build ingestion pipeline", subagent_type="rag-pipeline:document-processor", prompt="You are the document-processor agent. Build complete document ingestion pipeline for $ARGUMENTS.

Context: Detected project type, configs (chunking, embedding, vector DB) from Phase 1
Documentation: LlamaIndex ingestion, LangChain loaders/transformers fetched

Requirements:
Create ingestion.py with 6 stages:
1. Load documents (PDF, DOCX, TXT, MD, HTML support)
2. Parse and extract text + metadata
3. Chunk/split with configurable size and overlap
4. Generate embeddings in batches
5. Store vectors in database with metadata
6. Verify ingestion success

Features:
- Batch processing for large document sets
- Retry logic with exponential backoff
- Progress tracking (tqdm/logging)
- Error logging with failed document tracking
- Resume capability for interrupted runs
- Metadata preservation (source, page, timestamps)
- CLI interface (argparse/typer)
- Type hints and docstrings
- Config loading from .env/config file

Deliverables:
- ingestion.py or ingestion_pipeline.py
- config.yaml/.env template
- test_ingestion.py with validation
- Usage documentation")

Phase 3: Testing and Verification
Goal: Set up testing infrastructure and verify pipeline

Actions:
- Create test_data/ directory with sample document
- Example: !{bash mkdir -p test_data && echo "Sample test document" > test_data/sample.txt}
- Verify ingestion script exists: !{bash ls -la ingestion*.py 2>/dev/null}
- Check imports compile: !{bash python -m py_compile ingestion*.py 2>/dev/null || echo "Check imports manually"}
- List all created files (ingestion.py, config template, test script)

Phase 4: Summary
Goal: Display usage instructions

Actions:
Summary:
- Files: ingestion.py, config.yaml/.env, test_ingestion.py, test_data/
- Capabilities: Multi-format support, batch processing, error handling, progress tracking, resume capability
- Usage:
  1. Configure API keys and vector DB credentials
  2. Run: python ingestion.py --source ./documents
  3. Test: python test_ingestion.py
- Next steps: Add documents, configure credentials, run test ingestion, consider /rag-pipeline:build-retrieval

Important Notes:
- Adapts to LlamaIndex or LangChain
- Production-ready with error handling and batch processing
