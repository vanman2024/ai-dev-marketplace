#!/usr/bin/env bash
#
# list-voices.sh - List and search ElevenLabs voices
#
# Usage:
#   bash list-voices.sh --category all
#   bash list-voices.sh --category cloned
#   bash list-voices.sh --category library --search "Australian narration"
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CATEGORY="all"
SEARCH_TERM=""
OUTPUT_FORMAT="table"
API_KEY="${ELEVEN_API_KEY:-}"
API_BASE_URL="${ELEVEN_API_BASE_URL:-https://api.elevenlabs.io/v1}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --search)
            SEARCH_TERM="$2"
            shift 2
            ;;
        --format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --category     Filter by category: all, cloned, library, default, voice-design"
            echo "  --search       Search term for filtering voices"
            echo "  --format       Output format: table or json (default: table)"
            echo "  --api-key      ElevenLabs API key (or set ELEVEN_API_KEY env var)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Validate API key
if [[ -z "$API_KEY" ]]; then
    echo -e "${RED}Error: API key not found. Set ELEVEN_API_KEY environment variable or use --api-key${NC}"
    exit 1
fi

# Validate output format
if [[ "$OUTPUT_FORMAT" != "table" && "$OUTPUT_FORMAT" != "json" ]]; then
    echo -e "${RED}Error: Format must be 'table' or 'json'${NC}"
    exit 1
fi

echo -e "${GREEN}Fetching ElevenLabs Voices${NC}"
echo "=============================="

# Fetch voices from API
RESPONSE=$(curl -s -X GET \
  "${API_BASE_URL}/voices" \
  -H "xi-api-key: $API_KEY")

# Check for errors
if echo "$RESPONSE" | jq -e '.detail' >/dev/null 2>&1; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.detail')
    echo -e "${RED}Error: $ERROR_MSG${NC}"
    exit 1
fi

# Extract voices array
VOICES=$(echo "$RESPONSE" | jq -c '.voices // []')

if [[ "$VOICES" == "[]" ]]; then
    echo -e "${YELLOW}No voices found${NC}"
    exit 0
fi

# Filter by category if specified
if [[ "$CATEGORY" != "all" ]]; then
    case $CATEGORY in
        cloned)
            VOICES=$(echo "$VOICES" | jq -c '[.[] | select(.category == "cloned")]')
            ;;
        library)
            VOICES=$(echo "$VOICES" | jq -c '[.[] | select(.category == "premade")]')
            ;;
        default)
            VOICES=$(echo "$VOICES" | jq -c '[.[] | select(.category == "premade" and .fine_tuning == null)]')
            ;;
        voice-design)
            VOICES=$(echo "$VOICES" | jq -c '[.[] | select(.category == "generated")]')
            ;;
        *)
            echo -e "${RED}Error: Invalid category. Use: all, cloned, library, default, voice-design${NC}"
            exit 1
            ;;
    esac
fi

# Apply search filter if specified
if [[ -n "$SEARCH_TERM" ]]; then
    SEARCH_LOWER=$(echo "$SEARCH_TERM" | tr '[:upper:]' '[:lower:]')
    VOICES=$(echo "$VOICES" | jq -c --arg search "$SEARCH_LOWER" '[
        .[] | select(
            (.name // "" | ascii_downcase | contains($search)) or
            (.description // "" | ascii_downcase | contains($search)) or
            (.labels | to_entries | map(.key) | join(" ") | ascii_downcase | contains($search))
        )
    ]')
fi

# Count results
VOICE_COUNT=$(echo "$VOICES" | jq 'length')

if [[ "$VOICE_COUNT" -eq 0 ]]; then
    echo -e "${YELLOW}No voices found matching criteria${NC}"
    exit 0
fi

echo "Found $VOICE_COUNT voice(s)"
echo ""

# Output based on format
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "$VOICES" | jq '.'
else
    # Table format
    echo -e "${BLUE}$(printf '%-25s %-35s %-15s %-10s' 'NAME' 'VOICE ID' 'CATEGORY' 'SAMPLES')${NC}"
    echo "$(printf '%.0s-' {1..90})"

    echo "$VOICES" | jq -r '.[] | [
        .name,
        .voice_id,
        .category,
        (.samples | length | tostring)
    ] | @tsv' | while IFS=$'\t' read -r name voice_id category samples; do
        # Truncate name if too long
        if [[ ${#name} -gt 23 ]]; then
            name="${name:0:20}..."
        fi

        # Color code by category
        case $category in
            cloned)
                CATEGORY_COLOR="${GREEN}"
                ;;
            premade)
                CATEGORY_COLOR="${BLUE}"
                ;;
            generated)
                CATEGORY_COLOR="${YELLOW}"
                ;;
            *)
                CATEGORY_COLOR="${NC}"
                ;;
        esac

        printf "%-25s %-35s ${CATEGORY_COLOR}%-15s${NC} %-10s\n" \
            "$name" "$voice_id" "$category" "$samples"
    done

    echo ""
    echo "Category Legend:"
    echo -e "  ${GREEN}cloned${NC}     - Custom cloned voices"
    echo -e "  ${BLUE}premade${NC}    - Voice library and default voices"
    echo -e "  ${YELLOW}generated${NC}  - AI-generated (Voice Design)"
fi

# Display summary statistics
echo ""
echo -e "${GREEN}Summary Statistics:${NC}"

# Count by category
CLONED_COUNT=$(echo "$VOICES" | jq '[.[] | select(.category == "cloned")] | length')
PREMADE_COUNT=$(echo "$VOICES" | jq '[.[] | select(.category == "premade")] | length')
GENERATED_COUNT=$(echo "$VOICES" | jq '[.[] | select(.category == "generated")] | length')

echo "  Cloned: $CLONED_COUNT"
echo "  Library/Default: $PREMADE_COUNT"
echo "  Voice Design: $GENERATED_COUNT"
echo "  Total: $VOICE_COUNT"

# Display sample voice details
if [[ "$VOICE_COUNT" -gt 0 && "$VOICE_COUNT" -le 3 ]]; then
    echo ""
    echo -e "${GREEN}Voice Details:${NC}"
    echo "$VOICES" | jq -r '.[] | "
Name: \(.name)
Voice ID: \(.voice_id)
Category: \(.category)
Description: \(.description // "No description")
Samples: \(.samples | length)
Labels: \(.labels | to_entries | map(.key) | join(", "))
---"'
fi

# Save results to file
OUTPUT_FILE="voices_$(date +%Y%m%d_%H%M%S).json"
echo "$VOICES" | jq '.' > "$OUTPUT_FILE"
echo ""
echo -e "${GREEN}Results saved to: $OUTPUT_FILE${NC}"

# Usage tips
echo ""
echo "Tips:"
echo "  • View voice details: curl -H \"xi-api-key: $API_KEY\" ${API_BASE_URL}/voices/VOICE_ID"
echo "  • Filter by category: --category cloned|library|default|voice-design"
echo "  • Search voices: --search \"Australian narration\""
echo "  • JSON output: --format json"

exit 0
