---
description: Implement hybrid search (vector + keyword with RRF)
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep
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

Goal: Implement hybrid search combining vector similarity search and keyword-based full-text search using Reciprocal Rank Fusion (RRF) for optimal retrieval performance.

Core Principles:
- Build on existing vector search infrastructure
- Add full-text search capability (BM25 or database FTS)
- Implement RRF algorithm for result fusion
- Provide configurable weight tuning
- Compare hybrid vs pure vector search performance

Phase 1: Verify Vector Search Foundation
Goal: Ensure vector search infrastructure exists

Actions:
- Check for vector database configuration: !{bash find . -name "*vector*" -o -name "*embed*" -o -name "*index*" 2>/dev/null | grep -E "\.(py|ts|js|json|yml|yaml)$" | head -10}
- Look for embedding models: !{bash grep -r "embedding" --include="*.py" --include="*.ts" --include="*.js" . 2>/dev/null | head -5}
- Detect vector store (Pinecone, Chroma, pgvector, etc.): !{bash grep -r -E "(pinecone|chroma|pgvector|qdrant|weaviate|faiss)" --include="*.py" --include="*.ts" . 2>/dev/null | head -5}
- Verify dependencies: !{bash test -f requirements.txt && cat requirements.txt | grep -E "(llama-index|langchain|pinecone|chromadb|pgvector)" || echo "No requirements.txt found"}

Phase 2: Analyze Project Structure
Goal: Understand codebase organization

Actions:
- Identify main framework (LlamaIndex vs LangChain): !{bash grep -r "from llama_index\|from langchain" --include="*.py" . 2>/dev/null | head -5}
- Find existing retrieval code: !{bash find . -name "*retriev*" -o -name "*query*" -o -name "*search*" 2>/dev/null | grep -E "\.(py|ts|js)$" | head -10}
- Locate configuration files: !{bash find . -name "config.*" -o -name "settings.*" -o -name ".env*" 2>/dev/null | head -10}
- Check for existing documentation: !{bash find . -name "README*" -o -name "DOCS*" -o -name "*.md" 2>/dev/null | grep -v node_modules | head -10}

Phase 3: Implement Hybrid Search
Goal: Add hybrid search capability with RRF

Actions:

Task(description="Implement hybrid search with RRF", subagent_type="rag-pipeline:retrieval-optimizer", prompt="You are the retrieval-optimizer agent. Implement hybrid search (vector + keyword with RRF) for this RAG pipeline.

Context from analysis:
- Vector store detected: [from Phase 1 detection]
- Main framework: [LlamaIndex or LangChain from Phase 2]
- Existing retrieval code: [from Phase 2 findings]
- Project structure: [from Phase 2 analysis]

Reference Documentation:
- Hybrid Search Concepts: https://developers.llamaindex.ai/python/framework/understanding/
- RRF Algorithm: Reciprocal Rank Fusion combines rankings from multiple retrieval methods

Implementation Requirements:

1. **Add Full-Text Search Component**:
   - If using pgvector: Add PostgreSQL full-text search (tsvector/tsquery)
   - If using Pinecone/Chroma: Implement BM25 keyword search
   - If using LlamaIndex: Use BM25Retriever or custom keyword retriever
   - If using LangChain: Use BM25Retriever from langchain-community

2. **Implement RRF Algorithm**:
   - Create RRF fusion function: score = sum(1 / (k + rank_i)) for each retrieval method
   - Default k=60 (standard RRF parameter)
   - Combine results from vector search and keyword search
   - Re-rank merged results by RRF score

3. **Create Hybrid Retriever Class**:
   - Constructor accepts: vector_retriever, keyword_retriever, weights (optional)
   - retrieve() method that:
     * Runs both retrievers in parallel
     * Applies RRF fusion
     * Returns top-k merged results
   - Support configurable weight tuning (alpha parameter: 0=pure keyword, 1=pure vector)

4. **Add Configuration Options**:
   - config.py or settings file with:
     * HYBRID_SEARCH_ENABLED (bool)
     * RRF_K_PARAM (int, default 60)
     * VECTOR_WEIGHT (float, default 0.5)
     * KEYWORD_WEIGHT (float, default 0.5)
     * TOP_K_RESULTS (int, default 10)

5. **Create Comparison Utilities**:
   - compare_search_methods() function that runs same query with:
     * Pure vector search
     * Pure keyword search
     * Hybrid search (RRF)
   - Display metrics: retrieval time, result count, overlap analysis
   - Example usage script or notebook

6. **Add Tests**:
   - Unit tests for RRF algorithm
   - Integration tests for hybrid retriever
   - Performance benchmarks
   - Example queries demonstrating hybrid superiority

7. **Update Documentation**:
   - README section on hybrid search
   - API documentation for hybrid retriever
   - Configuration guide
   - Performance tuning tips

Files to Create/Modify:
- hybrid_search.py or hybrid_retriever.py (main implementation)
- config.py or settings.py (configuration)
- tests/test_hybrid_search.py (tests)
- examples/hybrid_search_demo.py (usage example)
- README.md (documentation updates)

Deliverable: Complete hybrid search implementation with RRF, tests, configuration, comparison utilities, and documentation.")

Phase 4: Validation and Testing
Goal: Verify hybrid search implementation works correctly

Actions:
- Check created files exist: !{bash ls -la hybrid_search.py hybrid_retriever.py 2>/dev/null || echo "Check for created hybrid search files"}
- Verify RRF implementation: !{bash grep -n "rrf\|reciprocal\|rank.*fusion" --include="*.py" . -r 2>/dev/null | head -10}
- Look for configuration options: !{bash grep -n "HYBRID\|RRF_K\|VECTOR_WEIGHT" --include="*.py" . -r 2>/dev/null | head -10}
- Check if tests were created: !{bash find . -path "*/test*" -name "*hybrid*" 2>/dev/null}
- Run tests if they exist: !{bash if [ -f tests/test_hybrid_search.py ]; then python -m pytest tests/test_hybrid_search.py -v 2>&1 | head -30; else echo "No tests found"; fi}

Phase 5: Summary and Usage Guide
Goal: Provide clear usage instructions

Actions:
- Display created files with absolute paths
- Show example usage: HybridRetriever(vector_retriever, keyword_retriever, rrf_k=60, vector_weight=0.5)
- Explain RRF parameters: k=60 (rank fusion), vector_weight 0.0-1.0 (balance vector/keyword)
- Suggest next steps: Tune weights, run benchmarks, integrate with RAG pipeline, monitor quality
- Performance tips: Start with 0.5/0.5 weights, increase vector weight for semantic queries, keyword for exact matches
