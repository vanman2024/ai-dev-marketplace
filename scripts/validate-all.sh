#!/usr/bin/env bash
# validate-all.sh - Master validation script for entire plugin
# Usage: validate-all.sh <plugin-directory>

set -euo pipefail

PLUGIN_DIR="${1:?Plugin directory required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_COMMANDS=0
PASSED_COMMANDS=0
TOTAL_AGENTS=0
PASSED_AGENTS=0
TOTAL_SKILLS=0
PASSED_SKILLS=0

echo "========================================="
echo "  Plugin Validation: $(basename "$PLUGIN_DIR")"
echo "========================================="
echo ""

# Validate plugin structure
echo "[1/4] Validating plugin structure..."
if bash "$SCRIPT_DIR/validate-plugin.sh" "$PLUGIN_DIR"; then
    echo -e "${GREEN}✅ Plugin structure valid${NC}"
else
    echo -e "${RED}❌ Plugin structure invalid${NC}"
    exit 1
fi
echo ""

# Validate all commands
echo "[2/4] Validating commands..."
if [ -d "$PLUGIN_DIR/commands" ]; then
    for cmd in "$PLUGIN_DIR/commands"/*.md; do
        if [ -f "$cmd" ]; then
            TOTAL_COMMANDS=$((TOTAL_COMMANDS + 1))
            CMD_NAME=$(basename "$cmd")

            if bash "$SCRIPT_DIR/validate-command.sh" "$cmd" > /dev/null 2>&1; then
                PASSED_COMMANDS=$((PASSED_COMMANDS + 1))
                echo -e "  ${GREEN}✅${NC} $CMD_NAME"
            else
                echo -e "  ${RED}❌${NC} $CMD_NAME"
                # Show errors for failed commands
                bash "$SCRIPT_DIR/validate-command.sh" "$cmd" 2>&1 | grep -E "ERROR|WARNING" || true
            fi
        fi
    done
else
    echo -e "${YELLOW}⚠ No commands directory found${NC}"
fi

echo ""
echo "Commands: $PASSED_COMMANDS/$TOTAL_COMMANDS passed"
echo ""

# Validate all agents
echo "[3/4] Validating agents..."
if [ -d "$PLUGIN_DIR/agents" ]; then
    for agent in "$PLUGIN_DIR/agents"/*.md; do
        if [ -f "$agent" ]; then
            TOTAL_AGENTS=$((TOTAL_AGENTS + 1))
            AGENT_NAME=$(basename "$agent")

            if bash "$SCRIPT_DIR/validate-agent.sh" "$agent" > /dev/null 2>&1; then
                PASSED_AGENTS=$((PASSED_AGENTS + 1))
                echo -e "  ${GREEN}✅${NC} $AGENT_NAME"
            else
                echo -e "  ${RED}❌${NC} $AGENT_NAME"
                # Show errors for failed agents
                bash "$SCRIPT_DIR/validate-agent.sh" "$agent" 2>&1 | grep -E "ERROR|WARNING" || true
            fi
        fi
    done
else
    echo -e "${YELLOW}⚠ No agents directory found${NC}"
fi

echo ""
echo "Agents: $PASSED_AGENTS/$TOTAL_AGENTS passed"
echo ""

# Validate all skills
echo "[4/5] Validating skills..."
if [ -d "$PLUGIN_DIR/skills" ]; then
    for skill_dir in "$PLUGIN_DIR/skills"/*/; do
        if [ -d "$skill_dir" ]; then
            TOTAL_SKILLS=$((TOTAL_SKILLS + 1))
            SKILL_NAME=$(basename "$skill_dir")

            if bash "$SCRIPT_DIR/validate-skill.sh" "$skill_dir" > /dev/null 2>&1; then
                PASSED_SKILLS=$((PASSED_SKILLS + 1))
                echo -e "  ${GREEN}✅${NC} $SKILL_NAME"
            else
                echo -e "  ${RED}❌${NC} $SKILL_NAME"
            fi
        fi
    done

    if [ $TOTAL_SKILLS -eq 0 ]; then
        echo -e "${YELLOW}⚠ Skills directory empty${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No skills directory found${NC}"
fi

echo ""
if [ $TOTAL_SKILLS -gt 0 ]; then
    echo "Skills: $PASSED_SKILLS/$TOTAL_SKILLS passed"
fi
echo ""

# Validate plugin completeness (templates, examples, scripts)
echo "[5/5] Validating plugin completeness..."
if bash "$SCRIPT_DIR/validate-plugin-completeness.sh" "$PLUGIN_DIR"; then
    echo -e "${GREEN}✅ Plugin completeness check passed${NC}"
else
    echo -e "${RED}❌ Plugin completeness check failed${NC}"
    echo "Some skills may be missing templates, examples, or scripts."
fi
echo ""

# Summary
echo "========================================="
echo "  Validation Summary"
echo "========================================="
echo ""
echo "Commands: $PASSED_COMMANDS/$TOTAL_COMMANDS"
echo "Agents:   $PASSED_AGENTS/$TOTAL_AGENTS"
if [ $TOTAL_SKILLS -gt 0 ]; then
    echo "Skills:   $PASSED_SKILLS/$TOTAL_SKILLS"
fi
echo ""

# Calculate total
TOTAL=$((TOTAL_COMMANDS + TOTAL_AGENTS + TOTAL_SKILLS))
PASSED=$((PASSED_COMMANDS + PASSED_AGENTS + PASSED_SKILLS))

if [ $PASSED -eq $TOTAL ]; then
    echo -e "${GREEN}✅ ALL VALIDATIONS PASSED ($PASSED/$TOTAL)${NC}"
    echo ""
    exit 0
else
    FAILED=$((TOTAL - PASSED))
    echo -e "${RED}❌ VALIDATION FAILED: $FAILED failures out of $TOTAL total${NC}"
    echo ""
    echo "Fix the failed validations and run again."
    exit 1
fi
