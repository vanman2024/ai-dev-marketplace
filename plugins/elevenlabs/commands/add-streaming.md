---
description: Add real-time WebSocket audio streaming for both TTS and STT with low latency optimization
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

Goal: Add real-time WebSocket audio streaming for ultra-low latency TTS and continuous STT transcription with proper buffer management and connection handling.

Core Principles:
- Implement WebSocket connections for real-time audio
- Support TTS streaming (audio chunks as generated)
- Support STT streaming (continuous transcription)
- Optimize for low latency (use Flash v2.5 model ~75ms)
- Handle connection lifecycle and reconnection

Phase 1: Discovery
Goal: Understand streaming requirements

Actions:
- Load SDK documentation:
  @elevenlabs-documentation.md
- Check setup: !{bash npm list @elevenlabs/elevenlabs-js 2>/dev/null || pip show elevenlabs 2>/dev/null}
- Detect framework: @package.json or @pyproject.toml
- Check for WebSocket support
- Parse $ARGUMENTS for streaming preferences

Phase 2: Requirements Gathering
Goal: Clarify streaming implementation

Actions:
- Use AskUserQuestion if needed:
  - Which streaming? (TTS only, STT only, or both)
  - Use case? (real-time conversations, live transcription, voice chat)
  - Latency priority? (ultra-low <100ms, balanced, quality-first)
  - Buffer size? (smaller for low latency, larger for quality)
  - Client platform? (web, mobile, server-to-server)

Phase 3: Planning
Goal: Design streaming architecture

Actions:
- Plan implementation:
  - WebSocket connection management
  - TTS streaming: text chunks → audio stream
  - STT streaming: audio stream → text updates
  - Buffer management: audio queuing, playback control
  - Latency optimization: Flash v2.5 for TTS, streaming STT
  - Error handling: connection loss, reconnection
  - Client-side audio: Web Audio API, MediaRecorder API
- Present plan

Phase 4: Implementation
Goal: Build streaming capabilities

Actions:

Launch the general-purpose agent to implement WebSocket streaming.

Provide detailed requirements:
- Context: Framework, SDK status, use case
- Target: $ARGUMENTS
- Requirements:
  - TTS Streaming:
    * WebSocket connection to /v1/text-to-speech/stream
    * Send text chunks for conversion
    * Receive audio chunks in real-time
    * Use eleven_flash_v2_5 for ultra-low latency (~75ms)
    * Buffer management for smooth playback
    * Web Audio API integration for browser
  - STT Streaming:
    * Continuous audio capture (MediaRecorder)
    * Stream audio chunks to STT endpoint
    * Receive partial transcription results
    * Update UI with interim results
    * Final transcription when speech ends
  - WebSocket Lifecycle:
    * Connection establishment with auth
    * Heartbeat/ping-pong for keep-alive
    * Graceful disconnection
    * Automatic reconnection on failure
    * Error handling and recovery
  - Buffer Management:
    * Audio queue for TTS playback
    * Chunk size optimization
    * Prevent buffer underrun/overrun
    * Latency monitoring
  - Client Components:
    * Streaming audio player
    * Live transcription display
    * Connection status indicator
    * Latency metrics (optional)
  - Use progressive docs: fetch streaming docs
- Expected output:
  - WebSocket client implementation
  - TTS streaming component
  - STT streaming component
  - Buffer management utilities
  - Example usage

Phase 5: Verification
Goal: Ensure streaming works

Actions:
- Verify files created
- Check syntax: !{bash npx tsc --noEmit 2>/dev/null || python -m py_compile *.py 2>/dev/null}
- Verify WebSocket setup
- Test buffer management logic

Phase 6: Summary
Goal: Guide on streaming usage

Actions:
- Display summary:
  - Features: TTS streaming, STT streaming, or both
  - Latency: ~75ms with Flash v2.5
  - Connection: WebSocket with auto-reconnect
- Usage instructions:
  - Start streaming TTS
  - Continuous STT transcription
  - Monitor connection status
  - Handle latency/quality tradeoffs
- Performance tips:
  - Use Flash v2.5 for lowest latency
  - Optimize buffer size for use case
  - Monitor network conditions
- Show code examples
- Next steps:
  - Build voice chat: /elevenlabs:add-vercel-ai-sdk
  - Voice agents: /elevenlabs:add-agents-platform
  - Production: /elevenlabs:add-production
