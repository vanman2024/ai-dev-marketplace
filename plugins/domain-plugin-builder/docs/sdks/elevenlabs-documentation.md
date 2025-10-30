# ElevenLabs SDK Documentation

*Comprehensive voice AI documentation for building TTS, STT, voice cloning, and agent applications*

Generated on: January 2025

## 🎤 ElevenLabs - Voice AI Platform

ElevenLabs provides cutting-edge AI voice technology including text-to-speech, speech-to-text, voice cloning, and conversational AI agents with full MCP support.

### Core SDK Documentation

- **[Overview](https://elevenlabs.io/docs/overview)** - Getting started with ElevenLabs
- **[Developer Quickstart](https://elevenlabs.io/docs/quickstart)** - Quick setup guide
- **[API Reference](https://elevenlabs.io/docs/api-reference/introduction)** - Complete API documentation
- **[Authentication](https://elevenlabs.io/docs/api-reference/authentication)** - API key setup

### Text-to-Speech (TTS)

- **[TTS Overview](https://elevenlabs.io/docs/capabilities/text-to-speech)** - Text-to-speech capabilities
- **[TTS API](https://elevenlabs.io/docs/api-reference/text-to-speech)** - Convert text to speech
- **[TTS Streaming](https://elevenlabs.io/docs/api-reference/streaming)** - Real-time audio streaming
- **[TTS Quickstart](https://elevenlabs.io/docs/cookbooks/text-to-speech/quickstart)** - Quick TTS tutorial

### Speech-to-Text (STT)

- **[STT Overview](https://elevenlabs.io/docs/capabilities/speech-to-text)** - Speech recognition with Scribe v1
- **[STT API](https://elevenlabs.io/docs/api-reference/speech-to-text)** - Transcribe audio
- **[STT Quickstart](https://elevenlabs.io/docs/cookbooks/speech-to-text/quickstart)** - Quick STT tutorial
- **[Vercel AI SDK Integration](https://elevenlabs.io/docs/cookbooks/speech-to-text/vercel-ai-sdk)** - STT with @ai-sdk/elevenlabs

### Voice Models

- **[Models Overview](https://elevenlabs.io/docs/models)** - All available models
- **[Eleven v3 Alpha](https://elevenlabs.io/docs/models#eleven-v3-alpha)** - Highest quality, 70+ languages
- **[Flash v2.5](https://elevenlabs.io/docs/models#flash-v25)** - Ultra-low latency ~75ms
- **[Turbo v2.5](https://elevenlabs.io/docs/models#turbo-v25)** - Balanced speed/quality
- **[Multilingual v2](https://elevenlabs.io/docs/models#multilingual-v2)** - Stable, 29 languages

### Voice Management

- **[Voices Overview](https://elevenlabs.io/docs/capabilities/voices)** - Voice library and cloning
- **[Instant Voice Cloning](https://elevenlabs.io/docs/cookbooks/voices/instant-voice-cloning)** - Clone with 1 min audio
- **[Professional Voice Cloning](https://elevenlabs.io/docs/cookbooks/voices/professional-voice-cloning)** - Clone with 30+ min
- **[Voice Design](https://elevenlabs.io/docs/cookbooks/voices/voice-design)** - Generate voices from text
- **[Voice Remixing](https://elevenlabs.io/docs/cookbooks/voices/remix-a-voice)** - Modify existing voices
- **[Voices API](https://elevenlabs.io/docs/api-reference/voices)** - Voice management endpoints

### Agents Platform & MCP Integration

- **[Agents Overview](https://elevenlabs.io/docs/agents-platform/overview)** - Conversational AI agents
- **[Agents Quickstart](https://elevenlabs.io/docs/agents-platform/quickstart)** - Get started with agents
- **[MCP Integration](https://elevenlabs.io/docs/agents-platform/customization/tools/mcp)** - Model Context Protocol support
- **[MCP Security](https://elevenlabs.io/docs/agents-platform/customization/tools/mcp/security)** - MCP security best practices
- **[MCP Dashboard](https://elevenlabs.io/app/agents/integrations)** - Configure MCP servers

### Advanced Features

- **[Sound Effects](https://elevenlabs.io/docs/capabilities/sound-effects)** - AI sound effect generation
- **[Sound Effects API](https://elevenlabs.io/docs/api-reference/sound-effects)** - Sound effects endpoint
- **[Voice Changer](https://elevenlabs.io/docs/capabilities/voice-changer)** - Transform voices
- **[Voice Isolator](https://elevenlabs.io/docs/capabilities/voice-isolator)** - Remove background noise
- **[Dubbing](https://elevenlabs.io/docs/capabilities/dubbing)** - Multi-language dubbing
- **[Dubbing API](https://elevenlabs.io/docs/api-reference/dubbing)** - Dubbing endpoint

### Streaming & Real-time

- **[Streaming API](https://elevenlabs.io/docs/api-reference/streaming)** - WebSocket streaming
- **[WebSockets](https://elevenlabs.io/docs/api-reference/websockets)** - Real-time connections

### Production & Optimization

- **[Concurrency & Priority](https://elevenlabs.io/docs/models#concurrency-and-priority)** - Rate limiting and optimization
- **[Pricing](https://elevenlabs.io/pricing)** - Pricing tiers and costs

## 🚀 SDK Quick Start

### Installation

```bash
# Python
pip install elevenlabs

# JavaScript/TypeScript
npm install @elevenlabs/elevenlabs-js

# Vercel AI SDK Provider
npm install @ai-sdk/elevenlabs
```

### Basic TTS Usage

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

### Basic STT with Vercel AI SDK

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

## 🤖 Key SDK Concepts

### Voice Models Comparison

| Model | Latency | Languages | Best For |
|-------|---------|-----------|----------|
| **Eleven v3 Alpha** | ~250-300ms | 70+ | Highest quality, emotional range |
| **Flash v2.5** | ~75ms | 32 | Ultra-low latency, real-time |
| **Turbo v2.5** | ~250-300ms | 32 | Balanced speed/quality |
| **Multilingual v2** | ~300ms | 29 | Stable, long-form content |

### Vercel AI SDK Integration

- **Official Provider**: @ai-sdk/elevenlabs
- **Transcription**: experimental_transcribe function
- **Multi-modal**: Combine with LLMs for voice conversations
- **Streaming**: Real-time audio processing

### MCP Integration (Major Feature!)

- **Native Support**: Built into Agents Platform
- **Zapier Integration**: Access hundreds of tools
- **Security Controls**: Fine-grained approval modes
- **Real-time**: SSE and HTTP transport

## 📚 Related Resources

- **[Python SDK (PyPI)](https://pypi.org/project/elevenlabs/)** - Python package
- **[TypeScript SDK (npm)](https://www.npmjs.com/package/@elevenlabs/elevenlabs-js)** - TypeScript package
- **[Vercel AI SDK Provider](https://ai-sdk.dev/providers/ai-sdk-providers/elevenlabs)** - Vercel integration
- **[GitHub](https://github.com/elevenlabs)** - Source code and examples
- **[Discord Community](https://discord.gg/elevenlabs)** - Developer community
