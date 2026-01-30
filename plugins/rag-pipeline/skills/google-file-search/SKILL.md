---
name: google-file-search
description: Google File Search API patterns for managed RAG with Gemini. Covers both TypeScript (@google/genai) and Python (google-genai) SDKs. Use when building File Search integrations, implementing RAG with Google AI, or when user mentions Google File Search, Gemini RAG, document indexing, or semantic search.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# Google File Search

Comprehensive skill for implementing Google File Search API with Gemini models for Retrieval-Augmented Generation (RAG).

## Overview

Google File Search provides managed RAG capabilities through:
- Automatic document chunking and embedding generation
- Semantic search across multiple document types
- Metadata-based filtering for targeted retrieval
- Grounding citations showing source documents
- Persistent storage with file search stores
- Integration with Gemini 2.5 models

**Two Official SDKs are available:**
- **TypeScript/JavaScript:** `@google/genai` npm package
- **Python:** `google-genai` pip package

## CRITICAL: Use Official SDKs Only

Do NOT use manual REST API calls or deprecated packages. Always use the official SDKs.

### TypeScript/JavaScript
```bash
npm install @google/genai
```

### Python
```bash
pip install google-genai
```

## Security: API Key Handling

**CRITICAL:** Never hardcode API keys.

```typescript
// ✅ CORRECT - TypeScript
const ai = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY! });

// ❌ WRONG
const ai = new GoogleGenAI({ apiKey: 'sk-abc123...' });
```

```python
# ✅ CORRECT - Python
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

# ❌ WRONG
client = genai.Client(api_key="sk-abc123...")
```

Get API keys from: https://aistudio.google.com/apikey

## TypeScript Implementation

### Initialize Client

```typescript
import { GoogleGenAI } from '@google/genai';

const ai = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY! });
```

### Create File Search Store

```typescript
const store = await ai.fileSearchStores.create({
  config: { displayName: 'my-knowledge-base' }
});
console.log(`Store created: ${store.name}`);
```

### Upload and Index Documents

**Use `uploadToFileSearchStore()` which uploads AND indexes in one operation.**

```typescript
async function uploadFile(storeName: string, filePath: string, filename: string) {
  let operation = await ai.fileSearchStores.uploadToFileSearchStore({
    file: filePath,
    fileSearchStoreName: storeName,
    config: { displayName: filename }
  });

  // Wait for indexing to complete
  while (!operation.done) {
    await new Promise(resolve => setTimeout(resolve, 2000));
    operation = await ai.operations.get({ operation });
  }
  console.log(`Indexed: ${filename}`);
}
```

### Semantic Search

```typescript
async function search(storeName: string, query: string) {
  const response = await ai.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: query,
    config: {
      tools: [{
        fileSearch: {
          fileSearchStoreNames: [storeName]
        }
      }]
    }
  });

  const sources = response.candidates?.[0]?.groundingMetadata?.groundingChunks?.map((c: any) => ({
    uri: c.retrievedContext?.uri,
    title: c.retrievedContext?.title
  })) || [];

  return { answer: response.text, sources };
}
```

### Next.js API Route Example

```typescript
// app/api/rag/route.ts
import { GoogleGenAI } from '@google/genai';
import { NextResponse } from 'next/server';

const ai = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY! });

export async function POST(request: Request) {
  const { query, storeId } = await request.json();

  const response = await ai.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: query,
    config: {
      tools: [{ fileSearch: { fileSearchStoreNames: [storeId] }}],
      systemInstruction: 'Answer based on the documents. Cite sources.'
    }
  });

  const sources = response.candidates?.[0]?.groundingMetadata?.groundingChunks?.map((c: any) => ({
    uri: c.retrievedContext?.uri,
    title: c.retrievedContext?.title
  })) || [];

  return NextResponse.json({ answer: response.text, sources });
}
```

## Python Implementation

### Initialize Client

```python
import os
from google import genai
from google.genai import types

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
```

### Create File Search Store

```python
store = client.file_search_stores.create(
    config={"display_name": "my-knowledge-base"}
)
print(f"Store created: {store.name}")
```

### Upload and Index Documents

**Use `upload_to_file_search_store()` which uploads AND indexes in one operation.**

```python
import time
from pathlib import Path

def upload_file(store_name: str, file_path: str, filename: str = None):
    path = Path(file_path)

    operation = client.file_search_stores.upload_to_file_search_store(
        file=str(path),
        file_search_store_name=store_name,
        config={"display_name": filename or path.name}
    )

    # Wait for indexing to complete
    while not operation.done:
        time.sleep(2)
        operation = client.operations.get(operation)

    print(f"Indexed: {path.name}")
```

### Semantic Search

```python
def search(store_name: str, query: str, model: str = "gemini-2.5-flash"):
    file_search = types.FileSearch(file_search_store_names=[store_name])
    tool = types.Tool(file_search=file_search)

    response = client.models.generate_content(
        model=model,
        contents=query,
        config=types.GenerateContentConfig(tools=[tool])
    )

    sources = []
    if response.candidates:
        gm = getattr(response.candidates[0], 'grounding_metadata', None)
        if gm and hasattr(gm, 'grounding_chunks'):
            for chunk in gm.grounding_chunks:
                rc = getattr(chunk, 'retrieved_context', None)
                if rc:
                    sources.append({
                        "uri": getattr(rc, 'uri', ''),
                        "title": getattr(rc, 'title', '')
                    })

    return {"answer": response.text, "sources": sources}
```

### FastAPI Endpoint Example

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google import genai
from google.genai import types
import os

app = FastAPI()
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

class RAGQuery(BaseModel):
    query: str
    store_id: str

@app.post("/rag/search")
async def rag_search(request: RAGQuery):
    try:
        file_search = types.FileSearch(file_search_store_names=[request.store_id])
        tool = types.Tool(file_search=file_search)

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=request.query,
            config=types.GenerateContentConfig(tools=[tool])
        )

        sources = []
        if response.candidates:
            gm = getattr(response.candidates[0], 'grounding_metadata', None)
            if gm and hasattr(gm, 'grounding_chunks'):
                for chunk in gm.grounding_chunks:
                    rc = getattr(chunk, 'retrieved_context', None)
                    if rc:
                        sources.append({
                            "uri": getattr(rc, 'uri', ''),
                            "title": getattr(rc, 'title', '')
                        })

        return {"answer": response.text, "sources": sources}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

## Supported Models

- **gemini-2.5-flash**: Fast model for quick responses (RECOMMENDED)
- **gemini-2.5-pro**: Production model for complex reasoning

## Supported File Types

**Documents:** PDF, DOCX, ODT, PPTX, XLSX, CSV, TXT, MD
**Code:** Python, JavaScript, Java, TypeScript, Go, Rust, SQL
**Data:** JSON, XML, YAML, HTML
**Archives:** ZIP (automatically extracted)

Over 100 MIME types supported.

## Storage Limits

**Per-Document:**
- Maximum file size: 100 MB
- Recommended store size: Under 20 GB

**Total Storage by Tier:**
- Free: 1 GB
- Tier 1: 10 GB
- Tier 2: 100 GB
- Tier 3: 1 TB

## Chunking Configuration

### TypeScript
```typescript
await ai.fileSearchStores.uploadToFileSearchStore({
  file: filePath,
  fileSearchStoreName: storeName,
  config: {
    displayName: filename,
    chunkingConfig: {
      whiteSpaceConfig: {
        maxTokensPerChunk: 200,
        maxOverlapTokens: 20
      }
    }
  }
});
```

### Python
```python
client.file_search_stores.upload_to_file_search_store(
    file=file_path,
    file_search_store_name=store_name,
    config={
        "display_name": filename,
        "chunking_config": {
            "white_space_config": {
                "max_tokens_per_chunk": 200,
                "max_overlap_tokens": 20
            }
        }
    }
)
```

## Metadata Filtering

### Adding Metadata (TypeScript)
```typescript
config: {
  displayName: filename,
  customMetadata: [
    { key: 'author', stringValue: 'John Doe' },
    { key: 'year', numericValue: 2024 }
  ]
}
```

### Adding Metadata (Python)
```python
config={
    "display_name": filename,
    "custom_metadata": [
        {"key": "author", "string_value": "John Doe"},
        {"key": "year", "numeric_value": 2024}
    ]
}
```

### Filtering Queries (Python)
```python
file_search = types.FileSearch(
    file_search_store_names=[store_name]
)
file_search.metadata_filter = 'author="John Doe" AND year >= 2024'
```

## Best Practices

1. **Chunk Size Optimization**
   - Technical docs: 300-500 tokens
   - General content: 200-300 tokens
   - Code: 100-200 tokens
   - Use overlap for context preservation

2. **Metadata Strategy**
   - Add author, date, category during upload
   - Use consistent naming conventions
   - Plan filtering needs upfront

3. **Store Organization**
   - Separate stores by domain/project
   - Keep stores under 20 GB for optimal retrieval
   - Name stores descriptively

4. **Citation Handling**
   - Always extract grounding metadata
   - Display sources to users
   - Enable fact-checking workflows

## Troubleshooting

**Issue: Files not uploading**
- Check file size (max 100 MB)
- Verify file type is supported
- Ensure API key has correct permissions

**Issue: Poor search results**
- Adjust chunking configuration
- Add relevant metadata for filtering
- Try different chunk sizes

**Issue: Missing citations**
- Check response for grounding_metadata
- Ensure store has indexed documents
- Verify model supports grounding

## Available Templates

- `templates/typescript-client.ts` - Complete TypeScript client
- `templates/python-client.py` - Complete Python client
- `templates/store-config.json` - Store configuration
- `templates/chunking-config.json` - Chunking settings
- `templates/env.example` - Environment variables

## References

- **Official Docs**: https://ai.google.dev/gemini-api/docs/file-search
- **API Keys**: https://aistudio.google.com/apikey
- **Filter Syntax**: https://google.aip.dev/160

## Version

**Skill Version:** 2.0.0
**Last Updated:** 2026-01-30
**Compatible With:** Gemini 2.5 Pro/Flash, @google/genai (TS), google-genai (Python)
