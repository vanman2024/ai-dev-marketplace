# eas-build-config

EAS Build configuration for Expo app builds.

## Contents

- eas.json profiles
- Build configurations
- Credentials management
- CI/CD integration
- Environment variables

## Usage

Reference this skill when configuring EAS Build.

## Key Patterns

### Profiles
- development: Dev client, internal distribution
- preview: Internal testing, APK output
- production: Store builds, AAB/IPA

### Configuration
- autoIncrement for versions
- resourceClass for build speed
- environment variables per profile

### Build Commands
- eas build --profile <profile>
- eas build --platform <ios|android|all>
- eas build:list, eas build:view

### Credentials
- eas credentials for management
- Managed by EAS (recommended)
- Custom provisioning profiles

### CI/CD
- EXPO_TOKEN for authentication
- --non-interactive flag
- GitHub Actions integration

## Security

Never commit signing keys. Use EAS managed credentials.
