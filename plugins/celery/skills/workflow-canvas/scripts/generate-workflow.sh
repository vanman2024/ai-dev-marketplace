#!/bin/bash
#
# Generate Celery Workflow from Template
# Create workflow files from predefined patterns
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") <workflow_type> <output_file> [options]

Generate Celery workflow from template patterns.

Arguments:
    workflow_type    Type of workflow (chain, group, chord, complex, error-handling, nested)
    output_file      Path to output Python file

Options:
    --app-name NAME  Celery app name (default: 'app')
    --broker URL     Broker URL (default: redis://localhost:6379/0)
    --backend URL    Result backend URL (default: redis://localhost:6379/0)
    -h, --help       Show this help message

Workflow Types:
    chain            - Sequential task execution
    group            - Parallel task execution
    chord            - Parallel with callback
    complex          - Multi-stage pipeline
    error-handling   - Comprehensive error patterns
    nested           - Nested workflow composition

Examples:
    # Generate basic chain workflow
    $(basename "$0") chain my_workflow.py

    # Generate chord with custom app name
    $(basename "$0") chord data_pipeline.py --app-name data_app

    # Generate complex workflow with custom broker
    $(basename "$0") complex etl_pipeline.py --broker redis://prod:6379/0
EOF
    exit 1
}

# Defaults
APP_NAME="app"
BROKER_URL="redis://localhost:6379/0"
BACKEND_URL="redis://localhost:6379/0"
WORKFLOW_TYPE=""
OUTPUT_FILE=""

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --app-name)
                APP_NAME="$2"
                shift 2
                ;;
            --broker)
                BROKER_URL="$2"
                shift 2
                ;;
            --backend)
                BACKEND_URL="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                if [[ -z "$WORKFLOW_TYPE" ]]; then
                    WORKFLOW_TYPE="$1"
                elif [[ -z "$OUTPUT_FILE" ]]; then
                    OUTPUT_FILE="$1"
                else
                    echo -e "${RED}Error: Unknown argument '$1'${NC}" >&2
                    usage
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$WORKFLOW_TYPE" ]] || [[ -z "$OUTPUT_FILE" ]]; then
        echo -e "${RED}Error: workflow_type and output_file required${NC}" >&2
        usage
    fi
}

# Get template directory
get_template_dir() {
    local script_dir="$(dirname "$0")"
    echo "$script_dir/../templates"
}

# Find template file
find_template() {
    local workflow_type="$1"
    local template_dir="$(get_template_dir)"

    case "$workflow_type" in
        chain)
            echo "$template_dir/chain-workflow.py"
            ;;
        group)
            echo "$template_dir/group-parallel.py"
            ;;
        chord)
            echo "$template_dir/chord-pattern.py"
            ;;
        complex)
            echo "$template_dir/complex-workflow.py"
            ;;
        error-handling)
            echo "$template_dir/error-handling-workflow.py"
            ;;
        nested)
            echo "$template_dir/nested-workflows.py"
            ;;
        *)
            echo -e "${RED}Error: Unknown workflow type '$workflow_type'${NC}" >&2
            echo "Valid types: chain, group, chord, complex, error-handling, nested" >&2
            return 1
            ;;
    esac
}

# Generate workflow
generate_workflow() {
    local template_file="$1"
    local output_file="$2"

    echo -e "${BLUE}Generating workflow...${NC}"
    echo -e "Template: ${GREEN}$(basename "$template_file")${NC}"
    echo -e "Output: ${GREEN}$output_file${NC}"

    # Check if template exists
    if [[ ! -f "$template_file" ]]; then
        echo -e "${RED}Error: Template not found: $template_file${NC}" >&2
        return 1
    fi

    # Check if output already exists
    if [[ -f "$output_file" ]]; then
        echo -e "${YELLOW}Warning: Output file exists, will be overwritten${NC}"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled"
            return 1
        fi
    fi

    # Copy template and customize
    cp "$template_file" "$output_file"

    # Replace placeholders
    sed -i "s/'[a-z_]*workflows'/'${APP_NAME}'/g" "$output_file"
    sed -i "s|'broker_url': 'redis://localhost:6379/0'|'broker_url': '${BROKER_URL}'|g" "$output_file"
    sed -i "s|'result_backend': 'redis://localhost:6379/0'|'result_backend': '${BACKEND_URL}'|g" "$output_file"

    echo -e "${GREEN}✓ Workflow generated successfully${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Review and customize tasks in: $output_file"
    echo "2. Test workflow: bash $(dirname "$0")/test-workflow.sh <workflow_function_name>"
    echo "3. Validate: bash $(dirname "$0")/validate-canvas.sh $output_file"
}

# Show workflow info
show_workflow_info() {
    local workflow_type="$1"

    echo -e "\n${BLUE}Workflow Type: $workflow_type${NC}"
    echo

    case "$workflow_type" in
        chain)
            cat <<EOF
Sequential task execution where each task's output feeds into the next.

Use cases:
- Data processing pipelines (fetch → transform → load)
- User onboarding flows (create account → setup → notify)
- Document processing (upload → extract → analyze → store)

Example tasks:
- fetch_data.s(url)
- transform_data.s()
- save_data.s()
EOF
            ;;
        group)
            cat <<EOF
Parallel task execution for independent operations.

Use cases:
- Bulk email campaigns
- Image batch processing
- Multiple API calls
- Database bulk operations

Example tasks:
- process_item.s(item) for item in items
EOF
            ;;
        chord)
            cat <<EOF
Parallel execution with callback for result aggregation.

Use cases:
- MapReduce patterns
- Report generation from multiple sources
- Distributed computation
- Batch processing with notification

Example structure:
chord(
    parallel_tasks
)(callback_task.s())
EOF
            ;;
        complex)
            cat <<EOF
Multi-stage pipeline combining chains, groups, and chords.

Use cases:
- ETL pipelines with multiple sources
- Hierarchical data processing
- Multi-tenant processing
- A/B testing workflows

Features:
- Multiple processing phases
- Conditional branching
- Error recovery
- Progress tracking
EOF
            ;;
        error-handling)
            cat <<EOF
Comprehensive error handling patterns.

Features:
- Error callbacks (.on_error)
- Try-catch in tasks
- Retry with exponential backoff
- Timeout handling
- Dead letter queues
- Circuit breaker pattern

Use when:
- Critical workflows need resilience
- External API calls may fail
- Need graceful degradation
EOF
            ;;
        nested)
            cat <<EOF
Advanced workflow composition and nesting.

Patterns:
- Chain of chords
- Groups within chains
- Nested chords
- Dynamic workflow generation
- Recursive processing

Use for:
- Complex hierarchical processing
- Conditional workflow paths
- Multi-level aggregation
EOF
            ;;
    esac
}

# Main
main() {
    parse_args "$@"

    echo -e "${GREEN}=== Celery Workflow Generator ===${NC}\n"

    # Find template
    template_file=$(find_template "$WORKFLOW_TYPE")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    # Show workflow info
    show_workflow_info "$WORKFLOW_TYPE"

    echo
    read -p "Generate workflow? (Y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Cancelled"
        exit 0
    fi

    # Generate
    if generate_workflow "$template_file" "$OUTPUT_FILE"; then
        echo
        echo -e "${GREEN}✓ Generation complete${NC}"
        exit 0
    else
        echo
        echo -e "${RED}✗ Generation failed${NC}" >&2
        exit 1
    fi
}

main "$@"
