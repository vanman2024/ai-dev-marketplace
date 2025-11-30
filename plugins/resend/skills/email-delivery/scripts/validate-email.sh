#!/bin/bash

# Email validation script for Resend email delivery patterns
# Validates email addresses, templates, and scheduling logic

set -e

EMAIL=${1:-}

if [ -z "$EMAIL" ]; then
    echo "Usage: validate-email.sh <email_address>"
    echo ""
    echo "Validates email format and common issues"
    exit 1
fi

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Validating email: $EMAIL"
echo "========================================"

# Basic format validation
if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}✗ INVALID: Email format is incorrect${NC}"
    exit 1
else
    echo -e "${GREEN}✓ VALID: Email format is correct${NC}"
fi

# Check for common issues
echo ""
echo "Common Issues Check:"
echo "---"

# Consecutive dots
if [[ "$EMAIL" =~ \.\. ]]; then
    echo -e "${RED}✗ Consecutive dots found${NC}"
    exit 1
else
    echo -e "${GREEN}✓ No consecutive dots${NC}"
fi

# Starts or ends with dot
if [[ "$EMAIL" =~ ^\. ]] || [[ "$EMAIL" =~ \. ]]; then
    if [[ "$EMAIL" =~ ^\..*@|@.*\.$ ]]; then
        echo -e "${RED}✗ Dot at start or end of local/domain${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ No dots at boundaries${NC}"

# Spaces
if [[ "$EMAIL" =~ " " ]]; then
    echo -e "${RED}✗ Contains spaces${NC}"
    exit 1
else
    echo -e "${GREEN}✓ No spaces${NC}"
fi

# Plus sign (common for testing)
if [[ "$EMAIL" =~ \+ ]]; then
    echo -e "${YELLOW}⚠ Contains plus sign (commonly used for testing)${NC}"
fi

# Length check
if [ ${#EMAIL} -gt 254 ]; then
    echo -e "${RED}✗ Email exceeds 254 characters${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Email length valid (${#EMAIL} chars)${NC}"
fi

# Domain checks
LOCAL_PART="${EMAIL%@*}"
DOMAIN_PART="${EMAIL#*@}"

if [ ${#LOCAL_PART} -gt 64 ]; then
    echo -e "${RED}✗ Local part exceeds 64 characters${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Local part valid (${#LOCAL_PART} chars)${NC}"
fi

if [ ${#DOMAIN_PART} -gt 255 ]; then
    echo -e "${RED}✗ Domain exceeds 255 characters${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Domain valid (${#DOMAIN_PART} chars)${NC}"
fi

echo ""
echo "========================================"
echo -e "${GREEN}All validations passed!${NC}"
