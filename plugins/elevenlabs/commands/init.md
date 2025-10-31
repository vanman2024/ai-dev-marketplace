---
description: Initialize ElevenLabs project with SDK installation, authentication setup, and framework detection
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion
---

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
