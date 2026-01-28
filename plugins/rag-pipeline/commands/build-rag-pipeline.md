---
description: Build complete RAG pipeline - initializes if needed, then runs specialized agents for embeddings, vector storage, retrieval, and deployment
argument-hint: <project-name> [--framework <langchain|llamaindex>]
---

# Build Complete RAG Pipeline

**Goal:** Create a production-ready RAG (Retrieval-Augmented Generation) pipeline by orchestrating all specialized agents.

**This command handles everything** - from setup to full pipeline with document processing, embeddings, vector storage, and optimized retrieval.

## Stack (Always Use Latest Versions)

- **LangChain** / **LlamaIndex** - Latest RAG framework
- **OpenAI** / **Google Gemini** - Latest embedding models
- **Pinecone** / **Qdrant** / **Supabase pgvector** - Latest vector DB
- **FastAPI** - Latest for API serving

**IMPORTANT:** Always use the latest versions. Check pip/npm for current versions.

## Arguments

- `$ARGUMENTS` - Project name and optional framework
- `--framework <name>` - RAG framework (langchain, llamaindex)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and framework preference
2. Discover architecture documentation for RAG requirements
3. Analyze document types and volume
4. Plan retrieval strategy based on use cases

### Phase 2: Architecture Design

```
Task("Design RAG architecture", @rag-architect, {
  prompt: "Design RAG pipeline architecture:
    - Analyze document requirements from architecture
    - Select optimal embedding model and dimensions
    - Choose vector database based on scale/features
    - Design retrieval strategy (hybrid, semantic, keyword)
    Create high-level pipeline design."
})
```

### Phase 3: Parallel Agent Execution

```
// Agent 1: Vector Database
Task("Setup vector database", @vector-db-engineer, {
  prompt: "Configure vector database:
    - Set up selected vector DB (Pinecone/Qdrant/pgvector)
    - Create collections with proper dimensions
    - Configure indexes for performance
    - Set up metadata filtering
    Follow architecture requirements."
})

// Agent 2: Embedding Pipeline
Task("Build embedding pipeline", @embedding-specialist, {
  prompt: "Implement embedding generation:
    - Configure embedding model
    - Implement batch embedding
    - Add embedding caching
    - Handle multi-modal embeddings if needed
    Optimize for cost and performance."
})

// Agent 3: Document Processing
Task("Setup document processing", @document-processor, {
  prompt: "Implement document ingestion:
    - Configure document loaders (PDF, web, etc.)
    - Implement chunking strategy
    - Add metadata extraction
    - Handle multi-format documents
    Follow document types from architecture."
})

// Agent 4: Retrieval Optimization
Task("Optimize retrieval", @retrieval-optimizer, {
  prompt: "Implement optimized retrieval:
    - Configure hybrid search (semantic + keyword)
    - Implement re-ranking
    - Add query expansion
    - Configure context compression
    Maximize relevance and accuracy."
})

// Agent 5: Framework Integration
Task("Integrate framework", @langchain-specialist, {
  prompt: "Implement with selected framework:
    - Create RAG chain/pipeline
    - Implement prompt templates
    - Add memory for conversation
    - Configure streaming responses
    Use LangChain or LlamaIndex based on selection."
})
```

### Phase 4: Testing & Deployment

```
// Test pipeline
Task("Test RAG pipeline", @rag-tester, {
  prompt: "Test and evaluate pipeline:
    - Create test document set
    - Run retrieval evaluation
    - Test answer quality
    - Measure latency and throughput
    Report metrics and issues."
})

// Deploy
Task("Deploy pipeline", @rag-deployment-agent, {
  prompt: "Prepare deployment:
    - Create FastAPI endpoints
    - Configure async processing
    - Set up health checks
    - Add usage tracking
    Output deployment configuration."
})
```

### Phase 5: Final Output

**Provide summary:**

- Pipeline architecture
- Vector DB configuration
- Usage examples:

  ```python
  # Query RAG pipeline
  response = rag.query("What are the key features?")

  # Ingest documents
  rag.ingest("./documents/")
  ```

## Utility Commands

- `/rag-pipeline:add-embeddings` - Configure embeddings only
- `/rag-pipeline:add-vector-db` - Set up vector database
- `/rag-pipeline:add-documents` - Add document processing
- `/rag-pipeline:optimize-retrieval` - Tune retrieval
- `/rag-pipeline:add-langchain` - LangChain integration
- `/rag-pipeline:add-llamaindex` - LlamaIndex integration
