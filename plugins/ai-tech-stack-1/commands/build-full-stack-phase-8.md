---
description: "Phase 8: Voice Features - Text-to-speech, speech-to-text, voice agents (optional)"
argument-hint: none
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

Goal: Add complete voice capabilities (TTS, STT, voice agents).

Phase 1: Load State and Requirements
- Load .ai-stack-config.json
- Verify phase7Complete is true (or phase6Complete if RAG was skipped)
- Extract appName, paths
- Create Phase 8 todo list
- AskUserQuestion: "Do you need voice features (text-to-speech, speech-to-text, voice agents)?"
  - Options: Yes / No (recommended for most apps)
  - If "No": Skip to Phase 7 (Save State), mark voiceEnabled: false

Phase 2: Voice Requirements Gathering
- AskUserQuestion (if user selected Yes):
  - "Which voice features do you need?"
  - Options (multiple selection):
    - Text-to-Speech (TTS)
    - Speech-to-Text (STT)
    - Voice Cloning
    - Voice Agents (conversational AI with voice)
    - Real-time Streaming

Phase 3: ElevenLabs Setup
- Execute immediately: !{slashcommand /elevenlabs:init}
- After completion, verify: !{bash grep -q "ELEVEN" ".env" && echo "✅ ElevenLabs configured" || echo "❌ Missing config"}

Phase 4: Text-to-Speech (if selected)
- Execute immediately: !{slashcommand /elevenlabs:add-text-to-speech}
- After completion, verify: TTS functionality added

Phase 5: Speech-to-Text (if selected)
- Execute immediately: !{slashcommand /elevenlabs:add-speech-to-text}
- After completion, verify: STT functionality added

Phase 6: Vercel AI SDK Integration
- Execute immediately: !{slashcommand /elevenlabs:add-vercel-ai-sdk}
- Integrates ElevenLabs with existing Vercel AI SDK from Phase 2
- After completion, verify: Voice streaming integrated

Phase 7: Voice Cloning (if selected)
- Execute immediately: !{slashcommand /elevenlabs:add-voice-management}
- After completion, verify: Voice cloning configured

Phase 8: Voice Agents (if selected)
- Execute immediately: !{slashcommand /elevenlabs:add-agents-platform}
- Creates conversational voice agents with MCP integration
- After completion, verify: Voice agents configured

Phase 9: Real-time Streaming (if selected)
- Execute immediately: !{slashcommand /elevenlabs:add-streaming}
- After completion, verify: Real-time audio streaming configured

Phase 10: Production Hardening
- Execute immediately: !{slashcommand /elevenlabs:add-production}
- Adds rate limiting, error handling, monitoring
- After completion, verify: Production features configured

Phase 11: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 8 | .phase8Complete = true | .voiceEnabled = true | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display: "✅ Phase 8 Complete - Voice features added"

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 8

## What Phase 8 Creates

**Voice Infrastructure:**
- Text-to-Speech (natural voice generation, 500+ voices)
- Speech-to-Text (99 languages, speaker diarization)
- Voice cloning (instant and professional)
- Voice agents with conversational AI
- Real-time audio streaming
- WebSocket connections for live audio
- Voice library management

**Integration Points:**
- Frontend voice components
- Backend voice API endpoints
- Vercel AI SDK voice streaming
- MCP voice agent tools

**Total Time:** ~10-15 minutes
