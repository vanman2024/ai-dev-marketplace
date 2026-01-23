---
name: add-screen
description: Add a new screen/view to the mobile app
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:add-screen

Add a new screen to the Expo Router mobile application.

## Arguments

$ARGUMENTS - Screen name (required)

Example: /mobile:add-screen profile

## Execution

### Phase 1: Parse and Validate

Extract screen name from $ARGUMENTS.
Verify app/ directory exists (Expo Router).

### Phase 2: Gather Screen Details

Use AskUserQuestion:
- Location: (tabs), (auth), root, or nested folder
- Screen type: List, Detail, Form, or Dashboard

### Phase 3: Invoke Mobile Architect

Task(description="Create screen component", subagent_type="mobile-architect", prompt="Create a new screen for Expo Router:

Screen Name: [from $ARGUMENTS]
Location: [from Phase 2]
Type: [from Phase 2]

Generate the screen file with:
- Proper SafeAreaView usage
- Navigation hooks (useRouter, useLocalSearchParams)
- Placeholder content matching screen type
- TypeScript types

If adding to tabs, update (tabs)/_layout.tsx with new tab.")

### Phase 4: Summary

Display:
- Screen created: app/[location]/[name].tsx
- Type: [selected type]
- Navigation updated: Yes/No
