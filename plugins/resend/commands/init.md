---
description: Initialize Resend SDK in project with environment setup and framework detection
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep
---

**Arguments**: $ARGUMENTS

Goal: Initialize Resend SDK in a TypeScript/JavaScript or Python project with automatic framework detection, dependency installation, environment configuration, and type-safe setup files.

Core Principles:
- Detect project type before making assumptions
- Create security-hardened setup with placeholder API keys
- Install framework-appropriate SDK variants
- Generate production-ready configuration

Phase 1: Discovery
Goal: Understand the project and validate inputs

Actions:
- Verify project path exists: !{bash test -d "$ARGUMENTS" && echo "Project found" || echo "Project not found"}
- Check for package.json (Node.js/TypeScript): !{bash test -f "$ARGUMENTS/package.json" && echo "Node.js project" || echo "No Node.js project"}
- Check for requirements.txt or pyproject.toml (Python): !{bash test -f "$ARGUMENTS/requirements.txt" -o -f "$ARGUMENTS/pyproject.toml" && echo "Python project" || echo "No Python project"}
- List framework indicators: !{bash cd "$ARGUMENTS" && ls -la | grep -E "(next|express|fastapi|flask|django)" 2>/dev/null || echo "Analyzing..."}

Phase 2: Framework Context
Goal: Gather information about project structure and preferences

Actions:
- If package.json exists, read it to understand dependencies
- If Python, check if async framework (FastAPI/Starlette) vs sync
- Identify existing framework (Next.js, Express, FastAPI, etc.)
- Load project structure overview

Phase 3: Agent Invocation
Goal: Execute Resend SDK setup via specialized agent

Actions:

Task(description="Initialize Resend SDK", subagent_type="resend-setup-agent", prompt="You are the resend-setup-agent. Initialize Resend SDK in the project at $ARGUMENTS with proper configuration, environment setup, and framework integration.

Requirements:
- Detect project type (TypeScript/JavaScript/Python)
- Identify framework (Next.js, Express, FastAPI, Starlette, etc.)
- Install appropriate SDK: 'resend' for Node.js or 'resend-python' for Python
- Create .env.example with RESEND_API_KEY=your_resend_api_key_here (placeholder only)
- Add .env* to .gitignore (except .env.example)
- Generate client initialization file (lib/resend.ts or lib/resend.py)
- Create framework-specific example endpoint
- Generate TypeScript types or Python type hints
- Validate setup with type checking or compilation

Deliverable: Report initialization completion with:
- Files created
- Dependencies installed
- Framework integration details
- Setup verification results
- Security check (confirm no hardcoded API keys)")

Phase 4: Summary
Goal: Confirm successful setup

Actions:
- Verify .env.example exists with placeholder only: !{bash grep -q "your_resend_api_key_here" "$ARGUMENTS/.env.example" && echo "✓ Placeholder found" || echo "⚠ Verify placeholder"}
- Verify .gitignore protects .env: !{bash grep -q ".env" "$ARGUMENTS/.gitignore" && echo "✓ .env protected" || echo "⚠ Check .gitignore"}
- List generated files: !{bash find "$ARGUMENTS" -type f \( -name "*resend*" -o -name ".env.example" \) 2>/dev/null}
- Display setup completion message with next steps
