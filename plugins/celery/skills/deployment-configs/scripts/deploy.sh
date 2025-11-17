#!/bin/bash
#
# Celery Deployment Orchestrator
# Deploys Celery workers and beat scheduler to various platforms
#
# Usage:
#   ./deploy.sh <platform> [options]
#
# Platforms:
#   docker      - Docker Compose deployment
#   kubernetes  - Kubernetes deployment
#   systemd     - Systemd service deployment
#
# Options:
#   --env=ENV              Environment (development|staging|production)
#   --namespace=NS         Kubernetes namespace (default: default)
#   --replicas=N           Number of worker replicas (default: 3)
#   --workers=N            Number of systemd workers (default: 4)
#   --config=FILE          Custom configuration file
#   --dry-run              Generate configs without deploying
#   --user=USER            Systemd user (default: celery)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

# Default values
PLATFORM=""
ENVIRONMENT="production"
NAMESPACE="default"
REPLICAS=3
WORKERS=4
CONFIG_FILE=""
DRY_RUN=false
SYSTEMD_USER="celery"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
parse_args() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi

    PLATFORM="$1"
    shift

    while [ $# -gt 0 ]; do
        case "$1" in
            --env=*)
                ENVIRONMENT="${1#*=}"
                ;;
            --namespace=*)
                NAMESPACE="${1#*=}"
                ;;
            --replicas=*)
                REPLICAS="${1#*=}"
                ;;
            --workers=*)
                WORKERS="${1#*=}"
                ;;
            --config=*)
                CONFIG_FILE="${1#*=}"
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --user=*)
                SYSTEMD_USER="${1#*=}"
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

show_usage() {
    cat << EOF
Usage: $0 <platform> [options]

Platforms:
  docker      - Docker Compose deployment
  kubernetes  - Kubernetes deployment
  systemd     - Systemd service deployment

Options:
  --env=ENV              Environment (development|staging|production)
  --namespace=NS         Kubernetes namespace (default: default)
  --replicas=N           Number of worker replicas (default: 3)
  --workers=N            Number of systemd workers (default: 4)
  --config=FILE          Custom configuration file
  --dry-run              Generate configs without deploying
  --user=USER            Systemd user (default: celery)

Examples:
  $0 docker --env=staging
  $0 kubernetes --namespace=prod --replicas=10
  $0 systemd --workers=4 --user=celery

EOF
}

# Pre-deployment checks
run_pre_checks() {
    log_info "Running pre-deployment checks..."

    # Check for required environment variables
    local required_vars=("CELERY_BROKER_URL" "CELERY_RESULT_BACKEND")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        log_info "Please set these variables or provide them in .env file"
        return 1
    fi

    # Check for hardcoded secrets (security validation)
    if grep -r "sk-ant-api" "$PROJECT_ROOT" 2>/dev/null | grep -v ".git" | grep -v "node_modules" > /dev/null; then
        log_error "SECURITY: Hardcoded API keys detected! Use environment variables."
        return 1
    fi

    log_success "Pre-deployment checks passed"
    return 0
}

# Deploy to Docker
deploy_docker() {
    log_info "Deploying to Docker Compose..."

    # Copy template
    if [ ! -f "$PROJECT_ROOT/docker-compose.yml" ] || [ "$DRY_RUN" = true ]; then
        cp "$TEMPLATES_DIR/docker-compose.yml" "$PROJECT_ROOT/"
        cp "$TEMPLATES_DIR/Dockerfile.worker" "$PROJECT_ROOT/"
        log_success "Generated Docker configuration files"
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "Dry run: Configuration generated, skipping deployment"
        return 0
    fi

    # Build images
    log_info "Building Docker images..."
    docker-compose build

    # Start services
    log_info "Starting services..."
    docker-compose up -d --scale celery-worker="$REPLICAS"

    # Wait for services
    log_info "Waiting for services to be healthy..."
    sleep 10

    # Check health
    if docker-compose ps | grep -q "unhealthy"; then
        log_error "Some services are unhealthy"
        docker-compose ps
        return 1
    fi

    log_success "Docker deployment completed successfully"
    log_info "View logs: docker-compose logs -f celery-worker"
    log_info "Flower UI: http://localhost:5555"
}

# Deploy to Kubernetes
deploy_kubernetes() {
    log_info "Deploying to Kubernetes (namespace: $NAMESPACE)..."

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install Kubernetes CLI."
        return 1
    fi

    # Create namespace if not exists
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_info "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    fi

    # Generate manifests directory
    local manifests_dir="$PROJECT_ROOT/k8s-manifests"
    mkdir -p "$manifests_dir"

    # Copy and customize templates
    cp "$TEMPLATES_DIR/kubernetes/"*.yaml "$manifests_dir/"

    # Replace placeholders
    find "$manifests_dir" -type f -name "*.yaml" -exec sed -i \
        -e "s/namespace: default/namespace: $NAMESPACE/g" \
        -e "s/replicas: 3/replicas: $REPLICAS/g" \
        {} \;

    log_success "Generated Kubernetes manifests in $manifests_dir"

    if [ "$DRY_RUN" = true ]; then
        log_info "Dry run: Manifests generated, skipping deployment"
        return 0
    fi

    # Apply manifests
    log_info "Applying Kubernetes manifests..."
    kubectl apply -f "$manifests_dir/" -n "$NAMESPACE"

    # Wait for rollout
    log_info "Waiting for deployment rollout..."
    kubectl rollout status deployment/celery-worker -n "$NAMESPACE" --timeout=5m

    # Check pods
    log_info "Checking pod status..."
    kubectl get pods -n "$NAMESPACE" -l app=celery-worker

    log_success "Kubernetes deployment completed successfully"
    log_info "View logs: kubectl logs -f deployment/celery-worker -n $NAMESPACE"
    log_info "Scale workers: kubectl scale deployment celery-worker --replicas=N -n $NAMESPACE"
}

# Deploy to Systemd
deploy_systemd() {
    log_info "Deploying to Systemd (user: $SYSTEMD_USER, workers: $WORKERS)..."

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "Systemd deployment requires root privileges. Use sudo."
        return 1
    fi

    # Copy service files
    local systemd_dir="/etc/systemd/system"
    cp "$TEMPLATES_DIR/systemd/celery-worker.service" "$systemd_dir/"
    cp "$TEMPLATES_DIR/systemd/celery-beat.service" "$systemd_dir/"

    log_success "Installed systemd service files"

    if [ "$DRY_RUN" = true ]; then
        log_info "Dry run: Service files installed, skipping activation"
        return 0
    fi

    # Reload systemd
    log_info "Reloading systemd daemon..."
    systemctl daemon-reload

    # Enable and start workers
    log_info "Enabling and starting $WORKERS worker instances..."
    for i in $(seq 1 "$WORKERS"); do
        systemctl enable "celery-worker@${i}.service"
        systemctl start "celery-worker@${i}.service"
    done

    # Enable and start beat
    log_info "Enabling and starting beat scheduler..."
    systemctl enable celery-beat.service
    systemctl start celery-beat.service

    # Check status
    sleep 5
    log_info "Checking service status..."
    systemctl status "celery-worker@*.service" --no-pager
    systemctl status celery-beat.service --no-pager

    log_success "Systemd deployment completed successfully"
    log_info "View logs: journalctl -u celery-worker@1.service -f"
    log_info "Check status: systemctl status celery-worker@*.service"
}

# Main deployment function
deploy() {
    case "$PLATFORM" in
        docker)
            deploy_docker
            ;;
        kubernetes|k8s)
            deploy_kubernetes
            ;;
        systemd)
            deploy_systemd
            ;;
        *)
            log_error "Unknown platform: $PLATFORM"
            show_usage
            exit 1
            ;;
    esac
}

# Main execution
main() {
    parse_args "$@"

    log_info "=== Celery Deployment ==="
    log_info "Platform: $PLATFORM"
    log_info "Environment: $ENVIRONMENT"
    log_info "Dry Run: $DRY_RUN"

    if ! run_pre_checks; then
        log_error "Pre-deployment checks failed. Aborting."
        exit 1
    fi

    if deploy; then
        log_success "=== Deployment Completed Successfully ==="
    else
        log_error "=== Deployment Failed ==="
        exit 1
    fi
}

main "$@"
