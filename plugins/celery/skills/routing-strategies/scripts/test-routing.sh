#!/bin/bash
#
# Test Celery Routing Configuration
#
# This script validates routing configuration and tests queue connectivity
#
# Usage:
#   ./test-routing.sh <config-file>
#   BROKER_URL=amqp://user:pass@host:5672// ./test-routing.sh celery_config.py
#   VERBOSE=1 ./test-routing.sh celery_config.py
#
# Exit Codes:
#   0 - All tests passed
#   1 - Configuration errors
#   2 - Broker connection failed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="${1:-celery_config.py}"
VERBOSE="${VERBOSE:-0}"
BROKER_URL="${BROKER_URL:-}"

echo -e "${BLUE}=== Celery Routing Configuration Test ===${NC}\n"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Config file found: $CONFIG_FILE\n"

# Function to log verbose messages
log_verbose() {
    if [[ "$VERBOSE" == "1" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Function to test Python syntax
test_python_syntax() {
    echo -e "${BLUE}Testing Python syntax...${NC}"
    if python3 -m py_compile "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Python syntax valid\n"
        return 0
    else
        echo -e "${RED}✗${NC} Python syntax errors detected\n"
        python3 -m py_compile "$CONFIG_FILE"
        return 1
    fi
}

# Function to extract broker URL from config
extract_broker_url() {
    if [[ -n "$BROKER_URL" ]]; then
        echo "$BROKER_URL"
        return 0
    fi

    # Try to extract from config file
    BROKER_URL=$(grep -oP "BROKER_URL\s*=\s*['\"].*?['\"]" "$CONFIG_FILE" | head -1 | grep -oP "['\"].*?['\"]" | tr -d "'\"" || echo "")

    if [[ -z "$BROKER_URL" ]]; then
        BROKER_URL=$(grep -oP "broker_url\s*=\s*['\"].*?['\"]" "$CONFIG_FILE" | head -1 | grep -oP "['\"].*?['\"]" | tr -d "'\"" || echo "")
    fi

    if [[ -z "$BROKER_URL" ]]; then
        # Try environment variable reference
        BROKER_URL=$(printenv CELERY_BROKER_URL || echo "amqp://guest:guest@localhost:5672//")
    fi

    echo "$BROKER_URL"
}

# Function to test broker connectivity
test_broker_connectivity() {
    echo -e "${BLUE}Testing broker connectivity...${NC}"

    BROKER=$(extract_broker_url)
    log_verbose "Broker URL: $BROKER"

    # Determine broker type
    if [[ "$BROKER" =~ ^amqp:// ]] || [[ "$BROKER" =~ ^pyamqp:// ]]; then
        BROKER_TYPE="rabbitmq"
        # Extract host and port
        HOST=$(echo "$BROKER" | sed -E 's|^[^:]+://([^:]+:[^@]+@)?([^:/]+).*|\2|')
        PORT=$(echo "$BROKER" | grep -oP ':\d+' | tail -1 | tr -d ':' || echo "5672")
    elif [[ "$BROKER" =~ ^redis:// ]]; then
        BROKER_TYPE="redis"
        HOST=$(echo "$BROKER" | sed -E 's|^redis://([^:/]+).*|\1|')
        PORT=$(echo "$BROKER" | grep -oP ':\d+' | head -1 | tr -d ':' || echo "6379")
    else
        echo -e "${YELLOW}⚠${NC} Unknown broker type, skipping connectivity test\n"
        return 0
    fi

    log_verbose "Broker type: $BROKER_TYPE"
    log_verbose "Host: $HOST, Port: $PORT"

    # Test connection
    if command -v nc &> /dev/null; then
        if nc -z -w5 "$HOST" "$PORT" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Broker is reachable at $HOST:$PORT ($BROKER_TYPE)\n"
            return 0
        else
            echo -e "${RED}✗${NC} Cannot connect to broker at $HOST:$PORT\n"
            return 2
        fi
    elif command -v telnet &> /dev/null; then
        if timeout 5 telnet "$HOST" "$PORT" 2>/dev/null | grep -q "Connected"; then
            echo -e "${GREEN}✓${NC} Broker is reachable at $HOST:$PORT ($BROKER_TYPE)\n"
            return 0
        else
            echo -e "${RED}✗${NC} Cannot connect to broker at $HOST:$PORT\n"
            return 2
        fi
    else
        echo -e "${YELLOW}⚠${NC} Neither nc nor telnet available, skipping connectivity test\n"
        return 0
    fi
}

# Function to validate queue configuration
validate_queue_config() {
    echo -e "${BLUE}Validating queue configuration...${NC}"

    # Check for CELERY_QUEUES or task_queues
    if grep -q "CELERY_QUEUES\|task_queues" "$CONFIG_FILE"; then
        echo -e "${GREEN}✓${NC} Queue definitions found"
        log_verbose "Queue count: $(grep -c "Queue(" "$CONFIG_FILE" || echo "0")"
    else
        echo -e "${YELLOW}⚠${NC} No queue definitions found (using default queue)"
    fi

    # Check for routing configuration
    if grep -q "CELERY_ROUTES\|task_routes" "$CONFIG_FILE"; then
        echo -e "${GREEN}✓${NC} Routing configuration found"
    else
        echo -e "${YELLOW}⚠${NC} No routing configuration found (all tasks use default queue)"
    fi

    # Check for Exchange imports
    if grep -q "from kombu import.*Exchange" "$CONFIG_FILE"; then
        echo -e "${GREEN}✓${NC} Exchange imports present"
    else
        echo -e "${YELLOW}⚠${NC} No Exchange imports found"
    fi

    # Check for Queue imports
    if grep -q "from kombu import.*Queue" "$CONFIG_FILE"; then
        echo -e "${GREEN}✓${NC} Queue imports present\n"
    else
        echo -e "${YELLOW}⚠${NC} No Queue imports found\n"
    fi
}

# Function to validate routing keys
validate_routing_keys() {
    echo -e "${BLUE}Validating routing keys...${NC}"

    # Check for routing_key definitions
    ROUTING_KEYS=$(grep -oP "routing_key\s*=\s*['\"].*?['\"]" "$CONFIG_FILE" | wc -l)

    if [[ $ROUTING_KEYS -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} Found $ROUTING_KEYS routing key definitions"
        log_verbose "Routing keys:"
        if [[ "$VERBOSE" == "1" ]]; then
            grep -oP "routing_key\s*=\s*['\"].*?['\"]" "$CONFIG_FILE" | sed 's/routing_key = /  - /' | tr -d "'\""
        fi
    else
        echo -e "${YELLOW}⚠${NC} No explicit routing keys found"
    fi
    echo ""
}

# Function to check priority queue configuration
check_priority_queues() {
    echo -e "${BLUE}Checking priority queue configuration...${NC}"

    # Check for x-max-priority
    if grep -q "x-max-priority" "$CONFIG_FILE"; then
        echo -e "${GREEN}✓${NC} Priority queue configuration found"
        MAX_PRIORITY=$(grep -oP "x-max-priority['\"]:\s*\d+" "$CONFIG_FILE" | head -1 | grep -oP "\d+" || echo "0")
        if [[ $MAX_PRIORITY -gt 0 ]]; then
            echo -e "${GREEN}✓${NC} Max priority level: $MAX_PRIORITY"
        fi
    else
        echo -e "${YELLOW}⚠${NC} No priority queue configuration (not using priorities)"
    fi

    # Check for task priority settings
    if grep -q "priority\s*[=:]" "$CONFIG_FILE"; then
        echo -e "${GREEN}✓${NC} Task priority settings found\n"
    else
        echo -e "${YELLOW}⚠${NC} No task priority settings\n"
    fi
}

# Function to check exchange types
check_exchange_types() {
    echo -e "${BLUE}Checking exchange configuration...${NC}"

    # Extract exchange types
    DIRECT=$(grep -c "type='direct'" "$CONFIG_FILE" || echo "0")
    TOPIC=$(grep -c "type='topic'" "$CONFIG_FILE" || echo "0")
    FANOUT=$(grep -c "type='fanout'" "$CONFIG_FILE" || echo "0")
    HEADERS=$(grep -c "type='headers'" "$CONFIG_FILE" || echo "0")

    echo -e "Exchange types:"
    [[ $DIRECT -gt 0 ]] && echo -e "${GREEN}✓${NC} Direct: $DIRECT"
    [[ $TOPIC -gt 0 ]] && echo -e "${GREEN}✓${NC} Topic: $TOPIC"
    [[ $FANOUT -gt 0 ]] && echo -e "${GREEN}✓${NC} Fanout: $FANOUT"
    [[ $HEADERS -gt 0 ]] && echo -e "${GREEN}✓${NC} Headers: $HEADERS"

    if [[ $((DIRECT + TOPIC + FANOUT + HEADERS)) -eq 0 ]]; then
        echo -e "${YELLOW}⚠${NC} No explicit exchange types (using defaults)"
    fi
    echo ""
}

# Function to validate security
validate_security() {
    echo -e "${BLUE}Checking security...${NC}"

    # Check for hardcoded credentials
    if grep -qE "(password|secret|key)\s*=\s*['\"][^'\"]{10,}['\"]" "$CONFIG_FILE"; then
        echo -e "${RED}✗${NC} WARNING: Possible hardcoded credentials detected!"
        echo -e "${YELLOW}⚠${NC} Review config for exposed secrets\n"
        return 1
    else
        echo -e "${GREEN}✓${NC} No obvious hardcoded credentials\n"
    fi
}

# Main test execution
FAILED=0

test_python_syntax || FAILED=1
test_broker_connectivity || FAILED=$?
validate_queue_config
validate_routing_keys
check_priority_queues
check_exchange_types
validate_security || FAILED=1

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}\n"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo -e "Routing configuration is valid and broker is reachable.\n"
    exit 0
elif [[ $FAILED -eq 2 ]]; then
    echo -e "${RED}✗ Broker connection failed${NC}"
    echo -e "Cannot connect to message broker. Check BROKER_URL and broker status.\n"
    exit 2
else
    echo -e "${YELLOW}⚠ Tests completed with warnings${NC}"
    echo -e "Configuration has issues that should be reviewed.\n"
    exit 1
fi
