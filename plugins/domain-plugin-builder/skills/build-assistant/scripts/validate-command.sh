#!/usr/bin/env bash
# Script: validate-command.sh
# Purpose: Validate slash command file compliance with framework standards
# Subsystem: build-system
# Called by: framework-slash-command after generation
# Outputs: Validation report to stdout

set -euo pipefail

COMMAND_FILE="${1:?Usage: $0 <command-file>}"
EXIT_CODE=0

echo "[INFO] Validating command file: $COMMAND_FILE"
echo ""

# Check file exists
if [[ ! -f "$COMMAND_FILE" ]]; then
    echo "❌ ERROR: File not found: $COMMAND_FILE"
    exit 1
fi

# Check frontmatter exists
if ! grep -q "^---$" "$COMMAND_FILE"; then
    echo "❌ ERROR: Missing frontmatter"
    EXIT_CODE=1
fi

# Check required frontmatter fields
REQUIRED_FIELDS=("allowed-tools:" "description:")
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! grep -q "^$field" "$COMMAND_FILE"; then
        echo "❌ ERROR: Missing required field: $field"
        EXIT_CODE=1
    fi
done

# Check file length (target: 120-150, allow 15% overage = 172)
LINE_COUNT=$(wc -l < "$COMMAND_FILE")
TARGET_MAX=150
TOLERANCE_MAX=172  # 150 + 15% overage

if ((LINE_COUNT > TOLERANCE_MAX)); then
    echo "❌ ERROR: Command file is $LINE_COUNT lines (max: $TOLERANCE_MAX with 15% tolerance)"
    EXIT_CODE=1
elif ((LINE_COUNT > TARGET_MAX)); then
    OVERAGE=$((LINE_COUNT - TARGET_MAX))
    echo "⚠️  WARNING: Command file is $LINE_COUNT lines (target: $TARGET_MAX, +$OVERAGE over)"
elif ((LINE_COUNT < 50)); then
    echo "⚠️  WARNING: Command file is $LINE_COUNT lines (might be too short)"
fi

# Check for $ARGUMENTS usage (not $1, $2, $3)
if grep -qE '\$[0-9]' "$COMMAND_FILE"; then
    echo "❌ ERROR: Found \$1/\$2/\$3 - use \$ARGUMENTS instead"
    EXIT_CODE=1
fi

if grep -q '\$ARGUMENTS' "$COMMAND_FILE" || grep -q 'DOLLAR_ARGUMENTS' "$COMMAND_FILE"; then
    echo "✅ Uses \$ARGUMENTS correctly"
else
    echo "⚠️  WARNING: No \$ARGUMENTS found"
fi

# Check for agent invocation patterns
USES_NATURAL_LANGUAGE=false
USES_EXPLICIT_TASK=false
USES_PARALLEL_PATTERN=false

# Check for natural language agent invocation
if grep -qiE "(Invoke the|Launch.*agent|Run.*agent)" "$COMMAND_FILE"; then
    USES_NATURAL_LANGUAGE=true
fi

# Check for explicit Task tool with subagent_type
if grep -q "subagent_type=" "$COMMAND_FILE"; then
    USES_EXPLICIT_TASK=true
fi

# Check for parallel execution pattern
if grep -qiE "(in parallel|IN PARALLEL|simultaneously|all at once)" "$COMMAND_FILE"; then
    USES_PARALLEL_PATTERN=true
fi

# Validate invocation patterns
if $USES_NATURAL_LANGUAGE || $USES_EXPLICIT_TASK; then
    if $USES_NATURAL_LANGUAGE; then
        echo "✅ Uses agent invocation (natural language)"
    fi
    if $USES_EXPLICIT_TASK; then
        echo "✅ Uses explicit Task tool with subagent_type"
    fi

    # If parallel pattern detected, check for proper implementation
    if $USES_PARALLEL_PATTERN; then
        echo "✅ Uses parallel execution pattern"

        # Check if it properly explains Task tool usage for parallel
        if grep -q "Task tool" "$COMMAND_FILE" && grep -q "SAME.*message\|single.*message\|ONE message" "$COMMAND_FILE"; then
            echo "✅ Properly explains parallel Task tool execution (multiple calls in ONE message)"
        elif $USES_EXPLICIT_TASK; then
            echo "✅ Uses explicit Task tool (parallel execution implied)"
        else
            echo "⚠️  WARNING: Parallel pattern found but no Task tool explanation"
            echo "    Consider adding explicit Task tool syntax for clarity"
        fi
    fi
else
    echo "⚠️  WARNING: No agent invocation found - might be Pattern 1 (simple command)"
fi

# Check for backticks in examples (causes parsing issues)
if grep -q '`' "$COMMAND_FILE"; then
    BACKTICK_COUNT=$(grep -o '`' "$COMMAND_FILE" | wc -l)
    echo "⚠️  WARNING: Found $BACKTICK_COUNT backticks - may cause parsing issues"
fi

# Check for code blocks (should NOT be in slash commands - use scripts instead)
if grep -q "\`\`\`" "$COMMAND_FILE"; then
    CODE_BLOCK_COUNT=$(grep -c "\`\`\`" "$COMMAND_FILE")
    echo "❌ ERROR: Found code blocks (triple backticks) - move code to scripts"
    EXIT_CODE=1
fi

# Check for proper allowed-tools format
if grep -q "allowed-tools:.*Task(\*)" "$COMMAND_FILE"; then
    echo "✅ Proper allowed-tools format found"
else
    echo "⚠️  WARNING: allowed-tools may not be properly formatted"
fi

# Check for bash execution patterns (! prefix)
if grep -q '!{' "$COMMAND_FILE"; then
    echo "✅ Uses bash execution pattern !{command}"
fi

# Check for file loading patterns (@ prefix)
if grep -q '@/' "$COMMAND_FILE" || grep -q '@[a-zA-Z]' "$COMMAND_FILE"; then
    echo "✅ Uses file loading pattern @filename"
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Command validation passed"
else
    echo "❌ Command validation failed"
fi

exit $EXIT_CODE
