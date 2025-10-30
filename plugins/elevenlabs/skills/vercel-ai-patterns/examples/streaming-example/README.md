# Streaming Transcription Example

Real-time streaming transcription demonstration with progress tracking and incremental results.

## Overview

This example shows how to implement streaming transcription workflows, including:

- Chunk-based audio processing
- Real-time progress updates
- WebSocket-based streaming architecture
- Client-server communication patterns

**Note**: Current Vercel AI SDK `experimental_transcribe` processes complete audio files. This example demonstrates patterns for when true streaming becomes available, plus workarounds for simulating streaming behavior.

## Architecture Patterns

### Pattern 1: Simulated Streaming (Current)

Process complete audio but deliver results incrementally:

```
Audio File → Transcribe → Segment Results → Stream to Client
```

### Pattern 2: WebSocket Streaming (Future/Custom)

Real-time streaming as audio is captured:

```
Microphone → Chunks → WebSocket → Transcribe → Stream Results
```

## Setup

### 1. Install Dependencies

```bash
npm install @ai-sdk/elevenlabs ai ws @types/ws
```

### 2. Copy Templates

```bash
mkdir -p lib
cp ../../templates/streaming-transcription.ts.template lib/streaming.ts
```

## Example 1: Simulated Streaming

### Server Implementation

```typescript
import { streamingTranscribe } from './lib/streaming';
import { readFile } from 'fs/promises';

async function main() {
  const audioBuffer = await readFile('audio.mp3');

  const result = await streamingTranscribe(audioBuffer, {
    language: 'en',
    onProgress: (progress) => {
      console.log(`Progress: ${progress.toFixed(0)}%`);
    },
    onChunk: (text, isFinal) => {
      console.log(`Chunk [${isFinal ? 'FINAL' : 'PARTIAL'}]: ${text}`);
    },
    onComplete: (fullText) => {
      console.log('\nComplete transcription:', fullText);
    },
    onError: (error) => {
      console.error('Error:', error.message);
    },
  });

  console.log('Final result:', result);
}

main();
```

### Expected Output

```
Progress: 20%
Chunk [PARTIAL]: Hello, this is
Progress: 40%
Chunk [PARTIAL]: a test of the
Progress: 60%
Chunk [PARTIAL]: streaming transcription
Progress: 80%
Chunk [PARTIAL]: system.
Progress: 100%
Chunk [FINAL]: Thank you.

Complete transcription: Hello, this is a test of the streaming transcription system. Thank you.
```

## Example 2: WebSocket Server

### Create WebSocket Server

```typescript
import { WebSocketServer } from 'ws';
import { StreamingTranscriptionServer } from './lib/streaming';

const wss = new WebSocketServer({ port: 8080 });
const transcriptionServer = new StreamingTranscriptionServer();

wss.on('connection', (ws) => {
  console.log('Client connected');
  transcriptionServer.handleConnection(ws);
});

console.log('WebSocket server running on ws://localhost:8080');
```

### Run Server

```bash
npx tsx server.ts
```

## Example 3: WebSocket Client

### Browser Client

```typescript
import { StreamingTranscriptionClient } from './lib/streaming';

async function setupClient() {
  const client = new StreamingTranscriptionClient('ws://localhost:8080', {
    onChunk: (chunk) => {
      console.log('Received chunk:', chunk.text);
      // Update UI with chunk
      appendToTranscript(chunk.text);
    },
    onComplete: (text) => {
      console.log('Complete:', text);
      // Finalize UI
      markTranscriptComplete();
    },
    onError: (error) => {
      console.error('Error:', error.message);
      showError(error.message);
    },
  });

  await client.connect();
  return client;
}

// Usage
const client = await setupClient();

// Send audio file
const audioFile = document.getElementById('audio-input').files[0];
await client.sendAudio(audioFile);
```

### React Component

```typescript
'use client';

import { useStreamingTranscription } from './lib/streaming';
import { useState } from 'react';

export default function StreamingDemo() {
  const { isConnected, isProcessing, chunks, fullText, error, connect, sendAudio, disconnect } =
    useStreamingTranscription();

  const [wsUrl] = useState('ws://localhost:8080');

  const handleConnect = async () => {
    await connect(wsUrl);
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      await sendAudio(file);
    }
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Streaming Transcription Demo</h1>

      <div className="space-y-4">
        {/* Connection */}
        <div>
          <button
            onClick={isConnected ? disconnect : handleConnect}
            className={`px-4 py-2 rounded ${
              isConnected ? 'bg-red-500' : 'bg-green-500'
            } text-white`}
          >
            {isConnected ? 'Disconnect' : 'Connect'}
          </button>
          <span className="ml-2">
            {isConnected ? '🟢 Connected' : '🔴 Disconnected'}
          </span>
        </div>

        {/* Upload */}
        {isConnected && (
          <div>
            <input
              type="file"
              accept="audio/*"
              onChange={handleFileUpload}
              disabled={isProcessing}
              className="block w-full text-sm"
            />
          </div>
        )}

        {/* Processing indicator */}
        {isProcessing && <div className="text-blue-600">Processing audio...</div>}

        {/* Error */}
        {error && <div className="text-red-600 p-4 bg-red-50 rounded">{error}</div>}

        {/* Streaming chunks */}
        {chunks.length > 0 && (
          <div className="border rounded p-4 bg-gray-50">
            <h2 className="font-bold mb-2">Streaming Results:</h2>
            <div className="space-y-2">
              {chunks.map((chunk, i) => (
                <div
                  key={i}
                  className={`p-2 rounded ${
                    chunk.isFinal ? 'bg-green-100' : 'bg-yellow-50'
                  }`}
                >
                  <span className="text-xs text-gray-500">
                    [{chunk.timestamp.toFixed(2)}s]
                  </span>{' '}
                  {chunk.text}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Final result */}
        {fullText && (
          <div className="border-2 border-green-500 rounded p-4 bg-green-50">
            <h2 className="font-bold mb-2">Complete Transcription:</h2>
            <p className="whitespace-pre-wrap">{fullText}</p>
          </div>
        )}
      </div>
    </div>
  );
}
```

## Example 4: Progress Tracking

### With Progress Bar

```typescript
import { useState } from 'react';

export function ProgressTracker() {
  const [progress, setProgress] = useState(0);
  const [status, setStatus] = useState('');

  const handleTranscribe = async (file: File) => {
    setProgress(0);
    setStatus('Starting...');

    const audioBuffer = Buffer.from(await file.arrayBuffer());

    await streamingTranscribe(audioBuffer, {
      onProgress: (p) => {
        setProgress(p);
        setStatus(`Processing: ${p.toFixed(0)}%`);
      },
      onComplete: (text) => {
        setProgress(100);
        setStatus('Complete!');
      },
    });
  };

  return (
    <div>
      <div className="w-full bg-gray-200 rounded h-4">
        <div
          className="bg-blue-500 h-4 rounded transition-all"
          style={{ width: `${progress}%` }}
        />
      </div>
      <p className="text-sm mt-2">{status}</p>
    </div>
  );
}
```

## Example 5: Chunk Visualization

### Live Transcript Display

```typescript
export function LiveTranscript() {
  const [chunks, setChunks] = useState<string[]>([]);

  const handleTranscribe = async (file: File) => {
    setChunks([]);

    const audioBuffer = Buffer.from(await file.arrayBuffer());

    await streamingTranscribe(audioBuffer, {
      onChunk: (text, isFinal) => {
        setChunks((prev) => [...prev, text]);

        // Auto-scroll to bottom
        setTimeout(() => {
          const element = document.getElementById('transcript-container');
          element?.scrollTo({
            top: element.scrollHeight,
            behavior: 'smooth',
          });
        }, 100);
      },
    });
  };

  return (
    <div
      id="transcript-container"
      className="h-96 overflow-y-auto border rounded p-4 bg-gray-50"
    >
      {chunks.map((chunk, i) => (
        <span key={i} className="mr-1">
          {chunk}
        </span>
      ))}
    </div>
  );
}
```

## Next.js API Route

### Streaming API Endpoint

```typescript
// app/api/transcribe-stream/route.ts
import { streamingTranscribe } from '@/lib/streaming';
import { NextRequest } from 'next/server';

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const audioFile = formData.get('audio') as File;

  if (!audioFile) {
    return new Response('No audio file', { status: 400 });
  }

  const audioBuffer = Buffer.from(await audioFile.arrayBuffer());

  // Create a ReadableStream
  const stream = new ReadableStream({
    async start(controller) {
      await streamingTranscribe(audioBuffer, {
        onChunk: (text, isFinal) => {
          const chunk = JSON.stringify({ type: 'chunk', text, isFinal });
          controller.enqueue(new TextEncoder().encode(chunk + '\n'));
        },
        onComplete: (fullText) => {
          const chunk = JSON.stringify({ type: 'complete', text: fullText });
          controller.enqueue(new TextEncoder().encode(chunk + '\n'));
          controller.close();
        },
        onError: (error) => {
          const chunk = JSON.stringify({ type: 'error', message: error.message });
          controller.enqueue(new TextEncoder().encode(chunk + '\n'));
          controller.close();
        },
      });
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  });
}
```

### Client-Side Consumer

```typescript
async function consumeStream(file: File) {
  const formData = new FormData();
  formData.append('audio', file);

  const response = await fetch('/api/transcribe-stream', {
    method: 'POST',
    body: formData,
  });

  const reader = response.body?.getReader();
  const decoder = new TextDecoder();

  if (!reader) return;

  while (true) {
    const { done, value } = await reader.read();

    if (done) break;

    const text = decoder.decode(value);
    const lines = text.split('\n').filter((line) => line.trim());

    for (const line of lines) {
      try {
        const data = JSON.parse(line);

        switch (data.type) {
          case 'chunk':
            console.log('Chunk:', data.text);
            break;
          case 'complete':
            console.log('Complete:', data.text);
            break;
          case 'error':
            console.error('Error:', data.message);
            break;
        }
      } catch (e) {
        console.error('Parse error:', e);
      }
    }
  }
}
```

## Performance Considerations

### Chunk Size Optimization

```typescript
// Smaller chunks = more frequent updates, higher overhead
// Larger chunks = less frequent updates, lower overhead

await streamingTranscribe(audioBuffer, {
  chunkSizeMs: 1000, // 1 second chunks
  onChunk: (text) => {
    // Process chunk
  },
});
```

### Connection Pooling

```typescript
// Reuse WebSocket connections
const connectionPool = new Map<string, StreamingTranscriptionClient>();

function getConnection(url: string) {
  if (!connectionPool.has(url)) {
    const client = new StreamingTranscriptionClient(url);
    connectionPool.set(url, client);
  }
  return connectionPool.get(url)!;
}
```

## Troubleshooting

### WebSocket Connection Fails

- Check firewall settings
- Verify WebSocket server is running
- Use `wss://` for HTTPS sites

### Chunks Not Appearing

- Verify `onChunk` callback is registered
- Check for errors in console
- Ensure audio has segments data

### Performance Issues

- Reduce chunk frequency
- Use connection pooling
- Implement client-side buffering

## Learn More

- [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)
- [Streams API](https://developer.mozilla.org/en-US/docs/Web/API/Streams_API)
- [Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
