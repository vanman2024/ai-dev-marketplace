---
description: Create and setup a new Vercel AI SDK application
argument-hint: [project-name]
allowed-tools: WebFetch(*), WebSearch(*), Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), Task(*), AskUserQuestion(*)
---

You are tasked with helping the user create a new Vercel AI SDK application. Follow these steps in order:

## Step 1: Fetch Latest Documentation (DO THIS FIRST)

Use WebFetch to read the official documentation NOW before asking any questions. Fetch documentation progressively throughout the setup process to get the most relevant, up-to-date information.

**Initial Documentation (fetch in parallel):**

1. Use WebFetch to read: https://sdk.vercel.ai/docs/introduction
2. Use WebFetch to read: https://sdk.vercel.ai/docs/getting-started
3. Use WebFetch to read: https://sdk.vercel.ai/docs/ai-sdk-core/overview
4. Use WebFetch to read: https://sdk.vercel.ai/docs/ai-sdk-ui/overview

**CRITICAL**: Do NOT skip these WebFetch calls. Fetch them in parallel. The documentation may have changed since your training data. Only after fetching these docs should you proceed to Step 2.

## Step 2: Gather Requirements

IMPORTANT: Ask these questions one at a time. Wait for the user's response before asking the next question. This makes it easier for the user to respond.

Ask the questions in this order (skip any that the user has already provided via arguments):

1. **Language** (ask first): "Would you like to use TypeScript, JavaScript, or Python?"

   - Wait for response before continuing

2. **Project name** (ask second): "What would you like to name your project?"

   - If $ARGUMENTS is provided, use that as the project name and skip this question
   - Wait for response before continuing

3. **Framework choice** (ask third): "Which framework would you like to use?

   - Next.js (React framework with App Router support)
   - React (standalone with Vite)
   - Node.js (backend/API only)
   - Python (backend/API with FastAPI or Flask)
   - Svelte (with SvelteKit)
   - Vue (with Nuxt or Vite)"
   - Wait for response before continuing

4. **AI Provider** (ask fourth): "Which AI provider would you like to use?

   - OpenAI (GPT-4, GPT-3.5)
   - Anthropic (Claude)
   - Google (Gemini)
   - Multiple providers (configure several)"
   - Wait for response before continuing

5. **Features** (ask fifth): "What features do you need? (Select all that apply)

   - Text streaming (real-time AI responses)
   - Tool/Function calling (AI can call your functions)
   - Multi-modal (text, images, files)
   - Chat history management
   - Rate limiting and caching"
   - Wait for response before continuing

6. **Tooling choice** (ask sixth): Let the user know what tools you'll use, and confirm with them that these are the tools they want to use (for example, they may prefer pnpm or bun over npm). Respect the user's preferences when executing on the requirements.

After all questions are answered, proceed to fetch additional documentation based on their choices and create the setup plan.

## Step 3: Fetch Feature-Specific Documentation

Based on the user's feature selections, fetch relevant documentation:

**If Text Streaming selected:**
- WebFetch: https://sdk.vercel.ai/docs/ai-sdk-core/generating-text
- WebFetch: https://sdk.vercel.ai/docs/ai-sdk-ui/streaming

**If Tool Calling selected:**
- WebFetch: https://sdk.vercel.ai/docs/ai-sdk-core/tools-and-tool-calling
- WebFetch: https://sdk.vercel.ai/docs/foundations/tools

**If Multi-modal selected:**
- WebFetch: https://sdk.vercel.ai/docs/ai-sdk-core/multimodal

**If Chat History selected:**
- WebFetch: https://sdk.vercel.ai/docs/ai-sdk-ui/chatbot

**For provider-specific setup, fetch:**
- OpenAI: https://sdk.vercel.ai/providers/ai-sdk-providers/openai
- Anthropic: https://sdk.vercel.ai/providers/ai-sdk-providers/anthropic
- Google: https://sdk.vercel.ai/providers/ai-sdk-providers/google-generative-ai

## Setup Plan

Based on the user's answers, create a plan that includes:

1. **Project initialization**:

   - Create project directory (if it doesn't exist)
   - Initialize framework and package manager:
     - Next.js: `npx create-next-app@latest` or manual setup with TypeScript
     - React: `npm create vite@latest` with React + TypeScript template
     - Node.js: `npm init -y` and setup `package.json` with type: "module" and scripts
     - Python: Create `requirements.txt` or use `poetry init`
     - Svelte: `npm create svelte@latest`
     - Vue: `npm create vue@latest`
   - Add necessary configuration files based on framework

2. **Check for Latest Versions**:

   - BEFORE installing, use WebSearch or check npm/PyPI to find the latest version
   - For TypeScript/JavaScript: Check https://www.npmjs.com/package/ai
   - For Python: Check https://pypi.org/project/ai/ or appropriate Python SDK
   - Inform the user which version you're installing

3. **SDK Installation**:

   - TypeScript/JavaScript: `npm install ai@latest` (or specify latest version)
   - Install provider SDKs based on selections:
     - OpenAI: `npm install @ai-sdk/openai`
     - Anthropic: `npm install @ai-sdk/anthropic`
     - Google: `npm install @ai-sdk/google`
   - Python: `pip install ai` or appropriate Python packages
   - After installation, verify the installed versions

4. **Create starter files**:

   - Create appropriate entry points based on framework:
     - Next.js: Create API route in `app/api/chat/route.ts` and UI component
     - React: Create components in `src/` with example chat interface
     - Node.js: Create `index.ts` or `src/index.ts` with API endpoints
     - Python: Create `main.py` with FastAPI or Flask endpoints
   - Include proper imports and error handling
   - Use modern, up-to-date syntax and patterns from the latest SDK version
   - Implement selected features (streaming, tool calling, etc.)

5. **Environment setup**:

   - Create a `.env.example` file with required API keys:
     - `OPENAI_API_KEY=your_openai_key_here` (if using OpenAI)
     - `ANTHROPIC_API_KEY=your_anthropic_key_here` (if using Anthropic)
     - `GOOGLE_GENERATIVE_AI_API_KEY=your_google_key_here` (if using Google)
   - Create `.env.local` (for Next.js) or `.env` with placeholder values
   - Add `.env.local` and `.env` to `.gitignore`
   - Explain how to get API keys from respective providers

6. **Feature Implementation**:

   - **If Text Streaming**: Implement streaming with `streamText()` or `useChat()` hook
   - **If Tool Calling**: Set up tools with proper schemas and handlers
   - **If Multi-modal**: Configure file/image handling
   - **If Chat History**: Implement message storage and retrieval
   - **If Rate Limiting**: Add rate limiting middleware or configuration

7. **UI Components** (if applicable):
   - Create chat interface components
   - Add loading states and error handling
   - Implement streaming UI updates
   - Style with Tailwind CSS (if available) or basic CSS

## Implementation

After gathering requirements and getting user confirmation on the plan:

1. Check for latest package versions using WebSearch or WebFetch
2. Execute the setup steps
3. Create all necessary files
4. Install dependencies (always use latest stable versions)
5. Verify installed versions and inform the user
6. Create a working example based on their selections
7. Add helpful comments in the code explaining what each part does
8. **VERIFY THE CODE WORKS BEFORE FINISHING**:
   - For TypeScript:
     - Run `npx tsc --noEmit` to check for type errors
     - Fix ALL type errors until types pass completely
     - Ensure imports and types are correct
     - Only proceed when type checking passes with no errors
   - For JavaScript:
     - Verify imports are correct
     - Check for basic syntax errors
   - For Python:
     - Verify imports are correct
     - Run basic linting if available
   - **DO NOT consider the setup complete until the code verifies successfully**

## Verification

After all files are created and dependencies are installed, invoke the appropriate verifier agent to validate that the Vercel AI SDK application is properly configured and ready for use:

1. **For TypeScript projects**: Invoke the **vercel-ai-verifier-ts** agent to validate the setup
2. **For JavaScript projects**: Invoke the **vercel-ai-verifier-js** agent to validate the setup
3. **For Python projects**: Invoke the **vercel-ai-verifier-py** agent to validate the setup
4. The agent will check SDK usage, configuration, functionality, and adherence to official documentation
5. Review the verification report and address any issues

## Getting Started Guide

Once setup is complete and verified, provide the user with:

1. **Next steps**:

   - How to set their API key(s)
   - How to run their application:
     - Next.js: `npm run dev` (opens on http://localhost:3000)
     - React: `npm run dev` (Vite dev server)
     - Node.js: `npm start` or `node --loader ts-node/esm index.ts`
     - Python: `python main.py` or `uvicorn main:app --reload`

2. **Useful resources**:

   - Link to Vercel AI SDK docs: https://sdk.vercel.ai/docs
   - Link to provider-specific docs
   - Link to examples: https://sdk.vercel.ai/examples
   - Explain key concepts: streaming, tool calling, providers

3. **Common next steps**:
   - How to customize prompts and model parameters
   - How to add custom tools/functions
   - How to implement authentication
   - How to deploy to Vercel or other platforms
   - How to add chat history persistence
   - How to implement rate limiting

4. **Testing the application**:
   - Provide example prompts to test
   - Show how to test tool calling (if enabled)
   - Demonstrate streaming behavior

## Important Notes

- **ALWAYS USE LATEST VERSIONS**: Before installing any packages, check for the latest versions using WebSearch or by checking npm/PyPI directly
- **FETCH DOCS PROGRESSIVELY**: Don't fetch all docs at once. Fetch relevant documentation based on user's choices throughout the process
- **VERIFY CODE RUNS CORRECTLY**:
  - For TypeScript: Run `npx tsc --noEmit` and fix ALL type errors before finishing
  - For JavaScript: Verify syntax and imports are correct
  - For Python: Verify syntax and imports are correct
  - Do NOT consider the task complete until the code passes verification
- Verify the installed versions after installation and inform the user
- Check the official documentation for any version-specific requirements (Node.js version, Python version, etc.)
- Always check if directories/files already exist before creating them
- Use the user's preferred package manager (npm, yarn, pnpm, bun for TypeScript/JavaScript; pip, poetry for Python)
- Ensure all code examples are functional and include proper error handling
- Use modern syntax and patterns that are compatible with the latest SDK version
- Make the experience interactive and educational
- **ASK QUESTIONS ONE AT A TIME** - Do not ask multiple questions in a single response
- **PROGRESSIVE DOCUMENTATION**: Fetch docs as needed based on user selections, not all at once

Begin by fetching the initial documentation, then ask the FIRST requirement question only. Wait for the user's answer before proceeding to the next question.
