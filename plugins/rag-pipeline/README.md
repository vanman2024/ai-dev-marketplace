# RAG Pipeline Plugin

**Google File Search RAG** - Fully managed RAG using Google's File Search API.

## Overview

This plugin provides a streamlined approach to building RAG systems using Google's managed File Search API. No vector database setup, no embedding management - just upload documents and search.

## Why Google File Search?

- **No Infrastructure** - No vector DB to manage
- **Automatic Embeddings** - Built-in semantic understanding
- **Automatic Chunking** - Smart document splitting
- **Native Gemini Integration** - Seamless RAG with Gemini models
- **Grounding Support** - Built-in citations and source attribution

## Features

- **Store Management** - Create and manage document stores
- **Document Upload** - Support for PDF, DOCX, HTML, Markdown, text, code
- **Semantic Search** - Automatic embeddings with configurable top_k
- **RAG Generation** - Complete RAG with Gemini and citations
- **Streaming** - Real-time streaming responses
- **Metadata Filtering** - Filter search by document attributes

## Commands

### `/rag-pipeline:build`
Build a complete Google File Search RAG system with:
- Store creation and configuration
- Document upload scripts
- Search API integration
- RAG endpoint with citations
- Streaming support

## Agents

### `@google-file-search-specialist`
Expert in Google File Search API implementation:
- Store management and configuration
- Document upload and processing
- Search implementation patterns
- RAG with Gemini integration
- FastAPI/Next.js endpoints

### `@document-processor`
Multi-format document processing:
- PDF text extraction
- Word document parsing
- HTML content extraction
- Markdown processing
- Batch processing scripts

## Skills

### `google-file-search`
Templates for Google File Search implementation:
- Store creation patterns
- Upload scripts
- Search queries
- RAG pipelines

### `document-parsers`
Document parsing utilities:
- PDF extraction
- DOCX processing
- HTML cleaning
- Text normalization

### `chunking-strategies`
Chunking configuration for optimal retrieval:
- Size configuration
- Overlap settings
- Format-specific strategies

## Quick Start

```python
from google import genai

client = genai.Client()

# 1. Create store
store = client.files.create_store(display_name="my-docs")

# 2. Upload documents
client.files.upload(path="doc.pdf", config={"store_id": store.id})

# 3. Search
results = client.files.search(
    store_id=store.id,
    query="How does X work?",
    top_k=5
)

# 4. Generate with context
context = "\n".join([r.content for r in results.results])
response = client.models.generate_content(
    model="gemini-2.0-flash",
    contents=f"Context:\n{context}\n\nQuestion: How does X work?"
)
```

## Documentation

- [Google File Search](https://ai.google.dev/gemini-api/docs/file-search)
- [Files API](https://ai.google.dev/api/files)
- [Grounding](https://ai.google.dev/gemini-api/docs/grounding)

## Requirements

```bash
pip install google-genai
```

## Environment Variables

```bash
# Required
GOOGLE_API_KEY=your_api_key_here
```

## Version

2.0.0 - Rebuilt for Google File Search (dropped vector DB support)

## License

MIT
