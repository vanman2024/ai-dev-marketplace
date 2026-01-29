#!/bin/bash
# Install authentication dependencies for Expo
# Usage: ./setup-auth.sh

echo "📦 Installing auth dependencies..."

npx expo install expo-secure-store expo-local-authentication expo-auth-session expo-crypto

echo "✅ Auth dependencies installed"
