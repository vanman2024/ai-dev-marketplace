#!/bin/bash

# validate-endpoints.sh
# Validates FastAPI endpoint files for best practices and common issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if file argument provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No file specified${NC}"
    echo "Usage: $0 <router_file.py>"
    exit 1
fi

FILE="$1"

# Check if file exists
if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: File '$FILE' not found${NC}"
    exit 1
fi

echo -e "${BLUE}=== Validating FastAPI Endpoint: $FILE ===${NC}\n"

WARNINGS=0
ERRORS=0
PASSES=0

# Check 1: APIRouter import
echo -n "Checking for APIRouter import... "
if grep -q "from fastapi import.*APIRouter" "$FILE" || grep -q "from fastapi import APIRouter" "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: APIRouter not imported${NC}"
    echo "  Add: from fastapi import APIRouter"
    ((WARNINGS++))
fi

# Check 2: Router instantiation
echo -n "Checking for router instantiation... "
if grep -q "router = APIRouter" "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: router not instantiated${NC}"
    echo "  Add: router = APIRouter(prefix='/path', tags=['tag'])"
    ((WARNINGS++))
fi

# Check 3: Response model usage
echo -n "Checking for response_model usage... "
if grep -q "response_model=" "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: No response_model found${NC}"
    echo "  Add response_model parameter to endpoints"
    ((WARNINGS++))
fi

# Check 4: Status code imports
echo -n "Checking for status code imports... "
if grep -q "from fastapi import.*status" "$FILE" || grep -q "status.HTTP_" "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: Status codes not imported${NC}"
    echo "  Add: from fastapi import status"
    echo "  Use: status.HTTP_200_OK, status.HTTP_201_CREATED, etc."
    ((WARNINGS++))
fi

# Check 5: HTTPException import
echo -n "Checking for HTTPException import... "
if grep -q "from fastapi import.*HTTPException" "$FILE" || grep -q "HTTPException" "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: HTTPException not imported${NC}"
    echo "  Add: from fastapi import HTTPException"
    ((WARNINGS++))
fi

# Check 6: Error raising
echo -n "Checking for error handling... "
if grep -q "raise HTTPException" "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: No error handling found${NC}"
    echo "  Add HTTPException raises for error cases"
    ((WARNINGS++))
fi

# Check 7: Docstrings
echo -n "Checking for endpoint documentation... "
DOCSTRING_COUNT=$(grep -c '"""' "$FILE" || echo "0")
if [ "$DOCSTRING_COUNT" -gt 2 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: Limited documentation found${NC}"
    echo "  Add docstrings to endpoints for OpenAPI docs"
    ((WARNINGS++))
fi

# Check 8: Type hints
echo -n "Checking for type hints... "
if grep -q ": int" "$FILE" || grep -q ": str" "$FILE" || grep -q "-> " "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: Limited type hints found${NC}"
    echo "  Add type hints to function parameters and returns"
    ((WARNINGS++))
fi

# Check 9: Pydantic models
echo -n "Checking for Pydantic model imports... "
if grep -q "from pydantic import" "$FILE" || grep -q "BaseModel" "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: No Pydantic models found${NC}"
    echo "  Use Pydantic models for request/response validation"
    ((WARNINGS++))
fi

# Check 10: Async endpoints
echo -n "Checking for async endpoint definitions... "
if grep -q "async def" "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: No async endpoints found${NC}"
    echo "  Consider using 'async def' for better performance"
    ((WARNINGS++))
fi

# Check 11: Pagination parameters
echo -n "Checking for pagination... "
if grep -q "skip.*int" "$FILE" && grep -q "limit.*int" "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
elif grep -q "page.*int" "$FILE" || grep -q "cursor" "$FILE"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
else
    echo -e "${YELLOW}⚠ WARNING: No pagination found${NC}"
    echo "  Add pagination parameters (skip/limit or page/page_size)"
    ((WARNINGS++))
fi

# Check 12: Dangerous patterns
echo -n "Checking for dangerous patterns... "
DANGEROUS=0

if grep -q "exec(" "$FILE"; then
    echo -e "${RED}✗ ERROR: exec() usage found (security risk)${NC}"
    ((ERRORS++))
    DANGEROUS=1
fi

if grep -q "eval(" "$FILE"; then
    echo -e "${RED}✗ ERROR: eval() usage found (security risk)${NC}"
    ((ERRORS++))
    DANGEROUS=1
fi

if grep -q "shell=True" "$FILE"; then
    echo -e "${RED}✗ ERROR: shell=True found (security risk)${NC}"
    ((ERRORS++))
    DANGEROUS=1
fi

if [ $DANGEROUS -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSES++))
fi

# Summary
echo -e "\n${BLUE}=== Validation Summary ===${NC}"
echo -e "${GREEN}Passed:   $PASSES${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Errors:   $ERRORS${NC}"

# Best practices recommendations
if [ $WARNINGS -gt 0 ] || [ $ERRORS -gt 0 ]; then
    echo -e "\n${BLUE}=== Recommendations ===${NC}"
    echo "1. Use APIRouter with prefix and tags for organization"
    echo "2. Always specify response_model for type safety"
    echo "3. Use status codes from fastapi.status module"
    echo "4. Implement error handling with HTTPException"
    echo "5. Add docstrings for OpenAPI documentation"
    echo "6. Use type hints for all parameters and returns"
    echo "7. Validate inputs with Pydantic models"
    echo "8. Prefer async endpoints for I/O operations"
    echo "9. Implement pagination for list endpoints"
    echo "10. Avoid dangerous patterns (exec, eval, shell=True)"
fi

# Exit code
if [ $ERRORS -gt 0 ]; then
    echo -e "\n${RED}Validation failed with errors${NC}"
    exit 1
elif [ $WARNINGS -gt 5 ]; then
    echo -e "\n${YELLOW}Validation passed with warnings - consider improvements${NC}"
    exit 0
else
    echo -e "\n${GREEN}Validation passed successfully${NC}"
    exit 0
fi
