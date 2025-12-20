#!/bin/bash
# Generate A2A Agent Card
# Usage: bash generate-agent-card.sh --name <name> --description <desc> --skills <skills>

set -e

# Parse arguments
AGENT_NAME=""
AGENT_DESC=""
SKILLS=""
MODALITIES="text"
AGENT_URL=""
OUTPUT_FILE=".well-known/agent.json"

while [[ $# -gt 0 ]]; do
  case $1 in
    --name)
      AGENT_NAME="$2"
      shift 2
      ;;
    --description)
      AGENT_DESC="$2"
      shift 2
      ;;
    --skills)
      SKILLS="$2"
      shift 2
      ;;
    --modalities)
      MODALITIES="$2"
      shift 2
      ;;
    --url)
      AGENT_URL="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [ -z "$AGENT_NAME" ]; then
  echo "Error: --name is required"
  echo "Usage: bash generate-agent-card.sh --name <name> --description <desc> --skills <skill1,skill2>"
  exit 1
fi

if [ -z "$AGENT_DESC" ]; then
  AGENT_DESC="$AGENT_NAME agent"
fi

if [ -z "$AGENT_URL" ]; then
  AGENT_URL="${A2A_AGENT_URL:-https://example.com}"
fi

echo "Generating Agent Card..."
echo "Name: $AGENT_NAME"
echo "Description: $AGENT_DESC"
echo "Skills: ${SKILLS:-none}"
echo "Modalities: $MODALITIES"
echo "URL: $AGENT_URL"

# Create .well-known directory if needed
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Parse skills into JSON array
SKILLS_JSON="[]"
if [ -n "$SKILLS" ]; then
  SKILLS_JSON="["
  IFS=',' read -ra SKILL_ARRAY <<< "$SKILLS"
  for i in "${!SKILL_ARRAY[@]}"; do
    skill="${SKILL_ARRAY[$i]}"
    if [ $i -gt 0 ]; then
      SKILLS_JSON+=","
    fi
    SKILLS_JSON+="{\"name\":\"$skill\",\"description\":\"$skill capability\"}"
  done
  SKILLS_JSON+="]"
fi

# Parse modalities into JSON array
MODALITIES_JSON="["
IFS=',' read -ra MOD_ARRAY <<< "$MODALITIES"
for i in "${!MOD_ARRAY[@]}"; do
  if [ $i -gt 0 ]; then
    MODALITIES_JSON+=","
  fi
  MODALITIES_JSON+="\"${MOD_ARRAY[$i]}\""
done
MODALITIES_JSON+="]"

# Generate Agent Card JSON
cat > "$OUTPUT_FILE" << EOF
{
  "id": "$AGENT_NAME",
  "name": "$AGENT_NAME",
  "description": "$AGENT_DESC",
  "version": "1.0.0",
  "url": "$AGENT_URL",
  "capabilities": {
    "skills": $SKILLS_JSON,
    "modalities": $MODALITIES_JSON,
    "streaming": true
  },
  "protocol": {
    "version": "0.3",
    "transport": "grpc"
  },
  "metadata": {
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "framework": "google-adk"
  }
}
EOF

echo "Agent Card generated: $OUTPUT_FILE"
echo ""
echo "View the card:"
echo "cat $OUTPUT_FILE | jq"
echo ""
echo "Validate the card:"
echo "bash scripts/validate-a2a.sh --config $OUTPUT_FILE"
