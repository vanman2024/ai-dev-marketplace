# Instant Voice Cloning Example

This example demonstrates the complete workflow for instant voice cloning using ElevenLabs.

## Overview

Instant Voice Cloning (IVC) allows you to quickly create voice clones from brief audio samples (1-5 minutes). This method is ideal for rapid prototyping, testing, and projects where high-fidelity reproduction is not critical.

## Prerequisites

- ElevenLabs API key (Creator plan or higher)
- Audio samples (1-5 minutes total)
- `curl` and `jq` installed
- Python 3.7+ with `pydub` for audio processing

## Step-by-Step Workflow

### Step 1: Prepare Audio Samples

Collect 1-5 minutes of clear audio from the target voice:

```bash
# Check audio quality
python ../../scripts/process-audio.py \
  --input raw_audio.mp3 \
  --info-only \
  --validate
```

Expected output:
```
Audio Information:
  Duration: 180.45 seconds
  Sample Rate: 44100 Hz
  Channels: 2

Validation Warnings:
  ⚠ Sample rate 44100 Hz is acceptable but 22,050 Hz or higher is recommended
```

### Step 2: Process Audio (Optional but Recommended)

Clean up the audio for better cloning results:

```bash
python ../../scripts/process-audio.py \
  --input raw_audio.mp3 \
  --output processed_audio.mp3 \
  --sample-rate 22050 \
  --remove-noise \
  --normalize \
  --trim-silence \
  --validate
```

Expected output:
```
Processing complete!
✓ Audio meets all recommended requirements

Processing Applied:
  ✓ Noise reduction
  ✓ Normalization
  ✓ Silence trimming
  ✓ Sample rate conversion (22050 Hz)
```

### Step 3: Clone the Voice

Use the instant cloning script:

```bash
bash ../../scripts/clone-voice.sh \
  --name "Demo Voice" \
  --method instant \
  --files "processed_audio.mp3" \
  --description "Professional narrator voice for demo"
```

Expected output:
```
ElevenLabs Voice Cloning
=========================
Voice Name: Demo Voice
Method: instant

Validating audio files...
✓ processed_audio.mp3 (2.5MB)

Cloning voice...
✓ Voice cloned successfully!

Voice ID: 7xK8J9mNqP4vZ2wL3dR5
Voice Name: Demo Voice
Method: instant
```

### Step 4: Test the Cloned Voice

Generate a test audio file:

```bash
export VOICE_ID="7xK8J9mNqP4vZ2wL3dR5"
export ELEVEN_API_KEY="your_api_key"

curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
  -H "xi-api-key: ${ELEVEN_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello! This is my cloned voice using instant voice cloning. How does it sound?"
    "model_id": "eleven_monolingual_v1"
  }' \
  --output test_output.mp3

# Play the audio
# macOS: afplay test_output.mp3
# Linux: mpv test_output.mp3 or vlc test_output.mp3
```

### Step 5: Adjust Voice Settings (If Needed)

Fine-tune the voice characteristics:

```bash
# Get current settings
bash ../../scripts/configure-voice-settings.sh \
  --voice-id "${VOICE_ID}" \
  --get-current

# Apply narration preset
bash ../../scripts/configure-voice-settings.sh \
  --voice-id "${VOICE_ID}" \
  --stability 0.8 \
  --similarity 0.75 \
  --style 0.0
```

## Complete Example Script

See `clone-workflow.sh` for a complete automated workflow.

## Audio Requirements

### Minimum Requirements
- **Duration**: 1 minute minimum, 3-5 minutes recommended
- **Sample Rate**: 16,000 Hz minimum, 22,050 Hz recommended
- **Format**: MP3, WAV, FLAC, or OGG
- **Quality**: Clear speech with minimal background noise

### Best Practices
- Use multiple shorter files (30s-2min each) rather than one long file
- Vary intonation and emotion across samples
- Record in consistent environment
- Avoid music, effects, or other speakers
- Include natural pauses and breathing

## Common Use Cases

### 1. Audiobook Narration
```bash
bash ../../scripts/clone-voice.sh \
  --name "Audiobook Narrator" \
  --method instant \
  --files "narrator_sample1.mp3,narrator_sample2.mp3" \
  --description "Professional audiobook narrator"

# Apply narration settings
bash ../../scripts/configure-voice-settings.sh \
  --voice-id "${VOICE_ID}" \
  --stability 0.85 \
  --similarity 0.8 \
  --style 0.0
```

### 2. Conversational AI
```bash
bash ../../scripts/clone-voice.sh \
  --name "AI Assistant Voice" \
  --method instant \
  --files "assistant_samples.mp3" \
  --description "Friendly conversational AI voice"

# Apply dialogue settings
bash ../../scripts/configure-voice-settings.sh \
  --voice-id "${VOICE_ID}" \
  --stability 0.5 \
  --similarity 0.8 \
  --style 0.2
```

### 3. Character Voice
```bash
bash ../../scripts/clone-voice.sh \
  --name "Character Voice" \
  --method instant \
  --files "character_samples.mp3" \
  --description "Energetic character for animation"

# Apply character settings
bash ../../scripts/configure-voice-settings.sh \
  --voice-id "${VOICE_ID}" \
  --stability 0.3 \
  --similarity 0.7 \
  --style 0.6
```

## Troubleshooting

### Clone Quality is Poor
- **Solution**: Increase audio sample duration (aim for 3-5 minutes)
- **Solution**: Process audio to remove noise and normalize levels
- **Solution**: Use multiple audio files instead of one long file
- **Solution**: Consider upgrading to Professional Voice Cloning

### Voice Sounds Robotic
- **Solution**: Lower stability parameter (try 0.4-0.6)
- **Solution**: Increase style parameter for more expressiveness
- **Solution**: Ensure original samples have varied intonation

### Voice Doesn't Match Original
- **Solution**: Increase similarity boost (try 0.85-0.95)
- **Solution**: Use higher quality audio samples
- **Solution**: Ensure samples are from the same recording environment

### API Errors
- **Solution**: Verify API key has Creator plan or higher
- **Solution**: Check audio files are not corrupted
- **Solution**: Ensure file sizes are within limits (< 10MB per file)

## Next Steps

1. **Professional Cloning**: For higher quality, see `../professional-cloning/`
2. **Voice Library**: Share your voice, see `../voice-library/`
3. **Settings Optimization**: Fine-tune parameters, see `../voice-settings-optimization/`

## Resources

- [ElevenLabs Instant Voice Cloning Guide](https://elevenlabs.io/docs/cookbooks/voices/instant-voice-cloning)
- [Voice API Reference](https://elevenlabs.io/docs/api-reference/voices)
- [Audio Processing Best Practices](../../README.md#voice-cloning-best-practices)
