# Voice Workflow Example

Complete end-to-end voice processing pipeline: Record → Transcribe → Process → Respond.

## Overview

This example demonstrates a production-ready voice workflow that combines:

1. **Voice Input** - Record or upload audio
2. **Transcription** - ElevenLabs speech-to-text
3. **LLM Processing** - Intelligent response generation
4. **Context Management** - Maintain conversation state

## Architecture

```
┌─────────────────┐
│  Voice Input    │
│  (Recording)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  ElevenLabs     │
│  Transcription  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Context        │
│  Enrichment     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  LLM            │
│  Processing     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Response       │
│  Generation     │
└─────────────────┘
```

## Setup

### 1. Create Project

```bash
mkdir voice-workflow
cd voice-workflow
npm init -y
npm install typescript @types/node tsx
npx tsc --init
```

### 2. Install Dependencies

```bash
npm install @ai-sdk/elevenlabs @ai-sdk/openai ai
npm install -D @types/node
```

### 3. Environment Variables

Create `.env`:

```bash
ELEVENLABS_API_KEY=your_elevenlabs_api_key
OPENAI_API_KEY=your_openai_api_key
```

### 4. Copy Workflow Template

```bash
mkdir -p lib
cp ../../templates/voice-workflow.ts.template lib/voice-workflow.ts
```

## Usage

### Basic Voice Processing

```typescript
import { processVoiceInput } from './lib/voice-workflow';
import { readFile } from 'fs/promises';

async function main() {
  // Read audio file
  const audioBuffer = await readFile('audio.mp3');

  // Process voice input
  const result = await processVoiceInput(audioBuffer, {
    language: 'en',
    systemPrompt: 'You are a helpful voice assistant.',
    temperature: 0.7,
  });

  if (result.success) {
    console.log('Transcription:', result.transcription.text);
    console.log('Response:', result.response.text);
    console.log('Time:', result.metadata.totalTimeMs, 'ms');
  } else {
    console.error('Error:', result.error);
  }
}

main();
```

### With Conversation Context

```typescript
const conversationHistory = [
  { role: 'user', content: 'What is the weather?' },
  { role: 'assistant', content: 'It is sunny today.' },
];

const result = await processVoiceInput(audioBuffer, {
  context: conversationHistory,
  systemPrompt: 'You are a weather assistant.',
});
```

### Streaming Responses

```typescript
import { processVoiceInputStreaming } from './lib/voice-workflow';

async function streamingExample() {
  const audioBuffer = await readFile('audio.mp3');

  const stream = await processVoiceInputStreaming(audioBuffer, {
    onTranscriptionComplete: (text) => {
      console.log('User said:', text);
    },
    onResponseChunk: (chunk) => {
      process.stdout.write(chunk);
    },
  });

  // Stream will automatically yield chunks
  for await (const chunk of stream) {
    // Process chunk
  }

  // Get final result
  const result = await stream.return(undefined);
  console.log('\nTotal time:', result.value.metadata.totalTimeMs, 'ms');
}
```

### Batch Processing

```typescript
import { batchProcessVoiceInputs } from './lib/voice-workflow';

async function batchExample() {
  const audioFiles = [
    await readFile('audio1.mp3'),
    await readFile('audio2.mp3'),
    await readFile('audio3.mp3'),
  ];

  const results = await batchProcessVoiceInputs(audioFiles, {
    language: 'en',
    systemPrompt: 'You are a helpful assistant.',
  });

  results.forEach((result, i) => {
    console.log(`File ${i + 1}:`, result.transcription.text);
  });
}
```

### With Retry Logic

```typescript
import { processVoiceInputWithRetry } from './lib/voice-workflow';

async function retryExample() {
  const result = await processVoiceInputWithRetry(
    audioBuffer,
    {
      language: 'en',
      systemPrompt: 'You are a helpful assistant.',
    },
    3 // Max retries
  );

  if (result.success) {
    console.log('Success after retries:', result.response.text);
  }
}
```

## Advanced Use Cases

### Voice Assistant with Memory

```typescript
class VoiceAssistant {
  private conversationHistory: Array<{
    role: 'user' | 'assistant';
    content: string;
  }> = [];

  async processVoice(audioBuffer: Buffer): Promise<string> {
    const result = await processVoiceInput(audioBuffer, {
      context: this.conversationHistory,
      systemPrompt: 'You are a helpful voice assistant with memory.',
      onTranscriptionComplete: (text) => {
        this.conversationHistory.push({ role: 'user', content: text });
      },
    });

    if (result.success) {
      this.conversationHistory.push({
        role: 'assistant',
        content: result.response.text,
      });
      return result.response.text;
    }

    throw new Error(result.error);
  }

  clearHistory() {
    this.conversationHistory = [];
  }
}

// Usage
const assistant = new VoiceAssistant();
const response1 = await assistant.processVoice(audio1);
const response2 = await assistant.processVoice(audio2); // Has context from audio1
```

### Multi-Language Support

```typescript
async function detectAndProcess(audioBuffer: Buffer) {
  // First transcribe without language hint
  const initialResult = await processVoiceInput(audioBuffer, {
    systemPrompt: 'Detect the language and respond in the same language.',
  });

  const detectedLanguage = initialResult.transcription.language;

  // Re-process with detected language for better accuracy
  const finalResult = await processVoiceInput(audioBuffer, {
    language: detectedLanguage,
    systemPrompt: `Respond in ${detectedLanguage}.`,
  });

  return finalResult;
}
```

### Voice Commands Handler

```typescript
const COMMANDS = {
  weather: /what('?s| is) the weather/i,
  time: /what('?s| is) the time/i,
  reminder: /remind me to (.+)/i,
};

async function handleVoiceCommand(audioBuffer: Buffer) {
  const result = await processVoiceInput(audioBuffer, {
    systemPrompt: 'Extract user intent and respond appropriately.',
  });

  const userText = result.transcription.text;

  // Check for specific commands
  for (const [command, pattern] of Object.entries(COMMANDS)) {
    if (pattern.test(userText)) {
      console.log(`Detected command: ${command}`);
      // Handle specific command
    }
  }

  return result.response.text;
}
```

### Meeting Transcription and Summary

```typescript
async function processMeeting(audioBuffer: Buffer) {
  const result = await processVoiceInput(audioBuffer, {
    speakers: 3,
    enableDiarization: true,
    enableTimestamps: true,
    systemPrompt: `
      Summarize the meeting with:
      1. Key discussion points
      2. Action items
      3. Decisions made
    `,
  });

  return {
    transcript: result.transcription.text,
    summary: result.response.text,
    speakers: result.transcription.segments,
  };
}
```

## Next.js Integration

### Create API Route

Create `app/api/voice-workflow/route.ts`:

```typescript
import { processVoiceInput } from '@/lib/voice-workflow';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const audioFile = formData.get('audio') as File;
    const systemPrompt = formData.get('systemPrompt') as string;
    const context = JSON.parse(
      (formData.get('context') as string) || '[]'
    );

    const audioBuffer = Buffer.from(await audioFile.arrayBuffer());

    const result = await processVoiceInput(audioBuffer, {
      systemPrompt,
      context,
      language: 'en',
    });

    return NextResponse.json(result);
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
```

### Client-Side Usage

```typescript
async function sendVoiceMessage(audioFile: File) {
  const formData = new FormData();
  formData.append('audio', audioFile);
  formData.append('systemPrompt', 'You are a helpful assistant.');
  formData.append('context', JSON.stringify(conversationHistory));

  const response = await fetch('/api/voice-workflow', {
    method: 'POST',
    body: formData,
  });

  const result = await response.json();
  return result;
}
```

## Performance Optimization

### Parallel Processing

```typescript
async function parallelProcess(audioFiles: Buffer[]) {
  const results = await Promise.all(
    audioFiles.map((audio) =>
      processVoiceInput(audio, {
        systemPrompt: 'You are a helpful assistant.',
      })
    )
  );

  return results;
}
```

### Caching Results

```typescript
import { createHash } from 'crypto';

const cache = new Map<string, any>();

async function cachedProcess(audioBuffer: Buffer) {
  const hash = createHash('sha256').update(audioBuffer).digest('hex');

  if (cache.has(hash)) {
    return cache.get(hash);
  }

  const result = await processVoiceInput(audioBuffer, {
    systemPrompt: 'You are a helpful assistant.',
  });

  cache.set(hash, result);
  return result;
}
```

## Testing

### Unit Tests

```typescript
import { describe, it, expect } from 'vitest';
import { processVoiceInput } from './voice-workflow';

describe('Voice Workflow', () => {
  it('processes audio successfully', async () => {
    const mockAudio = Buffer.from('mock audio data');
    const result = await processVoiceInput(mockAudio);
    expect(result.success).toBe(true);
  });

  it('handles errors gracefully', async () => {
    const invalidAudio = Buffer.from('');
    const result = await processVoiceInput(invalidAudio);
    expect(result.success).toBe(false);
    expect(result.error).toBeDefined();
  });
});
```

## Monitoring

### Add Logging

```typescript
import { Logger } from 'winston';

const logger = new Logger({
  // Winston config
});

const result = await processVoiceInput(audioBuffer, {
  onTranscriptionComplete: (text) => {
    logger.info('Transcription complete', { text });
  },
});

logger.info('Workflow complete', {
  transcriptionTime: result.metadata.transcriptionTimeMs,
  responseTime: result.metadata.responseTimeMs,
  totalTime: result.metadata.totalTimeMs,
});
```

## Learn More

- [Vercel AI SDK Documentation](https://ai-sdk.dev)
- [ElevenLabs API](https://elevenlabs.io/docs)
- [OpenAI API](https://platform.openai.com/docs)
