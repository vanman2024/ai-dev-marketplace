# Vercel AI SDK STT Integration Example

This example demonstrates how to integrate ElevenLabs STT with the Vercel AI SDK for TypeScript/JavaScript applications.

## Installation

```bash
# Install dependencies
npm install ai @ai-sdk/elevenlabs

# Or use the setup script
bash ../../scripts/setup-vercel-ai.sh
```

## Environment Setup

Create `.env.local`:

```bash
ELEVENLABS_API_KEY=your_api_key_here
```

## Basic Usage

### Simple Transcription

```typescript
import { elevenlabs } from '@ai-sdk/elevenlabs';
import { experimental_transcribe as transcribe } from 'ai';
import { readFile } from 'fs/promises';

const audioBuffer = await readFile('./audio.mp3');
const audioData = new Uint8Array(audioBuffer);

const result = await transcribe({
  model: elevenlabs.transcription('scribe_v1')
  audio: audioData
  providerOptions: {
    elevenlabs: {
      languageCode: 'en'
    }
  }
});

console.log(result.text);
```

### With Speaker Diarization

```typescript
const result = await transcribe({
  model: elevenlabs.transcription('scribe_v1')
  audio: audioData
  providerOptions: {
    elevenlabs: {
      languageCode: 'en'
      diarize: true
      numSpeakers: 2
    }
  }
});

// Format with speaker labels
const formatted = result.segments
  .filter(s => s.speaker)
  .map(s => `[${s.speaker}]: ${s.text}`)
  .join('\n');

console.log(formatted);
```

## Using the Template

The template provides a complete implementation with helper functions:

```typescript
import {
  transcribeAudio
  formatTranscriptWithSpeakers
  formatTimestamped
  extractSpeakerSegments
} from '../../templates/vercel-ai-transcribe.ts.template';

// Basic transcription
const result = await transcribeAudio({
  audioPath: './interview.mp3'
  languageCode: 'en'
  diarize: true
  numSpeakers: 2
});

// Format for display
console.log(formatTranscriptWithSpeakers(result));
console.log(formatTimestamped(result));

// Extract speaker segments
const speakers = extractSpeakerSegments(result);
speakers.forEach(segment => {
  console.log(`${segment.speaker} (${segment.startTime}s - ${segment.endTime}s):`);
  console.log(segment.text);
});
```

## Advanced Features

### Batch Processing

```typescript
import { transcribeBatch } from '../../templates/vercel-ai-transcribe.ts.template';

const audioPaths = [
  './audio/file1.mp3'
  './audio/file2.mp3'
  './audio/file3.mp3'
];

const results = await transcribeBatch(audioPaths, {
  languageCode: 'en'
  diarize: true
});

results.forEach((result, index) => {
  console.log(`File ${index + 1}:`, result.text);
});
```

### Progress Tracking

```typescript
import { transcribeWithProgress } from '../../templates/vercel-ai-transcribe.ts.template';

const result = await transcribeWithProgress(
  {
    audioPath: './long-audio.mp3'
    languageCode: 'en'
  }
  (progress) => {
    console.log(`Progress: ${Math.round(progress * 100)}%`);
  }
);
```

### Custom Configuration

```typescript
const result = await transcribe({
  model: elevenlabs.transcription('scribe_v1')
  audio: audioData
  providerOptions: {
    elevenlabs: {
      languageCode: 'en'
      diarize: true
      numSpeakers: 3
      tagAudioEvents: true
      timestampsGranularity: 'word'
      fileFormat: 'other', // or 'pcm_s16le_16' for lowest latency
    }
  }
});
```

## Integration Patterns

### Pattern 1: Real-time Audio Processing

```typescript
import { transcribeAudio } from '../../templates/vercel-ai-transcribe.ts.template';

async function processAudioUpload(file: File) {
  // Save uploaded file
  const buffer = await file.arrayBuffer();
  const tempPath = `/tmp/${file.name}`;
  await writeFile(tempPath, Buffer.from(buffer));

  // Transcribe
  const result = await transcribeAudio({
    audioPath: tempPath
    languageCode: 'en'
    diarize: true
  });

  // Clean up
  await unlink(tempPath);

  return result;
}
```

### Pattern 2: Next.js API Route

```typescript
// app/api/transcribe/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { transcribeAudio } from '@/lib/transcribe';

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const file = formData.get('audio') as File;
  const language = formData.get('language') as string;

  if (!file) {
    return NextResponse.json(
      { error: 'No audio file provided' }
      { status: 400 }
    );
  }

  try {
    const buffer = await file.arrayBuffer();
    const result = await transcribeAudio({
      audioBuffer: Buffer.from(buffer)
      languageCode: language || 'en'
      diarize: true
    });

    return NextResponse.json({
      text: result.text
      segments: result.segments
    });
  } catch (error) {
    console.error('Transcription error:', error);
    return NextResponse.json(
      { error: 'Transcription failed' }
      { status: 500 }
    );
  }
}
```

### Pattern 3: React Component

```typescript
'use client';

import { useState } from 'react';

export function AudioTranscriber() {
  const [transcription, setTranscription] = useState('');
  const [loading, setLoading] = useState(false);

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setLoading(true);

    const formData = new FormData();
    formData.append('audio', file);
    formData.append('language', 'en');

    try {
      const response = await fetch('/api/transcribe', {
        method: 'POST'
        body: formData
      });

      const data = await response.json();
      setTranscription(data.text);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <input
        type="file"
        accept="audio/*,video/*"
        onChange={handleFileUpload}
        disabled={loading}
      />
      {loading && <p>Transcribing...</p>}
      {transcription && (
        <div>
          <h3>Transcription:</h3>
          <p>{transcription}</p>
        </div>
      )}
    </div>
  );
}
```

## Provider Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `languageCode` | string | auto | ISO-639 language code |
| `diarize` | boolean | true | Enable speaker identification |
| `numSpeakers` | number | null | Number of speakers (1-32) |
| `tagAudioEvents` | boolean | true | Detect audio events |
| `timestampsGranularity` | string | 'word' | 'none', 'word', 'character' |
| `fileFormat` | string | 'other' | 'other' or 'pcm_s16le_16' |

## Error Handling

```typescript
import { transcribeAudio } from '../../templates/vercel-ai-transcribe.ts.template';

try {
  const result = await transcribeAudio({
    audioPath: './audio.mp3'
    languageCode: 'en'
  });

  if (result.success) {
    console.log('Success:', result.text);
  } else {
    console.error('Error:', result.error);
  }
} catch (error) {
  if (error instanceof Error) {
    if (error.message.includes('not found')) {
      console.error('Audio file not found');
    } else if (error.message.includes('API')) {
      console.error('API error - check your key');
    } else {
      console.error('Unexpected error:', error.message);
    }
  }
}
```

## Testing

```typescript
import { describe, it, expect } from 'vitest';
import { transcribeAudio } from '../../templates/vercel-ai-transcribe.ts.template';

describe('Audio Transcription', () => {
  it('should transcribe audio file', async () => {
    const result = await transcribeAudio({
      audioPath: './test/fixtures/sample.mp3'
      languageCode: 'en'
    });

    expect(result.success).toBe(true);
    expect(result.text).toBeTruthy();
  });

  it('should handle speaker diarization', async () => {
    const result = await transcribeAudio({
      audioPath: './test/fixtures/interview.mp3'
      languageCode: 'en'
      diarize: true
      numSpeakers: 2
    });

    const speakers = extractSpeakerSegments(result);
    expect(speakers.length).toBeGreaterThan(0);
  });
});
```

## Performance Optimization

### 1. Use Appropriate File Format

```typescript
// For lowest latency with uncompressed audio
const result = await transcribe({
  model: elevenlabs.transcription('scribe_v1')
  audio: pcmAudioData, // 16-bit PCM, 16kHz, mono
  providerOptions: {
    elevenlabs: {
      fileFormat: 'pcm_s16le_16'
    }
  }
});
```

### 2. Specify Language

```typescript
// Better performance than auto-detection
providerOptions: {
  elevenlabs: {
    languageCode: 'en', // Always specify when known
  }
}
```

### 3. Disable Unnecessary Features

```typescript
// For simple transcription without diarization
providerOptions: {
  elevenlabs: {
    diarize: false
    tagAudioEvents: false
    timestampsGranularity: 'none'
  }
}
```

## Troubleshooting

### API Key Not Found
```bash
# Set environment variable
export ELEVENLABS_API_KEY='your_key_here'

# Or in .env.local
ELEVENLABS_API_KEY=your_key_here
```

### Module Not Found
```bash
# Reinstall dependencies
npm install ai @ai-sdk/elevenlabs
```

### Type Errors
```bash
# Ensure TypeScript is configured
npm install -D typescript @types/node
```

## Next Steps

- [Speaker Diarization Example](../diarization/README.md)
- [Multi-Language Example](../multi-language/README.md)
- [Webhook Integration](../webhook-integration/README.md)

## Resources

- [Vercel AI SDK Documentation](https://ai-sdk.dev)
- [ElevenLabs Provider Docs](https://ai-sdk.dev/providers/ai-sdk-providers/elevenlabs)
- [ElevenLabs STT Cookbook](https://elevenlabs.io/docs/cookbooks/speech-to-text/vercel-ai-sdk)
