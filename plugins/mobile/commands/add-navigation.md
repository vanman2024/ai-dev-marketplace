---
name: add-navigation
description: Setup navigation with Expo Router or React Navigation
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
---

# /mobile:add-navigation

Configure navigation for the mobile app.

## Arguments

$ARGUMENTS - Optional: navigation type (tabs, drawer, stack)

## Execution

### Phase 1: Detect Setup

Check for existing Expo Router or React Navigation.

### Phase 2: Gather Requirements

Use AskUserQuestion:
- Navigation type: Tabs, Drawer, Stack, or Nested
- Number of screens: 3, 4, 5, or custom

### Phase 3: Invoke Navigation Specialist

Task(description="Setup navigation", subagent_type="mobile-navigation-specialist", prompt="Configure navigation for this Expo app:

Type: [from Phase 2]
Screens: [from Phase 2]

Create:
1. Root _layout.tsx with Stack navigator
2. Tab/Drawer group with _layout.tsx
3. Placeholder screens for each tab
4. Navigation utilities hook

Use Expo Router patterns, include proper types.")

### Phase 4: Summary

Display:
- Navigation type: [selected]
- Screens created: [list]
- Files modified: [list]
