---
description: Add text streaming capability to existing Vercel AI SDK project
argument-hint: none
allowed-tools: WebFetch, Read, Write, Edit, Bash(*), Glob, Grep, Skill
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

Goal: Add text streaming to existing Vercel AI SDK project with minimal docs and focused implementation

Core Principles:
- Detect existing project structure
- Fetch only streaming-specific docs (2-3 URLs)
- Implement streamText() or useChat() based on framework
- Verify functionality

Phase 1: Discovery
Goal: Understand existing project setup

Actions:
- Detect project type: Check for package.json, requirements.txt, framework configs
- Load existing configuration: @package.json or @requirements.txt
- Identify framework: Next.js, React, Node.js, Python, etc.
- Find entry points: Look for existing AI SDK usage

Phase 2: Fetch Streaming Documentation
Goal: Get streaming-specific docs only

Actions:
Fetch these docs in parallel (3 URLs max):

1. WebFetch: https://ai-sdk.dev/docs/foundations/streaming
2. WebFetch: https://ai-sdk.dev/docs/ai-sdk-core/generating-text
3. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot (if React/Next.js/frontend)

Phase 3: Implementation
Goal: Add streaming capability using appropriate agent

Actions:

Invoke the **general-purpose** agent to implement streaming:

The agent should:
- Analyze existing code structure
- Add streamText() function for backend/Node.js projects
- Add useChat() hook for React/Next.js/frontend projects
- Create example endpoint/component showing streaming
- Add proper error handling
- Include helpful comments explaining streaming

Provide the agent with:
- Context: Existing project files and structure
- Target: Add streaming based on framework detected
- Expected output: Working streaming implementation with example

Phase 4: Verification
Goal: Ensure streaming works

Actions:
- For TypeScript: Run npx tsc --noEmit to check types
- For JavaScript: Verify syntax
- For Python: Check imports
- Test that streaming endpoint/component exists
- Verify proper SDK usage patterns

Phase 5: Summary
Goal: Show what was added

Actions:
Provide summary:
- Files modified/created
- Streaming implementation approach (streamText vs useChat)
- How to test streaming
- Example usage code
- Next steps: Consider adding /vercel-ai-sdk:add-tools for function calling

Important Notes:
- Adapts to existing framework (Next.js, React, Node.js, Python)
- Fetches minimal docs (3 URLs)
- Uses general-purpose agent for implementation
- Verifies code compiles/runs
- Focused on streaming only
