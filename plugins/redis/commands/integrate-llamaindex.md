---
description: Integrate LlamaIndex VectorStoreIndex and query engines with Redis
argument-hint: [feature-type]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Set up complete LlamaIndex integration with Redis vector store for semantic search, RAG applications, and AI-powered data retrieval

Core Principles:
- Detect project structure and framework
- Use RedisVectorStore for optimal performance
- Configure appropriate query and chat engines
- Follow LlamaIndex best practices
- Provide working examples

Phase 1: Discovery
Goal: Understand project context and requirements

Actions:
- Parse $ARGUMENTS for integration type (basic, rag, chat, custom)
- Detect project structure and dependencies
- Check for existing LlamaIndex or Redis setup
- Example: !{bash test -f package.json && echo "node" || test -f pyproject.toml && echo "python" || test -f requirements.txt && echo "python"}
- Load existing configuration files if present
- Example: @.env

Phase 2: Requirements Gathering
Goal: Clarify integration specifications

Actions:
- If $ARGUMENTS is unclear or minimal, use AskUserQuestion to gather:
  - Which LlamaIndex features? (VectorStoreIndex, query engine, chat engine, agents)
  - Data source types? (documents, text, structured data)
  - Vector embedding model? (OpenAI, HuggingFace, custom)
  - Index strategy? (FLAT, HNSW)
  - Memory requirements? (chat history, conversation memory)
- Summarize requirements and confirm approach

Phase 3: Environment Analysis
Goal: Assess current setup and identify gaps

Actions:
- Check for required dependencies
- Python: !{bash pip list | grep -E "llama-index|redis" || echo "Not found"}
- Node.js: !{bash npm list llamaindex redis 2>/dev/null || echo "Not found"}
- Verify Redis connection details
- Check for existing vector indices
- Identify integration points in codebase

Phase 4: Integration Planning
Goal: Design the implementation approach

Actions:
- Outline integration strategy based on findings
- Determine file structure (index setup, query handlers, utilities)
- Plan configuration approach (environment variables, config files)
- Identify example use cases to implement
- Present plan to user for confirmation

Phase 5: Implementation
Goal: Execute LlamaIndex Redis integration

Actions:

Task(description="Integrate LlamaIndex with Redis", subagent_type="redis:llamaindex-integrator", prompt="You are the llamaindex-integrator agent. Implement complete LlamaIndex integration with Redis for $ARGUMENTS.

Project Context: [Context from Phase 3]

Requirements:
- Set up RedisVectorStore with appropriate configuration
- Implement VectorStoreIndex for semantic search
- Configure query engines (vector, keyword, hybrid)
- Add chat engines with conversation memory if requested
- Create working examples and documentation
- Follow security best practices (no hardcoded API keys)
- Use environment variables for all credentials

Integration Type: [From Phase 2]
Embedding Model: [From Phase 2]
Index Strategy: [From Phase 2]
Additional Features: [From Phase 2]

Expected Output:
- Complete integration code files
- Configuration templates (.env.example)
- Usage examples and documentation
- Test cases or validation scripts")

Phase 6: Verification
Goal: Validate the integration works correctly

Actions:
- Review generated integration code
- Check all configuration files use placeholders
- Verify .env.example exists with proper placeholders
- Ensure .gitignore protects secrets
- Run validation if applicable
- Python: !{bash python -m pytest tests/ -v 2>/dev/null || echo "No tests found"}
- Node.js: !{bash npm test 2>/dev/null || echo "No tests configured"}

Phase 7: Summary
Goal: Document what was accomplished

Actions:
- Summarize integration components created:
  - Vector store configuration
  - Index setup code
  - Query engine implementations
  - Chat engine setup (if applicable)
  - Example usage files
  - Documentation
- Highlight key configuration options
- Provide next steps:
  - How to obtain API keys (OpenAI, etc.)
  - How to populate vector index with data
  - How to run examples
  - How to customize for specific use cases
- Show file locations with absolute paths
