---
description: Implement document chunking strategies (fixed, semantic, recursive, hybrid)
argument-hint: [strategy-type]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebFetch
---

**Arguments**: $ARGUMENTS

Goal: Implement document chunking strategies for RAG pipeline with configurable parameters and validation

Core Principles:
- Ask user for chunking strategy preferences
- Fetch minimal documentation (LlamaIndex + LangChain)
- Generate chunking implementation with chosen strategy
- Test with sample documents
- Provide chunk statistics and recommendations

Phase 1: Gather Requirements
Goal: Understand chunking strategy needs

Actions:
- Parse $ARGUMENTS to check if strategy specified
- If strategy in $ARGUMENTS, use it; otherwise ask user
- AskUserQuestion: "Which chunking strategy would you like to implement?
  1. Fixed-size chunking (simple, predictable chunks)
  2. Semantic chunking (context-aware boundaries)
  3. Recursive chunking (hierarchical splitting)
  4. Hybrid chunking (combined approaches)

  Enter number (1-4) or strategy name:"
- AskUserQuestion: "Chunk size in characters/tokens? (default: 512)"
- AskUserQuestion: "Chunk overlap in characters/tokens? (default: 50)"
- Detect project structure: Check for existing Python environment

Phase 2: Fetch Documentation
Goal: Load chunking strategy documentation

Actions:
Fetch these docs in parallel (2 URLs):

1. WebFetch: https://docs.llamaindex.ai/en/stable/module_guides/loading/node_parsers/
2. WebFetch: https://python.langchain.com/docs/modules/data_connection/document_transformers/

Phase 3: Implementation
Goal: Generate chunking script with selected strategy

Actions:

Task(description="Generate chunking implementation", subagent_type="general-purpose", prompt="You are implementing document chunking for a RAG pipeline.

Strategy selected: [user's choice from Phase 1]
Chunk size: [user's chunk size]
Chunk overlap: [user's overlap]

Using the documentation fetched in Phase 2, create a Python script that:

1. Implements the chosen chunking strategy
2. Supports multiple document formats (txt, pdf, markdown)
3. Includes configuration for chunk size and overlap
4. Provides chunk metadata (position, source, length)
5. Handles edge cases (empty documents, very small documents)
6. Uses appropriate library (LlamaIndex or LangChain based on strategy):
   - Fixed-size: Use LangChain CharacterTextSplitter or LlamaIndex SentenceSplitter
   - Semantic: Use LangChain SemanticChunker or LlamaIndex SemanticSplitterNodeParser
   - Recursive: Use LangChain RecursiveCharacterTextSplitter
   - Hybrid: Combine multiple approaches

Create these files:
- chunking/chunker.py - Main chunking implementation
- chunking/config.py - Configuration for chunk parameters
- chunking/test_chunker.py - Test with sample documents
- chunking/requirements.txt - Dependencies

Include comprehensive docstrings and type hints.
Deliverable: Working chunking implementation ready for testing")

Wait for Task to complete.

Phase 4: Test Chunking
Goal: Validate chunking with sample documents

Actions:
- Create sample test document if not exists: !{bash mkdir -p chunking/samples}
- Generate sample text: Write simple test document to chunking/samples/test.txt
- Run chunking test: !{bash cd chunking && python test_chunker.py}
- Capture chunk statistics: Number of chunks, avg size, overlap effectiveness
- Verify chunk boundaries are appropriate

Phase 5: Statistics and Recommendations
Goal: Provide chunk analysis and next steps

Actions:
Display summary:
- Strategy implemented: [chosen strategy]
- Configuration: Chunk size [size], overlap [overlap]
- Test results: [number] chunks generated from sample
- Average chunk size: [avg] characters
- Files created:
  * chunking/chunker.py
  * chunking/config.py
  * chunking/test_chunker.py
  * chunking/requirements.txt
  * chunking/samples/test.txt

Recommendations:
- For semantic search: Consider chunk size 256-512 tokens
- For question answering: Consider chunk size 512-1024 tokens
- For summarization: Consider larger chunks 1024-2048 tokens
- Overlap should be 10-20% of chunk size
- Test with your actual documents and adjust parameters

Next steps:
- Install dependencies: pip install -r chunking/requirements.txt
- Test with your documents: python chunking/chunker.py your_document.pdf
- Integrate with vector database: /rag-pipeline:add-vector-db
- Add embeddings: /rag-pipeline:add-embeddings

Important Notes:
- Adapts to user's chunking strategy preference
- Fetches minimal docs (2 URLs)
- Generates production-ready chunking code
- Tests implementation with samples
- Provides tuning recommendations
