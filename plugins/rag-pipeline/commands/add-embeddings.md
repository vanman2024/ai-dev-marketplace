---
description: Configure embedding models (OpenAI, HuggingFace, Cohere, Voyage)
argument-hint: [model-provider]
allowed-tools: Task, Read, Write, Edit, Bash, AskUserQuestion, Glob, Skill
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

Goal: Configure embedding models for RAG pipeline with FREE HuggingFace or paid providers (OpenAI, Cohere, Voyage).

Core Principles:
- Highlight FREE HuggingFace models first
- Test embeddings before completing
- Calculate cost estimates for paid providers
- Provide clear next steps

Phase 1: Provider Selection
Goal: Determine which embedding provider to configure

Actions:
- Parse $ARGUMENTS to check if provider specified
- If $ARGUMENTS empty, use AskUserQuestion:
  "Which embedding provider?
   1. HuggingFace (FREE local - recommended for testing)
   2. OpenAI (Paid - high quality embeddings)
   3. Cohere (Paid - multilingual support)
   4. Voyage (Paid - specialized for retrieval)

   Recommendation: Start with FREE HuggingFace, upgrade later if needed."
- Display provider info (pricing, models, requirements)

Phase 2: Environment Detection
Goal: Understand project setup

Actions:
- Check config files: !{bash ls -la requirements.txt pyproject.toml package.json 2>/dev/null}
- Detect Python/Node.js environment
- Check .env exists: !{bash test -f .env && echo "exists" || echo "not found"}
- Identify package manager (pip, poetry, npm)

Phase 3: Installation & Configuration
Goal: Install dependencies and configure provider

Actions:

Task(description="Install and configure embeddings", subagent_type="rag-pipeline:embedding-specialist", prompt="You are the embedding-specialist agent. Install and configure $ARGUMENTS embedding provider.

Provider Details:

HuggingFace (FREE): Install sentence-transformers, torch. Popular models: all-MiniLM-L6-v2 (384d, fast), all-mpnet-base-v2 (768d, quality). Docs: https://huggingface.co/models?pipeline_tag=sentence-similarity. No API key needed.

OpenAI: Install openai package. Models: text-embedding-ada-002, text-embedding-3-small/large. Docs: https://platform.openai.com/docs/guides/embeddings. Needs OPENAI_API_KEY.

Cohere: Install cohere package. Models: embed-english-v3.0, embed-multilingual-v3.0. Docs: https://docs.cohere.com/docs/embeddings. Needs COHERE_API_KEY.

Voyage: Install voyageai package. Models: voyage-2, voyage-code-2. Docs: https://docs.voyageai.com/. Needs VOYAGE_API_KEY.

Tasks:
1. Install appropriate packages for detected environment
2. For paid providers: Ask user for API key using AskUserQuestion, add to .env file
3. For HuggingFace: Skip API key (local processing)
4. Create embeddings_config.yaml with: provider, model, dimensions, pricing (if paid), device settings
5. Verify installation with test import
6. Report installed packages and versions

Expected output: Configuration file path, installed packages, API key status")

Phase 4: Testing & Validation
Goal: Verify embeddings work correctly

Actions:

Task(description="Test embedding generation", subagent_type="rag-pipeline:embedding-specialist", prompt="You are the embedding-specialist agent. Test embedding generation for $ARGUMENTS provider.

Create test_embeddings script that:
1. Loads config from Phase 3
2. Generates embeddings for sample text: 'RAG pipeline test document'
3. Validates output: correct dimensions, numeric values, proper shape
4. Measures: generation time, tokens processed, cost estimate (if paid)

For HuggingFace: Test model loading, check GPU/CPU usage, verify cache location
For Paid APIs: Validate API key, test connection, verify response format

Expected output: Test script path, results (pass/fail), sample vector (first 5 values), performance metrics")

Phase 5: Cost Analysis
Goal: Calculate and display cost estimates

Actions:
- Read test results from Phase 4
- If HuggingFace: Display "Cost: FREE (local)", show compute requirements
- If paid: Calculate costs for 1K, 10K, 100K documents (~500 words each)
- Display pricing breakdown and monthly estimates
- Compare to FREE HuggingFace option
- Provide cost optimization tips

Phase 6: Summary
Goal: Document setup and next steps

Actions:
- Summarize: Provider, model, dimensions, cost, location (local/cloud)
- List created files: config file, test script, .env status
- Explain trade-offs: cost vs quality vs speed
- Next steps:
  * Run test: python test_embeddings.py
  * Add vector database: /rag-pipeline:add-vectorstore
  * Batch process existing documents
- Provide documentation links and troubleshooting resources
