---
description: Add chat UI with message persistence to existing Vercel AI SDK project
argument-hint: none
allowed-tools: WebFetch, Read, Write, Edit, Bash(*), Glob, Grep
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

Goal: Add chat interface with message persistence to existing Vercel AI SDK project

Core Principles:
- Detect existing framework (React/Next.js/Vue/Svelte)
- Fetch chat-specific docs (2-3 URLs)
- Implement UI components and persistence
- Verify functionality

Phase 1: Discovery
Goal: Understand project and framework

Actions:
- Detect framework: @package.json
- Check for UI library (React, Vue, Svelte)
- Identify where to add chat components
- Check if streaming already exists

Phase 2: Fetch Chat Documentation
Goal: Get chat UI docs only

Actions:
Fetch these docs in parallel (3 URLs max):

1. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot
2. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-message-persistence
3. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-resume-streams

Phase 3: Implementation
Goal: Add chat UI and persistence

Actions:

Invoke the **general-purpose** agent to implement chat:

The agent should:
- Create chat UI component (useChat hook or equivalent)
- Add message display component
- Implement input handling
- Add message persistence (localStorage or database)
- Create API route/endpoint for chat
- Add loading states and error handling
- Style with existing CSS framework or Tailwind

Provide the agent with:
- Context: Framework and existing code
- Target: Working chat interface with persistence
- Expected output: Chat component, API route, styling

Phase 4: Verification
Goal: Ensure chat works

Actions:
- For TypeScript: Run npx tsc --noEmit
- Verify chat component renders
- Check API route exists
- Test message persistence
- Verify styling applied

Phase 5: Summary
Goal: Show what was added

Actions:
Provide summary:
- Chat components created
- API routes added
- Persistence mechanism used
- How to test chat
- Customization options
- Next steps: Add tools with /vercel-ai-sdk:add-tools

Important Notes:
- Framework-specific implementation
- Fetches minimal docs (3 URLs)
- Includes persistence out of the box
- Adapts styling to project
