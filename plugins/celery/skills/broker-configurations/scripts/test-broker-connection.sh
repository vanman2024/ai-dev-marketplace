#!/bin/bash
#
# Test Celery Broker Connection
#
# Tests connectivity to Redis, RabbitMQ, or SQS broker and validates configuration.
# Usage: ./test-broker-connection.sh [broker-type]
#
# Examples:
#   ./test-broker-connection.sh redis
#   ./test-broker-connection.sh rabbitmq
#   ./test-broker-connection.sh sqs

set -e

BROKER_TYPE="${1:-redis}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if .env file exists
check_env_file() {
    if [ ! -f ".env" ]; then
        print_warning ".env file not found"
        print_info "Copy .env.example to .env and configure your settings"
        return 1
    fi
    return 0
}

# Load environment variables
load_env() {
    if check_env_file; then
        set -a
        source .env
        set +a
        print_success "Environment variables loaded"
    else
        print_error "Cannot load environment variables"
        exit 1
    fi
}

# Test Redis connection
test_redis() {
    print_header "Testing Redis Broker Connection"

    # Check if redis-cli is installed
    if ! command -v redis-cli &> /dev/null; then
        print_error "redis-cli not found. Install with: apt-get install redis-tools"
        return 1
    fi

    local host="${REDIS_HOST:-localhost}"
    local port="${REDIS_PORT:-6379}"
    local password="${REDIS_PASSWORD}"
    local db="${REDIS_DB:-0}"

    print_info "Host: $host:$port"
    print_info "Database: $db"

    # Test connection
    if [ -n "$password" ]; then
        if redis-cli -h "$host" -p "$port" -a "$password" -n "$db" PING > /dev/null 2>&1; then
            print_success "Redis connection successful"
        else
            print_error "Redis connection failed"
            return 1
        fi
    else
        if redis-cli -h "$host" -p "$port" -n "$db" PING > /dev/null 2>&1; then
            print_success "Redis connection successful"
        else
            print_error "Redis connection failed"
            return 1
        fi
    fi

    # Check Redis info
    print_info "Redis Server Info:"
    if [ -n "$password" ]; then
        redis-cli -h "$host" -p "$port" -a "$password" INFO server | grep -E "redis_version|os|uptime_in_days" | sed 's/^/  /'
    else
        redis-cli -h "$host" -p "$port" INFO server | grep -E "redis_version|os|uptime_in_days" | sed 's/^/  /'
    fi

    # Check maxmemory policy
    local policy
    if [ -n "$password" ]; then
        policy=$(redis-cli -h "$host" -p "$port" -a "$password" CONFIG GET maxmemory-policy 2>/dev/null | tail -1)
    else
        policy=$(redis-cli -h "$host" -p "$port" CONFIG GET maxmemory-policy 2>/dev/null | tail -1)
    fi

    if [ "$policy" != "noeviction" ]; then
        print_warning "Redis maxmemory-policy is '$policy' (recommended: noeviction)"
    else
        print_success "Redis maxmemory-policy correctly set to noeviction"
    fi

    return 0
}

# Test RabbitMQ connection
test_rabbitmq() {
    print_header "Testing RabbitMQ Broker Connection"

    # Check if rabbitmqadmin is installed
    if ! command -v rabbitmqadmin &> /dev/null; then
        print_warning "rabbitmqadmin not found. Using curl instead"
    fi

    local host="${RABBITMQ_HOST:-localhost}"
    local port="${RABBITMQ_PORT:-5672}"
    local user="${RABBITMQ_USER:-guest}"
    local password="${RABBITMQ_PASSWORD:-guest}"
    local vhost="${RABBITMQ_VHOST:-/}"

    print_info "Host: $host:$port"
    print_info "User: $user"
    print_info "VHost: $vhost"

    # Test connection using Python
    python3 - <<EOF
import sys
try:
    from kombu import Connection

    conn_url = "amqp://$user:$password@$host:$port/$vhost"
    with Connection(conn_url) as conn:
        conn.ensure_connection(max_retries=3, timeout=5)
        print("✅ RabbitMQ connection successful")

        # Try to get channel info
        channel = conn.channel()
        print("✅ Channel created successfully")
        channel.close()

    sys.exit(0)
except ImportError:
    print("❌ kombu not installed. Run: pip install kombu")
    sys.exit(1)
except Exception as e:
    print(f"❌ RabbitMQ connection failed: {e}")
    sys.exit(1)
EOF

    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        print_success "RabbitMQ connection test passed"
        return 0
    else
        print_error "RabbitMQ connection test failed"
        return 1
    fi
}

# Test SQS connection
test_sqs() {
    print_header "Testing Amazon SQS Broker Connection"

    local region="${AWS_REGION:-us-east-1}"
    local queue_prefix="${SQS_QUEUE_PREFIX:-celery-}"

    print_info "Region: $region"
    print_info "Queue Prefix: $queue_prefix"

    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Install with: pip install awscli"
        return 1
    fi

    # Test AWS credentials
    if ! aws sts get-caller-identity --region "$region" > /dev/null 2>&1; then
        print_error "AWS credentials not configured or invalid"
        print_info "Configure with: aws configure"
        return 1
    fi

    print_success "AWS credentials valid"

    # Get caller identity
    print_info "AWS Identity:"
    aws sts get-caller-identity --region "$region" | grep -E "UserId|Account|Arn" | sed 's/^/  /'

    # Test SQS access by listing queues
    if aws sqs list-queues --region "$region" --queue-name-prefix "$queue_prefix" > /dev/null 2>&1; then
        print_success "SQS access granted"

        # List existing queues with prefix
        local queues
        queues=$(aws sqs list-queues --region "$region" --queue-name-prefix "$queue_prefix" --output json 2>/dev/null | grep -o "https://[^\"]*")

        if [ -n "$queues" ]; then
            print_info "Existing Celery queues:"
            echo "$queues" | sed 's/^/  /'
        else
            print_info "No existing queues found with prefix '$queue_prefix'"
            print_info "Queues will be created automatically when first task is sent"
        fi
    else
        print_error "SQS access denied or not available"
        return 1
    fi

    return 0
}

# Test Celery with broker
test_celery_connection() {
    print_header "Testing Celery Configuration"

    # Create temporary test script
    cat > /tmp/celery_test.py <<EOF
import sys
import os
from celery import Celery

# Load broker URL from environment
broker_url = os.getenv('CELERY_BROKER_URL')

if not broker_url:
    print("❌ CELERY_BROKER_URL not set in environment")
    sys.exit(1)

try:
    app = Celery('test', broker=broker_url)

    # Test connection
    with app.connection() as conn:
        conn.ensure_connection(max_retries=3, timeout=5)
        print("✅ Celery broker connection successful")
        print(f"   Broker: {broker_url.split('@')[-1] if '@' in broker_url else broker_url.split('//')[1]}")

    sys.exit(0)
except ImportError:
    print("❌ Celery not installed. Run: pip install celery")
    sys.exit(1)
except Exception as e:
    print(f"❌ Celery connection failed: {e}")
    sys.exit(1)
EOF

    python3 /tmp/celery_test.py
    local exit_code=$?

    rm -f /tmp/celery_test.py

    return $exit_code
}

# Main function
main() {
    print_header "Celery Broker Connection Test"
    print_info "Broker Type: $BROKER_TYPE"

    # Load environment variables
    load_env

    # Test specific broker
    case "$BROKER_TYPE" in
        redis)
            test_redis
            ;;
        rabbitmq)
            test_rabbitmq
            ;;
        sqs)
            test_sqs
            ;;
        *)
            print_error "Unknown broker type: $BROKER_TYPE"
            print_info "Supported types: redis, rabbitmq, sqs"
            exit 1
            ;;
    esac

    # Test Celery connection
    test_celery_connection

    print_header "Test Complete"
    print_success "All tests passed for $BROKER_TYPE broker"
}

# Run main function
main
