---
description: Add RAG (Retrieval-Augmented Generation) pipeline with Google Gemini File API and Redis caching
argument-hint: [feature-description]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Implement a complete RAG pipeline using Google Gemini File API as the primary RAG solution with Redis as an intelligent caching layer for Gemini responses, embeddings, and file processing results.

Core Principles:
- Google Gemini File API is the PRIMARY RAG solution (handles embeddings, file uploads, retrieval)
- Redis provides CACHING layer (semantic cache for responses, embedding cache, file processing cache)
- Optimize for cost/speed by caching expensive Gemini API calls
- Support optional LangChain/LlamaIndex integration for flexibility
- Never hardcode API keys - use placeholders and environment variables
- Detect existing project structure before implementing

Phase 1: Discovery
Goal: Understand project context and RAG requirements

Actions:
- Parse $ARGUMENTS for feature description or use case
- If unclear, use AskUserQuestion to gather:
  - What documents/data will be processed? (PDFs, text files, web pages, etc.)
  - What queries will users ask? (search, Q&A, summarization, etc.)
  - Caching strategy preference? (aggressive for cost savings, conservative for freshness)
  - Integration preference? (Gemini only, or also LangChain/LlamaIndex)
- Detect project type and framework
- Example: !{bash ls package.json requirements.txt pyproject.toml 2>/dev/null}
- Check for existing Redis configuration
- Example: @.env.example

Phase 2: Architecture Planning
Goal: Design RAG pipeline architecture

Actions:
- Load existing project configuration files for context
- Determine architecture based on requirements:
  - **Gemini File API Layer**: File uploads, vector embeddings, semantic retrieval
  - **Redis Caching Layer**: Semantic cache, embedding cache, file processing results
  - **Optional Framework Integration**: LangChain or LlamaIndex abstractions
- Identify required components:
  - File upload/processing pipeline
  - Embedding generation (via Gemini)
  - Vector similarity search (via Gemini)
  - Redis semantic caching configuration
  - Query processing and response generation
- Present architecture plan to user for confirmation

Phase 3: Implementation
Goal: Build RAG pipeline with Gemini + Redis

Actions:

Task(description="Implement RAG pipeline with Google Gemini File API and Redis caching", subagent_type="redis:rag-specialist", prompt="You are the redis:rag-specialist agent. Implement a complete RAG pipeline with Google Gemini File API and Redis caching for $ARGUMENTS.

Context from Discovery:
- Feature description: $ARGUMENTS
- Project type detected
- Existing Redis configuration (if any)
- User requirements gathered

Architecture Requirements:
- **PRIMARY**: Google Gemini File API for RAG
  - File upload and processing (PDF, text, web)
  - Vector embedding generation
  - Semantic search and retrieval
  - Document chunking strategies
- **CACHING**: Redis for performance optimization
  - Semantic cache for Gemini API responses
  - Embedding cache to avoid recomputation
  - File processing results cache
  - Query result cache with TTL
- **OPTIONAL**: LangChain/LlamaIndex integration
  - Only if user requested framework integration
  - Use as abstraction layer over Gemini + Redis

Security Requirements:
- Use environment variables for API keys (GEMINI_API_KEY, REDIS_URL)
- Create .env.example with placeholders only
- Never hardcode credentials
- Document key acquisition in setup guide

Implementation Deliverables:
1. Gemini File API integration code
   - File upload handlers
   - Embedding generation functions
   - Semantic search/retrieval logic
2. Redis caching layer
   - Semantic cache implementation
   - Embedding cache with TTL
   - File processing cache
3. RAG pipeline orchestration
   - Query processing flow
   - Cache-first strategy
   - Fallback to Gemini API
4. Configuration files
   - .env.example with placeholders
   - Redis cache configuration
   - Gemini API settings
5. Documentation
   - Setup guide with API key instructions
   - Usage examples
   - Caching strategy explanation
   - Cost optimization tips
6. Example code
   - Sample RAG queries
   - File upload examples
   - Cache monitoring

Expected Output: Complete RAG implementation with Gemini as primary engine and Redis as intelligent cache")

Phase 4: Validation
Goal: Verify RAG pipeline functionality

Actions:
- Check that all required files were created
- Verify Redis caching configuration
- Validate Gemini API integration setup
- Run example queries if test data provided
- Example: !{bash python -c "import redis; redis.Redis().ping()" 2>/dev/null && echo "Redis OK" || echo "Redis not running"}

Phase 5: Summary
Goal: Document implementation and next steps

Actions:
- Summarize RAG pipeline architecture:
  - Gemini File API components implemented
  - Redis caching layers configured
  - Framework integrations (if any)
- List files created/modified
- Highlight key configuration:
  - Cache TTL settings
  - Embedding dimensions
  - Chunk sizes and strategies
- Provide next steps:
  - Set up Gemini API key (link to console)
  - Configure Redis connection
  - Upload first documents
  - Test sample queries
- Show cost optimization tips:
  - Cache hit rate monitoring
  - Embedding reuse strategies
  - Query result caching
