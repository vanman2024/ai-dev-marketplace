---
description: Add comprehensive text-to-speech capabilities with multiple voice models (v3, Flash, Turbo, Multilingual) and streaming support
argument-hint: [options]
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, AskUserQuestion, Skill
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

Goal: Add comprehensive TTS capabilities to the project with support for multiple ElevenLabs voice models, streaming audio, voice selection, and audio playback controls.

Core Principles:
- Detect framework and adapt implementation (Next.js, React, Python, Node.js)
- Support all 4 voice models (Eleven v3, Flash v2.5, Turbo v2.5, Multilingual v2)
- Implement both standard and streaming TTS
- Create reusable components/functions
- Include voice selection interface

Phase 1: Discovery
Goal: Understand project structure and existing setup

Actions:
- Check if ElevenLabs SDK is already installed:
  - TypeScript: !{bash npm list @elevenlabs/elevenlabs-js 2>/dev/null}
  - Python: !{bash pip show elevenlabs 2>/dev/null}
- Detect framework:
  - Next.js: @package.json (check for "next")
  - Python: @requirements.txt or @pyproject.toml
  - React: @package.json (check for "react")
- Check if authentication is configured (@.env or @.env.local)
- Parse $ARGUMENTS for specific options (model preference, streaming, etc.)

Phase 2: Requirements Gathering
Goal: Clarify TTS implementation needs

Actions:
- If $ARGUMENTS doesn't specify preferences, use AskUserQuestion to ask:
  - Which voice model to prioritize? (v3 Alpha for quality, Flash v2.5 for speed, Turbo v2.5 for balance, Multilingual v2 for stability)
  - Do you need streaming audio support? (real-time vs complete audio)
  - Should we include voice selection UI? (dropdown/list of available voices)
  - Where should TTS functionality be added? (new page, existing component, API route, etc.)

Phase 3: Planning
Goal: Design the TTS implementation approach

Actions:
- Based on detected framework, plan:
  - Component structure (React components, Python functions, API routes)
  - File locations following project conventions
  - Voice model configuration strategy
  - Audio playback implementation
  - Error handling approach
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Build TTS integration with specialized agent

Actions:

Launch the elevenlabs-tts-integrator agent to implement text-to-speech capabilities.

Provide the agent with a detailed prompt including:
- Context: Detected framework, existing project structure, SDK installation status
- Target: $ARGUMENTS (any specific requirements)
- Requirements:
  - Create TTS function/component with support for all 4 models:
    * Eleven v3 Alpha (eleven_multilingual_v3) - highest quality, 70+ languages
    * Eleven Flash v2.5 (eleven_flash_v2_5) - ultra-low latency ~75ms, 32 languages
    * Eleven Turbo v2.5 (eleven_turbo_v2_5) - balanced speed/quality ~250ms
    * Eleven Multilingual v2 (eleven_multilingual_v2) - stable, 29 languages
  - Implement standard TTS (complete audio generation)
  - Implement streaming TTS (real-time audio streaming) if requested
  - Add voice selection interface (fetch from /v1/voices API)
  - Create audio playback controls
  - Include error handling and loading states
  - Follow framework-specific patterns (React hooks, FastAPI routes, etc.)
  - Add proper TypeScript types or Python type hints
  - Use progressive documentation loading (fetch ElevenLabs TTS docs as needed)
- Expected output:
  - TTS component/function created
  - Voice selection UI (if requested)
  - Audio playback implementation
  - Example usage code
  - Configuration for voice model selection

Phase 5: Verification
Goal: Ensure TTS implementation works correctly

Actions:
- Verify files were created in correct locations
- Check for TypeScript/Python errors:
  - TypeScript: !{bash npx tsc --noEmit 2>/dev/null || echo "No TypeScript check available"}
  - Python: !{bash python -m py_compile *.py 2>/dev/null || echo "No Python files to check"}
- Verify imports and dependencies
- Test that API key is properly referenced from environment

Phase 6: Summary
Goal: Guide user on using TTS features

Actions:
- Display implementation summary:
  - Files created: [list of new files]
  - Voice models available: [list of 4 models with descriptions]
  - Features implemented: [standard TTS, streaming, voice selection, etc.]
- Provide usage instructions:
  - How to convert text to speech
  - How to select different voice models
  - How to use streaming vs standard mode
  - How to customize voice settings (stability, clarity, style)
- Show code example for detected framework
- Suggest next steps:
  - Test with different voice models
  - Explore voice cloning: /elevenlabs:add-voice-management
  - Add Vercel AI SDK integration: /elevenlabs:add-vercel-ai-sdk
  - Configure production features: /elevenlabs:add-production
