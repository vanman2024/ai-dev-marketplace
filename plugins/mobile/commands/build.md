---
description: Build complete mobile application for new or existing projects with React Native/Expo, navigation, auth, and deployment
argument-hint: [project-name] [--existing]
---

# Build Mobile Application

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(mobile-architect) Analyze project for mobile development.

Detect: Target platforms (iOS, Android, both)
Check: Existing web app, design system
Output: Mobile strategy
```

---

## Phase 2: Project Setup

**Goal:** Set up mobile project

**Actions:**

```
Task(expo-specialist) Set up mobile project.

Requirements:
- Initialize Expo project
- Configure TypeScript
- Set up project structure
- Add base dependencies
- Configure app.json
```

---

## Phase 3: Navigation

**Goal:** Set up navigation

**Actions:**

```
Task(mobile-navigation-specialist) Configure navigation.

Requirements:
- Set up React Navigation
- Create navigation structure
- Add stack/tab navigators
- Configure deep linking
- Add navigation types
```

---

## Phase 4: Authentication

**Goal:** Add mobile auth

**Actions:**

```
Task(mobile-auth-specialist) Set up authentication.

Requirements:
- Configure auth flow
- Add secure storage
- Set up biometrics
- Create auth screens
- Handle session management
```

---

## Phase 5: Data Layer

**Goal:** Set up data management

**Actions:**

```
Task(mobile-database-specialist) Configure data layer.

Requirements:
- Set up API client
- Configure offline storage
- Add state management
- Set up caching
- Handle sync
```

---

## Phase 6: UI Components

**Goal:** Create component library

**Actions:**

```
Task(responsive-design-specialist) Create UI components.

Requirements:
- Set up design system
- Create base components
- Add responsive layouts
- Configure theming
- Add animations
```

---

## Phase 7: Deployment

**Goal:** Prepare for app stores

**Actions:**

```
Task(app-store-deployer) Configure deployment.

Requirements:
- Set up EAS Build
- Configure app signing
- Create store assets
- Set up OTA updates
- Configure CI/CD
```

---

## Summary

**Output:**

```
✅ Mobile Application Complete

To add features:
  /mobile:add screen <name>            # Add screen
  /mobile:add auth <type>              # Add auth
  /mobile:add navigation <type>        # Add navigation
  /mobile:add pwa                      # PWA support
  /mobile:add deploy                   # App store deploy

To run:
  npx expo start
```
