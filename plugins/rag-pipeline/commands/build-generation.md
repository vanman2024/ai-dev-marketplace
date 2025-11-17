---
description: Build RAG generation pipeline with streaming support
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

Goal: Build complete RAG generation pipeline with retrieval, LLM generation, and streaming support

Core Principles:
- Verify retrieval pipeline exists before proceeding
- Fetch latest documentation for chosen LLM provider
- Highlight FREE Groq option for cost-effective development
- Implement streaming for real-time responses
- Manage context windows intelligently

Phase 1: Environment Verification
Goal: Ensure retrieval pipeline is ready and gather requirements

Actions:
- Create todo list using TodoWrite
- Check for existing retrieval components: !{bash find . -name "*retrieval*" -o -name "*embedding*" -o -name "*index*" 2>/dev/null | head -10}
- Verify vector store exists: !{bash test -f *.index -o -d chroma_db -o -d faiss_index && echo "found" || echo "missing"}
- If missing, warn: "Retrieval pipeline not found. Run build-retrieval first or /rag-pipeline:init"
- AskUserQuestion: "LLM provider? (OpenAI/Anthropic/Groq-FREE/Ollama/Multiple)"
- Record provider choice for documentation fetch

Phase 2: Documentation Loading
Goal: Fetch latest RAG and LLM provider documentation

Actions:
Use WebFetch to load documentation in parallel:
- https://docs.llamaindex.ai/en/stable/examples/query_engine/
- https://python.langchain.com/docs/tutorials/rag/
- https://platform.openai.com/docs/guides/text-generation
- https://console.groq.com/docs/quickstart
- https://docs.anthropic.com/claude/reference/streaming

Wait for all to complete. Update todos.

Phase 3: RAG Pipeline Generation
Goal: Build complete generation pipeline with retrieval integration

Actions:

Task(description="Build RAG generation pipeline", subagent_type="rag-pipeline:llamaindex-specialist", prompt="You are the llamaindex-specialist agent. Build a complete RAG generation pipeline with streaming support based on fetched documentation.

Provider: $ARGUMENTS (or from user question)

Implementation:

1. Core Pipeline (src/generation/):
   - query_engine.py: load_retriever(), retrieve_context(), format_prompt(), generate_response(), generate_stream()
   - llm_client.py: OpenAI/Anthropic/Groq/Ollama clients with streaming
   - context_manager.py: count_tokens(), truncate_context(), prioritize_chunks(), sliding_window()

2. Utilities (src/generation/utils/):
   - prompt_templates.py: rag_system_prompt, citation_template, conversation_template
   - response_parser.py: extract_citations(), format_markdown(), validate_response()

3. Streaming (src/generation/):
   - async_generator.py: stream_response(), buffer_tokens(), handle_errors()
   - sse_formatter.py: format_sse(), heartbeat()

4. API (api/endpoints/rag.py):
   - POST /rag/query, POST /rag/stream, GET /rag/sources

5. Config (config/generation.py + .env):
   - LLM_PROVIDER, MODEL_NAME, MAX_TOKENS, TEMPERATURE, CONTEXT_WINDOW, TOP_K_CHUNKS
   - OPENAI_API_KEY, ANTHROPIC_API_KEY, GROQ_API_KEY (FREE!), OLLAMA_BASE_URL

6. Testing:
   - tests/test_generation.py: Unit tests for all components
   - tests/test_e2e_rag.py: Full pipeline, citations, context overflow

7. Examples: simple_rag.py, streaming_rag.py, multi_turn_rag.py

8. Docs: generation.md, streaming.md, providers.md, README.md update

Best Practices: async/await, retry logic, caching, token logging, rate limits, citation validation, edge case testing

Groq FREE: 30 req/min, fastest inference, OpenAI-compatible, llama-3.1-70b/mixtral-8x7b

Deliverable: Complete RAG generation pipeline with streaming, context management, and provider flexibility.")

Phase 4: Validation
Goal: Verify generation pipeline works end-to-end

Actions:
- Verify structure: !{bash ls -la src/generation/}
- Check LLM client: !{bash test -f src/generation/llm_client.py && echo "exists"}
- Check streaming: !{bash test -f src/generation/async_generator.py && echo "exists"}
- Validate Python syntax: !{bash python3 -m py_compile src/generation/*.py 2>&1 | head -20}
- Test imports: !{bash python3 -c "from src.generation.query_engine import generate_response; print('OK')" 2>&1}
- Check examples: !{bash ls examples/*rag*.py 2>/dev/null}
- Update todos marking validation complete

Phase 5: End-to-End Test
Goal: Run complete RAG query to verify integration

Actions:
- Run simple RAG example: !{bash cd . && python3 examples/simple_rag.py 2>&1 | head -50}
- If successful, show sample output
- If errors, display for debugging
- Test streaming if available: !{bash python3 examples/streaming_rag.py 2>&1 | head -30}
- Update todos

Phase 6: Summary
Goal: Present setup information and next steps

Actions:
Display:
- RAG Generation Pipeline created
- Provider: [from user selection]
- Streaming: Enabled
- Context management: Configured
- Key files: query_engine.py, llm_client.py, context_manager.py

Next Steps:
1. Configure API key in .env:
   - Groq (FREE): Get key at https://console.groq.com
   - OpenAI: https://platform.openai.com/api-keys
   - Anthropic: https://console.anthropic.com
2. pip install -r requirements.txt
3. Test basic RAG: python examples/simple_rag.py
4. Test streaming: python examples/streaming_rag.py
5. Integrate with API: Add to FastAPI endpoints
6. Monitor token usage and costs

Performance Tips:
- Use Groq for fast free inference
- Cache frequent queries
- Limit context chunks (top_k=3-5)
- Stream for better UX
- Monitor context window usage

Mark all todos complete.

Resources:
- LlamaIndex Query: https://docs.llamaindex.ai/en/stable/examples/query_engine/
- LangChain RAG: https://python.langchain.com/docs/tutorials/rag/
- Groq Console: https://console.groq.com
- OpenAI API: https://platform.openai.com/docs
