#!/bin/bash
# Install A2A Protocol Go SDK

set -e

echo "Installing A2A Protocol Go SDK..."

# Check Go version
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed"
    exit 1
fi

GO_VERSION=$(go version | grep -oP 'go\K[0-9]+\.[0-9]+' | cut -d'.' -f1,2)
REQUIRED_VERSION="1.20"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "Error: Go $REQUIRED_VERSION or higher is required (found $GO_VERSION)"
    exit 1
fi

# Initialize module if needed
if [ ! -f "go.mod" ]; then
    echo "No go.mod found. Initializing Go module..."
    read -p "Enter module name (e.g., example.com/myproject): " MODULE_NAME
    go mod init "$MODULE_NAME"
fi

# Install SDK
echo "Installing github.com/a2a/protocol-go package..."
go get github.com/a2a/protocol-go

echo "✓ A2A Protocol Go SDK installed successfully"
echo ""
echo "Next steps:"
echo "1. Set up environment variables (see templates/env-template.txt)"
echo "2. Run validation: ./scripts/validate-go.sh"
