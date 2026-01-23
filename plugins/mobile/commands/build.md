---
name: build
description: Build app for iOS and Android using EAS Build
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:build

Build the app using EAS Build.

## Arguments

$ARGUMENTS - Optional: platform and profile

## Execution

### Phase 1: Verify EAS Setup

Check eas.json exists and eas-cli installed.
Run eas build:configure if needed.

### Phase 2: Gather Build Options

Use AskUserQuestion:
- Platform: Both, iOS only, Android only
- Profile: preview (recommended), development, production

### Phase 3: Invoke App Store Deployer

Task(description="Run EAS build", subagent_type="app-store-deployer", prompt="Build the Expo app with EAS:

Platform: [from Phase 2]
Profile: [from Phase 2]

Steps:
1. Verify app.json has bundleIdentifier and package
2. Check for required assets (icon, splash)
3. Run appropriate eas build command
4. Provide build URL for monitoring

Commands:
- Development: eas build --profile development --platform [platform]
- Preview: eas build --profile preview --platform [platform]
- Production: eas build --profile production --platform [platform]")

### Phase 4: Summary

Display:
- Build started for: [platform]
- Profile: [selected]
- Monitor at: [EAS dashboard URL]
- Next: Download when complete, use /mobile:deploy for store submission
