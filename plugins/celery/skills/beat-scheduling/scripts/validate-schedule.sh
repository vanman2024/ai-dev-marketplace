#!/bin/bash

################################################################################
# Celery Beat Schedule Validation Script
#
# Validates schedule configuration files for syntax, structure, and best practices.
#
# Usage:
#   bash validate-schedule.sh <config-file>
#
# Examples:
#   bash validate-schedule.sh celeryconfig.py
#   bash validate-schedule.sh schedules.json
#
# Exit codes:
#   0 - All validations passed
#   1 - Validation errors found
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
CHECKS=0

# Print functions
print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
    ((WARNINGS++))
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ INFO: $1${NC}"
}

# Check if file argument provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <config-file>"
    echo ""
    echo "Examples:"
    echo "  $0 celeryconfig.py"
    echo "  $0 schedules.json"
    exit 1
fi

CONFIG_FILE="$1"

# Check if file exists
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Celery Beat Schedule Validator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "Validating: $CONFIG_FILE"
echo ""

# Determine file type
FILE_EXT="${CONFIG_FILE##*.}"

if [ "$FILE_EXT" = "py" ]; then
    echo "📝 Validating Python schedule configuration..."
    echo ""

    # Check Python syntax
    ((CHECKS++))
    if python3 -m py_compile "$CONFIG_FILE" 2>/dev/null; then
        print_success "Python syntax valid"
    else
        print_error "Python syntax invalid"
    fi

    # Check for required imports
    ((CHECKS++))
    if grep -q "from celery import Celery" "$CONFIG_FILE" || grep -q "import celery" "$CONFIG_FILE"; then
        print_success "Celery import found"
    else
        print_warning "Missing Celery import"
    fi

    # Check for schedule imports
    ((CHECKS++))
    if grep -q "from celery.schedules import" "$CONFIG_FILE"; then
        print_success "Schedule imports found"
    else
        print_warning "No schedule imports (crontab, solar, schedule)"
    fi

    # Check for beat_schedule configuration
    ((CHECKS++))
    if grep -q "beat_schedule" "$CONFIG_FILE"; then
        print_success "beat_schedule configuration found"
    else
        print_error "No beat_schedule configuration found"
    fi

    # Validate crontab expressions
    echo ""
    echo "🕐 Validating crontab schedules..."

    CRONTAB_COUNT=$(grep -c "crontab(" "$CONFIG_FILE" || true)
    if [ "$CRONTAB_COUNT" -gt 0 ]; then
        print_info "Found $CRONTAB_COUNT crontab schedule(s)"

        # Check for common crontab mistakes
        if grep -q "crontab(minute='60'" "$CONFIG_FILE"; then
            print_error "Invalid minute value (must be 0-59)"
        fi

        if grep -q "crontab(hour='24'" "$CONFIG_FILE"; then
            print_error "Invalid hour value (must be 0-23)"
        fi

        if grep -q "crontab(day_of_week='7'" "$CONFIG_FILE"; then
            print_warning "day_of_week 7 is Sunday (0 is also Sunday)"
        fi

        print_success "Crontab expressions appear valid"
    fi

    # Validate interval schedules
    echo ""
    echo "⏱️  Validating interval schedules..."

    INTERVAL_COUNT=$(grep -c "timedelta(" "$CONFIG_FILE" || true)
    if [ "$INTERVAL_COUNT" -gt 0 ]; then
        print_info "Found $INTERVAL_COUNT interval schedule(s)"

        # Check for very short intervals (potential performance issue)
        if grep -q "schedule.*[0-4]\\.0" "$CONFIG_FILE"; then
            print_warning "Very short interval detected (< 5 seconds) - may impact performance"
        fi

        print_success "Interval schedules appear valid"
    fi

    # Validate solar schedules
    echo ""
    echo "🌅 Validating solar schedules..."

    SOLAR_COUNT=$(grep -c "solar(" "$CONFIG_FILE" || true)
    if [ "$SOLAR_COUNT" -gt 0 ]; then
        print_info "Found $SOLAR_COUNT solar schedule(s)"

        # Check for valid solar events
        VALID_EVENTS="sunrise|sunset|dawn_civil|dawn_nautical|dawn_astronomical|dusk_civil|dusk_nautical|dusk_astronomical|solar_noon"

        if grep "solar(" "$CONFIG_FILE" | grep -vE "$VALID_EVENTS" | grep -q solar; then
            print_warning "Potentially invalid solar event name"
        fi

        print_success "Solar schedules appear valid"
    fi

    # Check timezone configuration
    echo ""
    echo "🌍 Validating timezone configuration..."
    ((CHECKS++))

    if grep -q "timezone.*=" "$CONFIG_FILE"; then
        TIMEZONE=$(grep "timezone.*=" "$CONFIG_FILE" | head -1 | sed "s/.*timezone.*=['\"]\\([^'\"]*\\)['\"].*/\\1/")
        print_info "Timezone configured: $TIMEZONE"

        if [ "$TIMEZONE" = "UTC" ]; then
            print_success "Using UTC timezone (recommended)"
        else
            print_warning "Using non-UTC timezone: $TIMEZONE (ensure consistency across deployment)"
        fi
    else
        print_warning "No explicit timezone configuration (will use default)"
    fi

    # Check for task naming
    echo ""
    echo "📛 Validating task naming..."
    ((CHECKS++))

    if grep -q "'name':" "$CONFIG_FILE" || grep -q '"name":' "$CONFIG_FILE"; then
        print_success "Task names defined"
    else
        print_warning "No explicit task names (using task function names)"
    fi

    # Check for task arguments
    echo ""
    echo "📦 Checking task arguments..."

    if grep -q "'args':" "$CONFIG_FILE" || grep -q "'kwargs':" "$CONFIG_FILE"; then
        print_info "Task arguments found"
        print_success "Arguments configured"
    fi

    # Check for task options
    echo ""
    echo "⚙️  Checking task options..."

    if grep -q "'options':" "$CONFIG_FILE"; then
        print_info "Task options found"

        if grep -q "expires" "$CONFIG_FILE"; then
            print_success "Task expiration configured"
        fi

        if grep -q "queue" "$CONFIG_FILE"; then
            print_success "Custom queue routing configured"
        fi
    fi

    # Security checks
    echo ""
    echo "🔒 Security validation..."
    ((CHECKS++))

    # Check for hardcoded credentials
    if grep -qE "(password|secret|key|token).*=.*['\"][^'\"]{8,}['\"]" "$CONFIG_FILE"; then
        if ! grep -q "os.getenv\|os.environ" "$CONFIG_FILE"; then
            print_error "Potential hardcoded credentials detected (use environment variables)"
        fi
    fi

    if grep -q "os.getenv\|os.environ" "$CONFIG_FILE"; then
        print_success "Using environment variables for configuration"
    else
        print_warning "No environment variable usage detected"
    fi

elif [ "$FILE_EXT" = "json" ]; then
    echo "📝 Validating JSON schedule configuration..."
    echo ""

    # Check JSON syntax
    ((CHECKS++))
    if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
        print_success "JSON syntax valid"
    else
        print_error "JSON syntax invalid"
    fi

    # Check required fields
    ((CHECKS++))
    if grep -q '"tasks"' "$CONFIG_FILE"; then
        print_success "Tasks array found"
    else
        print_error "Missing 'tasks' array"
    fi

    # Count tasks
    TASK_COUNT=$(grep -c '"name"' "$CONFIG_FILE" || true)
    if [ "$TASK_COUNT" -gt 0 ]; then
        print_info "Found $TASK_COUNT task(s)"
    fi

    # Validate task structure
    echo ""
    echo "📋 Validating task structure..."

    if grep -q '"schedule"' "$CONFIG_FILE"; then
        print_success "Schedule definitions found"
    else
        print_warning "No schedule definitions"
    fi

    if grep -q '"task"' "$CONFIG_FILE"; then
        print_success "Task references found"
    else
        print_error "No task references"
    fi

else
    print_error "Unsupported file type: $FILE_EXT (expected .py or .json)"
    exit 1
fi

# Check for schedule conflicts
echo ""
echo "🔍 Checking for potential schedule conflicts..."
((CHECKS++))

# Extract all task names and check for duplicates
DUPLICATE_NAMES=$(grep -oE "'name':\s*'[^']+'" "$CONFIG_FILE" 2>/dev/null | sort | uniq -d || true)

if [ -n "$DUPLICATE_NAMES" ]; then
    print_warning "Duplicate task names detected:"
    echo "$DUPLICATE_NAMES"
else
    print_success "No duplicate task names"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Validation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total Checks: $CHECKS"
echo -e "Errors:       ${RED}$ERRORS${NC}"
echo -e "Warnings:     ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ All validations passed!${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Test schedule with: bash test-beat.sh <celery-app>"
        echo "  2. Start beat: celery -A <app> beat --loglevel=debug"
        exit 0
    else
        echo -e "${YELLOW}⚠ Validation passed with warnings${NC}"
        echo ""
        echo "Consider addressing warnings before deployment."
        exit 0
    fi
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s)${NC}"
    echo ""
    echo "Please fix errors before proceeding."
    exit 1
fi
