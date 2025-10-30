#!/usr/bin/env bash
# Validate and audit MCP tool approval permissions for security
# Usage: ./validate-tool-permissions.sh [config-file]

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default config file
CONFIG_FILE="${1:-.elevenlabs/mcp-config.json}"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  MCP Tool Permission Security Audit                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${RED}✗ Configuration file not found: $CONFIG_FILE${NC}"
  echo ""
  echo "Usage: $0 [config-file]"
  echo "  Default: .elevenlabs/mcp-config.json"
  exit 1
fi

echo -e "Auditing: ${YELLOW}$CONFIG_FILE${NC}"
echo ""

# Validate JSON
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
  echo -e "${RED}✗ Invalid JSON in configuration file${NC}"
  exit 1
fi

# Security checks
ISSUES_FOUND=0
WARNINGS_FOUND=0
RECOMMENDATIONS=()

echo -e "${BLUE}[1/6] Checking approval modes...${NC}"
echo ""

# Check each MCP server
SERVER_COUNT=$(jq '.mcpServers | length' "$CONFIG_FILE")

if [[ "$SERVER_COUNT" -eq 0 ]]; then
  echo -e "${YELLOW}⚠ No MCP servers configured${NC}"
  exit 0
fi

for SERVER in $(jq -r '.mcpServers | keys[]' "$CONFIG_FILE"); do
  APPROVAL_MODE=$(jq -r ".mcpServers[\"$SERVER\"].approvalMode // \"not_set\"" "$CONFIG_FILE")
  SERVER_URL=$(jq -r ".mcpServers[\"$SERVER\"].url // \"not_set\"" "$CONFIG_FILE")

  echo -e "  Server: ${BLUE}$SERVER${NC}"
  echo -e "  URL: $SERVER_URL"

  case $APPROVAL_MODE in
    "always_ask")
      echo -e "  Approval Mode: ${GREEN}Always Ask ✓${NC} (Recommended)"
      ;;
    "fine_grained")
      echo -e "  Approval Mode: ${YELLOW}Fine-Grained ⚠${NC}"
      WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
      RECOMMENDATIONS+=("Review fine-grained settings for '$SERVER'")
      ;;
    "no_approval")
      echo -e "  Approval Mode: ${RED}No Approval ✗${NC} (High Risk)"
      ISSUES_FOUND=$((ISSUES_FOUND + 1))
      RECOMMENDATIONS+=("Change '$SERVER' to 'Always Ask' or 'Fine-Grained' mode")
      ;;
    *)
      echo -e "  Approval Mode: ${RED}Not Set ✗${NC}"
      ISSUES_FOUND=$((ISSUES_FOUND + 1))
      RECOMMENDATIONS+=("Set approval mode for '$SERVER'")
      ;;
  esac

  echo ""
done

echo -e "${BLUE}[2/6] Checking authentication security...${NC}"
echo ""

for SERVER in $(jq -r '.mcpServers | keys[]' "$CONFIG_FILE"); do
  HAS_AUTH_HEADER=$(jq -r ".mcpServers[\"$SERVER\"].headers.Authorization // \"none\"" "$CONFIG_FILE")
  HAS_SECRET_TOKEN=$(jq -r ".mcpServers[\"$SERVER\"].secretToken // \"none\"" "$CONFIG_FILE")

  echo -e "  Server: ${BLUE}$SERVER${NC}"

  if [[ "$HAS_AUTH_HEADER" != "none" ]]; then
    # Check if token is hardcoded
    if [[ "$HAS_AUTH_HEADER" =~ ^Bearer\ [A-Za-z0-9_-]+$ ]]; then
      echo -e "  Authentication: ${RED}Hardcoded token detected ✗${NC}"
      ISSUES_FOUND=$((ISSUES_FOUND + 1))
      RECOMMENDATIONS+=("Move token for '$SERVER' to environment variable")
    else
      echo -e "  Authentication: ${GREEN}Configured ✓${NC}"
    fi
  elif [[ "$HAS_SECRET_TOKEN" != "none" ]]; then
    echo -e "  Authentication: ${GREEN}Secret token configured ✓${NC}"
  else
    echo -e "  Authentication: ${YELLOW}None ⚠${NC}"
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
  fi

  echo ""
done

echo -e "${BLUE}[3/6] Checking transport security...${NC}"
echo ""

for SERVER in $(jq -r '.mcpServers | keys[]' "$CONFIG_FILE"); do
  SERVER_URL=$(jq -r ".mcpServers[\"$SERVER\"].url" "$CONFIG_FILE")

  echo -e "  Server: ${BLUE}$SERVER${NC}"

  if [[ "$SERVER_URL" =~ ^https:// ]]; then
    echo -e "  Transport: ${GREEN}HTTPS ✓${NC}"
  elif [[ "$SERVER_URL" =~ ^http:// ]]; then
    echo -e "  Transport: ${RED}HTTP ✗${NC} (Insecure)"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    RECOMMENDATIONS+=("Switch '$SERVER' to HTTPS")
  else
    echo -e "  Transport: ${YELLOW}Unknown ⚠${NC}"
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
  fi

  echo ""
done

echo -e "${BLUE}[4/6] Checking fine-grained tool configurations...${NC}"
echo ""

FINE_GRAINED_COUNT=0

for SERVER in $(jq -r '.mcpServers | keys[]' "$CONFIG_FILE"); do
  APPROVAL_MODE=$(jq -r ".mcpServers[\"$SERVER\"].approvalMode" "$CONFIG_FILE")

  if [[ "$APPROVAL_MODE" == "fine_grained" ]]; then
    FINE_GRAINED_COUNT=$((FINE_GRAINED_COUNT + 1))
    echo -e "  Server: ${BLUE}$SERVER${NC}"

    # Check for tool-specific settings
    AUTO_APPROVED=$(jq -r ".mcpServers[\"$SERVER\"].autoApprovedTools // [] | length" "$CONFIG_FILE")
    REQUIRES_APPROVAL=$(jq -r ".mcpServers[\"$SERVER\"].requiresApprovalTools // [] | length" "$CONFIG_FILE")
    DISABLED=$(jq -r ".mcpServers[\"$SERVER\"].disabledTools // [] | length" "$CONFIG_FILE")

    echo "  Auto-approved tools: $AUTO_APPROVED"
    echo "  Requires approval: $REQUIRES_APPROVAL"
    echo "  Disabled tools: $DISABLED"

    if [[ "$AUTO_APPROVED" -eq 0 ]] && [[ "$REQUIRES_APPROVAL" -eq 0 ]] && [[ "$DISABLED" -eq 0 ]]; then
      echo -e "  ${YELLOW}⚠ No tool-specific settings configured${NC}"
      WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
      RECOMMENDATIONS+=("Configure tool-specific approvals for '$SERVER'")
    fi

    # Warn about dangerous auto-approved tools
    DANGEROUS_PATTERNS=("delete" "remove" "admin" "execute" "system")
    for PATTERN in "${DANGEROUS_PATTERNS[@]}"; do
      DANGEROUS_COUNT=$(jq -r ".mcpServers[\"$SERVER\"].autoApprovedTools // [] | map(select(test(\"$PATTERN\"; \"i\"))) | length" "$CONFIG_FILE")
      if [[ "$DANGEROUS_COUNT" -gt 0 ]]; then
        echo -e "  ${RED}✗ Found $DANGEROUS_COUNT auto-approved tools matching '$PATTERN'${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        RECOMMENDATIONS+=("Review auto-approved tools with '$PATTERN' in '$SERVER'")
      fi
    done

    echo ""
  fi
done

if [[ "$FINE_GRAINED_COUNT" -eq 0 ]]; then
  echo "  No fine-grained configurations to check"
  echo ""
fi

echo -e "${BLUE}[5/6] Checking for security best practices...${NC}"
echo ""

# Check for rate limiting
for SERVER in $(jq -r '.mcpServers | keys[]' "$CONFIG_FILE"); do
  HAS_RATE_LIMIT=$(jq -r ".mcpServers[\"$SERVER\"].rateLimiting // \"none\"" "$CONFIG_FILE")

  echo -e "  Server: ${BLUE}$SERVER${NC}"

  if [[ "$HAS_RATE_LIMIT" != "none" ]]; then
    echo -e "  Rate Limiting: ${GREEN}Configured ✓${NC}"
  else
    echo -e "  Rate Limiting: ${YELLOW}Not configured ⚠${NC}"
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
    RECOMMENDATIONS+=("Consider rate limiting for '$SERVER'")
  fi

  echo ""
done

echo -e "${BLUE}[6/6] Checking for PII and sensitive data exposure...${NC}"
echo ""

# Check if there are any patterns suggesting PII in config
SENSITIVE_PATTERNS=("password" "secret" "api_key" "token" "credential" "ssn" "social_security")
CONFIG_CONTENT=$(cat "$CONFIG_FILE")

for PATTERN in "${SENSITIVE_PATTERNS[@]}"; do
  if echo "$CONFIG_CONTENT" | grep -iq "$PATTERN"; then
    # Check if it's just the key name or an actual value
    OCCURRENCES=$(echo "$CONFIG_CONTENT" | grep -i "$PATTERN" | wc -l)
    echo -e "  ${YELLOW}⚠ Found $OCCURRENCES reference(s) to '$PATTERN'${NC}"
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
    echo "    Ensure sensitive values are in environment variables, not hardcoded"
    echo ""
  fi
done

# Security audit summary
echo ""
echo -e "${BLUE}Security Audit Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  MCP Servers:     $SERVER_COUNT"
echo -e "  Issues Found:    $([ $ISSUES_FOUND -eq 0 ] && echo -e "${GREEN}$ISSUES_FOUND${NC}" || echo -e "${RED}$ISSUES_FOUND${NC}")"
echo -e "  Warnings:        $([ $WARNINGS_FOUND -eq 0 ] && echo -e "${GREEN}$WARNINGS_FOUND${NC}" || echo -e "${YELLOW}$WARNINGS_FOUND${NC}")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Recommendations
if [[ ${#RECOMMENDATIONS[@]} -gt 0 ]]; then
  echo -e "${YELLOW}Recommendations:${NC}"
  echo ""
  for REC in "${RECOMMENDATIONS[@]}"; do
    echo -e "  • $REC"
  done
  echo ""
fi

# Best practices
echo -e "${BLUE}Security Best Practices:${NC}"
echo ""
echo "  1. Default to 'Always Ask' approval mode"
echo "  2. Use HTTPS for all MCP server connections"
echo "  3. Store authentication tokens in environment variables"
echo "  4. Regularly review and audit tool permissions"
echo "  5. Disable unnecessary or high-risk tools"
echo "  6. Implement rate limiting to prevent abuse"
echo "  7. Monitor tool usage for unusual patterns"
echo "  8. Keep MCP server URLs private and secure"
echo ""

# Overall result
if [[ $ISSUES_FOUND -eq 0 ]] && [[ $WARNINGS_FOUND -eq 0 ]]; then
  echo -e "${GREEN}✓ Security audit passed with no issues!${NC}"
  exit 0
elif [[ $ISSUES_FOUND -eq 0 ]]; then
  echo -e "${YELLOW}✓ Security audit passed with warnings${NC}"
  echo "  Review recommendations above"
  exit 0
else
  echo -e "${RED}✗ Security audit found critical issues${NC}"
  echo "  Address issues before deploying to production"
  exit 1
fi
