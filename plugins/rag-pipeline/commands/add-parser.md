---
description: Add document parsers (LlamaParse, Unstructured, PyPDF, PDFPlumber)
argument-hint: [parser-type]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch, Skill
---
## Available Skills

This commands has access to the following skills from the rag-pipeline plugin:

- **chunking-strategies**: Document chunking implementations and benchmarking tools for RAG pipelines including fixed-size, semantic, recursive, and sentence-based strategies. Use when implementing document processing, optimizing chunk sizes, comparing chunking approaches, benchmarking retrieval performance, or when user mentions chunking, text splitting, document segmentation, RAG optimization, or chunk evaluation.\n- **document-parsers**: Multi-format document parsing tools for PDF, DOCX, HTML, and Markdown with support for LlamaParse, Unstructured.io, PyPDF2, PDFPlumber, and python-docx. Use when parsing documents, extracting text from PDFs, processing Word documents, converting HTML to text, extracting tables from documents, building RAG pipelines, chunking documents, or when user mentions document parsing, PDF extraction, DOCX processing, table extraction, OCR, LlamaParse, Unstructured.io, or document ingestion.\n- **embedding-models**: Embedding model configurations and cost calculators\n- **langchain-patterns**: LangChain implementation patterns with templates, scripts, and examples for RAG pipelines\n- **llamaindex-patterns**: LlamaIndex implementation patterns with templates, scripts, and examples for building RAG applications. Use when implementing LlamaIndex, building RAG pipelines, creating vector indices, setting up query engines, implementing chat engines, integrating LlamaCloud, or when user mentions LlamaIndex, RAG, VectorStoreIndex, document indexing, semantic search, or question answering systems.\n- **retrieval-patterns**: Search and retrieval strategies including semantic, hybrid, and reranking for RAG systems. Use when implementing retrieval mechanisms, optimizing search performance, comparing retrieval approaches, or when user mentions semantic search, hybrid search, reranking, BM25, or retrieval optimization.\n- **vector-database-configs**: Vector database configuration and setup for pgvector, Chroma, Pinecone, Weaviate, Qdrant, and FAISS with comparison guide and migration helpers\n- **web-scraping-tools**: Web scraping templates, scripts, and patterns for documentation and content collection using Playwright, BeautifulSoup, and Scrapy. Includes rate limiting, error handling, and extraction patterns. Use when scraping documentation, collecting web content, extracting structured data, building RAG knowledge bases, harvesting articles, crawling websites, or when user mentions web scraping, documentation collection, content extraction, Playwright scraping, BeautifulSoup parsing, or Scrapy spiders.\n
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

Goal: Add and configure document parsers for RAG pipeline with multi-format support and advanced features.

Core Principles:
- Highlight FREE parsers (Unstructured, PyPDF2, PDFPlumber)
- Understand existing structure before adding dependencies
- Generate unified parsing interface
- Test parsing quality

Phase 1: Requirements & Discovery
Goal: Determine parser type and analyze project structure

Actions:
- Parse $ARGUMENTS for parser type (llamaparse, unstructured, pypdf, pdfplumber)
- If unclear, use AskUserQuestion to gather:
  - Which parser? (LlamaParse PAID | Unstructured/PyPDF2/PDFPlumber FREE)
  - Document types? (PDF, DOCX, HTML, Markdown)
  - Need table/image extraction? OCR?
  - Local processing or cloud API?
- Detect Python environment: !{bash python --version 2>&1}
- Check requirements: !{bash find . -name "requirements.txt" -o -name "pyproject.toml" | head -5}
- Find existing parsers: !{bash find . -type f -name "*.py" | xargs grep -l "parser\|parse" 2>/dev/null | head -10}
- Check dependencies: !{bash cat requirements.txt 2>/dev/null | grep -E "pdf|parse|unstructured" || echo "None"}

Phase 2: Load Documentation
Goal: Reference parser documentation based on selection

Actions:
- For LlamaParse: WebFetch: https://docs.cloud.llamaindex.ai/llamaparse/getting_started
- For Unstructured: WebFetch: https://unstructured-io.github.io/unstructured/introduction.html
- For PyPDF2: WebFetch: https://pypdf2.readthedocs.io/en/latest/user/extract-text.html
- For PDFPlumber: WebFetch: https://github.com/jsvine/pdfplumber#table-extraction

Phase 3: Implementation
Goal: Install parser and generate code

Actions:

Task(description="Configure document parser", subagent_type="rag-pipeline:document-processor", prompt="You are the document-processor agent. Add document parser for $ARGUMENTS.

Parser: [selected parser]
Features: Table extraction [yes/no], Image extraction [yes/no], OCR [yes/no]
Project: [structure]

Requirements:
1. Dependencies:
   - Update requirements.txt with parser package
   - LlamaParse: llama-parse
   - Unstructured: unstructured[all-docs]
   - PyPDF2: pypdf2
   - PDFPlumber: pdfplumber

2. Parser Implementation:
   - Create parser module with unified interface
   - Support PDF, DOCX, HTML, Markdown
   - Configure table/image handling
   - Add error handling and logging
   - Support batch processing

3. Configuration:
   - LlamaParse: Add LLAMA_CLOUD_API_KEY to .env
   - Create config file with parsing settings
   - Document all options

4. Utility Script:
   - Create parsing script supporting input dir/file
   - Auto-detect document type
   - Output structured text/JSON
   - Include progress tracking

5. Quality:
   - Type hints and docstrings
   - Usage examples in comments
   - Follow project style

Deliverables:
- Updated requirements.txt
- Parser module (parsers/[name].py)
- Utility script (scripts/parse_documents.py)
- Config file/env updates
- README documentation")

Phase 4: Validation
Goal: Test parser installation and quality

Actions:
- Verify install: !{bash pip list | grep -E "llama-parse|unstructured|pypdf|pdfplumber"}
- Check files: !{bash find . -type f -name "*parser*.py" -o -name "parse*.py" | head -10}
- Validate syntax: !{bash python -m py_compile [generated-files]}
- Test import: !{bash python -c "from parsers import [parser_class]" 2>&1}

Phase 5: Summary
Goal: Document accomplishments and next steps

Actions:
- Summarize:
  - Parser: [name and version]
  - Files: [created/modified]
  - Features: [enabled capabilities]
  - Format support: [PDF, DOCX, etc.]
- Usage examples:
  - Code snippet
  - CLI command
  - Configuration
- API keys (if LlamaParse):
  - Add LLAMA_CLOUD_API_KEY to .env
  - Get key from llamaindex.ai
- Cost notes:
  - FREE: Unstructured, PyPDF2, PDFPlumber
  - PAID: LlamaParse
- Next steps:
  - Test with your documents
  - Tune parameters
  - Integrate with embedding pipeline
  - Monitor quality metrics
