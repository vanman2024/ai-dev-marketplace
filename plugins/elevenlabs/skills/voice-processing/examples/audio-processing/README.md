# Audio Processing Examples

Prepare and optimize audio files for voice cloning.

## Quick Start

### Basic Processing
```bash
python ../../scripts/process-audio.py \
    --input raw_audio.mp3 \
    --output processed_audio.mp3 \
    --sample-rate 22050 \
    --remove-noise \
    --normalize
```

### Audio Information
```bash
python ../../scripts/process-audio.py \
    --input audio.mp3 \
    --info-only
```

### Validation for Cloning
```bash
python ../../scripts/process-audio.py \
    --input audio.mp3 \
    --info-only \
    --validate
```

## Processing Pipelines

### Instant Cloning Preset
```bash
python ../../scripts/process-audio.py \
    --input raw.mp3 \
    --output instant_ready.mp3 \
    --sample-rate 22050 \
    --remove-noise \
    --normalize \
    --trim-silence \
    --bitrate 128k
```

### Professional Cloning Preset
```bash
python ../../scripts/process-audio.py \
    --input raw.mp3 \
    --output pro_ready.mp3 \
    --sample-rate 44100 \
    --remove-noise \
    --normalize \
    --trim-silence \
    --format wav
```

### Batch Processing
```bash
# Process all files in directory
for file in raw_audio/*.mp3; do
    output="processed/$(basename "$file")"
    python ../../scripts/process-audio.py \
        --input "$file" \
        --output "$output" \
        --sample-rate 22050 \
        --remove-noise \
        --normalize \
        --trim-silence
done
```

## Format Conversion

### MP3 to WAV
```bash
python ../../scripts/process-audio.py \
    --input audio.mp3 \
    --output audio.wav \
    --format wav
```

### WAV to MP3
```bash
python ../../scripts/process-audio.py \
    --input audio.wav \
    --output audio.mp3 \
    --format mp3 \
    --bitrate 192k
```

## Troubleshooting

### Audio Too Quiet
```bash
python ../../scripts/process-audio.py \
    --input quiet.mp3 \
    --output normalized.mp3 \
    --normalize
```

### Background Noise
```bash
python ../../scripts/process-audio.py \
    --input noisy.mp3 \
    --output clean.mp3 \
    --remove-noise
```

### Long Silence
```bash
python ../../scripts/process-audio.py \
    --input silence.mp3 \
    --output trimmed.mp3 \
    --trim-silence \
    --silence-thresh -40
```

See complete examples in batch-process.sh
