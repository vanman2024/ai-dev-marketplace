---
description: Create and setup a new Vercel AI SDK application
argument-hint: [project-name]
allowed-tools: WebFetch(*), WebSearch(*), Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*)
---

You are tasked with helping the user create a new Vercel AI SDK application.

## Step 1: Fetch Initial Documentation (DO THIS FIRST)

Use WebFetch to read official docs NOW before asking questions. Fetch progressively throughout setup.

**Initial docs (fetch in parallel):**
1. WebFetch: https://sdk.vercel.ai/docs/introduction
2. WebFetch: https://sdk.vercel.ai/docs/getting-started
3. WebFetch: https://sdk.vercel.ai/docs/ai-sdk-core/overview
4. WebFetch: https://sdk.vercel.ai/docs/ai-sdk-ui/overview

## Step 2: Gather Requirements

Ask ONE question at a time. Wait for response before continuing.

1. **Language**: "TypeScript, JavaScript, or Python?"
2. **Project name**: Use $ARGUMENTS if provided, else ask
3. **Framework**: "Next.js, React, Node.js, Python, Svelte, or Vue?"
4. **AI Provider**: "OpenAI, Anthropic, Google, or Multiple?"
5. **Features**: "Text streaming, Tool calling, Multi-modal, Chat history, Rate limiting? (select all that apply)"
6. **Tooling**: Confirm package manager (npm, pnpm, bun, pip, poetry)

## Step 3: Fetch Feature-Specific Documentation

Based on selections, fetch relevant docs:

**Streaming**: https://sdk.vercel.ai/docs/ai-sdk-core/generating-text, https://sdk.vercel.ai/docs/ai-sdk-ui/streaming
**Tool Calling**: https://sdk.vercel.ai/docs/ai-sdk-core/tools-and-tool-calling, https://sdk.vercel.ai/docs/foundations/tools
**Multi-modal**: https://sdk.vercel.ai/docs/ai-sdk-core/multimodal
**Chat History**: https://sdk.vercel.ai/docs/ai-sdk-ui/chatbot

**Providers**:
- OpenAI: https://sdk.vercel.ai/providers/ai-sdk-providers/openai
- Anthropic: https://sdk.vercel.ai/providers/ai-sdk-providers/anthropic
- Google: https://sdk.vercel.ai/providers/ai-sdk-providers/google-generative-ai

## Step 4: Setup Plan

Create plan including:

1. **Initialize**: Create directory, init package manager, add config files
2. **Check Versions**: WebSearch for latest versions (https://www.npmjs.com/package/ai or PyPI)
3. **Install SDK**:
   - TypeScript/JavaScript: ai@latest + provider SDKs (@ai-sdk/openai, @ai-sdk/anthropic, @ai-sdk/google)
   - Python: Appropriate packages
4. **Create Files**: Entry points, imports, error handling, selected features
5. **Environment**: .env.example with API keys, .gitignore, explain key sources
6. **Features**: Implement streaming, tool calling, multi-modal, chat history, rate limiting as selected
7. **UI** (if applicable): Chat interface, loading states, streaming updates, styling

## Step 5: Implementation

1. Check latest versions
2. Execute setup
3. Create files with helpful comments
4. Install dependencies
5. Verify versions
6. **VERIFY CODE**:
   - TypeScript: Run npx tsc --noEmit, fix ALL errors
   - JavaScript: Verify imports
   - Python: Verify imports, lint if available
   - **DO NOT finish until verification passes**

## Step 6: Verification

Invoke appropriate verifier agent:

**TypeScript**: Invoke the **vercel-ai-verifier-ts** agent to validate the setup
**JavaScript**: Invoke the **vercel-ai-verifier-js** agent to validate the setup
**Python**: Invoke the **vercel-ai-verifier-py** agent to validate the setup

Review verification report and address issues.

## Step 7: Getting Started

Provide:

1. **Next steps**: How to set API keys, how to run (npm run dev, python main.py, etc.)
2. **Resources**: SDK docs (https://sdk.vercel.ai/docs), provider docs, examples (https://sdk.vercel.ai/examples)
3. **Common next steps**: Customize prompts, add tools, auth, deployment, history, rate limiting
4. **Testing**: Example prompts, tool calling tests, streaming demos

## Important

- **LATEST VERSIONS**: Always check before installing
- **PROGRESSIVE DOCS**: Fetch based on user choices, not all at once
- **VERIFY CODE**: Don't finish until verification passes
- **ONE QUESTION AT A TIME**: Wait for answers
- Check if files exist before creating
- Use user's preferred package manager
- Modern syntax, functional examples, proper error handling
- Make it interactive and educational

Begin by fetching initial docs, then ask FIRST question only.
