#!/bin/bash
# Test Broker Connection
#
# Tests connectivity to Redis or RabbitMQ message broker.
#
# Usage:
#   bash test-broker-connection.sh
#   bash test-broker-connection.sh redis://localhost:6379/0
#   bash test-broker-connection.sh amqp://guest:guest@localhost:5672//

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get broker URL from argument or environment
BROKER_URL="${1:-${CELERY_BROKER_URL:-}}"

echo "=================================================="
echo "Celery Broker Connection Test"
echo "=================================================="
echo ""

if [ -z "$BROKER_URL" ]; then
    echo -e "${RED}Error:${NC} No broker URL specified"
    echo "Usage: $0 <broker-url>"
    echo "   or: export CELERY_BROKER_URL=<broker-url> && $0"
    exit 1
fi

# Parse broker type from URL
if [[ "$BROKER_URL" =~ ^redis ]]; then
    BROKER_TYPE="redis"
elif [[ "$BROKER_URL" =~ ^amqp ]]; then
    BROKER_TYPE="rabbitmq"
else
    echo -e "${RED}Error:${NC} Unsupported broker URL: $BROKER_URL"
    exit 1
fi

echo "Broker URL: ${BROKER_URL%%@*}@..."
echo "Broker Type: $BROKER_TYPE"
echo ""

# Test connection with Python
python3 << EOF
import sys

try:
    from celery import Celery

    # Create temporary app
    app = Celery(broker='$BROKER_URL')

    print("Testing connection...")

    # Test connection
    conn = app.connection()
    conn.ensure_connection(max_retries=3, timeout=5)

    print("✓ Broker connection successful")
    print("")

    # Get connection info
    try:
        inspect = app.control.inspect()
        print("Broker is reachable and responsive")
    except:
        print("⚠ Broker reachable but no workers active")

    sys.exit(0)

except ImportError:
    print("✗ ERROR: Celery not installed")
    print("  Install with: pip install celery[${BROKER_TYPE}]")
    sys.exit(1)

except Exception as e:
    print(f"✗ ERROR: Connection failed: {e}")
    print("")
    print("Troubleshooting:")

    if "$BROKER_TYPE" == "redis":
        print("  - Ensure Redis is running: redis-cli ping")
        print("  - Check connection: redis-cli -h localhost -p 6379")
    else:
        print("  - Ensure RabbitMQ is running: rabbitmqctl status")
        print("  - Check connection: rabbitmqctl list_connections")

    sys.exit(1)
EOF

exit $?
