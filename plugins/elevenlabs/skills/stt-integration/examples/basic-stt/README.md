# Basic STT Example

This example demonstrates the simplest way to transcribe audio using ElevenLabs STT.

## Prerequisites

- ElevenLabs API key set in environment: `ELEVENLABS_API_KEY`
- Audio file to transcribe

## Quick Start

### Using the Script

```bash
# Transcribe with auto-detected language
bash ../../scripts/transcribe-audio.sh audio.mp3

# Transcribe with specific language
bash ../../scripts/transcribe-audio.sh audio.mp3 en

# Save to file
bash ../../scripts/transcribe-audio.sh audio.mp3 en --output=transcription.txt
```

### Using TypeScript

```typescript
import { transcribeAudio } from '../../templates/vercel-ai-transcribe.ts.template';

const result = await transcribeAudio({
  audioPath: './audio.mp3'
  languageCode: 'en'
});

console.log(result.text);
```

### Using Python

```python
from templates.vercel_ai_transcribe import transcribe_audio, TranscriptionConfig

config = TranscriptionConfig(
    audio_path="./audio.mp3"
    language_code="en"
)

result = transcribe_audio(config)
print(result.text)
```

## Supported Audio Formats

### Audio Files
- MP3, WAV, M4A, OGG, FLAC, AAC, AIFF, Opus, WebM

### Video Files
- MP4, AVI, MKV, MOV, WMV, FLV, WebM, MPEG, 3GP

## Language Codes

Common language codes (ISO-639-1):
- `en` - English
- `es` - Spanish
- `fr` - French
- `de` - German
- `ja` - Japanese
- `zh` - Chinese (Mandarin)
- `ar` - Arabic
- `hi` - Hindi
- `pt` - Portuguese
- `ru` - Russian

Leave blank or set to `null` for automatic language detection.

## Examples

### Example 1: Simple Transcription

```bash
# Transcribe English audio
bash ../../scripts/transcribe-audio.sh interview.mp3 en
```

**Output:**
```
Transcribing audio file: interview.mp3
Language: en
Speaker diarization: false
Audio event tagging: true
Timestamps: word

✓ Transcription completed successfully

Transcription:
Hello and welcome to today's podcast. We have an amazing guest with us...
```

### Example 2: Auto Language Detection

```bash
# Let the model detect language automatically
bash ../../scripts/transcribe-audio.sh multilingual.mp3
```

### Example 3: Transcribe Video

```bash
# Extract and transcribe audio from video
bash ../../scripts/transcribe-audio.sh presentation.mp4 en
```

### Example 4: JSON Output

```bash
# Get raw JSON response
bash ../../scripts/transcribe-audio.sh audio.mp3 en --json > result.json
```

## Configuration Options

### Basic Options
- `languageCode` - Language for transcription (e.g., 'en', 'es')
- `tagAudioEvents` - Detect sounds like laughter (default: true)
- `timestampsGranularity` - Level of timestamps: 'none', 'word', 'character'

### File Constraints
- Maximum file size: 3 GB
- Maximum duration: 10 hours
- Files >8 minutes are automatically chunked for faster processing

## Tips for Best Results

1. **Use High-Quality Audio**
   - Sample rate: 16kHz or higher
   - Bitrate: 192 kbps or higher
   - Clear voice, minimal background noise

2. **Specify Language When Known**
   - Improves accuracy
   - Reduces processing time
   - Better for specialized terminology

3. **Choose Appropriate Format**
   - Use lossless formats (WAV, FLAC) for best quality
   - MP3 is fine for most use cases
   - Use `pcm_s16le_16` for lowest latency

4. **Validate Audio First**
   ```bash
   bash ../../scripts/validate-audio.sh audio.mp3
   ```

## Common Issues

### Issue: File Too Large
**Solution:** Compress or split the file
```bash
# Validate first
bash ../../scripts/validate-audio.sh large.mp3 --fix
```

### Issue: Unsupported Format
**Solution:** Convert to MP3
```bash
ffmpeg -i audio.format -acodec libmp3lame -b:a 192k audio.mp3
```

### Issue: Poor Transcription Quality
**Solutions:**
- Use higher quality audio
- Specify correct language code
- Check for background noise
- Ensure audio is not corrupted

## Next Steps

- [Vercel AI SDK Integration](../vercel-ai-stt/README.md) - Use with Vercel AI SDK
- [Speaker Diarization](../diarization/README.md) - Identify multiple speakers
- [Multi-Language](../multi-language/README.md) - Transcribe content in 99 languages
- [Webhook Integration](../webhook-integration/README.md) - Async processing

## Resources

- [ElevenLabs STT Documentation](https://elevenlabs.io/docs/capabilities/speech-to-text)
- [Supported Languages](https://elevenlabs.io/docs/capabilities/speech-to-text#languages)
- [API Reference](https://elevenlabs.io/docs/api-reference/audio-to-text)
