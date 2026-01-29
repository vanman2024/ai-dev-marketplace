---
description: Add a specific feature to an existing RAG pipeline project. Features include document, search, embeddings, vectordb.
argument-hint: <feature> [options]
---

# Add RAG Pipeline Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Document Features

**If `$0` = "document":**

```
Task(document-processor) Add DOCUMENT processing.

Requirements:
- Document type: $1 (pdf, markdown, html, all - default: all)
- Processing: $2 (chunking, metadata, embeddings - default: all)
- Set up document loader
- Configure chunking strategy
- Add metadata extraction
- Create processing pipeline
```

### Search Features

**If `$0` = "search":**

```
Task(google-file-search-specialist) Add SEARCH feature.

Requirements:
- Search type: $1 (semantic, hybrid, keyword - default: semantic)
- Configure search endpoint
- Set up query processing
- Add relevance scoring
- Configure result ranking
```

### Embedding Features

**If `$0` = "embeddings":**

```
Task(document-processor) Add EMBEDDINGS.

Requirements:
- Model: $1 (openai, huggingface, cohere - default: openai)
- Dimensions: $2 (vector dimensions - default: 1536)
- Set up embedding model
- Configure batch processing
- Add caching
```

### Vector Database Features

**If `$0` = "vectordb":**

```
Task(document-processor) Add VECTOR DATABASE.

Requirements:
- Database: $1 (pinecone, supabase, qdrant, chroma - default: supabase)
- Configure vector store
- Set up indexing
- Add search functions
- Configure metadata filters
```

---

## Usage Examples

```bash
# Documents
/rag-pipeline:add document pdf chunking
/rag-pipeline:add document markdown all

# Search
/rag-pipeline:add search semantic
/rag-pipeline:add search hybrid

# Embeddings
/rag-pipeline:add embeddings openai 1536
/rag-pipeline:add embeddings huggingface 768

# Vector Database
/rag-pipeline:add vectordb supabase
/rag-pipeline:add vectordb pinecone
```

---

## Feature Reference

| Feature      | Agent              | $1 Options                      | Description         |
| ------------ | ------------------ | ------------------------------- | ------------------- |
| `document`   | document-processor | pdf/markdown/html/all           | Document processing |
| `search`     | file-search        | semantic/hybrid/keyword         | Search feature      |
| `embeddings` | document-processor | openai/huggingface/cohere       | Embedding model     |
| `vectordb`   | document-processor | pinecone/supabase/qdrant/chroma | Vector database     |
