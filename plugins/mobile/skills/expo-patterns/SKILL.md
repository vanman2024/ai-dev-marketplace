# expo-patterns

Expo SDK configuration and best practices for React Native mobile apps.

## Contents

- Project initialization templates
- app.json/app.config.js patterns
- Expo SDK module usage
- Environment variable configuration
- EAS configuration templates

## Usage

Reference this skill when setting up Expo projects or configuring SDK features.

## Key Patterns

### App Configuration
- Use app.config.js for dynamic config with environment variables
- EXPO_PUBLIC_ prefix for client-side env vars
- Configure plugins array for native modules

### SDK Modules
- expo-secure-store for sensitive data
- expo-image for optimized images
- expo-notifications for push
- expo-camera, expo-location for device features

## Security

All examples use environment variable placeholders. Never hardcode API keys.
