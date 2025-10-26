#!/usr/bin/env bash
# run-newman.sh - Run Newman tests on Postman collection
# Usage: run-newman.sh <collection.json> [environment.json]

set -euo pipefail

COLLECTION="${1:?Collection file required}"
ENVIRONMENT="${2:-}"
OUTPUT_DIR="newman-results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build Newman command
CMD="newman run \"$COLLECTION\""
CMD="$CMD --reporters cli,json,html"
CMD="$CMD --reporter-json-export \"$OUTPUT_DIR/results-$TIMESTAMP.json\""
CMD="$CMD --reporter-html-export \"$OUTPUT_DIR/report-$TIMESTAMP.html\""

# Add environment if provided
if [ -n "$ENVIRONMENT" ]; then
    CMD="$CMD --environment \"$ENVIRONMENT\""
fi

# Add iterations and delay
CMD="$CMD --iteration-count 1"
CMD="$CMD --delay-request 100"

# Run Newman
echo "Running Newman tests..."
echo "Collection: $COLLECTION"
[ -n "$ENVIRONMENT" ] && echo "Environment: $ENVIRONMENT"
echo ""

eval "$CMD"

echo ""
echo "Results saved to: $OUTPUT_DIR/results-$TIMESTAMP.json"
echo "HTML report: $OUTPUT_DIR/report-$TIMESTAMP.html"
