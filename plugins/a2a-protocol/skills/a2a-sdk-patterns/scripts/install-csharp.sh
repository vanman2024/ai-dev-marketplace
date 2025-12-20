#!/bin/bash
# Install A2A Protocol C# SDK

set -e

echo "Installing A2A Protocol C# SDK..."

# Check dotnet version
if ! command -v dotnet &> /dev/null; then
    echo "Error: .NET SDK is not installed"
    exit 1
fi

DOTNET_VERSION=$(dotnet --version | cut -d'.' -f1)
REQUIRED_VERSION=6

if [ "$DOTNET_VERSION" -lt "$REQUIRED_VERSION" ]; then
    echo "Error: .NET $REQUIRED_VERSION or higher is required (found $DOTNET_VERSION)"
    exit 1
fi

# Check if .csproj exists
if ! ls *.csproj 1> /dev/null 2>&1; then
    echo "No .csproj file found in current directory"
    echo "Please create a .NET project first:"
    echo "  dotnet new console -n MyA2AProject"
    exit 1
fi

# Install SDK via NuGet
echo "Installing A2A.Protocol package..."
dotnet add package A2A.Protocol

echo "✓ A2A Protocol C# SDK installed successfully"
echo ""
echo "Next steps:"
echo "1. Set up environment variables (see templates/env-template.txt)"
echo "2. Configure authentication (see templates/csharp-config.csproj)"
echo "3. Run validation: ./scripts/validate-csharp.sh"
