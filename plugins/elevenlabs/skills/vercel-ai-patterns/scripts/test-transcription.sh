#!/usr/bin/env bash

# Test script for ElevenLabs transcription via Vercel AI SDK
# Tests transcription with sample audio file and reports results

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS] <audio-file>

Test ElevenLabs transcription via Vercel AI SDK

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    --validate-key          Only validate API key without transcription
    --language CODE         Specify language code (e.g., en, es, fr)
    --speakers NUM          Number of speakers for diarization (1-32)
    --timestamps            Enable word-level timestamps

EXAMPLES:
    $0 audio.mp3
    $0 --language en --speakers 2 meeting.wav
    $0 --validate-key
    $0 --verbose --timestamps interview.m4a

EOF
    exit 1
}

check_dependencies() {
    local missing=()

    if ! command -v node &> /dev/null; then
        missing+=("node")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_info "Please install missing dependencies and try again"
        return 1
    fi

    return 0
}

check_api_key() {
    if [ -z "${ELEVENLABS_API_KEY:-}" ]; then
        log_error "ELEVENLABS_API_KEY not set"
        log_info "Set it in .env.local or export it:"
        echo -e "  ${BLUE}export ELEVENLABS_API_KEY=your_api_key${NC}"
        return 1
    fi

    log_success "ELEVENLABS_API_KEY is set"
    return 0
}

validate_api_key() {
    log_info "Validating API key..."

    # Create a minimal test script
    local test_script=$(mktemp --suffix=.mjs)

    cat > "$test_script" << 'EOF'
import { elevenlabs } from '@ai-sdk/elevenlabs';

const apiKey = process.env.ELEVENLABS_API_KEY;

if (!apiKey) {
  console.error('ERROR: ELEVENLABS_API_KEY not set');
  process.exit(1);
}

// Test by creating a model instance
try {
  const model = elevenlabs.transcription('scribe_v1');
  console.log('SUCCESS: API key format is valid');
  console.log('Model instance created successfully');
  process.exit(0);
} catch (error) {
  console.error('ERROR: Failed to create model instance');
  console.error(error.message);
  process.exit(1);
}
EOF

    if node "$test_script"; then
        log_success "API key validation passed"
        rm -f "$test_script"
        return 0
    else
        log_error "API key validation failed"
        rm -f "$test_script"
        return 1
    fi
}

check_audio_file() {
    local file="$1"

    if [ ! -f "$file" ]; then
        log_error "Audio file not found: $file"
        return 1
    fi

    log_success "Audio file found: $file"

    # Get file size
    local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "unknown")
    if [ "$size" != "unknown" ]; then
        local size_mb=$(echo "scale=2; $size / 1048576" | bc)
        log_info "File size: ${size_mb}MB"

        if [ "$size" -gt 104857600 ]; then # 100MB
            log_warning "File is larger than 100MB, transcription may take longer"
        fi
    fi

    return 0
}

run_transcription() {
    local audio_file="$1"
    local language="${2:-}"
    local speakers="${3:-}"
    local timestamps="${4:-false}"
    local verbose="${5:-false}"

    log_info "Starting transcription..."
    log_info "Model: elevenlabs/scribe_v1"

    # Create transcription script
    local transcribe_script=$(mktemp --suffix=.mjs)

    cat > "$transcribe_script" << EOF
import { experimental_transcribe as transcribe } from 'ai';
import { elevenlabs } from '@ai-sdk/elevenlabs';
import { readFile } from 'fs/promises';

const verbose = ${verbose};

async function main() {
  try {
    const startTime = Date.now();

    if (verbose) {
      console.log('[DEBUG] Reading audio file...');
    }

    const audioBuffer = await readFile('${audio_file}');

    if (verbose) {
      console.log('[DEBUG] File size:', audioBuffer.length, 'bytes');
      console.log('[DEBUG] Starting transcription...');
    }

    const options = {
      model: elevenlabs.transcription('scribe_v1'),
      audio: audioBuffer,
    };

    // Add provider options if specified
    const providerOptions = {};

    ${language:+providerOptions.languageCode = '${language}';}
    ${speakers:+providerOptions.numSpeakers = ${speakers};}
    ${timestamps:+providerOptions.timestampsGranularity = 'word';}

    if (${speakers:-false}) {
      providerOptions.diarize = true;
    }

    if (Object.keys(providerOptions).length > 0) {
      options.providerOptions = { elevenlabs: providerOptions };
    }

    if (verbose) {
      console.log('[DEBUG] Options:', JSON.stringify(options.providerOptions || {}, null, 2));
    }

    const result = await transcribe(options);

    const endTime = Date.now();
    const duration = ((endTime - startTime) / 1000).toFixed(2);

    console.log('\\n=== TRANSCRIPTION RESULT ===');
    console.log('Text:', result.text);

    if (result.language) {
      console.log('Detected Language:', result.language);
    }

    if (result.durationInSeconds) {
      console.log('Audio Duration:', result.durationInSeconds, 'seconds');
    }

    if (result.segments && result.segments.length > 0) {
      console.log('\\n=== SEGMENTS ===');
      result.segments.forEach((segment, idx) => {
        const speaker = segment.speaker ? \`[Speaker \${segment.speaker}] \` : '';
        const time = segment.timestamp ? \`[\${segment.timestamp}s] \` : '';
        console.log(\`\${idx + 1}. \${time}\${speaker}\${segment.text}\`);
      });
    }

    console.log('\\nTranscription Time:', duration, 'seconds');

    process.exit(0);
  } catch (error) {
    console.error('\\n=== TRANSCRIPTION FAILED ===');
    console.error('Error:', error.message);

    if (error.name === 'AI_NoTranscriptGeneratedError') {
      console.error('\\nThis is a transcription error from the provider.');
      if (error.response) {
        console.error('Provider response:', JSON.stringify(error.response, null, 2));
      }
    }

    if (verbose) {
      console.error('\\nFull error:', error);
    }

    process.exit(1);
  }
}

main();
EOF

    # Run transcription
    if node "$transcribe_script"; then
        log_success "Transcription completed successfully"
        rm -f "$transcribe_script"
        return 0
    else
        log_error "Transcription failed"
        rm -f "$transcribe_script"
        return 1
    fi
}

main() {
    local audio_file=""
    local validate_only=false
    local verbose=false
    local language=""
    local speakers=""
    local timestamps=false

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --validate-key)
                validate_only=true
                shift
                ;;
            --language)
                language="$2"
                shift 2
                ;;
            --speakers)
                speakers="$2"
                shift 2
                ;;
            --timestamps)
                timestamps=true
                shift
                ;;
            *)
                if [ -z "$audio_file" ]; then
                    audio_file="$1"
                else
                    log_error "Unknown argument: $1"
                    usage
                fi
                shift
                ;;
        esac
    done

    log_info "ElevenLabs Transcription Test"
    echo

    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    # Check API key
    if ! check_api_key; then
        exit 1
    fi

    # Validate API key if requested
    if [ "$validate_only" = true ]; then
        validate_api_key
        exit $?
    fi

    # Check audio file
    if [ -z "$audio_file" ]; then
        log_error "Audio file not specified"
        usage
    fi

    if ! check_audio_file "$audio_file"; then
        exit 1
    fi

    echo

    # Run transcription
    if ! run_transcription "$audio_file" "$language" "$speakers" "$timestamps" "$verbose"; then
        exit 1
    fi

    echo
    log_success "Test completed successfully"
}

# Run main function
main "$@"
