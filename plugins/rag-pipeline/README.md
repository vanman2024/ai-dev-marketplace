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
- **Document Upload** - Support for PDF, DOCX, HTML, Markdown, text, code (100+ types)
- **Semantic Search** - Automatic embeddings with File Search tool
- **RAG Generation** - Complete RAG with Gemini and citations
- **Metadata Filtering** - Filter search by document attributes

## Commands

### `/rag-pipeline:build`

Build a complete Google File Search RAG system with:

- Store creation and configuration
- Document upload scripts
- Search API integration
- RAG endpoint with citations

## Agents

### `@google-file-search-ts`

TypeScript/JavaScript specialist using `@google/genai` SDK:

- Store management (`ai.fileSearchStores.create()`)
- Document upload (`ai.fileSearchStores.uploadToFileSearchStore()`)
- Semantic search (`ai.models.generateContent()` with fileSearch tool)
- Next.js API route examples
- Citation extraction from grounding metadata

### `@google-file-search-py`

Python specialist using `google-genai` SDK:

- Store management (`client.file_search_stores.create()`)
- Document upload (`client.file_search_stores.upload_to_file_search_store()`)
- Semantic search (`client.models.generate_content()` with FileSearch tool)
- FastAPI endpoint examples
- Citation extraction from grounding metadata

### `@document-processor`

Multi-format document processing:

- PDF text extraction
- Word document parsing
- HTML content extraction
- Markdown processing
- Batch processing scripts

## Skills

### `google-file-search`

Templates and patterns for both TypeScript and Python:

- Complete client classes
- Store creation patterns
- Upload with chunking configuration
- Search with metadata filtering
- RAG pipelines with citations

### `document-parsers`

Document parsing utilities

### `chunking-strategies`

Chunking configuration for optimal retrieval

## Quick Start

### TypeScript/JavaScript

```bash
npm install @google/genai
```

```typescript
import { GoogleGenAI } from '@google/genai';

const ai = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY! });

// 1. Create store
const store = await ai.fileSearchStores.create({
  config: { displayName: 'my-docs' }
});

// 2. Upload document (uploads AND indexes)
let op = await ai.fileSearchStores.uploadToFileSearchStore({
  file: './document.pdf',
  fileSearchStoreName: store.name,
  config: { displayName: 'document.pdf' }
});

// Wait for indexing
while (!op.done) {
  await new Promise(r => setTimeout(r, 2000));
  op = await ai.operations.get({ operation: op });
}

// 3. Search with File Search tool
const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: 'How does X work?',
  config: {
    tools: [{ fileSearch: { fileSearchStoreNames: [store.name] }}]
  }
});

console.log(response.text);
```

### Python

```bash
pip install google-genai
```

```python
import os
import time
from google import genai
from google.genai import types

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

# 1. Create store
store = client.file_search_stores.create(
    config={"display_name": "my-docs"}
)

# 2. Upload document (uploads AND indexes)
operation = client.file_search_stores.upload_to_file_search_store(
    file="./document.pdf",
    file_search_store_name=store.name,
    config={"display_name": "document.pdf"}
)

# Wait for indexing
while not operation.done:
    time.sleep(2)
    operation = client.operations.get(operation)

# 3. Search with File Search tool
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="How does X work?",
    config=types.GenerateContentConfig(
        tools=[types.Tool(file_search=types.FileSearch(
            file_search_store_names=[store.name]
        ))]
    )
)

print(response.text)
```

## Documentation

- [Google File Search](https://ai.google.dev/gemini-api/docs/file-search)
- [API Keys](https://aistudio.google.com/apikey)

## Requirements

### TypeScript/JavaScript
```bash
npm install @google/genai
```

### Python
```bash
pip install google-genai
```

## Environment Variables

```bash
# Required
GOOGLE_API_KEY=your_api_key_here
```

## Supported Models

- `gemini-2.5-flash` - Fast responses (recommended)
- `gemini-2.5-pro` - Complex reasoning

## Version

3.0.0 - Rebuilt with official SDK patterns for both TypeScript and Python

## License

MIT
