---
description: Initialize ElevenLabs project with SDK installation, authentication setup, and framework detection
argument-hint: [project-name]
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

Goal: Setup ElevenLabs integration with automatic framework detection, SDK installation, authentication configuration, and basic TTS/STT examples.

Core Principles:
- Detect framework (Next.js, React, Python, Node.js) - never assume
- Install appropriate SDK (@elevenlabs/elevenlabs-js or elevenlabs Python)
- Configure authentication securely (.env files)
- Provide working examples adapted to detected framework
- Include Vercel AI SDK setup if Next.js detected

Phase 1: Discovery
Goal: Understand project structure and gather requirements

Actions:
- Parse $ARGUMENTS for optional project name
- Detect project type by checking for framework indicators:
  - Next.js: package.json with "next" dependency
  - React: package.json with "react" without "next"
  - Python: requirements.txt, pyproject.toml, or setup.py
  - Node.js: package.json without framework
- Load relevant configuration files for context
- Example: !{bash ls package.json pyproject.toml requirements.txt 2>/dev/null}

Phase 2: Requirements Gathering
Goal: Clarify user needs

Actions:
- If framework cannot be detected or multiple options exist, use AskUserQuestion to ask:
  - Which framework are you using? (Next.js, React, Python/FastAPI, Node.js, Other)
  - Do you want Vercel AI SDK integration? (for Next.js/React projects)
  - Which features to include? (TTS, STT, Voice Cloning, Streaming)
  - Do you have an ElevenLabs API key? (if no, provide instructions)

Phase 3: Planning
Goal: Design the setup approach

Actions:
- Based on detected framework, determine:
  - Which SDK to install (TypeScript or Python)
  - Where to place configuration (.env, .env.local)
  - Which example files to create
  - Whether to include Vercel AI SDK (@ai-sdk/elevenlabs)
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Execute setup with specialized agent

Actions:

Launch the elevenlabs-setup agent to initialize the ElevenLabs integration.

Provide the agent with a detailed prompt including:
- Context: Detected framework and project structure
- Target: $ARGUMENTS (project name if provided)
- Requirements:
  - Install appropriate SDK (TypeScript: @elevenlabs/elevenlabs-js OR Python: elevenlabs)
  - Setup authentication (.env file with ELEVENLABS_API_KEY)
  - Create basic TTS example
  - Create basic STT example (if requested)
  - Add Vercel AI SDK integration if Next.js detected and user requested
  - Follow existing project conventions and structure
  - Use progressive documentation loading (fetch docs as needed, not all upfront)
- Expected output:
  - SDK installed and configured
  - .env file created with API key placeholder
  - Example files created in appropriate locations
  - README or setup instructions

Phase 5: Verification
Goal: Ensure setup is complete and functional

Actions:
- Verify SDK installation:
  - TypeScript: !{bash npm list @elevenlabs/elevenlabs-js 2>/dev/null || echo "Not installed"}
  - Python: !{bash pip show elevenlabs 2>/dev/null || echo "Not installed"}
- Check .env file exists and has placeholder
- Verify example files were created
- Test imports/syntax if possible

Phase 6: Summary
Goal: Guide user on next steps

Actions:
- Display setup summary:
  - Framework detected: [framework]
  - SDK installed: [version]
  - Files created: [list of files]
  - Configuration: .env file location
- Provide next steps:
  1. Add your ElevenLabs API key to .env file (get from https://elevenlabs.io/app/settings/api-keys)
  2. Run example: [command to run example]
  3. Explore features: /elevenlabs:add-text-to-speech, /elevenlabs:add-speech-to-text
  4. For Vercel AI SDK: /elevenlabs:add-vercel-ai-sdk
- Show quick start code snippet for detected framework
