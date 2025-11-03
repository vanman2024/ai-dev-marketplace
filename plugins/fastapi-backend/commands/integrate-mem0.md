---
description: Add Mem0 memory layer to FastAPI endpoints with user context and conversation history
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, mcp__context7
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

Goal: Integrate Mem0 memory layer into FastAPI backend to enable AI memory capabilities for user context, conversation history, and personalized responses.

Core Principles:
- Detect existing FastAPI project structure
- Ask user for memory configuration preferences
- Follow FastAPI dependency injection patterns
- Configure Mem0 with vector store and LLM providers
- Provide clear examples and documentation

Phase 1: Discovery

Goal: Understand the FastAPI project structure and existing setup

Actions:

Check if we're in a FastAPI project:
!{bash test -f requirements.txt && echo "Found requirements.txt" || echo "No requirements.txt"}

Load requirements.txt to check existing dependencies:
@requirements.txt

Check for main FastAPI application file:
!{bash find . -name "main.py" -o -name "app.py" | head -1}

Detect project structure (app/, routes/, services/):
!{bash ls -d app 2>/dev/null || ls -d src 2>/dev/null || echo "Root structure"}

Check for existing Mem0 or memory-related dependencies:
!{bash grep -E "(mem0|memory|vector)" requirements.txt 2>/dev/null || echo "No memory dependencies found"}

Phase 2: Requirements Gathering

Goal: Ask user about Mem0 configuration preferences

Actions:

Use AskUserQuestion to gather:
- Which Mem0 deployment? (Options: Hosted Platform with API key, Self-hosted with vector store)
- Vector store preference for self-hosted? (Qdrant, Pinecone, Weaviate, ChromaDB - default Qdrant)
- LLM provider for Mem0? (OpenAI, Anthropic - default OpenAI)
- Do you want memory API endpoints created? (Yes/No - default Yes)
- Do you want example chat route with memory? (Yes/No - default Yes)

Phase 3: Implementation

Goal: Invoke mem0-integration-agent to add memory capabilities

Actions:

Task(description="Integrate Mem0 memory layer", subagent_type="fastapi-backend:mem0-integration-agent", prompt="You are the mem0-integration-agent. Integrate Mem0 memory capabilities into this FastAPI backend for $ARGUMENTS.

Project context from Phase 1-2. Reference: docs/FASTAPI-VERCEL-AI-MEM0-STACK.md sections 646-992

Core Tasks:
1. Install Mem0 dependencies (mem0ai, vector store client if self-hosted)
2. Create app/services/memory_service.py with MemoryClient/AsyncMemory
3. Implement: add_conversation(), search_memories(), get_user_summary(), add_user_preference()
4. Create app/api/routes/memory.py with endpoints: /conversation, /search, /summary, /preference
5. Add memory dependency injection to FastAPI
6. Create .env.example with required variables (MEM0_API_KEY or QDRANT_HOST/OPENAI_API_KEY)
7. Add example chat integration with memory context and background tasks
8. Include error handling and logging

Configuration:
- Hosted: Use MemoryClient with MEM0_API_KEY
- Self-hosted: Configure vector store (Qdrant/Pinecone), LLM provider, embedder

WebFetch documentation:
- https://docs.mem0.ai/platform/quickstart
- https://docs.mem0.ai/open-source/overview
- https://docs.mem0.ai/integrations

Deliverable: Complete Mem0 integration with service layer, API routes, and working examples")

Wait for agent to complete.

Phase 4: Validation

Goal: Verify Mem0 integration is correct

Actions:

Check that mem0ai package was added:
!{bash grep -i mem0 requirements.txt}

Verify memory service exists:
!{bash find . -name "memory_service.py" | head -1}

Check memory API routes created:
!{bash find . -path "*/routes/memory.py" -o -path "*/api/memory.py" | head -1}

Verify .env.example has Mem0 variables:
!{bash grep -E "(MEM0|QDRANT|VECTOR)" .env.example 2>/dev/null || echo "Check .env configuration"}

Run Python import check:
!{bash python -c "import mem0; print('✅ Mem0 installed')" 2>/dev/null || echo "⚠️ Run: pip install -r requirements.txt"}

Phase 5: Summary and Next Steps

Goal: Guide user through setup and usage

Actions:

Display what was added:
- Memory service layer (app/services/memory_service.py)
- Memory API routes (app/api/routes/memory.py)
- Environment configuration (.env.example)
- Updated requirements.txt with Mem0 dependencies

API Endpoints created:
- POST /api/v1/memory/conversation - Add conversation
- POST /api/v1/memory/search - Search memories
- GET /api/v1/memory/summary - Get user summary
- POST /api/v1/memory/preference - Add preference
- DELETE /api/v1/memory/user/{user_id} - Delete memories

Setup instructions:
1. Copy .env.example to .env and add API keys
2. Install: pip install -r requirements.txt
3. For self-hosted: docker run -p 6333:6333 qdrant/qdrant
4. Test at /api/v1/docs

Environment variables (based on deployment):
- Hosted: MEM0_API_KEY, MEM0_HOST (optional)
- Self-hosted: QDRANT_HOST, QDRANT_PORT, QDRANT_API_KEY, OPENAI_API_KEY

You can now:
- Track conversation history per user
- Search memories with semantic search
- Store and retrieve user preferences
- Build memory-enhanced AI experiences
