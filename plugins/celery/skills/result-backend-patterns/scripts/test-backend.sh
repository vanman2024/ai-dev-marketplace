#!/bin/bash
#
# Test Celery Result Backend Connection and Functionality
# ========================================================
#
# Usage: ./test-backend.sh <backend-type>
#
# Backend types: redis, postgresql, mysql, sqlite, rpc
#
# This script verifies:
# - Backend service is reachable
# - Connection parameters are correct
# - Result storage and retrieval works
# - Serialization functions properly
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if backend type provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <backend-type>"
    echo ""
    echo "Backend types:"
    echo "  redis       - Redis backend"
    echo "  postgresql  - PostgreSQL database backend"
    echo "  mysql       - MySQL database backend"
    echo "  sqlite      - SQLite database backend"
    echo "  rpc         - RPC (AMQP) backend"
    exit 1
fi

BACKEND_TYPE="$1"

print_info "Testing $BACKEND_TYPE result backend..."
echo ""

# Create test script
TEST_SCRIPT=$(mktemp /tmp/celery_backend_test_XXXXXX.py)

case "$BACKEND_TYPE" in
    redis)
        print_info "Testing Redis backend connection..."

        cat > "$TEST_SCRIPT" <<'EOF'
import os
import sys
from celery import Celery

# Load from environment
redis_host = os.getenv('REDIS_HOST', 'localhost')
redis_port = os.getenv('REDIS_PORT', '6379')
redis_password = os.getenv('REDIS_PASSWORD', '')
redis_db = os.getenv('REDIS_DB', '0')

# Build connection string
if redis_password:
    result_backend = f'redis://:{redis_password}@{redis_host}:{redis_port}/{redis_db}'
else:
    result_backend = f'redis://{redis_host}:{redis_port}/{redis_db}'

print(f"Testing connection to: redis://{redis_host}:{redis_port}/{redis_db}")

# Test connection
try:
    app = Celery('test', backend=result_backend)
    backend = app.backend

    # Try to connect
    backend.client.ping()
    print("✓ Redis connection successful")

    # Test result storage
    test_task_id = 'test-backend-verification-task'
    test_result = {'status': 'success', 'message': 'Backend test passed'}

    backend.store_result(test_task_id, test_result, 'SUCCESS')
    print("✓ Result storage successful")

    # Test result retrieval
    retrieved = backend.get_result(test_task_id)
    print(f"✓ Result retrieval successful: {retrieved}")

    # Cleanup
    backend.forget(test_task_id)
    print("✓ Result cleanup successful")

    print("\n✓ All Redis backend tests passed!")
    sys.exit(0)

except Exception as e:
    print(f"✗ Redis backend test failed: {e}")
    sys.exit(1)
EOF
        ;;

    postgresql|mysql)
        print_info "Testing database backend connection..."

        cat > "$TEST_SCRIPT" <<'EOF'
import os
import sys
from celery import Celery

# Load from environment
db_type = os.getenv('DB_TYPE', 'postgresql')
db_user = os.getenv('DB_USER', 'celery')
db_password = os.getenv('DB_PASSWORD', '')
db_host = os.getenv('DB_HOST', 'localhost')
db_port = os.getenv('DB_PORT', '5432')
db_name = os.getenv('DB_NAME', 'celery_results')

# Build connection string
result_backend = f'db+{db_type}://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'

print(f"Testing connection to: db+{db_type}://{db_user}:***@{db_host}:{db_port}/{db_name}")

# Test connection
try:
    app = Celery('test', backend=result_backend)
    backend = app.backend

    # Try to query database
    from celery.backends.database import SessionManager
    session = SessionManager()
    engine = session.get_engine(backend.url)

    # Test connection
    with engine.connect() as conn:
        conn.execute("SELECT 1")
    print("✓ Database connection successful")

    # Create tables if needed
    from celery.backends.database import models
    models.ResultModelBase.metadata.create_all(engine)
    print("✓ Database tables verified")

    # Test result storage
    test_task_id = 'test-backend-verification-task'
    test_result = {'status': 'success', 'message': 'Backend test passed'}

    backend.store_result(test_task_id, test_result, 'SUCCESS')
    print("✓ Result storage successful")

    # Test result retrieval
    retrieved = backend.get_result(test_task_id)
    print(f"✓ Result retrieval successful: {retrieved}")

    # Cleanup
    backend.forget(test_task_id)
    print("✓ Result cleanup successful")

    print("\n✓ All database backend tests passed!")
    sys.exit(0)

except Exception as e:
    print(f"✗ Database backend test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF
        ;;

    sqlite)
        print_info "Testing SQLite backend..."

        cat > "$TEST_SCRIPT" <<'EOF'
import os
import sys
from celery import Celery

# SQLite backend (for development)
db_path = os.getenv('SQLITE_PATH', './celery_results.db')
result_backend = f'db+sqlite:///{db_path}'

print(f"Testing SQLite backend at: {db_path}")

try:
    app = Celery('test', backend=result_backend)
    backend = app.backend

    # Create tables
    from celery.backends.database import models
    from celery.backends.database import SessionManager

    session = SessionManager()
    engine = session.get_engine(backend.url)
    models.ResultModelBase.metadata.create_all(engine)
    print("✓ SQLite database created")

    # Test result storage
    test_task_id = 'test-backend-verification-task'
    test_result = {'status': 'success', 'message': 'Backend test passed'}

    backend.store_result(test_task_id, test_result, 'SUCCESS')
    print("✓ Result storage successful")

    # Test result retrieval
    retrieved = backend.get_result(test_task_id)
    print(f"✓ Result retrieval successful: {retrieved}")

    # Cleanup
    backend.forget(test_task_id)
    print("✓ Result cleanup successful")

    print("\n✓ All SQLite backend tests passed!")
    sys.exit(0)

except Exception as e:
    print(f"✗ SQLite backend test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF
        ;;

    rpc)
        print_info "Testing RPC backend..."

        cat > "$TEST_SCRIPT" <<'EOF'
import os
import sys
from celery import Celery

# Load broker configuration
broker_user = os.getenv('BROKER_USER', 'guest')
broker_password = os.getenv('BROKER_PASSWORD', 'guest')
broker_host = os.getenv('BROKER_HOST', 'localhost')
broker_port = os.getenv('BROKER_PORT', '5672')
broker_vhost = os.getenv('BROKER_VHOST', '/')

broker_url = f'amqp://{broker_user}:{broker_password}@{broker_host}:{broker_port}/{broker_vhost}'
result_backend = 'rpc://'

print(f"Testing RPC backend with broker: amqp://{broker_user}:***@{broker_host}:{broker_port}/{broker_vhost}")

try:
    app = Celery('test', broker=broker_url, backend=result_backend)

    # Test broker connection
    with app.connection() as conn:
        conn.connect()
    print("✓ Broker connection successful")

    # RPC backend verification
    backend = app.backend
    print("✓ RPC backend initialized")

    # Note: RPC backend needs actual task execution to test fully
    # We can only verify configuration here
    print("✓ RPC backend configured correctly")

    print("\n✓ RPC backend tests passed!")
    print("  Note: Full testing requires running worker and sending actual tasks")
    sys.exit(0)

except Exception as e:
    print(f"✗ RPC backend test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF
        ;;

    *)
        print_error "Unknown backend type: $BACKEND_TYPE"
        echo "Supported: redis, postgresql, mysql, sqlite, rpc"
        exit 1
        ;;
esac

# Set DB_TYPE for database backends
if [ "$BACKEND_TYPE" = "postgresql" ] || [ "$BACKEND_TYPE" = "mysql" ]; then
    export DB_TYPE="$BACKEND_TYPE"
fi

# Run test
print_info "Running backend tests..."
echo ""

if python3 "$TEST_SCRIPT"; then
    echo ""
    print_success "All backend tests passed for $BACKEND_TYPE!"
    rm -f "$TEST_SCRIPT"
    exit 0
else
    echo ""
    print_error "Backend tests failed for $BACKEND_TYPE"
    print_info "Test script saved to: $TEST_SCRIPT"
    echo ""
    print_info "Troubleshooting tips:"

    case "$BACKEND_TYPE" in
        redis)
            echo "  1. Check Redis is running: redis-cli ping"
            echo "  2. Verify REDIS_HOST environment variable"
            echo "  3. Verify REDIS_PASSWORD if auth enabled"
            echo "  4. Check firewall/network connectivity"
            ;;
        postgresql|mysql)
            echo "  1. Check database server is running"
            echo "  2. Verify DB_USER, DB_PASSWORD, DB_HOST environment variables"
            echo "  3. Verify database exists: $DB_NAME"
            echo "  4. Check user permissions"
            echo "  5. Install driver: pip install psycopg2-binary  # or mysqlclient"
            ;;
        sqlite)
            echo "  1. Check write permissions to database directory"
            echo "  2. Install sqlalchemy: pip install sqlalchemy"
            ;;
        rpc)
            echo "  1. Check RabbitMQ is running: rabbitmqctl status"
            echo "  2. Verify BROKER_USER and BROKER_PASSWORD"
            echo "  3. Check broker connectivity"
            ;;
    esac

    exit 1
fi
