#!/usr/bin/env bash

# Benchmark ElevenLabs transcription performance
# Tests latency, throughput, and accuracy across different audio formats

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
Usage: $0 [OPTIONS] <test-directory>

Benchmark ElevenLabs transcription performance

OPTIONS:
    -h, --help              Show this help message
    -o, --output FILE       Output results to file (default: benchmark-results.json)
    -r, --runs NUM          Number of runs per file (default: 3)
    --verbose               Enable verbose output

EXAMPLES:
    $0 test-audio/
    $0 --runs 5 --output results.json test-audio/
    $0 --verbose test-audio/

EOF
    exit 1
}

check_dependencies() {
    local missing=()

    if ! command -v node &> /dev/null; then
        missing+=("node")
    fi

    if ! command -v jq &> /dev/null; then
        log_warning "jq not installed (optional, for JSON formatting)"
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}"
        return 1
    fi

    return 0
}

find_audio_files() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        log_error "Directory not found: $dir"
        return 1
    fi

    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$dir" -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.m4a" -o -name "*.flac" -o -name "*.ogg" \) -print0)

    if [ ${#files[@]} -eq 0 ]; then
        log_error "No audio files found in $dir"
        return 1
    fi

    printf '%s\n' "${files[@]}"
    return 0
}

get_file_info() {
    local file="$1"

    local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
    local size_mb=$(echo "scale=2; $size / 1048576" | bc)
    local ext="${file##*.}"

    echo "$size|$size_mb|$ext"
}

run_benchmark() {
    local file="$1"
    local runs="$2"
    local verbose="$3"

    log_info "Benchmarking: $(basename "$file")"

    local file_info=$(get_file_info "$file")
    local size=$(echo "$file_info" | cut -d'|' -f1)
    local size_mb=$(echo "$file_info" | cut -d'|' -f2)
    local ext=$(echo "$file_info" | cut -d'|' -f3)

    log_info "  Format: $ext | Size: ${size_mb}MB"

    local total_time=0
    local total_audio_duration=0
    local total_text_length=0
    local success_count=0

    for i in $(seq 1 "$runs"); do
        if [ "$verbose" = "true" ]; then
            log_info "  Run $i/$runs..."
        fi

        local result=$(run_single_transcription "$file" "$verbose")
        local exit_code=$?

        if [ $exit_code -eq 0 ]; then
            local time=$(echo "$result" | jq -r '.processingTime')
            local audio_duration=$(echo "$result" | jq -r '.audioDuration')
            local text_length=$(echo "$result" | jq -r '.textLength')

            total_time=$(echo "$total_time + $time" | bc)
            total_audio_duration=$(echo "$total_audio_duration + $audio_duration" | bc)
            total_text_length=$(echo "$total_text_length + $text_length" | bc)
            success_count=$((success_count + 1))

            if [ "$verbose" = "true" ]; then
                log_success "  Run $i: ${time}ms"
            fi
        else
            log_error "  Run $i failed"
        fi
    done

    if [ $success_count -eq 0 ]; then
        log_error "All runs failed for $(basename "$file")"
        echo "{\"success\": false, \"file\": \"$file\"}"
        return 1
    fi

    local avg_time=$(echo "scale=2; $total_time / $success_count" | bc)
    local avg_audio_duration=$(echo "scale=2; $total_audio_duration / $success_count" | bc)
    local avg_text_length=$(echo "scale=0; $total_text_length / $success_count" | bc)
    local rtf=$(echo "scale=3; $avg_time / ($avg_audio_duration * 1000)" | bc)

    log_success "  Average: ${avg_time}ms | RTF: $rtf | Success: $success_count/$runs"

    # Output JSON result
    cat << EOF
{
  "file": "$file",
  "format": "$ext",
  "sizeBytes": $size,
  "sizeMB": $size_mb,
  "runs": $runs,
  "successfulRuns": $success_count,
  "avgProcessingTimeMs": $avg_time,
  "avgAudioDurationSeconds": $avg_audio_duration,
  "avgTextLength": $avg_text_length,
  "realTimeFactor": $rtf
}
EOF

    return 0
}

run_single_transcription() {
    local file="$1"
    local verbose="$2"

    local test_script=$(mktemp --suffix=.mjs)

    cat > "$test_script" << EOF
import { experimental_transcribe as transcribe } from 'ai';
import { elevenlabs } from '@ai-sdk/elevenlabs';
import { readFile } from 'fs/promises';

const verbose = ${verbose};

async function main() {
  try {
    const audioBuffer = await readFile('${file}');
    const startTime = Date.now();

    const result = await transcribe({
      model: elevenlabs.transcription('scribe_v1'),
      audio: audioBuffer,
    });

    const endTime = Date.now();
    const processingTime = endTime - startTime;

    const output = {
      success: true,
      processingTime: processingTime,
      audioDuration: result.durationInSeconds || 0,
      textLength: result.text.length,
      text: verbose ? result.text : null,
    };

    console.log(JSON.stringify(output));
    process.exit(0);
  } catch (error) {
    console.error(JSON.stringify({
      success: false,
      error: error.message,
    }));
    process.exit(1);
  }
}

main();
EOF

    local output=$(node "$test_script" 2>&1)
    local exit_code=$?

    rm -f "$test_script"

    if [ $exit_code -eq 0 ]; then
        echo "$output"
        return 0
    else
        if [ "$verbose" = "true" ]; then
            log_error "Transcription failed: $output"
        fi
        return 1
    fi
}

generate_report() {
    local results="$1"
    local output_file="$2"

    log_info "Generating benchmark report..."

    # Write JSON results
    if command -v jq &> /dev/null; then
        echo "$results" | jq '.' > "$output_file"
    else
        echo "$results" > "$output_file"
    fi

    log_success "Results written to: $output_file"

    # Print summary
    echo
    echo "======================================"
    echo "      BENCHMARK SUMMARY"
    echo "======================================"
    echo

    if command -v jq &> /dev/null; then
        echo "$results" | jq -r '
          .results[] |
          "\(.format) (\(.sizeMB)MB): \(.avgProcessingTimeMs)ms (RTF: \(.realTimeFactor))"
        '
    else
        log_info "Install jq for formatted summary"
        cat "$output_file"
    fi

    echo
    echo "======================================"
}

main() {
    local test_dir=""
    local output_file="benchmark-results.json"
    local runs=3
    local verbose=false

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -r|--runs)
                runs="$2"
                shift 2
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            *)
                if [ -z "$test_dir" ]; then
                    test_dir="$1"
                else
                    log_error "Unknown argument: $1"
                    usage
                fi
                shift
                ;;
        esac
    done

    if [ -z "$test_dir" ]; then
        log_error "Test directory not specified"
        usage
    fi

    log_info "ElevenLabs Transcription Benchmark"
    echo

    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    # Check API key
    if [ -z "${ELEVENLABS_API_KEY:-}" ]; then
        log_error "ELEVENLABS_API_KEY not set"
        exit 1
    fi

    log_success "ELEVENLABS_API_KEY is set"
    echo

    # Find audio files
    log_info "Finding audio files in: $test_dir"
    local files=$(find_audio_files "$test_dir")

    if [ $? -ne 0 ]; then
        exit 1
    fi

    local file_count=$(echo "$files" | wc -l)
    log_info "Found $file_count audio file(s)"
    echo

    # Run benchmarks
    local results='{"results": []}'

    while IFS= read -r file; do
        local result=$(run_benchmark "$file" "$runs" "$verbose")

        if [ $? -eq 0 ]; then
            results=$(echo "$results" | jq ".results += [$result]")
        fi

        echo
    done <<< "$files"

    # Generate report
    generate_report "$results" "$output_file"

    log_success "Benchmark complete!"
}

# Run main function
main "$@"
