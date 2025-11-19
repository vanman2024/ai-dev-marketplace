---
description: Add RedisVL (Redis Vector Library) integration for vector similarity search with HNSW
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Integrate RedisVL for vector similarity search with HNSW indexing

Core Principles:
- Detect project language and framework before setup
- Use environment variables for Redis configuration
- Follow RedisVL best practices for vector search
- Provide clear setup instructions and examples

Phase 1: Discovery
Goal: Understand project structure and requirements

Actions:
- Parse $ARGUMENTS for project path (default to current directory)
- Detect project language (Python, Node.js, etc.)
- Check if Redis is already configured
- Load package manager files: @package.json or @pyproject.toml or @requirements.txt
- Detect existing vector search implementations

Phase 2: Requirements Gathering
Goal: Clarify vector search configuration needs

Actions:
- If requirements are unclear, use AskUserQuestion to gather:
  - What data will be indexed? (documents, images, embeddings)
  - What embedding model? (OpenAI, Cohere, local model)
  - What distance metric? (cosine, euclidean, dot product)
  - Index size expectations? (1K, 100K, 1M+ vectors)
  - HNSW parameters? (M, ef_construction, ef_runtime)
- Document user requirements for agent context

Phase 3: Pre-flight Validation
Goal: Verify environment readiness

Actions:
- Check Redis availability: !{bash redis-cli ping 2>/dev/null || echo "Redis not running"}
- Verify Redis version supports vector search (7.2+)
- Check if RedisVL is already installed
- Detect conflicts with existing vector search libraries

Phase 4: Implementation
Goal: Execute RedisVL integration

Actions:

Task(description="Add RedisVL integration", subagent_type="redis:redisvl-integrator", prompt="You are the redisvl-integrator agent. Add RedisVL (Redis Vector Library) integration for $ARGUMENTS.

Project Context:
- Language: [Detected from Phase 1]
- Framework: [Detected from Phase 1]
- Existing Redis config: [From Phase 1]

User Requirements:
- Data type: [From Phase 2]
- Embedding model: [From Phase 2]
- Distance metric: [From Phase 2]
- Index size: [From Phase 2]
- HNSW parameters: [From Phase 2]

Implementation Tasks:
1. Install RedisVL package (pip install redisvl OR npm install redisvl)
2. Configure Redis connection with environment variables
3. Create vector index schema with HNSW algorithm
4. Generate example code for:
   - Creating vector index
   - Storing embeddings
   - Performing similarity search
   - Updating/deleting vectors
5. Add configuration file (.env.example with placeholders)
6. Create setup documentation

Security Requirements:
- Use REDIS_URL environment variable
- Never hardcode credentials
- Add .env to .gitignore
- Document where to get Redis credentials

Expected Deliverables:
- RedisVL package installed
- Vector index schema file
- Example usage code
- Environment variable template
- Setup documentation with next steps")

Phase 5: Verification
Goal: Validate RedisVL integration

Actions:
- Verify RedisVL package is installed
- Check environment variable template exists
- Validate example code syntax
- Test Redis connection if available
- Run type checking if TypeScript: !{bash npm run typecheck 2>/dev/null || true}
- Run linting if configured: !{bash npm run lint 2>/dev/null || pylint . 2>/dev/null || true}

Phase 6: Summary
Goal: Document what was accomplished

Actions:
- Summarize changes made:
  - Package installed
  - Files created/modified
  - Vector index configuration
  - HNSW parameters used
- Provide next steps:
  - Set Redis URL in environment
  - Configure embedding model
  - Run example code to test
  - Customize HNSW parameters for production
- Share relevant file paths (absolute paths)
- Display RedisVL documentation links
