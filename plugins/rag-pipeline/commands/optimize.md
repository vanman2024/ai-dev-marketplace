---
description: Optimize RAG performance and reduce costs
argument-hint: none
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---

## Available Skills

This commands has access to the following skills from the rag-pipeline plugin:

- **chunking-strategies**: Document chunking implementations and benchmarking tools for RAG pipelines including fixed-size, semantic, recursive, and sentence-based strategies. Use when implementing document processing, optimizing chunk sizes, comparing chunking approaches, benchmarking retrieval performance, or when user mentions chunking, text splitting, document segmentation, RAG optimization, or chunk evaluation.
- **document-parsers**: Multi-format document parsing tools for PDF, DOCX, HTML, and Markdown with support for LlamaParse, Unstructured.io, PyPDF2, PDFPlumber, and python-docx. Use when parsing documents, extracting text from PDFs, processing Word documents, converting HTML to text, extracting tables from documents, building RAG pipelines, chunking documents, or when user mentions document parsing, PDF extraction, DOCX processing, table extraction, OCR, LlamaParse, Unstructured.io, or document ingestion.
- **embedding-models**: Embedding model configurations and cost calculators
- **langchain-patterns**: LangChain implementation patterns with templates, scripts, and examples for RAG pipelines
- **llamaindex-patterns**: LlamaIndex implementation patterns with templates, scripts, and examples for building RAG applications. Use when implementing LlamaIndex, building RAG pipelines, creating vector indices, setting up query engines, implementing chat engines, integrating LlamaCloud, or when user mentions LlamaIndex, RAG, VectorStoreIndex, document indexing, semantic search, or question answering systems.
- **retrieval-patterns**: Search and retrieval strategies including semantic, hybrid, and reranking for RAG systems. Use when implementing retrieval mechanisms, optimizing search performance, comparing retrieval approaches, or when user mentions semantic search, hybrid search, reranking, BM25, or retrieval optimization.
- **vector-database-configs**: Vector database configuration and setup for pgvector, Chroma, Pinecone, Weaviate, Qdrant, and FAISS with comparison guide and migration helpers
- **web-scraping-tools**: Web scraping templates, scripts, and patterns for documentation and content collection using Playwright, BeautifulSoup, and Scrapy. Includes rate limiting, error handling, and extraction patterns. Use when scraping documentation, collecting web content, extracting structured data, building RAG knowledge bases, harvesting articles, crawling websites, or when user mentions web scraping, documentation collection, content extraction, Playwright scraping, BeautifulSoup parsing, or Scrapy spiders.

**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

---



## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Analyze and optimize RAG pipeline performance, reduce latency, improve accuracy, and minimize costs through intelligent caching, batching, and parameter tuning.

Core Principles:
- Analyze current performance metrics and identify bottlenecks
- Optimize chunk sizes and overlap based on content type
- Tune vector index parameters (HNSW, IVF) for speed/accuracy tradeoff
- Implement caching strategies to reduce redundant operations
- Apply cost reduction techniques (batch processing, cheaper embeddings)

Phase 1: Performance Analysis
Goal: Understand current RAG pipeline performance and identify optimization opportunities

Actions:
- Parse $ARGUMENTS for specific optimization focus areas
- Detect RAG setup: !{bash find . -name "*config*" -o -name "*vector*" -o -name "*retrieval*" 2>/dev/null | head -10}
- Check for metrics: !{bash grep -r "latency\|cost\|performance" . --include="*.py" --include="*.ts" 2>/dev/null | head -10}
- Identify bottlenecks: chunking strategy, embedding model, vector index config, query latency, cache hit rates, API costs

If optimization goals are unclear from $ARGUMENTS, use AskUserQuestion:
- "What are your main concerns? (latency/accuracy/cost/throughput)"
- "Current average query latency?"
- "Monthly API/embedding cost?"
- "Documents in your index?"
- "Framework? (LlamaIndex/LangChain/both)"

Phase 2: Load Optimization Documentation
Goal: Fetch framework-specific optimization guides

Actions:
Fetch these docs in parallel:

1. WebFetch: https://docs.llamaindex.ai/en/stable/optimizing/production_rag/
2. WebFetch: https://python.langchain.com/docs/guides/productionization/
3. WebFetch: https://www.pinecone.io/learn/hnsw/ (if using HNSW index)
4. WebFetch: https://docs.llamaindex.ai/en/stable/optimizing/advanced_retrieval/

Phase 3: Parallel Optimization
Goal: Run independent optimization tasks in parallel for maximum efficiency

Actions:

Task(description="Optimize chunk sizes", subagent_type="rag-pipeline:document-processor", prompt="You are the document-processor agent. Optimize the chunking strategy for a RAG pipeline.

Using the fetched optimization docs:
- Analyze current chunk_size and chunk_overlap
- Test different sizes based on content type (code: 512-1024, docs: 256-512, articles: 512-1024)
- Consider semantic vs fixed-size chunking
- Implement adaptive chunking based on content structure
- Generate chunk size recommendation report

Deliverable: Optimized chunking configuration with analysis report")

Task(description="Optimize vector index", subagent_type="rag-pipeline:vector-db-engineer", prompt="You are the vector-db-engineer agent. Optimize the vector index configuration for a RAG pipeline.

Using the fetched documentation, tune index parameters based on detected database:

HNSW indexes (Pinecone, Chroma, Qdrant):
- Adjust ef_construction (default 200, increase for accuracy)
- Tune M parameter (connections per node, 16-64)
- Optimize ef_search at query time

IVF indexes (FAISS):
- Optimize nlist (number of clusters)
- Tune nprobe at query time
- Consider PQ (product quantization)

PGVector:
- Optimize lists parameter for IVF
- Configure probes for query time
- Add indexes on metadata columns

Deliverable: Optimized index configuration with before/after benchmarks")

Task(description="Optimize query processing", subagent_type="rag-pipeline:retrieval-optimizer", prompt="You are the retrieval-optimizer agent. Optimize query processing and retrieval for a RAG pipeline.

Using fetched docs, implement these optimizations:

Query Caching:
- Semantic cache for similar queries (0.95+ similarity)
- Result caching with TTL
- Redis or in-memory cache
- Track cache hit rates

Query Optimization:
- Query preprocessing: normalization, expansion, decomposition
- Query routing to appropriate retrieval strategies
- Optimize top_k parameter (fetch fewer, rerank if needed)
- Add early stopping for high-confidence results

Batch Processing:
- Batch embedding requests to reduce API calls
- Async processing for parallel queries
- Request deduplication
- Embedding model caching

Deliverable: Query optimization with caching layer and performance metrics")

Task(description="Reduce RAG costs", subagent_type="rag-pipeline:retrieval-optimizer", prompt="You are the retrieval-optimizer agent. Implement cost reduction strategies for a RAG pipeline.

Using fetched docs, apply these cost optimizations:

Embedding Cost Reduction:
- Use cheaper models where appropriate (text-embedding-3-small)
- Implement embedding caching (never re-embed same content)
- Batch embed requests
- Consider local models (sentence-transformers) for dev

LLM Cost Reduction:
- Reduce context window (fetch only top-k relevant chunks)
- Implement context compression (extract key sentences)
- Use cheaper models for simple queries (GPT-3.5-turbo vs GPT-4)
- Enable streaming to reduce timeout costs

Infrastructure:
- Use free tiers: Chroma (free local), HuggingFace (free embeddings), Groq (free LLM tier)
- Cache frequently accessed documents
- Implement request deduplication
- Use batch processing for bulk operations

Deliverable: Cost reduction implementation with savings analysis")

Wait for all parallel tasks to complete before proceeding to Phase 4.

Phase 4: Results Aggregation
Goal: Collect optimization results and generate comprehensive report

Actions:
- Collect results from all optimization tasks
- Aggregate performance improvements: !{bash cat *_optimization_results.json 2>/dev/null}
- Calculate total improvements: latency reduction %, cost savings %, accuracy improvements
- Identify remaining bottlenecks

Phase 5: Optimization Report
Goal: Create comprehensive optimization report with results and recommendations

Actions:
Display summary:
- **Chunking Optimization**: New chunk size [size], overlap [overlap], improvement [%]
- **Vector Index Optimization**: Index params tuned, query latency reduced by [%]
- **Query Optimization**: Cache hit rate [%], API calls reduced by [%]
- **Cost Reduction**: Monthly cost reduced from $[before] to $[after] ([%] savings)
- **Overall**: Latency [before]ms → [after]ms, Cost [before] → [after], Accuracy [before] → [after]

Recommendations:
- Monitor cache hit rates and adjust cache size
- Run A/B tests on chunk sizes with production queries
- Set up alerts for latency spikes and cost overruns
- Continue iterating on retrieval quality
- Consider additional optimizations: hybrid search, reranking, query decomposition

Next steps:
- Test optimizations with production traffic: /rag-pipeline:test
- Monitor performance metrics: /rag-pipeline:add-monitoring
- Deploy optimized configuration: /rag-pipeline:deploy
- Set up continuous optimization: schedule monthly reviews

Important Notes:
- Runs 4 optimization tasks in parallel for efficiency
- Uses fetched docs for latest best practices
- Generates before/after comparisons
- Provides actionable recommendations
- Focuses on quick wins with high ROI
