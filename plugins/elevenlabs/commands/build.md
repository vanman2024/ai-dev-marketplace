---
description: Build complete ElevenLabs integration for new or existing projects with text-to-speech, speech-to-text, voice cloning, and conversational AI agents
argument-hint: [project-name] [--existing]
---

# Build ElevenLabs Integration

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(elevenlabs-setup) Analyze project for ElevenLabs integration.

Detect: Language (TypeScript, Python), framework
Check: Existing audio handling
Output: Integration strategy
```

---

## Phase 2: Core Setup

**Goal:** Set up ElevenLabs SDK

**Actions:**

```
Task(elevenlabs-setup) Set up ElevenLabs infrastructure.

Requirements:
- Install elevenlabs SDK
- Configure API key
- Set up client instance
- Test connection
```

---

## Phase 3: Text-to-Speech

**Goal:** Add TTS capabilities

**Actions:**

```
Task(elevenlabs-tts-integrator) Set up text-to-speech.

Requirements:
- Configure TTS endpoint
- Set up voice selection
- Add streaming audio support
- Create audio output handling
- Configure voice settings (stability, similarity)
```

---

## Phase 4: Speech-to-Text

**Goal:** Add STT capabilities

**Actions:**

```
Task(elevenlabs-stt-integrator) Set up speech-to-text.

Requirements:
- Configure STT endpoint
- Handle audio input
- Process transcriptions
- Add real-time transcription
```

---

## Phase 5: Voice Management

**Goal:** Set up voice library

**Actions:**

```
Task(elevenlabs-voice-manager) Configure voice management.

Requirements:
- List available voices
- Set up voice selection UI
- Configure voice cloning (if enabled)
- Add voice preview functionality
```

---

## Phase 6: Production

**Goal:** Prepare for production

**Actions:**

```
Task(elevenlabs-production-agent) Configure production settings.

Requirements:
- Add error handling
- Set up rate limiting
- Configure caching
- Add usage tracking
- Optimize latency
```

---

## Summary

**Output:**

```
✅ ElevenLabs Integration Complete

To add features:
  /elevenlabs:add tts <options>        # Text-to-speech
  /elevenlabs:add stt                  # Speech-to-text
  /elevenlabs:add voice-clone          # Voice cloning
  /elevenlabs:add agents               # Conversational AI
  /elevenlabs:add production           # Production features

To run:
  npm run dev
```
