#!/bin/bash
# Setup doctl CLI with authentication
# Usage: ./setup-doctl.sh

echo "🔧 Setting up doctl CLI..."

# Check if doctl is installed
if ! command -v doctl &> /dev/null; then
    echo "Installing doctl..."
    # macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install doctl
    # Linux
    else
        curl -sL https://github.com/digitalocean/doctl/releases/download/v1.100.0/doctl-1.100.0-linux-amd64.tar.gz | tar -xzv
        sudo mv doctl /usr/local/bin
    fi
fi

echo "Authenticate with DigitalOcean:"
doctl auth init

echo "✅ doctl configured"
