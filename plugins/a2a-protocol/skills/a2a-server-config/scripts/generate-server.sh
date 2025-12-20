#!/bin/bash
# Generate A2A server from template

set -e

TRANSPORT_TYPE="$1"
LANGUAGE="$2"
OUTPUT_FILE="$3"

if [ -z "$TRANSPORT_TYPE" ] || [ -z "$LANGUAGE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <transport-type> <language> <output-file>"
    echo ""
    echo "Transport types: http, stdio, sse, websocket"
    echo "Languages: python, typescript"
    echo ""
    echo "Example: $0 http python server.py"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

# Validate transport type
case "$TRANSPORT_TYPE" in
    http|stdio|sse|websocket)
        ;;
    *)
        echo "Error: Invalid transport type: $TRANSPORT_TYPE"
        echo "Valid types: http, stdio, sse, websocket"
        exit 1
        ;;
esac

# Validate language
case "$LANGUAGE" in
    python)
        TEMPLATE_FILE="$TEMPLATES_DIR/${LANGUAGE}-${TRANSPORT_TYPE}-server.py"
        ;;
    typescript)
        TEMPLATE_FILE="$TEMPLATES_DIR/${LANGUAGE}-${TRANSPORT_TYPE}-server.ts"
        ;;
    *)
        echo "Error: Invalid language: $LANGUAGE"
        echo "Valid languages: python, typescript"
        exit 1
        ;;
esac

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template not found: $TEMPLATE_FILE"
    exit 1
fi

echo "Generating $LANGUAGE $TRANSPORT_TYPE server..."
echo "Template: $TEMPLATE_FILE"
echo "Output: $OUTPUT_FILE"

# Copy template
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

echo "Server generated successfully!"
echo ""
echo "Next steps:"
echo "1. Review and customize the server configuration"
echo "2. Create .env file from .env.example"
echo "3. Install dependencies:"
if [ "$LANGUAGE" = "python" ]; then
    echo "   pip install -r requirements.txt"
elif [ "$LANGUAGE" = "typescript" ]; then
    echo "   npm install"
fi
echo "4. Run validation: bash $SCRIPT_DIR/validate-config.sh $OUTPUT_FILE"
echo "5. Start the server"
