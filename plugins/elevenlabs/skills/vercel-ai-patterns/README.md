---
name: vercel-ai-patterns
description: Vercel AI SDK integration patterns for ElevenLabs including @ai-sdk/elevenlabs setup, transcription workflows, multi-modal chat, and voice-to-LLM pipelines. Use when building Next.js AI apps with ElevenLabs, implementing voice transcription, creating multi-modal chat interfaces, setting up voice workflows, or when user mentions Vercel AI SDK, @ai-sdk/elevenlabs, experimental_transcribe, multi-modal, or voice-to-text integration.
allowed-tools: Read(*), Bash(*)
---

# Vercel AI Patterns for ElevenLabs

Complete integration patterns for using ElevenLabs with Vercel AI SDK through the `@ai-sdk/elevenlabs` provider.

## Overview

This skill provides:
- Setup scripts for @ai-sdk/elevenlabs integration
- TypeScript templates for transcription workflows
- Multi-modal chat component patterns
- Complete working examples for Next.js apps
- Voice-to-LLM pipeline implementations

## Quick Start

### 1. Install Dependencies

```bash
bash scripts/setup-vercel-ai.sh
```

This installs:
- `@ai-sdk/elevenlabs` - ElevenLabs provider
- `ai` - Vercel AI SDK core
- Required Next.js dependencies

### 2. Configure API Keys

```bash
# .env.local
ELEVENLABS_API_KEY=your_elevenlabs_api_key
OPENAI_API_KEY=your_openai_api_key  # Optional for LLM responses
```

### 3. Test Transcription

```bash
bash scripts/test-transcription.sh /path/to/audio.mp3
```

## Components

### Scripts

**setup-vercel-ai.sh**
- Installs @ai-sdk/elevenlabs and dependencies
- Verifies installation
- Creates example .env.local template
- Checks Next.js compatibility

**test-transcription.sh**
- Tests transcription with sample audio file
- Validates API key configuration
- Reports transcription results with timing
- Debugging support for troubleshooting

**create-api-route.sh**
- Generates Next.js API route for transcription
- Supports App Router (app/) and Pages Router (pages/)
- Includes error handling and validation
- TypeScript ready

**validate-integration.sh**
- Validates @ai-sdk/elevenlabs installation
- Checks API key configuration
- Tests transcription endpoint
- Reports integration status

**benchmark-transcription.sh**
- Performance testing for transcription workflows
- Measures latency and throughput
- Compares different audio formats
- Generates performance reports

### Templates

**api-route.ts.template**
- Next.js API route for transcription
- Handles file uploads
- Returns transcribed text with metadata
- Error handling included

**transcribe-hook.ts.template**
- React hook for client-side transcription
- File upload handling
- Loading states and error management
- TypeScript typed

**multi-modal-chat.tsx.template**
- Complete multi-modal chat component
- Voice input + text input support
- Displays transcription results
- LLM integration ready

**voice-workflow.ts.template**
- Voice → Transcription → LLM → Response pipeline
- Combines experimental_transcribe with generateText
- Streaming support
- Context management

**streaming-transcription.ts.template**
- Real-time transcription streaming
- WebSocket integration
- Chunk processing
- Progress updates

**speaker-diarization.ts.template**
- Multi-speaker transcription
- Speaker identification and labeling
- Timestamp granularity options
- Diarization configuration

### Examples

**nextjs-transcription/**
- Complete Next.js 15 app with transcription
- File upload interface
- API route implementation
- Results display with metadata

**multi-modal-chat/**
- Voice + text chat application
- ElevenLabs transcription integration
- OpenAI GPT integration for responses
- Real-time conversation flow

**voice-workflow/**
- End-to-end voice workflow example
- Record → Transcribe → Process → Respond
- Error recovery patterns
- Production-ready structure

**streaming-example/**
- Real-time streaming transcription
- Progress indicators
- Chunk-based processing
- WebSocket implementation

**speaker-detection/**
- Multi-speaker conversation transcription
- Speaker identification demo
- Timestamp visualization
- Meeting transcription use case

## Integration Patterns

### Pattern 1: Basic Transcription

```typescript
import { experimental_transcribe as transcribe } from 'ai';
import { elevenlabs } from '@ai-sdk/elevenlabs';

const { text } = await transcribe({
  model: elevenlabs.transcription('scribe_v1')
  audio: audioBuffer
});
```

### Pattern 2: Multi-Modal Chat

```typescript
// 1. Transcribe voice input
const { text: userMessage } = await transcribe({
  model: elevenlabs.transcription('scribe_v1')
  audio: voiceInput
});

// 2. Generate LLM response
const { text: aiResponse } = await generateText({
  model: openai('gpt-4')
  prompt: userMessage
});

// 3. Optionally synthesize speech response
const { audio: responseAudio } = await experimental_generateSpeech({
  model: elevenlabs.speech('eleven_multilingual_v2')
  text: aiResponse
});
```

### Pattern 3: Speaker Diarization

```typescript
const { text, segments } = await transcribe({
  model: elevenlabs.transcription('scribe_v1')
  audio: meetingRecording
  providerOptions: {
    elevenlabs: {
      diarize: true
      numSpeakers: 3
      timestampsGranularity: 'word'
    }
  }
});

// segments contains speaker labels and timestamps
segments?.forEach(segment => {
  console.log(`[Speaker ${segment.speaker}] ${segment.text}`);
});
```

### Pattern 4: Streaming Transcription

```typescript
import { experimental_transcribeStream } from 'ai';

const stream = await experimental_transcribeStream({
  model: elevenlabs.transcription('scribe_v1')
  audio: audioStream
});

for await (const chunk of stream) {
  console.log(chunk.text); // Process chunks as they arrive
}
```

## Configuration Options

### Transcription Model Options

```typescript
providerOptions: {
  elevenlabs: {
    languageCode: 'en',              // ISO 639-1 language code
    tagAudioEvents: true,            // Label non-speech sounds
    numSpeakers: 2,                  // Max speakers (1-32)
    timestampsGranularity: 'word',   // 'none' | 'word' | 'character'
    diarize: true,                   // Enable speaker identification
    fileFormat: 'pcm_s16le_16',      // Audio format hint
  }
}
```

### Supported Audio Formats

- MP3, WAV, FLAC, M4A, OGG
- PCM (16-bit, 16kHz mono recommended)
- Base64-encoded audio strings
- Buffer, Uint8Array, ArrayBuffer
- URL objects (for remote audio)

### Language Support

ElevenLabs scribe_v1 supports 30+ languages:
- English (en), Spanish (es), French (fr), German (de)
- Chinese (zh), Japanese (ja), Korean (ko)
- And many more via ISO 639-1 codes

## Error Handling

```typescript
try {
  const { text } = await transcribe({
    model: elevenlabs.transcription('scribe_v1')
    audio: audioFile
  });
} catch (error) {
  if (error.name === 'AI_NoTranscriptGeneratedError') {
    console.error('Transcription failed:', error.message);
    console.error('Model response:', error.response);
  }
  throw error;
}
```

## Performance Considerations

### Best Practices

1. **Audio Quality**: Use 16kHz mono PCM for optimal results
2. **File Size**: Keep audio files under 100MB for faster processing
3. **Language Hints**: Provide languageCode for better accuracy
4. **Speaker Count**: Specify numSpeakers for diarization efficiency
5. **Streaming**: Use streaming for long audio files (>5 minutes)

### Benchmarking

```bash
# Run performance tests
bash scripts/benchmark-transcription.sh /path/to/test-audio/
```

## Testing

```bash
# Test basic transcription
bash scripts/test-transcription.sh audio.mp3

# Validate complete integration
bash scripts/validate-integration.sh

# Run benchmarks
bash scripts/benchmark-transcription.sh test-files/
```

## Troubleshooting

### API Key Issues

```bash
# Check API key is set
echo $ELEVENLABS_API_KEY

# Test API key validity
bash scripts/test-transcription.sh --validate-key
```

### Audio Format Issues

```bash
# Convert audio to supported format
ffmpeg -i input.wav -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```

### Next.js API Route Issues

- Ensure file size limits are configured in next.config.js
- Check bodyParser settings for API routes
- Verify CORS headers for client-side uploads

## Production Deployment

### Environment Variables

```bash
# Required
ELEVENLABS_API_KEY=sk_...

# Optional
NEXT_PUBLIC_MAX_FILE_SIZE=10485760  # 10MB
TRANSCRIPTION_TIMEOUT=60000          # 60 seconds
```

### Next.js Configuration

```javascript
// next.config.js
module.exports = {
  api: {
    bodyParser: {
      sizeLimit: '10mb'
    }
  }
};
```

### Edge Runtime Support

The @ai-sdk/elevenlabs provider works with Next.js Edge Runtime:

```typescript
export const runtime = 'edge';

export async function POST(request: Request) {
  // Transcription logic here
}
```

## References

- [@ai-sdk/elevenlabs Documentation](https://ai-sdk.dev/providers/ai-sdk-providers/elevenlabs)
- [Vercel AI SDK Transcription API](https://ai-sdk.dev/docs/ai-sdk-core/transcription)
- [ElevenLabs Speech-to-Text Cookbook](https://elevenlabs.io/docs/cookbooks/speech-to-text/vercel-ai-sdk)
- [Next.js API Routes](https://nextjs.org/docs/app/building-your-application/routing/route-handlers)

## Examples Directory Structure

```
examples/
├── nextjs-transcription/       # Basic Next.js transcription app
│   ├── app/
│   ├── package.json
│   └── README.md
├── multi-modal-chat/           # Voice + text chat
│   ├── app/
│   ├── components/
│   └── README.md
├── voice-workflow/             # Complete voice pipeline
│   ├── app/
│   ├── lib/
│   └── README.md
├── streaming-example/          # Real-time streaming
│   └── README.md
└── speaker-detection/          # Multi-speaker demo
    └── README.md
```

---

**Generated from**: plugins/elevenlabs/skills/vercel-ai-patterns/
**Version**: 1.0.0
