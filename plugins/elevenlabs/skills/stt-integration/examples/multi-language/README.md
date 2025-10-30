# Multi-Language Transcription Example

This example demonstrates how to use ElevenLabs STT with 99 supported languages, from automatic language detection to multi-language content transcription.

## Language Support Overview

ElevenLabs Scribe v1 supports **99 languages** across 4 accuracy tiers:

- **Excellent (≤5% WER)**: 30 languages
- **High (>5-10% WER)**: 19 languages
- **Good (>10-25% WER)**: 30 languages
- **Moderate (>25-50% WER)**: 19 languages

WER = Word Error Rate (lower is better)

## Quick Start

### Auto Language Detection

```bash
# Let the model detect language automatically
bash ../../scripts/transcribe-audio.sh multilingual-audio.mp3
```

### Specific Language

```bash
# Spanish
bash ../../scripts/transcribe-audio.sh audio-es.mp3 es

# Japanese
bash ../../scripts/transcribe-audio.sh audio-ja.mp3 ja

# Arabic
bash ../../scripts/transcribe-audio.sh audio-ar.mp3 ar
```

## Supported Languages

### Excellent Accuracy (≤5% WER)

| Code | Language | Code | Language |
|------|----------|------|----------|
| `en` | English | `ja` | Japanese |
| `fr` | French | `pt` | Portuguese |
| `de` | German | `nl` | Dutch |
| `es` | Spanish | `pl` | Polish |
| `it` | Italian | `ru` | Russian |

**All 30 Excellent Languages:**
en, fr, de, es, it, ja, pt, nl, pl, ru, ar, cs, da, fi, el, he, hu, ko, no, ro, sk, sv, tr, uk, bg, ca, hr, et, lv, lt

### High Accuracy (>5-10% WER)

| Code | Language | Code | Language |
|------|----------|------|----------|
| `bn` | Bengali | `ta` | Tamil |
| `zh` | Chinese (Mandarin) | `te` | Telugu |
| `hi` | Hindi | `vi` | Vietnamese |

**All 19 High Accuracy Languages:**
bn, zh, ta, te, vi, id, th, mr, kn, ml, gu, fa, ur, sw, pa, jv, is, gl, eu

### Good Accuracy (>10-25% WER)

**30 languages including:**
af, az, be, bs, cy, eo, tl, ka, ha, hy, kk, km, lo, lb, mk, ms, mt, mn, ne, ps, si, sl, so, sq, sr, su, tg, uz, yi

### Moderate Accuracy (>25-50% WER)

**19 languages including:**
am, my, ht, ig, mg, mi, om, sa, sd, sm, sn, st, to, ug, xh, yo

## Usage Examples

### Example 1: Auto Language Detection

Best for unknown or mixed-language content.

```typescript
import { transcribeAudio } from '../../templates/vercel-ai-transcribe.ts.template';

const result = await transcribeAudio({
  audioPath: './unknown-language.mp3',
  // No languageCode - automatic detection
});

console.log('Transcription:', result.text);
```

```bash
# Shell script
bash ../../scripts/transcribe-audio.sh unknown-language.mp3
```

### Example 2: Spanish Transcription

```typescript
const result = await transcribeAudio({
  audioPath: './audio-spanish.mp3',
  languageCode: 'es',
  diarize: true,
});

console.log(formatTranscriptWithSpeakers(result));
```

### Example 3: Japanese with Diarization

```typescript
const result = await transcribeAudio({
  audioPath: './interview-japanese.mp3',
  languageCode: 'ja',
  diarize: true,
  numSpeakers: 2,
});

console.log(formatTranscriptWithSpeakers(result));
```

### Example 4: Arabic (Right-to-Left)

```typescript
const result = await transcribeAudio({
  audioPath: './audio-arabic.mp3',
  languageCode: 'ar',
});

// Arabic text (RTL)
console.log(result.text);
```

### Example 5: Chinese (Mandarin)

```typescript
const result = await transcribeAudio({
  audioPath: './audio-chinese.mp3',
  languageCode: 'zh',
  timestampsGranularity: 'character', // Character-level for Chinese
});

console.log(result.text);
```

## Batch Processing Multi-Language Content

```typescript
import { transcribeBatch } from '../../templates/vercel-ai-transcribe.ts.template';

const files = [
  { path: './audio-en.mp3', language: 'en' },
  { path: './audio-es.mp3', language: 'es' },
  { path: './audio-ja.mp3', language: 'ja' },
  { path: './audio-ar.mp3', language: 'ar' },
];

for (const file of files) {
  const result = await transcribeAudio({
    audioPath: file.path,
    languageCode: file.language,
  });

  console.log(`\n=== ${file.language.toUpperCase()} ===`);
  console.log(result.text);
}
```

```bash
# Shell script batch processing
bash ../../scripts/batch-transcribe.sh ./audio-multilingual/ --pattern="*.mp3"
```

## Language-Specific Configurations

### Character-Based Languages (Chinese, Japanese, Korean)

```typescript
// For better timestamps in character-based languages
const result = await transcribeAudio({
  audioPath: './audio-chinese.mp3',
  languageCode: 'zh',
  timestampsGranularity: 'character',
});
```

### Right-to-Left Languages (Arabic, Hebrew, Urdu)

```typescript
const result = await transcribeAudio({
  audioPath: './audio-arabic.mp3',
  languageCode: 'ar',
});

// Text will be in correct RTL format
// Display in RTL-aware UI components
```

### Tonal Languages (Mandarin, Thai, Vietnamese)

```typescript
// Use high-quality audio for tonal accuracy
const result = await transcribeAudio({
  audioPath: './audio-mandarin.mp3',
  languageCode: 'zh',
  fileFormat: 'pcm_s16le_16', // Best quality for tonal languages
});
```

## Multi-Language Detection Strategy

When to use auto-detection vs. specified language:

### Use Auto-Detection When:
- Language is unknown
- Content may switch between languages
- Testing different language audio files
- User-uploaded content

```typescript
// Let model detect language
const result = await transcribeAudio({
  audioPath: './user-upload.mp3',
  // No languageCode
});
```

### Specify Language When:
- Language is known
- Need best accuracy
- Working with specialized terminology
- Batch processing same-language files

```typescript
// Specify for better accuracy
const result = await transcribeAudio({
  audioPath: './spanish-podcast.mp3',
  languageCode: 'es', // Known Spanish content
});
```

## Language Code Reference

### ISO-639-1 (2-letter codes)

Most common languages use 2-letter codes:
```
en - English       es - Spanish       fr - French
de - German        it - Italian       ja - Japanese
pt - Portuguese    ru - Russian       ar - Arabic
zh - Chinese       hi - Hindi         ko - Korean
```

### ISO-639-3 (3-letter codes)

Some languages use 3-letter codes:
```
ben - Bengali      tam - Tamil        tel - Telugu
guj - Gujarati     mar - Marathi      kan - Kannada
mal - Malayalam    urd - Urdu         fas - Persian
```

## Best Practices

### 1. Specify Language When Known

```typescript
// ✅ Better accuracy
const result = await transcribeAudio({
  audioPath: './french-audio.mp3',
  languageCode: 'fr', // Known French
});

// ⚠️ Works but less accurate
const result = await transcribeAudio({
  audioPath: './french-audio.mp3',
  // Auto-detect (slower, less accurate)
});
```

### 2. Use Appropriate Timestamp Granularity

```typescript
// For word-based languages (English, Spanish, etc.)
timestampsGranularity: 'word'

// For character-based languages (Chinese, Japanese)
timestampsGranularity: 'character'
```

### 3. Handle Language-Specific Characters

```typescript
// Save with UTF-8 encoding for non-Latin scripts
import { writeFile } from 'fs/promises';

const result = await transcribeAudio({
  audioPath: './audio-japanese.mp3',
  languageCode: 'ja',
});

// Save with UTF-8 encoding
await writeFile('transcript.txt', result.text, 'utf-8');
```

## Advanced Use Cases

### Use Case 1: Video Subtitle Generation

```typescript
async function generateMultilingualSubtitles(videoPath: string, languages: string[]) {
  for (const lang of languages) {
    const result = await transcribeAudio({
      audioPath: videoPath,
      languageCode: lang,
    });

    const srt = formatAsSRT(result.segments);
    await writeFile(`subtitles-${lang}.srt`, srt, 'utf-8');
  }
}

await generateMultilingualSubtitles('./video.mp4', ['en', 'es', 'fr', 'ja']);
```

### Use Case 2: Translation Pipeline

```typescript
// Step 1: Transcribe in original language
const transcription = await transcribeAudio({
  audioPath: './spanish-audio.mp3',
  languageCode: 'es',
});

// Step 2: Translate to target languages
// (Use translation service here)

// Step 3: Generate TTS in target languages
// (Use ElevenLabs TTS)
```

### Use Case 3: Language Learning Application

```typescript
async function analyzeLanguageLearning(audioPath: string, expectedLanguage: string) {
  const result = await transcribeAudio({
    audioPath,
    languageCode: expectedLanguage,
  });

  // Check pronunciation, grammar, etc.
  return {
    transcription: result.text,
    wordCount: result.text.split(' ').length,
    duration: result.duration,
    // Add language analysis
  };
}
```

## Troubleshooting

### Problem: Wrong Language Detected

**Solution:** Explicitly specify language code
```typescript
// Instead of auto-detect
const result = await transcribeAudio({
  audioPath: './audio.mp3',
  languageCode: 'ja', // Specify Japanese
});
```

### Problem: Poor Accuracy in Certain Languages

**Solutions:**
1. Check language tier (moderate tier = lower accuracy)
2. Improve audio quality
3. Use higher sample rate (≥16kHz)
4. Reduce background noise

### Problem: Special Characters Not Displaying

**Solution:** Ensure UTF-8 encoding
```typescript
// Save with explicit UTF-8
await writeFile('transcript.txt', result.text, { encoding: 'utf-8' });

// Display in browser with correct meta tag
// <meta charset="UTF-8">
```

## Testing Different Languages

```bash
# Create test suite for multiple languages
bash ../../scripts/test-stt.sh

# Test specific language
bash ../../scripts/transcribe-audio.sh test-audio-es.mp3 es --verbose
```

## Language Detection Confidence

While the API doesn't return confidence scores, you can validate:

```typescript
async function validateLanguage(audioPath: string, expectedLang: string) {
  // Try with auto-detect
  const autoResult = await transcribeAudio({ audioPath });

  // Try with specified language
  const specifiedResult = await transcribeAudio({
    audioPath,
    languageCode: expectedLang,
  });

  // Compare results
  return {
    autoDetected: autoResult.text,
    specified: specifiedResult.text,
    match: autoResult.text.length > 0 && specifiedResult.text.length > 0,
  };
}
```

## Language Performance Comparison

```typescript
async function compareLanguageAccuracy(audioPath: string, languages: string[]) {
  const results = {};

  for (const lang of languages) {
    const start = Date.now();

    const result = await transcribeAudio({
      audioPath,
      languageCode: lang,
    });

    results[lang] = {
      text: result.text,
      wordCount: result.text.split(/\s+/).length,
      processingTime: Date.now() - start,
    };
  }

  return results;
}

// Test same audio with different language hints
const comparison = await compareLanguageAccuracy('./audio.mp3', ['en', 'es', 'fr']);
console.log(comparison);
```

## Resources

- [Full Language List](../../templates/stt-config.json.template) - See `languageSupport` section
- [Language Codes (ISO-639)](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
- [ElevenLabs Language Documentation](https://elevenlabs.io/docs/capabilities/speech-to-text#languages)

## Next Steps

- [Basic STT Example](../basic-stt/README.md) - Simple transcription
- [Diarization Example](../diarization/README.md) - Multi-language with speaker identification
- [Webhook Integration](../webhook-integration/README.md) - Async processing for long files
