#!/bin/bash
# Install A2A Protocol Java SDK

set -e

echo "Installing A2A Protocol Java SDK..."

# Check Java version
if ! command -v java &> /dev/null; then
    echo "Error: Java is not installed"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
REQUIRED_VERSION=11

if [ "$JAVA_VERSION" -lt "$REQUIRED_VERSION" ]; then
    echo "Error: Java $REQUIRED_VERSION or higher is required (found $JAVA_VERSION)"
    exit 1
fi

# Detect build tool
if [ -f "pom.xml" ]; then
    BUILD_TOOL="maven"
    echo "Detected Maven project"

    # Add dependency to pom.xml if not already present
    if ! grep -q "a2a-protocol-java" pom.xml; then
        echo "Adding A2A Protocol dependency to pom.xml..."
        echo "Please add this dependency to your pom.xml:"
        echo ""
        cat templates/java-config.xml
    else
        echo "A2A Protocol dependency already in pom.xml"
    fi

    # Install dependencies
    mvn clean install

elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    BUILD_TOOL="gradle"
    echo "Detected Gradle project"

    echo "Please add this dependency to your build.gradle:"
    echo ""
    echo "implementation 'com.a2a:protocol-java:1.0.0'"
    echo ""
    echo "Then run: ./gradlew build"

else
    echo "No pom.xml or build.gradle found"
    echo "Please create a Maven or Gradle project first"
    exit 1
fi

echo "✓ A2A Protocol Java SDK setup complete"
echo ""
echo "Next steps:"
echo "1. Set up environment variables (see templates/env-template.txt)"
echo "2. Run validation: ./scripts/validate-java.sh"
