#!/usr/bin/env bash
# Script: validate-skill.sh
# Purpose: Validate Agent Skill directory compliance with Claude Code standards
# Subsystem: build-system
# Called by: /build:skill command after generation
# Outputs: Validation report to stdout

set -euo pipefail

SKILL_DIR="${1:?Usage: $0 <skill-directory>}"
EXIT_CODE=0

echo "[INFO] Validating skill directory: $SKILL_DIR"
echo ""

# Check directory exists
if [[ ! -d "$SKILL_DIR" ]]; then
    echo "❌ ERROR: Directory not found: $SKILL_DIR"
    exit 1
fi

# Check SKILL.md exists
if [[ ! -f "$SKILL_DIR/SKILL.md" ]]; then
    echo "❌ ERROR: Missing SKILL.md file"
    exit 1
fi

# Check frontmatter exists
if ! grep -q "^---$" "$SKILL_DIR/SKILL.md"; then
    echo "❌ ERROR: Missing frontmatter in SKILL.md"
    exit 1
fi

# Check required frontmatter fields
REQUIRED_FIELDS=("name:" "description:")
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! grep -q "^$field" "$SKILL_DIR/SKILL.md"; then
        echo "❌ ERROR: Missing required field: $field"
        exit 1
    fi
done

# Check description includes trigger keywords
if ! grep -q "Use when" "$SKILL_DIR/SKILL.md"; then
    echo "⚠️  WARNING: Description should include 'Use when' trigger context"
fi

echo ""
echo "[INFO] Checking minimum requirements (scripts, templates, examples)..."
echo ""

# Minimum requirements per skill
MIN_SCRIPTS=3
MIN_TEMPLATES=4
MIN_EXAMPLES=3

# Count scripts
if [[ -d "$SKILL_DIR/scripts" ]]; then
    SCRIPT_COUNT=$(find "$SKILL_DIR/scripts" -type f -name "*.sh" | wc -l)
    echo "📂 Scripts found: $SCRIPT_COUNT"

    if ((SCRIPT_COUNT >= MIN_SCRIPTS)); then
        echo "   ✅ Meets minimum requirement (>= $MIN_SCRIPTS scripts)"
    else
        echo "   ❌ ERROR: Below minimum requirement (need $MIN_SCRIPTS, found $SCRIPT_COUNT)"
        echo "      Each skill should have 3-5 helper scripts (setup, validate, generate, etc.)"
        EXIT_CODE=1
    fi

    # List scripts
    if ((SCRIPT_COUNT > 0)); then
        echo "   Scripts:"
        find "$SKILL_DIR/scripts" -type f -name "*.sh" -exec basename {} \; | sed 's/^/     - /'
    fi
else
    echo "📂 Scripts: directory not found"
    echo "   ❌ ERROR: Missing scripts/ directory"
    EXIT_CODE=1
fi

echo ""

# Count templates
if [[ -d "$SKILL_DIR/templates" ]]; then
    TEMPLATE_COUNT=$(find "$SKILL_DIR/templates" -type f | wc -l)
    echo "📂 Templates found: $TEMPLATE_COUNT"

    if ((TEMPLATE_COUNT >= MIN_TEMPLATES)); then
        echo "   ✅ Meets minimum requirement (>= $MIN_TEMPLATES templates)"
    else
        echo "   ❌ ERROR: Below minimum requirement (need $MIN_TEMPLATES, found $TEMPLATE_COUNT)"
        echo "      Each skill should have 4-6 templates (basic, advanced, TS, Python, etc.)"
        EXIT_CODE=1
    fi

    # Check for TypeScript and Python coverage
    TS_COUNT=$(find "$SKILL_DIR/templates" -type f -name "*.ts" -o -name "*.tsx" | wc -l)
    PY_COUNT=$(find "$SKILL_DIR/templates" -type f -name "*.py" | wc -l)

    if ((TS_COUNT > 0)) && ((PY_COUNT > 0)); then
        echo "   ✅ Has both TypeScript ($TS_COUNT) and Python ($PY_COUNT) templates"
    elif ((TS_COUNT > 0)); then
        echo "   ⚠️  WARNING: Has TypeScript templates but no Python templates"
    elif ((PY_COUNT > 0)); then
        echo "   ⚠️  WARNING: Has Python templates but no TypeScript templates"
    fi

    # List templates by type
    if ((TEMPLATE_COUNT > 0)); then
        echo "   Templates:"
        find "$SKILL_DIR/templates" -type f | sed "s|$SKILL_DIR/templates/||" | sed 's/^/     - /'
    fi
else
    echo "📂 Templates: directory not found"
    echo "   ❌ ERROR: Missing templates/ directory"
    EXIT_CODE=1
fi

echo ""

# Count examples
if [[ -d "$SKILL_DIR/examples" ]]; then
    EXAMPLE_COUNT=$(find "$SKILL_DIR/examples" -type f -name "*.md" | wc -l)
    echo "📂 Examples found: $EXAMPLE_COUNT"

    if ((EXAMPLE_COUNT >= MIN_EXAMPLES)); then
        echo "   ✅ Meets minimum requirement (>= $MIN_EXAMPLES examples)"
    else
        echo "   ❌ ERROR: Below minimum requirement (need $MIN_EXAMPLES, found $EXAMPLE_COUNT)"
        echo "      Each skill should have 3-5 examples (basic, advanced, patterns, edge-cases, integration)"
        EXIT_CODE=1
    fi

    # List examples
    if ((EXAMPLE_COUNT > 0)); then
        echo "   Examples:"
        find "$SKILL_DIR/examples" -type f -name "*.md" -exec basename {} \; | sed 's/^/     - /'
    fi
else
    echo "📂 Examples: directory not found"
    echo "   ❌ ERROR: Missing examples/ directory"
    EXIT_CODE=1
fi

echo ""

# Cross-reference: Check that SKILL.md references match actual files
echo "[INFO] Checking SKILL.md references match actual files..."
echo ""

# Count references in SKILL.md
SCRIPT_REFS=$(grep -oE 'scripts/[a-zA-Z0-9_-]+\.sh' "$SKILL_DIR/SKILL.md" 2>/dev/null | sort -u | wc -l || echo 0)
TEMPLATE_REFS=$(grep -oE 'templates/[a-zA-Z0-9_/.-]+\.(ts|py|tsx|js)' "$SKILL_DIR/SKILL.md" 2>/dev/null | sort -u | wc -l || echo 0)
EXAMPLE_REFS=$(grep -oE 'examples/[a-zA-Z0-9_-]+\.md' "$SKILL_DIR/SKILL.md" 2>/dev/null | sort -u | wc -l || echo 0)

echo "📝 SKILL.md references:"
echo "   Scripts referenced: $SCRIPT_REFS"
echo "   Templates referenced: $TEMPLATE_REFS"
echo "   Examples referenced: $EXAMPLE_REFS"

echo ""

# Compare references to actual files
if [[ -d "$SKILL_DIR/scripts" ]]; then
    if ((SCRIPT_REFS == SCRIPT_COUNT)); then
        echo "   ✅ Script references match actual files ($SCRIPT_REFS = $SCRIPT_COUNT)"
    else
        echo "   ⚠️  WARNING: Script count mismatch (referenced: $SCRIPT_REFS, actual: $SCRIPT_COUNT)"
    fi
fi

if [[ -d "$SKILL_DIR/templates" ]]; then
    if ((TEMPLATE_REFS == TEMPLATE_COUNT)); then
        echo "   ✅ Template references match actual files ($TEMPLATE_REFS = $TEMPLATE_COUNT)"
    else
        echo "   ⚠️  WARNING: Template count mismatch (referenced: $TEMPLATE_REFS, actual: $TEMPLATE_COUNT)"
    fi
fi

if [[ -d "$SKILL_DIR/examples" ]]; then
    if ((EXAMPLE_REFS == EXAMPLE_COUNT)); then
        echo "   ✅ Example references match actual files ($EXAMPLE_REFS = $EXAMPLE_COUNT)"
    else
        echo "   ⚠️  WARNING: Example count mismatch (referenced: $EXAMPLE_REFS, actual: $EXAMPLE_COUNT)"
    fi
fi

echo ""

# Final result
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Skill validation passed - all minimum requirements met!"
else
    echo "❌ Skill validation failed - does not meet minimum requirements"
fi

exit $EXIT_CODE
