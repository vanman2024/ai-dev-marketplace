# Professional Voice Cloning Training Guide

This guide provides best practices for recording and preparing training audio for professional voice cloning.

## Recording Equipment

### Recommended Setup
- **Microphone**: Condenser microphone (USB or XLR)
  - Budget: Blue Yeti, Audio-Technica AT2020
  - Professional: Neumann TLM 103, Shure SM7B
- **Audio Interface**: Focusrite Scarlett 2i2, PreSonus AudioBox (for XLR mics)
- **Headphones**: Closed-back monitoring headphones
- **Pop Filter**: Essential for reducing plosives
- **Acoustic Treatment**: Foam panels or portable vocal booth

### Recording Environment
- **Room**: Small to medium room with soft furnishings
- **Noise Control**: Turn off AC, fans, refrigerator during recording
- **Sound Treatment**: Use blankets, pillows, or acoustic foam to reduce reflections
- **Time of Day**: Record when ambient noise is lowest (early morning/late night)

## Recording Settings

### DAW/Software Settings
- **Sample Rate**: 44.1 kHz or 48 kHz
- **Bit Depth**: 24-bit
- **Format**: WAV or FLAC (lossless)
- **Buffer Size**: 256-512 samples for low latency

### Microphone Settings
- **Gain**: Set to avoid clipping (peaks at -12 to -6 dB)
- **Pattern**: Cardioid (for single speaker)
- **Distance**: 6-12 inches from microphone
- **Angle**: Slightly off-axis to reduce plosives

## Content Planning

### Training Audio Structure

**Total Duration Target: 30-60 minutes**

1. **Neutral/Conversational (40%)**: 12-24 minutes
   - Natural conversation
   - Storytelling
   - Casual narration

2. **Expressive/Emotional (30%)**: 9-18 minutes
   - Happy, excited, enthusiastic
   - Sad, concerned, empathetic
   - Serious, authoritative
   - Surprised, questioning

3. **Formal/Professional (15%)**: 4.5-9 minutes
   - Business presentations
   - Technical descriptions
   - News-style delivery

4. **Dynamic Range (15%)**: 4.5-9 minutes
   - Whispers to normal volume
   - Quiet to loud speech
   - Slow to fast pacing

### Sample Scripts

Create scripts covering various styles:

**Conversational**
```
"Hey, how's it going? I wanted to tell you about something interesting
I learned today. You know how we were talking about voice cloning? Well,
the technology has really come a long way..."
```

**Expressive - Happy**
```
"This is absolutely incredible! I can't believe how well this works.
It's like magic, but it's real technology. I'm so excited to see
where this goes next!"
```

**Expressive - Serious**
```
"We need to take this seriously. The implications of this technology
are significant, and we have a responsibility to use it ethically
and thoughtfully."
```

**Professional**
```
"Today's presentation covers the quarterly financial results, including
revenue growth of 15 percent year-over-year, and operating margins
that exceeded our projected targets."
```

**Technical**
```
"The audio processing pipeline utilizes a sample rate of 44.1 kilohertz,
with 24-bit depth encoding. The compression algorithm employs variable
bitrate encoding for optimal quality."
```

## Recording Workflow

### Pre-Recording Checklist
- [ ] Test microphone levels (speak at normal volume, check peaks)
- [ ] Eliminate background noise sources
- [ ] Position pop filter correctly
- [ ] Have water nearby (for dry mouth)
- [ ] Warm up voice (hum, vocal exercises)
- [ ] Review script and practice delivery

### Recording Session
1. **Record Room Tone**: 30 seconds of silence for noise profiling
2. **Slate Each Take**: "Take 1, conversational style"
3. **Record Multiple Takes**: 2-3 takes per script segment
4. **Take Breaks**: Every 15-20 minutes to maintain voice quality
5. **Stay Hydrated**: Sip water between takes
6. **Monitor Quality**: Check recordings for issues

### Post-Recording
1. **Listen to All Recordings**: Quality check
2. **Select Best Takes**: Choose clearest, most natural performances
3. **Export Selected Takes**: WAV or FLAC format
4. **Organize Files**: Name clearly (e.g., "01_conversational.wav")

## Audio Quality Standards

### Must-Have Qualities
- **Clear Speech**: Every word easily intelligible
- **Consistent Volume**: No significant level changes
- **Low Noise Floor**: Minimal background noise (-60 dB or lower)
- **No Clipping**: Peaks below 0 dB (ideally -6 dB or lower)
- **Consistent Tone**: Similar voice quality across all files

### Avoid These Issues
- **Plosives**: "P" and "B" sounds causing mic overload
- **Sibilance**: Harsh "S" sounds
- **Room Reverb**: Echoey, hollow sound
- **Mouth Clicks**: Dry mouth sounds
- **Breathing Sounds**: Loud inhales/exhales
- **Rustling**: Paper, clothing, or movement noise

## File Organization

### Recommended Structure
```
training_audio/
├── 01_neutral/
│   ├── conversation_01.wav
│   ├── conversation_02.wav
│   ├── narration_01.wav
│   └── storytelling_01.wav
├── 02_expressive/
│   ├── happy_01.wav
│   ├── excited_01.wav
│   ├── serious_01.wav
│   └── empathetic_01.wav
├── 03_professional/
│   ├── presentation_01.wav
│   ├── technical_01.wav
│   └── formal_01.wav
├── 04_dynamic/
│   ├── whisper_01.wav
│   ├── loud_01.wav
│   ├── fast_paced_01.wav
│   └── slow_paced_01.wav
└── room_tone.wav
```

### Naming Convention
```
[sequence]_[category]_[description].wav

Examples:
01_neutral_conversation.wav
02_expressive_happy.wav
03_professional_presentation.wav
04_dynamic_whisper.wav
```

## Processing Pipeline

### Before Cloning

1. **Normalize Levels**: Target -20 dB RMS
2. **Remove Noise**: Apply noise reduction using room tone
3. **Trim Silence**: Remove long pauses at start/end
4. **Check Sample Rate**: Convert to 44.1 kHz or 22.05 kHz
5. **Convert Format**: MP3 at 128-192 kbps (from WAV/FLAC)

### Using Processing Scripts

```bash
# Process all training audio
for file in training_audio/*/*.wav; do
    output="processed_training/$(basename "$file" .wav).mp3"

    python ../../scripts/process-audio.py \
        --input "$file" \
        --output "$output" \
        --sample-rate 44100 \
        --remove-noise \
        --normalize \
        --trim-silence \
        --format mp3 \
        --bitrate 192k
done
```

## Common Mistakes to Avoid

### Recording Mistakes
1. **Inconsistent Mic Distance**: Stay same distance throughout
2. **Varying Voice Energy**: Maintain consistent vocal effort
3. **Different Rooms**: Record all audio in same location
4. **Equipment Changes**: Don't switch microphones mid-project
5. **Inadequate Warmup**: Voice quality improves after warmup

### Content Mistakes
1. **Not Enough Variety**: Need diverse emotional range
2. **Too Monotone**: Include expressive content
3. **Insufficient Duration**: Less than 30 minutes reduces quality
4. **Poor Script Quality**: Unnatural, stilted language
5. **Reading vs Speaking**: Should sound conversational, not read

### Technical Mistakes
1. **Clipping Audio**: Recording too loud
2. **Noisy Recordings**: Background hum, AC, traffic
3. **Overprocessing**: Too much compression/EQ
4. **Wrong Sample Rate**: Recording at 8 kHz or very low rates
5. **Lossy Source**: Using MP3 as recording format

## Quality Verification

### Pre-Upload Checklist
- [ ] Total duration: 30+ minutes
- [ ] All files: Clear and intelligible
- [ ] Consistent: Same voice quality across files
- [ ] Variety: Multiple emotions and styles
- [ ] Processed: Noise reduced and normalized
- [ ] Organized: Clearly named and structured
- [ ] Tested: Listened to all files in full

### Testing Protocol

```bash
# Validate all files
for file in processed_training/*.mp3; do
    echo "Checking: $file"
    python ../../scripts/process-audio.py \
        --input "$file" \
        --info-only \
        --validate
done
```

## Resources

### Recording Software (Free)
- **Audacity**: Cross-platform audio editor
- **Reaper**: DAW with free trial
- **GarageBand**: Mac users
- **Ocenaudio**: Simple audio editor

### Learning Resources
- Voice recording techniques for podcasting
- Home studio acoustic treatment guides
- Microphone placement tutorials
- Voice acting training (for expressiveness)

## Timeline

### Typical Project Schedule
- **Day 1-2**: Script writing and preparation
- **Day 3-4**: Recording sessions (multiple sessions)
- **Day 5**: Review and select best takes
- **Day 6**: Audio processing and cleanup
- **Day 7**: Upload and initiate professional cloning
- **Day 8-10**: Wait for training to complete
- **Day 11**: Test and fine-tune settings

Total: ~2 weeks from start to finished professional voice clone

---

Remember: Quality matters more than quantity. Better to have 30 minutes of excellent audio than 60 minutes of mediocre recordings.
