# app-store-deployment

App store submission patterns for iOS and Android.

## Contents

- EAS Submit configuration
- iOS App Store Connect setup
- Google Play Console setup
- Release tracks
- Submission automation

## Usage

Reference this skill when deploying to app stores.

## Key Patterns

### iOS Submission
- Apple ID and app-specific password
- ASC App ID and Team ID
- TestFlight for beta testing
- Submit via eas submit --platform ios

### Android Submission
- Service Account with JSON key
- Release tracks: internal, alpha, beta, production
- AAB format for Play Store
- Submit via eas submit --platform android

### EAS Submit Config
```json
{
  "submit": {
    "production": {
      "ios": { "appleId": "...", "ascAppId": "..." },
      "android": { "serviceAccountKeyPath": "...", "track": "internal" }
    }
  }
}
```

### Automation
- --auto-submit with build
- GitHub Actions workflow
- EAS Secrets for credentials

## Security

Never commit credentials. Use EAS Secrets for CI/CD.
