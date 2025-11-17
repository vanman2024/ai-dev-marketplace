#!/bin/bash

################################################################################
# Celery Beat Testing Script
#
# Tests Celery Beat configuration and execution.
# Validates scheduler startup, schedule registration, and task execution.
#
# Usage:
#   bash test-beat.sh <celery-app>
#
# Examples:
#   bash test-beat.sh myproject
#   bash test-beat.sh tasks
#   bash test-beat.sh myapp.celery:app
#
# Requirements:
#   - Celery installed and accessible
#   - Redis or configured broker running
#   - Tasks module importable
#
# Exit codes:
#   0 - All tests passed
#   1 - Tests failed
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Print functions
print_error() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    ((TESTS_FAILED++))
}

print_success() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    ((TESTS_PASSED++))
}

print_info() {
    echo -e "${BLUE}ℹ INFO: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

run_test() {
    ((TESTS_RUN++))
}

# Check if app argument provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <celery-app>"
    echo ""
    echo "Examples:"
    echo "  $0 myproject"
    echo "  $0 tasks"
    echo "  $0 myapp.celery:app"
    exit 1
fi

CELERY_APP="$1"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Celery Beat Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "Testing Celery app: $CELERY_APP"
echo ""

# Test 1: Check Celery installation
echo "Test 1: Celery Installation"
echo "─────────────────────────────"
run_test

if command -v celery &> /dev/null; then
    CELERY_VERSION=$(celery --version 2>&1 | head -1)
    print_success "Celery installed: $CELERY_VERSION"
else
    print_error "Celery not found in PATH"
fi
echo ""

# Test 2: Check Python imports
echo "Test 2: Python Module Imports"
echo "─────────────────────────────"
run_test

IMPORT_TEST=$(python3 -c "
try:
    import celery
    from celery.schedules import crontab, schedule, solar
    print('SUCCESS')
except Exception as e:
    print(f'ERROR: {e}')
" 2>&1)

if [[ "$IMPORT_TEST" == "SUCCESS" ]]; then
    print_success "Celery modules importable"
else
    print_error "Failed to import Celery modules: $IMPORT_TEST"
fi
echo ""

# Test 3: Validate Celery app
echo "Test 3: Celery App Validation"
echo "─────────────────────────────"
run_test

APP_TEST=$(python3 -c "
import sys
try:
    app_module = '$CELERY_APP'.split(':')[0]
    __import__(app_module)
    print('SUCCESS')
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
" 2>&1)

if [[ "$APP_TEST" == "SUCCESS" ]]; then
    print_success "Celery app module importable"
else
    print_error "Failed to import app: $APP_TEST"
fi
echo ""

# Test 4: Check broker connectivity
echo "Test 4: Broker Connectivity"
echo "─────────────────────────────"
run_test

BROKER_TEST=$(celery -A "$CELERY_APP" inspect ping 2>&1 || echo "FAILED")

if [[ "$BROKER_TEST" != *"FAILED"* ]] && [[ "$BROKER_TEST" != *"Error"* ]]; then
    print_success "Broker connection successful"
else
    print_warning "Could not connect to broker (workers may not be running)"
fi
echo ""

# Test 5: List registered scheduled tasks
echo "Test 5: Scheduled Tasks Registration"
echo "─────────────────────────────────────"
run_test

print_info "Attempting to list scheduled tasks..."

# Create temporary Python script to inspect beat schedule
INSPECT_SCRIPT=$(mktemp)
cat > "$INSPECT_SCRIPT" << 'EOF'
import sys
try:
    app_path = sys.argv[1]
    if ':' in app_path:
        module_name, app_name = app_path.split(':')
    else:
        module_name = app_path
        app_name = 'app'

    module = __import__(module_name, fromlist=[app_name])
    app = getattr(module, app_name)

    schedule = app.conf.beat_schedule

    if schedule:
        print(f"Found {len(schedule)} scheduled task(s):")
        for name, config in schedule.items():
            task = config.get('task', 'unknown')
            schedule_type = type(config.get('schedule', None)).__name__
            print(f"  - {name}: {task} ({schedule_type})")
        print("SUCCESS")
    else:
        print("No scheduled tasks found")
        print("WARNING")
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
EOF

SCHEDULE_TEST=$(python3 "$INSPECT_SCRIPT" "$CELERY_APP" 2>&1)
rm -f "$INSPECT_SCRIPT"

if [[ "$SCHEDULE_TEST" == *"SUCCESS"* ]]; then
    echo "$SCHEDULE_TEST" | grep -v "SUCCESS"
    print_success "Scheduled tasks registered"
elif [[ "$SCHEDULE_TEST" == *"WARNING"* ]]; then
    print_warning "No scheduled tasks found in configuration"
else
    print_error "Failed to inspect schedule: $SCHEDULE_TEST"
fi
echo ""

# Test 6: Validate schedule syntax
echo "Test 6: Schedule Syntax Validation"
echo "─────────────────────────────────────"
run_test

SYNTAX_TEST=$(python3 -c "
import sys
try:
    app_path = '$CELERY_APP'
    if ':' in app_path:
        module_name, app_name = app_path.split(':')
    else:
        module_name = app_path
        app_name = 'app'

    module = __import__(module_name, fromlist=[app_name])
    app = getattr(module, app_name)

    schedule = app.conf.beat_schedule
    errors = []

    for name, config in schedule.items():
        if 'task' not in config:
            errors.append(f'{name}: Missing task field')
        if 'schedule' not in config:
            errors.append(f'{name}: Missing schedule field')

    if errors:
        for error in errors:
            print(error)
        sys.exit(1)
    else:
        print('SUCCESS')
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
" 2>&1)

if [[ "$SYNTAX_TEST" == "SUCCESS" ]]; then
    print_success "Schedule syntax valid"
else
    print_error "Schedule syntax errors: $SYNTAX_TEST"
fi
echo ""

# Test 7: Check timezone configuration
echo "Test 7: Timezone Configuration"
echo "─────────────────────────────"
run_test

TIMEZONE_TEST=$(python3 -c "
try:
    app_path = '$CELERY_APP'
    if ':' in app_path:
        module_name, app_name = app_path.split(':')
    else:
        module_name = app_path
        app_name = 'app'

    module = __import__(module_name, fromlist=[app_name])
    app = getattr(module, app_name)

    timezone = app.conf.timezone or 'Not configured'
    enable_utc = app.conf.enable_utc

    print(f'Timezone: {timezone}')
    print(f'UTC enabled: {enable_utc}')
    print('SUCCESS')
except Exception as e:
    print(f'ERROR: {e}')
" 2>&1)

if [[ "$TIMEZONE_TEST" == *"SUCCESS"* ]]; then
    echo "$TIMEZONE_TEST" | grep -v "SUCCESS"
    print_success "Timezone configuration found"
else
    print_warning "Could not determine timezone configuration"
fi
echo ""

# Test 8: Dry run beat scheduler (5 second test)
echo "Test 8: Beat Scheduler Dry Run"
echo "─────────────────────────────"
run_test

print_info "Starting beat scheduler for 5 seconds..."

# Start beat in background with timeout
BEAT_LOG=$(mktemp)
timeout 5s celery -A "$CELERY_APP" beat --loglevel=info > "$BEAT_LOG" 2>&1 || true

# Check beat log for successful startup
if grep -q "beat: Starting" "$BEAT_LOG"; then
    print_success "Beat scheduler started successfully"

    # Check for schedule registration
    if grep -q "Scheduler:" "$BEAT_LOG"; then
        SCHEDULE_COUNT=$(grep -c "Scheduler:" "$BEAT_LOG" || echo "0")
        print_info "Registered $SCHEDULE_COUNT schedule entries"
    fi

    # Check for any errors
    if grep -qi "error\|exception\|traceback" "$BEAT_LOG"; then
        print_warning "Errors detected in beat log:"
        grep -i "error\|exception" "$BEAT_LOG" | head -5
    fi
else
    print_error "Beat scheduler failed to start"
    echo "Log output:"
    cat "$BEAT_LOG"
fi

rm -f "$BEAT_LOG"
echo ""

# Test 9: Check beat schedule file
echo "Test 9: Beat Schedule Persistence"
echo "─────────────────────────────────────"
run_test

if [ -f "celerybeat-schedule" ]; then
    SCHEDULE_SIZE=$(du -h celerybeat-schedule | cut -f1)
    print_success "Beat schedule file exists (size: $SCHEDULE_SIZE)"
    print_info "Location: $(pwd)/celerybeat-schedule"

    # Clean up test schedule file
    print_info "Cleaning up test schedule file..."
    rm -f celerybeat-schedule
else
    print_warning "No beat schedule file created (database scheduler may be in use)"
fi
echo ""

# Test 10: Validate schedule task references
echo "Test 10: Task Reference Validation"
echo "─────────────────────────────────────"
run_test

TASK_REF_TEST=$(python3 -c "
import sys
try:
    app_path = '$CELERY_APP'
    if ':' in app_path:
        module_name, app_name = app_path.split(':')
    else:
        module_name = app_path
        app_name = 'app'

    module = __import__(module_name, fromlist=[app_name])
    app = getattr(module, app_name)

    schedule = app.conf.beat_schedule
    registered_tasks = list(app.tasks.keys())

    missing_tasks = []
    for name, config in schedule.items():
        task_name = config.get('task')
        if task_name and task_name not in registered_tasks:
            missing_tasks.append(f'{name}: references unknown task {task_name}')

    if missing_tasks:
        for task in missing_tasks:
            print(task)
        print('WARNING')
    else:
        print('SUCCESS')
except Exception as e:
    print(f'ERROR: {e}')
" 2>&1)

if [[ "$TASK_REF_TEST" == *"SUCCESS"* ]]; then
    print_success "All scheduled tasks reference valid task functions"
elif [[ "$TASK_REF_TEST" == *"WARNING"* ]]; then
    print_warning "Some tasks may not be registered:"
    echo "$TASK_REF_TEST" | grep -v "WARNING"
else
    print_error "Failed to validate task references"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Your Celery Beat configuration is ready for use."
    echo ""
    echo "To start beat scheduler:"
    echo "  celery -A $CELERY_APP beat --loglevel=info"
    echo ""
    echo "To start worker:"
    echo "  celery -A $CELERY_APP worker --loglevel=info"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Please address the failures before deploying."
    exit 1
fi
