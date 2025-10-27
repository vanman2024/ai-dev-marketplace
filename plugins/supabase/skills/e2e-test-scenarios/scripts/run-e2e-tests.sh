#!/bin/bash
set -euo pipefail

# Run Complete E2E Test Suite for Supabase
# Executes all test categories: database, auth, vector, realtime, and integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Parse command line arguments
VERBOSE=false
CLEANUP=true
PARALLEL=true
COVERAGE=false
TEST_SUITE="all"

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --no-cleanup)
            CLEANUP=false
            shift
            ;;
        --no-parallel)
            PARALLEL=false
            shift
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        --suite)
            TEST_SUITE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose       Enable verbose output"
            echo "  --no-cleanup        Skip cleanup after tests"
            echo "  --no-parallel       Run tests sequentially"
            echo "  --coverage          Generate coverage report"
            echo "  --suite <name>      Run specific test suite (database|auth|vector|realtime|integration|all)"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Load environment variables
load_env() {
    if [[ -f "$PROJECT_ROOT/.env.test" ]]; then
        set -a
        source "$PROJECT_ROOT/.env.test"
        set +a
        log_info "Loaded .env.test"
    else
        log_error ".env.test not found. Run setup-test-env.sh first"
        exit 1
    fi
}

# Verify test environment
verify_environment() {
    log_section "Verifying Test Environment"

    # Check required env variables
    local required_vars=(
        "SUPABASE_TEST_URL"
        "SUPABASE_TEST_ANON_KEY"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Missing required environment variable: $var"
            exit 1
        fi
    done

    # Check Supabase connection
    if command -v supabase &> /dev/null; then
        if supabase status &> /dev/null; then
            log_info "✓ Supabase is running"
        else
            log_warn "Supabase local instance not running"
            log_warn "Start it with: supabase start"
        fi
    fi

    # Check node_modules
    if [[ ! -d "$PROJECT_ROOT/node_modules" ]]; then
        log_error "node_modules not found. Run: npm install"
        exit 1
    fi

    log_info "✓ Environment verification complete"
}

# Run database tests (pgTAP)
run_database_tests() {
    log_section "Running Database Tests (pgTAP)"

    if [[ ! -d "$PROJECT_ROOT/supabase/tests" ]]; then
        log_warn "No database tests found, skipping"
        ((SKIPPED_TESTS++))
        return
    fi

    cd "$PROJECT_ROOT"

    if supabase test db; then
        log_info "✓ Database tests passed"
        ((PASSED_TESTS++))
    else
        log_error "✗ Database tests failed"
        ((FAILED_TESTS++))
        return 1
    fi
}

# Run auth workflow tests
run_auth_tests() {
    log_section "Running Authentication Tests"

    if [[ -f "$SCRIPT_DIR/test-auth-workflow.sh" ]]; then
        if bash "$SCRIPT_DIR/test-auth-workflow.sh"; then
            log_info "✓ Auth tests passed"
            ((PASSED_TESTS++))
        else
            log_error "✗ Auth tests failed"
            ((FAILED_TESTS++))
            return 1
        fi
    else
        log_warn "Auth test script not found, skipping"
        ((SKIPPED_TESTS++))
    fi
}

# Run vector/AI tests
run_vector_tests() {
    log_section "Running Vector/AI Tests"

    if [[ -f "$SCRIPT_DIR/test-ai-features.sh" ]]; then
        if bash "$SCRIPT_DIR/test-ai-features.sh"; then
            log_info "✓ Vector tests passed"
            ((PASSED_TESTS++))
        else
            log_error "✗ Vector tests failed"
            ((FAILED_TESTS++))
            return 1
        fi
    else
        log_warn "Vector test script not found, skipping"
        ((SKIPPED_TESTS++))
    fi
}

# Run realtime tests
run_realtime_tests() {
    log_section "Running Realtime Tests"

    if [[ -f "$SCRIPT_DIR/test-realtime-workflow.sh" ]]; then
        if bash "$SCRIPT_DIR/test-realtime-workflow.sh"; then
            log_info "✓ Realtime tests passed"
            ((PASSED_TESTS++))
        else
            log_error "✗ Realtime tests failed"
            ((FAILED_TESTS++))
            return 1
        fi
    else
        log_warn "Realtime test script not found, skipping"
        ((SKIPPED_TESTS++))
    fi
}

# Run Jest/Vitest integration tests
run_integration_tests() {
    log_section "Running Integration Tests"

    cd "$PROJECT_ROOT"

    local test_cmd="npm test"
    local test_args=""

    if [[ "$VERBOSE" == "true" ]]; then
        test_args="$test_args --verbose"
    fi

    if [[ "$PARALLEL" == "false" ]]; then
        test_args="$test_args --maxWorkers=1"
    fi

    if [[ "$COVERAGE" == "true" ]]; then
        test_args="$test_args --coverage"
    fi

    if $test_cmd $test_args; then
        log_info "✓ Integration tests passed"
        ((PASSED_TESTS++))
    else
        log_error "✗ Integration tests failed"
        ((FAILED_TESTS++))
        return 1
    fi
}

# Cleanup test resources
cleanup_tests() {
    if [[ "$CLEANUP" == "false" ]]; then
        log_info "Cleanup disabled, skipping"
        return
    fi

    log_section "Cleaning Up Test Resources"

    if [[ -f "$SCRIPT_DIR/cleanup-test-resources.sh" ]]; then
        bash "$SCRIPT_DIR/cleanup-test-resources.sh"
        log_info "✓ Cleanup complete"
    else
        log_warn "Cleanup script not found"
    fi
}

# Generate test report
generate_report() {
    log_section "Test Results Summary"

    TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS + SKIPPED_TESTS))

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Total Tests:   $TOTAL_TESTS"
    echo -e "  ${GREEN}Passed:        $PASSED_TESTS${NC}"
    echo -e "  ${RED}Failed:        $FAILED_TESTS${NC}"
    echo -e "  ${YELLOW}Skipped:       $SKIPPED_TESTS${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    local start_time=$(date +%s)

    log_section "Supabase E2E Test Suite"
    echo "Suite: $TEST_SUITE"
    echo "Parallel: $PARALLEL"
    echo "Coverage: $COVERAGE"
    echo ""

    load_env
    verify_environment

    # Run selected test suite
    case "$TEST_SUITE" in
        database)
            run_database_tests || true
            ;;
        auth)
            run_auth_tests || true
            ;;
        vector)
            run_vector_tests || true
            ;;
        realtime)
            run_realtime_tests || true
            ;;
        integration)
            run_integration_tests || true
            ;;
        all)
            run_database_tests || true
            run_auth_tests || true
            run_vector_tests || true
            run_realtime_tests || true
            run_integration_tests || true
            ;;
        *)
            log_error "Unknown test suite: $TEST_SUITE"
            exit 1
            ;;
    esac

    cleanup_tests

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    generate_report

    echo ""
    echo "Total execution time: ${duration}s"
    echo ""

    # Exit with appropriate code
    if [[ $FAILED_TESTS -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
