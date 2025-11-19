---
description: Add vector search capabilities with KNN, range queries, and metadata filtering
argument-hint: <feature-description>
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Implement comprehensive vector search capabilities in Redis with KNN search, range queries, metadata filtering, and hybrid search patterns.

Core Principles:
- Detect existing Redis configuration before assuming structure
- Ask clarifying questions about vector dimensions and use cases
- Follow Redis vector search best practices and indexing strategies
- Provide runtime query configuration examples

## Security: API Key Handling

**CRITICAL:** When generating any configuration files or code:

- Never hardcode actual API keys or secrets
- Never include real credentials in examples
- Always use placeholders: `your_redis_key_here`
- Always read from environment variables in code
- Always add `.env*` to `.gitignore` (except `.env.example`)
- Always document where to obtain keys

**Placeholder format:** `redis_{env}_your_key_here`

Phase 1: Discovery
Goal: Understand project context and vector search requirements

Actions:
- Parse $ARGUMENTS for feature description and requirements
- Check if Redis is already configured: @.env, @package.json, @requirements.txt
- Detect project language/framework:
  - !{bash ls package.json pyproject.toml go.mod 2>/dev/null}
- Load existing Redis configuration if present

Phase 2: Requirements Gathering
Goal: Clarify vector search specifications

Actions:
- If $ARGUMENTS lacks detail, use AskUserQuestion to gather:
  - Vector dimension (e.g., 1536 for OpenAI embeddings)
  - Use case (semantic search, recommendations, image similarity)
  - Metadata fields for filtering (user_id, category, timestamp)
  - Distance metric (cosine, euclidean, inner product)
- Summarize requirements and confirm with user

Phase 3: Analysis
Goal: Understand existing codebase patterns

Actions:
- Search for existing Redis usage:
  - !{bash find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) -exec grep -l "redis\|Redis" {} \; 2>/dev/null | head -10}
- Check for existing vector/embedding code:
  - !{bash find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) -exec grep -l "embedding\|vector" {} \; 2>/dev/null | head -10}
- Read relevant files to understand current architecture
- Identify integration points for vector search

Phase 4: Planning
Goal: Design the vector search implementation

Actions:
- Outline approach: index schema, query patterns, integration points
- Present plan: index config, code structure, query examples, performance notes
- Get user approval before implementing

Phase 5: Implementation
Goal: Build vector search capabilities with specialist agent

DO NOT START WITHOUT USER APPROVAL

Actions:

Task(description="Implement Redis vector search", subagent_type="redis:vector-search-specialist", prompt="You are the redis:vector-search-specialist agent. Implement comprehensive vector search capabilities for $ARGUMENTS.

Requirements from discovery:
- Vector dimension: [dimension from Phase 2]
- Use case: [use case from Phase 2]
- Metadata fields: [fields from Phase 2]
- Distance metric: [metric from Phase 2]
- Project language: [detected language]

Implementation Requirements:
- Create vector index with proper schema configuration
- Implement KNN (k-nearest neighbor) search queries
- Implement vector range queries for similarity thresholds
- Implement metadata filtering combined with vector search
- Implement hybrid search (vector + keyword/tag filtering)
- Provide runtime query configuration examples
- Include error handling and validation
- Add comprehensive code comments

Search Patterns to Implement:
1. Pure KNN: Find top-k most similar vectors
2. Range Query: Find all vectors within distance threshold
3. Metadata Filter: KNN with user_id/category/tag filters
4. Hybrid Search: Combine vector similarity with keyword matching
5. Multi-vector: Search across multiple vector fields

Expected Deliverables:
- Index creation code with schema definition
- Query functions for each search pattern
- Example usage code demonstrating all patterns
- Configuration file with tunable parameters
- Documentation of query capabilities and performance tips

Use existing project patterns and follow codebase conventions.")

Phase 6: Verification
Goal: Validate vector search implementation

Actions:
- Check that all required files were created
- Verify index schema includes all specified fields
- Verify all search patterns are implemented:
  - KNN search
  - Range queries
  - Metadata filtering
  - Hybrid search
- Review code for proper error handling
- Check for placeholder API keys (no hardcoded secrets)
- Run type checking if applicable:
  - !{bash npm run typecheck 2>/dev/null || python -m mypy . 2>/dev/null || echo "No type checking available"}

Phase 7: Summary
Goal: Document what was accomplished

Actions:
- Summarize implementation:
  - Files created and their purposes
  - Index schema configuration
  - Available search patterns
  - Example queries for each pattern
  - Configuration parameters
- Highlight key features:
  - Vector dimension and distance metric
  - Metadata filtering capabilities
  - Hybrid search options
  - Performance considerations
- Suggest next steps:
  - Test with sample embeddings
  - Tune index parameters for dataset size
  - Add monitoring/logging for query performance
  - Consider adding batch indexing for large datasets
