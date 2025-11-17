#!/bin/bash
#
# Test Celery Workflow Execution
# Validates and executes workflow patterns with monitoring
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Globals
DRY_RUN=false
VERBOSE=false
TIMEOUT=30
WORKFLOW_NAME=""

# Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") <workflow_name> [options]

Test and execute Celery workflow patterns.

Arguments:
    workflow_name       Name of workflow function to test

Options:
    --dry-run          Validate without execution
    --verbose          Show detailed task flow
    --timeout SECONDS  Execution timeout (default: 30)
    -h, --help         Show this help message

Examples:
    # Test basic chain workflow
    $(basename "$0") basic_chain_example

    # Dry run validation
    $(basename "$0") etl_pipeline_workflow --dry-run

    # With verbose output and custom timeout
    $(basename "$0") nested_chords_workflow --verbose --timeout 60

Workflow Types:
    - Chain workflows (chain-workflow.py)
    - Group parallel (group-parallel.py)
    - Chord patterns (chord-pattern.py)
    - Complex workflows (complex-workflow.py)
    - Error handling (error-handling-workflow.py)
    - Nested workflows (nested-workflows.py)
EOF
    exit 1
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                if [[ -z "$WORKFLOW_NAME" ]]; then
                    WORKFLOW_NAME="$1"
                else
                    echo -e "${RED}Error: Unknown argument '$1'${NC}" >&2
                    usage
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$WORKFLOW_NAME" ]]; then
        echo -e "${RED}Error: workflow_name required${NC}" >&2
        usage
    fi
}

# Find workflow file
find_workflow_file() {
    local workflow_name="$1"
    local templates_dir="$(dirname "$0")/../templates"

    # Search for workflow in template files
    for file in "$templates_dir"/*.py; do
        if grep -q "def ${workflow_name}" "$file" 2>/dev/null; then
            echo "$file"
            return 0
        fi
    done

    echo -e "${RED}Error: Workflow '$workflow_name' not found in templates${NC}" >&2
    return 1
}

# Check dependencies
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"

    # Check Python
    if ! command -v python3 &>/dev/null; then
        echo -e "${RED}Error: python3 not found${NC}" >&2
        return 1
    fi

    # Check Celery
    if ! python3 -c "import celery" 2>/dev/null; then
        echo -e "${RED}Error: Celery not installed${NC}" >&2
        echo "Install: pip install celery[redis]" >&2
        return 1
    fi

    # Check Redis connection
    if ! python3 -c "import redis; r = redis.Redis(); r.ping()" 2>/dev/null; then
        echo -e "${YELLOW}Warning: Cannot connect to Redis${NC}"
        echo "Make sure Redis is running: redis-server" >&2
    fi

    echo -e "${GREEN}✓ Dependencies OK${NC}"
    return 0
}

# Validate workflow structure
validate_workflow() {
    local workflow_file="$1"
    local workflow_name="$2"

    echo -e "${BLUE}Validating workflow structure...${NC}"

    # Check if workflow uses result backend
    if ! grep -q "result_backend" "$workflow_file"; then
        echo -e "${YELLOW}Warning: No result_backend configured${NC}"
    fi

    # Check for ignored results in groups/chords
    if grep -q "group\|chord" "$workflow_file"; then
        if grep -q "ignore_result=True" "$workflow_file"; then
            echo -e "${RED}Error: Tasks in groups/chords should not ignore results${NC}" >&2
            return 1
        fi
    fi

    # Check for proper error handling
    if ! grep -q "on_error\|try:\|except" "$workflow_file"; then
        echo -e "${YELLOW}Warning: No error handling detected${NC}"
    fi

    echo -e "${GREEN}✓ Validation passed${NC}"
    return 0
}

# Execute workflow
execute_workflow() {
    local workflow_file="$1"
    local workflow_name="$2"

    echo -e "${BLUE}Executing workflow: $workflow_name${NC}"

    # Create Python script to execute workflow
    local test_script="/tmp/celery_test_$$.py"
    cat > "$test_script" <<EOF
import sys
import os
sys.path.insert(0, os.path.dirname('$workflow_file'))

# Import workflow module
module_name = os.path.splitext(os.path.basename('$workflow_file'))[0]
workflow_module = __import__(module_name)

# Get workflow function
workflow_func = getattr(workflow_module, '$workflow_name')

# Execute workflow
print(f"Starting workflow: $workflow_name")
result = workflow_func()

# Wait for result
if hasattr(result, 'get'):
    try:
        output = result.get(timeout=$TIMEOUT)
        print(f"Result: {output}")
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)
else:
    print(f"Result: {result}")
EOF

    # Execute
    if $VERBOSE; then
        python3 "$test_script"
    else
        python3 "$test_script" 2>&1 | grep -v "WARNING"
    fi

    local exit_code=$?
    rm -f "$test_script"

    return $exit_code
}

# Monitor workflow progress
monitor_workflow() {
    local workflow_name="$1"

    if ! $VERBOSE; then
        return 0
    fi

    echo -e "${BLUE}Monitoring workflow execution...${NC}"

    # Simple progress indicator
    local i=0
    while [[ $i -lt $TIMEOUT ]]; do
        echo -n "."
        sleep 1
        ((i++))
    done
    echo
}

# Main
main() {
    parse_args "$@"

    echo -e "${GREEN}=== Celery Workflow Test ===${NC}"
    echo -e "Workflow: ${BLUE}$WORKFLOW_NAME${NC}"
    echo -e "Dry run: ${BLUE}$DRY_RUN${NC}"
    echo -e "Timeout: ${BLUE}$TIMEOUT${NC}s"
    echo

    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    # Find workflow file
    workflow_file=$(find_workflow_file "$WORKFLOW_NAME")
    if [[ -z "$workflow_file" ]]; then
        exit 1
    fi

    echo -e "Found: ${GREEN}$(basename "$workflow_file")${NC}"
    echo

    # Validate
    if ! validate_workflow "$workflow_file" "$WORKFLOW_NAME"; then
        exit 1
    fi

    # Execute (unless dry run)
    if $DRY_RUN; then
        echo -e "${GREEN}✓ Dry run complete${NC}"
        exit 0
    fi

    echo
    if execute_workflow "$workflow_file" "$WORKFLOW_NAME"; then
        echo
        echo -e "${GREEN}✓ Workflow completed successfully${NC}"
        exit 0
    else
        echo
        echo -e "${RED}✗ Workflow failed${NC}" >&2
        exit 1
    fi
}

main "$@"
