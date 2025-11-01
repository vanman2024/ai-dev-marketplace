---
description: Integrate Vercel AI SDK for streaming AI responses
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, mcp__context7
---

**Arguments**: $ARGUMENTS

Goal: Integrate Vercel AI SDK into Next.js project with streaming support and API routes for selected AI providers

Core Principles:
- Detect existing Next.js setup and configuration
- Ask user for provider preferences before installing
- Follow Next.js App Router conventions for API routes
- Configure environment variables properly
- Provide clear examples for immediate use

Phase 1: Discovery
Goal: Understand the Next.js project structure and existing setup

Actions:
- Check if we're in a Next.js project:
  !{bash test -f package.json && echo "Found package.json" || echo "No package.json"}
- Load package.json to check Next.js version and existing dependencies:
  @package.json
- Detect if using App Router or Pages Router:
  !{bash test -d app && echo "App Router" || test -d pages && echo "Pages Router" || echo "Unknown"}
- Check for existing AI SDK installations:
  !{bash grep -E "(ai|@ai-sdk|openai|anthropic)" package.json 2>/dev/null || echo "No AI dependencies found"}

Phase 2: Requirements Gathering
Goal: Ask user about AI provider preferences

Actions:
- Use AskUserQuestion to gather provider preferences:
  - Which AI providers would you like to integrate? (Options: Anthropic/Claude, OpenAI, Google/Gemini, Multiple)
  - Do you need streaming support? (Yes/No - default Yes)
  - Do you want example API routes created? (Yes/No - default Yes)
  - Do you want a client-side example component? (Yes/No - default Yes)

Phase 3: Planning
Goal: Determine what needs to be installed and configured

Actions:
- Based on user responses, identify required packages:
  - Core: ai, @ai-sdk/react (for streaming hooks)
  - Anthropic: @ai-sdk/anthropic
  - OpenAI: @ai-sdk/openai
  - Google: @ai-sdk/google
- Identify App Router vs Pages Router structure
- Plan API route locations:
  - App Router: app/api/chat/route.ts
  - Pages Router: pages/api/chat.ts
- Determine .env.local variables needed based on providers

Phase 4: Implementation
Goal: Install packages and integrate AI SDK

Actions:

Task(description="Integrate Vercel AI SDK", subagent_type="ai-sdk-integration-agent", prompt="You are the ai-sdk-integration-agent. Integrate Vercel AI SDK into this Next.js project for $ARGUMENTS.

Context:
- Next.js project detected with structure analyzed
- User selected providers and preferences from Phase 2
- Package.json loaded for dependency management

Requirements:
- Install ai and @ai-sdk/react packages
- Install provider packages based on user selection (Anthropic, OpenAI, Google)
- Create API route for chat endpoint (streaming support)
- Follow App Router or Pages Router conventions detected
- Create .env.local template with required API keys
- Add proper TypeScript types if project uses TypeScript
- Create example client component showing streaming usage
- Follow Next.js best practices for API routes and server components

Provider Configuration:
- Anthropic: Use @ai-sdk/anthropic with ANTHROPIC_API_KEY
- OpenAI: Use @ai-sdk/openai with OPENAI_API_KEY
- Google: Use @ai-sdk/google with GOOGLE_API_KEY

Expected Output:
- Installed packages listed
- API route created at correct location
- .env.local template created
- Example client component (if requested)
- Clear instructions for adding API keys")

Phase 5: Validation
Goal: Verify the integration is correct

Actions:
- Check that packages were installed:
  !{bash grep -E "(ai|@ai-sdk)" package.json}
- Verify API route exists:
  !{bash test -f app/api/chat/route.ts && echo "App Router API found" || test -f pages/api/chat.ts && echo "Pages Router API found" || echo "API route not found"}
- Check .env.local template exists:
  !{bash test -f .env.local.example && echo "Found .env.local.example" || test -f .env.local && echo "Found .env.local" || echo "No env template"}
- Run TypeScript check if applicable:
  !{bash test -f tsconfig.json && npm run type-check 2>/dev/null || echo "TypeScript not configured"}

Phase 6: Examples and Next Steps
Goal: Show the user how to use the integration

Actions:
- Display API route location and basic usage
- Show example of streaming chat completion:
  - Client component with useChat() hook
  - API route with streamText() function
- List environment variables that need to be set:
  - Based on selected providers
  - Show where to get API keys
- Provide next steps:
  - Add API keys to .env.local
  - Start development server: npm run dev
  - Test the chat endpoint
  - Customize the system prompt and model parameters

Phase 7: Summary
Goal: Recap what was accomplished

Actions:
- Summarize integration:
  - Packages installed (ai, provider SDKs)
  - API routes created
  - Environment variables configured
  - Examples provided
- Highlight key files:
  - API route location
  - Example component location
  - .env configuration
- Remind about API key setup
- Suggest testing the integration with a simple prompt
