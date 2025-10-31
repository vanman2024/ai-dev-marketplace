# Multi-Modal Chat Example

Complete voice + text chat application combining ElevenLabs transcription with LLM responses.

## Features

- Voice input via file upload or microphone recording
- Text input via traditional chat interface
- ElevenLabs transcription integration
- OpenAI GPT integration for intelligent responses
- Conversation history management
- Real-time message streaming
- TypeScript + React 19 + Next.js 15

## Architecture

```
User Input (Voice/Text)
    ↓
ElevenLabs Transcription (if voice)
    ↓
LLM Processing (OpenAI/Anthropic)
    ↓
Response Generation
    ↓
Display in Chat UI
```

## Setup

### 1. Create Project

```bash
npx create-next-app@latest multi-modal-chat --typescript --tailwind --app
cd multi-modal-chat
```

### 2. Install Dependencies

```bash
npm install @ai-sdk/elevenlabs @ai-sdk/openai ai
```

### 3. Environment Variables

Create `.env.local`:

```bash
ELEVENLABS_API_KEY=your_elevenlabs_api_key
OPENAI_API_KEY=your_openai_api_key
```

### 4. Create Hook

Copy the transcription hook:

```bash
mkdir -p hooks
cp ../../templates/transcribe-hook.ts.template hooks/useTranscribe.ts
```

### 5. Create Chat API Route

Create `app/api/chat/route.ts`:

```typescript
import { streamText } from 'ai';
import { openai } from '@ai-sdk/openai';
import { NextRequest } from 'next/server';

export async function POST(request: NextRequest) {
  const { messages } = await request.json();

  const result = await streamText({
    model: openai('gpt-4o')
    messages
  });

  return result.toAIStreamResponse();
}
```

### 6. Create Transcription API Route

```bash
mkdir -p app/api/transcribe
cp ../../templates/api-route.ts.template app/api/transcribe/route.ts
```

### 7. Create Main Component

Copy the multi-modal chat component:

```bash
mkdir -p components
cp ../../templates/multi-modal-chat.tsx.template components/MultiModalChat.tsx
```

### 8. Update Main Page

Create `app/page.tsx`:

```typescript
import MultiModalChat from '@/components/MultiModalChat';

export default function Home() {
  return (
    <div className="h-screen">
      <MultiModalChat />
    </div>
  );
}
```

## Usage

### Voice Input

1. Click the microphone icon
2. Upload an audio file or record from microphone
3. Wait for transcription
4. LLM generates response automatically

### Text Input

1. Type message in the input field
2. Press Enter or click Send
3. LLM generates response

## Advanced Features

### Add Microphone Recording

Install recorder library:

```bash
npm install react-media-recorder
```

Update `MultiModalChat.tsx`:

```typescript
import { useReactMediaRecorder } from 'react-media-recorder';

const { status, startRecording, stopRecording, mediaBlobUrl } =
  useReactMediaRecorder({ audio: true });

// Add recording button
<button
  onClick={status === 'recording' ? stopRecording : startRecording}
  className={status === 'recording' ? 'bg-red-500' : 'bg-blue-500'}
>
  {status === 'recording' ? 'Stop Recording' : 'Start Recording'}
</button>;
```

### Add Speech Synthesis for Responses

Install ElevenLabs speech:

```typescript
import { experimental_generateSpeech as generateSpeech } from 'ai';
import { elevenlabs } from '@ai-sdk/elevenlabs';

const synthesizeResponse = async (text: string) => {
  const { audio } = await generateSpeech({
    model: elevenlabs.speech('eleven_multilingual_v2')
    text
    voice: 'Rachel'
  });

  // Play audio
  const audioBlob = new Blob([audio], { type: 'audio/mpeg' });
  const audioUrl = URL.createObjectURL(audioBlob);
  const audioElement = new Audio(audioUrl);
  audioElement.play();
};
```

### Add Conversation Context

```typescript
const [conversationContext, setConversationContext] = useState<
  Array<{ role: 'user' | 'assistant'; content: string }>
>([]);

// Update on each message
setConversationContext((prev) => [
  ...prev
  { role: 'user', content: userMessage }
  { role: 'assistant', content: aiResponse }
]);
```

### Add Message Persistence

```typescript
// Save to localStorage
useEffect(() => {
  localStorage.setItem('messages', JSON.stringify(messages));
}, [messages]);

// Load on mount
useEffect(() => {
  const saved = localStorage.getItem('messages');
  if (saved) {
    setMessages(JSON.parse(saved));
  }
}, []);
```

## Component Customization

### Custom Styling

Update Tailwind classes in `MultiModalChat.tsx`:

```typescript
// Change message bubbles
className={`rounded-xl p-4 ${
  message.role === 'user'
    ? 'bg-gradient-to-r from-blue-500 to-blue-600 text-white'
    : 'bg-gradient-to-r from-gray-100 to-gray-200 text-gray-900'
}`}
```

### Add Message Actions

```typescript
<div className="flex gap-2 mt-2">
  <button onClick={() => copyToClipboard(message.content)}>Copy</button>
  <button onClick={() => shareMessage(message)}>Share</button>
  <button onClick={() => regenerateResponse(message)}>Regenerate</button>
</div>
```

### Add File Attachments

```typescript
const [attachments, setAttachments] = useState<File[]>([]);

// In form
<input
  type="file"
  multiple
  onChange={(e) => {
    const files = Array.from(e.target.files || []);
    setAttachments(files);
  }}
/>;
```

## Testing

### Manual Testing

```bash
npm run dev
```

Test scenarios:
1. Upload MP3 file with clear speech
2. Type text message
3. Upload audio in different language
4. Test error handling with invalid file

### Automated Testing

Install testing libraries:

```bash
npm install -D @testing-library/react @testing-library/jest-dom vitest
```

Create `__tests__/MultiModalChat.test.tsx`:

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import MultiModalChat from '@/components/MultiModalChat';

describe('MultiModalChat', () => {
  it('renders chat interface', () => {
    render(<MultiModalChat />);
    expect(screen.getByText('Multi-Modal Chat')).toBeInTheDocument();
  });

  it('handles text input', async () => {
    render(<MultiModalChat />);
    const input = screen.getByPlaceholderText('Type a message...');
    fireEvent.change(input, { target: { value: 'Hello' } });
    fireEvent.submit(input.closest('form')!);
    // Assert message appears
  });
});
```

## Deployment

### Vercel

```bash
vercel
```

Set environment variables in Vercel dashboard:
- `ELEVENLABS_API_KEY`
- `OPENAI_API_KEY`

### Docker

Create `Dockerfile`:

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
```

Build and run:

```bash
docker build -t multi-modal-chat .
docker run -p 3000:3000 --env-file .env.local multi-modal-chat
```

## Performance Optimization

### Lazy Load Components

```typescript
const MultiModalChat = lazy(() => import('@/components/MultiModalChat'));
```

### Virtualize Message List

```bash
npm install react-window
```

```typescript
import { FixedSizeList } from 'react-window';

<FixedSizeList
  height={600}
  itemCount={messages.length}
  itemSize={100}
  width="100%"
>
  {({ index, style }) => (
    <div style={style}>{/* Message component */}</div>
  )}
</FixedSizeList>;
```

## Troubleshooting

### Microphone Access Denied

Check browser permissions and use HTTPS in production.

### Audio Format Not Supported

Convert audio files:

```bash
ffmpeg -i input.wav -ar 16000 -ac 1 output.wav
```

### API Rate Limits

Implement rate limiting:

```typescript
import { Ratelimit } from '@upstash/ratelimit';

const ratelimit = new Ratelimit({
  redis: /* ... */
  limiter: Ratelimit.slidingWindow(10, '1 m')
});
```

## Learn More

- [Vercel AI SDK Documentation](https://ai-sdk.dev)
- [ElevenLabs API](https://elevenlabs.io/docs)
- [OpenAI API](https://platform.openai.com/docs)
- [Next.js App Router](https://nextjs.org/docs/app)
