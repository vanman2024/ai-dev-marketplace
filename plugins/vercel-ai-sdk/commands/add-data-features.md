---
description: Add data features to Vercel AI SDK app including embeddings generation, RAG with vector databases, and structured data generation
argument-hint: [feature-requests]
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, AskUserQuestion, Skill
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

Goal: Add AI-powered data processing capabilities to a Vercel AI SDK application including embeddings generation, RAG (Retrieval Augmented Generation) with vector databases, and structured data generation.

Core Principles:
- Understand data sources and volume before designing solutions
- Ask about vector database preferences
- Follow Vercel AI SDK documentation patterns
- Optimize for cost and performance

Phase 1: Discovery
Goal: Understand what data features are needed

Actions:
- Parse $ARGUMENTS to identify requested features
- If unclear or no arguments provided, use AskUserQuestion to gather:
  - Which data features do you want? (Embeddings, RAG, structured data generation)
  - What's the size of your dataset?
  - Do you have a vector database? (Pinecone, Weaviate, Chroma, pgvector, etc.)
  - What kind of data needs to be processed?
- Load package.json to understand current setup
- Example: @package.json

Phase 2: Analysis
Goal: Understand current project state

Actions:
- Check for existing AI SDK installation
- Identify data sources (files, APIs, databases)
- Verify database infrastructure availability
- Assess data volume and processing requirements
- Example: !{bash ls *.txt *.pdf *.md 2>/dev/null | wc -l}

Phase 3: Implementation
Goal: Add requested data features using specialized agent

Actions:

Invoke the vercel-ai-data-agent to implement the requested data features.

The agent should:
- Fetch relevant Vercel AI SDK documentation for the requested features
- Design optimal architecture for the data volume
- Install required packages (vector DB clients, zod, etc.)
- Implement requested features following SDK best practices:
  - Embeddings generation using embed() and embedMany()
  - Vector database integration and schema design
  - RAG pipeline with document chunking and retrieval
  - Structured data generation using generateObject/streamObject
- Add proper TypeScript types and Zod schemas
- Implement error handling and retry logic
- Optimize for cost and performance

Provide the agent with:
- Context: Current project structure and data sources
- Target: $ARGUMENTS (requested data features)
- Expected output: Production-ready data processing pipeline

Phase 4: Verification
Goal: Ensure features work correctly

Actions:
- Run TypeScript compilation check
- Example: !{bash npx tsc --noEmit}
- Test embeddings generation with sample data
- Verify vector database operations (if applicable)
- Check cost implications and optimization

Phase 5: Summary
Goal: Document what was added

Actions:
- List all data features that were implemented
- Show database schema and indexes created
- Note any API keys or environment variables needed
- Provide cost estimates and optimization suggestions
- Suggest next steps (data ingestion, query optimization)
