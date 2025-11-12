# Basic File Search Setup

A simple walkthrough for getting started with Google File Search API.

## Overview

This example demonstrates:
- Creating your first file search store
- Uploading a single document
- Performing basic semantic search
- Extracting grounding citations

**Time to complete:** ~10 minutes

## Prerequisites

1. **Google AI API Key**
   - Get from: https://aistudio.google.com/apikey
   - Set environment variable: `export GOOGLE_API_KEY=your_google_api_key_here`

2. **Python Environment**
   ```bash
   pip install google-genai
   ```

3. **Sample Document**
   - Any PDF, DOCX, TXT, or supported format
   - Maximum 100 MB per file

## Step 1: Create a File Search Store

Stores are containers for indexed documents. Create one for your documents:

```python
from google import genai

# Initialize client
client = genai.Client(api_key="your_google_api_key_here")

# Create store
store = client.file_search_stores.create(
    config={"display_name": "My First RAG Store"}
)

print(f"Store created: {store.name}")
# Save this ID - you'll need it for uploads and searches
```

**Or use the script:**
```bash
python scripts/setup_file_search.py --name "My First RAG Store"
```

Output:
```
✅ Store created successfully!
   Store ID: fileSearchStores/abc123xyz
   Display Name: My First RAG Store
💾 Store info saved to: .env.file-search

To use this store, source the file:
   source .env.file-search
```

## Step 2: Upload a Document

Upload your first document to the store:

```python
import time

# Upload and index
operation = client.file_search_stores.upload_to_file_search_store(
    file="./my-document.pdf",
    file_search_store_name=store.name,
    config={"display_name": "My Document"}
)

# Wait for indexing to complete
while not operation.done:
    time.sleep(2)
    operation = client.operations.get(operation)

print("Document indexed successfully!")
```

**Or use the script:**
```bash
# Source the store config first
source .env.file-search

# Upload document
python scripts/upload_documents.py --file ./my-document.pdf
```

Output:
```
📤 Uploading: my-document.pdf
   ⏳ Indexing...
   ✅ Uploaded and indexed: my-document.pdf

📊 Upload Summary:
   ✅ Successful: 1
   ❌ Failed: 0
   📈 Total: 1
```

## Step 3: Perform Semantic Search

Query your indexed documents using natural language:

```python
from google.genai import types

# Create file search tool
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="What are the main topics covered?",
    config=types.GenerateContentConfig(
        tools=[
            types.Tool(
                file_search=types.FileSearch(
                    file_search_store_names=[store.name]
                )
            )
        ]
    )
)

print(response.text)
```

**Or use the script:**
```bash
python scripts/search_query.py --query "What are the main topics covered?"
```

Output:
```
🔍 Searching store: fileSearchStores/abc123xyz
   Query: What are the main topics covered?

💬 Response:
────────────────────────────────────────────────────────────────────────────────
Based on the document, the main topics covered are:

1. Introduction to RAG systems
2. Document chunking strategies
3. Embedding generation
4. Vector similarity search
5. Grounding and citation handling
────────────────────────────────────────────────────────────────────────────────

📚 Source Citations:
   [1] Chunk ID: chunk_abc123
       Snippet: RAG (Retrieval-Augmented Generation) combines document retrieval with language model generation...
```

## Step 4: Extract Citations

Verify AI responses against source documents:

```python
# Get grounding metadata from response
if response.candidates and len(response.candidates) > 0:
    grounding_metadata = response.candidates[0].grounding_metadata

    if hasattr(grounding_metadata, 'grounding_chunks'):
        print("\n📚 Citations:")
        for i, chunk in enumerate(grounding_metadata.grounding_chunks, 1):
            print(f"\n[{i}] Chunk ID: {chunk.chunk_id}")
            print(f"    Content: {chunk.content[:100]}...")
```

**Or use the script:**
```bash
python scripts/extract_citations.py --store $GOOGLE_FILE_SEARCH_STORE_ID \
    --query "What are the main topics?" \
    --extract
```

Output:
```
📚 Grounding Citations:

[1] Citation:
    chunk_id: chunk_abc123
    content: RAG (Retrieval-Augmented Generation) combines document retrieval with language model generation to provide fact-based responses...
    score: 0.95

[2] Citation:
    chunk_id: chunk_def456
    content: Document chunking is the process of dividing large texts into smaller, semantically meaningful segments...
    score: 0.89
```

## Complete Example Script

Save this as `basic_example.py`:

```python
#!/usr/bin/env python3
"""Basic File Search Example"""

import os
import time
from google import genai
from google.genai import types

# SECURITY: Read API key from environment
api_key = os.getenv("GOOGLE_API_KEY")
if not api_key:
    raise ValueError("GOOGLE_API_KEY environment variable not set")

# Initialize client
client = genai.Client(api_key=api_key)

# Step 1: Create store
print("1️⃣ Creating file search store...")
store = client.file_search_stores.create(
    config={"display_name": "Basic Example Store"}
)
print(f"   ✅ Created: {store.name}\n")

# Step 2: Upload document (replace with your file)
print("2️⃣ Uploading document...")
# operation = client.file_search_stores.upload_to_file_search_store(
#     file="./your-document.pdf",
#     file_search_store_name=store.name,
#     config={"display_name": "Your Document"}
# )
# while not operation.done:
#     time.sleep(2)
#     operation = client.operations.get(operation)
# print("   ✅ Uploaded and indexed\n")

# Step 3: Search
print("3️⃣ Searching documents...")
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="What are the key points?",
    config=types.GenerateContentConfig(
        tools=[
            types.Tool(
                file_search=types.FileSearch(
                    file_search_store_names=[store.name]
                )
            )
        ]
    )
)
print(f"   💬 Response:\n   {response.text}\n")

# Step 4: Extract citations
print("4️⃣ Extracting citations...")
if response.candidates:
    grounding_metadata = response.candidates[0].grounding_metadata
    if hasattr(grounding_metadata, 'grounding_chunks'):
        print(f"   📚 Found {len(grounding_metadata.grounding_chunks)} citation(s)")

print("\n✅ Example complete!")

# Cleanup (uncomment to delete store)
# client.file_search_stores.delete(name=store.name, config={"force": True})
```

Run it:
```bash
python basic_example.py
```

## Next Steps

Once you're comfortable with basic operations, explore:

1. **[Advanced Chunking](./advanced-chunking.md)** - Optimize chunk sizes for your content
2. **[Metadata Filtering](./metadata-filtering.md)** - Add metadata to filter searches
3. **[Grounding Citations](./grounding-citations.md)** - Build citation UIs
4. **[Multi-Store Management](./multi-store.md)** - Organize documents across stores

## Common Issues

### API Key Not Set
```
❌ Error: GOOGLE_API_KEY environment variable not set
```
**Solution:** Export your API key: `export GOOGLE_API_KEY=your_key_here`

### File Too Large
```
❌ Error: File too large: 150.5MB (max: 100MB)
```
**Solution:** Split large documents or compress them before uploading

### Store Not Found
```
❌ Error: Store not found: fileSearchStores/invalid-id
```
**Solution:** Verify store ID is correct. List stores with:
```bash
python scripts/validate_setup.py --list-stores
```

### No Search Results
If search returns no relevant results:
1. Verify documents were indexed successfully
2. Try broader queries
3. Check chunking configuration (may be too small/large)
4. Ensure documents contain relevant content

## Tips for Better Results

1. **Query Phrasing**: Use natural language questions
   - Good: "What are the benefits of RAG systems?"
   - Bad: "RAG benefits"

2. **Document Preparation**: Use clear, well-structured documents
   - PDFs with selectable text (not scanned images)
   - Markdown or plain text for best results
   - Clean formatting without excessive special characters

3. **Storage Management**: Keep stores organized
   - One store per domain or project
   - Clear naming conventions
   - Regular cleanup of unused stores

4. **Cost Optimization**: Minimize indexing costs
   - Index documents once, query many times
   - Use appropriate chunk sizes (default 200 tokens is good)
   - Monitor storage quotas

## Resources

- **Official Docs**: https://ai.google.dev/gemini-api/docs/file-search
- **API Keys**: https://aistudio.google.com/apikey
- **Python SDK**: https://pypi.org/project/google-genai/
- **Support**: https://ai.google.dev/gemini-api/docs/support

---

**Congratulations!** You've completed the basic File Search setup. You're now ready to build more advanced RAG applications.
