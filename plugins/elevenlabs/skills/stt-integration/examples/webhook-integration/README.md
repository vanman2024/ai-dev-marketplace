# Webhook Integration Example

This example demonstrates asynchronous transcription using webhooks for processing long audio files without blocking.

## Why Use Webhooks?

Webhooks are ideal for:
- **Long audio files** (>8 minutes are automatically chunked)
- **Large batch processing** (process multiple files without waiting)
- **Background processing** (don't block user interface)
- **Reliable delivery** (automatic retries on failure)
- **Scalable systems** (handle many concurrent requests)

## How Webhooks Work

1. Submit transcription request with webhook URL
2. API returns immediately with request ID
3. Transcription processes asynchronously
4. API posts results to your webhook URL when complete
5. Your server processes the results

## Setup

### 1. Create Webhook Endpoint

```typescript
// Next.js API Route: app/api/transcription-webhook/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    // Validate webhook (optional but recommended)
    const signature = request.headers.get('x-elevenlabs-signature');
    if (!validateSignature(signature, body)) {
      return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
    }

    // Extract transcription result
    const {
      request_id,
      text,
      segments,
      status,
      error,
    } = body;

    if (status === 'completed') {
      // Process successful transcription
      await saveTranscription(request_id, text, segments);

      // Notify user (email, websocket, etc.)
      await notifyUser(request_id, 'Transcription complete');
    } else if (status === 'failed') {
      // Handle failure
      console.error(`Transcription ${request_id} failed:`, error);
      await notifyUser(request_id, 'Transcription failed');
    }

    return NextResponse.json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}

function validateSignature(signature: string, body: any): boolean {
  // Implement signature validation
  // Use HMAC with your webhook secret
  return true; // Placeholder
}

async function saveTranscription(requestId: string, text: string, segments: any[]) {
  // Save to database
  console.log(`Saving transcription ${requestId}`);
}

async function notifyUser(requestId: string, message: string) {
  // Notify user via websocket, email, etc.
  console.log(`Notifying user: ${message}`);
}
```

### 2. Submit Transcription with Webhook

```typescript
async function transcribeWithWebhook(audioPath: string, webhookUrl: string) {
  const apiKey = process.env.ELEVENLABS_API_KEY;
  const audioBuffer = await readFile(audioPath);

  const formData = new FormData();
  formData.append('audio', new Blob([audioBuffer]), 'audio.mp3');
  formData.append('model_id', 'scribe_v1');
  formData.append('language_code', 'en');
  formData.append('diarize', 'true');
  formData.append('webhook_url', webhookUrl);

  const response = await fetch('https://api.elevenlabs.io/v1/audio-to-text', {
    method: 'POST',
    headers: {
      'xi-api-key': apiKey,
    },
    body: formData,
  });

  const result = await response.json();
  return result.request_id; // Save this to track the request
}

// Submit transcription
const requestId = await transcribeWithWebhook(
  './long-audio.mp3',
  'https://your-domain.com/api/transcription-webhook'
);

console.log('Transcription submitted:', requestId);
```

## Webhook Payload Structure

### Success Response

```json
{
  "request_id": "req_abc123xyz",
  "status": "completed",
  "text": "Full transcription text here...",
  "segments": [
    {
      "type": "word",
      "text": "Hello",
      "start_time": 0.5,
      "end_time": 1.2,
      "speaker": "Speaker 1"
    }
  ],
  "duration": 120.5,
  "language": "en",
  "completed_at": "2025-10-29T10:30:00Z"
}
```

### Failure Response

```json
{
  "request_id": "req_abc123xyz",
  "status": "failed",
  "error": {
    "code": "audio_format_unsupported",
    "message": "The audio format is not supported"
  },
  "failed_at": "2025-10-29T10:30:00Z"
}
```

## Complete Implementation

### Express.js Server

```typescript
import express from 'express';
import crypto from 'crypto';

const app = express();
app.use(express.json());

// Webhook endpoint
app.post('/webhook/transcription', async (req, res) => {
  // Validate signature
  const signature = req.headers['x-elevenlabs-signature'];
  if (!validateWebhookSignature(signature, req.body)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  const { request_id, status, text, segments, error } = req.body;

  if (status === 'completed') {
    // Store in database
    await db.transcriptions.update(request_id, {
      status: 'completed',
      text,
      segments,
      completed_at: new Date(),
    });

    // Notify via WebSocket
    io.to(request_id).emit('transcription:complete', { text, segments });

    res.json({ received: true });
  } else if (status === 'failed') {
    await db.transcriptions.update(request_id, {
      status: 'failed',
      error: error.message,
      failed_at: new Date(),
    });

    io.to(request_id).emit('transcription:failed', { error: error.message });

    res.json({ received: true });
  } else {
    res.status(400).json({ error: 'Unknown status' });
  }
});

function validateWebhookSignature(signature: string, body: any): boolean {
  const secret = process.env.ELEVENLABS_WEBHOOK_SECRET;
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(JSON.stringify(body));
  const expectedSignature = hmac.digest('hex');
  return signature === expectedSignature;
}

app.listen(3000, () => {
  console.log('Webhook server listening on port 3000');
});
```

## Webhook Security

### 1. Signature Validation

```typescript
import crypto from 'crypto';

function validateWebhookSignature(
  signature: string,
  body: any,
  secret: string
): boolean {
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(JSON.stringify(body));
  const expectedSignature = hmac.digest('hex');

  // Constant-time comparison to prevent timing attacks
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}
```

### 2. Request ID Tracking

```typescript
// Store request IDs for validation
const pendingRequests = new Set<string>();

// When submitting transcription
const requestId = await transcribeWithWebhook(audioPath, webhookUrl);
pendingRequests.add(requestId);

// In webhook handler
app.post('/webhook/transcription', (req, res) => {
  const { request_id } = req.body;

  // Validate this is a request we submitted
  if (!pendingRequests.has(request_id)) {
    return res.status(404).json({ error: 'Unknown request' });
  }

  // Process webhook...
  pendingRequests.delete(request_id);
  res.json({ received: true });
});
```

### 3. Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

const webhookLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // Max 100 requests per minute
  message: 'Too many webhook requests',
});

app.post('/webhook/transcription', webhookLimiter, async (req, res) => {
  // Handle webhook...
});
```

## Database Integration

### Schema

```sql
CREATE TABLE transcriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_id VARCHAR(255) UNIQUE NOT NULL,
  user_id UUID NOT NULL,
  audio_filename VARCHAR(255) NOT NULL,
  status VARCHAR(50) NOT NULL, -- pending, completed, failed
  text TEXT,
  segments JSONB,
  error TEXT,
  submitted_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  webhook_url VARCHAR(500),
  INDEX idx_request_id (request_id),
  INDEX idx_user_id (user_id),
  INDEX idx_status (status)
);
```

### Save/Retrieve

```typescript
// Save initial request
async function saveTranscriptionRequest(
  userId: string,
  requestId: string,
  audioFilename: string,
  webhookUrl: string
) {
  await db.query(
    `INSERT INTO transcriptions (user_id, request_id, audio_filename, status, webhook_url)
     VALUES ($1, $2, $3, $4, $5)`,
    [userId, requestId, audioFilename, 'pending', webhookUrl]
  );
}

// Update when webhook received
async function updateTranscription(
  requestId: string,
  text: string,
  segments: any[]
) {
  await db.query(
    `UPDATE transcriptions
     SET status = $1, text = $2, segments = $3, completed_at = NOW()
     WHERE request_id = $4`,
    ['completed', text, JSON.stringify(segments), requestId]
  );
}

// Retrieve for user
async function getUserTranscriptions(userId: string) {
  const result = await db.query(
    `SELECT * FROM transcriptions
     WHERE user_id = $1
     ORDER BY submitted_at DESC`,
    [userId]
  );
  return result.rows;
}
```

## Real-Time Updates

### Using WebSockets

```typescript
import { Server } from 'socket.io';

const io = new Server(httpServer);

// Client connects with request ID
io.on('connection', (socket) => {
  socket.on('watch:transcription', (requestId) => {
    socket.join(requestId);
  });
});

// In webhook handler
app.post('/webhook/transcription', async (req, res) => {
  const { request_id, status, text, segments } = req.body;

  if (status === 'completed') {
    // Emit to clients watching this transcription
    io.to(request_id).emit('transcription:update', {
      status: 'completed',
      text,
      segments,
    });
  }

  res.json({ received: true });
});
```

### Client-Side

```typescript
import { io } from 'socket.io-client';

const socket = io('https://your-server.com');

// Watch for transcription updates
function watchTranscription(requestId: string) {
  socket.emit('watch:transcription', requestId);

  socket.on('transcription:update', (data) => {
    if (data.status === 'completed') {
      console.log('Transcription complete:', data.text);
      // Update UI
    }
  });
}
```

## Retry Logic

Handle webhook failures with retry:

```typescript
// Exponential backoff for retries
async function retryWebhook(
  webhookUrl: string,
  payload: any,
  maxRetries = 3
) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const response = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        return true;
      }

      // Exponential backoff: 1s, 2s, 4s
      await new Promise(resolve =>
        setTimeout(resolve, Math.pow(2, attempt) * 1000)
      );
    } catch (error) {
      console.error(`Webhook attempt ${attempt + 1} failed:`, error);
    }
  }

  return false; // All retries failed
}
```

## Monitoring & Logging

```typescript
// Log all webhook events
app.post('/webhook/transcription', async (req, res) => {
  const { request_id, status } = req.body;

  // Log to monitoring service
  logger.info('Webhook received', {
    request_id,
    status,
    timestamp: new Date().toISOString(),
  });

  // Track metrics
  metrics.increment('webhook.received', { status });

  // Process webhook...
});
```

## Testing Webhooks

### Using ngrok for Local Development

```bash
# Install ngrok
npm install -g ngrok

# Start your local server
node server.js

# In another terminal, expose it
ngrok http 3000

# Use the ngrok URL as webhook URL
# https://abc123.ngrok.io/webhook/transcription
```

### Mock Webhook Payload

```typescript
// Test your webhook handler
async function testWebhook() {
  const mockPayload = {
    request_id: 'test_req_123',
    status: 'completed',
    text: 'This is a test transcription.',
    segments: [
      { type: 'word', text: 'This', start_time: 0.0, end_time: 0.5 },
      { type: 'word', text: 'is', start_time: 0.5, end_time: 0.8 },
    ],
    duration: 2.0,
    language: 'en',
    completed_at: new Date().toISOString(),
  };

  const response = await fetch('http://localhost:3000/webhook/transcription', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(mockPayload),
  });

  console.log('Test response:', await response.json());
}

testWebhook();
```

## Best Practices

1. **Always validate webhook signatures** to prevent spoofing
2. **Return 200 OK quickly** - process async if needed
3. **Implement idempotency** - handle duplicate webhooks gracefully
4. **Store request IDs** - track which requests you submitted
5. **Use retry logic** - handle temporary failures
6. **Log all webhooks** - for debugging and monitoring
7. **Set webhook timeout** - don't let requests hang
8. **Use HTTPS** - webhooks should always use secure URLs

## Troubleshooting

### Webhooks Not Received

**Check:**
- URL is publicly accessible
- Server is running and listening
- Firewall/security groups allow incoming requests
- HTTPS certificate is valid (if using HTTPS)

**Test:**
```bash
# Test webhook endpoint manually
curl -X POST https://your-domain.com/webhook/transcription \
  -H "Content-Type: application/json" \
  -d '{"request_id":"test","status":"completed","text":"Test"}'
```

### Webhook Signature Validation Fails

**Check:**
- Using correct secret
- Serializing body consistently
- Comparing signatures securely

### Duplicate Webhooks

**Solution:** Implement idempotency
```typescript
const processedWebhooks = new Set<string>();

app.post('/webhook/transcription', async (req, res) => {
  const { request_id } = req.body;

  if (processedWebhooks.has(request_id)) {
    // Already processed, return success
    return res.json({ received: true });
  }

  // Process webhook...
  processedWebhooks.add(request_id);
  res.json({ received: true });
});
```

## Resources

- [ElevenLabs Webhook Documentation](https://elevenlabs.io/docs/api-reference/webhooks)
- [Basic STT Example](../basic-stt/README.md)
- [Batch Processing](../../scripts/batch-transcribe.sh)
