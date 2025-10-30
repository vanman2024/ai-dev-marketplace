# Speaker Diarization Example

This example demonstrates how to use ElevenLabs speaker diarization to identify and label up to 32 speakers in audio.

## What is Speaker Diarization?

Speaker diarization answers "who spoke when" by:
- Identifying distinct speakers in audio
- Labeling each word/segment with speaker ID
- Providing timestamps for speaker changes
- Handling up to 32 speakers simultaneously

## Quick Start

### Using the Script

```bash
# Enable diarization with auto speaker detection
bash ../../scripts/transcribe-audio.sh interview.mp3 en --diarize

# Specify number of speakers (better accuracy)
bash ../../scripts/transcribe-audio.sh meeting.mp3 en --diarize --num-speakers=3
```

### Using Vercel AI SDK

```typescript
import { elevenlabs } from '@ai-sdk/elevenlabs';
import { experimental_transcribe as transcribe } from 'ai';

const result = await transcribe({
  model: elevenlabs.transcription('scribe_v1'),
  audio: audioData,
  providerOptions: {
    elevenlabs: {
      languageCode: 'en',
      diarize: true,
      numSpeakers: 2, // Optional: specify for better accuracy
    },
  },
});

// Extract speaker-separated transcript
const transcript = result.segments
  .filter(s => s.speaker)
  .reduce((acc, s) => {
    const last = acc[acc.length - 1];
    if (last && last.speaker === s.speaker) {
      last.text += ' ' + s.text;
    } else {
      acc.push({ speaker: s.speaker, text: s.text });
    }
    return acc;
  }, []);

transcript.forEach(({ speaker, text }) => {
  console.log(`[${speaker}]: ${text}`);
});
```

## Use Cases

### 1. Two-Person Interview

Perfect for podcasts, interviews, Q&A sessions.

```typescript
const result = await transcribe({
  model: elevenlabs.transcription('scribe_v1'),
  audio: audioData,
  providerOptions: {
    elevenlabs: {
      languageCode: 'en',
      diarize: true,
      numSpeakers: 2, // Host and guest
    },
  },
});
```

**Output:**
```
[Speaker 1]: Welcome to the podcast. Today we have an amazing guest.
[Speaker 2]: Thanks for having me. I'm excited to be here.
[Speaker 1]: Let's dive right in. Tell us about your background.
[Speaker 2]: I've been working in tech for over 15 years...
```

### 2. Multi-Person Meeting

Business meetings, team discussions, conference calls.

```typescript
const result = await transcribe({
  model: elevenlabs.transcription('scribe_v1'),
  audio: audioData,
  providerOptions: {
    elevenlabs: {
      languageCode: 'en',
      diarize: true,
      numSpeakers: 5, // Or null for auto-detect
    },
  },
});
```

### 3. Panel Discussion

Panel discussions, roundtable conversations, debates.

```typescript
const result = await transcribe({
  model: elevenlabs.transcription('scribe_v1'),
  audio: audioData,
  providerOptions: {
    elevenlabs: {
      languageCode: 'en',
      diarize: true,
      numSpeakers: 6,
      tagAudioEvents: true, // Capture audience reactions
    },
  },
});
```

### 4. Classroom/Lecture

Lectures with Q&A, classroom discussions.

```typescript
const result = await transcribe({
  model: elevenlabs.transcription('scribe_v1'),
  audio: audioData,
  providerOptions: {
    elevenlabs: {
      languageCode: 'en',
      diarize: true,
      // Don't specify numSpeakers - let model detect varying student questions
    },
  },
});
```

## Using the Template

The template provides helper functions for working with diarization:

```typescript
import {
  transcribeAudio,
  extractSpeakerSegments,
  formatTranscriptWithSpeakers,
} from '../../templates/vercel-ai-transcribe.ts.template';

// Transcribe with diarization
const result = await transcribeAudio({
  audioPath: './meeting.mp3',
  languageCode: 'en',
  diarize: true,
  numSpeakers: 3,
});

// Extract speaker segments
const speakers = extractSpeakerSegments(result);

speakers.forEach(segment => {
  console.log(`${segment.speaker} (${segment.startTime}s - ${segment.endTime}s):`);
  console.log(`  ${segment.text}`);
  console.log();
});

// Or use formatted output
console.log(formatTranscriptWithSpeakers(result));
```

## Advanced Features

### Custom Speaker Labels

Replace generic "Speaker 1" with actual names:

```typescript
const result = await transcribeAudio({
  audioPath: './interview.mp3',
  languageCode: 'en',
  diarize: true,
  numSpeakers: 2,
});

// Map speakers to names
const speakerMap = {
  'Speaker 1': 'Host',
  'Speaker 2': 'Guest',
};

const formatted = formatTranscriptWithSpeakers(result)
  .replace(/Speaker 1/g, speakerMap['Speaker 1'])
  .replace(/Speaker 2/g, speakerMap['Speaker 2']);

console.log(formatted);
```

### Speaker Statistics

Analyze who spoke most:

```typescript
const speakers = extractSpeakerSegments(result);

const stats = speakers.reduce((acc, segment) => {
  if (!acc[segment.speaker]) {
    acc[segment.speaker] = {
      wordCount: 0,
      duration: 0,
      segments: 0,
    };
  }

  acc[segment.speaker].wordCount += segment.text.split(' ').length;
  acc[segment.speaker].duration += segment.endTime - segment.startTime;
  acc[segment.speaker].segments += 1;

  return acc;
}, {});

Object.entries(stats).forEach(([speaker, data]) => {
  console.log(`${speaker}:`);
  console.log(`  Words: ${data.wordCount}`);
  console.log(`  Speaking time: ${data.duration.toFixed(1)}s`);
  console.log(`  Segments: ${data.segments}`);
});
```

### Speaker Timeline

Visualize when each speaker talked:

```typescript
const speakers = extractSpeakerSegments(result);

console.log('Timeline:');
speakers.forEach(segment => {
  const start = formatTime(segment.startTime);
  const end = formatTime(segment.endTime);
  console.log(`[${start}-${end}] ${segment.speaker}: ${segment.text.slice(0, 50)}...`);
});

function formatTime(seconds) {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}
```

## Configuration Reference

### Load Configuration Template

```bash
# View diarization configuration options
cat ../../templates/diarization-config.json.template
```

### Key Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `diarize` | boolean | true | Enable speaker diarization |
| `numSpeakers` | number | null | Number of speakers (1-32, null=auto) |
| `tagAudioEvents` | boolean | true | Tag events like laughter |
| `timestampsGranularity` | string | 'word' | 'none', 'word', 'character' |

## Best Practices

### 1. Specify Speaker Count When Known

```typescript
// ✅ Good - known speaker count
providerOptions: {
  elevenlabs: {
    diarize: true,
    numSpeakers: 2, // Interview with 2 people
  },
}

// ⚠️ Works but less accurate
providerOptions: {
  elevenlabs: {
    diarize: true,
    // Let model guess speaker count
  },
}
```

### 2. Use High-Quality Audio

- Individual microphones per speaker (best)
- Clear separation between speakers
- Minimal background noise
- Avoid speaker overlap (cross-talk)

### 3. Handle Edge Cases

```typescript
const result = await transcribeAudio({
  audioPath: './audio.mp3',
  diarize: true,
  numSpeakers: 3,
});

// Check if diarization worked
const speakers = extractSpeakerSegments(result);
if (speakers.length === 0) {
  console.warn('No speakers detected - falling back to full transcript');
  console.log(result.text);
} else {
  console.log(formatTranscriptWithSpeakers(result));
}
```

## Output Formats

### Format 1: Grouped by Speaker

```typescript
const formatted = formatTranscriptWithSpeakers(result);
```

**Output:**
```
[Speaker 1]: Hello everyone. Welcome to today's meeting. Let's start with updates.

[Speaker 2]: Thanks. I'll go first. We completed the backend integration last week.

[Speaker 3]: Great work. On the frontend side, we're making good progress too.
```

### Format 2: Timeline with Timestamps

```typescript
const formatted = formatTimestamped(result);
```

**Output:**
```
[00:00] [Speaker 1] Hello everyone
[00:03] [Speaker 1] Welcome to today's meeting
[00:07] [Speaker 2] Thanks I'll go first
[00:10] [Speaker 2] We completed the backend integration
```

### Format 3: JSON with Full Metadata

```typescript
const speakers = extractSpeakerSegments(result);
console.log(JSON.stringify(speakers, null, 2));
```

**Output:**
```json
[
  {
    "speaker": "Speaker 1",
    "text": "Hello everyone. Welcome to today's meeting.",
    "startTime": 0.5,
    "endTime": 7.2
  },
  {
    "speaker": "Speaker 2",
    "text": "Thanks. I'll go first.",
    "startTime": 7.5,
    "endTime": 10.1
  }
]
```

## Troubleshooting

### Problem: Speakers Not Detected

**Causes:**
- Poor audio quality
- Only one speaker in audio
- Speakers too similar
- Too much background noise

**Solutions:**
```bash
# Validate audio first
bash ../../scripts/validate-audio.sh audio.mp3

# Try with explicit speaker count
bash ../../scripts/transcribe-audio.sh audio.mp3 en --diarize --num-speakers=2
```

### Problem: Too Many Speakers Detected

**Causes:**
- Background voices
- Echo or reverb
- Music interfering

**Solutions:**
```typescript
// Set specific speaker count
providerOptions: {
  elevenlabs: {
    diarize: true,
    numSpeakers: 3, // Exactly 3 speakers expected
    tagAudioEvents: false, // Disable to reduce false positives
  },
}
```

### Problem: Speakers Mislabeled

**Causes:**
- Similar voice characteristics
- Inconsistent audio levels
- Speaker position changes

**Solutions:**
- Use separate microphones per speaker
- Maintain consistent audio levels
- Post-process to merge similar speakers

## Integration Examples

### Save with Speaker Labels

```typescript
import { writeFile } from 'fs/promises';

const result = await transcribeAudio({
  audioPath: './meeting.mp3',
  diarize: true,
  numSpeakers: 4,
});

const formatted = formatTranscriptWithSpeakers(result);
await writeFile('transcript.txt', formatted);
```

### Generate Subtitles with Speakers

```typescript
function toSRT(segments) {
  return segments
    .filter(s => s.speaker && s.text)
    .map((segment, i) => {
      const start = formatSRTTime(segment.startTime);
      const end = formatSRTTime(segment.endTime);
      return `${i + 1}\n${start} --> ${end}\n[${segment.speaker}] ${segment.text}\n`;
    })
    .join('\n');
}

const srt = toSRT(extractSpeakerSegments(result));
await writeFile('subtitles.srt', srt);
```

## Next Steps

- [Multi-Language Example](../multi-language/README.md) - Diarization in 99 languages
- [Webhook Integration](../webhook-integration/README.md) - Async processing for long files
- [Basic STT](../basic-stt/README.md) - Simple transcription without diarization

## Resources

- [Diarization Configuration Template](../../templates/diarization-config.json.template)
- [ElevenLabs Diarization Docs](https://elevenlabs.io/docs/capabilities/speech-to-text#diarization)
- [Speaker Identification Best Practices](https://elevenlabs.io/docs/capabilities/speech-to-text#speaker-identification)
