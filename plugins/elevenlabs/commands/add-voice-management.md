---
description: Add voice cloning, library access, voice design, and voice customization capabilities
argument-hint: [options]
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, AskUserQuestion
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

Goal: Add comprehensive voice management features including instant/professional voice cloning, voice library access, voice design from text descriptions, and voice customization.

Core Principles:
- Support instant cloning (1 min audio) and professional cloning (30+ min)
- Provide voice library browsing and selection
- Enable voice design (generate from text descriptions)
- Include voice remixing and customization
- Implement voice upload and file handling

Phase 1: Discovery
Goal: Understand voice management needs

Actions:
- Load SDK documentation:
  @elevenlabs-documentation.md
- Check setup: !{bash npm list @elevenlabs/elevenlabs-js 2>/dev/null || pip show elevenlabs 2>/dev/null}
- Detect framework: @package.json or @pyproject.toml
- Parse $ARGUMENTS for specific voice features

Phase 2: Requirements Gathering
Goal: Clarify voice management scope

Actions:
- Use AskUserQuestion if needed:
  - Which features? (Voice cloning, Library, Design, Remix)
  - Cloning type? (Instant for quick, Professional for quality)
  - Voice library UI? (Browse, search, preview voices)
  - Voice design? (Generate from text descriptions)
  - File upload? (Audio samples for cloning)

Phase 3: Planning
Goal: Design voice management system

Actions:
- Plan implementation:
  - Voice cloning: upload audio, process, test cloned voice
  - Voice library: fetch available voices, preview, select
  - Voice design: text input → voice generation
  - Voice settings: stability, similarity, style, boost
  - Storage: manage custom voices
- Present plan

Phase 4: Implementation
Goal: Build voice management features

Actions:

Launch the elevenlabs-voice-manager agent to implement voice management.

Provide detailed requirements:
- Context: Framework, SDK status, project structure
- Target: $ARGUMENTS
- Requirements:
  - Instant Voice Cloning:
    * File upload (1 min minimum audio)
    * POST /v1/voices/add endpoint
    * Voice name and description
    * Test cloned voice with sample text
  - Professional Voice Cloning:
    * Upload 30+ minutes of audio
    * Higher quality cloning
    * Additional customization options
  - Voice Library:
    * GET /v1/voices endpoint
    * Browse 70+ pre-made voices
    * Voice preview functionality
    * Voice selection interface
  - Voice Design:
    * Text description → voice generation
    * Gender, age, accent parameters
    * Preview and iterate
  - Voice Settings:
    * Stability (0-1): consistency vs expressiveness
    * Similarity boost (0-1): closeness to original
    * Style exaggeration (0-1): emphasis
    * Speaker boost (boolean): enhance clarity
  - File handling for audio upload
  - Error handling for invalid audio
  - Use progressive docs: fetch voice cloning docs
- Expected output:
  - Voice cloning interface
  - Voice library browser
  - Voice design tool
  - Settings customization
  - Example usage

Phase 5: Verification
Goal: Ensure voice features work

Actions:
- Verify files created
- Check syntax: !{bash npx tsc --noEmit 2>/dev/null || python -m py_compile *.py 2>/dev/null}
- Verify API endpoints referenced
- Test file upload validation

Phase 6: Summary
Goal: Guide on voice management

Actions:
- Display summary:
  - Features: cloning, library, design, customization
  - Voice library: 70+ pre-made voices
  - Cloning types: instant (1 min) vs professional (30+ min)
- Usage instructions:
  - Clone voice from audio sample
  - Browse and preview voices
  - Generate voice from description
  - Customize voice settings
- Show examples
- Next steps:
  - Use cloned voices: /elevenlabs:add-text-to-speech
  - Build voice agents: /elevenlabs:add-agents-platform
