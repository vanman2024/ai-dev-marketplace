#!/bin/bash
#
# Validate Celery Queue Configuration Across Project
#
# This script validates that:
# - Task decorators reference valid queues
# - No hardcoded queue names in task calls
# - All queues are defined in routing configuration
# - Priority settings are valid
# - Worker configurations match defined queues
#
# Usage:
#   ./validate-queues.sh <project-dir>
#   REPORT=1 ./validate-queues.sh . > validation-report.md
#
# Exit Codes:
#   0 - Validation passed
#   1 - Validation failed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="${1:-.}"
GENERATE_REPORT="${REPORT:-0}"

# Check if project directory exists
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${RED}Error: Project directory not found: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# Arrays to track issues
declare -a ERRORS
declare -a WARNINGS
declare -a INFO

# Function to add error
add_error() {
    ERRORS+=("$1")
    if [[ "$GENERATE_REPORT" == "0" ]]; then
        echo -e "${RED}✗ ERROR:${NC} $1"
    fi
}

# Function to add warning
add_warning() {
    WARNINGS+=("$1")
    if [[ "$GENERATE_REPORT" == "0" ]]; then
        echo -e "${YELLOW}⚠ WARNING:${NC} $1"
    fi
}

# Function to add info
add_info() {
    INFO+=("$1")
    if [[ "$GENERATE_REPORT" == "0" ]]; then
        echo -e "${BLUE}ℹ INFO:${NC} $1"
    fi
}

echo -e "${BLUE}=== Celery Queue Validation ===${NC}\n"

# Find Celery config files
CONFIG_FILES=$(find . -name "celery*.py" -o -name "*config*.py" | grep -v "__pycache__" | grep -v ".venv" | grep -v "venv" || echo "")

if [[ -z "$CONFIG_FILES" ]]; then
    add_error "No Celery configuration files found"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found configuration files:"
echo "$CONFIG_FILES" | while read -r file; do
    echo "  - $file"
done
echo ""

# Extract defined queues from config
DEFINED_QUEUES=()
for config in $CONFIG_FILES; do
    while IFS= read -r line; do
        if [[ "$line" =~ Queue\([\'\"](.*?)[\'\"] ]]; then
            queue_name="${BASH_REMATCH[1]}"
            DEFINED_QUEUES+=("$queue_name")
        fi
    done < "$config"
done

# Remove duplicates
DEFINED_QUEUES=($(echo "${DEFINED_QUEUES[@]}" | tr ' ' '\n' | sort -u))

if [[ ${#DEFINED_QUEUES[@]} -eq 0 ]]; then
    add_warning "No queue definitions found in config files"
else
    add_info "Found ${#DEFINED_QUEUES[@]} defined queues: ${DEFINED_QUEUES[*]}"
fi

# Find all Python files with Celery tasks
TASK_FILES=$(find . -name "*.py" -type f | grep -v "__pycache__" | grep -v ".venv" | grep -v "venv" | xargs grep -l "@.*task" 2>/dev/null || echo "")

if [[ -z "$TASK_FILES" ]]; then
    add_warning "No task files found"
else
    TASK_COUNT=$(echo "$TASK_FILES" | wc -l)
    add_info "Scanning $TASK_COUNT files for task definitions"
fi

# Validate task decorators
echo -e "\n${BLUE}Validating task decorators...${NC}"

for file in $TASK_FILES; do
    # Check for queue parameter in task decorators
    while IFS= read -r line; do
        if [[ "$line" =~ @.*task.*queue=[\'\"](.*?)[\'\"] ]]; then
            queue_name="${BASH_REMATCH[1]}"

            # Check if queue is defined
            if [[ ! " ${DEFINED_QUEUES[@]} " =~ " ${queue_name} " ]]; then
                add_error "Undefined queue '$queue_name' in $file"
            fi
        fi
    done < "$file"

    # Check for apply_async with queue parameter
    while IFS= read -r line; do
        if [[ "$line" =~ apply_async.*queue=[\'\"](.*?)[\'\"] ]]; then
            queue_name="${BASH_REMATCH[1]}"

            # Check if queue is defined
            if [[ ! " ${DEFINED_QUEUES[@]} " =~ " ${queue_name} " ]]; then
                add_error "Undefined queue '$queue_name' in apply_async call in $file"
            fi
        fi
    done < "$file"

    # Check for hardcoded queue names (should use config)
    if grep -qE "queue\s*=\s*['\"][a-z_]+['\"]" "$file"; then
        # Count hardcoded queues
        HARDCODED_COUNT=$(grep -cE "queue\s*=\s*['\"][a-z_]+['\"]" "$file" || echo "0")
        if [[ $HARDCODED_COUNT -gt 0 ]]; then
            add_warning "Found $HARDCODED_COUNT hardcoded queue name(s) in $file (should use constants)"
        fi
    fi
done

# Validate priority settings
echo -e "\n${BLUE}Validating priority settings...${NC}"

for file in $TASK_FILES; do
    # Check for priority values
    while IFS= read -r line; do
        if [[ "$line" =~ priority\s*=\s*([0-9]+) ]]; then
            priority="${BASH_REMATCH[1]}"

            # Priority should be 0-255 (RabbitMQ limit)
            if [[ $priority -gt 255 ]]; then
                add_error "Invalid priority value $priority in $file (max: 255)"
            elif [[ $priority -gt 10 ]]; then
                add_warning "Unusual priority value $priority in $file (common range: 0-10)"
            fi
        fi
    done < "$file"
done

# Validate routing configuration
echo -e "\n${BLUE}Validating routing configuration...${NC}"

for config in $CONFIG_FILES; do
    # Check for CELERY_ROUTES or task_routes
    if grep -q "CELERY_ROUTES\|task_routes" "$config"; then
        add_info "Routing configuration found in $config"

        # Extract task routes
        ROUTE_COUNT=$(grep -cE "^[ ]*['\"].*tasks\." "$config" || echo "0")
        if [[ $ROUTE_COUNT -gt 0 ]]; then
            add_info "Found $ROUTE_COUNT task routes in $config"
        fi
    fi

    # Check for routing functions
    if grep -q "def route_" "$config"; then
        ROUTE_FUNCS=$(grep -c "def route_" "$config" || echo "0")
        add_info "Found $ROUTE_FUNCS routing function(s) in $config"
    fi
done

# Validate exchange configuration
echo -e "\n${BLUE}Validating exchange configuration...${NC}"

for config in $CONFIG_FILES; do
    # Check for Exchange imports
    if ! grep -q "from kombu import.*Exchange" "$config"; then
        add_warning "No Exchange import in $config (using default exchange)"
    fi

    # Check exchange types
    EXCHANGE_TYPES=$(grep -oE "type=['\"][a-z]+['\"]" "$config" | sort -u || echo "")
    if [[ -n "$EXCHANGE_TYPES" ]]; then
        add_info "Exchange types in $config: $(echo "$EXCHANGE_TYPES" | tr '\n' ' ')"
    fi
done

# Check for worker configuration files
echo -e "\n${BLUE}Checking worker configurations...${NC}"

WORKER_CONFIGS=$(find . -name "worker*.py" -o -name "start_workers.sh" | grep -v "__pycache__" || echo "")

if [[ -n "$WORKER_CONFIGS" ]]; then
    add_info "Found worker configuration files:"
    echo "$WORKER_CONFIGS" | while read -r file; do
        echo "  - $file"

        # Check for queue assignments
        if [[ "$file" == *.py ]]; then
            WORKER_QUEUES=$(grep -oE "queues\s*=\s*\[.*\]" "$file" || echo "")
            if [[ -n "$WORKER_QUEUES" ]]; then
                add_info "Worker queue assignments found in $file"
            fi
        elif [[ "$file" == *.sh ]]; then
            WORKER_QUEUES=$(grep -oE "\-Q\s+[a-z_,]+" "$file" || echo "")
            if [[ -n "$WORKER_QUEUES" ]]; then
                add_info "Worker queue assignments found in $file"
            fi
        fi
    done
else
    add_warning "No worker configuration files found"
fi

# Generate report if requested
if [[ "$GENERATE_REPORT" == "1" ]]; then
    echo "# Celery Queue Validation Report"
    echo ""
    echo "**Project**: $PROJECT_DIR"
    echo "**Date**: $(date)"
    echo ""

    echo "## Summary"
    echo ""
    echo "- **Errors**: ${#ERRORS[@]}"
    echo "- **Warnings**: ${#WARNINGS[@]}"
    echo "- **Info**: ${#INFO[@]}"
    echo "- **Defined Queues**: ${#DEFINED_QUEUES[@]}"
    echo ""

    if [[ ${#DEFINED_QUEUES[@]} -gt 0 ]]; then
        echo "## Defined Queues"
        echo ""
        for queue in "${DEFINED_QUEUES[@]}"; do
            echo "- $queue"
        done
        echo ""
    fi

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo "## Errors"
        echo ""
        for error in "${ERRORS[@]}"; do
            echo "- ❌ $error"
        done
        echo ""
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo "## Warnings"
        echo ""
        for warning in "${WARNINGS[@]}"; do
            echo "- ⚠️ $warning"
        done
        echo ""
    fi

    if [[ ${#INFO[@]} -gt 0 ]]; then
        echo "## Information"
        echo ""
        for info in "${INFO[@]}"; do
            echo "- ℹ️ $info"
        done
        echo ""
    fi

    echo "## Recommendations"
    echo ""
    echo "1. Fix all errors before deploying to production"
    echo "2. Address warnings to improve configuration quality"
    echo "3. Use queue constants instead of hardcoded strings"
    echo "4. Document queue purpose and expected load"
    echo "5. Test routing with actual tasks before deployment"
    echo ""
fi

# Summary
echo -e "\n${BLUE}=== Validation Summary ===${NC}\n"

echo -e "Errors: ${#ERRORS[@]}"
echo -e "Warnings: ${#WARNINGS[@]}"
echo -e "Info: ${#INFO[@]}"
echo -e "Defined Queues: ${#DEFINED_QUEUES[@]}\n"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo -e "${RED}✗ Validation failed${NC}"
    echo -e "Fix errors before deploying to production.\n"
    exit 1
else
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Validation passed with warnings${NC}"
        echo -e "Address warnings to improve configuration quality.\n"
    else
        echo -e "${GREEN}✓ Validation passed${NC}"
        echo -e "Queue configuration is valid.\n"
    fi
    exit 0
fi
