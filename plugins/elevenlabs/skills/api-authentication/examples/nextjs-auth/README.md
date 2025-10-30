# Next.js ElevenLabs Authentication Example

Complete example of ElevenLabs authentication in a Next.js application using Server Actions and API Routes.

## Project Structure

```
my-nextjs-app/
├── .env.local                    # Environment variables (never commit!)
├── src/
│   ├── lib/
│   │   └── elevenlabs.ts        # ElevenLabs client
│   ├── app/
│   │   ├── api/
│   │   │   └── tts/
│   │   │       └── route.ts     # API route for text-to-speech
│   │   └── page.tsx             # Main page with TTS form
│   └── actions/
│       └── tts.ts               # Server actions for TTS
└── package.json
```

## Setup Instructions

### 1. Install Dependencies

```bash
npm install elevenlabs dotenv
```

### 2. Configure Environment Variables

Create `.env.local`:

```env
ELEVENLABS_API_KEY=sk_your_api_key_here
ELEVENLABS_DEFAULT_VOICE_ID=21m00Tcm4TlvDq8ikWAM
ELEVENLABS_DEFAULT_MODEL_ID=eleven_monolingual_v1
```

### 3. Create ElevenLabs Client

Copy the Next.js template:

```bash
bash scripts/generate-client.sh typescript src/lib/elevenlabs.ts
```

Or manually create `src/lib/elevenlabs.ts`:

```typescript
'use server';

import { ElevenLabsClient } from 'elevenlabs';
import { cache } from 'react';

export const createElevenLabsClient = cache((): ElevenLabsClient => {
  const apiKey = process.env.ELEVENLABS_API_KEY;

  if (!apiKey) {
    throw new Error('ELEVENLABS_API_KEY not set in .env.local');
  }

  return new ElevenLabsClient({ apiKey });
});

export async function generateSpeech(text: string, voiceId?: string): Promise<Buffer> {
  const client = createElevenLabsClient();
  const voice = voiceId || process.env.ELEVENLABS_DEFAULT_VOICE_ID!;

  const audio = await client.generate({
    voice,
    text,
    model_id: process.env.ELEVENLABS_DEFAULT_MODEL_ID || 'eleven_monolingual_v1',
  });

  const chunks: Uint8Array[] = [];
  for await (const chunk of audio) {
    chunks.push(chunk);
  }

  return Buffer.concat(chunks);
}
```

### 4. Create Server Action

Create `src/actions/tts.ts`:

```typescript
'use server';

import { generateSpeech } from '@/lib/elevenlabs';

export async function textToSpeechAction(text: string, voiceId?: string) {
  try {
    const audio = await generateSpeech(text, voiceId);
    return {
      success: true,
      audio: audio.toString('base64'),
    };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}
```

### 5. Create API Route

Create `src/app/api/tts/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { generateSpeech } from '@/lib/elevenlabs';

export async function POST(request: NextRequest) {
  try {
    const { text, voiceId } = await request.json();

    if (!text) {
      return NextResponse.json(
        { error: 'Text is required' },
        { status: 400 }
      );
    }

    const audio = await generateSpeech(text, voiceId);

    return new NextResponse(audio, {
      headers: {
        'Content-Type': 'audio/mpeg',
        'Content-Disposition': 'attachment; filename=speech.mp3',
      },
    });
  } catch (error) {
    console.error('TTS error:', error);
    return NextResponse.json(
      { error: 'Text-to-speech generation failed' },
      { status: 500 }
    );
  }
}
```

### 6. Create UI Component

Create `src/app/page.tsx`:

```typescript
'use client';

import { useState } from 'react';
import { textToSpeechAction } from '@/actions/tts';

export default function Home() {
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const result = await textToSpeechAction(text);

      if (result.success && result.audio) {
        // Convert base64 to audio blob
        const audioBlob = new Blob(
          [Uint8Array.from(atob(result.audio), c => c.charCodeAt(0))],
          { type: 'audio/mpeg' }
        );

        // Create download link
        const url = URL.createObjectURL(audioBlob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'speech.mp3';
        a.click();
        URL.revokeObjectURL(url);
      } else {
        setError(result.error || 'Unknown error');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold mb-4">ElevenLabs Text-to-Speech</h1>

      <form onSubmit={handleSubmit} className="max-w-md">
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Enter text to convert to speech..."
          className="w-full p-2 border rounded mb-4"
          rows={4}
        />

        <button
          type="submit"
          disabled={loading || !text}
          className="px-4 py-2 bg-blue-500 text-white rounded disabled:bg-gray-300"
        >
          {loading ? 'Generating...' : 'Generate Speech'}
        </button>

        {error && (
          <p className="text-red-500 mt-4">{error}</p>
        )}
      </form>
    </main>
  );
}
```

## Usage Patterns

### Pattern 1: Server Action (Recommended)

Best for forms and user interactions:

```typescript
'use client';

import { textToSpeechAction } from '@/actions/tts';

export function TTSForm() {
  async function handleSubmit(formData: FormData) {
    const text = formData.get('text') as string;
    const result = await textToSpeechAction(text);
    // Handle result...
  }

  return (
    <form action={handleSubmit}>
      <input name="text" />
      <button type="submit">Generate</button>
    </form>
  );
}
```

### Pattern 2: API Route

Best for external API calls:

```typescript
// Client-side fetch
const response = await fetch('/api/tts', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ text: 'Hello world!' }),
});

const blob = await response.blob();
const url = URL.createObjectURL(blob);
// Play or download audio
```

### Pattern 3: Server Component

Best for pre-rendered content:

```typescript
import { generateSpeech } from '@/lib/elevenlabs';

export default async function Page() {
  const audio = await generateSpeech('Welcome message');

  return (
    <div>
      <audio controls src={`data:audio/mpeg;base64,${audio.toString('base64')}`} />
    </div>
  );
}
```

## Error Handling

```typescript
try {
  const audio = await generateSpeech(text);
} catch (error) {
  if (error instanceof Error) {
    if (error.message.includes('401')) {
      // Invalid API key
    } else if (error.message.includes('429')) {
      // Rate limit exceeded
    } else {
      // Other errors
    }
  }
}
```

## Testing

Test your setup:

```bash
# Test connection
curl http://localhost:3000/api/tts \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello world!"}' \
  --output test.mp3
```

## Security Best Practices

1. **Never expose API keys in client code**
   - Use Server Actions or API Routes
   - Keep API key in `.env.local` (server-side only)

2. **Add rate limiting**
   ```typescript
   import rateLimit from 'express-rate-limit';

   const limiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 100, // limit each IP to 100 requests per windowMs
   });
   ```

3. **Validate input**
   ```typescript
   if (!text || text.length > 5000) {
     throw new Error('Text must be 1-5000 characters');
   }
   ```

4. **Add authentication**
   ```typescript
   import { auth } from '@/lib/auth';

   export async function textToSpeechAction(text: string) {
     const session = await auth();
     if (!session) {
       throw new Error('Unauthorized');
     }
     // Generate speech...
   }
   ```

## Next Steps

1. Add voice selection UI
2. Implement audio player component
3. Add caching for generated audio
4. Implement usage tracking
5. Add webhook for long-form content

## References

- [Next.js Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
- [ElevenLabs API Docs](https://elevenlabs.io/docs)
- [Next.js API Routes](https://nextjs.org/docs/app/building-your-application/routing/route-handlers)
