#!/bin/bash
#
# Celery Deployment Test Suite
# Validates deployed Celery infrastructure
#
# Usage:
#   ./test-deployment.sh <platform> [options]
#
# Platforms:
#   docker      - Test Docker Compose deployment
#   kubernetes  - Test Kubernetes deployment
#   systemd     - Test Systemd services
#
# Options:
#   --namespace=NS    Kubernetes namespace (default: default)
#   --verbose         Show detailed output
#   --watch           Continuous monitoring
#   --interval=N      Watch interval in seconds (default: 60)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM=""
NAMESPACE="default"
VERBOSE=false
WATCH=false
INTERVAL=60

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Parse arguments
parse_args() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <platform> [options]"
        exit 1
    fi

    PLATFORM="$1"
    shift

    while [ $# -gt 0 ]; do
        case "$1" in
            --namespace=*) NAMESPACE="${1#*=}" ;;
            --verbose) VERBOSE=true ;;
            --watch) WATCH=true ;;
            --interval=*) INTERVAL="${1#*=}" ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done
}

# Test Docker deployment
test_docker() {
    log_info "Testing Docker Compose deployment..."

    # Check if services are running
    if ! docker-compose ps | grep -q "Up"; then
        log_error "Docker services are not running"
        return 1
    fi
    log_success "Docker services are running"

    # Check Redis
    if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
        log_success "Redis broker is responsive"
    else
        log_error "Redis broker is not responsive"
    fi

    # Check PostgreSQL
    if docker-compose exec -T postgres pg_isready -U celery | grep -q "accepting connections"; then
        log_success "PostgreSQL result backend is responsive"
    else
        log_error "PostgreSQL result backend is not responsive"
    fi

    # Check Celery workers
    if docker-compose exec -T celery-worker celery -A myapp inspect ping | grep -q "pong"; then
        log_success "Celery workers are responding"
    else
        log_error "Celery workers are not responding"
    fi

    # Check worker stats
    local worker_count=$(docker-compose exec -T celery-worker celery -A myapp inspect stats | grep -c "OK")
    log_success "Active workers: $worker_count"

    # Check Flower
    if curl -s http://localhost:5555/healthcheck > /dev/null; then
        log_success "Flower monitoring dashboard is accessible"
    else
        log_warning "Flower monitoring dashboard is not accessible"
    fi

    # Submit test task
    log_info "Submitting test task..."
    if docker-compose exec -T celery-worker python -c "
from celery import Celery
app = Celery('myapp')
app.config_from_object('celeryconfig')
result = app.send_task('test_task')
print('Task submitted:', result.id)
"; then
        log_success "Test task submitted successfully"
    else
        log_warning "Could not submit test task"
    fi

    # Check logs for errors
    if docker-compose logs celery-worker | grep -i "error" | tail -5; then
        log_warning "Recent errors found in worker logs"
    fi
}

# Test Kubernetes deployment
test_kubernetes() {
    log_info "Testing Kubernetes deployment (namespace: $NAMESPACE)..."

    # Check if pods are running
    local running_pods=$(kubectl get pods -n "$NAMESPACE" -l app=celery-worker --field-selector=status.phase=Running --no-headers | wc -l)
    if [ "$running_pods" -gt 0 ]; then
        log_success "Celery worker pods running: $running_pods"
    else
        log_error "No Celery worker pods are running"
        return 1
    fi

    # Check pod health
    local healthy_pods=$(kubectl get pods -n "$NAMESPACE" -l app=celery-worker -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -c "True")
    if [ "$healthy_pods" -eq "$running_pods" ]; then
        log_success "All worker pods are healthy ($healthy_pods/$running_pods)"
    else
        log_error "Some worker pods are unhealthy ($healthy_pods/$running_pods)"
    fi

    # Check beat scheduler
    local beat_running=$(kubectl get statefulset -n "$NAMESPACE" celery-beat -o jsonpath='{.status.readyReplicas}')
    if [ "${beat_running:-0}" -eq 1 ]; then
        log_success "Celery beat scheduler is running"
    else
        log_error "Celery beat scheduler is not running"
    fi

    # Test worker connectivity
    local test_pod=$(kubectl get pods -n "$NAMESPACE" -l app=celery-worker -o jsonpath='{.items[0].metadata.name}')
    if kubectl exec -n "$NAMESPACE" "$test_pod" -- celery -A myapp inspect ping | grep -q "pong"; then
        log_success "Workers are responding to ping"
    else
        log_error "Workers are not responding to ping"
    fi

    # Check HPA status
    if kubectl get hpa -n "$NAMESPACE" celery-worker-hpa &> /dev/null; then
        local current_replicas=$(kubectl get hpa -n "$NAMESPACE" celery-worker-hpa -o jsonpath='{.status.currentReplicas}')
        local desired_replicas=$(kubectl get hpa -n "$NAMESPACE" celery-worker-hpa -o jsonpath='{.status.desiredReplicas}')
        log_success "HPA status: $current_replicas/$desired_replicas replicas"
    fi

    # Check recent pod restarts
    local restart_count=$(kubectl get pods -n "$NAMESPACE" -l app=celery-worker -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '{s+=$1} END {print s}')
    if [ "${restart_count:-0}" -eq 0 ]; then
        log_success "No pod restarts detected"
    else
        log_warning "Total pod restarts: $restart_count"
    fi

    # Check for errors in logs
    if kubectl logs -n "$NAMESPACE" -l app=celery-worker --tail=100 | grep -i "error"; then
        log_warning "Recent errors found in worker logs"
    fi
}

# Test Systemd deployment
test_systemd() {
    log_info "Testing Systemd services..."

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "Systemd tests require root privileges. Use sudo."
        return 1
    fi

    # Check worker services
    local active_workers=0
    for service in /etc/systemd/system/celery-worker@*.service; do
        local instance=$(basename "$service" | sed 's/celery-worker@\(.*\)\.service/\1/')
        if systemctl is-active "celery-worker@${instance}.service" &> /dev/null; then
            active_workers=$((active_workers + 1))
            log_success "Worker instance $instance is active"
        else
            log_error "Worker instance $instance is not active"
        fi
    done

    if [ "$active_workers" -gt 0 ]; then
        log_success "Total active workers: $active_workers"
    else
        log_error "No active workers found"
        return 1
    fi

    # Check beat service
    if systemctl is-active celery-beat.service &> /dev/null; then
        log_success "Celery beat scheduler is active"
    else
        log_error "Celery beat scheduler is not active"
    fi

    # Check for failed units
    local failed_count=$(systemctl list-units "celery-*" --state=failed --no-legend | wc -l)
    if [ "$failed_count" -eq 0 ]; then
        log_success "No failed Celery services"
    else
        log_error "Failed Celery services: $failed_count"
        systemctl list-units "celery-*" --state=failed
    fi

    # Check recent restarts
    log_info "Checking service restart history..."
    journalctl -u "celery-worker@*" -u celery-beat.service --since "1 hour ago" | grep -i "Started\|Stopped" | tail -10

    # Check for errors in logs
    if journalctl -u "celery-worker@*" --since "1 hour ago" | grep -i "error"; then
        log_warning "Recent errors found in worker logs"
    fi
}

# Run test suite
run_tests() {
    case "$PLATFORM" in
        docker)
            test_docker
            ;;
        kubernetes|k8s)
            test_kubernetes
            ;;
        systemd)
            test_systemd
            ;;
        *)
            log_error "Unknown platform: $PLATFORM"
            exit 1
            ;;
    esac
}

# Show test summary
show_summary() {
    echo ""
    echo "=== Test Summary ==="
    log_success "Passed: $TESTS_PASSED"
    if [ "$TESTS_FAILED" -gt 0 ]; then
        log_error "Failed: $TESTS_FAILED"
    else
        log_info "Failed: $TESTS_FAILED"
    fi
    echo "===================="

    if [ "$TESTS_FAILED" -gt 0 ]; then
        return 1
    fi
    return 0
}

# Main execution
main() {
    parse_args "$@"

    if [ "$WATCH" = true ]; then
        log_info "Starting continuous monitoring (interval: ${INTERVAL}s)"
        log_info "Press Ctrl+C to stop"
        while true; do
            clear
            TESTS_PASSED=0
            TESTS_FAILED=0
            run_tests
            show_summary || true
            sleep "$INTERVAL"
        done
    else
        run_tests
        show_summary
    fi
}

main "$@"
