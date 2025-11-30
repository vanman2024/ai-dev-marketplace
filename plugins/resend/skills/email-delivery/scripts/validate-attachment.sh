#!/bin/bash

# Validate attachments for email sending
# Checks file size, type, and other constraints

set -e

FILE_PATH=${1:-}

if [ -z "$FILE_PATH" ]; then
    echo "Usage: validate-attachment.sh <file_path>"
    echo ""
    echo "Validates email attachments for:"
    echo "  - File existence"
    echo "  - File size (max 25MB total)"
    echo "  - Supported file types"
    exit 1
fi

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Validating attachment: $FILE_PATH"
echo "========================================"

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    echo -e "${RED}✗ File not found: $FILE_PATH${NC}"
    exit 1
else
    echo -e "${GREEN}✓ File exists${NC}"
fi

# Get file info
FILE_NAME=$(basename "$FILE_PATH")
FILE_SIZE=$(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH" 2>/dev/null)
FILE_EXT="${FILE_NAME##*.}"
FILE_TYPE=$(file -b "$FILE_PATH" | cut -d, -f1)

echo "File: $FILE_NAME"
echo "Size: $(numfmt --to=iec-i --suffix=B $FILE_SIZE 2>/dev/null || echo "$FILE_SIZE bytes")"
echo "Type: $FILE_TYPE"
echo ""

# Size validation
MAX_SIZE=$((25 * 1024 * 1024)) # 25MB
if [ $FILE_SIZE -gt $MAX_SIZE ]; then
    echo -e "${RED}✗ File exceeds 25MB limit (${FILE_SIZE} bytes)${NC}"
    exit 1
else
    echo -e "${GREEN}✓ File size is within 25MB limit${NC}"
fi

# Recommended max size warning
RECOMMENDED_MAX=$((10 * 1024 * 1024)) # 10MB
if [ $FILE_SIZE -gt $RECOMMENDED_MAX ]; then
    echo -e "${YELLOW}⚠ File exceeds recommended 10MB (may have delivery issues)${NC}"
fi

# Supported file types
SUPPORTED_TYPES=(
    "PDF"
    "ASCII text"
    "Microsoft Word"
    "Microsoft Excel"
    "Microsoft PowerPoint"
    "image"
    "ZIP"
    "gzip compressed"
)

SUPPORTED=false
for TYPE in "${SUPPORTED_TYPES[@]}"; do
    if [[ "$FILE_TYPE" == *"$TYPE"* ]]; then
        SUPPORTED=true
        break
    fi
done

if [ "$SUPPORTED" = true ]; then
    echo -e "${GREEN}✓ File type is supported${NC}"
else
    echo -e "${YELLOW}⚠ File type may not be supported: $FILE_TYPE${NC}"
fi

# File extension check
SAFE_EXTENSIONS=(pdf txt csv xlsx xls docx doc pptx ppt zip tar gz jpg jpeg png gif)
SAFE=false
for EXT in "${SAFE_EXTENSIONS[@]}"; do
    if [ "$FILE_EXT" = "$EXT" ] || [ "$FILE_EXT" = "${EXT^^}" ]; then
        SAFE=true
        break
    fi
done

if [ "$SAFE" = true ]; then
    echo -e "${GREEN}✓ File extension is safe${NC}"
else
    echo -e "${YELLOW}⚠ File extension not in common list: .$FILE_EXT${NC}"
fi

# Security check: executable files
if file "$FILE_PATH" | grep -q -i "executable"; then
    echo -e "${RED}✗ Executable files cannot be sent as attachments${NC}"
    exit 1
fi

if file "$FILE_PATH" | grep -q -i "script"; then
    echo -e "${RED}✗ Script files cannot be sent as attachments${NC}"
    exit 1
fi

echo -e "${GREEN}✓ No executable or script files${NC}"

# Check for suspicious patterns
if [[ "$FILE_NAME" == *".exe"* ]] || [[ "$FILE_NAME" == *".bat"* ]] || [[ "$FILE_NAME" == *".sh"* ]]; then
    echo -e "${RED}✗ Suspicious file extension in filename${NC}"
    exit 1
fi
echo -e "${GREEN}✓ No suspicious file extensions${NC}"

echo ""
echo "========================================"
echo -e "${GREEN}Attachment validation passed!${NC}"
echo ""
echo "Ready to use in email:"
echo "  attachments: [{"
echo "    filename: \"$FILE_NAME\","
echo "    content: \"<file content>\""
echo "  }]"
