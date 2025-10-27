#!/usr/bin/env bash
# Checks Claude Agent SDK version compatibility

set -euo pipefail

PROJECT_DIR="${1:-.}"

echo "🔍 Checking Claude Agent SDK Version"
echo ""

# Check TypeScript SDK version
if [[ -f "$PROJECT_DIR/package.json" ]]; then
    SDK_VERSION=$(grep -o '"@claude-ai/sdk".*"[^"]*"' "$PROJECT_DIR/package.json" | grep -o '[0-9][^"]*' || echo "not found")

    if [[ "$SDK_VERSION" != "not found" ]]; then
        echo "TypeScript SDK Version: $SDK_VERSION"

        # Check if version is compatible (1.0.0+)
        MAJOR_VERSION=$(echo "$SDK_VERSION" | cut -d. -f1 | grep -o '[0-9]*')
        if [[ $MAJOR_VERSION -ge 1 ]]; then
            echo "✅ SDK version compatible"
        else
            echo "⚠️  WARNING: SDK version may be outdated"
            echo "   Latest: npm install @claude-ai/sdk@latest"
        fi
    fi
fi

# Check Python SDK version
if [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
    SDK_VERSION=$(grep -o 'claude-ai-sdk[^"]*' "$PROJECT_DIR/pyproject.toml" | head -1 || echo "not found")

    if [[ "$SDK_VERSION" != "not found" ]]; then
        echo "Python SDK Version: $SDK_VERSION"
        echo "✅ SDK dependency configured"
    fi
fi

# Check installed version (TypeScript)
if [[ -d "$PROJECT_DIR/node_modules/@claude-ai/sdk" ]]; then
    INSTALLED_VERSION=$(grep -o '"version".*"[^"]*"' "$PROJECT_DIR/node_modules/@claude-ai/sdk/package.json" | grep -o '[0-9][^"]*' || echo "unknown")
    echo "Installed TypeScript SDK: $INSTALLED_VERSION"
fi

# Check installed version (Python)
if command -v python3 &> /dev/null; then
    INSTALLED_VERSION=$(python3 -c "import claude_sdk; print(claude_sdk.__version__)" 2>/dev/null || echo "not installed")
    if [[ "$INSTALLED_VERSION" != "not installed" ]]; then
        echo "Installed Python SDK: $INSTALLED_VERSION"
    fi
fi

echo ""
echo "✅ Version check complete"
