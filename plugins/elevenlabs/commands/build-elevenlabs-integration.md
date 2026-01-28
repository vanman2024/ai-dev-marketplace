---
description: Build complete ElevenLabs integration - initializes if needed, then runs specialized agents for TTS, STT, voice cloning, and conversational AI
argument-hint: <project-name> [--features <tts|stt|agents|all>]
---

# Build Complete ElevenLabs Integration

**Goal:** Create a production-ready ElevenLabs integration for voice AI features.

**This command handles everything** - from setup to full integration with text-to-speech, speech-to-text, voice management, and conversational AI agents.

## Stack (Always Use Latest Versions)

- **ElevenLabs API** - Latest API version
- **elevenlabs** - Latest Python/Node SDK
- Framework integration (FastAPI, Next.js)

**IMPORTANT:** Always use the latest ElevenLabs SDK versions. Check npm/pip for current versions.

## Arguments

- `$ARGUMENTS` - Project name and optional features
- `--features <name>` - Features to enable (tts, stt, agents, all)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and features
2. Auto-detect required features from architecture docs
3. Plan voice AI integration based on use cases
4. Check API key availability

### Phase 2: ElevenLabs Setup

```
Task("Initialize ElevenLabs", @elevenlabs-setup, {
  prompt: "Initialize ElevenLabs integration:
    - Install elevenlabs SDK (latest)
    - Configure API key from environment
    - Create client singleton
    - Set up voice defaults
    Detect framework and configure appropriately."
})
```

### Phase 3: Parallel Agent Execution

```
// Agent 1: Text-to-Speech
Task("Setup TTS", @elevenlabs-tts-integrator, {
  prompt: "Implement text-to-speech:
    - Configure voice selection
    - Implement streaming audio
    - Add voice settings (stability, similarity)
    - Create TTS API endpoints
    Follow voice requirements from architecture."
})

// Agent 2: Speech-to-Text (if needed)
Task("Setup STT", @elevenlabs-stt-integrator, {
  prompt: "Implement speech-to-text if specified:
    - Configure audio input handling
    - Implement real-time transcription
    - Add language detection
    - Create STT API endpoints
    Skip if no STT in architecture."
})

// Agent 3: Voice Management
Task("Manage voices", @elevenlabs-voice-manager, {
  prompt: "Set up voice management:
    - List available voices
    - Configure voice cloning if needed
    - Set up voice library
    - Create voice selection UI
    Follow voice requirements from architecture."
})

// Agent 4: Conversational AI (if needed)
Task("Build AI agents", @elevenlabs-agents-builder, {
  prompt: "Implement conversational AI agents if specified:
    - Configure ElevenLabs Conversational AI
    - Set up agent prompts and personas
    - Implement real-time conversation
    - Add tool/function calling
    Skip if no agents in architecture."
})
```

### Phase 4: Production Optimization

```
Task("Optimize for production", @elevenlabs-production-agent, {
  prompt: "Optimize implementation:
    - Add caching for generated audio
    - Implement rate limiting
    - Configure error handling
    - Add usage tracking/quotas
    Prepare for production use."
})
```

### Phase 5: Final Output

**Provide summary:**

- Voice features implemented
- Voices configured
- Usage examples:

  ```python
  # Generate speech
  audio = client.generate(
      text="Hello world",
      voice="Rachel",
      model="eleven_multilingual_v2"
  )

  # Stream audio
  for chunk in client.generate_stream(...):
      play(chunk)
  ```

## Utility Commands

- `/elevenlabs:add-tts` - Text-to-speech only
- `/elevenlabs:add-stt` - Speech-to-text only
- `/elevenlabs:add-agents` - Conversational AI agents
- `/elevenlabs:manage-voices` - Voice cloning/management
