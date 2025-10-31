---
description: Add advanced UI features to Vercel AI SDK app including generative UI, useObject, useCompletion, message persistence, and attachments
argument-hint: [feature-requests]
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Add advanced UI capabilities to a Vercel AI SDK application including generative user interfaces, structured object generation, text completion, message persistence, and file attachments.

Core Principles:
- Understand existing project structure before adding features
- Ask for clarification when feature requirements are unclear
- Follow Vercel AI SDK documentation patterns
- Maintain framework-agnostic approach (Next.js, React, Node.js, etc.)

Phase 1: Discovery
Goal: Understand what UI features are needed

Actions:
- Parse $ARGUMENTS to identify requested features
- If unclear or no arguments provided, use AskUserQuestion to gather:
  - Which UI features do you want? (Generative UI, useObject, useCompletion, persistence, attachments)
  - Do you have a database set up for persistence?
  - What framework are you using? (or should we detect it?)
- Load package.json to understand current setup
- Example: @package.json

Phase 2: Analysis
Goal: Understand current project state

Actions:
- Check for existing AI SDK installation
- Identify framework (Next.js App Router, Pages Router, plain React, etc.)
- Locate existing AI-related code
- Verify TypeScript/JavaScript setup
- Example: !{bash ls tsconfig.json package.json 2>/dev/null}

Phase 3: Implementation
Goal: Add requested UI features using specialized agent

Actions:

Invoke the vercel-ai-ui-agent to implement the requested UI features.

The agent should:
- Fetch relevant Vercel AI SDK documentation for the requested features
- Detect the framework and adapt implementation accordingly
- Install required packages (@ai-sdk/ui-utils, zod, database clients if needed)
- Implement requested features following SDK best practices:
  - Generative UI using AI SDK RSC (if Next.js App Router)
  - useObject hook for structured outputs
  - useCompletion hook for text completion
  - Message persistence with database integration
  - File attachment handling for multi-modal chat
- Add proper TypeScript types
- Implement error handling and loading states
- Follow existing project patterns and conventions

Provide the agent with:
- Context: Current project structure and framework
- Target: $ARGUMENTS (requested UI features)
- Expected output: Production-ready UI components with proper error handling

Phase 4: Verification
Goal: Ensure features work correctly

Actions:
- Run TypeScript compilation check
- Example: !{bash npx tsc --noEmit}
- Verify new features are properly integrated
- Check that dependencies are in package.json
- Confirm environment variables are documented

Phase 5: Summary
Goal: Document what was added

Actions:
- List all UI features that were implemented
- Show file locations for new components/routes
- Note any environment variables that need to be set
- Suggest next steps (testing, styling, deployment)
