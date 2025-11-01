---
description: Build document ingestion pipeline (load, parse, chunk, embed, store)
argument-hint: none
allowed-tools: Task, WebFetch, Read, Write, Edit, Bash, Grep, Glob
---

**Arguments**: $ARGUMENTS

Goal: Build complete document ingestion pipeline with loading, parsing, chunking, embedding, and vector storage

Core Principles:
- Detect existing configurations
- Fetch minimal documentation
- Generate unified ingestion script with batch processing, error handling, and progress tracking

Phase 1: Discovery and Documentation
Goal: Understand RAG infrastructure and fetch ingestion docs

Actions:
- Detect project: Check for package.json, requirements.txt, pyproject.toml
- Load configs: @config.yaml, @.env for chunking, embedding, vector DB settings
- Example: !{bash grep -r "chunk_size\|embedding\|vector" . --include="*.py" --include="*.json" --include="*.yaml" 2>/dev/null | head -10}

Fetch docs in parallel:
1. WebFetch: https://docs.llamaindex.ai/en/stable/understanding/loading/loading/
2. WebFetch: https://docs.llamaindex.ai/en/stable/module_guides/loading/ingestion_pipeline/
3. WebFetch: https://python.langchain.com/docs/modules/data_connection/document_loaders/
4. WebFetch: https://python.langchain.com/docs/modules/data_connection/document_transformers/

Phase 2: Implementation
Goal: Generate unified ingestion pipeline with all stages

Actions:

Task(description="Build ingestion pipeline", subagent_type="general-purpose", prompt="Build complete document ingestion pipeline for $ARGUMENTS.

Context: Detected project type, configs (chunking, embedding, vector DB) from Phase 1
Documentation: LlamaIndex ingestion, LangChain loaders/transformers fetched

Requirements:
Create ingestion.py with 6 stages:
1. Load documents (PDF, DOCX, TXT, MD, HTML support)
2. Parse and extract text + metadata
3. Chunk/split with configurable size and overlap
4. Generate embeddings in batches
5. Store vectors in database with metadata
6. Verify ingestion success

Features:
- Batch processing for large document sets
- Retry logic with exponential backoff
- Progress tracking (tqdm/logging)
- Error logging with failed document tracking
- Resume capability for interrupted runs
- Metadata preservation (source, page, timestamps)
- CLI interface (argparse/typer)
- Type hints and docstrings
- Config loading from .env/config file

Deliverables:
- ingestion.py or ingestion_pipeline.py
- config.yaml/.env template
- test_ingestion.py with validation
- Usage documentation")

Phase 3: Testing and Verification
Goal: Set up testing infrastructure and verify pipeline

Actions:
- Create test_data/ directory with sample document
- Example: !{bash mkdir -p test_data && echo "Sample test document" > test_data/sample.txt}
- Verify ingestion script exists: !{bash ls -la ingestion*.py 2>/dev/null}
- Check imports compile: !{bash python -m py_compile ingestion*.py 2>/dev/null || echo "Check imports manually"}
- List all created files (ingestion.py, config template, test script)

Phase 4: Summary
Goal: Display usage instructions

Actions:
Summary:
- Files: ingestion.py, config.yaml/.env, test_ingestion.py, test_data/
- Capabilities: Multi-format support, batch processing, error handling, progress tracking, resume capability
- Usage:
  1. Configure API keys and vector DB credentials
  2. Run: python ingestion.py --source ./documents
  3. Test: python test_ingestion.py
- Next steps: Add documents, configure credentials, run test ingestion, consider /rag-pipeline:build-retrieval

Important Notes:
- Adapts to LlamaIndex or LangChain
- Production-ready with error handling and batch processing
