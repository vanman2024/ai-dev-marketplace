---
name: expo-patterns
description: Expo and React Native patterns for mobile development with EAS Build, SDK integration, and native module configuration. Use when building Expo apps, configuring native features, or setting up app signing for store deployment.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# Expo Patterns

Comprehensive skill for building production mobile apps with Expo and React Native.

## Overview

Expo provides managed workflow for React Native development:

- Simplified native module configuration
- EAS Build for cloud-based app building
- OTA updates with expo-updates
- Push notifications with expo-notifications
- Cross-platform APIs for camera, location, etc.

## Use When

This skill is automatically invoked when:

- Initializing new Expo/React Native projects
- Configuring native features (camera, location, notifications)
- Setting up EAS Build for iOS/Android
- Managing app signing and certificates
- Implementing OTA updates

## Security: Credentials

**CRITICAL:** Never commit signing credentials

❌ NEVER commit: `.p12`, `.mobileprovision`, keystore files
✅ ALWAYS use: `eas secret:create` for sensitive values
✅ ALWAYS add to `.gitignore`: `*.jks`, `*.p12`, `*.mobileprovision`

## Available Scripts

| Script                           | Description                                 |
| -------------------------------- | ------------------------------------------- |
| `scripts/init-expo-project.sh`   | Initialize new Expo project with TypeScript |
| `scripts/setup-eas-build.sh`     | Configure EAS Build profiles                |
| `scripts/setup-notifications.sh` | Set up push notifications                   |

## Available Templates

| Template                | Description                    |
| ----------------------- | ------------------------------ |
| `templates/app.json`    | Expo app configuration         |
| `templates/eas.json`    | EAS Build configuration        |
| `templates/env.example` | Environment variables template |

## CLI Commands

```bash
# Create new project
npx create-expo-app my-app --template tabs

# EAS Build
eas build --platform ios --profile development
eas build --platform android --profile preview

# Submit to stores
eas submit --platform ios
eas submit --platform android
```

## Best Practices

1. Use expo-router for file-based routing
2. Use expo-secure-store for tokens
3. Set up EAS Build for consistent builds
4. Implement OTA updates for quick fixes
