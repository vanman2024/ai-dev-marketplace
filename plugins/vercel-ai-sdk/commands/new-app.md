---
description: Create initial Vercel AI SDK project scaffold with basic setup
argument-hint: [project-name]
allowed-tools: WebFetch(*), WebSearch(*), Read(*), Write(*), Edit(*), Bash(*), AskUserQuestion(*)
---

**Arguments**: $ARGUMENTS

Goal: Create minimal Vercel AI SDK project scaffold with basic configuration. Features like streaming, tools, and chat are added separately using other commands.

Core Principles:
- Keep it simple - scaffold only, no features
- Fetch minimal docs (3-5 URLs)
- Get user choices early
- Verify setup works

Phase 1: Discovery
Goal: Understand project requirements

Actions:
- Parse $ARGUMENTS for project name (if provided)
- Ask ONE question at a time, wait for response:
  1. **Project name**: Use $ARGUMENTS or ask "What should we name your project?"
  2. **Language**: "TypeScript, JavaScript, or Python?"
  3. **Framework**: "Next.js, React (Vite), Node.js, Python (FastAPI), Svelte, or Vue?"
  4. **AI Provider**: "OpenAI, Anthropic, Google, or xAI?"

Phase 2: Fetch Minimal Documentation
Goal: Get essential setup docs only

Actions:
Fetch these docs in parallel (4 URLs max):

1. WebFetch: https://ai-sdk.dev/docs/introduction
2. WebFetch: https://ai-sdk.dev/docs/foundations/overview
3. WebFetch: https://ai-sdk.dev/docs/getting-started/[framework-specific]
4. WebFetch: https://ai-sdk.dev/providers/ai-sdk-providers/[provider]

Replace [framework-specific] and [provider] with user selections.

Phase 3: Project Setup
Goal: Create basic project structure

Actions:

1. **Check latest version**:
   - Use WebSearch to find latest `ai` package version
   - For TypeScript/JavaScript: https://www.npmjs.com/package/ai
   - For Python: https://pypi.org/project/ai/

2. **Create project directory**:
   - Create directory with project name
   - Navigate into it

3. **Initialize project**:
   - TypeScript/JavaScript: Run npm init -y, setup package.json with type: module
   - Python: Create requirements.txt or pyproject.toml

4. **Install SDK and provider**:
   - TypeScript/JavaScript: npm install ai@latest @ai-sdk/[provider]
   - Python: pip install ai [provider-package]
   - Verify installed versions

5. **Create basic files**:
   - Create .env.example with [PROVIDER]_API_KEY placeholder
   - Add .env to .gitignore
   - Create minimal entry point (index.ts/js or main.py) with simple example
   - Add helpful comments explaining next steps

6. **Environment notes**:
   - Explain how to get API key from provider
   - Show how to set .env file

Phase 4: Verification
Goal: Ensure setup is correct

Actions:

Invoke the appropriate verifier agent based on language:

**For TypeScript**: Invoke the **vercel-ai-verifier-ts** agent to validate the setup
**For JavaScript**: Invoke the **vercel-ai-verifier-js** agent to validate the setup
**For Python**: Invoke the **vercel-ai-verifier-py** agent to validate the setup

Agent should check:
- Package installation
- Configuration files
- Basic imports work
- Environment setup

Phase 5: Next Steps
Goal: Guide user on what to do next

Actions:
Provide clear next steps:

1. **Set API key**: How to add key to .env file
2. **Run the app**: Command to execute (npm start, python main.py, etc.)
3. **Add features**: Point to other commands:
   - /vercel-ai-sdk:add-streaming - Add text streaming
   - /vercel-ai-sdk:add-tools - Add function/tool calling
   - /vercel-ai-sdk:add-chat - Add chat UI
   - /vercel-ai-sdk:add-provider - Add another AI provider

4. **Resources**:
   - SDK docs: https://ai-sdk.dev/docs
   - Examples: https://ai-sdk.dev/examples
   - Provider docs link

Important Notes:
- This creates SCAFFOLD ONLY - no features implemented yet
- Use other commands to add streaming, tools, chat, etc.
- Always check latest package versions before installing
- Verify code compiles/runs before finishing
- Keep it minimal and focused
