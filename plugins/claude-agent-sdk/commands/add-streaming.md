---
description: Add streaming input/output capabilities to Claude Agent SDK project
argument-hint: [none]
allowed-tools: Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), mcp__context7__resolve-library-id(*), mcp__context7__get-library-docs(*)
---

Add streaming input/output capabilities to your Claude Agent SDK application.

## Step 1: Verify SDK Project

Check that this is an Agent SDK project:
- Look for `@anthropic-ai/claude-agent-sdk` in package.json (TypeScript)
- Or `claude-agent-sdk` in requirements.txt (Python)

If not found, inform the user they need to run `/claude-agent-sdk:new-app` first.

## Step 2: Fetch Streaming Documentation

Use Context7 MCP to get latest streaming documentation:
1. Use mcp__context7__resolve-library-id with libraryName: "@anthropic-ai/claude-agent-sdk"
2. Use mcp__context7__get-library-docs with topic: "streaming"

## Step 3: Detect Project Language

Check project language:
- TypeScript: package.json with `@anthropic-ai/claude-agent-sdk`
- Python: requirements.txt with `claude-agent-sdk`

## Step 4: Implement Streaming

**For TypeScript:**
- Update code to use streaming mode with `for await` loops
- Add real-time response handling
- Implement progress indicators
- Add cancellation handling

**For Python:**
- Update code to iterate over streamed responses
- Add real-time processing logic
- Implement progress tracking
- Handle stream interruption

## Step 5: Add Examples

Create example file demonstrating:
- Basic streaming usage
- Handling streaming responses in real-time
- Progress updates to user
- Cancellation and cleanup

## Step 6: Update Documentation

Update project README with:
- Streaming usage examples
- Configuration options
- Performance considerations

Inform user that streaming has been added successfully with examples of how to use it.
