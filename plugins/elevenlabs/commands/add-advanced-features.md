---
description: Add sound effects generation, voice changer, dubbing, and voice isolator capabilities
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

Goal: Add advanced audio capabilities including AI sound effects generation, voice transformation, multi-language dubbing, and background noise removal.

Core Principles:
- Support sound effects generation from text descriptions
- Enable voice-to-voice transformation
- Implement multi-language dubbing workflows
- Provide voice isolation (noise removal)
- Detect framework and adapt implementation

Phase 1: Discovery
Goal: Understand which advanced features are needed

Actions:
- Load SDK documentation:
  @elevenlabs-documentation.md
- Check setup: !{bash npm list @elevenlabs/elevenlabs-js 2>/dev/null || pip show elevenlabs 2>/dev/null}
- Detect framework: @package.json or @pyproject.toml
- Parse $ARGUMENTS for feature selection

Phase 2: Requirements Gathering
Goal: Clarify feature scope

Actions:
- Use AskUserQuestion if needed:
  - Which features? (Sound effects, Voice changer, Dubbing, Voice isolator)
  - Sound effects: text descriptions → audio (cinematic quality)
  - Voice changer: transform voice characteristics
  - Dubbing: translate and dub audio to other languages
  - Voice isolator: remove background noise from recordings
  - Use cases for each selected feature

Phase 3: Planning
Goal: Design advanced features implementation

Actions:
- For each selected feature, plan:
  - Sound Effects: text prompt → audio generation, duration control
  - Voice Changer: source audio → transformed voice, settings
  - Dubbing: source audio + target language → dubbed audio
  - Voice Isolator: noisy audio → clean voice output
- File upload/processing requirements
- API endpoints and parameters
- Present plan

Phase 4: Implementation
Goal: Build advanced features

Actions:

Launch the general-purpose agent to implement advanced audio features.

Provide detailed requirements:
- Context: Framework, SDK status, selected features
- Target: $ARGUMENTS
- Requirements:
  - Sound Effects Generation:
    * POST /v1/sound-effects endpoint
    * Text description input (e.g., "cinematic thunder")
    * Duration parameter (optional)
    * Audio format selection
    * Preview and download generated audio
  - Voice Changer:
    * POST /v1/voice-changer endpoint
    * Upload source audio
    * Select target voice characteristics
    * Transform voice while preserving speech
    * Output transformed audio
  - Dubbing:
    * POST /v1/dubbing endpoint
    * Upload source audio/video
    * Select target language (70+ supported)
    * Voice mapping for speakers
    * Dubbed audio output with timing preserved
  - Voice Isolator:
    * POST /v1/voice-isolator endpoint
    * Upload audio with background noise
    * Remove noise, enhance voice clarity
    * Output clean voice track
  - For each feature:
    * File upload interface
    * Parameter configuration UI
    * Processing status/progress
    * Result preview and download
    * Error handling
  - Use progressive docs: fetch relevant feature docs
- Expected output:
  - Interface for each selected feature
  - File upload handling
  - API integration code
  - Processing workflows
  - Example usage

Phase 5: Verification
Goal: Ensure features work correctly

Actions:
- Verify files created
- Check syntax: !{bash npx tsc --noEmit 2>/dev/null || python -m py_compile *.py 2>/dev/null}
- Verify API endpoints referenced
- Test file upload logic

Phase 6: Summary
Goal: Guide on using advanced features

Actions:
- Display summary:
  - Features implemented: [list]
  - Sound effects: text → cinematic audio
  - Voice changer: transform voice characteristics
  - Dubbing: 70+ languages
  - Voice isolator: noise removal
- Usage instructions for each feature
- Show code examples
- Use cases:
  - Sound effects: game audio, podcasts, videos
  - Voice changer: privacy, creative projects
  - Dubbing: international content
  - Voice isolator: podcast cleanup, interviews
- Next steps:
  - Integrate with TTS/STT: /elevenlabs:add-text-to-speech
  - Production deploy: /elevenlabs:add-production
  - Full stack: /elevenlabs:build-full-stack
