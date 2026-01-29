#!/bin/bash
# Install React Navigation dependencies for Expo
# Usage: ./setup-navigation.sh

echo "📦 Installing navigation dependencies..."

npx expo install @react-navigation/native @react-navigation/native-stack @react-navigation/bottom-tabs
npx expo install react-native-screens react-native-safe-area-context

echo "✅ Navigation dependencies installed"
