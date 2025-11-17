#!/bin/bash
#
# Validate Celery Canvas Workflow Structure
# Static analysis of workflow patterns and best practices
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
ERRORS=0
WARNINGS=0
INFO=0

# Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") <workflow_file>

Validate Celery canvas workflow structure and best practices.

Arguments:
    workflow_file    Path to Python workflow file

Examples:
    # Validate single workflow
    $(basename "$0") path/to/workflow.py

    # Validate all workflows in directory
    for f in workflows/*.py; do $(basename "$0") "\$f"; done

Checks:
    - Result backend configuration
    - ignore_result settings for groups/chords
    - Error handling patterns
    - Timeout configurations
    - Signature usage
    - Task dependencies
EOF
    exit 1
}

# Parse arguments
if [[ $# -lt 1 ]]; then
    usage
fi

WORKFLOW_FILE="$1"

if [[ ! -f "$WORKFLOW_FILE" ]]; then
    echo -e "${RED}Error: File not found: $WORKFLOW_FILE${NC}" >&2
    exit 1
fi

# Helper functions
error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((ERRORS++))
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    ((INFO++))
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Check result backend
check_result_backend() {
    echo -e "\n${BLUE}Checking result backend configuration...${NC}"

    if ! grep -q "result_backend" "$WORKFLOW_FILE"; then
        error "No result_backend configured - required for canvas operations"
        info "Add: result_backend = 'redis://localhost:6379/0'"
    else
        success "Result backend configured"
    fi

    # Check for result_extended
    if grep -q "chord\|group" "$WORKFLOW_FILE" && ! grep -q "result_extended" "$WORKFLOW_FILE"; then
        warning "result_extended not set - recommended for canvas workflows"
        info "Add: result_extended = True"
    fi
}

# Check ignore_result in canvas tasks
check_ignore_result() {
    echo -e "\n${BLUE}Checking ignore_result settings...${NC}"

    # Find tasks used in groups/chords
    if grep -q "group\|chord" "$WORKFLOW_FILE"; then
        # Check for ignore_result=True in task definitions
        if grep -q "@app.task.*ignore_result=True" "$WORKFLOW_FILE"; then
            # Get line numbers
            local lines=$(grep -n "@app.task.*ignore_result=True" "$WORKFLOW_FILE" | cut -d: -f1)

            # Check if these tasks are used in groups/chords
            for line in $lines; do
                local task_name=$(sed -n "$((line+1))p" "$WORKFLOW_FILE" | grep -oP 'def \K[^(]+')
                if grep -q "group.*$task_name\|chord.*$task_name" "$WORKFLOW_FILE"; then
                    error "Task '$task_name' has ignore_result=True but is used in group/chord"
                    info "Tasks in groups/chords must NOT ignore results"
                fi
            done
        fi

        # Check for explicit ignore_result=False
        if ! grep -q "ignore_result=False" "$WORKFLOW_FILE"; then
            warning "Consider explicitly setting ignore_result=False for canvas tasks"
        else
            success "Explicit ignore_result=False found"
        fi
    fi
}

# Check error handling
check_error_handling() {
    echo -e "\n${BLUE}Checking error handling...${NC}"

    local has_error_handling=false

    # Check for on_error callbacks
    if grep -q "\.on_error" "$WORKFLOW_FILE"; then
        success "Error callbacks found (.on_error)"
        has_error_handling=true
    fi

    # Check for try-except blocks
    if grep -q "try:" "$WORKFLOW_FILE" && grep -q "except" "$WORKFLOW_FILE"; then
        success "Try-except blocks found"
        has_error_handling=true
    fi

    # Check for error callback task definitions
    if grep -q "def.*error.*request.*exc.*traceback" "$WORKFLOW_FILE"; then
        success "Error callback tasks defined"
        has_error_handling=true
    fi

    if ! $has_error_handling; then
        warning "No error handling detected"
        info "Consider adding .on_error() callbacks or try-except blocks"
    fi
}

# Check timeout configurations
check_timeouts() {
    echo -e "\n${BLUE}Checking timeout configurations...${NC}"

    # Check for time_limit
    if grep -q "time_limit" "$WORKFLOW_FILE"; then
        success "Time limits configured"

        # Check for soft_time_limit
        if ! grep -q "soft_time_limit" "$WORKFLOW_FILE"; then
            warning "time_limit without soft_time_limit - consider adding soft timeout"
        fi
    else
        warning "No time limits configured"
        info "Consider adding time_limit and soft_time_limit for long-running tasks"
    fi

    # Check for .get() timeout
    if grep -q "\.get()" "$WORKFLOW_FILE" && ! grep -q "\.get(timeout=" "$WORKFLOW_FILE"; then
        warning ".get() called without timeout - may block indefinitely"
        info "Use: result.get(timeout=30)"
    fi
}

# Check signature usage
check_signatures() {
    echo -e "\n${BLUE}Checking signature usage...${NC}"

    # Check for signature imports
    if grep -q "from celery import.*signature" "$WORKFLOW_FILE"; then
        success "Signature imported"
    fi

    # Check for .s() usage
    if grep -q "\.s(" "$WORKFLOW_FILE"; then
        success "Signature shorthand (.s) used"
    fi

    # Check for .si() immutable signatures
    if grep -q "\.si(" "$WORKFLOW_FILE"; then
        success "Immutable signatures (.si) used"
        info "Good for preventing result forwarding in chains"
    fi

    # Check for potential argument forwarding issues
    if grep -q "chain" "$WORKFLOW_FILE" && ! grep -q "\.si(" "$WORKFLOW_FILE"; then
        warning "Chain without immutable signatures - verify result forwarding is intentional"
    fi
}

# Check chord requirements
check_chord_requirements() {
    echo -e "\n${BLUE}Checking chord requirements...${NC}"

    if ! grep -q "chord" "$WORKFLOW_FILE"; then
        return 0
    fi

    success "Chord usage detected"

    # Check for result backend (already checked but critical for chords)
    if ! grep -q "result_backend" "$WORKFLOW_FILE"; then
        error "Chords require result backend - not configured"
    fi

    # Check for Redis version comment/note
    if ! grep -qi "redis.*2\.2" "$WORKFLOW_FILE"; then
        info "Note: Chords require Redis 2.2+ for proper operation"
    fi

    # Check for after_return override warning
    if grep -q "def after_return" "$WORKFLOW_FILE" && ! grep -q "super().*after_return" "$WORKFLOW_FILE"; then
        error "after_return() override without super() call - breaks chord callbacks"
        info "Always call super().after_return() in overrides"
    fi
}

# Check for anti-patterns
check_anti_patterns() {
    echo -e "\n${BLUE}Checking for anti-patterns...${NC}"

    # Synchronous waiting in tasks
    if grep -q "\.get()" "$WORKFLOW_FILE"; then
        # Check if it's inside a task definition
        local in_task=false
        while IFS= read -r line; do
            if [[ "$line" =~ @app\.task ]]; then
                in_task=true
            elif [[ "$line" =~ ^def[[:space:]] ]] && [[ ! "$line" =~ @app\.task ]]; then
                in_task=false
            fi

            if $in_task && [[ "$line" =~ \.get\( ]]; then
                warning "Synchronous .get() called inside task - avoid blocking in tasks"
                break
            fi
        done < "$WORKFLOW_FILE"
    fi

    # Deeply nested workflows
    local nesting_level=$(grep -o "chord\|group\|chain" "$WORKFLOW_FILE" | wc -l)
    if [[ $nesting_level -gt 10 ]]; then
        warning "High nesting level ($nesting_level primitives) - consider simplifying"
    fi

    # Missing task names
    if grep -q "@app.task\b" "$WORKFLOW_FILE" && ! grep -q "@app.task(name=" "$WORKFLOW_FILE"; then
        info "Consider explicitly naming tasks for easier debugging"
    fi
}

# Check retry configuration
check_retry_config() {
    echo -e "\n${BLUE}Checking retry configuration...${NC}"

    if grep -q "autoretry_for" "$WORKFLOW_FILE"; then
        success "Automatic retry configured"

        # Check for retry_backoff
        if grep -q "retry_backoff=True" "$WORKFLOW_FILE"; then
            success "Exponential backoff enabled"
        else
            warning "autoretry_for without retry_backoff - consider exponential backoff"
        fi

        # Check for max_retries
        if ! grep -q "max_retries" "$WORKFLOW_FILE"; then
            warning "autoretry_for without max_retries - may retry indefinitely"
        fi
    fi
}

# Check workflow composition
check_workflow_composition() {
    echo -e "\n${BLUE}Checking workflow composition...${NC}"

    # Check for canvas primitives usage
    local uses_chain=$(grep -q "chain" "$WORKFLOW_FILE" && echo "yes" || echo "no")
    local uses_group=$(grep -q "group" "$WORKFLOW_FILE" && echo "yes" || echo "no")
    local uses_chord=$(grep -q "chord" "$WORKFLOW_FILE" && echo "yes" || echo "no")

    info "Primitives: chain=$uses_chain, group=$uses_group, chord=$uses_chord"

    # Check for workflow complexity
    if [[ "$uses_chain" == "yes" ]] && [[ "$uses_chord" == "yes" ]]; then
        success "Complex workflow composition detected"
    fi
}

# Main validation
main() {
    echo -e "${GREEN}=== Celery Canvas Validation ===${NC}"
    echo -e "File: ${BLUE}$WORKFLOW_FILE${NC}\n"

    # Run all checks
    check_result_backend
    check_ignore_result
    check_error_handling
    check_timeouts
    check_signatures
    check_chord_requirements
    check_anti_patterns
    check_retry_config
    check_workflow_composition

    # Summary
    echo
    echo -e "${GREEN}=== Validation Summary ===${NC}"

    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}Errors: $ERRORS${NC}"
    else
        echo -e "${GREEN}Errors: 0${NC}"
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    else
        echo -e "Warnings: 0"
    fi

    echo -e "Info: $INFO"

    # Exit code
    if [[ $ERRORS -gt 0 ]]; then
        echo
        echo -e "${RED}Validation failed${NC}"
        exit 1
    elif [[ $WARNINGS -gt 0 ]]; then
        echo
        echo -e "${YELLOW}Validation passed with warnings${NC}"
        exit 0
    else
        echo
        echo -e "${GREEN}Validation passed${NC}"
        exit 0
    fi
}

main
