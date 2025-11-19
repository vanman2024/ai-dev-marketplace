---
description: Create vector index with FLAT or HNSW algorithm for similarity search
argument-hint: <index-name> [--type=FLAT|HNSW] [--metric=COSINE|L2|IP] [--dimensions=N]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Create a Redis vector index configured for similarity search with support for FLAT or HNSW algorithms, custom distance metrics, and metadata fields.

Core Principles:
- Detect existing Redis configuration before creating index
- Validate schema and parameters before execution
- Support both FLAT (exact search) and HNSW (approximate) algorithms
- Configure appropriate distance metrics (COSINE, L2, IP)
- Add metadata fields for filtering and hybrid search

Phase 1: Discovery
Goal: Understand project context and requirements

Actions:
- Parse $ARGUMENTS to extract:
  - Index name (required)
  - Index type: --type=FLAT or --type=HNSW (default: HNSW)
  - Distance metric: --metric=COSINE|L2|IP (default: COSINE)
  - Vector dimensions: --dimensions=N (required)
  - Additional metadata fields (optional)
- Detect project structure and Redis configuration:
  - Check for existing Redis connection files
  - Look for environment variables or config files
  - Example: !{bash find . -name "*.env*" -o -name "*redis*config*" 2>/dev/null | head -5}
- If any required parameters are missing, use AskUserQuestion:
  - What is the vector dimension? (e.g., 1536 for OpenAI embeddings)
  - Which index type? (FLAT for exact search, HNSW for approximate)
  - Which distance metric? (COSINE for normalized vectors, L2/IP for others)
  - What metadata fields to include? (e.g., user_id, category, timestamp)

Phase 2: Validation
Goal: Verify inputs and environment are ready

Actions:
- Validate index parameters:
  - Index name is valid (alphanumeric, underscores)
  - Dimensions is positive integer
  - Type is either FLAT or HNSW
  - Metric is COSINE, L2, or IP
- Check Redis connection configuration:
  - Verify REDIS_URL or connection settings exist
  - Example: @.env (if exists)
- Confirm prerequisites:
  - Redis Stack or RedisJSON module available
  - Vector search capability enabled

Phase 3: Implementation
Goal: Create vector index using specialized agent

Actions:

Task(description="Create vector index", subagent_type="vector-index-architect", prompt="You are the vector-index-architect agent. Create a Redis vector index for $ARGUMENTS.

Context:
- Project directory detected in Phase 1
- Index parameters validated in Phase 2
- Redis configuration available

Requirements:
- Create FT.CREATE command with proper schema
- Configure index type (FLAT or HNSW) based on parameters
- Set up vector field with correct dimensions and distance metric
- Add metadata fields for filtering (if specified)
- Include schema validation
- Generate example queries for the index
- Provide connection code snippet

Index Configuration:
- Name: [extracted from $ARGUMENTS]
- Type: [FLAT or HNSW]
- Metric: [COSINE, L2, or IP]
- Dimensions: [extracted from $ARGUMENTS]
- Metadata: [extracted from $ARGUMENTS or defaults]

Expected output:
1. Redis FT.CREATE command for index creation
2. Schema validation script
3. Example search queries (KNN, range, hybrid)
4. Connection code snippet for application integration
5. Performance tuning recommendations")

Phase 4: Verification
Goal: Validate the created index configuration

Actions:
- Review agent's output for completeness
- Check that FT.CREATE command includes:
  - Correct index type (FLAT or HNSW)
  - Vector field with proper VECTOR parameters
  - Distance metric configuration
  - All metadata fields
- Verify example queries are syntactically correct
- Confirm connection code matches project language/framework

Phase 5: Summary
Goal: Report index creation and next steps

Actions:
- Display index configuration summary:
  - Index name and type
  - Vector dimensions and metric
  - Metadata fields included
  - Algorithm parameters (if HNSW: M, EF_CONSTRUCTION, EF_RUNTIME)
- Show FT.CREATE command to execute
- Provide example search queries
- Suggest next steps:
  - Execute FT.CREATE command on Redis instance
  - Insert sample vectors for testing
  - Integrate search queries into application
  - Monitor index performance and adjust parameters
