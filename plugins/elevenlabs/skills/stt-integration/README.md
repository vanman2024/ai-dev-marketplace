# STT Integration Skill

Comprehensive Speech-to-Text integration skill for ElevenLabs Scribe v1 model with 99-language support, speaker diarization, and Vercel AI SDK integration.

## Overview

This skill provides complete guidance and tools for implementing ElevenLabs Speech-to-Text (STT) capabilities in your applications, including:

- **Multi-language transcription** - Support for 99 languages with state-of-the-art accuracy
- **Speaker diarization** - Identify and label up to 32 speakers
- **Vercel AI SDK integration** - Seamless TypeScript/JavaScript integration
- **Direct API access** - Python and TypeScript templates for custom implementations
- **Audio validation** - Format checking and quality validation
- **Batch processing** - Transcribe multiple files efficiently

## Quick Start

### 1. Setup

```bash
# Install Vercel AI SDK (TypeScript/JavaScript)
bash scripts/setup-vercel-ai.sh

# Or install Python dependencies
pip install elevenlabs httpx aiofiles
```

### 2. Basic Transcription

```bash
# Transcribe audio file
bash scripts/transcribe-audio.sh audio.mp3 en

# With speaker diarization
bash scripts/transcribe-audio.sh interview.mp3 en --diarize --num-speakers=2
```

### 3. Validate Audio

```bash
# Check if audio is compatible
bash scripts/validate-audio.sh audio.mp3

# Auto-fix issues
bash scripts/validate-audio.sh audio.mp3 --fix
```

### 4. Batch Processing

```bash
# Transcribe all audio files in directory
bash scripts/batch-transcribe.sh ./audio/ en --diarize
```

## Skill Structure

### Scripts (5 functional scripts)

1. **transcribe-audio.sh** - Main transcription with full API integration
   - Auto language detection or specified language
   - Speaker diarization support
   - Audio event tagging
   - JSON or formatted text output

2. **setup-vercel-ai.sh** - Complete setup for Vercel AI SDK
   - Auto-detects package manager (npm/yarn/pnpm)
   - Installs dependencies
   - Creates .env template
   - Configures .gitignore

3. **test-stt.sh** - Comprehensive test suite
   - Environment validation
   - API connectivity tests
   - Audio format validation
   - Integration tests

4. **validate-audio.sh** - Audio file validation and fixing
   - Format compatibility check
   - File size validation (<3GB)
   - Duration check (<10 hours)
   - Audio quality analysis with ffprobe
   - Auto-fix with format conversion

5. **batch-transcribe.sh** - Parallel batch processing
   - Process multiple files
   - Concurrent transcription support
   - Progress tracking
   - Error handling

### Templates (6 comprehensive templates)

1. **stt-config.json.template** - Complete STT configuration
   - All API parameters documented
   - Language support reference
   - Use case examples
   - Best practices

2. **vercel-ai-transcribe.ts.template** - TypeScript with Vercel AI SDK
   - Full type definitions
   - Helper functions
   - Batch processing
   - Progress tracking
   - Speaker diarization helpers
   - Format utilities (SRT, timestamps)

3. **vercel-ai-transcribe.py.template** - Python with Vercel AI SDK
   - Async support
   - Dataclass models
   - Batch processing
   - Speaker extraction
   - Format utilities

4. **api-transcribe.ts.template** - Direct API TypeScript
   - No external dependencies
   - Custom API client class
   - Error handling
   - Batch support

5. **api-transcribe.py.template** - Direct API Python
   - Requests-based implementation
   - Type hints with dataclasses
   - Context manager support
   - SRT generation

6. **diarization-config.json.template** - Speaker diarization reference
   - Configuration options
   - Use case patterns
   - Optimization tips
   - Troubleshooting guide

### Examples (5 comprehensive guides)

1. **basic-stt/** - Simple transcription patterns
   - Quick start guide
   - Language code reference
   - Common issues
   - Tips for best results

2. **vercel-ai-stt/** - Vercel AI SDK integration
   - Installation instructions
   - Usage patterns
   - Next.js API routes
   - React components
   - Error handling
   - Testing examples

3. **diarization/** - Speaker identification
   - Use cases (interview, meeting, panel)
   - Configuration guide
   - Custom speaker labels
   - Speaker statistics
   - Timeline visualization
   - Troubleshooting

4. **multi-language/** - 99-language support
   - Language accuracy tiers
   - Auto-detection vs. specified language
   - Character-based languages (Chinese, Japanese)
   - RTL languages (Arabic, Hebrew)
   - Batch multi-language processing

5. **webhook-integration/** - Async processing
   - Webhook setup (Express, Next.js)
   - Security (signature validation)
   - Database integration
   - Real-time updates (WebSockets)
   - Retry logic
   - Testing with ngrok

## Key Features

### Multi-Language Support

- **99 languages** across 4 accuracy tiers
- **Excellent tier** (≤5% WER): 30 languages including English, Spanish, French, German, Japanese
- **Automatic detection** or explicit language specification
- **Character-level timestamps** for CJK languages

### Speaker Diarization

- Up to **32 speakers** simultaneously
- Automatic or manual speaker count
- Speaker timeline and statistics
- Custom speaker labels
- Word-level timestamps per speaker

### Audio Format Support

**Audio:** AAC, AIFF, OGG, MP3, Opus, WAV, WebM, FLAC, M4A
**Video:** MP4, AVI, Matroska, QuickTime, WMV, FLV, WebM, MPEG, 3GPP

**Limits:**
- Max file size: 3 GB
- Max duration: 10 hours
- Files >8 minutes automatically chunked

### Integration Options

1. **Vercel AI SDK** - Official TypeScript/JavaScript SDK
2. **Direct API** - Custom implementations with full control
3. **Python SDK** - ElevenLabs Python client
4. **Webhooks** - Async processing for long files

## Use Cases

### Podcasts & Interviews
- Transcribe with speaker diarization
- Generate show notes automatically
- Create searchable archives

### Meetings & Conferences
- Record and transcribe team meetings
- Track who said what
- Generate meeting minutes

### Content Creation
- Subtitle generation for videos
- Multi-language subtitle support
- Accessible content creation

### Voice Applications
- Voice note transcription
- Voice command processing
- Customer support call analysis

### Education
- Lecture transcription
- Student Q&A capture
- Multi-language classroom support

## Configuration

### Basic Configuration

```typescript
{
  languageCode: 'en',        // ISO-639 code or null for auto-detect
  diarize: true,             // Enable speaker identification
  numSpeakers: 2,            // Specific speaker count (1-32)
  tagAudioEvents: true,      // Detect laughter, applause
  timestampsGranularity: 'word', // none, word, character
  fileFormat: 'other'        // other or pcm_s16le_16
}
```

### Advanced Options

See `templates/stt-config.json.template` for complete configuration reference including:
- Language support matrix
- Webhook configuration
- Retry policies
- Output formats
- Performance tuning

## Best Practices

### Audio Quality
- Use sample rate ≥16kHz
- Minimize background noise
- Use individual microphones per speaker
- Avoid speaker overlap

### Performance
- Specify language when known (better accuracy)
- Use pcm_s16le_16 for lowest latency
- Set numSpeakers for better diarization
- Use webhooks for files >8 minutes

### Error Handling
- Validate audio before transcription
- Handle API rate limits
- Implement retry logic
- Check file size and duration limits

## Troubleshooting

### Common Issues

1. **File too large** - Use `validate-audio.sh --fix` to compress
2. **Unsupported format** - Convert with ffmpeg or validation script
3. **Poor accuracy** - Check audio quality, specify language
4. **Speakers not detected** - Set numSpeakers explicitly
5. **API errors** - Check ELEVENLABS_API_KEY environment variable

### Testing

```bash
# Run comprehensive test suite
bash scripts/test-stt.sh

# Test with sample audio
bash scripts/transcribe-audio.sh sample.mp3 en --verbose

# Validate setup
bash scripts/test-stt.sh --skip-api  # Skip API calls
```

## Resources

### Documentation
- [SKILL.md](SKILL.md) - Skill manifest with usage instructions
- [ElevenLabs STT Docs](https://elevenlabs.io/docs/capabilities/speech-to-text)
- [Vercel AI SDK Docs](https://ai-sdk.dev/providers/ai-sdk-providers/elevenlabs)

### Scripts
- [scripts/transcribe-audio.sh](scripts/transcribe-audio.sh) - Main transcription
- [scripts/setup-vercel-ai.sh](scripts/setup-vercel-ai.sh) - Setup Vercel AI SDK
- [scripts/test-stt.sh](scripts/test-stt.sh) - Test suite
- [scripts/validate-audio.sh](scripts/validate-audio.sh) - Audio validation
- [scripts/batch-transcribe.sh](scripts/batch-transcribe.sh) - Batch processing

### Templates
- [templates/stt-config.json.template](templates/stt-config.json.template) - Configuration
- [templates/vercel-ai-transcribe.ts.template](templates/vercel-ai-transcribe.ts.template) - TypeScript
- [templates/vercel-ai-transcribe.py.template](templates/vercel-ai-transcribe.py.template) - Python
- [templates/diarization-config.json.template](templates/diarization-config.json.template) - Diarization

### Examples
- [examples/basic-stt/](examples/basic-stt/) - Getting started
- [examples/vercel-ai-stt/](examples/vercel-ai-stt/) - Vercel AI SDK
- [examples/diarization/](examples/diarization/) - Speaker identification
- [examples/multi-language/](examples/multi-language/) - 99 languages
- [examples/webhook-integration/](examples/webhook-integration/) - Async processing

## Version History

**v1.0.0** (2025-10-29)
- Initial release
- 5 functional scripts
- 6 comprehensive templates
- 5 detailed example guides
- Support for 99 languages
- Up to 32 speaker diarization
- Vercel AI SDK integration
- Direct API templates
- Webhook integration examples

## License

This skill is part of the ElevenLabs plugin for Claude Code.

## Support

For issues or questions:
- Check the troubleshooting sections in examples
- Review script comments and documentation
- Validate audio files before transcription
- Test API connectivity with test-stt.sh

---

**Skill Location:** `plugins/elevenlabs/skills/stt-integration/`
**Plugin:** elevenlabs
**Version:** 1.0.0
**Last Updated:** 2025-10-29
