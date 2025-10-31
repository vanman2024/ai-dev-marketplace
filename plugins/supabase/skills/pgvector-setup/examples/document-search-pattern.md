# Complete Document Search Implementation

A production-ready pattern for implementing semantic document search with pgvector in Supabase.

## Architecture Overview

```
┌─────────────┐
│   Client    │
│ Application │
└──────┬──────┘
       │
       │ 1. Upload document
       ▼
┌─────────────────────────────────────┐
│   Supabase Edge Function           │
│   - Chunk document                  │
│   - Generate embeddings             │
│   - Store in database               │
└──────┬──────────────────────────────┘
       │
       │ 2. Store chunks + embeddings
       ▼
┌─────────────────────────────────────┐
│   PostgreSQL + pgvector             │
│   - documents table                 │
│   - document_chunks table           │
│   - HNSW index                      │
└──────┬──────────────────────────────┘
       │
       │ 3. Search query
       ▼
┌─────────────────────────────────────┐
│   Vector Search Function            │
│   - Semantic similarity             │
│   - Hybrid search (optional)        │
│   - Return ranked results           │
└─────────────────────────────────────┘
```

## Database Schema

```sql
-- Main documents table
CREATE TABLE documents (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
    title TEXT NOT NULL
    source_url TEXT
    file_name TEXT
    file_size INTEGER
    content_type TEXT
    metadata JSONB DEFAULT '{}'::jsonb
    status TEXT DEFAULT 'processing'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Document chunks table with embeddings
CREATE TABLE document_chunks (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    document_id BIGINT NOT NULL REFERENCES documents(id) ON DELETE CASCADE
    chunk_index INTEGER NOT NULL
    content TEXT NOT NULL
    embedding vector(1536), -- OpenAI text-embedding-3-small
    token_count INTEGER
    -- For hybrid search
    fts tsvector GENERATED ALWAYS AS (to_tsvector('english', content)) STORED
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    UNIQUE(document_id, chunk_index)
);

-- Indexes
CREATE INDEX document_chunks_document_id_idx ON document_chunks(document_id);
CREATE INDEX document_chunks_embedding_idx ON document_chunks
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
CREATE INDEX document_chunks_fts_idx ON document_chunks USING gin(fts);

-- Enable RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_chunks ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own documents"
    ON documents FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own documents"
    ON documents FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their document chunks"
    ON document_chunks FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM documents
            WHERE documents.id = document_chunks.document_id
            AND documents.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their document chunks"
    ON document_chunks FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM documents
            WHERE documents.id = document_chunks.document_id
            AND documents.user_id = auth.uid()
        )
    );
```

## Search Function

```sql
-- Semantic search across user's documents
CREATE OR REPLACE FUNCTION search_document_chunks(
    query_embedding vector(1536)
    user_id_filter UUID
    match_threshold FLOAT DEFAULT 0.78
    match_count INT DEFAULT 10
)
RETURNS TABLE(
    chunk_id BIGINT
    document_id BIGINT
    document_title TEXT
    content TEXT
    chunk_index INTEGER
    similarity FLOAT
    metadata JSONB
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        dc.id AS chunk_id
        dc.document_id
        d.title AS document_title
        dc.content
        dc.chunk_index
        1 - (dc.embedding <=> query_embedding) AS similarity
        dc.metadata
    FROM document_chunks dc
    JOIN documents d ON d.id = dc.document_id
    WHERE
        d.user_id = user_id_filter
        AND 1 - (dc.embedding <=> query_embedding) > match_threshold
    ORDER BY dc.embedding <=> query_embedding
    LIMIT least(match_count, 200);
$$;

-- Hybrid search function
CREATE OR REPLACE FUNCTION hybrid_search_documents(
    query_text TEXT
    query_embedding vector(1536)
    user_id_filter UUID
    match_count INT DEFAULT 10
    full_text_weight FLOAT DEFAULT 1.0
    semantic_weight FLOAT DEFAULT 1.0
)
RETURNS TABLE(
    chunk_id BIGINT
    document_id BIGINT
    document_title TEXT
    content TEXT
    similarity FLOAT
    fts_rank FLOAT
    hybrid_score FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH semantic_results AS (
        SELECT
            dc.id
            dc.document_id
            d.title
            dc.content
            1 - (dc.embedding <=> query_embedding) AS similarity
            ROW_NUMBER() OVER (ORDER BY dc.embedding <=> query_embedding) AS rank
        FROM document_chunks dc
        JOIN documents d ON d.id = dc.document_id
        WHERE d.user_id = user_id_filter
        ORDER BY dc.embedding <=> query_embedding
        LIMIT match_count * 2
    )
    fulltext_results AS (
        SELECT
            dc.id
            dc.document_id
            d.title
            dc.content
            ts_rank(dc.fts, websearch_to_tsquery('english', query_text)) AS fts_rank
            ROW_NUMBER() OVER (
                ORDER BY ts_rank(dc.fts, websearch_to_tsquery('english', query_text)) DESC
            ) AS rank
        FROM document_chunks dc
        JOIN documents d ON d.id = dc.document_id
        WHERE
            d.user_id = user_id_filter
            AND dc.fts @@ websearch_to_tsquery('english', query_text)
        ORDER BY fts_rank DESC
        LIMIT match_count * 2
    )
    SELECT
        COALESCE(s.id, f.id) AS chunk_id
        COALESCE(s.document_id, f.document_id) AS document_id
        COALESCE(s.title, f.title) AS document_title
        COALESCE(s.content, f.content) AS content
        COALESCE(s.similarity, 0.0) AS similarity
        COALESCE(f.fts_rank, 0.0) AS fts_rank
        (
            COALESCE(1.0 / (50 + s.rank), 0.0) * semantic_weight +
            COALESCE(1.0 / (50 + f.rank), 0.0) * full_text_weight
        ) AS hybrid_score
    FROM semantic_results s
    FULL OUTER JOIN fulltext_results f ON s.id = f.id
    ORDER BY hybrid_score DESC
    LIMIT match_count;
END;
$$;
```

## Document Processing (Edge Function)

```typescript
// supabase/functions/process-document/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import OpenAI from 'https://deno.land/x/openai@v4.20.1/mod.ts'

interface DocumentChunk {
    content: string
    chunk_index: number
    token_count: number
}

// Chunk text into smaller pieces
function chunkText(text: string, maxTokens: number = 500): DocumentChunk[] {
    const chunks: DocumentChunk[] = []
    const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0)

    let currentChunk = ""
    let currentTokens = 0
    let chunkIndex = 0

    for (const sentence of sentences) {
        const sentenceTokens = Math.ceil(sentence.length / 4) // Rough estimate

        if (currentTokens + sentenceTokens > maxTokens && currentChunk) {
            chunks.push({
                content: currentChunk.trim()
                chunk_index: chunkIndex++
                token_count: currentTokens
            })
            currentChunk = ""
            currentTokens = 0
        }

        currentChunk += sentence + ". "
        currentTokens += sentenceTokens
    }

    if (currentChunk.trim()) {
        chunks.push({
            content: currentChunk.trim()
            chunk_index: chunkIndex
            token_count: currentTokens
        })
    }

    return chunks
}

// Generate embeddings for chunks
async function generateEmbeddings(
    chunks: DocumentChunk[]
    openai: OpenAI
): Promise<number[][]> {
    const batchSize = 100
    const embeddings: number[][] = []

    for (let i = 0; i < chunks.length; i += batchSize) {
        const batch = chunks.slice(i, i + batchSize)
        const response = await openai.embeddings.create({
            model: "text-embedding-3-small"
            input: batch.map(chunk => chunk.content)
        })
        embeddings.push(...response.data.map(d => d.embedding))
    }

    return embeddings
}

serve(async (req) => {
    try {
        const { documentId, content } = await req.json()

        // Initialize clients
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )
        const openai = new OpenAI({
            apiKey: Deno.env.get('OPENAI_API_KEY')!
        })

        // 1. Chunk the document
        const chunks = chunkText(content, 500)

        // 2. Generate embeddings
        const embeddings = await generateEmbeddings(chunks, openai)

        // 3. Store chunks with embeddings
        const chunksToInsert = chunks.map((chunk, index) => ({
            document_id: documentId
            chunk_index: chunk.chunk_index
            content: chunk.content
            embedding: embeddings[index]
            token_count: chunk.token_count
        }))

        const { error: insertError } = await supabase
            .from('document_chunks')
            .insert(chunksToInsert)

        if (insertError) throw insertError

        // 4. Update document status
        await supabase
            .from('documents')
            .update({ status: 'ready' })
            .eq('id', documentId)

        return new Response(
            JSON.stringify({
                success: true
                chunks_created: chunks.length
            })
            { headers: { "Content-Type": "application/json" } }
        )

    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message })
            { status: 500, headers: { "Content-Type": "application/json" } }
        )
    }
})
```

## Client Application Code

```typescript
// Upload and process document
async function uploadDocument(file: File, userId: string) {
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

    // 1. Create document record
    const { data: document, error: docError } = await supabase
        .from('documents')
        .insert({
            user_id: userId
            title: file.name
            file_name: file.name
            file_size: file.size
            content_type: file.type
            status: 'processing'
        })
        .select()
        .single()

    if (docError) throw docError

    // 2. Read file content
    const content = await file.text()

    // 3. Trigger processing Edge Function
    const { error: processError } = await supabase.functions.invoke(
        'process-document'
        {
            body: {
                documentId: document.id
                content: content
            }
        }
    )

    if (processError) throw processError

    return document
}

// Search documents
async function searchDocuments(
    query: string
    userId: string
    searchType: 'semantic' | 'hybrid' = 'hybrid'
) {
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

    // 1. Generate query embedding
    const embeddingResponse = await fetch('https://api.openai.com/v1/embeddings', {
        method: 'POST'
        headers: {
            'Authorization': `Bearer ${OPENAI_API_KEY}`
            'Content-Type': 'application/json'
        }
        body: JSON.stringify({
            model: 'text-embedding-3-small'
            input: query
        })
    })

    const { data } = await embeddingResponse.json()
    const queryEmbedding = data[0].embedding

    // 2. Execute search
    if (searchType === 'semantic') {
        const { data: results, error } = await supabase.rpc(
            'search_document_chunks'
            {
                query_embedding: queryEmbedding
                user_id_filter: userId
                match_threshold: 0.75
                match_count: 10
            }
        )

        if (error) throw error
        return results
    } else {
        const { data: results, error } = await supabase.rpc(
            'hybrid_search_documents'
            {
                query_text: query
                query_embedding: queryEmbedding
                user_id_filter: userId
                match_count: 10
                full_text_weight: 1.0
                semantic_weight: 1.0
            }
        )

        if (error) throw error
        return results
    }
}

// Group results by document
function groupResultsByDocument(results: any[]) {
    const grouped = new Map()

    for (const result of results) {
        if (!grouped.has(result.document_id)) {
            grouped.set(result.document_id, {
                document_id: result.document_id
                document_title: result.document_title
                chunks: []
                max_similarity: 0
            })
        }

        const doc = grouped.get(result.document_id)
        doc.chunks.push(result)
        doc.max_similarity = Math.max(doc.max_similarity, result.similarity)
    }

    return Array.from(grouped.values())
        .sort((a, b) => b.max_similarity - a.max_similarity)
}
```

## React Component Example

```tsx
import { useState } from 'react'
import { useSupabaseClient, useUser } from '@supabase/auth-helpers-react'

export function DocumentSearch() {
    const [query, setQuery] = useState('')
    const [results, setResults] = useState([])
    const [loading, setLoading] = useState(false)
    const supabase = useSupabaseClient()
    const user = useUser()

    const handleSearch = async () => {
        if (!query.trim()) return

        setLoading(true)
        try {
            const searchResults = await searchDocuments(query, user.id, 'hybrid')
            const grouped = groupResultsByDocument(searchResults)
            setResults(grouped)
        } catch (error) {
            console.error('Search error:', error)
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="document-search">
            <div className="search-bar">
                <input
                    type="text"
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                    placeholder="Search your documents..."
                />
                <button onClick={handleSearch} disabled={loading}>
                    {loading ? 'Searching...' : 'Search'}
                </button>
            </div>

            <div className="results">
                {results.map((doc) => (
                    <div key={doc.document_id} className="result-document">
                        <h3>{doc.document_title}</h3>
                        <div className="similarity-score">
                            Relevance: {(doc.max_similarity * 100).toFixed(0)}%
                        </div>

                        <div className="chunks">
                            {doc.chunks.slice(0, 3).map((chunk) => (
                                <div key={chunk.chunk_id} className="chunk">
                                    <p>{chunk.content.substring(0, 200)}...</p>
                                    <div className="chunk-meta">
                                        Similarity: {(chunk.similarity * 100).toFixed(0)}%
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    )
}
```

## Performance Optimization

### 1. Batch Processing

```typescript
// Process multiple documents in parallel
async function batchProcessDocuments(files: File[], userId: string) {
    const batchSize = 5 // Process 5 at a time
    const results = []

    for (let i = 0; i < files.length; i += batchSize) {
        const batch = files.slice(i, i + batchSize)
        const batchResults = await Promise.all(
            batch.map(file => uploadDocument(file, userId))
        )
        results.push(...batchResults)
    }

    return results
}
```

### 2. Caching Search Results

```typescript
// Cache search results for 5 minutes
const searchCache = new Map<string, { results: any[], timestamp: number }>()

async function cachedSearch(query: string, userId: string) {
    const cacheKey = `${userId}:${query}`
    const cached = searchCache.get(cacheKey)

    if (cached && Date.now() - cached.timestamp < 5 * 60 * 1000) {
        return cached.results
    }

    const results = await searchDocuments(query, userId)
    searchCache.set(cacheKey, { results, timestamp: Date.now() })

    return results
}
```

### 3. Incremental Loading

```typescript
// Load more results as user scrolls
async function loadMoreResults(
    query: string
    userId: string
    offset: number
    limit: number = 10
) {
    // Implementation would need to modify search function
    // to support offset/limit pagination
}
```

## Monitoring & Analytics

```sql
-- Track search queries
CREATE TABLE search_logs (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    user_id UUID NOT NULL
    query_text TEXT NOT NULL
    result_count INTEGER
    search_type TEXT
    avg_similarity FLOAT
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Log searches (call from Edge Function)
CREATE OR REPLACE FUNCTION log_search(
    p_user_id UUID
    p_query TEXT
    p_result_count INT
    p_search_type TEXT
    p_avg_similarity FLOAT
) RETURNS void AS $$
BEGIN
    INSERT INTO search_logs (user_id, query_text, result_count, search_type, avg_similarity)
    VALUES (p_user_id, p_query, p_result_count, p_search_type, p_avg_similarity);
END;
$$ LANGUAGE plpgsql;
```

## Testing

```typescript
// Test document processing
describe('Document Processing', () => {
    it('should chunk document correctly', () => {
        const text = 'Sample text. Another sentence. Third sentence.'
        const chunks = chunkText(text, 100)
        expect(chunks.length).toBeGreaterThan(0)
        expect(chunks[0]).toHaveProperty('content')
        expect(chunks[0]).toHaveProperty('chunk_index')
    })

    it('should generate embeddings', async () => {
        const chunks = [{ content: 'test', chunk_index: 0, token_count: 1 }]
        const embeddings = await generateEmbeddings(chunks, openai)
        expect(embeddings).toHaveLength(1)
        expect(embeddings[0]).toHaveLength(1536)
    })
})

// Test search functionality
describe('Search', () => {
    it('should return relevant results', async () => {
        const results = await searchDocuments('machine learning', userId)
        expect(results).toBeDefined()
        expect(results.length).toBeGreaterThan(0)
        expect(results[0]).toHaveProperty('similarity')
    })
})
```

## Next Steps

1. Deploy Edge Function: `supabase functions deploy process-document`
2. Set environment variables in Supabase dashboard
3. Enable RLS policies
4. Create test documents
5. Monitor performance with `pg_stat_statements`
6. Set up error tracking (Sentry, etc.)
7. Add user feedback mechanisms
8. Optimize chunk size based on use case
