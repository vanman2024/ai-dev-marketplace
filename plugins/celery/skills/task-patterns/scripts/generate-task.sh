#!/bin/bash
# Generate Celery Task from Template
#
# Usage: ./generate-task.sh <template_name> <output_file> [options]
#
# Generates a new Celery task file from a template with customizations

set -euo pipefail

TEMPLATE_NAME="${1:-}"
OUTPUT_FILE="${2:-}"
TASK_NAME="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SKILL_DIR/templates"

# Available templates
TEMPLATES=(
    "basic-task"
    "retry-task"
    "rate-limited-task"
    "time-limited-task"
    "custom-task-class"
    "pydantic-validation"
    "database-task"
    "api-task"
)

show_usage() {
    echo "Usage: $0 <template_name> <output_file> [task_name]"
    echo ""
    echo "Available templates:"
    for template in "${TEMPLATES[@]}"; do
        echo "  - $template"
    done
    echo ""
    echo "Examples:"
    echo "  $0 basic-task tasks/my_task.py my_task"
    echo "  $0 retry-task tasks/api_call.py fetch_api"
    echo "  $0 rate-limited-task tasks/batch.py process_batch"
    exit 1
}

if [[ -z "$TEMPLATE_NAME" ]] || [[ -z "$OUTPUT_FILE" ]]; then
    show_usage
fi

# Check if template exists
TEMPLATE_FILE="$TEMPLATES_DIR/${TEMPLATE_NAME}.py"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "❌ Error: Template not found: $TEMPLATE_FILE"
    echo ""
    echo "Available templates:"
    for template in "${TEMPLATES[@]}"; do
        echo "  - $template"
    done
    exit 1
fi

echo "🎨 Generating Celery task from template: $TEMPLATE_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create output directory if needed
OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
if [[ ! -d "$OUTPUT_DIR" ]]; then
    mkdir -p "$OUTPUT_DIR"
    echo "📁 Created directory: $OUTPUT_DIR"
fi

# Copy template
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"
echo "✅ Copied template to: $OUTPUT_FILE"

# Customize task name if provided
if [[ -n "$TASK_NAME" ]]; then
    echo ""
    echo "🔧 Customizing task name to: $TASK_NAME"

    # Get original task names from template
    ORIGINAL_TASKS=$(grep -E "^def [a-z_]+\(" "$TEMPLATE_FILE" | sed 's/def \([a-z_]*\)(.*/\1/' || echo "")

    if [[ -n "$ORIGINAL_TASKS" ]]; then
        FIRST_TASK=$(echo "$ORIGINAL_TASKS" | head -1)
        echo "  Replacing '$FIRST_TASK' with '$TASK_NAME'"

        # Replace in file (macOS compatible)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/def $FIRST_TASK(/def $TASK_NAME(/g" "$OUTPUT_FILE"
            sed -i '' "s/$FIRST_TASK\.delay/$TASK_NAME.delay/g" "$OUTPUT_FILE"
            sed -i '' "s/$FIRST_TASK\.apply_async/$TASK_NAME.apply_async/g" "$OUTPUT_FILE"
        else
            sed -i "s/def $FIRST_TASK(/def $TASK_NAME(/g" "$OUTPUT_FILE"
            sed -i "s/$FIRST_TASK\.delay/$TASK_NAME.delay/g" "$OUTPUT_FILE"
            sed -i "s/$FIRST_TASK\.apply_async/$TASK_NAME.apply_async/g" "$OUTPUT_FILE"
        fi
    fi
fi

# Provide next steps
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Task generated successfully!"
echo ""
echo "📝 Generated file: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  1. Customize the task logic in: $OUTPUT_FILE"
echo "  2. Update broker configuration (Redis/RabbitMQ URL)"
echo "  3. Update API keys/credentials to use environment variables"
echo "  4. Validate task: ./scripts/validate-task.sh $OUTPUT_FILE"
echo "  5. Test task: ./scripts/test-task.sh $OUTPUT_FILE"
echo ""

# Show template info
case "$TEMPLATE_NAME" in
    "basic-task")
        echo "Template: Basic Task"
        echo "  - Simple task structure"
        echo "  - Standard error handling"
        echo "  - Synchronous and async execution"
        ;;
    "retry-task")
        echo "Template: Retry Task"
        echo "  - Automatic retry with backoff"
        echo "  - Manual retry control"
        echo "  - Fixed and exponential delays"
        echo "  - Configure: autoretry_for, max_retries"
        ;;
    "rate-limited-task")
        echo "Template: Rate Limited Task"
        echo "  - Respects API rate limits"
        echo "  - Per-second/minute/hour limits"
        echo "  - Batch processing with rate control"
        echo "  - Configure: rate_limit parameter"
        ;;
    "time-limited-task")
        echo "Template: Time Limited Task"
        echo "  - Soft and hard time limits"
        echo "  - Graceful timeout handling"
        echo "  - Progress saving on timeout"
        echo "  - Configure: soft_time_limit, time_limit"
        ;;
    "custom-task-class")
        echo "Template: Custom Task Class"
        echo "  - Connection pooling"
        echo "  - Result caching"
        echo "  - Metrics tracking"
        echo "  - Lifecycle hooks"
        echo "  - Customize: Task class methods"
        ;;
    "pydantic-validation")
        echo "Template: Pydantic Validation"
        echo "  - Type-safe input validation"
        echo "  - Pydantic models"
        echo "  - Custom validators"
        echo "  - Structured error messages"
        echo "  - Customize: Pydantic models"
        ;;
    "database-task")
        echo "Template: Database Task"
        echo "  - Connection pooling"
        echo "  - Parameterized queries"
        echo "  - Transaction support"
        echo "  - Bulk operations"
        echo "  - Customize: Database connection"
        ;;
    "api-task")
        echo "Template: API Task"
        echo "  - External API calls"
        echo "  - Automatic retry on errors"
        echo "  - Authentication patterns"
        echo "  - Pagination support"
        echo "  - Customize: API endpoints, auth"
        ;;
esac

echo ""
echo "📚 Documentation:"
echo "  - Task patterns: $SKILL_DIR/SKILL.md"
echo "  - Examples: $SKILL_DIR/examples/"
echo ""
echo "🚀 Run task:"
echo "  celery -A $(basename "$(dirname "$OUTPUT_FILE")") worker --loglevel=info"
