# Streaming TTS Example

Real-time text-to-speech streaming using WebSocket connections for ultra-low latency applications.

## Overview

Streaming TTS allows you to:
- Start playing audio before generation completes
- Achieve ultra-low latency (as low as 75ms with Flash v2.5)
- Build interactive voice applications
- Handle real-time conversations

## Use Cases

- **Real-time chatbots**: Voice responses during conversations
- **Virtual assistants**: Natural voice interactions
- **Gaming**: Dynamic character voices
- **Live narration**: Real-time content narration
- **Interactive IVR**: Responsive phone systems

## How It Works

1. **WebSocket Connection**: Establish persistent connection to ElevenLabs
2. **Text Streaming**: Send text chunks as they're generated
3. **Audio Chunks**: Receive audio chunks immediately
4. **Progressive Playback**: Play audio while still generating

## Prerequisites

- ElevenLabs API key
- Voice ID
- WebSocket client (JavaScript, Python, etc.)
- Audio playback capability

## Quick Start (JavaScript)

### 1. Setup

```bash
npm install ws
```

### 2. Basic Streaming

```javascript
const WebSocket = require('ws');
const fs = require('fs');

const voiceId = 'YOUR_VOICE_ID';
const apiKey = process.env.ELEVENLABS_API_KEY;
const model = 'eleven_flash_v2_5';  // Recommended for streaming

const ws = new WebSocket(`wss://api.elevenlabs.io/v1/text-to-speech/${voiceId}/stream?model_id=${model}`);

ws.on('open', () => {
    const config = {
        text: 'Hello, this is streaming text-to-speech!',
        voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75
        }
    };

    ws.send(JSON.stringify(config));
});

ws.on('message', (data) => {
    // Audio chunk received
    console.log('Received audio chunk:', data.length, 'bytes');
    // Play or save audio chunk
});

ws.on('close', () => {
    console.log('Stream ended');
});
```

## Configuration Options

### Model Selection for Streaming

**Recommended: Eleven Flash v2.5**
- Ultra-low latency (~75ms)
- Best for real-time applications
- 50% cheaper
- 32 languages

**Alternative: Eleven Turbo v2.5**
- Better quality than Flash
- Slightly higher latency (~250-300ms)
- Good balance for streaming

### Latency Optimization

```json
{
  "optimize_streaming_latency": 4,
  "voice_settings": {
    "stability": 0.5,
    "similarity_boost": 0.75,
    "style": 0.0,
    "use_speaker_boost": true
  }
}
```

**optimize_streaming_latency levels:**
- `0`: No optimization (highest quality)
- `1`: Slight optimization
- `2`: Moderate optimization
- `3`: High optimization (recommended)
- `4`: Maximum optimization (lowest latency)

### Chunk Length Schedule

Control how audio is chunked:

```json
{
  "chunk_length_schedule": [120, 160, 250, 290]
}
```

- Smaller values = lower latency, more chunks
- Larger values = better quality, fewer chunks
- Default is optimized for balance

## Complete JavaScript Example

See `client-example.js` for a full implementation including:
- Connection management
- Audio buffering
- Error handling
- Reconnection logic
- Progress tracking

```bash
node client-example.js --voice-id YOUR_VOICE_ID --text "Your text here"
```

## Python Example

```python
import websockets
import asyncio
import json
import os

async def stream_tts():
    voice_id = "YOUR_VOICE_ID"
    api_key = os.environ.get('ELEVENLABS_API_KEY')
    model = "eleven_flash_v2_5"

    uri = f"wss://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream?model_id={model}"

    async with websockets.connect(uri) as websocket:
        # Send configuration
        config = {
            "text": "Hello from Python streaming TTS!",
            "voice_settings": {
                "stability": 0.5,
                "similarity_boost": 0.75
            },
            "optimize_streaming_latency": 3
        }

        await websocket.send(json.dumps(config))

        # Receive audio chunks
        async for message in websocket:
            if isinstance(message, bytes):
                print(f"Received audio chunk: {len(message)} bytes")
                # Process or play audio chunk
            else:
                data = json.loads(message)
                if data.get('audio'):
                    print("Audio generation complete")
                elif data.get('error'):
                    print(f"Error: {data['error']}")

asyncio.run(stream_tts())
```

## Advanced Features

### Multi-turn Conversations

Maintain context across multiple exchanges:

```javascript
const contextIds = [];

// First message
const request1 = {
    text: "Hello, how are you?",
    voice_settings: { /* ... */ },
    next_text: "I'm doing great, thanks for asking!"
};

// Send and capture request ID
ws.send(JSON.stringify(request1));

// Later messages use previous context
const request2 = {
    text: "I'm doing great, thanks for asking!",
    voice_settings: { /* ... */ },
    previous_request_ids: contextIds
};
```

### Text Chunking

For long text, send chunks progressively:

```javascript
const chunks = longText.match(/.{1,500}/g);

for (let i = 0; i < chunks.length; i++) {
    const chunk = {
        text: chunks[i],
        voice_settings: { /* ... */ },
        flush: (i === chunks.length - 1)  // Flush on last chunk
    };

    ws.send(JSON.stringify(chunk));
}
```

### Audio Format Selection

```javascript
const format = "mp3_44100_128";  // Or opus_44100_64 for even lower bandwidth
const ws = new WebSocket(
    `wss://api.elevenlabs.io/v1/text-to-speech/${voiceId}/stream?output_format=${format}`
);
```

## Performance Optimization

### Reduce Latency

1. **Use Flash v2.5 model**
   ```json
   { "model_id": "eleven_flash_v2_5" }
   ```

2. **Maximum latency optimization**
   ```json
   { "optimize_streaming_latency": 4 }
   ```

3. **Lower bitrate format**
   ```
   output_format=opus_44100_64
   ```

4. **Aggressive chunk schedule**
   ```json
   { "chunk_length_schedule": [80, 120, 160, 200] }
   ```

### Buffer Management

Implement client-side buffering for smooth playback:

```javascript
const audioQueue = [];
let isPlaying = false;

ws.on('message', (chunk) => {
    audioQueue.push(chunk);
    if (!isPlaying) {
        playNextChunk();
    }
});

function playNextChunk() {
    if (audioQueue.length === 0) {
        isPlaying = false;
        return;
    }

    isPlaying = true;
    const chunk = audioQueue.shift();
    playAudio(chunk, () => {
        playNextChunk();
    });
}
```

## Error Handling

### Connection Errors

```javascript
ws.on('error', (error) => {
    console.error('WebSocket error:', error);
    // Implement reconnection logic
    reconnect();
});

ws.on('close', (code, reason) => {
    console.log(`Connection closed: ${code} - ${reason}`);
    if (code !== 1000) {  // Not normal closure
        reconnect();
    }
});

function reconnect() {
    setTimeout(() => {
        console.log('Reconnecting...');
        // Recreate WebSocket connection
    }, 2000);
}
```

### Generation Errors

```javascript
ws.on('message', (data) => {
    try {
        const message = JSON.parse(data);
        if (message.error) {
            console.error('Generation error:', message.error);
            // Handle error (retry, fallback, etc.)
        }
    } catch (e) {
        // Binary audio chunk, process normally
        processAudioChunk(data);
    }
});
```

## Use Case Examples

### Real-time Chatbot

```javascript
// Client sends message to chatbot
const userMessage = "What's the weather like?";

// Chatbot generates response
const botResponse = "The weather is sunny with a high of 75 degrees.";

// Stream response immediately
streamTTS(botResponse, {
    model: 'eleven_flash_v2_5',
    optimize_streaming_latency: 4,
    voice_settings: { stability: 0.5 }
});
```

### Interactive Game Character

```javascript
// Character responds to player action
const characterDialogue = "Well done, brave warrior! You've defeated the dragon!";

streamTTS(characterDialogue, {
    model: 'eleven_v3',  // More expressive for character
    optimize_streaming_latency: 2,
    voice_settings: {
        stability: 0.4,  // More expressive
        style: 0.3       // Character personality
    }
});
```

### Live Narration

```javascript
// Narrator describes live events
const narration = "And the ball is passed to Johnson, he's making a run...";

streamTTS(narration, {
    model: 'eleven_turbo_v2_5',
    optimize_streaming_latency: 3,
    voice_settings: {
        stability: 0.6,
        similarity_boost: 0.75
    }
});
```

## Testing

Test streaming with the provided script:

```bash
bash stream-example.sh \
  --voice-id YOUR_VOICE_ID \
  --text "Testing streaming TTS" \
  --model eleven_flash_v2_5 \
  --optimize-latency 4
```

## Monitoring

Track streaming performance:

```javascript
const metrics = {
    firstChunkTime: 0,
    totalChunks: 0,
    totalBytes: 0,
    startTime: Date.now()
};

ws.on('message', (chunk) => {
    if (metrics.totalChunks === 0) {
        metrics.firstChunkTime = Date.now() - metrics.startTime;
        console.log(`First chunk in ${metrics.firstChunkTime}ms`);
    }

    metrics.totalChunks++;
    metrics.totalBytes += chunk.length;
});

ws.on('close', () => {
    const duration = Date.now() - metrics.startTime;
    console.log(`Stream complete: ${metrics.totalChunks} chunks, ${metrics.totalBytes} bytes in ${duration}ms`);
});
```

## Best Practices

1. **Use Flash v2.5 for streaming**: Optimized for low latency
2. **Set optimize_streaming_latency**: Level 3-4 for real-time apps
3. **Implement buffering**: Smooth playback despite network jitter
4. **Handle reconnections**: Gracefully recover from connection loss
5. **Monitor latency**: Track first-chunk-time and adjust settings
6. **Test thoroughly**: Validate across network conditions
7. **Fallback strategy**: Have HTTP endpoint as backup

## Troubleshooting

**High latency despite optimization**
- Check network connection
- Use Flash v2.5 model
- Increase optimize_streaming_latency
- Use lower bitrate format

**Audio stuttering**
- Increase client buffer size
- Check network stability
- Reduce optimize_streaming_latency (improves chunk quality)

**Connection drops**
- Implement reconnection with exponential backoff
- Use ping/pong to keep connection alive
- Monitor connection health

## Resources

- WebSocket client: `client-example.js`
- Configuration template: `../../templates/streaming-config.json.template`
- ElevenLabs docs: https://elevenlabs.io/docs/api-reference/streaming
