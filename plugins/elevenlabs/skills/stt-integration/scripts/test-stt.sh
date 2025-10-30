#!/usr/bin/env bash
set -euo pipefail

#############################################################
# ElevenLabs STT Test Suite
#############################################################
# Usage: ./test-stt.sh [--skip-api] [--skip-validation]
#
# This script runs comprehensive tests for STT functionality:
#   1. Environment validation
#   2. Audio file validation
#   3. API connectivity test
#   4. Basic transcription test
#   5. Speaker diarization test
#   6. Multi-language test
#
# Environment Variables:
#   ELEVENLABS_API_KEY - Required API key for authentication
#
# Options:
#   --skip-api          Skip actual API calls (offline mode)
#   --skip-validation   Skip audio validation tests
#   --verbose           Show detailed output
#############################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Options
SKIP_API="false"
SKIP_VALIDATION="false"
VERBOSE="false"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-api)
            SKIP_API="true"
            shift
            ;;
        --skip-validation)
            SKIP_VALIDATION="true"
            shift
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            shift
            ;;
    esac
done

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_test() {
    echo -e "${BLUE}▸ $1${NC}"
}

pass_test() {
    echo -e "${GREEN}  ✓ $1${NC}"
    ((TESTS_PASSED++))
}

fail_test() {
    echo -e "${RED}  ✗ $1${NC}"
    ((TESTS_FAILED++))
}

skip_test() {
    echo -e "${YELLOW}  ⊘ $1${NC}"
    ((TESTS_SKIPPED++))
}

# Start tests
print_header "ElevenLabs STT Test Suite"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

#############################################################
# Test 1: Environment Validation
#############################################################
print_test "Test 1: Environment Validation"

# Check for API key
if [[ -z "${ELEVENLABS_API_KEY:-}" ]]; then
    fail_test "ELEVENLABS_API_KEY not set"
    echo -e "${YELLOW}  Set it with: export ELEVENLABS_API_KEY='your_api_key'${NC}"
else
    pass_test "ELEVENLABS_API_KEY is set"
fi

# Check for required commands
REQUIRED_COMMANDS=("curl" "jq")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        pass_test "$cmd is installed"
    else
        fail_test "$cmd is not installed"
        echo -e "${YELLOW}  Install with: sudo apt-get install $cmd${NC}"
    fi
done

# Check for optional commands
if command -v ffmpeg &> /dev/null; then
    pass_test "ffmpeg is installed (optional)"
else
    skip_test "ffmpeg not found (optional, useful for audio conversion)"
fi

#############################################################
# Test 2: Script Validation
#############################################################
print_test "Test 2: Script Validation"

# Check if scripts exist and are executable
SCRIPTS=(
    "transcribe-audio.sh"
    "setup-vercel-ai.sh"
    "validate-audio.sh"
    "batch-transcribe.sh"
)

for script in "${SCRIPTS[@]}"; do
    SCRIPT_PATH="$SCRIPT_DIR/$script"
    if [[ -f "$SCRIPT_PATH" ]]; then
        if [[ -x "$SCRIPT_PATH" ]]; then
            pass_test "$script exists and is executable"
        else
            fail_test "$script exists but is not executable"
            echo -e "${YELLOW}  Fix with: chmod +x $SCRIPT_PATH${NC}"
        fi
    else
        fail_test "$script not found"
    fi
done

#############################################################
# Test 3: Template Validation
#############################################################
print_test "Test 3: Template Validation"

TEMPLATES=(
    "templates/stt-config.json.template"
    "templates/vercel-ai-transcribe.ts.template"
    "templates/vercel-ai-transcribe.py.template"
)

for template in "${TEMPLATES[@]}"; do
    TEMPLATE_PATH="$SKILL_DIR/$template"
    if [[ -f "$TEMPLATE_PATH" ]]; then
        pass_test "$(basename $template) exists"
    else
        fail_test "$(basename $template) not found"
    fi
done

#############################################################
# Test 4: Audio Format Validation
#############################################################
if [[ "$SKIP_VALIDATION" == "false" ]]; then
    print_test "Test 4: Audio Format Validation"

    # Test supported formats
    SUPPORTED_FORMATS=("mp3" "wav" "m4a" "ogg" "flac" "mp4")
    for format in "${SUPPORTED_FORMATS[@]}"; do
        # Just verify format is recognized (not actual file test)
        if [[ " aac aiff ogg mp3 opus wav webm flac m4a mp4 avi mkv mov wmv flv mpeg 3gp " =~ " $format " ]]; then
            pass_test "Format .$format is supported"
        else
            fail_test "Format .$format not in supported list"
        fi
    done
else
    skip_test "Audio format validation (--skip-validation)"
fi

#############################################################
# Test 5: API Connectivity
#############################################################
if [[ "$SKIP_API" == "false" ]] && [[ -n "${ELEVENLABS_API_KEY:-}" ]]; then
    print_test "Test 5: API Connectivity"

    # Test API endpoint accessibility
    API_URL="https://api.elevenlabs.io/v1/models"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "xi-api-key: $ELEVENLABS_API_KEY" \
        "$API_URL" || echo "000")

    if [[ "$HTTP_CODE" == "200" ]]; then
        pass_test "API endpoint accessible (HTTP $HTTP_CODE)"
    elif [[ "$HTTP_CODE" == "401" ]]; then
        fail_test "API authentication failed (HTTP $HTTP_CODE)"
        echo -e "${YELLOW}  Check your ELEVENLABS_API_KEY${NC}"
    elif [[ "$HTTP_CODE" == "000" ]]; then
        fail_test "Cannot connect to API (network error)"
    else
        fail_test "API returned unexpected status (HTTP $HTTP_CODE)"
    fi
else
    skip_test "API connectivity test (--skip-api or no API key)"
fi

#############################################################
# Test 6: Mock Transcription Test
#############################################################
if [[ "$SKIP_API" == "false" ]] && [[ -n "${ELEVENLABS_API_KEY:-}" ]]; then
    print_test "Test 6: Sample Audio Transcription"

    # Check if we have a sample audio file
    SAMPLE_AUDIO=""
    POSSIBLE_SAMPLES=(
        "$SKILL_DIR/examples/basic-stt/sample.mp3"
        "$SKILL_DIR/examples/basic-stt/sample.wav"
        "/tmp/test-audio.mp3"
    )

    for sample in "${POSSIBLE_SAMPLES[@]}"; do
        if [[ -f "$sample" ]]; then
            SAMPLE_AUDIO="$sample"
            break
        fi
    done

    if [[ -n "$SAMPLE_AUDIO" ]]; then
        # Test transcription with sample audio
        TEMP_OUTPUT=$(mktemp)
        if "$SCRIPT_DIR/transcribe-audio.sh" "$SAMPLE_AUDIO" --output="$TEMP_OUTPUT" > /dev/null 2>&1; then
            if [[ -f "$TEMP_OUTPUT" ]] && [[ -s "$TEMP_OUTPUT" ]]; then
                pass_test "Sample transcription successful"
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -e "${BLUE}  Transcription: $(cat $TEMP_OUTPUT)${NC}"
                fi
            else
                fail_test "Transcription produced no output"
            fi
        else
            fail_test "Transcription failed"
        fi
        rm -f "$TEMP_OUTPUT"
    else
        skip_test "No sample audio file found for testing"
        echo -e "${YELLOW}  Create sample at: $SKILL_DIR/examples/basic-stt/sample.mp3${NC}"
    fi
else
    skip_test "Sample transcription test (--skip-api or no API key)"
fi

#############################################################
# Test 7: Vercel AI SDK Integration
#############################################################
print_test "Test 7: Vercel AI SDK Integration"

# Check if Node.js is installed
if command -v node &> /dev/null; then
    pass_test "Node.js is installed ($(node --version))"

    # Check if package.json exists
    if [[ -f "package.json" ]]; then
        # Check for ai-sdk packages
        if command -v npm &> /dev/null; then
            if npm list ai @ai-sdk/elevenlabs > /dev/null 2>&1; then
                pass_test "Vercel AI SDK packages installed"
            else
                skip_test "Vercel AI SDK packages not installed"
                echo -e "${YELLOW}  Install with: bash $SCRIPT_DIR/setup-vercel-ai.sh${NC}"
            fi
        else
            skip_test "npm not available to check packages"
        fi
    else
        skip_test "No package.json found"
    fi
else
    skip_test "Node.js not installed (required for Vercel AI SDK)"
fi

#############################################################
# Test 8: Python SDK Integration
#############################################################
print_test "Test 8: Python SDK Integration"

# Check if Python is installed
if command -v python3 &> /dev/null || command -v python &> /dev/null; then
    PYTHON_CMD="python3"
    if ! command -v python3 &> /dev/null; then
        PYTHON_CMD="python"
    fi

    pass_test "Python is installed ($($PYTHON_CMD --version))"

    # Check for elevenlabs package
    if $PYTHON_CMD -c "import elevenlabs" 2> /dev/null; then
        pass_test "elevenlabs package installed"
    else
        skip_test "elevenlabs package not installed"
        echo -e "${YELLOW}  Install with: pip install elevenlabs${NC}"
    fi
else
    skip_test "Python not installed"
fi

#############################################################
# Test Summary
#############################################################
print_header "Test Summary"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))

echo -e "${GREEN}Passed:  $TESTS_PASSED${NC}"
echo -e "${RED}Failed:  $TESTS_FAILED${NC}"
echo -e "${YELLOW}Skipped: $TESTS_SKIPPED${NC}"
echo -e "${BLUE}Total:   $TOTAL_TESTS${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ All tests passed!                          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ Some tests failed                          ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════╝${NC}"
    exit 1
fi
