#!/usr/bin/env bash

# rollback.sh
# Automated rollback script for ElevenLabs deployments
# Usage: bash rollback.sh --deployment-id deploy-123 --reason "High error rate"

set -e

# Configuration
DEPLOYMENT_ID=""
REASON="Manual rollback"
NOTIFY=true
BACKUP_DIR="./backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --deployment-id)
            DEPLOYMENT_ID="$2"
            shift 2
            ;;
        --reason)
            REASON="$2"
            shift 2
            ;;
        --no-notify)
            NOTIFY=false
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

# Validate inputs
if [ -z "$DEPLOYMENT_ID" ]; then
    log_error "Deployment ID is required (--deployment-id)"
    exit 1
fi

log_info "Initiating rollback for deployment: $DEPLOYMENT_ID"
log_info "Reason: $REASON"

# Find backup
BACKUP_PATH="$BACKUP_DIR/$DEPLOYMENT_ID"

if [ ! -d "$BACKUP_PATH" ]; then
    log_error "Backup not found: $BACKUP_PATH"
    exit 1
fi

log_info "Found backup at: $BACKUP_PATH"

# Restore configuration files
log_info "Restoring configuration files..."

if [ -f "$BACKUP_PATH/.env.backup" ]; then
    cp "$BACKUP_PATH/.env.backup" .env
    log_info "Restored .env"
fi

if [ -f "$BACKUP_PATH/production.json.backup" ]; then
    mkdir -p config
    cp "$BACKUP_PATH/production.json.backup" config/production.json
    log_info "Restored config/production.json"
fi

# Notify team
if [ "$NOTIFY" = true ]; then
    log_info "Sending rollback notification..."

    MESSAGE="🔄 Rollback initiated
Deployment: $DEPLOYMENT_ID
Reason: $REASON
Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Add notification logic here (Slack, email, etc.)
    echo "$MESSAGE"
fi

log_info "Rollback complete ✓"
log_warn "Please verify application health and monitoring"
