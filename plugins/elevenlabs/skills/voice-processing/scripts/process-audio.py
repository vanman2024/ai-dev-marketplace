#!/usr/bin/env python3
"""
process-audio.py - Audio processing for ElevenLabs voice cloning

Usage:
    python process-audio.py --input audio.mp3 --output processed.mp3 --sample-rate 22050
    python process-audio.py --input audio.mp3 --output processed.mp3 --remove-noise --normalize
"""

import argparse
import os
import sys
import json
from pathlib import Path

# Check for required dependencies
try:
    from pydub import AudioSegment
    from pydub.effects import normalize as pydub_normalize
    from pydub.silence import detect_silence
except ImportError:
    print("Error: pydub not installed. Install with: pip install pydub", file=sys.stderr)
    sys.exit(1)

# Optional dependencies
try:
    import numpy as np
    NUMPY_AVAILABLE = True
except ImportError:
    NUMPY_AVAILABLE = False
    print("Warning: numpy not available. Some features will be limited.", file=sys.stderr)

try:
    import noisereduce as nr
    NOISE_REDUCE_AVAILABLE = True
except ImportError:
    NOISE_REDUCE_AVAILABLE = False


# Color codes for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color


def print_colored(message, color):
    """Print colored message to terminal"""
    print(f"{color}{message}{Colors.NC}")


def validate_audio_file(file_path):
    """Validate audio file exists and is readable"""
    if not os.path.exists(file_path):
        print_colored(f"Error: Input file not found: {file_path}", Colors.RED)
        return False

    if not os.path.isfile(file_path):
        print_colored(f"Error: Path is not a file: {file_path}", Colors.RED)
        return False

    file_size = os.path.getsize(file_path)
    if file_size < 1000:
        print_colored(f"Warning: File appears very small: {file_size} bytes", Colors.YELLOW)

    return True


def get_audio_info(audio):
    """Get audio file information"""
    return {
        'duration_seconds': len(audio) / 1000.0,
        'channels': audio.channels,
        'sample_rate': audio.frame_rate,
        'sample_width': audio.sample_width,
        'frame_count': audio.frame_count(),
        'size_bytes': len(audio.raw_data)
    }


def convert_format(audio, output_format):
    """Convert audio to specified format"""
    print(f"Converting to {output_format.upper()} format...")
    # Format conversion is handled by pydub's export
    return audio


def change_sample_rate(audio, target_rate):
    """Change audio sample rate"""
    if audio.frame_rate == target_rate:
        print(f"Sample rate already {target_rate} Hz, skipping conversion")
        return audio

    print(f"Converting sample rate: {audio.frame_rate} Hz -> {target_rate} Hz...")
    return audio.set_frame_rate(target_rate)


def remove_noise(audio):
    """Remove noise from audio using noise reduction"""
    if not NOISE_REDUCE_AVAILABLE:
        if not NUMPY_AVAILABLE:
            print_colored("Warning: Noise reduction requires noisereduce and numpy libraries", Colors.YELLOW)
            print_colored("Install with: pip install noisereduce numpy", Colors.YELLOW)
            return audio
        else:
            print_colored("Warning: Noise reduction requires noisereduce library", Colors.YELLOW)
            print_colored("Install with: pip install noisereduce", Colors.YELLOW)
            return audio

    print("Removing noise...")

    # Convert to numpy array
    samples = np.array(audio.get_array_of_samples())

    # Handle stereo audio
    if audio.channels == 2:
        samples = samples.reshape((-1, 2))

    # Apply noise reduction
    reduced_noise = nr.reduce_noise(
        y=samples,
        sr=audio.frame_rate,
        stationary=True,
        prop_decrease=0.8
    )

    # Convert back to AudioSegment
    if audio.channels == 2:
        reduced_noise = reduced_noise.flatten()

    # Ensure correct data type
    reduced_noise = reduced_noise.astype(np.int16)

    # Create new AudioSegment
    audio_cleaned = AudioSegment(
        reduced_noise.tobytes(),
        frame_rate=audio.frame_rate,
        sample_width=audio.sample_width,
        channels=audio.channels
    )

    return audio_cleaned


def normalize_audio(audio):
    """Normalize audio levels"""
    print("Normalizing audio...")
    return pydub_normalize(audio)


def trim_silence(audio, silence_thresh=-40, chunk_size=10):
    """Trim silence from beginning and end of audio"""
    print("Trimming silence...")

    # Detect silence at start and end
    silence_ranges = detect_silence(
        audio,
        min_silence_len=500,
        silence_thresh=silence_thresh,
        seek_step=chunk_size
    )

    if not silence_ranges:
        print("No silence detected to trim")
        return audio

    # Calculate trim points
    start_trim = 0
    end_trim = len(audio)

    # Find first non-silent region
    if silence_ranges and silence_ranges[0][0] == 0:
        start_trim = silence_ranges[0][1]

    # Find last non-silent region
    if silence_ranges and silence_ranges[-1][1] >= len(audio) - 100:
        end_trim = silence_ranges[-1][0]

    if start_trim > 0 or end_trim < len(audio):
        print(f"Trimming: {start_trim}ms from start, {len(audio) - end_trim}ms from end")
        return audio[start_trim:end_trim]

    return audio


def validate_for_cloning(audio):
    """Validate audio meets ElevenLabs cloning requirements"""
    print("\nValidating audio for voice cloning...")

    info = get_audio_info(audio)
    issues = []
    warnings = []

    # Duration check
    duration = info['duration_seconds']
    if duration < 30:
        warnings.append(f"Audio is short ({duration:.1f}s). Recommended: 30s-300s for instant, 30min+ for professional")
    elif duration < 60:
        warnings.append(f"Audio duration ({duration:.1f}s) is on the shorter side. Longer samples improve quality")

    # Sample rate check
    sample_rate = info['sample_rate']
    if sample_rate < 16000:
        issues.append(f"Sample rate too low: {sample_rate} Hz. Minimum: 16,000 Hz, Recommended: 22,050 Hz or higher")
    elif sample_rate < 22050:
        warnings.append(f"Sample rate {sample_rate} Hz is acceptable but 22,050 Hz or higher is recommended")

    # Channel check
    if info['channels'] > 2:
        issues.append(f"Too many channels: {info['channels']}. Convert to mono or stereo")

    # Print validation results
    if issues:
        print_colored("\nValidation Issues (must fix):", Colors.RED)
        for issue in issues:
            print(f"  ✗ {issue}")

    if warnings:
        print_colored("\nValidation Warnings (recommended improvements):", Colors.YELLOW)
        for warning in warnings:
            print(f"  ⚠ {warning}")

    if not issues and not warnings:
        print_colored("✓ Audio meets all recommended requirements", Colors.GREEN)

    return len(issues) == 0


def main():
    parser = argparse.ArgumentParser(
        description='Process audio files for ElevenLabs voice cloning'
    )

    # Input/output
    parser.add_argument('--input', required=True, help='Input audio file')
    parser.add_argument('--output', required=True, help='Output audio file')

    # Processing options
    parser.add_argument('--sample-rate', type=int, help='Target sample rate (Hz)')
    parser.add_argument('--format', help='Output format (mp3, wav, flac, ogg)')
    parser.add_argument('--bitrate', default='128k', help='Output bitrate for compressed formats')
    parser.add_argument('--remove-noise', action='store_true', help='Apply noise reduction')
    parser.add_argument('--normalize', action='store_true', help='Normalize audio levels')
    parser.add_argument('--trim-silence', action='store_true', help='Trim silence from start/end')
    parser.add_argument('--validate', action='store_true', help='Validate audio for voice cloning')

    # Advanced options
    parser.add_argument('--silence-thresh', type=int, default=-40,
                        help='Silence threshold in dB (default: -40)')
    parser.add_argument('--info-only', action='store_true', help='Only show audio info, no processing')

    args = parser.parse_args()

    # Validate input file
    if not validate_audio_file(args.input):
        sys.exit(1)

    # Load audio
    print_colored(f"Loading audio file: {args.input}", Colors.GREEN)
    try:
        audio = AudioSegment.from_file(args.input)
    except Exception as e:
        print_colored(f"Error loading audio file: {e}", Colors.RED)
        sys.exit(1)

    # Display audio info
    info = get_audio_info(audio)
    print("\nAudio Information:")
    print(f"  Duration: {info['duration_seconds']:.2f} seconds")
    print(f"  Sample Rate: {info['sample_rate']} Hz")
    print(f"  Channels: {info['channels']}")
    print(f"  Sample Width: {info['sample_width']} bytes")
    print(f"  Frame Count: {info['frame_count']}")
    print(f"  Size: {info['size_bytes']:,} bytes")

    # If info-only mode, exit here
    if args.info_only:
        if args.validate:
            validate_for_cloning(audio)
        sys.exit(0)

    # Apply processing steps
    processed_audio = audio

    if args.remove_noise:
        processed_audio = remove_noise(processed_audio)

    if args.normalize:
        processed_audio = normalize_audio(processed_audio)

    if args.trim_silence:
        processed_audio = trim_silence(processed_audio, silence_thresh=args.silence_thresh)

    if args.sample_rate:
        processed_audio = change_sample_rate(processed_audio, args.sample_rate)

    # Validate if requested
    if args.validate:
        if not validate_for_cloning(processed_audio):
            print_colored("\nWarning: Audio has validation issues. Consider fixing before cloning.", Colors.YELLOW)

    # Determine output format
    output_format = args.format
    if not output_format:
        output_format = Path(args.output).suffix[1:].lower()
        if not output_format:
            output_format = 'mp3'

    # Export audio
    print(f"\nExporting audio to: {args.output}")
    try:
        export_params = {
            'format': output_format,
        }

        # Add bitrate for compressed formats
        if output_format in ['mp3', 'ogg']:
            export_params['bitrate'] = args.bitrate

        processed_audio.export(args.output, **export_params)
    except Exception as e:
        print_colored(f"Error exporting audio: {e}", Colors.RED)
        sys.exit(1)

    # Display output info
    output_info = get_audio_info(processed_audio)
    print_colored("\n✓ Processing complete!", Colors.GREEN)
    print("\nOutput Information:")
    print(f"  Duration: {output_info['duration_seconds']:.2f} seconds")
    print(f"  Sample Rate: {output_info['sample_rate']} Hz")
    print(f"  Channels: {output_info['channels']}")
    print(f"  Format: {output_format.upper()}")
    print(f"  File size: {os.path.getsize(args.output):,} bytes")

    # Show processing summary
    print("\nProcessing Applied:")
    if args.remove_noise:
        print("  ✓ Noise reduction")
    if args.normalize:
        print("  ✓ Normalization")
    if args.trim_silence:
        print("  ✓ Silence trimming")
    if args.sample_rate:
        print(f"  ✓ Sample rate conversion ({args.sample_rate} Hz)")

    print("\nNext steps:")
    print(f"  1. Use processed audio for voice cloning:")
    print(f"     bash scripts/clone-voice.sh --name \"Voice Name\" --files \"{args.output}\"")
    print(f"  2. Validate audio quality:")
    print(f"     python scripts/process-audio.py --input \"{args.output}\" --info-only --validate")

    sys.exit(0)


if __name__ == '__main__':
    main()
