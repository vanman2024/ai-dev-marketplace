---
description: Optimize RAG performance and reduce costs
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, WebFetch
---

**Arguments**: $ARGUMENTS

Goal: Analyze and optimize RAG pipeline performance, reduce latency, improve accuracy, and minimize costs through intelligent caching, batching, and parameter tuning.

Core Principles:
- Analyze current performance metrics and identify bottlenecks
- Optimize chunk sizes and overlap based on content type
- Tune vector index parameters (HNSW, IVF) for better speed/accuracy tradeoff
- Implement caching strategies to reduce redundant operations
- Apply cost reduction techniques (batch processing, cheaper embeddings)
- Generate actionable optimization report

Phase 1: Performance Analysis
Goal: Understand current RAG pipeline performance and identify optimization opportunities

Actions:
- Parse $ARGUMENTS for specific optimization focus areas
- Detect existing RAG setup: @config files, @vector database config, @retrieval settings
- Scan for performance metrics: Check for existing monitoring, logging, or analytics
- Identify current bottlenecks:
  * Chunking strategy and parameters
  * Embedding model and batch sizes
  * Vector index configuration (HNSW ef_construction, M, ef_search)
  * Query latency patterns
  * Cache hit rates (if caching exists)
  * Cost metrics (API calls, token usage)

If optimization goals are unclear from $ARGUMENTS, use AskUserQuestion to gather:
- What are your main concerns?
  * Query latency (response time)
  * Retrieval accuracy (better results)
  * Cost reduction (API/embedding costs)
  * Throughput (queries per second)
- What is your current average query latency?
- What is your monthly API/embedding cost?
- How many documents are in your index?
- What frameworks are you using? (LlamaIndex, LangChain, both)

Phase 2: Load Optimization Documentation
Goal: Fetch framework-specific optimization guides

Actions:
Fetch these docs in parallel (4 URLs max):

1. WebFetch: https://docs.llamaindex.ai/en/stable/optimizing/production_rag/
2. WebFetch: https://python.langchain.com/docs/guides/productionization/
3. WebFetch: https://www.pinecone.io/learn/hnsw/ (if using Pinecone/HNSW)
4. WebFetch: https://docs.llamaindex.ai/en/stable/optimizing/advanced_retrieval/ (for retrieval optimization)

Phase 3: Chunk Size Optimization
Goal: Optimize chunking strategy for better retrieval quality

Actions:

Invoke the **general-purpose** agent to analyze and optimize chunking:

Task(description="Optimize chunk sizes", subagent_type="general-purpose", prompt="You are optimizing the chunking strategy for a RAG pipeline.

Analyze the current chunking configuration and optimize:
- Evaluate current chunk_size and chunk_overlap parameters
- Test different chunk sizes based on content type:
  * Code: 512-1024 tokens with high overlap (100-200)
  * Documentation: 256-512 tokens with medium overlap (50-100)
  * Articles/blogs: 512-1024 tokens with low overlap (20-50)
- Consider semantic chunking vs fixed-size chunking
- Implement adaptive chunking based on content structure
- Add chunk size validation and warnings
- Generate chunk size recommendation report

Deliverable: Optimized chunking configuration with analysis report")

Phase 4: Vector Index Optimization
Goal: Tune vector index parameters for optimal speed/accuracy tradeoff

Actions:

Invoke the **general-purpose** agent to optimize vector index:

Task(description="Optimize vector index", subagent_type="general-purpose", prompt="You are optimizing the vector index configuration for a RAG pipeline.

Tune index parameters based on detected vector database:

For HNSW indexes (Pinecone, Chroma, Qdrant):
- Adjust ef_construction (default 200, increase for better accuracy)
- Tune M parameter (connections per node, 16-64 range)
- Optimize ef_search at query time (trade latency for accuracy)
- Consider index segment size and merge policies

For IVF indexes (FAISS):
- Optimize nlist (number of clusters)
- Tune nprobe at query time
- Consider PQ (product quantization) for memory reduction

For PGVector:
- Optimize lists parameter for IVF
- Configure probes for query time
- Add appropriate indexes on metadata columns

Create before/after performance comparison and generate index optimization report.

Deliverable: Optimized index configuration with performance benchmarks")

Phase 5: Query and Retrieval Optimization
Goal: Optimize query processing and retrieval efficiency

Actions:

Invoke the **general-purpose** agent to optimize queries:

Task(description="Optimize query processing", subagent_type="general-purpose", prompt="You are optimizing query processing and retrieval for a RAG pipeline.

Implement these query optimizations:

Query Caching:
- Add semantic cache for similar queries (cache hits for 0.95+ similarity)
- Implement result caching with TTL
- Use Redis or in-memory cache for fast lookups
- Track cache hit rates and effectiveness

Query Optimization:
- Add query preprocessing: normalization, expansion, decomposition
- Implement query routing to appropriate retrieval strategies
- Optimize top_k parameter (fetch fewer documents, rerank if needed)
- Add early stopping for high-confidence results

Batch Processing:
- Batch embedding requests to reduce API calls
- Implement async processing for parallel queries
- Add request deduplication
- Use embedding model caching

Deliverable: Query optimization implementation with caching layer and performance metrics")

Phase 6: Cost Reduction Strategies
Goal: Minimize API costs and operational expenses

Actions:

Invoke the **general-purpose** agent to implement cost reduction:

Task(description="Reduce RAG costs", subagent_type="general-purpose", prompt="You are implementing cost reduction strategies for a RAG pipeline.

Apply these cost optimizations:

Embedding Cost Reduction:
- Use cheaper embedding models where appropriate (e.g., text-embedding-3-small)
- Implement embedding caching (never re-embed same content)
- Batch embed requests to maximize throughput
- Consider local embedding models (sentence-transformers) for development

LLM Cost Reduction:
- Reduce context window by fetching only top-k most relevant chunks
- Implement context compression (extract key sentences only)
- Use cheaper models for simple queries, reserve expensive models for complex ones
- Add prompt caching for repeated system prompts
- Track token usage per query

Vector DB Cost Reduction:
- Archive old/unused embeddings
- Use compression techniques (quantization)
- Optimize index size to reduce storage costs
- Consider tiered storage for cold data

Generate cost analysis report:
- Current monthly costs breakdown
- Projected savings per optimization
- Cost per query before/after
- ROI analysis

Deliverable: Cost optimization implementation and detailed cost analysis report")

Phase 7: Generate Optimization Report
Goal: Provide comprehensive optimization summary and recommendations

Actions:
Compile and present optimization report:

- Performance Improvements:
  * Query latency: Before vs After (with percentiles p50, p95, p99)
  * Retrieval accuracy: Changes in precision@k, recall@k, MRR
  * Throughput: Queries per second improvement
  * Cache hit rate: Percentage of cached responses

- Cost Savings:
  * Embedding cost reduction: Monthly savings
  * LLM cost reduction: Token usage decrease
  * Infrastructure cost: Storage/compute savings
  * Total monthly cost: Before vs After

- Optimizations Applied:
  * Chunking strategy changes
  * Vector index tuning (specific parameters)
  * Query caching implementation
  * Batch processing setup
  * Cost reduction techniques

- Files Modified/Created:
  * List all configuration files updated
  * New caching layer files
  * Optimization scripts created
  * Monitoring/metrics code added

- Recommendations:
  * Further optimization opportunities
  * A/B testing suggestions
  * Monitoring and alerting setup
  * Scaling considerations

- Next Steps:
  * Deploy optimizations to staging
  * Run A/B tests to validate improvements
  * Set up continuous monitoring
  * Consider /rag-pipeline:add-hybrid-search if not using hybrid retrieval
  * Consider implementing guardrails for quality assurance

Important Notes:
- Optimizations are data-driven based on actual metrics
- All changes are backward compatible
- Caching strategies preserve result freshness
- Cost reductions do not sacrifice quality
- Supports both LlamaIndex and LangChain frameworks
- Includes rollback instructions if optimizations cause issues
