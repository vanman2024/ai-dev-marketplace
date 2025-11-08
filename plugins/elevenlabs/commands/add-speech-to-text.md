---
description: Add speech-to-text transcription with Scribe v1, 99 languages, speaker diarization, and Vercel AI SDK integration
argument-hint: [options]
---
## Available Skills

This commands has access to the following skills from the elevenlabs plugin:

- **api-authentication**: API authentication patterns, SDK installation scripts, environment variable management, and connection testing for ElevenLabs. Use when setting up ElevenLabs authentication, installing ElevenLabs SDK, configuring API keys, testing ElevenLabs connection, or when user mentions ElevenLabs authentication, xi-api-key, ELEVENLABS_API_KEY, or ElevenLabs setup.
- **mcp-integration**
- **production-deployment**: Production deployment patterns for ElevenLabs API including rate limiting, error handling, monitoring, and testing. Use when deploying to production, implementing rate limiting, setting up monitoring, handling errors, testing concurrency, or when user mentions production deployment, rate limits, error handling, monitoring, ElevenLabs production.
- **stt-integration**: ElevenLabs Speech-to-Text transcription workflows with Scribe v1 supporting 99 languages, speaker diarization, and Vercel AI SDK integration. Use when implementing audio transcription, building STT features, integrating speech-to-text, setting up Vercel AI SDK with ElevenLabs, or when user mentions transcription, STT, Scribe v1, audio-to-text, speaker diarization, or multi-language transcription.
- **tts-integration**
- **vercel-ai-patterns**
- **voice-processing**: Voice cloning workflows, voice library management, audio format conversion, and voice settings. Use when cloning voices, managing voice libraries, processing audio for voice creation, configuring voice settings, or when user mentions voice cloning, instant cloning, professional cloning, voice library, audio processing, voice settings, or ElevenLabs voices.

**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

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
