# ElevenLabs Plugin

Comprehensive ElevenLabs AI audio integration for voice-enabled applications with TTS, STT, voice cloning, conversational AI agents, and Vercel AI SDK support.

## Overview

The ElevenLabs plugin provides complete integration with ElevenLabs voice AI platform, enabling developers to build production-ready voice applications with text-to-speech, speech-to-text, voice cloning, and conversational agents with MCP tool calling.

## Features

### Core Capabilities
- **Text-to-Speech (TTS)**: 4 voice models (v3 Alpha, Flash v2.5, Turbo v2.5, Multilingual v2)
- **Speech-to-Text (STT)**: Scribe v1 with 99 languages, speaker diarization, timestamps
- **Voice Cloning**: Instant (1 min) and professional (30+ min) voice cloning
- **Voice Library**: Access to 70+ pre-made voices
- **Voice Design**: Generate voices from text descriptions

### Advanced Features
- **Agents Platform**: Conversational AI agents with full MCP integration
- **MCP Support**: Zapier MCP server and custom MCP servers for tool calling
- **Streaming**: Real-time WebSocket audio streaming (TTS and STT)
- **Sound Effects**: AI-generated cinematic sound effects
- **Dubbing**: Multi-language audio dubbing (70+ languages)
- **Voice Changer**: Transform voice characteristics
- **Voice Isolator**: Remove background noise

### Vercel AI SDK Integration
- **@ai-sdk/elevenlabs Provider**: Official Vercel AI SDK provider
- **experimental_transcribe**: STT with AI workflows
- **Multi-modal Chat**: Voice input → LLM → Voice output pipelines

### Production Features
- **Rate Limiting**: Concurrent request management
- **Monitoring**: Usage tracking, latency metrics, cost estimation
- **Error Handling**: Retry logic, circuit breakers, graceful degradation
- **Security**: Secure API key management, input validation
- **Cost Optimization**: Model selection, caching strategies

## Commands

### Setup & Initialization
- `/elevenlabs:init [project-name]` - Initialize ElevenLabs project with SDK and auth

### Feature Commands
- `/elevenlabs:add-text-to-speech` - Add TTS with all 4 voice models
- `/elevenlabs:add-speech-to-text` - Add STT with Scribe v1 and Vercel AI SDK
- `/elevenlabs:add-vercel-ai-sdk` - Integrate Vercel AI SDK provider
- `/elevenlabs:add-voice-management` - Add voice cloning and library features
- `/elevenlabs:add-agents-platform` - Add conversational agents with MCP
- `/elevenlabs:add-streaming` - Add real-time WebSocket streaming
- `/elevenlabs:add-advanced-features` - Add sound effects, dubbing, voice changer
- `/elevenlabs:add-production` - Add rate limiting, monitoring, security

### Orchestrator
- `/elevenlabs:build-full-stack [app-name]` - Build complete voice application (chains all commands)

## Agents

- **elevenlabs-setup**: Initialize project with SDK and framework-specific setup
- **elevenlabs-tts-integrator**: Implement TTS with all voice models
- **elevenlabs-stt-integrator**: Implement STT with Vercel AI SDK integration
- **elevenlabs-voice-manager**: Implement voice cloning and library features
- **elevenlabs-agents-builder**: Build conversational agents with MCP
- **elevenlabs-production-agent**: Implement production features

## Quick Start

### 1. Initialize Project
```bash
/elevenlabs:init my-voice-app
```

### 2. Add Features
```bash
# Add text-to-speech
/elevenlabs:add-text-to-speech

# Add speech-to-text with Vercel AI SDK
/elevenlabs:add-speech-to-text

# Add Vercel AI SDK for multi-modal chat
/elevenlabs:add-vercel-ai-sdk
```

### 3. Build Full Stack (All-in-One)
```bash
/elevenlabs:build-full-stack my-voice-app
```

## Framework Support

- **Next.js 15**: App Router, React Server Components, Vercel AI SDK integration
- **React**: Client-side voice applications
- **Python/FastAPI**: Backend APIs with async processing
- **Node.js**: Server-side voice processing

## Voice Models

| Model | Latency | Languages | Best For |
|-------|---------|-----------|----------|
| **Eleven v3 Alpha** | ~250-300ms | 70+ | Highest quality, emotional range |
| **Flash v2.5** | ~75ms | 32 | Ultra-low latency, real-time |
| **Turbo v2.5** | ~250-300ms | 32 | Balanced speed/quality |
| **Multilingual v2** | ~300ms | 29 | Stable, long-form content |

## MCP Integration

ElevenLabs has **full native MCP support** via the Agents Platform:

- **Zapier MCP Server**: Access hundreds of tools (https://zapier.com/mcp)
- **Custom MCP Servers**: Build your own tool integrations
- **Security Controls**: Fine-grained approval modes (always ask, auto-approve, disabled)
- **Real-time**: SSE and HTTP transport support

### MCP Dashboard
Configure MCP servers at: https://elevenlabs.io/app/agents/integrations

## Pricing Tiers

### Text-to-Speech
- **Free**: 10,000 chars/month
- **Starter**: $5/month - 30,000 chars
- **Creator**: $22/month - 100,000 chars
- **Pro**: $99/month - 500,000 chars

### Speech-to-Text
- **Starter**: $5/month - 12.5 hours
- **Creator**: $22/month - ~63 hours
- **Pro**: $99/month - 300 hours

## Environment Variables

Create `.env` file with:
```bash
ELEVENLABS_API_KEY=your_api_key_here
```

Get your API key: https://elevenlabs.io/app/settings/api-keys

## Documentation

### Official ElevenLabs Docs
- **Main Docs**: https://elevenlabs.io/docs/overview
- **API Reference**: https://elevenlabs.io/docs/api-reference/introduction
- **Developer Quickstart**: https://elevenlabs.io/docs/quickstart
- **Models**: https://elevenlabs.io/docs/models
- **Agents Platform**: https://elevenlabs.io/docs/agents-platform/overview
- **MCP Integration**: https://elevenlabs.io/docs/agents-platform/customization/tools/mcp

### Vercel AI SDK Integration
- **ElevenLabs Provider**: https://ai-sdk.dev/providers/ai-sdk-providers/elevenlabs
- **Transcription Guide**: https://ai-sdk.dev/docs/ai-sdk-core/transcription
- **STT Cookbook**: https://elevenlabs.io/docs/cookbooks/speech-to-text/vercel-ai-sdk

### Local Documentation
- `docs/elevenlabs-documentation-complete-links.md` - Complete URL reference
- `docs/mcp-integration-examples.md` - MCP integration patterns

## Examples

### Basic TTS (TypeScript)
```typescript
import { ElevenLabsClient } from "@elevenlabs/elevenlabs-js";

const client = new ElevenLabsClient({
  apiKey: process.env.ELEVENLABS_API_KEY,
});

const audio = await client.textToSpeech.convert({
  text: "Hello world!",
  voice_id: "JBFqnCBsd6RMkjVDRZzb",
  model_id: "eleven_flash_v2_5",
});
```

### STT with Vercel AI SDK (TypeScript)
```typescript
import { elevenlabs } from '@ai-sdk/elevenlabs';
import { experimental_transcribe as transcribe } from 'ai';

const result = await transcribe({
  model: elevenlabs.transcription('scribe_v1'),
  audio: audioFile,
  providerOptions: {
    elevenlabs: {
      languageCode: 'en',
      diarize: true,
      timestampsGranularity: 'word',
    },
  },
});
```

### Python TTS
```python
from elevenlabs.client import ElevenLabs
import os

client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))

audio = client.text_to_speech.convert(
    text="Hello world!",
    voice_id="JBFqnCBsd6RMkjVDRZzb",
    model_id="eleven_flash_v2_5"
)
```

## Contributing

This plugin is part of the ai-dev-marketplace. For issues, feature requests, or contributions, please visit the repository.

## License

MIT

## Support

- **ElevenLabs Docs**: https://elevenlabs.io/docs
- **Discord Community**: https://discord.gg/elevenlabs
- **Support**: https://elevenlabs.io/support
