# Voice Library Management Example

Browse, search, and manage voices in the ElevenLabs Voice Library.

## Overview

The Voice Library contains 5,000+ community-contributed voices. This example demonstrates how to discover, preview, and manage voices.

## Browsing Voices

### List All Voices
```bash
bash ../../scripts/list-voices.sh --category all
```

### Filter by Category
```bash
# Cloned voices only
bash ../../scripts/list-voices.sh --category cloned

# Library voices
bash ../../scripts/list-voices.sh --category library

# Default voices
bash ../../scripts/list-voices.sh --category default
```

### Search by Keywords
```bash
bash ../../scripts/list-voices.sh --category library --search "Australian narration"
bash ../../scripts/list-voices.sh --category library --search "female professional"
bash ../../scripts/list-voices.sh --category library --search "British accent"
```

## Managing Your Voices

### Add Voice to Collection
```bash
bash ../../scripts/manage-voice-library.sh \
    --action add \
    --voice-id "YOUR_VOICE_ID" \
    --collection "Narrators" \
    --tags "audiobook,professional"
```

### Share Voice in Library
```bash
# Professional clones only
bash ../../scripts/manage-voice-library.sh \
    --action share \
    --voice-id "YOUR_VOICE_ID" \
    --enable-rewards \
    --description "Professional narrator with neutral American accent" \
    --tags "narrator,audiobook,professional,neutral"
```

### Update Voice Metadata
```bash
bash ../../scripts/manage-voice-library.sh \
    --action update \
    --voice-id "YOUR_VOICE_ID" \
    --description "Updated voice description" \
    --tags "new,tags,here"
```

### Remove from Library
```bash
bash ../../scripts/manage-voice-library.sh \
    --action remove \
    --voice-id "YOUR_VOICE_ID"
```

## Voice Discovery Tips

### Effective Search Terms
- **By Accent**: "British", "Australian", "American Southern", "Indian"
- **By Use Case**: "narration", "character", "conversational", "professional"
- **By Tone**: "warm", "authoritative", "friendly", "serious"
- **By Age**: "young", "mature", "elderly"
- **By Gender**: "male", "female", "neutral"

### Previewing Voices
```bash
# Get voice details
curl -s -X GET \
    "https://api.elevenlabs.io/v1/voices/VOICE_ID" \
    -H "xi-api-key: $ELEVEN_API_KEY" \
    | jq '.'

# Generate preview
curl -X POST \
    "https://api.elevenlabs.io/v1/text-to-speech/VOICE_ID" \
    -H "xi-api-key: $ELEVEN_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"text":"Preview of this voice."}' \
    --output preview.mp3
```

## Monetization

### Earning with Voice Sharing
- Share Professional Voice Clones
- Enable cash rewards
- Earn when others use your voice
- Track usage and earnings in dashboard

### Optimization for Earnings
1. **High Quality**: Ensure professional-grade voice
2. **Clear Description**: Help users find your voice
3. **Relevant Tags**: Use searchable keywords
4. **Unique Voice**: Fill niche not covered by existing voices
5. **Regular Updates**: Keep voice metadata current
