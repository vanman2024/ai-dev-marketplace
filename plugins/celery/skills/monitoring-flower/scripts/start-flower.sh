#!/bin/bash

# start-flower.sh - Start Flower monitoring server for Celery
#
# Usage:
#   ./start-flower.sh [broker-url] [port]
#
# Examples:
#   ./start-flower.sh
#   ./start-flower.sh redis://localhost:6379/0 5555
#   ./start-flower.sh amqp://guest:guest@localhost:5672// 5555
#   FLOWER_BASIC_AUTH="user:password" ./start-flower.sh
#
# Environment Variables:
#   CELERY_BROKER_URL - Broker URL (default: redis://localhost:6379/0)
#   FLOWER_PORT - Port to run on (default: 5555)
#   FLOWER_BASIC_AUTH - Basic auth credentials (username:password)
#   FLOWER_OAUTH2_KEY - OAuth2 client ID
#   FLOWER_OAUTH2_SECRET - OAuth2 client secret
#   FLOWER_OAUTH2_REDIRECT_URI - OAuth2 redirect URI
#   FLOWER_MAX_TASKS - Maximum tasks in memory (default: 10000)
#   FLOWER_PERSISTENT - Enable database persistence (true/false)
#   FLOWER_DB - Database path for persistence

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_BROKER="redis://localhost:6379/0"
DEFAULT_PORT="5555"

# Get parameters
BROKER_URL="${1:-${CELERY_BROKER_URL:-$DEFAULT_BROKER}}"
PORT="${2:-${FLOWER_PORT:-$DEFAULT_PORT}}"

# Configuration
MAX_TASKS="${FLOWER_MAX_TASKS:-10000}"
PERSISTENT="${FLOWER_PERSISTENT:-true}"
DB_PATH="${FLOWER_DB:-flower.db}"
URL_PREFIX="${FLOWER_URL_PREFIX:-}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}             Starting Flower Monitoring Server              ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ============================================================================
# Validation
# ============================================================================

echo -e "\n${YELLOW}[1/5] Validating Configuration...${NC}"

# Check if flower is installed
if ! command -v flower &> /dev/null; then
    echo -e "${RED}✗ Flower is not installed${NC}"
    echo -e "${YELLOW}Install with: pip install flower${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flower is installed${NC}"

# Validate broker URL
if [ -z "$BROKER_URL" ]; then
    echo -e "${RED}✗ Broker URL is required${NC}"
    echo -e "${YELLOW}Set CELERY_BROKER_URL or pass as first argument${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Broker URL configured${NC}"

# Check port availability
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Port $PORT is already in use${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Security check
if [ -z "$FLOWER_BASIC_AUTH" ] && [ -z "$FLOWER_OAUTH2_KEY" ]; then
    echo -e "${YELLOW}⚠ WARNING: No authentication configured!${NC}"
    echo -e "${YELLOW}  Flower will be publicly accessible.${NC}"
    echo -e "${YELLOW}  Set FLOWER_BASIC_AUTH or configure OAuth2${NC}"
    sleep 2
fi

# ============================================================================
# Build Flower Command
# ============================================================================

echo -e "\n${YELLOW}[2/5] Building Flower Command...${NC}"

# Start with basic command
FLOWER_CMD="flower"

# Add broker URL
FLOWER_CMD="$FLOWER_CMD --broker=$BROKER_URL"

# Add port
FLOWER_CMD="$FLOWER_CMD --port=$PORT"

# Add persistence
if [ "$PERSISTENT" = "true" ]; then
    FLOWER_CMD="$FLOWER_CMD --persistent=True --db=$DB_PATH"
    echo -e "${GREEN}✓ Persistence enabled: $DB_PATH${NC}"
fi

# Add max tasks
FLOWER_CMD="$FLOWER_CMD --max_tasks=$MAX_TASKS"

# Add URL prefix if set
if [ -n "$URL_PREFIX" ]; then
    FLOWER_CMD="$FLOWER_CMD --url_prefix=$URL_PREFIX"
    echo -e "${GREEN}✓ URL prefix: $URL_PREFIX${NC}"
fi

# Add authentication
if [ -n "$FLOWER_BASIC_AUTH" ]; then
    FLOWER_CMD="$FLOWER_CMD --basic_auth=$FLOWER_BASIC_AUTH"
    echo -e "${GREEN}✓ Basic authentication enabled${NC}"
fi

# Add OAuth2 if configured
if [ -n "$FLOWER_OAUTH2_KEY" ] && [ -n "$FLOWER_OAUTH2_SECRET" ]; then
    FLOWER_AUTH_REGEX="${FLOWER_AUTH_REGEX:-.*@example\.com}"
    FLOWER_REDIRECT_URI="${FLOWER_OAUTH2_REDIRECT_URI:-http://localhost:$PORT/login}"

    FLOWER_CMD="$FLOWER_CMD --auth=$FLOWER_AUTH_REGEX"
    FLOWER_CMD="$FLOWER_CMD --oauth2_key=$FLOWER_OAUTH2_KEY"
    FLOWER_CMD="$FLOWER_CMD --oauth2_secret=$FLOWER_OAUTH2_SECRET"
    FLOWER_CMD="$FLOWER_CMD --oauth2_redirect_uri=$FLOWER_REDIRECT_URI"
    echo -e "${GREEN}✓ OAuth2 authentication enabled${NC}"
fi

# ============================================================================
# Check Celery Workers
# ============================================================================

echo -e "\n${YELLOW}[3/5] Checking Celery Workers...${NC}"

# Test broker connectivity
if command -v redis-cli &> /dev/null && [[ $BROKER_URL == redis://* ]]; then
    # Extract Redis host and port
    REDIS_HOST=$(echo $BROKER_URL | sed -E 's|redis://([^:@]+).*|\1|' | sed 's|.*@||')
    REDIS_PORT=$(echo $BROKER_URL | sed -E 's|redis://[^:]+:([0-9]+).*|\1|')

    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping &> /dev/null; then
        echo -e "${GREEN}✓ Redis broker is accessible${NC}"
    else
        echo -e "${YELLOW}⚠ Cannot connect to Redis broker${NC}"
        echo -e "${YELLOW}  Make sure Redis is running${NC}"
    fi
fi

# Check for running workers (this requires celery command)
if command -v celery &> /dev/null; then
    WORKER_COUNT=$(celery -b "$BROKER_URL" inspect active_queues 2>/dev/null | grep -c "celery@" || echo "0")
    if [ "$WORKER_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $WORKER_COUNT active worker(s)${NC}"
    else
        echo -e "${YELLOW}⚠ No active workers detected${NC}"
        echo -e "${YELLOW}  Start workers with: celery -A yourapp worker${NC}"
    fi
fi

# ============================================================================
# Display Configuration
# ============================================================================

echo -e "\n${YELLOW}[4/5] Configuration Summary:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Mask sensitive parts of broker URL
DISPLAY_BROKER=$(echo "$BROKER_URL" | sed 's|\(://[^:]*:\)[^@]*@|\1***@|')
echo -e "  Broker:       ${DISPLAY_BROKER}"
echo -e "  Port:         ${PORT}"
echo -e "  Max Tasks:    ${MAX_TASKS}"
echo -e "  Persistent:   ${PERSISTENT}"
if [ "$PERSISTENT" = "true" ]; then
    echo -e "  Database:     ${DB_PATH}"
fi
if [ -n "$URL_PREFIX" ]; then
    echo -e "  URL Prefix:   ${URL_PREFIX}"
fi
if [ -n "$FLOWER_BASIC_AUTH" ]; then
    echo -e "  Auth:         Basic Authentication"
elif [ -n "$FLOWER_OAUTH2_KEY" ]; then
    echo -e "  Auth:         OAuth2"
else
    echo -e "  Auth:         ${YELLOW}None (WARNING)${NC}"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ============================================================================
# Start Flower
# ============================================================================

echo -e "\n${YELLOW}[5/5] Starting Flower...${NC}"

# Create log directory if it doesn't exist
mkdir -p logs

# Start Flower
echo -e "${GREEN}✓ Starting Flower monitoring server...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Display access information
if [ -n "$URL_PREFIX" ]; then
    echo -e "${GREEN}  Flower UI:    http://localhost:$PORT$URL_PREFIX${NC}"
else
    echo -e "${GREEN}  Flower UI:    http://localhost:$PORT${NC}"
fi

if [ -n "$FLOWER_BASIC_AUTH" ]; then
    USERNAME=$(echo "$FLOWER_BASIC_AUTH" | cut -d: -f1 | cut -d, -f1)
    echo -e "${YELLOW}  Username:     $USERNAME${NC}"
    echo -e "${YELLOW}  Password:     (from FLOWER_BASIC_AUTH)${NC}"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${GREEN}Starting Flower...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"

# Execute Flower command
exec $FLOWER_CMD
