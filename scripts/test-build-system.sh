#!/usr/bin/env bash
# Script: test-build-system.sh
# Purpose: Automated testing for domain-plugin-builder infrastructure
# Usage: ./test-build-system.sh [--quick|--full]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$HOME/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
SKIPPED=0

echo "================================================"
echo "Domain Plugin Builder Testing Suite"
echo "================================================"
echo ""
echo "Testing: $PLUGIN_DIR"
echo ""

# Test functions
test_file_exists() {
  local file=$1
  if [ -f "$file" ]; then
    echo -e "${GREEN}✓${NC} $file"
    PASSED=$((PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $file (missing)"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

test_dir_exists() {
  local dir=$1
  if [ -d "$dir" ]; then
    echo -e "${GREEN}✓${NC} $dir/"
    PASSED=$((PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $dir/ (missing)"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

test_executable() {
  local file=$1
  if [ -x "$file" ]; then
    echo -e "${GREEN}✓${NC} $file (executable)"
    PASSED=$((PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $file (not executable)"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

# Test 1: Core Directory Structure
echo "[1/8] Testing Core Directory Structure..."
test_dir_exists "$PLUGIN_DIR/commands"
test_dir_exists "$PLUGIN_DIR/agents"
test_dir_exists "$PLUGIN_DIR/skills"
test_dir_exists "$PLUGIN_DIR/docs"
test_dir_exists "$PLUGIN_DIR/skills/build-assistant/scripts"
test_dir_exists "$PLUGIN_DIR/skills/build-assistant/templates"
echo ""

# Test 2: Commands
echo "[2/8] Testing Commands..."
test_file_exists "$PLUGIN_DIR/commands/plugin-create.md"
test_file_exists "$PLUGIN_DIR/commands/build-plugin.md"
test_file_exists "$PLUGIN_DIR/commands/agents-create.md"
test_file_exists "$PLUGIN_DIR/commands/slash-commands-create.md"
test_file_exists "$PLUGIN_DIR/commands/skills-create.md"
test_file_exists "$PLUGIN_DIR/commands/hooks-create.md"
test_file_exists "$PLUGIN_DIR/commands/validate.md"
echo ""

# Test 3: Agents
echo "[3/8] Testing Agents..."
test_file_exists "$PLUGIN_DIR/agents/agents-builder.md"
test_file_exists "$PLUGIN_DIR/agents/slash-commands-builder.md"
test_file_exists "$PLUGIN_DIR/agents/skills-builder.md"
test_file_exists "$PLUGIN_DIR/agents/hooks-builder.md"
test_file_exists "$PLUGIN_DIR/agents/plugin-validator.md"
echo ""

# Test 4: Skills
echo "[4/8] Testing Skills..."
test_dir_exists "$PLUGIN_DIR/skills/build-assistant"
test_file_exists "$PLUGIN_DIR/skills/build-assistant/SKILL.md"
test_file_exists "$PLUGIN_DIR/skills/build-assistant/reference.md"
test_file_exists "$PLUGIN_DIR/skills/build-assistant/examples.md"
echo ""

# Test 5: Templates
echo "[5/8] Testing Templates..."
test_dir_exists "$PLUGIN_DIR/skills/build-assistant/templates/agents"
test_dir_exists "$PLUGIN_DIR/skills/build-assistant/templates/commands"
test_dir_exists "$PLUGIN_DIR/skills/build-assistant/templates/skills"
test_file_exists "$PLUGIN_DIR/skills/build-assistant/templates/agents/agent-with-phased-webfetch.md"
test_file_exists "$PLUGIN_DIR/skills/build-assistant/templates/commands/template-command-patterns.md"
test_file_exists "$PLUGIN_DIR/skills/build-assistant/templates/skills/SKILL.md.template"
echo ""

# Test 6: Documentation
echo "[6/8] Testing Documentation..."
test_file_exists "$PLUGIN_DIR/README.md"
test_file_exists "$PLUGIN_DIR/CLAUDE.md"
test_dir_exists "$PLUGIN_DIR/docs/frameworks/claude"
test_dir_exists "$PLUGIN_DIR/docs/frameworks/claude/agents"
test_dir_exists "$PLUGIN_DIR/docs/frameworks/claude/plugins"
test_dir_exists "$PLUGIN_DIR/docs/frameworks/claude/reference"
test_file_exists "$PLUGIN_DIR/docs/frameworks/claude/agents/agent-color-decision.md"
test_file_exists "$PLUGIN_DIR/docs/frameworks/claude/agents/agent-color-standard.md"
test_file_exists "$PLUGIN_DIR/docs/frameworks/claude/reference/component-decision-framework.md"
test_file_exists "$PLUGIN_DIR/docs/frameworks/claude/reference/dans-composition-pattern.md"
echo ""

# Test 7: Validation Scripts
echo "[7/8] Testing Validation Scripts..."
test_executable "$PLUGIN_DIR/skills/build-assistant/scripts/validate-agent.sh"
test_executable "$PLUGIN_DIR/skills/build-assistant/scripts/validate-command.sh"
test_executable "$PLUGIN_DIR/skills/build-assistant/scripts/validate-skill.sh"
test_executable "$PLUGIN_DIR/skills/build-assistant/scripts/validate-plugin.sh"
test_executable "$PLUGIN_DIR/skills/build-assistant/scripts/validate-all.sh"
test_executable "$PLUGIN_DIR/skills/build-assistant/scripts/sync-marketplace.sh"
test_executable "$PLUGIN_DIR/skills/build-assistant/scripts/register-commands-in-settings.sh"
test_executable "$PLUGIN_DIR/skills/build-assistant/scripts/register-skills-in-settings.sh"
echo ""

# Test 8: Configuration Files
echo "[8/8] Testing Configuration Files..."
test_file_exists "$PLUGIN_DIR/.claude-plugin/plugin.json"
test_file_exists "$HOME/.claude/plugins/marketplaces/domain-plugin-builder/docs/security/SECURITY-RULES.md"
echo ""

# Summary
echo "================================================"
echo "Test Summary"
echo "================================================"
echo -e "${GREEN}Passed:${NC}  $PASSED"
echo -e "${RED}Failed:${NC}  $FAILED"
echo -e "${YELLOW}Skipped:${NC} $SKIPPED"
echo ""

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
