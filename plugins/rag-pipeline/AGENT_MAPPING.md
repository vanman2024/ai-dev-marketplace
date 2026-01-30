# RAG Pipeline Agent Mapping

## Agents

| Agent                     | Model  | Purpose                                                                  |
| ------------------------- | ------ | ------------------------------------------------------------------------ |
| `@google-file-search-ts`  | Sonnet | Google File Search for TypeScript/JavaScript using `@google/genai` SDK   |
| `@google-file-search-py`  | Sonnet | Google File Search for Python using `google-genai` SDK                   |
| `@document-processor`     | Haiku  | Document parsing - PDF, DOCX, HTML, Markdown extraction                  |

## Usage

### Google File Search - TypeScript/JavaScript

```
@google-file-search-ts Build a RAG system for my Next.js app
```

- Uses official `@google/genai` npm package
- Creates File Search stores with `ai.fileSearchStores.create()`
- Uploads with `ai.fileSearchStores.uploadToFileSearchStore()`
- Searches with `ai.models.generateContent()` + fileSearch tool
- Extracts citations from grounding metadata
- Provides Next.js API route examples

### Google File Search - Python

```
@google-file-search-py Build a RAG system with FastAPI
```

- Uses official `google-genai` pip package
- Creates stores with `client.file_search_stores.create()`
- Uploads with `client.file_search_stores.upload_to_file_search_store()`
- Searches with `client.models.generate_content()` + FileSearch tool
- Extracts citations from grounding metadata
- Provides FastAPI endpoint examples

### Document Processor

```
@document-processor Parse and prepare documents from /docs folder
```

- Extracts text from PDFs
- Processes Word documents
- Cleans HTML content
- Handles Markdown files
- Creates batch processing scripts

## Workflow

1. **Prepare Documents**: Use `@document-processor` to parse and clean source documents
2. **Build RAG System**: Use `@google-file-search-ts` (for JS/TS) or `@google-file-search-py` (for Python)
3. **Generate**: Query with Gemini for RAG responses with citations

## Which Agent to Use?

| Your Stack            | Use This Agent            |
| --------------------- | ------------------------- |
| Next.js, Node.js, TS  | `@google-file-search-ts`  |
| React, JavaScript     | `@google-file-search-ts`  |
| FastAPI, Flask, Django| `@google-file-search-py`  |
| Python scripts        | `@google-file-search-py`  |

## Key SDK Methods

### TypeScript (@google/genai)

```typescript
import { GoogleGenAI } from '@google/genai';
const ai = new GoogleGenAI({ apiKey });

// Create store
await ai.fileSearchStores.create({ config: { displayName } });

// Upload + index (single operation)
await ai.fileSearchStores.uploadToFileSearchStore({ file, fileSearchStoreName, config });

// Poll operation
await ai.operations.get({ operation });

// Search with File Search tool
await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: query,
  config: { tools: [{ fileSearch: { fileSearchStoreNames: [storeName] }}] }
});
```

### Python (google-genai)

```python
from google import genai
from google.genai import types
client = genai.Client(api_key=api_key)

# Create store
client.file_search_stores.create(config={"display_name": name})

# Upload + index (single operation)
client.file_search_stores.upload_to_file_search_store(file=path, file_search_store_name=name, config={})

# Poll operation
client.operations.get(operation)

# Search with File Search tool
client.models.generate_content(
    model="gemini-2.5-flash",
    contents=query,
    config=types.GenerateContentConfig(tools=[types.Tool(file_search=types.FileSearch(...))])
)
```

## Skills Auto-Loading

Agents automatically access relevant skills:

- `google-file-search` - File Search API patterns (Python & TypeScript)
- `document-parsers` - Document parsing utilities
- `chunking-strategies` - Chunking configuration
