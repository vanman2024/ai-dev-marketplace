#!/bin/bash
#
# Setup Redis Broker for Celery
#
# Installs and configures Redis for use as a Celery broker.
# Includes production-ready settings and security configurations.
#
# Usage: ./setup-redis.sh [--install] [--configure] [--docker]

set -e

INSTALL=false
CONFIGURE=false
USE_DOCKER=false
REDIS_CONF="/etc/redis/redis.conf"

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
            echo "  --install     Install Redis server"
            echo "  --configure   Configure Redis for Celery"
            echo "  --docker      Use Docker for Redis"
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

# Install Redis
install_redis() {
    print_header "Installing Redis"

    if command -v redis-server &> /dev/null; then
        print_warning "Redis is already installed"
        redis-server --version
        return 0
    fi

    # Detect OS
    if [ -f /etc/debian_version ]; then
        print_info "Installing Redis on Debian/Ubuntu"
        sudo apt-get update
        sudo apt-get install -y redis-server redis-tools
    elif [ -f /etc/redhat-release ]; then
        print_info "Installing Redis on RHEL/CentOS"
        sudo yum install -y redis
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "Installing Redis on macOS"
        brew install redis
    else
        print_error "Unsupported OS"
        exit 1
    fi

    print_success "Redis installed successfully"
}

# Configure Redis for Celery
configure_redis() {
    print_header "Configuring Redis for Celery"

    if [ ! -f "$REDIS_CONF" ]; then
        print_error "Redis config not found at $REDIS_CONF"
        exit 1
    fi

    # Backup existing config
    sudo cp "$REDIS_CONF" "${REDIS_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    print_success "Backed up existing config"

    # Configure maxmemory-policy (CRITICAL for Celery)
    print_info "Setting maxmemory-policy to noeviction"
    sudo sed -i 's/^maxmemory-policy .*/maxmemory-policy noeviction/' "$REDIS_CONF"
    if ! grep -q "^maxmemory-policy" "$REDIS_CONF"; then
        echo "maxmemory-policy noeviction" | sudo tee -a "$REDIS_CONF" > /dev/null
    fi

    # Set maxmemory (adjust based on your system)
    print_info "Setting maxmemory to 256mb (adjust as needed)"
    sudo sed -i 's/^maxmemory .*/maxmemory 256mb/' "$REDIS_CONF"
    if ! grep -q "^maxmemory " "$REDIS_CONF"; then
        echo "maxmemory 256mb" | sudo tee -a "$REDIS_CONF" > /dev/null
    fi

    # Enable persistence (optional but recommended)
    print_info "Enabling RDB and AOF persistence"
    sudo sed -i 's/^save .*/save 900 1\nsave 300 10\nsave 60 10000/' "$REDIS_CONF"
    sudo sed -i 's/^appendonly .*/appendonly yes/' "$REDIS_CONF"
    if ! grep -q "^appendonly" "$REDIS_CONF"; then
        echo "appendonly yes" | sudo tee -a "$REDIS_CONF" > /dev/null
    fi

    # Disable protected mode for local development (enable for production)
    print_warning "Disabling protected mode for development"
    print_info "For production, enable protected mode and set a password"
    sudo sed -i 's/^protected-mode .*/protected-mode no/' "$REDIS_CONF"

    # Restart Redis
    print_info "Restarting Redis service"
    if command -v systemctl &> /dev/null; then
        sudo systemctl restart redis-server || sudo systemctl restart redis
        sudo systemctl enable redis-server || sudo systemctl enable redis
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew services restart redis
    fi

    print_success "Redis configured successfully"
}

# Setup Redis with Docker
setup_docker_redis() {
    print_header "Setting up Redis with Docker"

    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Install Docker first."
        exit 1
    fi

    # Create docker-compose.yml
    cat > docker-compose.redis.yml <<EOF
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: celery-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    networks:
      - celery-network

volumes:
  redis_data:

networks:
  celery-network:
    driver: bridge
EOF

    # Create redis.conf for Docker
    cat > redis.conf <<EOF
# Redis configuration for Celery

# Memory management
maxmemory 256mb
maxmemory-policy noeviction

# Persistence
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec

# Performance
tcp-backlog 511
timeout 0
tcp-keepalive 300

# Security (set password in production)
# requirepass your_redis_password_here

# Logging
loglevel notice
logfile ""
EOF

    print_success "Created docker-compose.redis.yml and redis.conf"
    print_info "Start Redis with: docker-compose -f docker-compose.redis.yml up -d"
    print_info "Stop Redis with: docker-compose -f docker-compose.redis.yml down"
    print_warning "For production, set a password in redis.conf (uncomment requirepass)"
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
# Redis Broker Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=your_redis_password_here
REDIS_USE_SSL=false

# Celery broker URL
CELERY_BROKER_URL=redis://:your_redis_password_here@localhost:6379/0

# Result backend (can use same Redis instance with different DB)
CELERY_RESULT_BACKEND=redis://:your_redis_password_here@localhost:6379/1
EOF

    print_success "Created $ENV_FILE"
    print_warning "Replace 'your_redis_password_here' with actual password"
    print_info "For development without password, use: redis://localhost:6379/0"
}

# Test Redis installation
test_redis() {
    print_header "Testing Redis Installation"

    if ! command -v redis-cli &> /dev/null; then
        print_error "redis-cli not found"
        return 1
    fi

    # Test connection
    if redis-cli PING > /dev/null 2>&1; then
        print_success "Redis is running and responding"
        redis-cli INFO server | grep -E "redis_version|uptime_in_days"
    else
        print_error "Cannot connect to Redis"
        print_info "Make sure Redis is running: sudo systemctl status redis"
        return 1
    fi

    # Check maxmemory-policy
    local policy=$(redis-cli CONFIG GET maxmemory-policy 2>/dev/null | tail -1)
    if [ "$policy" = "noeviction" ]; then
        print_success "maxmemory-policy correctly set to noeviction"
    else
        print_warning "maxmemory-policy is '$policy' (should be noeviction)"
    fi
}

# Main function
main() {
    print_header "Redis Setup for Celery"

    if [ "$USE_DOCKER" = true ]; then
        setup_docker_redis
        create_env_template
        print_success "Docker setup complete"
        exit 0
    fi

    if [ "$INSTALL" = true ]; then
        install_redis
    fi

    if [ "$CONFIGURE" = true ]; then
        configure_redis
    fi

    if [ "$INSTALL" = true ] || [ "$CONFIGURE" = true ]; then
        create_env_template
        test_redis
    fi

    print_header "Setup Complete"
    print_success "Redis is ready for Celery"
    print_info "Next steps:"
    print_info "1. Review and update .env file"
    print_info "2. Test connection: ./test-broker-connection.sh redis"
    print_info "3. Start Celery worker with Redis broker"
}

main
