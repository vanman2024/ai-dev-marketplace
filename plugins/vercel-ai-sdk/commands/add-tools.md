---
description: Add tool/function calling capability to existing Vercel AI SDK project
argument-hint: none
allowed-tools: WebFetch(*), Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*)
---

**Arguments**: $ARGUMENTS

Goal: Add tool/function calling to existing Vercel AI SDK project with focused implementation

Core Principles:
- Detect existing project structure
- Fetch only tools-specific docs (2-3 URLs)
- Implement tool definitions with proper schemas
- Verify functionality

Phase 1: Discovery
Goal: Understand existing project setup

Actions:
- Detect project type: Check for package.json, requirements.txt
- Load existing configuration: @package.json or @requirements.txt
- Identify framework and AI SDK usage
- Find where tools should be integrated

Phase 2: Fetch Tools Documentation
Goal: Get tools-specific docs only

Actions:
Fetch these docs in parallel (3 URLs max):

1. WebFetch: https://ai-sdk.dev/docs/foundations/tools
2. WebFetch: https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling
3. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-tool-usage (if frontend)

Phase 3: Implementation
Goal: Add tool calling capability

Actions:

Invoke the **general-purpose** agent to implement tools:

The agent should:
- Define tool schemas with zod or similar validation
- Create tool handler functions
- Integrate tools with existing AI calls
- Add example tools (e.g., getWeather, calculator)
- Include proper error handling and validation
- Add comments explaining tool structure

Provide the agent with:
- Context: Existing project files
- Target: Add 1-2 example tools with proper schemas
- Expected output: Working tool implementation

Phase 4: Verification
Goal: Ensure tools work

Actions:
- For TypeScript: Run npx tsc --noEmit
- For JavaScript: Verify syntax
- For Python: Check imports and schemas
- Verify tool schemas are valid
- Check tool handlers exist

Phase 5: Summary
Goal: Show what was added

Actions:
Provide summary:
- Tool definitions created
- Handler functions implemented
- How to test tool calling
- Example tool usage
- How to add more custom tools
- Next steps: Consider /vercel-ai-sdk:add-chat for UI

Important Notes:
- Adapts to existing framework
- Fetches minimal docs (3 URLs)
- Creates 1-2 example tools
- Uses proper schema validation
- Focused on tools only
