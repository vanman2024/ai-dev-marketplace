---
description: "Phase 7: RAG Features - Document ingestion, vector search, hybrid retrieval (standard for most AI apps)"
argument-hint: none
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

Goal: Add complete RAG capabilities for knowledge retrieval and semantic search.

Phase 1: Load State and Requirements
- Load .ai-stack-config.json
- Verify phase6Complete is true
- Extract appName, paths
- Create Phase 7 todo list
- AskUserQuestion: "Do you need RAG (Retrieval-Augmented Generation) features for knowledge base/document search?"
  - Options: Yes (recommended for most AI apps) / No / Maybe later
  - If "No" or "Maybe later": Skip to Phase 11 (Save State), mark ragEnabled: false

Phase 2: RAG Framework Setup
- Execute immediately: !{slashcommand /rag-pipeline:init}
- After completion, verify: RAG project initialized

Phase 3: Vector Database Configuration
- Execute immediately: !{slashcommand /rag-pipeline:add-vector-db pgvector}
- Uses existing Supabase database with pgvector extension
- After completion, verify: !{bash psql $DATABASE_URL -c "SELECT * FROM pg_extension WHERE extname='vector'" && echo "✅ pgvector enabled" || echo "❌ pgvector missing"}

Phase 4: Embedding Model Setup
- Execute immediately: !{slashcommand /rag-pipeline:add-embeddings}
- Configures embedding model (OpenAI text-embedding-3-small by default)
- After completion, verify: Embedding configuration created

Phase 5: Chunking Strategy
- Execute immediately: !{slashcommand /rag-pipeline:add-chunking}
- Configures document chunking (semantic chunking by default)
- After completion, verify: Chunking strategy configured

Phase 6: Document Ingestion Pipeline
- Execute immediately: !{slashcommand /rag-pipeline:build-ingestion}
- Creates document ingestion pipeline (PDF, DOCX, HTML, Markdown, web scraping)
- After completion, verify: Ingestion pipeline created

Phase 7: Retrieval Pipeline
- Execute immediately: !{slashcommand /rag-pipeline:build-retrieval}
- Creates semantic search and retrieval pipeline
- After completion, verify: Retrieval pipeline created

Phase 8: Hybrid Search
- Execute immediately: !{slashcommand /rag-pipeline:add-hybrid-search}
- Adds hybrid search (semantic + BM25 keyword search)
- After completion, verify: Hybrid search configured

Phase 9: Generation Pipeline
- Execute immediately: !{slashcommand /rag-pipeline:build-generation}
- Integrates RAG with OpenRouter for multi-model generation
- After completion, verify: RAG generation pipeline created

Phase 10: Optimization and Testing
- Execute immediately: !{slashcommand /rag-pipeline:optimize}
- After completion, execute immediately: !{slashcommand /rag-pipeline:test}
- After completion, verify: RAG pipeline tested and optimized

Phase 11: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 7 | .phase7Complete = true | .ragEnabled = true | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display: "✅ Phase 7 Complete - RAG features added"

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 7

## What Phase 7 Creates

**RAG Infrastructure:**
- Document ingestion pipeline (PDF, DOCX, HTML, Markdown, web scraping)
- Vector database with pgvector extension (Supabase)
- Embedding generation (OpenAI text-embedding-3-small)
- Semantic chunking strategy
- Vector similarity search
- Hybrid search (semantic + keyword/BM25)
- RAG generation pipeline with OpenRouter

**Integration Points:**
- Backend API endpoints for document upload
- Vector search endpoints
- RAG query endpoints
- Frontend components for document management (optional)

**Total Time:** ~15-20 minutes
