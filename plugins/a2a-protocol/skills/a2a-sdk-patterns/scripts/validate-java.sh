#!/bin/bash
# Validate A2A Protocol Java SDK installation

set -e

echo "Validating A2A Protocol Java SDK installation..."

# Check if Maven or Gradle project
if [ -f "pom.xml" ]; then
    BUILD_TOOL="maven"

    # Check if dependency exists
    if ! grep -q "a2a-protocol-java" pom.xml; then
        echo "✗ A2A Protocol Java SDK is not in pom.xml"
        echo "Run: ./scripts/install-java.sh"
        exit 1
    fi

    echo "✓ A2A Protocol Java SDK configured in pom.xml"

    # Try to compile to verify
    if mvn compile > /dev/null 2>&1; then
        echo "✓ Project compiles successfully"
    else
        echo "⚠ Warning: Project compilation failed"
    fi

elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    BUILD_TOOL="gradle"

    if grep -q "a2a.*protocol-java" build.gradle* 2>/dev/null; then
        echo "✓ A2A Protocol Java SDK configured in build.gradle"
    else
        echo "✗ A2A Protocol Java SDK is not in build.gradle"
        echo "Run: ./scripts/install-java.sh"
        exit 1
    fi

else
    echo "✗ No Maven or Gradle project found"
    exit 1
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
