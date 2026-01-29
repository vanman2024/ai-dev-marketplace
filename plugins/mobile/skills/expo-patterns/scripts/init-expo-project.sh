#!/bin/bash
# Initialize new Expo project with TypeScript and common dependencies
# Usage: ./init-expo-project.sh <project-name>

PROJECT_NAME=${1:-"my-app"}

echo "🚀 Creating Expo project: $PROJECT_NAME"

# Create project with tabs template
npx create-expo-app "$PROJECT_NAME" --template tabs

cd "$PROJECT_NAME" || exit 1

# Install common dependencies
echo "📦 Installing common dependencies..."
npx expo install expo-secure-store expo-local-authentication expo-notifications expo-image

# Initialize EAS
echo "🔧 Initializing EAS..."
eas init

echo "✅ Project created: $PROJECT_NAME"
echo "Next steps:"
echo "  cd $PROJECT_NAME"
echo "  npx expo start"
