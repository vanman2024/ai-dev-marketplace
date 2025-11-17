#!/bin/bash
# Generate Celery Configuration
#
# Generates framework-specific Celery configuration files based on detected
# or specified framework and broker choice.
#
# Usage:
#   bash generate-config.sh --framework=django --broker=redis
#   bash generate-config.sh --framework=flask --broker=rabbitmq --output=custom.py

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
FRAMEWORK=""
BROKER=""
OUTPUT_PATH=""
WITH_BEAT=false
WITH_MONITORING=false

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SKILL_DIR/templates"

echo "=================================================="
echo "Celery Configuration Generator"
echo "=================================================="
echo ""

# ============================================================================
# Parse Arguments
# ============================================================================

for arg in "$@"; do
    case $arg in
        --framework=*)
            FRAMEWORK="${arg#*=}"
            shift
            ;;
        --broker=*)
            BROKER="${arg#*=}"
            shift
            ;;
        --output=*)
            OUTPUT_PATH="${arg#*=}"
            shift
            ;;
        --with-beat)
            WITH_BEAT=true
            shift
            ;;
        --with-monitoring)
            WITH_MONITORING=true
            shift
            ;;
        --help)
            echo "Usage: $0 --framework=<framework> --broker=<broker> [options]"
            echo ""
            echo "Required:"
            echo "  --framework=FRAMEWORK    Framework: django, flask, fastapi, standalone"
            echo "  --broker=BROKER          Broker: redis, rabbitmq"
            echo ""
            echo "Optional:"
            echo "  --output=PATH            Custom output file path"
            echo "  --with-beat              Include Celery Beat configuration"
            echo "  --with-monitoring        Include monitoring configuration"
            echo "  --help                   Show this help message"
            echo ""
            exit 0
            ;;
    esac
done

# Validate required arguments
if [ -z "$FRAMEWORK" ]; then
    echo "Error: --framework is required"
    echo "Run with --help for usage"
    exit 1
fi

if [ -z "$BROKER" ]; then
    echo "Error: --broker is required"
    echo "Run with --help for usage"
    exit 1
fi

# Validate framework
case $FRAMEWORK in
    django|flask|fastapi|standalone)
        ;;
    *)
        echo "Error: Invalid framework '$FRAMEWORK'"
        echo "Valid options: django, flask, fastapi, standalone"
        exit 1
        ;;
esac

# Validate broker
case $BROKER in
    redis|rabbitmq)
        ;;
    *)
        echo "Error: Invalid broker '$BROKER'"
        echo "Valid options: redis, rabbitmq"
        exit 1
        ;;
esac

echo "Configuration:"
echo "  Framework: $FRAMEWORK"
echo "  Broker: $BROKER"
echo ""

# ============================================================================
# Generate Configuration Files
# ============================================================================

# Copy framework-specific template
FRAMEWORK_TEMPLATE="$TEMPLATES_DIR/celery-app-${FRAMEWORK}.py"
if [ ! -f "$FRAMEWORK_TEMPLATE" ]; then
    echo "Error: Template not found: $FRAMEWORK_TEMPLATE"
    exit 1
fi

# Determine output path
if [ -z "$OUTPUT_PATH" ]; then
    case $FRAMEWORK in
        django)
            OUTPUT_PATH="myproject/celery.py"
            ;;
        flask)
            OUTPUT_PATH="celery_app.py"
            ;;
        fastapi)
            OUTPUT_PATH="celery_app.py"
            ;;
        standalone)
            OUTPUT_PATH="celery_app.py"
            ;;
    esac
fi

echo "Generating files..."
echo ""

# Copy framework template
mkdir -p "$(dirname "$OUTPUT_PATH")"
cp "$FRAMEWORK_TEMPLATE" "$OUTPUT_PATH"
echo -e "${GREEN}✓${NC} Created: $OUTPUT_PATH"

# Generate .env.example
ENV_EXAMPLE=".env.example"
cat > "$ENV_EXAMPLE" << EOF
# Celery Configuration
# Copy this file to .env and fill in actual values

EOF

case $BROKER in
    redis)
        cat >> "$ENV_EXAMPLE" << 'EOF'
# Redis Broker Configuration
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# For authenticated Redis:
# REDIS_PASSWORD=your_redis_password_here
# CELERY_BROKER_URL=redis://:${REDIS_PASSWORD}@localhost:6379/0
# CELERY_RESULT_BACKEND=redis://:${REDIS_PASSWORD}@localhost:6379/0
EOF
        ;;
    rabbitmq)
        cat >> "$ENV_EXAMPLE" << 'EOF'
# RabbitMQ Broker Configuration
CELERY_BROKER_URL=amqp://guest:guest@localhost:5672//
CELERY_RESULT_BACKEND=rpc://

# For production:
# RABBITMQ_USER=your_rabbitmq_user
# RABBITMQ_PASSWORD=your_rabbitmq_password_here
# CELERY_BROKER_URL=amqp://${RABBITMQ_USER}:${RABBITMQ_PASSWORD}@localhost:5672//
EOF
        ;;
esac

echo -e "${GREEN}✓${NC} Created: $ENV_EXAMPLE"

# Create .gitignore entry
if [ ! -f .gitignore ]; then
    echo ".env" > .gitignore
    echo -e "${GREEN}✓${NC} Created: .gitignore"
else
    if ! grep -q "^\.env$" .gitignore; then
        echo ".env" >> .gitignore
        echo -e "${GREEN}✓${NC} Updated: .gitignore"
    fi
fi

# Generate tasks.py template
if [ ! -f "tasks.py" ]; then
    cat > tasks.py << 'EOF'
"""
Celery Tasks

Define your tasks here using the @shared_task decorator.
"""

from celery import shared_task
import time
import logging

logger = logging.getLogger(__name__)


@shared_task
def example_task(name):
    """Example task that logs a message"""
    logger.info(f"Running example task for: {name}")
    time.sleep(2)  # Simulate work
    return f"Task completed for {name}"


@shared_task(bind=True, max_retries=3)
def example_task_with_retry(self, data):
    """Example task with retry logic"""
    try:
        # Your task logic here
        logger.info(f"Processing: {data}")
        return {"status": "success", "data": data}
    except Exception as exc:
        logger.error(f"Task failed: {exc}")
        raise self.retry(exc=exc, countdown=60)
EOF
    echo -e "${GREEN}✓${NC} Created: tasks.py"
fi

# Generate Beat schedule if requested
if [ "$WITH_BEAT" = true ]; then
    BEAT_TEMPLATE="$TEMPLATES_DIR/beat-schedule.py"
    if [ -f "$BEAT_TEMPLATE" ]; then
        cp "$BEAT_TEMPLATE" "celerybeat_schedule.py"
        echo -e "${GREEN}✓${NC} Created: celerybeat_schedule.py"
    fi
fi

echo ""

# ============================================================================
# Generate Setup Documentation
# ============================================================================

SETUP_DOC="CELERY_SETUP.md"
cat > "$SETUP_DOC" << EOF
# Celery Setup Instructions

Generated for: **$FRAMEWORK** with **$BROKER** broker

## Prerequisites

- Python 3.8+
- ${BROKER^} server running
EOF

case $BROKER in
    redis)
        cat >> "$SETUP_DOC" << 'EOF'
- Redis: `redis-server` or Docker: `docker run -d -p 6379:6379 redis:7-alpine`
EOF
        ;;
    rabbitmq)
        cat >> "$SETUP_DOC" << 'EOF'
- RabbitMQ: `rabbitmq-server` or Docker: `docker run -d -p 5672:5672 rabbitmq:3-alpine`
EOF
        ;;
esac

cat >> "$SETUP_DOC" << EOF

## Installation

\`\`\`bash
# Install Celery with ${BROKER} support
pip install celery[${BROKER}]

# Update requirements
pip freeze > requirements.txt
\`\`\`

## Configuration

1. Copy environment template:
\`\`\`bash
cp .env.example .env
\`\`\`

2. Edit .env and fill in actual values (NEVER commit .env!)

3. Files generated:
   - \`$OUTPUT_PATH\` - Celery application
   - \`tasks.py\` - Task definitions
   - \`.env.example\` - Environment template
EOF

if [ "$WITH_BEAT" = true ]; then
    cat >> "$SETUP_DOC" << 'EOF'
   - `celerybeat_schedule.py` - Periodic task schedule
EOF
fi

cat >> "$SETUP_DOC" << 'EOF'

## Running Celery

```bash
# Start worker
celery -A myapp worker --loglevel=info

# Start Beat (for periodic tasks)
celery -A myapp beat --loglevel=info

# Monitor with Flower
pip install flower
celery -A myapp flower
```

## Testing

```python
# Test task execution
from tasks import example_task

result = example_task.delay("test")
print(f"Task ID: {result.id}")
print(f"Result: {result.get(timeout=10)}")
```

## Next Steps

1. Define your tasks in `tasks.py`
2. Use tasks in your application code
3. Start Celery worker and Beat
4. Monitor with Flower dashboard
5. Deploy to production

For detailed setup, see:
EOF

case $FRAMEWORK in
    django)
        echo "  examples/django-setup.md" >> "$SETUP_DOC"
        ;;
    flask)
        echo "  examples/flask-setup.md" >> "$SETUP_DOC"
        ;;
    fastapi)
        echo "  examples/fastapi-setup.md" >> "$SETUP_DOC"
        ;;
    standalone)
        echo "  examples/standalone-setup.md" >> "$SETUP_DOC"
        ;;
esac

echo -e "${GREEN}✓${NC} Created: $SETUP_DOC"
echo ""

# ============================================================================
# Summary
# ============================================================================

echo "=================================================="
echo "Setup Complete!"
echo "=================================================="
echo ""
echo "Generated files:"
echo "  - $OUTPUT_PATH"
echo "  - tasks.py"
echo "  - .env.example"
echo "  - $SETUP_DOC"
if [ "$WITH_BEAT" = true ]; then
    echo "  - celerybeat_schedule.py"
fi
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env and configure"
echo "  2. Start ${BROKER} server"
echo "  3. Start Celery: celery -A <app> worker --loglevel=info"
echo "  4. Read $SETUP_DOC for detailed instructions"
echo ""

exit 0
