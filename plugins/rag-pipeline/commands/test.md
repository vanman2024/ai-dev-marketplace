---
description: Run comprehensive RAG pipeline tests
argument-hint: [--coverage]
allowed-tools: Task, Bash, Read, Grep, Glob, Write, Skill
---
## Available Skills

This commands has access to the following skills from the rag-pipeline plugin:

- **chunking-strategies**: Document chunking implementations and benchmarking tools for RAG pipelines including fixed-size, semantic, recursive, and sentence-based strategies. Use when implementing document processing, optimizing chunk sizes, comparing chunking approaches, benchmarking retrieval performance, or when user mentions chunking, text splitting, document segmentation, RAG optimization, or chunk evaluation.\n- **document-parsers**: Multi-format document parsing tools for PDF, DOCX, HTML, and Markdown with support for LlamaParse, Unstructured.io, PyPDF2, PDFPlumber, and python-docx. Use when parsing documents, extracting text from PDFs, processing Word documents, converting HTML to text, extracting tables from documents, building RAG pipelines, chunking documents, or when user mentions document parsing, PDF extraction, DOCX processing, table extraction, OCR, LlamaParse, Unstructured.io, or document ingestion.\n- **embedding-models**: Embedding model configurations and cost calculators\n- **langchain-patterns**: LangChain implementation patterns with templates, scripts, and examples for RAG pipelines\n- **llamaindex-patterns**: LlamaIndex implementation patterns with templates, scripts, and examples for building RAG applications. Use when implementing LlamaIndex, building RAG pipelines, creating vector indices, setting up query engines, implementing chat engines, integrating LlamaCloud, or when user mentions LlamaIndex, RAG, VectorStoreIndex, document indexing, semantic search, or question answering systems.\n- **retrieval-patterns**: Search and retrieval strategies including semantic, hybrid, and reranking for RAG systems. Use when implementing retrieval mechanisms, optimizing search performance, comparing retrieval approaches, or when user mentions semantic search, hybrid search, reranking, BM25, or retrieval optimization.\n- **vector-database-configs**: Vector database configuration and setup for pgvector, Chroma, Pinecone, Weaviate, Qdrant, and FAISS with comparison guide and migration helpers\n- **web-scraping-tools**: Web scraping templates, scripts, and patterns for documentation and content collection using Playwright, BeautifulSoup, and Scrapy. Includes rate limiting, error handling, and extraction patterns. Use when scraping documentation, collecting web content, extracting structured data, building RAG knowledge bases, harvesting articles, crawling websites, or when user mentions web scraping, documentation collection, content extraction, Playwright scraping, BeautifulSoup parsing, or Scrapy spiders.\n
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

Goal: Execute comprehensive test suite for RAG pipeline including ingestion, embeddings, retrieval quality, end-to-end queries, performance benchmarking, cost analysis, and generate detailed test report.

Core Principles:
- Run independent test suites in parallel for speed
- Measure quality metrics (precision, recall, latency)
- Track costs (API calls, embeddings, storage)
- Generate actionable test reports

Phase 1: Discovery and Setup
Goal: Detect test infrastructure and prepare test environment

Actions:
- Check test files: !{bash find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | head -20}
- Detect framework: !{bash grep -l "llama_index\|langchain" requirements.txt setup.py pyproject.toml 2>/dev/null}
- Parse coverage flag: !{bash echo "$ARGUMENTS" | grep -q "\-\-coverage" && echo "coverage-enabled" || echo "coverage-disabled"}
- Load test configs: @tests/config.yaml, @.env.test, @pytest.ini
- Check vector DB: !{bash python -c "import os; print(os.getenv('VECTOR_DB_URL', 'not-configured'))" 2>/dev/null}

Phase 2: Parallel Test Execution
Goal: Run independent test suites in parallel for maximum speed

Actions:

Task(description="Test ingestion pipeline", subagent_type="rag-pipeline:rag-tester", prompt="You are the rag-tester agent. Run ingestion pipeline tests for $ARGUMENTS.

Test scope: Document loading (PDF, DOCX, TXT, MD, HTML), parsing accuracy, metadata extraction, error handling for corrupted files, batch processing, resume capability

Test approach: Create fixtures with sample documents, run ingestion on test_data/, verify document count and metadata preservation, test error scenarios, measure throughput (docs/sec), check logging

Deliverable: ingestion_test_results.json with pass/fail status, throughput metrics, error logs")

Task(description="Test embedding generation", subagent_type="rag-pipeline:rag-tester", prompt="You are the rag-tester agent. Run embedding generation tests for $ARGUMENTS.

Test scope: Embedding model initialization, batch generation, vector dimension validation, consistency (same input = same output), API rate limiting and retry logic, embedding quality (semantic similarity)

Test approach: Test with sample chunks, verify vector dimensions, test batch sizes (1, 10, 100 documents), measure speed (chunks/sec), test semantic similarity with cosine similarity, test rate limit handling

Deliverable: embeddings_test_results.json with quality metrics, speed benchmarks, API call counts")

Task(description="Test retrieval quality", subagent_type="rag-pipeline:rag-tester", prompt="You are the rag-tester agent. Run retrieval quality tests for $ARGUMENTS.

Test scope: Precision (relevance of retrieved documents), recall (coverage of relevant documents), ranking quality, hybrid search (if enabled), filtering and metadata-based retrieval, query latency

Test approach: Create golden dataset with queries plus expected documents, run retrieval for each query, calculate precision at k, recall at k, MRR, NDCG, test semantic vs keyword vs hybrid search, measure query latency (p50, p95, p99), test edge cases (empty queries, very long queries)

Deliverable: retrieval_test_results.json with precision, recall, MRR, NDCG scores, latency percentiles")

Task(description="Test end-to-end RAG", subagent_type="rag-pipeline:rag-tester", prompt="You are the rag-tester agent. Run end-to-end RAG query tests for $ARGUMENTS.

Test scope: Complete RAG pipeline (retrieve plus generate), answer quality and factual accuracy, citation/source attribution, hallucination detection, response formatting, error handling (no results, API failures)

Test approach: Define test questions with expected answers, run complete RAG pipeline, validate answer correctness (exact match, semantic similarity, LLM-as-judge), check source citations are included and accurate, test hallucination by verifying claims are grounded in retrieved docs, measure end-to-end latency, test error scenarios

Deliverable: e2e_test_results.json with answer quality scores, citation accuracy, hallucination rate, latency")

Task(description="Performance benchmarking", subagent_type="rag-pipeline:rag-tester", prompt="You are the rag-tester agent. Run performance benchmarks for $ARGUMENTS.

Test scope: Ingestion throughput (docs/sec, MB/sec), embedding generation speed (chunks/sec), query latency (p50, p95, p99), concurrent query handling, vector DB performance, memory usage, scalability (100, 1K, 10K, 100K documents)

Test approach: Run load tests with increasing document counts, measure throughput at each scale, test concurrent queries (1, 10, 50, 100 concurrent), profile memory usage during ingestion and querying, identify bottlenecks (embedding API, vector DB, LLM), generate performance charts

Deliverable: performance_results.json with throughput, latency, memory metrics, scalability analysis")

Task(description="Cost analysis", subagent_type="rag-pipeline:rag-tester", prompt="You are the rag-tester agent. Run cost analysis for $ARGUMENTS.

Test scope: Embedding API costs (per document, per query), LLM generation costs (per query), vector DB storage costs, total cost projections, cost optimization opportunities

Test approach: Track API calls during test runs, calculate costs based on pricing (OpenAI embeddings, GPT-4, GPT-3.5), estimate monthly costs for different usage levels, identify cost reduction strategies (caching, batch processing, model selection), compare cost vs quality tradeoffs

Deliverable: cost_analysis.json with per-operation costs, projections, optimization recommendations")

Wait for all parallel tasks to complete before proceeding to Phase 3.

Phase 3: Results Aggregation
Goal: Collect all test results and generate comprehensive report

Actions:
- Collect results: !{bash cat *_test_results.json cost_analysis.json 2>/dev/null}
- Check failures: !{bash grep -l '"status": "failed"' *_test_results.json 2>/dev/null || echo "all-passed"}
- Count tests: !{bash grep -oh '"tests_run": [0-9]*' *_test_results.json | awk '{sum+=$NF} END {print sum}' 2>/dev/null}
- Pass rate: !{bash grep -oh '"tests_passed": [0-9]*\|"tests_run": [0-9]*' *_test_results.json | awk 'NR%2{p=$NF;next} {print (p/$NF)*100"%"}' 2>/dev/null}
- Coverage: !{bash if echo "$ARGUMENTS" | grep -q "\-\-coverage"; then pytest --cov=. --cov-report=html tests/ 2>&1 && echo "Coverage report: htmlcov/index.html"; fi}

Phase 4: Test Report Generation
Goal: Create comprehensive test report with results, metrics, and recommendations

Actions:
- Create test_report.md with:
  * Executive Summary (pass rate, total tests, execution time)
  * Ingestion Results (throughput, error rate, supported formats)
  * Embedding Results (speed, quality, API usage)
  * Retrieval Quality (precision at 5, recall at 10, MRR, NDCG)
  * E2E RAG Results (answer quality, hallucination rate, citation accuracy)
  * Performance Benchmarks (latency percentiles, throughput at scale)
  * Cost Analysis (per-query cost, monthly projections, optimization opportunities)
  * Failed Tests (if any with error details)
  * Recommendations (performance optimizations, cost reductions, quality improvements)
  * Coverage Report Link (if coverage flag used)

Display summary:
- Total tests run and pass rate
- Key metrics: retrieval precision, query latency, cost per query
- Critical failures (if any)
- Report location: test_report.md
- Coverage report: htmlcov/index.html (if enabled)

Important Notes:
- Tests run in parallel for speed
- Quality metrics use golden datasets (create if missing)
- Cost tracking uses actual pricing from providers
- Performance tests scale based on available test data
- Report includes actionable recommendations
