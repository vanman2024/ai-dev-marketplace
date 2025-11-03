---
description: Implement document chunking strategies (fixed, semantic, recursive, hybrid)
argument-hint: [strategy-type]
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

Goal: Implement document chunking strategies for RAG pipeline with configurable parameters and validation

Core Principles:
- Ask user for chunking strategy preferences
- Fetch minimal documentation (LlamaIndex + LangChain)
- Generate chunking implementation with chosen strategy
- Test with sample documents
- Provide chunk statistics and recommendations

Phase 1: Gather Requirements
Goal: Understand chunking strategy needs

Actions:
- Parse $ARGUMENTS to check if strategy specified
- If strategy in $ARGUMENTS, use it; otherwise ask user
- AskUserQuestion: "Which chunking strategy would you like to implement?
  1. Fixed-size chunking (simple, predictable chunks)
  2. Semantic chunking (context-aware boundaries)
  3. Recursive chunking (hierarchical splitting)
  4. Hybrid chunking (combined approaches)

  Enter number (1-4) or strategy name:"
- AskUserQuestion: "Chunk size in characters/tokens? (default: 512)"
- AskUserQuestion: "Chunk overlap in characters/tokens? (default: 50)"
- Detect project structure: Check for existing Python environment

Phase 2: Fetch Documentation
Goal: Load chunking strategy documentation

Actions:
Fetch these docs in parallel (2 URLs):

1. WebFetch: https://docs.llamaindex.ai/en/stable/module_guides/loading/node_parsers/
2. WebFetch: https://python.langchain.com/docs/modules/data_connection/document_transformers/

Phase 3: Implementation
Goal: Generate chunking script with selected strategy

Actions:

Task(description="Generate chunking implementation", subagent_type="rag-pipeline:document-processor", prompt="You are the document-processor agent. Implement document chunking for a RAG pipeline.

Strategy selected: [user's choice from Phase 1]
Chunk size: [user's chunk size]
Chunk overlap: [user's overlap]

Using the documentation fetched in Phase 2, create a Python script that:

1. Implements the chosen chunking strategy
2. Supports multiple document formats (txt, pdf, markdown)
3. Includes configuration for chunk size and overlap
4. Provides chunk metadata (position, source, length)
5. Handles edge cases (empty documents, very small documents)
6. Uses appropriate library (LlamaIndex or LangChain based on strategy):
   - Fixed-size: Use LangChain CharacterTextSplitter or LlamaIndex SentenceSplitter
   - Semantic: Use LangChain SemanticChunker or LlamaIndex SemanticSplitterNodeParser
   - Recursive: Use LangChain RecursiveCharacterTextSplitter
   - Hybrid: Combine multiple approaches

Create these files:
- chunking/chunker.py - Main chunking implementation
- chunking/config.py - Configuration for chunk parameters
- chunking/test_chunker.py - Test with sample documents
- chunking/requirements.txt - Dependencies

Include comprehensive docstrings and type hints.
Deliverable: Working chunking implementation ready for testing")

Wait for Task to complete.

Phase 4: Test Chunking
Goal: Validate chunking with sample documents

Actions:
- Create sample test document if not exists: !{bash mkdir -p chunking/samples}
- Generate sample text: Write simple test document to chunking/samples/test.txt
- Run chunking test: !{bash cd chunking && python test_chunker.py}
- Capture chunk statistics: Number of chunks, avg size, overlap effectiveness
- Verify chunk boundaries are appropriate

Phase 5: Statistics and Recommendations
Goal: Provide chunk analysis and next steps

Actions:
Display summary:
- Strategy implemented: [chosen strategy]
- Configuration: Chunk size [size], overlap [overlap]
- Test results: [number] chunks generated from sample
- Average chunk size: [avg] characters
- Files created:
  * chunking/chunker.py
  * chunking/config.py
  * chunking/test_chunker.py
  * chunking/requirements.txt
  * chunking/samples/test.txt

Recommendations:
- For semantic search: Consider chunk size 256-512 tokens
- For question answering: Consider chunk size 512-1024 tokens
- For summarization: Consider larger chunks 1024-2048 tokens
- Overlap should be 10-20% of chunk size
- Test with your actual documents and adjust parameters

Next steps:
- Install dependencies: pip install -r chunking/requirements.txt
- Test with your documents: python chunking/chunker.py your_document.pdf
- Integrate with vector database: /rag-pipeline:add-vector-db
- Add embeddings: /rag-pipeline:add-embeddings

Important Notes:
- Adapts to user's chunking strategy preference
- Fetches minimal docs (2 URLs)
- Generates production-ready chunking code
- Tests implementation with samples
- Provides tuning recommendations
