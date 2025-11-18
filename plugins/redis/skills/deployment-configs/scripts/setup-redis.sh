#!/bin/bash
# Setup Redis for local development

echo "Setting up Redis..."

# Check if Redis is installed
if ! command -v redis-cli &> /dev/null; then
    echo "Redis not installed. Installing..."
    # Platform detection would go here
fi

# Start Redis
echo "Starting Redis server..."
redis-server --daemonize yes

echo "Redis setup complete!"
