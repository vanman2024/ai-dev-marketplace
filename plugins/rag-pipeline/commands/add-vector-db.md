---
description: Configure vector database (pgvector, Chroma, Pinecone, Weaviate, Qdrant, FAISS)
argument-hint: [database-type]
allowed-tools: Task, Read, Write, Edit, Bash, AskUserQuestion, Glob, Grep, mcp__supabase
---

**Arguments**: $ARGUMENTS

Goal: Configure and setup a vector database for RAG pipeline with cost-aware recommendations

Core Principles:
- Highlight free and open-source options (pgvector, Chroma, FAISS)
- Fetch vendor-specific documentation
- Generate working configuration
- Test connectivity before completion
- Provide cost estimates and free tier information

Phase 1: Database Selection
Goal: Determine which vector database to configure

Actions:
- Check if $ARGUMENTS specifies a database type
- If not provided, ask user which vector database:

  "Which vector database would you like to configure?

  **Free & Open Source:**
  - pgvector (Postgres extension, free, production-ready)
  - Chroma (embedded or server, free, developer-friendly)
  - FAISS (Facebook AI, in-memory, free, high-performance)

  **Managed Services (paid with free tiers):**
  - Pinecone (serverless, free tier: 100K vectors)
  - Weaviate (cloud or self-hosted, free tier available)
  - Qdrant (cloud or self-hosted, free tier: 1GB cluster)

  Enter database name (pgvector, chroma, pinecone, weaviate, qdrant, or faiss):"

- Store selection for use in subsequent phases

Phase 2: Fetch Documentation
Goal: Load vendor-specific setup documentation

Actions:
Fetch docs based on selection (WebFetch in parallel):
- pgvector: github.com/pgvector/pgvector, supabase.com/docs/guides/ai/vector-columns
- Chroma: docs.trychroma.com, docs.trychroma.com/getting-started
- Pinecone: docs.pinecone.io, docs.pinecone.io/guides/get-started/quickstart
- Weaviate: weaviate.io/developers/weaviate, weaviate.io/developers/weaviate/quickstart
- Qdrant: qdrant.tech/documentation, qdrant.tech/documentation/quickstart
- FAISS: faiss.ai, github.com/facebookresearch/faiss/wiki/Getting-started

Phase 3: Project Discovery
Goal: Understand existing project structure

Actions:
- Detect project type: Check for package.json, requirements.txt, pyproject.toml
- Load existing configuration if present
- Identify framework (Next.js, FastAPI, Express, etc.)
- Check if database client libraries already installed
- Locate or create config directory for database settings

Phase 4: Implementation
Goal: Install dependencies and generate configuration

Actions:

Task(description="Setup vector database configuration", subagent_type="general-purpose", prompt="Configure $ARGUMENTS for RAG pipeline.

Install dependencies based on detected language (Python/Node.js):
- pgvector: psycopg2-binary+pgvector or pg+pgvector
- Chroma/Pinecone/Weaviate/Qdrant: respective client libraries
- FAISS: faiss-cpu or faiss-gpu (Python only)

Create config/vector_db.py or config/vector-db.ts with connection params, dimensions (default 1536), distance metric.

Create schema/collection setup script for chosen database.

Add environment variables to .env.example (DATABASE_URL, API keys, etc).

Create scripts/test_vector_db script to verify connectivity and vector operations.

Use fetched docs for latest patterns.")

Phase 5: Connectivity Test
Goal: Verify the database configuration works

Actions:
- Prompt user to configure environment variables if needed
- Run the test script created in Phase 4
- For pgvector with Supabase: Optionally use mcp__supabase tool to verify connection
- Display test results (success/failure)
- If failures occur, provide troubleshooting guidance
- Verify vector operations work (insert test vector, query similarity)

Phase 6: Cost & Usage Summary
Goal: Inform user about pricing and free tier limits

Actions:
Display summary for chosen database:

Free Options:
- pgvector: Free (uses Postgres), Supabase: 500MB free, production-ready
- Chroma: Free/OSS, embedded or server, good for dev/medium datasets
- FAISS: Free/OSS, in-memory, high-performance, custom persistence needed

Managed Services:
- Pinecone: Free tier 100K vectors, paid pricing starts at low cost per GB/month, fully managed
- Weaviate: 14-day sandbox free, paid clusters from USD 25/month, or self-host OSS
- Qdrant: 1GB free cluster (1M vectors), paid from USD 25/month for 2GB, or self-host OSS

Next Steps:
- Insert embeddings, perform similarity search, update/delete vectors
- Monitor performance and optimize
- Link to relevant documentation

Notes:
- Check existing config before overwriting
- Use proper error handling and connection pooling
- Recommend pgvector for cost-conscious, Chroma for dev, managed for production
- Test vector operations before complete
