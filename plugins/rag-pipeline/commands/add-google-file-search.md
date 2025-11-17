---
description: Integrate Google File Search API for managed RAG with Gemini - handles store creation, file uploads, chunking, and citations
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, TodoWrite
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---


**Arguments**: $ARGUMENTS

Goal: Integrate Google File Search API into projects for fully managed RAG with automatic chunking, semantic search, and grounding citations - eliminating the need for separate vector database infrastructure.

Core Principles:
- Understand project structure before making changes
- Ask clarifying questions about document types and volume
- Follow official Google File Search API patterns
- Secure API key management (no hardcoded credentials)
- Provide clear setup instructions

Phase 1: Discovery
Goal: Understand project structure and requirements

Actions:
- Create todo list with TodoWrite for tracking progress
- Parse $ARGUMENTS for project path (default: current directory)
- Detect project type (Python vs Node.js/TypeScript)
- Check for existing Google AI SDK installation
- Load relevant files for context:
  - @package.json (Node.js projects)
  - @requirements.txt or @pyproject.toml (Python projects)
- Identify if RAG components already exist

Phase 2: Requirements Gathering
Goal: Clarify implementation details

Actions:

Use AskUserQuestion to gather critical information:

Questions to ask:
- "What types of documents will you be indexing?" (PDF, Office docs, code files, etc.)
- "What's your expected document volume?" (helps determine storage tier)
- "Do you need metadata filtering capabilities?" (for multi-tenant or categorized search)
- "Do you want custom chunking configuration?" (or use default white space chunking)

This information will guide the configuration strategy.

Phase 3: Analysis
Goal: Review existing codebase patterns

Actions:
- Search for existing RAG implementation:
  - !{bash find . -type f \( -name "*.py" -o -name "*.ts" -o -name "*.js" \) -exec grep -l "embedding\|vector\|rag\|retrieval" {} \; 2>/dev/null | head -10}
- Read existing vector database setup (if any)
- Understand current document processing workflows
- Identify integration points for File Search

Phase 4: Planning
Goal: Design File Search integration approach

Actions:
- Determine store strategy (single store vs multiple stores)
- Plan chunking configuration based on document types
- Design metadata schema if filtering needed
- Map out document upload workflow
- Identify where to extract and display grounding citations
- Present plan to user and confirm approach

Phase 5: Implementation
Goal: Integrate Google File Search API

Actions:

Task(description="Implement Google File Search", subagent_type="rag-pipeline:google-file-search-specialist", prompt="You are the google-file-search-specialist agent. Integrate Google File Search API for $ARGUMENTS.

Project Context:
- Project type: [Python/Node.js detected from Phase 1]
- Existing setup: [RAG components found in Phase 3]
- Document types: [From Phase 2 questions]
- Volume: [From Phase 2 questions]
- Metadata filtering: [From Phase 2 questions]
- Chunking: [From Phase 2 questions]

Requirements:
- Install Google Generative AI SDK (google-generativeai for Python, @google/generative-ai for Node.js)
- Create File Search store with appropriate configuration
- Implement document upload workflow (direct or separate method)
- Configure chunking strategy based on document types
- Add metadata schema if filtering required
- Integrate with Gemini generation calls
- Extract and display grounding citations
- Set up secure API key management (environment variables)
- Create .env.example with placeholders
- Add .gitignore protection for .env files
- Document API key acquisition in README or setup guide

Expected Deliverables:
- Store creation and configuration code
- Document upload utilities
- Search and retrieval functions
- Grounding citation extraction
- Environment configuration files (.env.example)
- Setup documentation with clear instructions
- Example usage code")

Phase 6: Verification
Goal: Ensure implementation works correctly

Actions:
- Check that SDK dependencies were installed
- Verify .env.example exists with placeholder API keys
- Confirm .gitignore protects .env files
- Review generated code for security best practices
- Test store creation code (if API key available)
- Validate chunking configuration
- Run type checking if applicable:
  - TypeScript: !{bash npx tsc --noEmit 2>&1 || echo "No TypeScript"}
  - Python: !{bash python -m mypy . 2>&1 || echo "No mypy"}

Phase 7: Summary
Goal: Document what was accomplished

Actions:
- Mark all todos complete with TodoWrite
- Display comprehensive summary:

**Google File Search Integration Complete!**

**What was implemented:**
- File Search store creation and management
- Document upload workflow
- Semantic search with embeddings
- Grounding citations extraction
- Secure API key configuration

**Files created/modified:**
- [List all files created by agent]

**Key Features:**
- Fully Managed RAG - No vector database setup needed
- Automatic Chunking - Google handles document segmentation
- Built-in Citations - Grounding metadata with source attribution
- Persistent Storage - Documents don't expire
- Cost Effective - Free storage, pay only for indexing

**Setup Instructions:**
1. Get Google AI API key from https://ai.google.dev/
2. Copy .env.example to .env and add your API key
3. Run the setup/example code to create your first store

**Next Steps:**
- Upload documents and test semantic search
- Review grounding citations in responses
- Configure custom chunking or metadata filtering as needed

**Documentation:**
- https://ai.google.dev/gemini-api/docs/file-search
- https://ai.google.dev/pricing
