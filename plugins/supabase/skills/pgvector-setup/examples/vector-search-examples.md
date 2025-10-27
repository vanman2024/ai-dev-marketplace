# Vector Search Examples

Common patterns and use cases for pgvector semantic search in Supabase.

## Basic Semantic Search

### Pattern 1: Simple Document Search

```javascript
// Generate embedding for query
const queryText = "machine learning algorithms";
const { data: embeddingData } = await openai.embeddings.create({
    model: "text-embedding-3-small",
    input: queryText
});
const queryEmbedding = embeddingData.data[0].embedding;

// Search documents
const { data, error } = await supabase.rpc('match_documents', {
    query_embedding: queryEmbedding,
    match_threshold: 0.78,
    match_count: 10
});

console.log(data);
// [
//   { id: 1, content: "...", similarity: 0.92 },
//   { id: 5, content: "...", similarity: 0.87 },
//   ...
// ]
```

### Pattern 2: Search with Metadata Filtering

```javascript
// Search only user's documents
const { data } = await supabase.rpc('match_documents', {
    query_embedding: queryEmbedding,
    match_threshold: 0.7,
    match_count: 20
}).eq('user_id', userId);

// Search by category
const { data } = await supabase.rpc('match_documents', {
    query_embedding: queryEmbedding,
    match_threshold: 0.75,
    match_count: 15
}).contains('metadata', { category: 'technical' });
```

### Pattern 3: Multi-Query Search

```javascript
// Search with multiple queries, merge results
const queries = [
    "artificial intelligence",
    "neural networks",
    "deep learning"
];

const allResults = await Promise.all(
    queries.map(async (query) => {
        const embedding = await generateEmbedding(query);
        const { data } = await supabase.rpc('match_documents', {
            query_embedding: embedding,
            match_threshold: 0.75,
            match_count: 5
        });
        return data;
    })
);

// Merge and deduplicate
const uniqueResults = [...new Map(
    allResults.flat().map(item => [item.id, item])
).values()];
```

## Advanced Patterns

### Pattern 4: Reciprocal Rank Fusion (Multiple Queries)

```javascript
// Custom RRF implementation for multiple queries
async function multiQueryRRF(queries, k = 60) {
    const results = new Map();

    for (const query of queries) {
        const embedding = await generateEmbedding(query);
        const { data } = await supabase.rpc('match_documents', {
            query_embedding: embedding,
            match_threshold: 0.0, // Get all results
            match_count: 50
        });

        data.forEach((doc, index) => {
            const rank = index + 1;
            const rrfScore = 1 / (k + rank);

            if (results.has(doc.id)) {
                results.get(doc.id).score += rrfScore;
            } else {
                results.set(doc.id, { ...doc, score: rrfScore });
            }
        });
    }

    return Array.from(results.values())
        .sort((a, b) => b.score - a.score)
        .slice(0, 10);
}

// Usage
const results = await multiQueryRRF([
    "natural language processing",
    "NLP techniques",
    "text analysis methods"
]);
```

### Pattern 5: Hybrid Search (Semantic + Keyword)

```javascript
// Use the hybrid search function
const queryText = "PostgreSQL performance optimization";
const queryEmbedding = await generateEmbedding(queryText);

const { data } = await supabase.rpc('documents_hybrid_search', {
    query_text: queryText,
    query_embedding: queryEmbedding,
    match_count: 10,
    full_text_weight: 1.0,    // Keyword importance
    semantic_weight: 1.0       // Semantic importance
});

console.log(data);
// [
//   {
//     id: 1,
//     content: "...",
//     similarity: 0.85,      // Semantic score
//     fts_rank: 0.12,        // Keyword score
//     hybrid_score: 0.47     // Combined RRF score
//   },
//   ...
// ]
```

### Pattern 6: Contextual Search with Re-ranking

```javascript
// First pass: broad semantic search
const { data: candidates } = await supabase.rpc('match_documents', {
    query_embedding: queryEmbedding,
    match_threshold: 0.6,  // Lower threshold
    match_count: 50         // Get more candidates
});

// Second pass: re-rank with additional context
const reranked = candidates.map(doc => {
    let score = doc.similarity;

    // Boost recent documents
    const daysSinceCreation = (Date.now() - new Date(doc.created_at)) / (1000 * 60 * 60 * 24);
    score *= (1 + 0.1 / (1 + daysSinceCreation / 30)); // Decay over 30 days

    // Boost by user engagement
    if (doc.metadata.views) {
        score *= (1 + Math.log10(doc.metadata.views + 1) * 0.05);
    }

    return { ...doc, final_score: score };
})
.sort((a, b) => b.final_score - a.final_score)
.slice(0, 10);
```

## Use Case Examples

### Use Case 1: Document Q&A (RAG)

```javascript
async function documentQA(question, userId) {
    // 1. Generate query embedding
    const queryEmbedding = await generateEmbedding(question);

    // 2. Find relevant context
    const { data: context } = await supabase.rpc('match_documents', {
        query_embedding: queryEmbedding,
        match_threshold: 0.75,
        match_count: 5
    }).eq('user_id', userId);

    // 3. Construct prompt with context
    const contextText = context.map(doc => doc.content).join('\n\n');
    const prompt = `Context:\n${contextText}\n\nQuestion: ${question}\n\nAnswer:`;

    // 4. Generate answer
    const completion = await openai.chat.completions.create({
        model: "gpt-4",
        messages: [{ role: "user", content: prompt }]
    });

    return {
        answer: completion.choices[0].message.content,
        sources: context.map(doc => ({ id: doc.id, content: doc.content }))
    };
}

// Usage
const result = await documentQA("What is the refund policy?", userId);
console.log(result.answer);
console.log("Sources:", result.sources);
```

### Use Case 2: Semantic Deduplication

```javascript
async function findDuplicates(documents, threshold = 0.95) {
    const duplicates = [];

    for (let i = 0; i < documents.length; i++) {
        const { data } = await supabase.rpc('match_documents', {
            query_embedding: documents[i].embedding,
            match_threshold: threshold,
            match_count: 10
        }).neq('id', documents[i].id); // Exclude self

        if (data.length > 0) {
            duplicates.push({
                original: documents[i],
                duplicates: data
            });
        }
    }

    return duplicates;
}

// Usage
const { data: allDocs } = await supabase
    .from('documents')
    .select('*')
    .limit(1000);

const dupes = await findDuplicates(allDocs);
console.log(`Found ${dupes.length} potential duplicates`);
```

### Use Case 3: Content Recommendation

```javascript
async function recommendSimilarContent(documentId, count = 5) {
    // Get the document embedding
    const { data: doc } = await supabase
        .from('documents')
        .select('embedding, user_id')
        .eq('id', documentId)
        .single();

    // Find similar documents
    const { data: similar } = await supabase.rpc('match_documents', {
        query_embedding: doc.embedding,
        match_threshold: 0.7,
        match_count: count + 1 // +1 to exclude self
    })
    .neq('id', documentId)
    .eq('user_id', doc.user_id);

    return similar;
}

// Usage
const recommendations = await recommendSimilarContent(123, 5);
```

### Use Case 4: Semantic Clustering

```javascript
async function clusterDocuments(documents, numClusters = 5) {
    // 1. Get embeddings for all documents
    const embeddings = documents.map(doc => doc.embedding);

    // 2. Run k-means clustering (simplified)
    const clusters = kMeans(embeddings, numClusters);

    // 3. Assign cluster labels
    return documents.map((doc, i) => ({
        ...doc,
        cluster: clusters[i]
    }));
}

// 4. Find cluster representatives
async function getClusterRepresentatives(clusteredDocs) {
    const clusterGroups = {};

    clusteredDocs.forEach(doc => {
        if (!clusterGroups[doc.cluster]) {
            clusterGroups[doc.cluster] = [];
        }
        clusterGroups[doc.cluster].push(doc);
    });

    const representatives = {};
    for (const [cluster, docs] of Object.entries(clusterGroups)) {
        // Find centroid of cluster
        const centroid = calculateCentroid(docs.map(d => d.embedding));

        // Find document closest to centroid
        const { data } = await supabase.rpc('match_documents', {
            query_embedding: centroid,
            match_threshold: 0.0,
            match_count: 1
        });

        representatives[cluster] = data[0];
    }

    return representatives;
}
```

### Use Case 5: Multi-Modal Search

```javascript
// Search across different content types
async function multiModalSearch(query, types = ['text', 'code', 'image']) {
    const queryEmbedding = await generateEmbedding(query);
    const results = {};

    for (const type of types) {
        const { data } = await supabase.rpc('match_documents', {
            query_embedding: queryEmbedding,
            match_threshold: 0.7,
            match_count: 10
        }).eq('content_type', type);

        results[type] = data;
    }

    return results;
}

// Usage
const results = await multiModalSearch("database optimization");
console.log("Text results:", results.text);
console.log("Code results:", results.code);
```

## Performance Optimization

### Pattern 7: Batch Embedding Generation

```javascript
// Efficient batch embedding generation
async function batchEmbed(texts, batchSize = 100) {
    const embeddings = [];

    for (let i = 0; i < texts.length; i += batchSize) {
        const batch = texts.slice(i, i + batchSize);

        const { data } = await openai.embeddings.create({
            model: "text-embedding-3-small",
            input: batch
        });

        embeddings.push(...data.data.map(d => d.embedding));
    }

    return embeddings;
}

// Usage
const texts = ["text 1", "text 2", ..., "text 1000"];
const embeddings = await batchEmbed(texts);
```

### Pattern 8: Caching Embeddings

```javascript
// In-memory cache
const embeddingCache = new Map();

async function getCachedEmbedding(text) {
    // Check cache first
    if (embeddingCache.has(text)) {
        return embeddingCache.get(text);
    }

    // Generate if not cached
    const { data } = await openai.embeddings.create({
        model: "text-embedding-3-small",
        input: text
    });

    const embedding = data.data[0].embedding;
    embeddingCache.set(text, embedding);

    // Optional: persist to Supabase
    await supabase
        .from('embedding_cache')
        .upsert({ query: text, embedding });

    return embedding;
}
```

### Pattern 9: Pagination for Large Result Sets

```javascript
async function paginatedSearch(query, page = 1, pageSize = 20) {
    const queryEmbedding = await generateEmbedding(query);

    // Get all results up to current page
    const { data } = await supabase.rpc('match_documents', {
        query_embedding: queryEmbedding,
        match_threshold: 0.7,
        match_count: page * pageSize
    });

    // Return only current page
    const start = (page - 1) * pageSize;
    const end = start + pageSize;

    return {
        results: data.slice(start, end),
        page,
        pageSize,
        total: data.length,
        hasMore: data.length === page * pageSize
    };
}
```

## Testing & Debugging

### Debug Pattern: Compare Distance Metrics

```javascript
async function compareDistanceMetrics(query) {
    const embedding = await generateEmbedding(query);

    const results = {
        cosine: await supabase.rpc('match_documents_cosine', {
            query_embedding: embedding,
            match_count: 10
        }),
        innerProduct: await supabase.rpc('match_documents_ip', {
            query_embedding: embedding,
            match_count: 10
        }),
        euclidean: await supabase.rpc('match_documents_l2', {
            query_embedding: embedding,
            match_count: 10
        })
    };

    return results;
}
```

### Debug Pattern: Analyze Query Performance

```javascript
async function analyzeQueryPerformance(query, iterations = 10) {
    const embedding = await generateEmbedding(query);
    const times = [];

    for (let i = 0; i < iterations; i++) {
        const start = performance.now();

        await supabase.rpc('match_documents', {
            query_embedding: embedding,
            match_threshold: 0.7,
            match_count: 10
        });

        times.push(performance.now() - start);
    }

    return {
        avg: times.reduce((a, b) => a + b) / times.length,
        min: Math.min(...times),
        max: Math.max(...times),
        median: times.sort()[Math.floor(times.length / 2)]
    };
}
```

## Error Handling

### Pattern: Robust Search with Fallbacks

```javascript
async function robustSearch(query, options = {}) {
    const {
        maxRetries = 3,
        fallbackThreshold = 0.5,
        minResults = 5
    } = options;

    let attempt = 0;
    let threshold = 0.78;

    while (attempt < maxRetries) {
        try {
            const embedding = await generateEmbedding(query);
            const { data, error } = await supabase.rpc('match_documents', {
                query_embedding: embedding,
                match_threshold: threshold,
                match_count: 20
            });

            if (error) throw error;

            // If we got enough results, return them
            if (data.length >= minResults) {
                return { success: true, data, threshold };
            }

            // Lower threshold and retry
            threshold = Math.max(threshold - 0.1, fallbackThreshold);
            attempt++;

        } catch (error) {
            console.error(`Search attempt ${attempt + 1} failed:`, error);
            attempt++;

            if (attempt === maxRetries) {
                return {
                    success: false,
                    error: error.message,
                    data: []
                };
            }

            // Wait before retry
            await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
        }
    }
}
```

## Next Steps

- See `embedding-strategies.md` for index selection and tuning
- See `../templates/` for SQL function implementations
- See `../scripts/` for setup automation
- Test with your own data and adjust thresholds
