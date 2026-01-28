---
description: Build Google File Search powered RAG pipeline - managed retrieval with document processing and chunking
argument-hint: <project-name> [--backend <fastapi|nextjs>]
---

# Build Google File Search RAG Pipeline

**Goal:** Create a production-ready RAG pipeline using Google's managed File Search API with document processing.

**This command handles everything** - document upload, store creation, and retrieval integration.

## Stack (Always Use Latest Versions)

- **Google File Search API** - Managed RAG service (vector storage, retrieval, ranking)
- **Google Store API** - Document storage and management
- **FastAPI** / **Next.js** - API serving
- **Google Gemini** - LLM for generation

**IMPORTANT:** Always use the latest versions. Check for current API versions.

## Why Google File Search?

- **Fully Managed** - No vector DB setup, no embedding management
- **Automatic Chunking** - Intelligent document splitting
- **Built-in Ranking** - Optimized retrieval out of the box
- **Scales Automatically** - No infrastructure management
- **Cost Effective** - Pay per use, no idle costs

## Arguments

- `$ARGUMENTS` - Project name and optional backend
- `--backend <name>` - Backend framework (fastapi, nextjs)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and backend
2. Check for Google Cloud credentials
3. Analyze document requirements
4. Plan store structure

### Phase 2: Document Processing

```
Task("Process documents for upload", @document-processor, {
  prompt: "Prepare documents for Google File Search:
    - Parse documents (PDF, text, markdown, etc.)
    - Extract and validate content
    - Prepare metadata for filtering
    - Organize by collection/topic
    Output files ready for upload."
})
```

### Phase 3: Google File Search Setup

```
Task("Setup Google File Search store", @google-file-search-specialist, {
  prompt: "Configure Google File Search:
    - Create file store with proper settings
    - Upload processed documents
    - Configure chunking parameters
    - Set up metadata filtering
    - Test retrieval quality
    Follow Google best practices."
})
```

### Phase 4: API Integration

```
Task("Build RAG API endpoint", @google-file-search-specialist, {
  prompt: "Create retrieval API:
    - Build search endpoint using File Search API
    - Integrate with Gemini for generation
    - Add streaming responses
    - Implement conversation context
    - Add source citations
    Use selected backend framework."
})
```

## Project Structure (FastAPI)

```
{project-name}/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app
│   ├── config.py            # Settings
│   ├── routers/
│   │   └── rag.py           # RAG endpoints
│   └── services/
│       ├── file_search.py   # Google File Search client
│       ├── document.py      # Document processing
│       └── generation.py    # Gemini integration
├── documents/               # Source documents
├── scripts/
│   └── upload_documents.py  # Bulk upload script
├── .env.example
├── requirements.txt
└── README.md
```

## Project Structure (Next.js)

```
{project-name}/
├── app/
│   ├── api/
│   │   └── rag/
│   │       └── route.ts     # RAG API route
│   └── page.tsx             # Chat interface
├── lib/
│   ├── file-search.ts       # Google File Search client
│   └── generation.ts        # Gemini integration
├── documents/               # Source documents
├── scripts/
│   └── upload-documents.ts  # Bulk upload script
├── .env.example
├── package.json
└── README.md
```

## Key Implementation Patterns

### Google File Search Client (Python)

```python
from google import genai
from google.genai import types

client = genai.Client()

# Create a file store
store = client.files.create_store(
    display_name="my-knowledge-base",
    description="RAG document store"
)

# Upload documents
file = client.files.upload(
    path="document.pdf",
    config=types.UploadFileConfig(
        store_id=store.id,
        metadata={"category": "technical"}
    )
)

# Search
results = client.files.search(
    store_id=store.id,
    query="How does authentication work?",
    top_k=5
)
```

### RAG with Gemini (Python)

```python
# Combine retrieval with generation
def rag_query(question: str, store_id: str) -> str:
    # Retrieve relevant chunks
    results = client.files.search(
        store_id=store_id,
        query=question,
        top_k=5
    )
    
    # Build context from results
    context = "\n\n".join([r.content for r in results.results])
    
    # Generate response with Gemini
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=f"""Based on the following context, answer the question.

Context:
{context}

Question: {question}

Answer:"""
    )
    
    return response.text
```

## Environment Variables

```bash
# .env.example
GOOGLE_API_KEY=your_google_api_key_here
GOOGLE_CLOUD_PROJECT=your_project_id_here
FILE_STORE_ID=your_store_id_here
```

## Security Requirements

**CRITICAL:** Never hardcode API keys.
- ✅ Use environment variables
- ✅ Create `.env.example` with placeholders
- ❌ NEVER commit real credentials

## Post-Build Validation

After building, verify:
1. Documents uploaded successfully
2. Search returns relevant results
3. Generation includes proper citations
4. Streaming responses work
5. Error handling is robust
