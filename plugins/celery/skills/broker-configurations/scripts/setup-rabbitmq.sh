#!/bin/bash
#
# Setup RabbitMQ Broker for Celery
#
# Installs and configures RabbitMQ for use as a Celery broker.
# Includes quorum queues, high availability, and production settings.
#
# Usage: ./setup-rabbitmq.sh [--install] [--configure] [--docker]

set -e

INSTALL=false
CONFIGURE=false
USE_DOCKER=false
RABBITMQ_USER="${RABBITMQ_USER:-celery}"
RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-your_rabbitmq_password_here}"
RABBITMQ_VHOST="${RABBITMQ_VHOST:-celery_vhost}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install)
            INSTALL=true
            shift
            ;;
        --configure)
            CONFIGURE=true
            shift
            ;;
        --docker)
            USE_DOCKER=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--install] [--configure] [--docker]"
            echo ""
            echo "Options:"
            echo "  --install     Install RabbitMQ server"
            echo "  --configure   Configure RabbitMQ for Celery"
            echo "  --docker      Use Docker for RabbitMQ"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# If no options, show usage
if [ "$INSTALL" = false ] && [ "$CONFIGURE" = false ] && [ "$USE_DOCKER" = false ]; then
    print_info "Usage: $0 [--install] [--configure] [--docker]"
    print_info "Use --help for more information"
    exit 0
fi

# Install RabbitMQ
install_rabbitmq() {
    print_header "Installing RabbitMQ"

    if command -v rabbitmqctl &> /dev/null; then
        print_warning "RabbitMQ is already installed"
        rabbitmqctl version
        return 0
    fi

    # Detect OS
    if [ -f /etc/debian_version ]; then
        print_info "Installing RabbitMQ on Debian/Ubuntu"

        # Install Erlang
        sudo apt-get update
        sudo apt-get install -y curl gnupg apt-transport-https

        # Add RabbitMQ repository
        curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/rabbitmq-archive-keyring.gpg

        # Add RabbitMQ apt repository
        sudo tee /etc/apt/sources.list.d/rabbitmq.list > /dev/null <<EOF
deb [signed-by=/usr/share/keyrings/rabbitmq-archive-keyring.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $(lsb_release -sc) main
deb [signed-by=/usr/share/keyrings/rabbitmq-archive-keyring.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu $(lsb_release -sc) main
EOF

        # Install
        sudo apt-get update
        sudo apt-get install -y rabbitmq-server

    elif [ -f /etc/redhat-release ]; then
        print_info "Installing RabbitMQ on RHEL/CentOS"
        sudo yum install -y rabbitmq-server
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "Installing RabbitMQ on macOS"
        brew install rabbitmq
    else
        print_error "Unsupported OS"
        exit 1
    fi

    print_success "RabbitMQ installed successfully"
}

# Configure RabbitMQ for Celery
configure_rabbitmq() {
    print_header "Configuring RabbitMQ for Celery"

    # Enable RabbitMQ plugins
    print_info "Enabling RabbitMQ management plugin"
    sudo rabbitmq-plugins enable rabbitmq_management

    # Start RabbitMQ
    print_info "Starting RabbitMQ service"
    if command -v systemctl &> /dev/null; then
        sudo systemctl start rabbitmq-server
        sudo systemctl enable rabbitmq-server
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew services start rabbitmq
    fi

    # Wait for RabbitMQ to start
    print_info "Waiting for RabbitMQ to start..."
    sleep 5

    # Create user
    print_info "Creating Celery user: $RABBITMQ_USER"
    sudo rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASSWORD" 2>/dev/null || print_warning "User already exists"

    # Create vhost
    print_info "Creating vhost: $RABBITMQ_VHOST"
    sudo rabbitmqctl add_vhost "$RABBITMQ_VHOST" 2>/dev/null || print_warning "VHost already exists"

    # Set permissions
    print_info "Setting permissions for $RABBITMQ_USER on $RABBITMQ_VHOST"
    sudo rabbitmqctl set_permissions -p "$RABBITMQ_VHOST" "$RABBITMQ_USER" ".*" ".*" ".*"

    # Set user tags
    print_info "Setting user tags"
    sudo rabbitmqctl set_user_tags "$RABBITMQ_USER" management

    # Configure RabbitMQ settings
    print_info "Configuring RabbitMQ settings"

    # Create advanced.config for quorum queue defaults
    sudo tee /etc/rabbitmq/advanced.config > /dev/null <<EOF
[
  {rabbit, [
    {default_queue_type, quorum},
    {default_vhost, <<"/">>},
    {disk_free_limit, {mem_relative, 1.5}},
    {vm_memory_high_watermark, 0.4}
  ]},
  {rabbitmq_management, [
    {listener, [{port, 15672}]}
  ]}
].
EOF

    # Restart RabbitMQ to apply changes
    print_info "Restarting RabbitMQ"
    if command -v systemctl &> /dev/null; then
        sudo systemctl restart rabbitmq-server
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew services restart rabbitmq
    fi

    sleep 5
    print_success "RabbitMQ configured successfully"
}

# Setup RabbitMQ with Docker
setup_docker_rabbitmq() {
    print_header "Setting up RabbitMQ with Docker"

    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Install Docker first."
        exit 1
    fi

    # Create docker-compose.yml
    cat > docker-compose.rabbitmq.yml <<EOF
version: '3.8'

services:
  rabbitmq:
    image: rabbitmq:3.13-management-alpine
    container_name: celery-rabbitmq
    restart: unless-stopped
    hostname: rabbitmq
    ports:
      - "5672:5672"    # AMQP port
      - "15672:15672"  # Management UI
    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD}
      RABBITMQ_DEFAULT_VHOST: ${RABBITMQ_VHOST}
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
      - ./rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro
      - ./advanced.config:/etc/rabbitmq/advanced.config:ro
    healthcheck:
      test: rabbitmq-diagnostics -q ping
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - celery-network

volumes:
  rabbitmq_data:

networks:
  celery-network:
    driver: bridge
EOF

    # Create rabbitmq.conf
    cat > rabbitmq.conf <<EOF
# RabbitMQ Configuration for Celery

# Clustering and HA
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config

# Memory and disk settings
vm_memory_high_watermark.relative = 0.4
disk_free_limit.relative = 1.5

# Performance
channel_max = 2048
heartbeat = 60

# Management
management.tcp.port = 15672
management.load_definitions = /etc/rabbitmq/definitions.json
EOF

    # Create advanced.config for quorum queues
    cat > advanced.config <<EOF
[
  {rabbit, [
    {default_queue_type, quorum}
  ]}
].
EOF

    # Create definitions.json for initial setup
    cat > definitions.json <<EOF
{
  "users": [
    {
      "name": "${RABBITMQ_USER}",
      "password": "${RABBITMQ_PASSWORD}",
      "tags": "management"
    }
  ],
  "vhosts": [
    {
      "name": "${RABBITMQ_VHOST}"
    }
  ],
  "permissions": [
    {
      "user": "${RABBITMQ_USER}",
      "vhost": "${RABBITMQ_VHOST}",
      "configure": ".*",
      "write": ".*",
      "read": ".*"
    }
  ],
  "policies": [
    {
      "vhost": "${RABBITMQ_VHOST}",
      "name": "ha-all",
      "pattern": ".*",
      "definition": {
        "ha-mode": "all",
        "ha-sync-mode": "automatic"
      }
    }
  ]
}
EOF

    print_success "Created docker-compose.rabbitmq.yml and configuration files"
    print_info "Start RabbitMQ with: docker-compose -f docker-compose.rabbitmq.yml up -d"
    print_info "Management UI: http://localhost:15672"
    print_info "Default credentials: $RABBITMQ_USER / $RABBITMQ_PASSWORD"
}

# Create .env template
create_env_template() {
    print_header "Creating .env Template"

    if [ -f ".env" ]; then
        print_warning ".env already exists, creating .env.example"
        ENV_FILE=".env.example"
    else
        ENV_FILE=".env"
    fi

    cat > "$ENV_FILE" <<EOF
# RabbitMQ Broker Configuration
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=${RABBITMQ_USER}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}
RABBITMQ_VHOST=${RABBITMQ_VHOST}
RABBITMQ_USE_SSL=false

# Celery broker URL
CELERY_BROKER_URL=amqp://${RABBITMQ_USER}:${RABBITMQ_PASSWORD}@localhost:5672/${RABBITMQ_VHOST}

# Result backend (optional - can use Redis or database)
CELERY_RESULT_BACKEND=redis://localhost:6379/0
EOF

    print_success "Created $ENV_FILE"
    print_warning "Update RABBITMQ_PASSWORD with a secure password"
}

# Test RabbitMQ installation
test_rabbitmq() {
    print_header "Testing RabbitMQ Installation"

    if ! command -v rabbitmqctl &> /dev/null; then
        print_error "rabbitmqctl not found"
        return 1
    fi

    # Check RabbitMQ status
    if sudo rabbitmqctl status > /dev/null 2>&1; then
        print_success "RabbitMQ is running"
        sudo rabbitmqctl status | grep -E "RabbitMQ version|Erlang version"
    else
        print_error "RabbitMQ is not running"
        return 1
    fi

    # List vhosts
    print_info "Virtual hosts:"
    sudo rabbitmqctl list_vhosts | sed 's/^/  /'

    # List users
    print_info "Users:"
    sudo rabbitmqctl list_users | sed 's/^/  /'

    print_success "RabbitMQ test complete"
}

# Main function
main() {
    print_header "RabbitMQ Setup for Celery"

    if [ "$USE_DOCKER" = true ]; then
        setup_docker_rabbitmq
        create_env_template
        print_success "Docker setup complete"
        exit 0
    fi

    if [ "$INSTALL" = true ]; then
        install_rabbitmq
    fi

    if [ "$CONFIGURE" = true ]; then
        configure_rabbitmq
    fi

    if [ "$INSTALL" = true ] || [ "$CONFIGURE" = true ]; then
        create_env_template
        test_rabbitmq
    fi

    print_header "Setup Complete"
    print_success "RabbitMQ is ready for Celery"
    print_info "Next steps:"
    print_info "1. Review and update .env file"
    print_info "2. Access management UI: http://localhost:15672"
    print_info "3. Test connection: ./test-broker-connection.sh rabbitmq"
    print_info "4. Start Celery worker with RabbitMQ broker"
}

main
