# Speaker Detection Example

Multi-speaker transcription with speaker identification, diarization, and meeting analysis.

## Overview

This example demonstrates advanced speaker diarization features:

- Automatic speaker detection (up to 32 speakers)
- Speaker labeling and identification
- Timestamp tracking per speaker
- Turn-taking analysis
- Meeting transcription and summaries
- Speaker interaction patterns

## Use Cases

- Meeting transcription
- Interview recordings
- Podcast transcription
- Multi-speaker conversations
- Conference call analysis
- Focus group recordings

## Setup

### 1. Install Dependencies

```bash
npm install @ai-sdk/elevenlabs ai
npm install -D @types/node typescript tsx
```

### 2. Copy Template

```bash
mkdir -p lib
cp ../../templates/speaker-diarization.ts.template lib/diarization.ts
```

### 3. Environment Variables

```bash
# .env
ELEVENLABS_API_KEY=your_elevenlabs_api_key
```

## Example 1: Basic Speaker Detection

### Simple Usage

```typescript
import { transcribeWithDiarization } from './lib/diarization';
import { readFile } from 'fs/promises';

async function basicExample() {
  const audioBuffer = await readFile('meeting.mp3');

  const result = await transcribeWithDiarization(audioBuffer, {
    language: 'en'
    expectedSpeakers: 3, // Hint: 3 speakers in this recording
  });

  console.log('Detected speakers:', result.numSpeakersDetected);
  console.log('Total duration:', result.totalDuration, 'seconds');

  // Print speaker statistics
  result.speakers.forEach((speaker) => {
    console.log(`\nSpeaker ${speaker.speakerId}:`);
    console.log(`  Speaking time: ${speaker.totalDuration.toFixed(1)}s`);
    console.log(`  Percentage: ${speaker.percentageOfTotal.toFixed(1)}%`);
    console.log(`  Turns: ${speaker.segmentCount}`);
  });
}

basicExample();
```

### Expected Output

```
Detected speakers: 3
Total duration: 180 seconds

Speaker 0:
  Speaking time: 65.2s
  Percentage: 36.2%
  Turns: 12

Speaker 1:
  Speaking time: 58.8s
  Percentage: 32.7%
  Turns: 15

Speaker 2:
  Speaking time: 56.0s
  Percentage: 31.1%
  Turns: 10
```

## Example 2: Formatted Transcript

### Generate Readable Transcript

```typescript
import { transcribeWithDiarization, formatDiarizedTranscript } from './lib/diarization';

async function formatExample() {
  const audioBuffer = await readFile('meeting.mp3');
  const result = await transcribeWithDiarization(audioBuffer);

  // Generate formatted transcript
  const transcript = formatDiarizedTranscript(result);

  console.log(transcript);

  // Save to file
  await writeFile('transcript.txt', transcript);
  console.log('Transcript saved to transcript.txt');
}
```

### Output Format

```
[0:05] Speaker 0: Hello everyone, thanks for joining today's meeting.

[0:12] Speaker 1: Thanks for having me. Let me share the latest updates.

[0:25] Speaker 1: We've completed the first phase of the project and are moving into testing.

[0:42] Speaker 2: That's great progress. Do we have a timeline for the next phase?

[0:55] Speaker 0: Yes, we're targeting early next month for phase two.
```

## Example 3: Meeting Summary

### Generate Summary Report

```typescript
import { transcribeWithDiarization, generateMeetingSummary } from './lib/diarization';

async function summaryExample() {
  const audioBuffer = await readFile('meeting.mp3');
  const result = await transcribeWithDiarization(audioBuffer, {
    language: 'en'
    expectedSpeakers: 3
  });

  const summary = generateMeetingSummary(result);

  console.log(summary);

  // Save as markdown
  await writeFile('meeting-summary.md', summary);
  console.log('Summary saved to meeting-summary.md');
}
```

### Output Format

```markdown
# Meeting Transcription Summary

## Overview

- Duration: 3m 0s
- Speakers: 3
- Total Segments: 37

## Speaker Breakdown

### Speaker 0

- Speaking Time: 1m 5s (36.2%)
- Turns: 12
- Avg Turn Length: 5s

### Speaker 1

- Speaking Time: 58s (32.7%)
- Turns: 15
- Avg Turn Length: 3s

### Speaker 2

- Speaking Time: 56s (31.1%)
- Turns: 10
- Avg Turn Length: 5s

## Full Transcript

[0:05] Speaker 0: Hello everyone...
```

## Example 4: Speaker Search

### Find Specific Speaker's Contributions

```typescript
import { transcribeWithDiarization, findSpeakerSegments } from './lib/diarization';

async function searchExample() {
  const audioBuffer = await readFile('meeting.mp3');
  const result = await transcribeWithDiarization(audioBuffer);

  // Find all segments from Speaker 1
  const speaker1Segments = findSpeakerSegments(result, 1);

  console.log(`Speaker 1 spoke ${speaker1Segments.length} times:\n`);

  speaker1Segments.forEach((segment, i) => {
    console.log(`${i + 1}. [${segment.startTime.toFixed(1)}s] ${segment.text}`);
  });
}
```

## Example 5: Dialogue Extraction

### Extract Conversation Between Two Speakers

```typescript
import { transcribeWithDiarization, extractDialogue } from './lib/diarization';

async function dialogueExample() {
  const audioBuffer = await readFile('interview.mp3');
  const result = await transcribeWithDiarization(audioBuffer, {
    expectedSpeakers: 2, // Interviewer and interviewee
  });

  // Extract dialogue between Speaker 0 and Speaker 1
  const dialogue = extractDialogue(result, 0, 1);

  console.log('Interview Dialogue:\n');

  dialogue.forEach((segment) => {
    const label = segment.speaker === 0 ? 'Interviewer' : 'Interviewee';
    console.log(`${label}: ${segment.text}\n`);
  });
}
```

## Example 6: Speaker Interactions

### Analyze Turn-Taking Patterns

```typescript
import { transcribeWithDiarization, analyzeSpeakerInteractions } from './lib/diarization';

async function interactionExample() {
  const audioBuffer = await readFile('meeting.mp3');
  const result = await transcribeWithDiarization(audioBuffer);

  const interactions = analyzeSpeakerInteractions(result);

  console.log('Speaker Interaction Patterns:\n');

  interactions.forEach((interaction) => {
    console.log(
      `Speaker ${interaction.from} → Speaker ${interaction.to}: ${interaction.count} times`
    );
  });
}
```

### Output

```
Speaker Interaction Patterns:

Speaker 0 → Speaker 1: 8 times
Speaker 1 → Speaker 2: 7 times
Speaker 2 → Speaker 0: 6 times
Speaker 1 → Speaker 0: 5 times
Speaker 0 → Speaker 2: 4 times
Speaker 2 → Speaker 1: 3 times
```

## Example 7: Export to JSON

### Structured Data Export

```typescript
import { transcribeWithDiarization, exportDiarizedTranscript } from './lib/diarization';

async function exportExample() {
  const audioBuffer = await readFile('meeting.mp3');
  const result = await transcribeWithDiarization(audioBuffer);

  const exportData = exportDiarizedTranscript(result);

  await writeFile('transcript.json', JSON.stringify(exportData, null, 2));

  console.log('Exported to transcript.json');
}
```

### JSON Structure

```json
{
  "metadata": {
    "duration": 180
    "speakers": 3
    "segments": 37
    "generatedAt": "2025-10-29T12:00:00.000Z"
  }
  "speakers": [
    {
      "speakerId": 0
      "totalDuration": 65.2
      "segmentCount": 12
      "averageSegmentDuration": 5.4
      "percentageOfTotal": 36.2
    }
  ]
  "segments": [
    {
      "speaker": 0
      "text": "Hello everyone"
      "startTime": 5.2
      "endTime": 7.8
      "duration": 2.6
    }
  ]
  "fullText": "Hello everyone..."
}
```

## Next.js API Route

### Create Diarization Endpoint

```typescript
// app/api/diarize/route.ts
import { handleDiarizationRequest } from '@/lib/diarization';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const audioFile = formData.get('audio') as File;
    const language = formData.get('language') as string | null;
    const speakersStr = formData.get('speakers') as string | null;
    const format = (formData.get('format') as 'json' | 'text' | 'summary') || 'json';

    if (!audioFile) {
      return NextResponse.json({ error: 'No audio file provided' }, { status: 400 });
    }

    const audioBuffer = Buffer.from(await audioFile.arrayBuffer());

    const result = await handleDiarizationRequest(audioBuffer, {
      language: language || undefined
      expectedSpeakers: speakersStr ? parseInt(speakersStr, 10) : undefined
      format
    });

    return NextResponse.json(result);
  } catch (error) {
    return NextResponse.json(
      {
        error: error instanceof Error ? error.message : 'Unknown error'
      }
      { status: 500 }
    );
  }
}
```

### Client Usage

```typescript
async function transcribeMeeting(audioFile: File) {
  const formData = new FormData();
  formData.append('audio', audioFile);
  formData.append('language', 'en');
  formData.append('speakers', '3');
  formData.append('format', 'summary');

  const response = await fetch('/api/diarize', {
    method: 'POST'
    body: formData
  });

  const result = await response.json();
  return result;
}
```

## React Component

### Meeting Transcription UI

```typescript
'use client';

import { useState } from 'react';

export default function MeetingTranscriber() {
  const [result, setResult] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleTranscribe = async (file: File) => {
    setIsLoading(true);

    try {
      const formData = new FormData();
      formData.append('audio', file);
      formData.append('format', 'json');

      const response = await fetch('/api/diarize', {
        method: 'POST'
        body: formData
      });

      const data = await response.json();
      setResult(data.content);
    } catch (error) {
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Meeting Transcription</h1>

      <input
        type="file"
        accept="audio/*"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) handleTranscribe(file);
        }}
        className="mb-4"
      />

      {isLoading && <p>Transcribing with speaker detection...</p>}

      {result && (
        <div className="space-y-6">
          {/* Overview */}
          <div className="bg-gray-50 p-4 rounded">
            <h2 className="font-bold mb-2">Overview</h2>
            <p>Duration: {result.metadata.duration}s</p>
            <p>Speakers: {result.metadata.speakers}</p>
            <p>Segments: {result.metadata.segments}</p>
          </div>

          {/* Speakers */}
          <div>
            <h2 className="font-bold mb-2">Speakers</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {result.speakers.map((speaker: any) => (
                <div key={speaker.speakerId} className="bg-blue-50 p-4 rounded">
                  <h3 className="font-bold">Speaker {speaker.speakerId}</h3>
                  <p className="text-sm">
                    {speaker.totalDuration.toFixed(1)}s ({speaker.percentageOfTotal.toFixed(1)}%)
                  </p>
                  <p className="text-sm">{speaker.segmentCount} turns</p>
                </div>
              ))}
            </div>
          </div>

          {/* Transcript */}
          <div>
            <h2 className="font-bold mb-2">Transcript</h2>
            <div className="space-y-2">
              {result.segments.map((segment: any, i: number) => (
                <div key={i} className="border-l-4 border-blue-500 pl-4 py-2">
                  <p className="text-xs text-gray-500">
                    Speaker {segment.speaker} • {segment.startTime.toFixed(1)}s
                  </p>
                  <p>{segment.text}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
```

## Advanced Analysis

### Speaker Dominance Visualization

```typescript
function visualizeSpeakerDominance(speakers: SpeakerStats[]) {
  const total = speakers.reduce((sum, s) => sum + s.totalDuration, 0);

  return speakers.map((speaker) => ({
    speaker: speaker.speakerId
    percentage: (speaker.totalDuration / total) * 100
    color: getColorForSpeaker(speaker.speakerId)
  }));
}
```

### Meeting Insights

```typescript
function analyzeMeeting(result: DiarizationResult) {
  const insights = {
    mostActiveSpeaker: result.speakers[0].speakerId
    averageTurnLength:
      result.segments.reduce((sum, s) => sum + s.duration, 0) / result.segments.length
    totalInterruptions: countInterruptions(result.segments)
    speakerBalance: calculateBalance(result.speakers)
  };

  return insights;
}
```

## Tips for Better Results

### Optimize Audio Quality

- Use high-quality recordings (16kHz+ sample rate)
- Minimize background noise
- Ensure clear speaker separation

### Speaker Count

- Provide expected speaker count for better accuracy
- Maximum 32 speakers supported
- Works best with 2-6 speakers

### Language Hints

- Always specify language when known
- Improves accuracy and processing speed
- Supports 30+ languages

## Troubleshooting

### Speakers Not Detected

- Check audio quality
- Verify speaker voices are distinct
- Try adjusting `expectedSpeakers` parameter

### Incorrect Speaker Labels

- Speaker IDs are assigned arbitrarily
- Use speaker statistics to identify who is who
- Consider manual speaker mapping

### Missing Timestamps

- Ensure `enableTimestamps: true`
- Check audio file format compatibility
- Verify API response includes segments

## Learn More

- [ElevenLabs Transcription API](https://elevenlabs.io/docs/api-reference/transcription)
- [Speaker Diarization Overview](https://en.wikipedia.org/wiki/Speaker_diarisation)
- [Audio Processing Best Practices](https://www.audiocheck.net/)
