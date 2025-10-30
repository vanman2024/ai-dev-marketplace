#!/usr/bin/env bash
# generate-client.sh - Generate API client boilerplate from templates
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Get arguments
LANGUAGE="${1:-}"
OUTPUT_PATH="${2:-}"

show_usage() {
    echo "Usage: bash scripts/generate-client.sh [typescript|python] [output-path]"
    echo ""
    echo "Arguments:"
    echo "  language      typescript or python"
    echo "  output-path   Where to generate the client file"
    echo ""
    echo "Examples:"
    echo "  bash scripts/generate-client.sh typescript src/lib/elevenlabs.ts"
    echo "  bash scripts/generate-client.sh python src/elevenlabs_client.py"
    echo ""
    echo "Available templates:"
    echo "  TypeScript:"
    echo "    - api-client.ts.template (standard)"
    echo "    - api-client-nextjs.ts.template (Next.js server-side)"
    echo "    - api-client-edge.ts.template (edge runtime)"
    echo "  Python:"
    echo "    - api-client.py.template (standard)"
    echo "    - api-client-async.py.template (async with pooling)"
    echo "    - api-client-fastapi.py.template (FastAPI integration)"
    exit 1
}

# Validate arguments
if [[ -z "$LANGUAGE" ]] || [[ -z "$OUTPUT_PATH" ]]; then
    show_usage
fi

# Normalize language
case "$LANGUAGE" in
    typescript|ts|node|nodejs|javascript|js)
        LANGUAGE="typescript"
        TEMPLATE="$SKILL_DIR/templates/api-client.ts.template"
        ;;
    python|py)
        LANGUAGE="python"
        TEMPLATE="$SKILL_DIR/templates/api-client.py.template"
        ;;
    *)
        echo -e "${RED}Error: Invalid language '$LANGUAGE'${NC}"
        echo ""
        show_usage
        ;;
esac

echo "ElevenLabs Client Generator"
echo "==========================="
echo ""
echo "Language: $LANGUAGE"
echo "Output: $OUTPUT_PATH"
echo ""

# Check if template exists
if [[ ! -f "$TEMPLATE" ]]; then
    echo -e "${RED}Error: Template not found: $TEMPLATE${NC}"
    exit 1
fi

# Check if output file already exists
if [[ -f "$OUTPUT_PATH" ]]; then
    echo -e "${YELLOW}Warning: File already exists: $OUTPUT_PATH${NC}"
    echo "Overwrite? (y/n)"
    read -r overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "Generation cancelled."
        exit 0
    fi
fi

# Create output directory if it doesn't exist
OUTPUT_DIR="$(dirname "$OUTPUT_PATH")"
if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Creating directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
fi

# For TypeScript, check for framework-specific templates
if [[ "$LANGUAGE" == "typescript" ]]; then
    # Check if this is a Next.js project
    if [[ -f "next.config.js" ]] || [[ -f "next.config.ts" ]] || [[ -f "next.config.mjs" ]]; then
        echo -e "${BLUE}Next.js project detected${NC}"
        echo "Use Next.js server-side template? (y/n)"
        read -r use_nextjs
        if [[ "$use_nextjs" =~ ^[Yy]$ ]]; then
            TEMPLATE="$SKILL_DIR/templates/api-client-nextjs.ts.template"
        fi
    fi

    # Check for edge runtime indication
    if [[ "$OUTPUT_PATH" == *"edge"* ]] || [[ "$OUTPUT_PATH" == *"middleware"* ]]; then
        echo -e "${BLUE}Edge runtime path detected${NC}"
        echo "Use edge runtime template? (y/n)"
        read -r use_edge
        if [[ "$use_edge" =~ ^[Yy]$ ]]; then
            TEMPLATE="$SKILL_DIR/templates/api-client-edge.ts.template"
        fi
    fi
fi

# For Python, check for framework-specific templates
if [[ "$LANGUAGE" == "python" ]]; then
    # Check if this is a FastAPI project
    if grep -r "from fastapi import" . --include="*.py" 2>/dev/null | head -1 > /dev/null; then
        echo -e "${BLUE}FastAPI project detected${NC}"
        echo "Use FastAPI integration template? (y/n)"
        read -r use_fastapi
        if [[ "$use_fastapi" =~ ^[Yy]$ ]]; then
            TEMPLATE="$SKILL_DIR/templates/api-client-fastapi.py.template"
        fi
    fi

    # Check for async indication
    if [[ "$OUTPUT_PATH" == *"async"* ]]; then
        echo -e "${BLUE}Async path detected${NC}"
        echo "Use async template? (y/n)"
        read -r use_async
        if [[ "$use_async" =~ ^[Yy]$ ]]; then
            TEMPLATE="$SKILL_DIR/templates/api-client-async.py.template"
        fi
    fi
fi

# Copy template to output path
echo "Generating client from template..."
cp "$TEMPLATE" "$OUTPUT_PATH"

echo -e "${GREEN}✓ Client generated successfully${NC}"
echo ""
echo "Generated file: $OUTPUT_PATH"
echo "Template used: $(basename "$TEMPLATE")"
echo ""

# Show next steps based on language
if [[ "$LANGUAGE" == "typescript" ]]; then
    echo "Next steps:"
    echo "1. Ensure SDK is installed: bash scripts/install-sdk.sh typescript"
    echo "2. Configure .env: bash scripts/setup-auth.sh"
    echo "3. Import and use the client:"
    echo "   import { createElevenLabsClient } from './${OUTPUT_PATH#*/}'"
    echo "   const client = createElevenLabsClient()"
else
    echo "Next steps:"
    echo "1. Ensure SDK is installed: bash scripts/install-sdk.sh python"
    echo "2. Configure .env: bash scripts/setup-auth.sh"
    echo "3. Import and use the client:"
    echo "   from ${OUTPUT_PATH%.py} import create_elevenlabs_client"
    echo "   client = create_elevenlabs_client()"
fi

echo ""
echo "See examples for usage patterns:"
echo "  ls $SKILL_DIR/examples/"
