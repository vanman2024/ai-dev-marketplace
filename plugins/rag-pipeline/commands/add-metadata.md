---
description: Add metadata filtering and multi-tenant support
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

Goal: Add metadata filtering and multi-tenant isolation to enable filtered retrieval by tags, categories, dates, and tenant boundaries.

Core Principles:
- Define flexible metadata schema
- Update ingestion to extract and store metadata
- Implement metadata filtering in retrieval
- Add multi-tenant isolation with secure boundaries

Phase 1: Analyze Current Infrastructure
Goal: Understand existing RAG pipeline structure

Actions:
- Detect vector database: !{bash grep -r -E "(pinecone|chroma|pgvector|qdrant|weaviate|faiss)" --include="*.py" --include="*.ts" . 2>/dev/null | head -5}
- Check existing metadata: !{bash grep -r "metadata" --include="*.py" --include="*.ts" . 2>/dev/null | head -10}
- Find ingestion pipeline: !{bash find . -name "*ingest*" -o -name "*pipeline*" 2>/dev/null | grep -E "\.(py|ts|js)$" | head -5}
- Locate retrieval code: !{bash find . -name "*retriev*" -o -name "*query*" 2>/dev/null | grep -E "\.(py|ts|js)$" | head -5}
- Check framework: !{bash grep -r "from llama_index\|from langchain" --include="*.py" . 2>/dev/null | head -5}

Phase 2: Gather Requirements
Goal: Determine metadata schema and tenant needs

Actions:
- AskUserQuestion: "Metadata fields needed? (Examples: tags, categories, departments, date ranges, authors). Default: tags, categories, tenant_id, created_at, author, document_type"
- AskUserQuestion: "Enable multi-tenant isolation? (yes/no, default: yes)"
- AskUserQuestion: "Tenant identifier field? (Examples: tenant_id, organization_id, workspace_id). Default: tenant_id"

Phase 3: Implement Metadata Support
Goal: Add metadata extraction, storage, and filtering

Actions:

Task(description="Implement metadata filtering and multi-tenant support", subagent_type="rag-pipeline:retrieval-optimizer", prompt="You are the retrieval-optimizer agent. Add metadata filtering and multi-tenant support to this RAG pipeline.

Context: Vector database [Phase 1], Framework [Phase 1], Schema fields [Phase 2], Multi-tenant [Phase 2], Tenant field [Phase 2]

Requirements:

1. **Metadata Schema** (metadata_schema.py):
   - MetadataSchema class with fields: tenant_id, tags (array), category, created_at, updated_at, author, document_type, custom_fields
   - Validation functions for each field type
   - Support required/optional fields

2. **Ingestion Updates**:
   - Extract file metadata (filename, extension, dates)
   - Extract content metadata (type, author)
   - Accept custom metadata via parameters
   - Validate and store metadata with vectors

3. **Metadata Filtering** (metadata_filter.py):
   - MetadataFilter class with operations: ==, !=, contains, in, range, AND, OR, NOT
   - Integrate with vector DB API (LlamaIndex MetadataFilters, LangChain filter param, Pinecone/Chroma/pgvector syntax)
   - FilterBuilder with fluent API: .where(field, op, value).build()

4. **Multi-Tenant Isolation** (tenant_context.py):
   - TenantContext class for current tenant
   - TenantRetriever wrapper auto-injecting tenant_id filter
   - Tenant validation middleware
   - Security: never trust client tenant_id, audit cross-tenant access

5. **Configuration** (config.py/.env):
   - MULTI_TENANT_ENABLED, TENANT_FIELD_NAME, METADATA_FIELDS, REQUIRE_TENANT_FILTER, DEFAULT_METADATA

6. **Examples**:
   - examples/metadata_ingestion.py (ingest with metadata)
   - examples/metadata_retrieval.py (filtered queries)
   - examples/multi_tenant_demo.py (tenant isolation)

7. **Tests** (tests/test_metadata.py):
   - Validation, filtered retrieval, tenant isolation (no leakage), performance, edge cases

8. **Documentation**:
   - README: metadata filtering, multi-tenant architecture, API reference, security practices, migration guide

Files: metadata_schema.py, metadata_filter.py, tenant_context.py, config.py, tests/test_metadata.py, examples/metadata_*.py, README.md updates

Deliverable: Complete metadata filtering and multi-tenant support with schema, ingestion updates, filtered retrieval, tenant isolation, tests, examples, docs.")

Phase 4: Validation
Goal: Verify implementation

Actions:
- Check files: !{bash ls -la metadata_schema.* metadata_filter.* tenant_context.* 2>/dev/null}
- Verify filters: !{bash grep -n "MetadataFilter\|tenant" --include="*.py" --include="*.ts" . -r 2>/dev/null | head -10}
- Find tests: !{bash find . -path "*/test*" -name "*metadata*" -o -path "*/test*" -name "*tenant*" 2>/dev/null}

Phase 5: Summary
Goal: Usage instructions

Actions:
Summary:
- Files: metadata_schema.py, metadata_filter.py, tenant_context.py, updated ingestion/retrieval, tests, examples
- Ingest: ingest_document(content, metadata={'tenant_id': 'org-123', 'tags': ['api'], 'category': 'docs'})
- Query: filter = FilterBuilder().where('tenant_id', '==', 'org-123').where('tags', 'contains', 'api').build()
- Tenant-scoped: TenantRetriever(base_retriever, tenant_id='org-123').retrieve(query)
- Security: Validate tenant_id from auth context, enable REQUIRE_TENANT_FILTER, audit cross-tenant access
- Next: Update existing documents, test filtering, add tenant auth, monitor performance, add metadata indexes
