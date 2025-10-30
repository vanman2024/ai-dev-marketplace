#!/usr/bin/env bash

# validate-config.sh
# Production configuration validator for ElevenLabs integration
# Usage: bash validate-config.sh --config-file config/production.json --strict true

set -e

# Default configuration
CONFIG_FILE="config/production.json"
STRICT=false
CHECK_API_KEY=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config-file)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --strict)
            STRICT="$2"
            shift 2
            ;;
        --skip-api-check)
            CHECK_API_KEY=false
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

VALIDATION_FAILED=false
ERROR_COUNT=0
WARNING_COUNT=0

# Validation functions
validate_required_var() {
    local var_name=$1
    local var_value=${!var_name}

    if [ -z "$var_value" ]; then
        log_error "Required environment variable not set: $var_name"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        VALIDATION_FAILED=true
        return 1
    fi
    return 0
}

validate_optional_var() {
    local var_name=$1
    local var_value=${!var_name}

    if [ -z "$var_value" ]; then
        log_warn "Optional environment variable not set: $var_name"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
}

# Validate environment variables
log_info "Validating environment variables..."

validate_required_var "ELEVENLABS_API_KEY"
validate_optional_var "ELEVENLABS_PLAN_TIER"
validate_optional_var "ELEVENLABS_CONCURRENCY_LIMIT"
validate_optional_var "LOG_LEVEL"
validate_optional_var "ENVIRONMENT"

# Validate API key format
if [ -n "$ELEVENLABS_API_KEY" ]; then
    if [[ ! "$ELEVENLABS_API_KEY" =~ ^[a-zA-Z0-9_-]{32,}$ ]]; then
        log_error "Invalid API key format (must be 32+ alphanumeric characters)"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        VALIDATION_FAILED=true
    else
        log_info "API key format: valid ✓"
    fi
fi

# Test API connectivity
if [ "$CHECK_API_KEY" = true ] && [ -n "$ELEVENLABS_API_KEY" ]; then
    log_info "Testing API connectivity..."

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X GET "https://api.elevenlabs.io/v1/user" \
        -H "xi-api-key: $ELEVENLABS_API_KEY")

    if [ "$HTTP_CODE" = "200" ]; then
        log_info "API connectivity: valid ✓"
    elif [ "$HTTP_CODE" = "401" ]; then
        log_error "API key is invalid (HTTP 401)"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        VALIDATION_FAILED=true
    else
        log_warn "API connectivity test returned HTTP $HTTP_CODE"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
fi

# Validate configuration files
if [ -f "$CONFIG_FILE" ]; then
    log_info "Validating configuration file: $CONFIG_FILE"

    # Check JSON syntax
    if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
        log_info "Configuration JSON: valid ✓"
    else
        log_error "Configuration JSON is invalid"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        VALIDATION_FAILED=true
    fi
else
    if [ "$STRICT" = true ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        VALIDATION_FAILED=true
    else
        log_warn "Configuration file not found: $CONFIG_FILE"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
fi

# Validate rate limit configuration
if [ -f "config/rate-limit.json" ]; then
    log_info "Validating rate limit configuration..."

    if command -v jq &> /dev/null; then
        CONCURRENCY=$(jq -r '.concurrencyLimit' config/rate-limit.json)
        if [ "$CONCURRENCY" -gt 0 ] 2>/dev/null; then
            log_info "Concurrency limit: $CONCURRENCY ✓"
        else
            log_error "Invalid concurrency limit in rate-limit.json"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            VALIDATION_FAILED=true
        fi
    fi
fi

# Validate monitoring setup
log_info "Validating monitoring configuration..."

if [ -d "monitoring/config" ]; then
    log_info "Monitoring directory: exists ✓"

    if [ -f "monitoring/config/metrics.js" ] || [ -f "monitoring/config/metrics.py" ]; then
        log_info "Metrics configuration: exists ✓"
    else
        log_warn "Metrics configuration not found"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi

    if [ -f "monitoring/config/health.js" ] || [ -f "monitoring/config/health.py" ]; then
        log_info "Health check configuration: exists ✓"
    else
        log_warn "Health check configuration not found"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
else
    log_warn "Monitoring directory not found"
    WARNING_COUNT=$((WARNING_COUNT + 1))
fi

# Validate logging setup
if [ -d "logs" ]; then
    log_info "Logs directory: exists ✓"

    # Check write permissions
    if [ -w "logs" ]; then
        log_info "Logs directory: writable ✓"
    else
        log_error "Logs directory is not writable"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        VALIDATION_FAILED=true
    fi
else
    log_warn "Logs directory not found (will be created)"
    WARNING_COUNT=$((WARNING_COUNT + 1))
fi

# Summary
echo ""
log_info "=========================================="
log_info "  Validation Summary"
log_info "=========================================="
echo ""
log_info "Errors: $ERROR_COUNT"
log_info "Warnings: $WARNING_COUNT"
echo ""

if [ "$VALIDATION_FAILED" = true ]; then
    log_error "Validation FAILED ✗"
    exit 1
else
    log_info "Validation PASSED ✓"
    exit 0
fi
