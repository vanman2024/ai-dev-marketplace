# Edge Runtime ElevenLabs Authentication Example

Examples for using ElevenLabs in edge runtime environments (Vercel Edge Functions, Cloudflare Workers, Deno Deploy).

## Overview

Edge runtimes have constraints:
- No Node.js APIs (no `Buffer`, `fs`, etc.)
- Limited execution time
- Optimized for streaming
- Global distribution

This guide shows how to work with these constraints.

## Vercel Edge Functions

### Setup

1. Install dependencies:
```bash
npm install elevenlabs
```

2. Configure environment variables in Vercel dashboard:
```
ELEVENLABS_API_KEY=sk_your_key_here
```

### Example: Edge API Route

Create `app/api/tts/route.ts`:

```typescript
import { streamSpeech } from '@/lib/elevenlabs-edge';

export const runtime = 'edge';

export async function POST(request: Request) {
  const { text, voiceId } = await request.json();

  if (!text) {
    return new Response(JSON.stringify({ error: 'Text required' }), {
      status: 400
      headers: { 'Content-Type': 'application/json' }
    });
  }

  try {
    // Stream audio directly to client
    return await streamSpeech(text, voiceId);
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Speech generation failed' })
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}
```

### Example: Middleware

Create `middleware.ts`:

```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export const config = {
  matcher: '/api/tts/:path*'
  runtime: 'edge'
};

export function middleware(request: NextRequest) {
  // Verify API key is configured
  if (!process.env.ELEVENLABS_API_KEY) {
    return new Response('API key not configured', { status: 500 });
  }

  // Add rate limiting header
  const response = NextResponse.next();
  response.headers.set('X-RateLimit-Limit', '100');
  return response;
}
```

## Cloudflare Workers

### Setup

1. Create `wrangler.toml`:
```toml
name = "elevenlabs-worker"
main = "src/index.ts"
compatibility_date = "2023-01-01"

[vars]
ENVIRONMENT = "production"

# Add secret via: wrangler secret put ELEVENLABS_API_KEY
```

2. Set secret:
```bash
wrangler secret put ELEVENLABS_API_KEY
```

### Example: Worker

Create `src/index.ts`:

```typescript
import { ElevenLabsClient } from 'elevenlabs';

interface Env {
  ELEVENLABS_API_KEY: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Only handle POST requests
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    const { text, voiceId } = await request.json();

    if (!text) {
      return Response.json({ error: 'Text required' }, { status: 400 });
    }

    try {
      const client = new ElevenLabsClient({
        apiKey: env.ELEVENLABS_API_KEY
      });

      const audio = await client.generate({
        voice: voiceId || '21m00Tcm4TlvDq8ikWAM'
        text
        model_id: 'eleven_monolingual_v1'
      });

      // Stream response
      const stream = new ReadableStream({
        async start(controller) {
          try {
            for await (const chunk of audio) {
              controller.enqueue(chunk);
            }
            controller.close();
          } catch (error) {
            controller.error(error);
          }
        }
      });

      return new Response(stream, {
        headers: {
          'Content-Type': 'audio/mpeg'
          'Cache-Control': 'public, max-age=3600'
        }
      });
    } catch (error) {
      console.error('TTS error:', error);
      return Response.json(
        { error: 'Speech generation failed' }
        { status: 500 }
      );
    }
  }
};
```

### Deploy

```bash
npm install wrangler -g
wrangler deploy
```

## Deno Deploy

### Setup

1. Create `main.ts`:

```typescript
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { ElevenLabsClient } from "npm:elevenlabs";

const ELEVENLABS_API_KEY = Deno.env.get("ELEVENLABS_API_KEY");

if (!ELEVENLABS_API_KEY) {
  throw new Error("ELEVENLABS_API_KEY not set");
}

const client = new ElevenLabsClient({ apiKey: ELEVENLABS_API_KEY });

async function handler(req: Request): Promise<Response> {
  const url = new URL(req.url);

  if (url.pathname === "/api/tts" && req.method === "POST") {
    const { text, voiceId } = await req.json();

    if (!text) {
      return Response.json({ error: "Text required" }, { status: 400 });
    }

    try {
      const audio = await client.generate({
        voice: voiceId || "21m00Tcm4TlvDq8ikWAM"
        text
        model_id: "eleven_monolingual_v1"
      });

      const stream = new ReadableStream({
        async start(controller) {
          try {
            for await (const chunk of audio) {
              controller.enqueue(chunk);
            }
            controller.close();
          } catch (error) {
            controller.error(error);
          }
        }
      });

      return new Response(stream, {
        headers: {
          "Content-Type": "audio/mpeg"
          "Cache-Control": "public, max-age=3600"
        }
      });
    } catch (error) {
      return Response.json(
        { error: "Speech generation failed" }
        { status: 500 }
      );
    }
  }

  return Response.json({ error: "Not found" }, { status: 404 });
}

serve(handler, { port: 8000 });
```

### Deploy

```bash
deployctl deploy --project=my-project main.ts
```

## Edge-Optimized Patterns

### Pattern 1: Streaming Response

Always stream for better performance:

```typescript
// ✓ Good: Stream directly
const stream = new ReadableStream({
  async start(controller) {
    for await (const chunk of audio) {
      controller.enqueue(chunk);
    }
    controller.close();
  }
});

return new Response(stream, {
  headers: { 'Content-Type': 'audio/mpeg' }
});

// ✗ Bad: Buffer entire response
const chunks = [];
for await (const chunk of audio) {
  chunks.push(chunk);
}
const buffer = Buffer.concat(chunks); // Buffer not available in edge!
```

### Pattern 2: Caching

Use edge caching for repeated content:

```typescript
const cacheKey = `tts:${voiceId}:${hashText(text)}`;
const cache = caches.default;

// Check cache first
let response = await cache.match(cacheKey);

if (!response) {
  // Generate audio
  const audio = await generateSpeech(text, voiceId);

  response = new Response(audio, {
    headers: {
      'Content-Type': 'audio/mpeg'
      'Cache-Control': 'public, max-age=86400'
    }
  });

  // Store in cache
  await cache.put(cacheKey, response.clone());
}

return response;
```

### Pattern 3: Error Handling

Handle edge runtime errors:

```typescript
try {
  const audio = await generateSpeech(text, voiceId);
  return streamResponse(audio);
} catch (error) {
  // Log to edge service
  console.error('[ElevenLabs]', error);

  // Return appropriate status
  if (error.message.includes('401')) {
    return Response.json({ error: 'Invalid API key' }, { status: 500 });
  }

  if (error.message.includes('429')) {
    return Response.json(
      { error: 'Rate limit exceeded' }
      { status: 429, headers: { 'Retry-After': '60' } }
    );
  }

  return Response.json({ error: 'Internal error' }, { status: 500 });
}
```

### Pattern 4: Request Validation

Validate early in edge functions:

```typescript
// Quick validation before expensive operations
function validateRequest(data: any): { text: string; voiceId?: string } {
  if (!data || typeof data !== 'object') {
    throw new Error('Invalid request body');
  }

  const { text, voiceId } = data;

  if (!text || typeof text !== 'string') {
    throw new Error('Text is required');
  }

  if (text.length > 5000) {
    throw new Error('Text too long (max 5000 characters)');
  }

  if (voiceId && typeof voiceId !== 'string') {
    throw new Error('Invalid voice ID');
  }

  return { text, voiceId };
}
```

## Performance Tips

1. **Minimize cold starts**: Keep edge functions small
2. **Stream responses**: Don't buffer large audio files
3. **Cache aggressively**: Use edge cache for repeated content
4. **Validate early**: Reject invalid requests quickly
5. **Monitor latency**: Use edge platform metrics

## Testing Edge Functions

### Local Testing (Vercel)

```bash
npm install -g vercel
vercel dev
```

### Local Testing (Cloudflare)

```bash
wrangler dev
```

### Local Testing (Deno)

```bash
deno run --allow-net --allow-env main.ts
```

## References

- [Vercel Edge Functions](https://vercel.com/docs/functions/edge-functions)
- [Cloudflare Workers](https://developers.cloudflare.com/workers/)
- [Deno Deploy](https://deno.com/deploy)
- [ElevenLabs Streaming](https://elevenlabs.io/docs/api-reference/streaming)
