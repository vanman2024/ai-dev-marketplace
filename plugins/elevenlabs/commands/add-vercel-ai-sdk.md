---
description: Add Vercel AI SDK integration with @ai-sdk/elevenlabs provider for multi-modal AI workflows
argument-hint: [options]
allowed-tools: Task(*), Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*)
---

**Arguments**: $ARGUMENTS

Goal: Integrate @ai-sdk/elevenlabs provider to enable multi-modal AI workflows combining voice transcription with LLM processing for voice-enabled chat applications.

Core Principles:
- Install @ai-sdk/elevenlabs provider package
- Configure experimental_transcribe for STT
- Integrate with existing AI SDK workflows (streamText, generateText)
- Build voice input → LLM → voice output pipelines
- Support Next.js App Router and API routes

Phase 1: Discovery
Goal: Understand existing AI SDK setup

Actions:
- Load SDK documentation:
  @plugins/domain-plugin-builder/docs/sdks/elevenlabs-documentation.md
- Check for Vercel AI SDK:
  !{bash npm list ai @ai-sdk/openai @ai-sdk/anthropic @ai-sdk/elevenlabs 2>/dev/null}
- Detect framework: @package.json
- Check existing AI routes: !{bash find app/api -name "*.ts" 2>/dev/null | head -5}
- Parse $ARGUMENTS for specific integration needs

Phase 2: Requirements Gathering
Goal: Clarify integration approach

Actions:
- Use AskUserQuestion if needed:
  - Which LLM provider are you using? (OpenAI, Anthropic, Google, etc.)
  - Do you want voice-to-voice chat? (STT → LLM → TTS)
  - Should we create API routes? (Next.js /api/transcribe, /api/chat)
  - Multi-modal chat UI? (text + voice in same interface)

Phase 3: Planning
Goal: Design Vercel AI SDK integration

Actions:
- Plan integration:
  - Install @ai-sdk/elevenlabs if not present
  - Create API route for transcription using experimental_transcribe
  - Optionally integrate with existing chat routes
  - Build client-side voice recording component
  - Connect transcription → LLM → response pipeline
- Present plan

Phase 4: Implementation
Goal: Build Vercel AI SDK integration

Actions:

Launch the elevenlabs-stt-integrator agent to implement Vercel AI SDK integration.

Provide detailed requirements:
- Context: Detected AI SDK setup, framework structure
- Target: $ARGUMENTS
- Requirements:
  - Install @ai-sdk/elevenlabs: `npm install @ai-sdk/elevenlabs`
  - Create transcription API route using experimental_transcribe
  - Import elevenlabs provider: `import { elevenlabs } from '@ai-sdk/elevenlabs'`
  - Configure transcription model: elevenlabs.transcription('scribe_v1')
  - Set providerOptions for language, diarization, timestamps
  - If voice chat requested:
    * Integrate with streamText or generateText
    * Create voice → text → LLM → response flow
    * Optionally add TTS for voice responses
  - Create client components for:
    * Audio recording interface
    * Voice input handling
    * Multi-modal chat UI (if requested)
  - Add proper error handling
  - Include TypeScript types from AI SDK
  - Use progressive docs: fetch Vercel AI SDK docs as needed
- Expected output:
  - API routes created
  - Client components for voice input
  - Integration with LLM workflows
  - Example usage code

Phase 5: Verification
Goal: Ensure integration works

Actions:
- Verify package installed:
  !{bash npm list @ai-sdk/elevenlabs 2>/dev/null}
- Check TypeScript: !{bash npx tsc --noEmit 2>/dev/null || echo "No check"}
- Verify imports resolve
- Test API routes exist

Phase 6: Summary
Goal: Guide on Vercel AI SDK usage

Actions:
- Display summary:
  - Files created: [list]
  - Integration: @ai-sdk/elevenlabs provider
  - Features: transcription, multi-modal chat, LLM workflows
- Usage instructions:
  - API endpoint: POST /api/transcribe
  - Voice chat workflow
  - Multi-modal interface
- Show code example
- Next steps:
  - Build complete voice app: /elevenlabs:build-full-stack
  - Add streaming: /elevenlabs:add-streaming
  - Production ready: /elevenlabs:add-production
