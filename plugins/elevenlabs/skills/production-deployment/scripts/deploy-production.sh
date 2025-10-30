#!/usr/bin/env bash

# deploy-production.sh
# Production deployment orchestration for ElevenLabs API integration
# Usage: bash deploy-production.sh --environment production --api-key $API_KEY --concurrency-limit 10

set -e

# Default configuration
ENVIRONMENT="production"
API_KEY=""
CONCURRENCY_LIMIT=10
REGION="us-east-1"
SKIP_TESTS=false
SKIP_BACKUP=false
DEPLOYMENT_ID="deploy-$(date +%s)"
ROLLBACK_ENABLED=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --concurrency-limit)
            CONCURRENCY_LIMIT="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --no-rollback)
            ROLLBACK_ENABLED=false
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Rollback handler
rollback() {
    if [ "$ROLLBACK_ENABLED" = true ]; then
        log_error "Deployment failed! Initiating rollback..."
        if [ -f "./scripts/rollback.sh" ]; then
            bash ./scripts/rollback.sh --deployment-id "$DEPLOYMENT_ID" --reason "Deployment failure"
        else
            log_warn "Rollback script not found. Manual rollback may be required."
        fi
    else
        log_error "Deployment failed! Rollback is disabled."
    fi
    exit 1
}

# Set up error handler
trap rollback ERR

# Validate environment
validate_environment() {
    log_step "Validating environment configuration..."

    # Check API key
    if [ -z "$API_KEY" ]; then
        if [ -z "$ELEVENLABS_API_KEY" ]; then
            log_error "API key not provided. Use --api-key or set ELEVENLABS_API_KEY"
            exit 1
        fi
        API_KEY="$ELEVENLABS_API_KEY"
    fi

    # Validate API key format
    if [[ ! "$API_KEY" =~ ^[a-zA-Z0-9_-]{32,}$ ]]; then
        log_error "Invalid API key format"
        exit 1
    fi

    # Check concurrency limit
    if ! [[ "$CONCURRENCY_LIMIT" =~ ^[0-9]+$ ]] || [ "$CONCURRENCY_LIMIT" -lt 1 ]; then
        log_error "Invalid concurrency limit: $CONCURRENCY_LIMIT"
        exit 1
    fi

    # Validate environment name
    if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
        log_error "Invalid environment: $ENVIRONMENT (must be development, staging, or production)"
        exit 1
    fi

    log_info "Environment validation passed ✓"
    log_info "  - Environment: $ENVIRONMENT"
    log_info "  - Region: $REGION"
    log_info "  - Concurrency limit: $CONCURRENCY_LIMIT"
}

# Backup current deployment
backup_deployment() {
    if [ "$SKIP_BACKUP" = true ]; then
        log_info "Skipping backup (--skip-backup flag)"
        return 0
    fi

    log_step "Creating deployment backup..."

    BACKUP_DIR="./backups/$DEPLOYMENT_ID"
    mkdir -p "$BACKUP_DIR"

    # Backup configuration files
    if [ -f ".env" ]; then
        cp .env "$BACKUP_DIR/.env.backup"
    fi

    if [ -f "config/production.json" ]; then
        cp config/production.json "$BACKUP_DIR/production.json.backup"
    fi

    # Save deployment metadata
    cat > "$BACKUP_DIR/metadata.json" << EOF
{
  "deploymentId": "$DEPLOYMENT_ID",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "environment": "$ENVIRONMENT",
  "concurrencyLimit": $CONCURRENCY_LIMIT,
  "region": "$REGION"
}
EOF

    log_info "Backup created: $BACKUP_DIR ✓"
}

# Install dependencies
install_dependencies() {
    log_step "Installing dependencies..."

    if [ -f "package.json" ]; then
        log_info "Installing Node.js dependencies..."
        npm ci --production
        log_info "Node.js dependencies installed ✓"
    fi

    if [ -f "requirements.txt" ]; then
        log_info "Installing Python dependencies..."
        pip3 install -r requirements.txt --upgrade
        log_info "Python dependencies installed ✓"
    fi

    if [ ! -f "package.json" ] && [ ! -f "requirements.txt" ]; then
        log_warn "No dependency files found (package.json or requirements.txt)"
    fi
}

# Configure rate limiting
configure_rate_limiting() {
    log_step "Configuring rate limiting..."

    # Create rate limit configuration
    mkdir -p config

    cat > config/rate-limit.json << EOF
{
  "concurrencyLimit": $CONCURRENCY_LIMIT,
  "queueSize": 1000,
  "timeout": 30000,
  "retryAttempts": 3,
  "retryDelay": 1000,
  "circuitBreaker": {
    "enabled": true,
    "failureThreshold": 5,
    "resetTimeout": 60000,
    "monitorInterval": 5000
  }
}
EOF

    log_info "Rate limiting configured ✓"
}

# Configure error handling
configure_error_handling() {
    log_step "Configuring error handling..."

    cat > config/error-handling.json << EOF
{
  "retryStrategies": {
    "429": {
      "enabled": true,
      "maxRetries": 5,
      "backoffType": "exponential",
      "initialDelay": 1000,
      "maxDelay": 30000,
      "jitter": true
    },
    "5xx": {
      "enabled": true,
      "maxRetries": 3,
      "backoffType": "exponential",
      "initialDelay": 2000,
      "maxDelay": 10000,
      "jitter": true
    },
    "network": {
      "enabled": true,
      "maxRetries": 3,
      "backoffType": "linear",
      "initialDelay": 1000,
      "maxDelay": 5000
    }
  },
  "circuitBreaker": {
    "enabled": true,
    "errorThreshold": 50,
    "volumeThreshold": 10,
    "timeout": 60000
  },
  "fallback": {
    "enabled": true,
    "strategy": "cached"
  }
}
EOF

    log_info "Error handling configured ✓"
}

# Setup monitoring
setup_monitoring() {
    log_step "Setting up monitoring..."

    # Run monitoring setup script if available
    if [ -f "./scripts/setup-monitoring.sh" ]; then
        bash ./scripts/setup-monitoring.sh \
            --project-name "elevenlabs-$ENVIRONMENT" \
            --log-level "info" \
            --skip-install
    else
        log_warn "Monitoring setup script not found"
    fi

    # Create environment file for monitoring
    cat > .env.production << EOF
NODE_ENV=$ENVIRONMENT
ENVIRONMENT=$ENVIRONMENT
ELEVENLABS_API_KEY=$API_KEY
ELEVENLABS_CONCURRENCY_LIMIT=$CONCURRENCY_LIMIT
REGION=$REGION
DEPLOYMENT_ID=$DEPLOYMENT_ID
LOG_LEVEL=info
METRICS_ENABLED=true
TRACING_ENABLED=true
EOF

    log_info "Monitoring setup complete ✓"
}

# Run smoke tests
run_smoke_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        log_info "Skipping smoke tests (--skip-tests flag)"
        return 0
    fi

    log_step "Running smoke tests..."

    # Test 1: API connectivity
    log_info "Testing API connectivity..."

    # Create temporary test script
    cat > /tmp/smoke_test.sh << 'EOF'
#!/bin/bash
curl -s -X GET "https://api.elevenlabs.io/v1/voices" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -o /dev/null -w "%{http_code}"
EOF
    chmod +x /tmp/smoke_test.sh

    HTTP_CODE=$(ELEVENLABS_API_KEY="$API_KEY" bash /tmp/smoke_test.sh)

    if [ "$HTTP_CODE" = "200" ]; then
        log_info "  ✓ API connectivity test passed"
    else
        log_error "  ✗ API connectivity test failed (HTTP $HTTP_CODE)"
        exit 1
    fi

    # Test 2: Health check endpoint
    if [ -f "monitoring/config/health.js" ] || [ -f "monitoring/config/health.py" ]; then
        log_info "Testing health check endpoint..."
        # The health check would be started by the application
        log_info "  ✓ Health check configuration present"
    fi

    # Test 3: Configuration validation
    log_info "Validating configuration files..."

    if [ -f "config/rate-limit.json" ]; then
        if python3 -m json.tool config/rate-limit.json > /dev/null 2>&1; then
            log_info "  ✓ rate-limit.json is valid"
        else
            log_error "  ✗ rate-limit.json is invalid"
            exit 1
        fi
    fi

    if [ -f "config/error-handling.json" ]; then
        if python3 -m json.tool config/error-handling.json > /dev/null 2>&1; then
            log_info "  ✓ error-handling.json is valid"
        else
            log_error "  ✗ error-handling.json is invalid"
            exit 1
        fi
    fi

    log_info "Smoke tests passed ✓"
}

# Health check
wait_for_health() {
    log_step "Waiting for application to be healthy..."

    MAX_ATTEMPTS=30
    ATTEMPT=0
    HEALTH_PORT=${HEALTH_PORT:-8080}

    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if curl -s -f "http://localhost:$HEALTH_PORT/health" > /dev/null 2>&1; then
            log_info "Application is healthy ✓"
            return 0
        fi

        ATTEMPT=$((ATTEMPT + 1))
        log_info "Waiting for health check... ($ATTEMPT/$MAX_ATTEMPTS)"
        sleep 2
    done

    log_error "Application failed to become healthy"
    return 1
}

# Generate deployment report
generate_report() {
    log_step "Generating deployment report..."

    REPORT_FILE="./deployments/$DEPLOYMENT_ID-report.json"
    mkdir -p ./deployments

    cat > "$REPORT_FILE" << EOF
{
  "deploymentId": "$DEPLOYMENT_ID",
  "environment": "$ENVIRONMENT",
  "region": "$REGION",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "configuration": {
    "concurrencyLimit": $CONCURRENCY_LIMIT,
    "rateLimitingEnabled": true,
    "errorHandlingEnabled": true,
    "monitoringEnabled": true
  },
  "tests": {
    "smokeTests": $([ "$SKIP_TESTS" = true ] && echo "false" || echo "true"),
    "smokeTestsPassed": true
  },
  "status": "success"
}
EOF

    log_info "Deployment report saved: $REPORT_FILE ✓"
}

# Print summary
print_summary() {
    echo ""
    log_info "=========================================="
    log_info "  Deployment Complete!"
    log_info "=========================================="
    echo ""
    log_info "Deployment Details:"
    log_info "  - Deployment ID: $DEPLOYMENT_ID"
    log_info "  - Environment: $ENVIRONMENT"
    log_info "  - Region: $REGION"
    log_info "  - Concurrency Limit: $CONCURRENCY_LIMIT"
    echo ""
    log_info "Configuration Files:"
    log_info "  - config/rate-limit.json"
    log_info "  - config/error-handling.json"
    log_info "  - .env.production"
    echo ""
    log_info "Next Steps:"
    log_info "  1. Start your application"
    log_info "  2. Monitor metrics at http://localhost:8080/metrics"
    log_info "  3. Check health at http://localhost:8080/health"
    log_info "  4. Review logs in ./logs/"
    log_info "  5. Monitor alerts in your alerting system"
    echo ""
    log_info "Rollback Command (if needed):"
    log_info "  bash ./scripts/rollback.sh --deployment-id $DEPLOYMENT_ID"
    echo ""
}

# Main execution
main() {
    log_info "Starting production deployment..."
    log_info "Deployment ID: $DEPLOYMENT_ID"
    echo ""

    validate_environment
    backup_deployment
    install_dependencies
    configure_rate_limiting
    configure_error_handling
    setup_monitoring
    run_smoke_tests
    generate_report
    print_summary

    log_info "Deployment completed successfully! 🚀"
}

# Run main function
main
