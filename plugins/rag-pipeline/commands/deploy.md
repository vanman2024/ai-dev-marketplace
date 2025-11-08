---
description: Deploy RAG application to production platforms
argument-hint: [platform]
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

Goal: Deploy RAG application to production platforms with platform-specific configuration and health validation.

Core Principles:
- Verify RAG pipeline readiness before deployment
- Fetch latest platform documentation
- Generate platform-specific deployment files
- Validate deployment with automated health checks

Phase 1: Pre-Deployment Verification
Goal: Ensure RAG application is complete and ready

Actions:
- Create deployment tracking: TodoWrite
- Check project structure: !{bash ls -la src/ config/ requirements.txt 2>/dev/null || echo "missing"}
- Verify RAG pipeline: !{bash test -f src/rag_pipeline.py -o -f src/generation/query_engine.py && echo "ready" || echo "incomplete"}
- Check API exists: !{bash find . -name "*api*" -o -name "app.py" 2>/dev/null | head -3}
- If incomplete, warn: "Run /rag-pipeline:init or build commands first"
- Parse $ARGUMENTS for platform override
- AskUserQuestion: "Platform? (1) DigitalOcean, (2) Vercel, (3) HuggingFace Spaces, (4) Google Colab"
- Record selection for documentation fetch

Phase 2: Documentation Loading
Goal: Fetch platform deployment guides

Actions:
Use WebFetch to load documentation:
- https://docs.digitalocean.com/products/app-platform/
- https://vercel.com/docs
- https://huggingface.co/docs/hub/spaces
- https://fastapi.tiangolo.com/deployment/

Wait for completion. Update todos.

Phase 3: Deployment Configuration
Goal: Generate platform-specific configs and API endpoints

Actions:

Task(description="Generate deployment files", subagent_type="rag-pipeline:rag-deployment-agent", prompt="You are the rag-deployment-agent. Generate deployment configuration for RAG application.

Platform: $ARGUMENTS (from user selection)

Files to Create:

**DigitalOcean:**
- .do/app.yaml: Service spec with health checks, environment, routes
- Dockerfile: Multi-stage build (python:3.11-slim base)
- .dockerignore: venv/, .git/, __pycache__/, *.pyc, data/raw/
- scripts/deploy_do.sh: doctl app create/update commands

**Vercel:**
- vercel.json: Routes, builds, environment variables
- api/index.py: Serverless function wrapper for RAG endpoint
- .vercelignore: Exclude venv/, data/

**HuggingFace:**
- app.py: Gradio interface with RAG query box and response display
- requirements.txt: Ensure HF-compatible (no heavy deps)
- README.md: Space card with usage instructions

**Colab:**
- notebooks/deploy_demo.ipynb: Complete RAG demo with setup cells
- README_COLAB.md: Badge and instructions

**Universal (all platforms):**
- api/main.py (if not exists): FastAPI with POST /api/query, GET /health, GET /docs
- .env.production.example: OPENAI_API_KEY, GROQ_API_KEY, VECTOR_DB_PATH, CORS_ORIGINS
- health/check.py: check_vector_db(), check_llm(), check_embeddings()
- docs/deployment.md: Platform instructions, domain setup, monitoring, troubleshooting

Best Practices: Environment variables for secrets, rate limiting, CORS configuration, async endpoints, error handling, deployment validation.

Groq Recommendation: FREE API with 30 req/min, fastest inference, perfect for RAG deployments.

Deliverable: Complete platform-ready deployment configuration.")

Phase 4: Environment Setup
Goal: Configure production environment variables

Actions:
- Check .env.production: !{bash test -f .env.production && echo "exists" || echo "needed"}
- List required vars: !{bash grep -E "^[A-Z_]+=" .env.example 2>/dev/null | cut -d= -f1}
- Display platform-specific instructions:
  - DigitalOcean: App Platform > Settings > Environment Variables
  - Vercel: Dashboard > Settings > Environment Variables or vercel env add
  - HuggingFace: Space > Settings > Repository Secrets
  - Colab: Use Colab Secrets or getpass()
- Update todos

Phase 5: Deploy
Goal: Execute platform deployment

Actions:
Execute based on platform:

**DigitalOcean:**
!{bash command -v doctl && echo "ready" || echo "install: brew install doctl"}
!{bash bash scripts/deploy_do.sh 2>&1 | tee deploy.log}

**Vercel:**
!{bash command -v vercel && echo "ready" || echo "install: npm i -g vercel"}
!{bash vercel --prod 2>&1 | tee deploy.log}

**HuggingFace:**
!{bash git remote -v | grep -q huggingface && echo "configured" || echo "add remote"}
!{bash git push huggingface main 2>&1 | tee deploy.log}

**Colab:**
Display notebook path and Colab open link (no deployment)

Extract deployment URL from logs. Update todos.

Phase 6: Health Validation
Goal: Verify deployment is functional

Actions:
- Wait for startup: !{bash sleep 10}
- Test health: !{bash curl -f [deployment-url]/health 2>&1}
- Test RAG query: !{bash curl -X POST [deployment-url]/api/query -H "Content-Type: application/json" -d '{"query":"test"}' 2>&1}
- Verify response format and status codes
- Update todos with results

Phase 7: Summary
Goal: Display deployment info and next steps

Actions:
Display:
- Status: SUCCESS/FAILED
- Platform: [selected]
- Endpoint: https://[url]
- Health: /health
- API Docs: /docs
- Logs: deploy.log

API Usage:
```bash
curl -X POST https://[url]/api/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Your question"}'
```

Next Steps:
1. Test at https://[url]/docs (Swagger UI)
2. Configure custom domain (platform settings)
3. Setup monitoring and alerts
4. Add authentication/API keys
5. Implement rate limiting
6. Monitor costs and usage

Troubleshooting:
- Check logs: [platform command]
- Verify environment variables
- Test vector DB connection
- Validate API keys

Resources:
- DigitalOcean: https://cloud.digitalocean.com/apps
- Vercel: https://vercel.com/dashboard
- HuggingFace: https://huggingface.co/spaces
- Groq (FREE): https://console.groq.com

Mark todos complete.

Deployment live at: https://[endpoint-url]
