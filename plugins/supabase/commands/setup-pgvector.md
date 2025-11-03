---
description: Configure pgvector for vector search - enables extension, creates embedding tables, sets up HNSW/IVFFlat indexes
argument-hint: [--dimensions=1536] [--index=hnsw|ivfflat]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
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

Goal: Set up pgvector for AI embeddings using ai-specialist agent

Actions:
- Invoke supabase-ai-specialist agent with dimension and index preferences
- Agent uses pgvector-setup skill to configure extension
- Display vector search setup and usage examples
