---
description: Integrate LangChain vector store and memory with Redis
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS
**Security**: @~/.claude/plugins/marketplaces/dev-lifecycle-marketplace/docs/security/SECURITY-RULES.md

Goal: Integrate LangChain vector store and memory capabilities with Redis for AI applications

Core Principles:
- Detect existing LangChain usage before adding
- Ask user which features they need (vector store, memory, chat history, semantic cache)
- Use RedisVectorStore for embeddings and semantic search
- Implement appropriate memory types based on use case
- Follow LangChain best practices and patterns

Phase 1: Discovery
Goal: Understand project context and LangChain usage

Actions:
- Detect if LangChain is already installed
- Check for existing vector store or memory implementations
- Identify AI/LLM usage patterns in codebase
- Example: !{bash grep -r "langchain" . --include="*.py" --include="*.js" --include="*.ts" 2>/dev/null | head -5}

Phase 2: Requirements Gathering
Goal: Determine which LangChain + Redis features to integrate

Actions:
- Use AskUserQuestion to determine needs:
  - Which features? (vector store, conversation memory, entity memory, summary memory, chat history, semantic cache)
  - What embedding model? (OpenAI, Anthropic, local model)
  - Memory retention policy? (session-based, persistent, TTL)
  - Semantic similarity threshold? (0.85-0.95 recommended)
- Confirm project type (Python, JavaScript/TypeScript)
- Validate Redis connection details available

Phase 3: Planning
Goal: Design the LangChain + Redis integration approach

Actions:
- Based on requirements, plan integration:
  - Vector store: RedisVectorStore with HNSW indexes
  - Memory types: ConversationBufferMemory, EntityMemory, ConversationSummaryMemory
  - Chat history: RedisChatMessageHistory for persistence
  - Semantic cache: Integrated with LangChain cache layer
- Identify files to create/modify
- Present plan to user for approval

Phase 4: Implementation
Goal: Integrate LangChain features with Redis

Actions:

Task(description="Integrate LangChain with Redis", subagent_type="redis:langchain-integrator", prompt="You are the redis:langchain-integrator agent. Integrate LangChain vector store and memory with Redis for $ARGUMENTS.

Context: User selected the following features to integrate
Features requested: [List from Phase 2]
Embedding model: [From Phase 2]
Memory policy: [From Phase 2]
Similarity threshold: [From Phase 2]

Requirements:
- Install langchain-redis package and dependencies
- Configure RedisVectorStore with HNSW indexes for vector similarity
- Implement selected memory types (conversation, entity, summary)
- Set up RedisChatMessageHistory for chat persistence
- Integrate semantic cache if requested
- Follow LangChain patterns for retrieval chains
- Add environment variable configuration (REDIS_URL, embedding API keys)
- Create example usage code showing integration
- Add error handling and connection validation
- Include cost optimization recommendations

Expected output:
- LangChain + Redis integration code
- Configuration files with placeholder API keys
- Example usage demonstrating features
- Documentation on memory patterns and retention policies")

Phase 5: Verification
Goal: Validate LangChain + Redis integration works

Actions:
- Verify all dependencies installed
- Check configuration files use placeholders (no hardcoded keys)
- Test vector store connection and indexing
- Test memory persistence and retrieval
- Validate chat history storage
- Example: !{bash python -c "from langchain_redis import RedisVectorStore; print('Import successful')" 2>&1}

Phase 6: Summary
Goal: Document integration and provide guidance

Actions:
- Summarize what was integrated:
  - Vector store capabilities (embedding search, similarity)
  - Memory types implemented (conversation, entity, summary)
  - Chat history persistence
  - Semantic cache if enabled
- Highlight key files created/modified
- Provide cost optimization tips:
  - Semantic cache hit rate monitoring
  - Memory TTL tuning
  - Embedding reuse strategies
- Suggest next steps:
  - Test with real queries
  - Tune similarity thresholds
  - Monitor memory usage
  - Set up chat history cleanup policies
