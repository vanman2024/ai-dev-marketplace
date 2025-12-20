#!/bin/bash
# Validate A2A Protocol C# SDK installation

set -e

echo "Validating A2A Protocol C# SDK installation..."

# Check if .csproj exists
if ! ls *.csproj 1> /dev/null 2>&1; then
    echo "✗ No .csproj file found"
    exit 1
fi

# Check if package is installed
if ! grep -q "A2A.Protocol" *.csproj; then
    echo "✗ A2A Protocol C# SDK is not installed"
    echo "Run: ./scripts/install-csharp.sh"
    exit 1
fi

# Get version
VERSION=$(grep "A2A.Protocol" *.csproj | grep -oP 'Version="\K[^"]+' || echo "unknown")
echo "✓ A2A Protocol C# SDK installed (version: $VERSION)"

# Try to restore to verify
if dotnet restore > /dev/null 2>&1; then
    echo "✓ NuGet packages restored successfully"
else
    echo "⚠ Warning: NuGet restore failed"
fi

# Check environment variables
if [ -z "$A2A_API_KEY" ]; then
    echo "⚠ Warning: A2A_API_KEY environment variable not set"
else
    echo "✓ A2A_API_KEY is set"
fi

if [ -z "$A2A_BASE_URL" ]; then
    echo "⚠ Warning: A2A_BASE_URL environment variable not set"
else
    echo "✓ A2A_BASE_URL is set"
fi

echo ""
echo "Validation complete!"
