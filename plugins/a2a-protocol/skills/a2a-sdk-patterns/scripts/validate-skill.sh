#!/bin/bash
# Validate A2A SDK Patterns Skill
# Checks skill structure, frontmatter, scripts, templates, and examples

set -e

SKILL_DIR="/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/a2a-protocol/skills/a2a-sdk-patterns"

echo "Validating A2A SDK Patterns skill..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to check file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        return 0
    else
        echo -e "${RED}✗${NC} $2 - File not found: $1"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        return 0
    else
        echo -e "${RED}✗${NC} $2 - Directory not found: $1"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Check SKILL.md exists
echo "=== Checking SKILL.md ==="
if check_file "$SKILL_DIR/SKILL.md" "SKILL.md exists"; then
    # Check frontmatter starts at line 1
    FIRST_LINE=$(head -n 1 "$SKILL_DIR/SKILL.md")
    if [ "$FIRST_LINE" = "---" ]; then
        echo -e "${GREEN}✓${NC} Frontmatter starts at line 1"
    else
        echo -e "${RED}✗${NC} Frontmatter must start at line 1 (found: '$FIRST_LINE')"
        ERRORS=$((ERRORS + 1))
    fi

    # Check for required frontmatter fields
    if grep -q "^name:" "$SKILL_DIR/SKILL.md"; then
        echo -e "${GREEN}✓${NC} Has 'name' field"
    else
        echo -e "${RED}✗${NC} Missing 'name' field in frontmatter"
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q "^description:" "$SKILL_DIR/SKILL.md"; then
        echo -e "${GREEN}✓${NC} Has 'description' field"
    else
        echo -e "${RED}✗${NC} Missing 'description' field in frontmatter"
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q "^allowed-tools:" "$SKILL_DIR/SKILL.md"; then
        echo -e "${GREEN}✓${NC} Has 'allowed-tools' field"
    else
        echo -e "${YELLOW}⚠${NC} Missing 'allowed-tools' field (optional)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi
echo ""

# Check directory structure
echo "=== Checking Directory Structure ==="
check_dir "$SKILL_DIR/scripts" "scripts/ directory exists"
check_dir "$SKILL_DIR/templates" "templates/ directory exists"
check_dir "$SKILL_DIR/examples" "examples/ directory exists"
echo ""

# Check scripts (must have at least 3)
echo "=== Checking Scripts ==="
SCRIPT_COUNT=$(find "$SKILL_DIR/scripts" -name "*.sh" -type f | wc -l)
if [ "$SCRIPT_COUNT" -ge 3 ]; then
    echo -e "${GREEN}✓${NC} Has $SCRIPT_COUNT scripts (minimum 3 required)"
else
    echo -e "${RED}✗${NC} Has $SCRIPT_COUNT scripts (minimum 3 required)"
    ERRORS=$((ERRORS + 1))
fi

# Check specific installation scripts
check_file "$SKILL_DIR/scripts/install-python.sh" "install-python.sh exists"
check_file "$SKILL_DIR/scripts/install-typescript.sh" "install-typescript.sh exists"
check_file "$SKILL_DIR/scripts/validate-python.sh" "validate-python.sh exists"
check_file "$SKILL_DIR/scripts/validate-typescript.sh" "validate-typescript.sh exists"

# Check scripts are executable
for script in "$SKILL_DIR/scripts"/*.sh; do
    if [ -x "$script" ]; then
        echo -e "${GREEN}✓${NC} $(basename "$script") is executable"
    else
        echo -e "${YELLOW}⚠${NC} $(basename "$script") is not executable"
        WARNINGS=$((WARNINGS + 1))
    fi
done
echo ""

# Check templates (must have at least 4)
echo "=== Checking Templates ==="
TEMPLATE_COUNT=$(find "$SKILL_DIR/templates" -type f | wc -l)
if [ "$TEMPLATE_COUNT" -ge 4 ]; then
    echo -e "${GREEN}✓${NC} Has $TEMPLATE_COUNT templates (minimum 4 required)"
else
    echo -e "${RED}✗${NC} Has $TEMPLATE_COUNT templates (minimum 4 required)"
    ERRORS=$((ERRORS + 1))
fi

# Check for key templates
check_file "$SKILL_DIR/templates/env-template.txt" "env-template.txt exists"
check_file "$SKILL_DIR/templates/python-config.py" "python-config.py exists"
check_file "$SKILL_DIR/templates/typescript-config.ts" "typescript-config.ts exists"

# Check templates have both Python and TypeScript
HAS_PYTHON=0
HAS_TYPESCRIPT=0
if ls "$SKILL_DIR/templates"/*.py >/dev/null 2>&1; then
    HAS_PYTHON=1
fi
if ls "$SKILL_DIR/templates"/*.ts >/dev/null 2>&1; then
    HAS_TYPESCRIPT=1
fi

if [ "$HAS_PYTHON" -eq 1 ]; then
    echo -e "${GREEN}✓${NC} Has Python template"
else
    echo -e "${RED}✗${NC} Missing Python template"
    ERRORS=$((ERRORS + 1))
fi

if [ "$HAS_TYPESCRIPT" -eq 1 ]; then
    echo -e "${GREEN}✓${NC} Has TypeScript template"
else
    echo -e "${RED}✗${NC} Missing TypeScript template"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check examples (must have at least 3)
echo "=== Checking Examples ==="
EXAMPLE_COUNT=$(find "$SKILL_DIR/examples" -type f | wc -l)
if [ "$EXAMPLE_COUNT" -ge 3 ]; then
    echo -e "${GREEN}✓${NC} Has $EXAMPLE_COUNT examples (minimum 3 required)"
else
    echo -e "${RED}✗${NC} Has $EXAMPLE_COUNT examples (minimum 3 required)"
    ERRORS=$((ERRORS + 1))
fi

# Check for key examples
check_file "$SKILL_DIR/examples/python-basic.py" "python-basic.py exists"
check_file "$SKILL_DIR/examples/typescript-basic.ts" "typescript-basic.ts exists"
echo ""

# Check README.md
echo "=== Checking Documentation ==="
check_file "$SKILL_DIR/README.md" "README.md exists"
echo ""

# Check for hardcoded API keys (security check)
echo "=== Security Check ==="
HARDCODED_KEYS=0

# Check for common API key patterns
if grep -r "sk-ant-api03-" "$SKILL_DIR" --exclude="*.md" --exclude="README.md" 2>/dev/null | grep -v "your_.*_key_here" | grep -v "placeholder" | grep -v "example"; then
    echo -e "${RED}✗${NC} Found hardcoded Anthropic API key"
    HARDCODED_KEYS=1
fi

if grep -r "sk-proj-" "$SKILL_DIR" --exclude="*.md" --exclude="README.md" 2>/dev/null | grep -v "your_.*_key_here" | grep -v "placeholder" | grep -v "example"; then
    echo -e "${RED}✗${NC} Found hardcoded OpenAI API key"
    HARDCODED_KEYS=1
fi

if [ "$HARDCODED_KEYS" -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No hardcoded API keys found"
else
    echo -e "${RED}✗${NC} Security violation: Hardcoded API keys detected"
    ERRORS=$((ERRORS + 1))
fi

# Check for proper placeholders
if grep -r "your_.*_key_here" "$SKILL_DIR/templates" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Templates use proper placeholders"
else
    echo -e "${YELLOW}⚠${NC} Templates should use 'your_*_key_here' placeholders"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Summary
echo "=== Validation Summary ==="
echo ""
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Skill is ready to use."
    exit 0
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation passed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "Skill is functional but consider addressing warnings."
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before using this skill."
    exit 1
fi
