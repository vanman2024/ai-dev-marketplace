---
name: deploy
description: Deploy to iOS App Store and Google Play Store
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:deploy

Submit app to app stores using EAS Submit.

## Arguments

$ARGUMENTS - Optional: platform (ios, android, all)

## Execution

### Phase 1: Verify Build Exists

Check for production builds: eas build:list --profile production

### Phase 2: Gather Deployment Options

Use AskUserQuestion:
- Stores: Both, iOS only, Android only
- Android track: internal, alpha, beta, production

### Phase 3: Invoke App Store Deployer

Task(description="Submit to stores", subagent_type="app-store-deployer", prompt="Deploy to app stores:

Platforms: [from Phase 2]
Android Track: [from Phase 2]

Steps:
1. Verify eas.json submit configuration
2. For iOS: Check Apple credentials, submit to TestFlight
3. For Android: Check service account, submit to selected track
4. Provide submission status

Commands:
- iOS: eas submit --platform ios --latest
- Android: eas submit --platform android --latest

SECURITY: Never commit google-service-account.json or Apple credentials.")

### Phase 4: Summary

Display:
- Submitted to: [platforms]
- iOS: Processing in TestFlight
- Android: Processing in [track]
- Next: Check stores in 10-30 minutes, add testers
