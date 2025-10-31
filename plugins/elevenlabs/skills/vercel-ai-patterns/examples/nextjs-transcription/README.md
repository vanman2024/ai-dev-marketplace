# Next.js Transcription Example

Complete Next.js 15 application demonstrating ElevenLabs transcription via Vercel AI SDK.

## Features

- File upload interface with drag-and-drop
- Real-time transcription progress
- Display results with metadata
- Support for multiple audio formats
- Error handling and validation
- TypeScript throughout

## Project Structure

```
nextjs-transcription/
├── app/
│   ├── api/
│   │   └── transcribe/
│   │       └── route.ts          # API route for transcription
│   ├── page.tsx                  # Main page with upload UI
│   ├── layout.tsx                # Root layout
│   └── globals.css               # Global styles
├── components/
│   ├── AudioUploader.tsx         # File upload component
│   └── TranscriptionResult.tsx   # Results display component
├── lib/
│   └── utils.ts                  # Utility functions
├── package.json
├── tsconfig.json
└── next.config.js
```

## Setup

### 1. Create Next.js App

```bash
npx create-next-app@latest nextjs-transcription --typescript --tailwind --app
cd nextjs-transcription
```

### 2. Install Dependencies

```bash
npm install @ai-sdk/elevenlabs ai
```

### 3. Configure Environment

Create `.env.local`:

```bash
ELEVENLABS_API_KEY=your_elevenlabs_api_key_here
```

### 4. Create API Route

Copy the API route template:

```bash
mkdir -p app/api/transcribe
cp ../../templates/api-route.ts.template app/api/transcribe/route.ts
```

### 5. Create Upload Component

Create `components/AudioUploader.tsx`:

```typescript
'use client';

import { useState } from 'react';

export default function AudioUploader({
  onTranscribe
}: {
  onTranscribe: (file: File) => Promise<void>;
}) {
  const [isDragging, setIsDragging] = useState(false);

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);

    const file = e.dataTransfer.files[0];
    if (file && file.type.startsWith('audio/')) {
      onTranscribe(file);
    }
  };

  return (
    <div
      onDragOver={(e) => {
        e.preventDefault();
        setIsDragging(true);
      }}
      onDragLeave={() => setIsDragging(false)}
      onDrop={handleDrop}
      className={`border-2 border-dashed rounded-lg p-8 text-center ${
        isDragging ? 'border-blue-500 bg-blue-50' : 'border-gray-300'
      }`}
    >
      <input
        type="file"
        accept="audio/*"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) onTranscribe(file);
        }}
        className="hidden"
        id="audio-upload"
      />
      <label htmlFor="audio-upload" className="cursor-pointer">
        <p className="text-lg mb-2">Drop audio file here or click to upload</p>
        <p className="text-sm text-gray-500">
          Supports MP3, WAV, M4A, FLAC, OGG (max 100MB)
        </p>
      </label>
    </div>
  );
}
```

### 6. Create Main Page

Create `app/page.tsx`:

```typescript
'use client';

import { useState } from 'react';
import AudioUploader from '@/components/AudioUploader';

interface TranscriptionResult {
  text: string;
  language?: string;
  durationInSeconds?: number;
  metadata?: {
    fileName: string;
    processingTimeMs: number;
  };
}

export default function Home() {
  const [result, setResult] = useState<TranscriptionResult | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleTranscribe = async (file: File) => {
    setIsLoading(true);
    setError(null);
    setResult(null);

    try {
      const formData = new FormData();
      formData.append('audio', file);

      const response = await fetch('/api/transcribe', {
        method: 'POST'
        body: formData
      });

      if (!response.ok) {
        throw new Error('Transcription failed');
      }

      const data = await response.json();
      setResult(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="container mx-auto p-8 max-w-4xl">
      <h1 className="text-3xl font-bold mb-8">Audio Transcription</h1>

      <AudioUploader onTranscribe={handleTranscribe} />

      {isLoading && (
        <div className="mt-8 p-4 bg-blue-50 rounded-lg">
          <p>Transcribing audio...</p>
        </div>
      )}

      {error && (
        <div className="mt-8 p-4 bg-red-50 text-red-900 rounded-lg">
          <p>Error: {error}</p>
        </div>
      )}

      {result && (
        <div className="mt-8 space-y-4">
          <div className="p-4 bg-gray-50 rounded-lg">
            <h2 className="font-bold mb-2">Transcription</h2>
            <p className="whitespace-pre-wrap">{result.text}</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600">Language</p>
              <p className="font-mono">{result.language || 'N/A'}</p>
            </div>
            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600">Duration</p>
              <p className="font-mono">
                {result.durationInSeconds?.toFixed(1)}s
              </p>
            </div>
            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600">Processing Time</p>
              <p className="font-mono">
                {result.metadata?.processingTimeMs}ms
              </p>
            </div>
            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600">File Name</p>
              <p className="font-mono text-sm">
                {result.metadata?.fileName}
              </p>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
```

## Running the App

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Usage

1. Click the upload area or drag-and-drop an audio file
2. Wait for transcription to complete
3. View the transcribed text and metadata

## Customization

### Add Language Selection

```typescript
const [language, setLanguage] = useState('en');

// In handleTranscribe:
formData.append('language', language);
```

### Add Speaker Diarization

```typescript
formData.append('speakers', '2');
formData.append('diarize', 'true');
```

### Export Results

```typescript
const exportTranscript = () => {
  const blob = new Blob([result.text], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'transcript.txt';
  a.click();
};
```

## Testing

Test with sample audio files:

```bash
curl -X POST http://localhost:3000/api/transcribe \
  -F 'audio=@sample-audio.mp3'
```

## Deployment

Deploy to Vercel:

```bash
vercel
```

Ensure `ELEVENLABS_API_KEY` is set in Vercel environment variables.

## Troubleshooting

### Large Files Timing Out

Increase timeout in `next.config.js`:

```javascript
module.exports = {
  api: {
    responseLimit: false
    bodyParser: {
      sizeLimit: '100mb'
    }
  }
  serverComponentsExternalPackages: ['@ai-sdk/elevenlabs']
};
```

### CORS Issues

Add CORS headers in API route:

```typescript
export async function OPTIONS() {
  return new NextResponse(null, {
    headers: {
      'Access-Control-Allow-Origin': '*'
      'Access-Control-Allow-Methods': 'POST, OPTIONS'
    }
  });
}
```

## Learn More

- [Next.js Documentation](https://nextjs.org/docs)
- [Vercel AI SDK](https://ai-sdk.dev)
- [ElevenLabs API](https://elevenlabs.io/docs)
