#!/bin/bash
# Validate A2A configuration
# Usage: bash validate-a2a.sh --config <agent-card.json>

set -e

CONFIG_FILE=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ -z "$CONFIG_FILE" ]; then
  echo "Error: --config is required"
  echo "Usage: bash validate-a2a.sh --config <agent-card.json>"
  exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file not found: $CONFIG_FILE"
  exit 1
fi

echo "Validating A2A Agent Card: $CONFIG_FILE"
echo "============================================"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed"
  echo "Install with: sudo apt-get install jq"
  exit 1
fi

# Validate JSON syntax
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
  echo "❌ FAIL: Invalid JSON syntax"
  exit 1
fi
echo "✅ PASS: Valid JSON syntax"

# Check required fields
REQUIRED_FIELDS=("id" "name" "description" "url" "capabilities" "protocol")
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! jq -e ".$field" "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "❌ FAIL: Missing required field: $field"
    exit 1
  fi
  echo "✅ PASS: Required field present: $field"
done

# Validate protocol version
PROTOCOL_VERSION=$(jq -r '.protocol.version' "$CONFIG_FILE")
if [[ ! "$PROTOCOL_VERSION" =~ ^0\.[0-9]+$ ]]; then
  echo "⚠️  WARN: Protocol version should be 0.x format: $PROTOCOL_VERSION"
else
  echo "✅ PASS: Valid protocol version: $PROTOCOL_VERSION"
fi

# Validate capabilities
if ! jq -e '.capabilities.skills' "$CONFIG_FILE" > /dev/null 2>&1; then
  echo "⚠️  WARN: No skills defined in capabilities"
else
  SKILL_COUNT=$(jq '.capabilities.skills | length' "$CONFIG_FILE")
  echo "✅ PASS: $SKILL_COUNT skills defined"
fi

# Validate modalities
if ! jq -e '.capabilities.modalities' "$CONFIG_FILE" > /dev/null 2>&1; then
  echo "⚠️  WARN: No modalities defined"
else
  MODALITIES=$(jq -r '.capabilities.modalities | join(", ")' "$CONFIG_FILE")
  echo "✅ PASS: Modalities: $MODALITIES"
fi

# Check URL accessibility (if verbose)
if [ "$VERBOSE" = true ]; then
  AGENT_URL=$(jq -r '.url' "$CONFIG_FILE")
  echo ""
  echo "Testing endpoint accessibility..."
  if curl -s -o /dev/null -w "%{http_code}" "$AGENT_URL/.well-known/agent.json" | grep -q "200"; then
    echo "✅ PASS: Agent Card accessible at $AGENT_URL/.well-known/agent.json"
  else
    echo "⚠️  WARN: Could not access Agent Card at $AGENT_URL/.well-known/agent.json"
  fi
fi

echo ""
echo "============================================"
echo "Validation complete!"
echo ""

if [ "$VERBOSE" = true ]; then
  echo "Agent Card contents:"
  jq . "$CONFIG_FILE"
fi
