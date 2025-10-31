---
name: rag-implementation
description: RAG (Retrieval Augmented Generation) implementation patterns including document chunking, embedding generation, vector database integration, semantic search, and RAG pipelines. Use when building RAG systems, implementing semantic search, creating knowledge bases, or when user mentions RAG, embeddings, vector database, retrieval, document chunking, or knowledge retrieval.
allowed-tools: Read, Write, Bash, Grep, Glob
---

# RAG Implementation Patterns

**Purpose:** Provide complete RAG pipeline templates, chunking strategies, vector database schemas, and retrieval patterns for building production-ready RAG systems with Vercel AI SDK.

**Activation Triggers:**
- Building RAG (Retrieval Augmented Generation) systems
- Implementing semantic search functionality
- Creating AI-powered knowledge bases
- Document ingestion and embedding generation
- Vector database integration
- Hybrid search (vector + keyword) implementation

**Key Resources:**
- `templates/rag-pipeline.ts` - Complete RAG pipeline template
- `templates/vector-db-schemas/` - Database schemas for Pinecone, Chroma, pgvector, Weaviate
- `templates/chunking-strategies.ts` - Document chunking implementations
- `templates/retrieval-patterns.ts` - Semantic search and hybrid search patterns
- `scripts/chunk-documents.sh` - Document chunking utility
- `scripts/generate-embeddings.sh` - Batch embedding generation
- `scripts/validate-rag-setup.sh` - Validate RAG configuration
- `examples/` - Complete RAG implementations (chatbot, Q&A, search)

## Core RAG Pipeline

### 1. Document Ingestion → Chunking → Embedding → Storage → Retrieval → Generation

**Template:** `templates/rag-pipeline.ts`

**Workflow:**
```typescript
// 1. Ingest documents
const documents = await loadDocuments()

// 2. Chunk documents
const chunks = await chunkDocuments(documents, {
  chunkSize: 1000
  overlap: 200
  strategy: 'semantic'
})

// 3. Generate embeddings
const embeddings = await embedMany({
  model: openai.embedding('text-embedding-3-small')
  values: chunks.map(c => c.text)
})

// 4. Store in vector DB
await vectorDB.upsert(chunks.map((chunk, i) => ({
  id: chunk.id
  embedding: embeddings.embeddings[i]
  metadata: chunk.metadata
})))

// 5. Retrieve relevant chunks
const query = await embed({
  model: openai.embedding('text-embedding-3-small')
  value: userQuestion
})

const results = await vectorDB.query({
  vector: query.embedding
  topK: 5
})

// 6. Generate response with context
const response = await generateText({
  model: openai('gpt-4o')
  messages: [
    {
      role: 'system'
      content: `Answer based on this context:\n\n${results.map(r => r.text).join('\n\n')}`
    }
    { role: 'user', content: userQuestion }
  ]
})
```

## Chunking Strategies

### 1. Fixed-Size Chunking

**When to use:** Simple documents, consistent structure

**Template:** `templates/chunking-strategies.ts#fixedSize`

```typescript
function chunkByFixedSize(text: string, chunkSize: number, overlap: number) {
  const chunks = []
  for (let i = 0; i < text.length; i += chunkSize - overlap) {
    chunks.push(text.slice(i, i + chunkSize))
  }
  return chunks
}
```

**Best for:** Articles, blog posts, documentation

### 2. Semantic Chunking

**When to use:** Preserve meaning and context

**Template:** `templates/chunking-strategies.ts#semantic`

```typescript
function chunkBySemantic(text: string) {
  // Split on paragraphs, headings, or natural breaks
  const sections = text.split(/\n\n+/)
  const chunks = []

  let currentChunk = ''
  for (const section of sections) {
    if ((currentChunk + section).length > 1000) {
      if (currentChunk) chunks.push(currentChunk.trim())
      currentChunk = section
    } else {
      currentChunk += '\n\n' + section
    }
  }
  if (currentChunk) chunks.push(currentChunk.trim())

  return chunks
}
```

**Best for:** Books, research papers, structured content

### 3. Recursive Chunking

**When to use:** Hierarchical documents with sections/subsections

**Template:** `templates/chunking-strategies.ts#recursive`

**Best for:** Technical docs, manuals, legal documents

## Vector Database Integration

### Supported Databases

**1. Pinecone (Fully Managed)**

**Template:** `templates/vector-db-schemas/pinecone-schema.ts`

```typescript
import { Pinecone } from '@pinecone-database/pinecone'

const pinecone = new Pinecone({
  apiKey: process.env.PINECONE_API_KEY!
})

const index = pinecone.index('knowledge-base')

// Upsert embeddings
await index.upsert([
  {
    id: 'doc-1-chunk-1'
    values: embedding
    metadata: {
      text: chunk.text
      source: chunk.source
      timestamp: Date.now()
    }
  }
])

// Query
const results = await index.query({
  vector: queryEmbedding
  topK: 5
  includeMetadata: true
})
```

**2. Chroma (Open Source)**

**Template:** `templates/vector-db-schemas/chroma-schema.ts`

**Best for:** Local development, prototyping

**3. pgvector (Postgres Extension)**

**Template:** `templates/vector-db-schemas/pgvector-schema.sql`

**Best for:** Existing Postgres infrastructure, cost-effective

**4. Weaviate (Open Source/Cloud)**

**Template:** `templates/vector-db-schemas/weaviate-schema.ts`

**Best for:** Advanced filtering, hybrid search

## Retrieval Patterns

### 1. Simple Semantic Search

**Template:** `templates/retrieval-patterns.ts#simpleSearch`

```typescript
async function semanticSearch(query: string, topK: number = 5) {
  // Embed query
  const { embedding } = await embed({
    model: openai.embedding('text-embedding-3-small')
    value: query
  })

  // Search vector DB
  const results = await vectorDB.query({
    vector: embedding
    topK
  })

  return results
}
```

### 2. Hybrid Search (Vector + Keyword)

**Template:** `templates/retrieval-patterns.ts#hybridSearch`

```typescript
async function hybridSearch(query: string, topK: number = 10) {
  // Vector search
  const vectorResults = await semanticSearch(query, topK)

  // Keyword search (BM25 or full-text)
  const keywordResults = await fullTextSearch(query, topK)

  // Combine and re-rank
  const combined = rerank(vectorResults, keywordResults)

  return combined.slice(0, topK)
}
```

**Best practice:** Use hybrid search for better recall

### 3. Re-Ranking

**Template:** `templates/retrieval-patterns.ts#reranking`

```typescript
async function rerankResults(query: string, results: any[]) {
  // Use cross-encoder or LLM for re-ranking
  const reranked = await generateObject({
    model: openai('gpt-4o')
    schema: z.object({
      rankedIds: z.array(z.string())
    })
    messages: [
      {
        role: 'system'
        content: 'Rank these documents by relevance to the query.'
      }
      {
        role: 'user'
        content: `Query: ${query}\n\nDocuments: ${JSON.stringify(results)}`
      }
    ]
  })

  return reranked.object.rankedIds.map(id =>
    results.find(r => r.id === id)
  )
}
```

## Implementation Workflow

### Step 1: Validate RAG Setup

```bash
# Check dependencies and configuration
./scripts/validate-rag-setup.sh
```

**Checks:**
- AI SDK installation
- Vector database client installed
- Environment variables configured
- Embedding model accessible

### Step 2: Choose Chunking Strategy

**Decision tree:**
- Uniform documents → Fixed-size chunking
- Natural sections → Semantic chunking
- Hierarchical structure → Recursive chunking
- Mixed content → Hybrid approach

### Step 3: Select Vector Database

**Considerations:**
- **Pinecone**: Best for production, fully managed, higher cost
- **Chroma**: Best for prototypes, local development, free
- **pgvector**: Best if using Postgres, cost-effective
- **Weaviate**: Best for complex filtering, hybrid search

### Step 4: Implement Embedding Generation

```bash
# Batch generate embeddings
./scripts/generate-embeddings.sh ./documents/ openai
```

**Optimization:**
- Use `embedMany` for batch processing
- Implement rate limiting for API quotas
- Cache embeddings to avoid re-generation
- Use cheaper models for prototyping

### Step 5: Build Retrieval Pipeline

**Use template:** `templates/retrieval-patterns.ts`

**Customize:**
1. Set topK (typically 3-10 chunks)
2. Add metadata filtering if needed
3. Implement re-ranking for better results
4. Add hybrid search for improved recall

### Step 6: Integrate with Generation

**Pattern:**
```typescript
const context = retrievedChunks.map(chunk => chunk.text).join('\n\n')

const response = await generateText({
  model: openai('gpt-4o')
  messages: [
    {
      role: 'system'
      content: `Answer based on this context. If the answer is not in the context, say so.\n\nContext:\n${context}`
    }
    { role: 'user', content: query }
  ]
})
```

## Optimization Strategies

### 1. Chunk Size Optimization

**Guideline:**
- Small chunks (200-500 tokens): Better precision, more API calls
- Medium chunks (500-1000 tokens): Balanced
- Large chunks (1000-2000 tokens): Better context, less precision

**Test with your data:** Use `scripts/chunk-documents.sh` with different sizes

### 2. Embedding Model Selection

**OpenAI text-embedding-3-small:**
- Dimensions: 1536
- Cost: $0.02 per 1M tokens
- Best for: Most use cases

**OpenAI text-embedding-3-large:**
- Dimensions: 3072
- Cost: $0.13 per 1M tokens
- Best for: Higher accuracy needs

**Cohere embed-english-v3.0:**
- Dimensions: 1024 (configurable)
- Cost: $0.10 per 1M tokens
- Best for: Semantic search, compression support

### 3. Query Optimization

**Multi-query retrieval:**
```typescript
// Generate multiple query variations
const variations = await generateText({
  model: openai('gpt-4o')
  messages: [{
    role: 'user'
    content: `Generate 3 variations of this query: "${query}"`
  }]
})

// Search with all variations and combine results
const allResults = await Promise.all(
  variations.map(v => semanticSearch(v))
)

const combined = deduplicateAndRank(allResults.flat())
```

## Production Best Practices

### 1. Error Handling

```typescript
try {
  const results = await ragPipeline(query)
  return results
} catch (error) {
  if (error.code === 'RATE_LIMIT') {
    // Implement exponential backoff
  } else if (error.code === 'VECTOR_DB_ERROR') {
    // Fallback to keyword search
  }
  throw error
}
```

### 2. Caching

```typescript
// Cache embeddings
const cache = new Map<string, number[]>()

async function getEmbedding(text: string) {
  if (cache.has(text)) {
    return cache.get(text)!
  }

  const { embedding } = await embed({ model, value: text })
  cache.set(text, embedding)
  return embedding
}
```

### 3. Monitoring

```typescript
// Track RAG metrics
metrics.record({
  operation: 'rag_query'
  latency: Date.now() - startTime
  chunksRetrieved: results.length
  vectorDBCalls: 1
  embeddingCost: calculateCost(query.length)
})
```

## Common RAG Patterns

### 1. Conversational RAG

**Example:** `examples/conversational-rag.ts`

Maintains conversation context while retrieving relevant information

### 2. Multi-Document RAG

**Example:** `examples/multi-document-rag.ts`

Retrieves from multiple knowledge bases

### 3. Agentic RAG

**Example:** `examples/agentic-rag.ts`

Uses tools to decide when and what to retrieve

## Resources

**Scripts:**
- `chunk-documents.sh` - Chunk documents with different strategies
- `generate-embeddings.sh` - Batch embedding generation
- `validate-rag-setup.sh` - Validate configuration

**Templates:**
- `rag-pipeline.ts` - Complete RAG implementation
- `chunking-strategies.ts` - All chunking approaches
- `retrieval-patterns.ts` - Search and re-ranking patterns
- `vector-db-schemas/` - Database-specific schemas

**Examples:**
- `conversational-rag.ts` - Chat with memory
- `multi-document-rag.ts` - Multiple sources
- `agentic-rag.ts` - Tool-based retrieval

---

**Supported Vector DBs:** Pinecone, Chroma, pgvector, Weaviate, Qdrant
**SDK Version:** Vercel AI SDK 5+
**Embedding Models:** OpenAI, Cohere, Custom

**Best Practice:** Start with simple semantic search, add complexity as needed
