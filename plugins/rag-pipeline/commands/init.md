---
description: Initialize RAG project with framework selection (LlamaIndex/LangChain)
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion
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

Goal: Initialize complete RAG project with user-selected framework, directory structure, dependencies, and starter code.

Core Principles:
- Ask user for framework preference early
- Create clean project structure
- Install dependencies correctly
- Provide documentation links and next steps

Phase 1: Discovery and Framework Selection
Goal: Determine project path and gather user preferences

Actions:
- Parse $ARGUMENTS for project path (default to current directory if empty)
- Check if path exists: !{bash test -d "$ARGUMENTS" && echo "exists" || echo "not-found"}
- Create directory if needed: !{bash mkdir -p "$ARGUMENTS"}
- Check existing setup: !{bash ls "$ARGUMENTS"/requirements.txt "$ARGUMENTS"/venv 2>/dev/null || echo "new-project"}
- Use AskUserQuestion: "Which RAG framework? (1) LlamaIndex, (2) LangChain, (3) Both"
- If Both selected, ask: "Vector database? (Chroma/Pinecone/FAISS)"

Phase 2: Project Setup
Goal: Create directory structure and install dependencies

Actions:
- Create directories: !{bash mkdir -p "$ARGUMENTS"/{data/{raw,processed},scripts,config,notebooks,tests,src}}
- Create venv: !{bash cd "$ARGUMENTS" && python3 -m venv venv}
- Install based on selection:
  - LlamaIndex: !{bash cd "$ARGUMENTS" && source venv/bin/activate && pip install llama-index python-dotenv}
  - LangChain: !{bash cd "$ARGUMENTS" && source venv/bin/activate && pip install langchain langchain-community python-dotenv}
  - Both: !{bash cd "$ARGUMENTS" && source venv/bin/activate && pip install llama-index langchain langchain-community python-dotenv}
- Install vector DB if selected: !{bash cd "$ARGUMENTS" && source venv/bin/activate && pip install chromadb}
- Generate requirements: !{bash cd "$ARGUMENTS" && source venv/bin/activate && pip freeze > requirements.txt}

Phase 3: Code Generation
Goal: Generate framework-specific starter code and documentation

Actions:

Task(description="Generate RAG starter code", subagent_type="rag-pipeline:rag-architect", prompt="You are the rag-architect agent. Generate starter code for RAG project at $ARGUMENTS.

Framework: [User's selection from Phase 1]
Vector DB: [User's selection from Phase 1]

Create these files:

1. config/.env.example - API key placeholders (OPENAI_API_KEY, etc), vector DB config
2. src/rag_pipeline.py - Main RAG pipeline with document loading, chunking, embeddings, vector store, query functions
3. scripts/index_documents.py - Index documents from data/raw/
4. scripts/query_example.py - Example query script
5. notebooks/rag_demo.ipynb - Step-by-step RAG demo notebook
6. README.md with:
   - Setup instructions
   - Documentation links:
     * LlamaIndex: https://developers.llamaindex.ai/python/framework/
     * LlamaIndex Getting Started: https://developers.llamaindex.ai/python/framework/getting_started/reading
     * LangChain: https://python.langchain.com/docs/
     * LangChain RAG Tutorial: https://python.langchain.com/docs/tutorials/rag/
   - Project structure explanation
   - Next steps guide
7. .gitignore - Exclude venv/, .env, __pycache__/, *.pyc, .ipynb_checkpoints/, data/

Use framework best practices, type hints, comprehensive comments, error handling.

Expected output: All files created with working code.")

Phase 4: Git Initialization and Summary
Goal: Initialize git repository and display summary

Actions:
- Check git status: !{bash cd "$ARGUMENTS" && git status 2>&1 | grep -q "not a git repository" && echo "no-git" || echo "exists"}
- If no git, initialize: !{bash cd "$ARGUMENTS" && git init}
- Stage files: !{bash cd "$ARGUMENTS" && git add .}
- Create commit: !{bash cd "$ARGUMENTS" && git commit -m "Initial RAG project setup

Framework: [selected framework]
Vector DB: [selected vector DB]

Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"}
- Display summary:
  - Project location: $ARGUMENTS
  - Framework and vector DB selections
  - Files created
  - Next steps: cd $ARGUMENTS, source venv/bin/activate, configure .env, review README.md
  - Documentation links for reference
