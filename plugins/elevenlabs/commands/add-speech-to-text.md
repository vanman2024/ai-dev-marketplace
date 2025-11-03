---
description: Add speech-to-text transcription with Scribe v1, 99 languages, speaker diarization, and Vercel AI SDK integration
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

Goal: Add comprehensive STT transcription capabilities with Scribe v1 model, supporting 99 languages, speaker diarization, word-level timestamps, and seamless Vercel AI SDK integration.

Core Principles:
- Detect framework and adapt (Next.js, React, Python, Node.js)
- Support Vercel AI SDK experimental_transcribe for TypeScript projects
- Include native ElevenLabs SDK for Python projects
- Implement file upload handling and audio processing
- Provide speaker diarization and timestamping options

Phase 1: Discovery
Goal: Understand project setup and STT requirements

Actions:
- Load SDK documentation:
  @elevenlabs-documentation.md
- Check existing setup:
  - SDK installed: !{bash npm list @elevenlabs/elevenlabs-js @ai-sdk/elevenlabs 2>/dev/null || pip show elevenlabs 2>/dev/null}
  - Framework: @package.json or @pyproject.toml
  - Authentication: @.env or @.env.local
- Parse $ARGUMENTS for preferences (language, diarization, timestamps)

Phase 2: Requirements Gathering
Goal: Clarify STT implementation details

Actions:
- If preferences not specified, use AskUserQuestion to ask:
  - Which approach? (Vercel AI SDK for TypeScript, Native SDK for Python)
  - Do you need speaker diarization? (identify multiple speakers)
  - Timestamp granularity? (word-level, segment-level, or none)
  - Audio event detection? (laughter, applause, background sounds)
  - Default language? (or auto-detect from 99 supported languages)
  - File upload interface? (drag-drop, file picker, URL input)

Phase 3: Planning
Goal: Design the STT implementation

Actions:
- Based on framework, plan:
  - Vercel AI SDK: Use experimental_transcribe with @ai-sdk/elevenlabs provider
  - Native SDK: Use client.speechToText.transcribe() method
  - File upload: multipart/form-data handling
  - Audio processing: format validation, size limits
  - Output format: text, words array, speaker labels, timestamps
- Present plan for confirmation

Phase 4: Implementation
Goal: Build STT integration with specialized agent

Actions:

Launch the elevenlabs-stt-integrator agent to implement speech-to-text capabilities.

Provide the agent with detailed requirements:
- Context: Detected framework, SDK status, project structure
- Target: $ARGUMENTS (specific requirements)
- Requirements:
  - Implement Scribe v1 transcription (99 languages, ≤5% WER for major languages)
  - Add file upload interface with audio validation
  - Configure transcription options:
    * Language code (auto-detect or specify)
    * Speaker diarization (up to 32 speakers)
    * Timestamps granularity (word or segment level)
    * Audio event tagging (optional)
  - For Vercel AI SDK projects:
    * Use experimental_transcribe from 'ai' package
    * Configure providerOptions.elevenlabs settings
    * Return structured TranscriptionResult
  - For Native SDK projects:
    * Use client.speechToText.transcribe()
    * Handle async audio processing
    * Format response consistently
  - Add error handling for unsupported formats, large files
  - Include loading states and progress indicators
  - Use progressive documentation: fetch STT docs as needed
- Expected output:
  - STT component/function with all features
  - File upload interface
  - Transcription result display
  - Example usage code

Phase 5: Verification
Goal: Ensure STT works correctly

Actions:
- Verify files created
- Check TypeScript/Python syntax:
  - TypeScript: !{bash npx tsc --noEmit 2>/dev/null || echo "No check"}
  - Python: !{bash python -m py_compile *.py 2>/dev/null || echo "No Python"}
- Verify imports and dependencies
- Test audio file validation logic

Phase 6: Summary
Goal: Guide user on STT usage

Actions:
- Display summary:
  - Files created: [list]
  - Languages supported: 99 (excellent accuracy for 12 major languages)
  - Features: diarization, timestamps, audio events
  - Integration: Vercel AI SDK or Native SDK
- Usage instructions:
  - Upload audio file (mp3, wav, m4a, webm, etc.)
  - Transcription with diarization
  - Access word-level timestamps
  - Speaker identification
- Show code example
- Next steps:
  - Combine with TTS: /elevenlabs:add-text-to-speech
  - Build voice chat: /elevenlabs:add-vercel-ai-sdk
  - Add streaming: /elevenlabs:add-streaming
