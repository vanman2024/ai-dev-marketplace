---
description: Add a specific feature to an existing ElevenLabs project. Features include tts, stt, voice-clone, agents, production.
argument-hint: <feature> [options]
---

# Add ElevenLabs Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Audio Features

**If `$0` = "tts":**

```
Task(elevenlabs-tts-integrator) Add TEXT-TO-SPEECH feature.

Requirements:
- Output type: $1 (streaming, file, buffer - default: streaming)
- Voice ID: $2 (optional, uses default voice)
- Configure TTS endpoint
- Set up audio streaming
- Add voice parameters
- Handle audio playback
```

**If `$0` = "stt":**

```
Task(elevenlabs-stt-integrator) Add SPEECH-TO-TEXT feature.

Requirements:
- Input type: $1 (file, microphone, stream - default: file)
- Configure STT endpoint
- Handle audio recording
- Process transcriptions
- Add real-time mode
```

### Voice Features

**If `$0` = "voice-clone":**

```
Task(elevenlabs-voice-manager) Add VOICE CLONING feature.

Requirements:
- Clone type: $1 (instant, professional - default: instant)
- Set up voice upload
- Configure cloning endpoint
- Add voice management UI
- Handle voice samples
```

**If `$0` = "voices":**

```
Task(elevenlabs-voice-manager) Add VOICE MANAGEMENT.

Requirements:
- Action: $1 (list, select, preview - default: list)
- Fetch available voices
- Create voice selector UI
- Add voice preview
- Configure favorites
```

### Agent Features

**If `$0` = "agents":**

```
Task(elevenlabs-agents-builder) Add CONVERSATIONAL AI agent.

Requirements:
- Agent type: $1 (phone, web, custom - default: web)
- Set up ElevenLabs Agents Platform
- Configure agent persona
- Add conversation handling
- Set up WebSocket connection
- Implement turn-taking
```

### Production Features

**If `$0` = "production":**

```
Task(elevenlabs-production-agent) Add PRODUCTION features.

Requirements:
- Feature: $1 (caching, ratelimit, monitoring, all - default: all)
- Add error handling
- Set up caching
- Configure rate limiting
- Add usage monitoring
- Optimize performance
```

---

## Usage Examples

```bash
# Audio features
/elevenlabs:add tts streaming
/elevenlabs:add tts file voice_id_here
/elevenlabs:add stt microphone

# Voice features
/elevenlabs:add voice-clone instant
/elevenlabs:add voices list

# Agent features
/elevenlabs:add agents web
/elevenlabs:add agents phone

# Production
/elevenlabs:add production caching
/elevenlabs:add production all
```

---

## Feature Reference

| Feature       | Agent            | $1 Options                   | Description         |
| ------------- | ---------------- | ---------------------------- | ------------------- |
| `tts`         | tts-integrator   | streaming/file/buffer        | Text-to-speech      |
| `stt`         | stt-integrator   | file/microphone/stream       | Speech-to-text      |
| `voice-clone` | voice-manager    | instant/professional         | Voice cloning       |
| `voices`      | voice-manager    | list/select/preview          | Voice management    |
| `agents`      | agents-builder   | phone/web/custom             | Conversational AI   |
| `production`  | production-agent | caching/ratelimit/monitoring | Production features |
