#!/usr/bin/env bash
#
# manage-voice-library.sh - Manage ElevenLabs voice library operations
#
# Usage:
#   bash manage-voice-library.sh --action add --voice-id "abc123" --collection "My Voices"
#   bash manage-voice-library.sh --action share --voice-id "abc123" --enable-rewards
#   bash manage-voice-library.sh --action remove --voice-id "abc123"
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ACTION=""
VOICE_ID=""
COLLECTION=""
ENABLE_REWARDS="false"
DESCRIPTION=""
TAGS=""
API_KEY="${ELEVEN_API_KEY:-}"
API_BASE_URL="${ELEVEN_API_BASE_URL:-https://api.elevenlabs.io/v1}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --action)
            ACTION="$2"
            shift 2
            ;;
        --voice-id)
            VOICE_ID="$2"
            shift 2
            ;;
        --collection)
            COLLECTION="$2"
            shift 2
            ;;
        --enable-rewards)
            ENABLE_REWARDS="true"
            shift
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --tags)
            TAGS="$2"
            shift 2
            ;;
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --action <action> --voice-id <id> [options]"
            echo ""
            echo "Actions:"
            echo "  add       Add voice to library"
            echo "  share     Share voice publicly (Professional clones only)"
            echo "  remove    Remove voice from library"
            echo "  update    Update voice metadata"
            echo "  details   Get voice details"
            echo ""
            echo "Options:"
            echo "  --voice-id         Voice ID (required)"
            echo "  --collection       Collection name"
            echo "  --enable-rewards   Enable cash rewards for shared voices"
            echo "  --description      Voice description"
            echo "  --tags             Comma-separated tags"
            echo "  --api-key          ElevenLabs API key (or set ELEVEN_API_KEY env var)"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$ACTION" ]]; then
    echo -e "${RED}Error: --action is required${NC}"
    exit 1
fi

if [[ -z "$VOICE_ID" ]]; then
    echo -e "${RED}Error: --voice-id is required${NC}"
    exit 1
fi

if [[ -z "$API_KEY" ]]; then
    echo -e "${RED}Error: API key not found. Set ELEVEN_API_KEY environment variable or use --api-key${NC}"
    exit 1
fi

# Validate action
case $ACTION in
    add|share|remove|update|details)
        ;;
    *)
        echo -e "${RED}Error: Invalid action. Use: add, share, remove, update, details${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}ElevenLabs Voice Library Management${NC}"
echo "===================================="
echo "Action: $ACTION"
echo "Voice ID: $VOICE_ID"
echo ""

# Get voice details first
get_voice_details() {
    local voice_id=$1
    curl -s -X GET \
        "${API_BASE_URL}/voices/${voice_id}" \
        -H "xi-api-key: $API_KEY"
}

# Check if voice exists
echo "Fetching voice details..."
VOICE_DETAILS=$(get_voice_details "$VOICE_ID")

if echo "$VOICE_DETAILS" | jq -e '.detail' >/dev/null 2>&1; then
    ERROR_MSG=$(echo "$VOICE_DETAILS" | jq -r '.detail')
    echo -e "${RED}Error: $ERROR_MSG${NC}"
    exit 1
fi

VOICE_NAME=$(echo "$VOICE_DETAILS" | jq -r '.name')
VOICE_CATEGORY=$(echo "$VOICE_DETAILS" | jq -r '.category')

echo -e "${GREEN}✓${NC} Voice found: $VOICE_NAME (Category: $VOICE_CATEGORY)"
echo ""

# Execute action
case $ACTION in
    details)
        echo -e "${BLUE}Voice Details:${NC}"
        echo "$VOICE_DETAILS" | jq '{
            voice_id: .voice_id,
            name: .name,
            category: .category,
            description: .description,
            samples: (.samples | length),
            labels: .labels,
            sharing: .sharing
        }'
        ;;

    add)
        # Adding voice to a collection (metadata update)
        echo "Adding voice to collection..."

        if [[ -z "$COLLECTION" ]]; then
            echo -e "${RED}Error: --collection is required for add action${NC}"
            exit 1
        fi

        # Build labels JSON
        LABELS_JSON="{\"collection\":\"$COLLECTION\""

        if [[ -n "$TAGS" ]]; then
            IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
            for tag in "${TAG_ARRAY[@]}"; do
                tag=$(echo "$tag" | xargs)
                LABELS_JSON="$LABELS_JSON,\"$tag\":\"$tag\""
            done
        fi

        LABELS_JSON="$LABELS_JSON}"

        # Update voice with collection label
        UPDATE_PAYLOAD=$(jq -n \
            --arg name "$VOICE_NAME" \
            --arg desc "${DESCRIPTION:-$VOICE_NAME}" \
            --argjson labels "$LABELS_JSON" \
            '{name: $name, description: $desc, labels: $labels}')

        RESPONSE=$(curl -s -X POST \
            "${API_BASE_URL}/voices/${VOICE_ID}/edit" \
            -H "xi-api-key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$UPDATE_PAYLOAD")

        if echo "$RESPONSE" | jq -e '.detail' >/dev/null 2>&1; then
            ERROR_MSG=$(echo "$RESPONSE" | jq -r '.detail')
            echo -e "${RED}Error: $ERROR_MSG${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Voice added to collection: $COLLECTION${NC}"
        ;;

    share)
        # Share voice in public library
        echo "Sharing voice in library..."

        # Check if voice is professional clone
        if [[ "$VOICE_CATEGORY" != "cloned" ]]; then
            echo -e "${YELLOW}Warning: Only Professional Voice Clones can be shared${NC}"
            echo "Current category: $VOICE_CATEGORY"
        fi

        # Build sharing configuration
        SHARING_PAYLOAD=$(jq -n \
            --arg desc "${DESCRIPTION:-$VOICE_NAME}" \
            --argjson enable_rewards "$(echo "$ENABLE_REWARDS" | jq -R 'fromjson')" \
            '{
                public_owner_id: true,
                status: "enabled",
                enable_for_tier: "all",
                category: "professional",
                enable_rewards: $enable_rewards,
                description: $desc
            }')

        # Add tags if provided
        if [[ -n "$TAGS" ]]; then
            IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
            TAGS_JSON=$(printf '%s\n' "${TAG_ARRAY[@]}" | jq -R . | jq -s .)
            SHARING_PAYLOAD=$(echo "$SHARING_PAYLOAD" | jq --argjson tags "$TAGS_JSON" '. + {tags: $tags}')
        fi

        # Update voice with sharing configuration
        EDIT_PAYLOAD=$(jq -n \
            --arg name "$VOICE_NAME" \
            --argjson sharing "$SHARING_PAYLOAD" \
            '{name: $name, sharing: $sharing}')

        RESPONSE=$(curl -s -X POST \
            "${API_BASE_URL}/voices/${VOICE_ID}/edit" \
            -H "xi-api-key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$EDIT_PAYLOAD")

        if echo "$RESPONSE" | jq -e '.detail' >/dev/null 2>&1; then
            ERROR_MSG=$(echo "$RESPONSE" | jq -r '.detail')
            echo -e "${RED}Error: $ERROR_MSG${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Voice shared in library${NC}"

        if [[ "$ENABLE_REWARDS" == "true" ]]; then
            echo -e "${GREEN}✓ Cash rewards enabled${NC}"
            echo ""
            echo "Your voice can now earn rewards when others use it!"
        fi
        ;;

    remove)
        # Remove voice from library
        echo "Removing voice from library..."

        # Disable sharing
        SHARING_PAYLOAD=$(jq -n '{
            status: "disabled"
        }')

        EDIT_PAYLOAD=$(jq -n \
            --arg name "$VOICE_NAME" \
            --argjson sharing "$SHARING_PAYLOAD" \
            '{name: $name, sharing: $sharing}')

        RESPONSE=$(curl -s -X POST \
            "${API_BASE_URL}/voices/${VOICE_ID}/edit" \
            -H "xi-api-key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$EDIT_PAYLOAD")

        if echo "$RESPONSE" | jq -e '.detail' >/dev/null 2>&1; then
            ERROR_MSG=$(echo "$RESPONSE" | jq -r '.detail')
            echo -e "${RED}Error: $ERROR_MSG${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Voice removed from library${NC}"
        ;;

    update)
        # Update voice metadata
        echo "Updating voice metadata..."

        # Build update payload
        UPDATE_PAYLOAD=$(jq -n --arg name "$VOICE_NAME" '{name: $name}')

        if [[ -n "$DESCRIPTION" ]]; then
            UPDATE_PAYLOAD=$(echo "$UPDATE_PAYLOAD" | jq --arg desc "$DESCRIPTION" '. + {description: $desc}')
        fi

        if [[ -n "$TAGS" ]]; then
            LABELS_JSON="{"
            IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
            for i in "${!TAG_ARRAY[@]}"; do
                tag=$(echo "${TAG_ARRAY[$i]}" | xargs)
                LABELS_JSON="$LABELS_JSON\"$tag\":\"$tag\""
                if [[ $i -lt $((${#TAG_ARRAY[@]} - 1)) ]]; then
                    LABELS_JSON="$LABELS_JSON,"
                fi
            done
            LABELS_JSON="$LABELS_JSON}"
            UPDATE_PAYLOAD=$(echo "$UPDATE_PAYLOAD" | jq --argjson labels "$LABELS_JSON" '. + {labels: $labels}')
        fi

        RESPONSE=$(curl -s -X POST \
            "${API_BASE_URL}/voices/${VOICE_ID}/edit" \
            -H "xi-api-key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$UPDATE_PAYLOAD")

        if echo "$RESPONSE" | jq -e '.detail' >/dev/null 2>&1; then
            ERROR_MSG=$(echo "$RESPONSE" | jq -r '.detail')
            echo -e "${RED}Error: $ERROR_MSG${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Voice metadata updated${NC}"
        ;;
esac

# Get updated voice details
echo ""
echo "Fetching updated voice details..."
UPDATED_DETAILS=$(get_voice_details "$VOICE_ID")

if echo "$UPDATED_DETAILS" | jq -e '.name' >/dev/null 2>&1; then
    echo -e "${GREEN}Updated Voice Details:${NC}"
    echo "$UPDATED_DETAILS" | jq '{
        voice_id: .voice_id,
        name: .name,
        category: .category,
        description: .description,
        labels: .labels,
        sharing: .sharing
    }'
fi

echo ""
echo "Next steps:"
echo "  • View all voices: bash scripts/list-voices.sh"
echo "  • Get voice details: bash scripts/manage-voice-library.sh --action details --voice-id \"$VOICE_ID\""
echo "  • Test voice: curl -X POST \"${API_BASE_URL}/text-to-speech/${VOICE_ID}\" \\"
echo "                  -H \"xi-api-key: $API_KEY\" \\"
echo "                  -H \"Content-Type: application/json\" \\"
echo "                  -d '{\"text\":\"Test\"}' --output test.mp3"

exit 0
