---
description: Build complete mobile app - initializes if needed, then runs specialized agents for React Native/Expo, navigation, auth, database, and deployment
argument-hint: <project-name> [--platform <expo|pwa|responsive>]
---

# Build Complete Mobile Application

**Goal:** Create a production-ready mobile application by orchestrating all specialized agents.

**This command handles everything** - from setup to full app with navigation, auth, database integration, and app store deployment.

## Stack (Always Use Latest Versions)

- **Expo** - Latest SDK with React Native
- **React Navigation** / **Expo Router** - Latest routing
- **Clerk** - Latest for mobile auth
- **Supabase** - Latest for mobile database
- **EAS Build** - Latest for deployment

**IMPORTANT:** Always use the latest SDK versions. Check `npx expo --version` and `npm info` for current versions.

## Arguments

- `$ARGUMENTS` - Project name and optional platform
- `--platform <name>` - Target platform (expo, pwa, responsive)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and platform
2. Discover architecture documentation for app requirements
3. Plan mobile architecture based on features needed
4. Determine navigation structure

### Phase 2: Project Setup

```
Task("Setup mobile project", @expo-specialist, {
  prompt: "Initialize mobile project:
    - Create Expo project (latest SDK)
    - Configure TypeScript
    - Set up project structure
    - Install core dependencies
    Use Expo Router for file-based routing."
})
```

### Phase 3: Parallel Agent Execution

```
// Agent 1: Architecture
Task("Design architecture", @mobile-architect, {
  prompt: "Design mobile architecture:
    - Define screen structure from architecture docs
    - Plan state management
    - Design API integration patterns
    - Configure offline support if needed
    Create app foundation."
})

// Agent 2: Navigation
Task("Build navigation", @mobile-navigation-specialist, {
  prompt: "Implement navigation:
    - Configure Expo Router or React Navigation
    - Create navigation structure from architecture
    - Implement tab/stack/drawer navigation
    - Add deep linking support
    Follow screen structure from architecture."
})

// Agent 3: Authentication
Task("Setup auth", @mobile-auth-specialist, {
  prompt: "Implement mobile authentication:
    - Configure Clerk for React Native
    - Create sign in/sign up screens
    - Handle auth state persistence
    - Add biometric authentication if specified
    Follow auth requirements from architecture."
})

// Agent 4: Database Integration
Task("Setup database", @mobile-database-specialist, {
  prompt: "Integrate Supabase:
    - Configure Supabase client for mobile
    - Implement offline-first storage
    - Add real-time subscriptions
    - Configure secure storage
    Follow data requirements from architecture."
})

// Agent 5: Responsive/PWA (if applicable)
Task("Add responsive/PWA", @responsive-design-specialist, {
  prompt: "Implement responsive features if web target:
    - Configure responsive layouts
    - Add PWA manifest
    - Implement service worker
    - Handle platform detection
    Skip if native-only target."
})
```

### Phase 4: Deployment Configuration

```
Task("Configure deployment", @app-store-deployer, {
  prompt: "Prepare app store deployment:
    - Configure EAS Build
    - Set up app.json/app.config.js
    - Create build profiles (dev, preview, production)
    - Configure code signing
    Output deployment documentation."
})
```

### Phase 5: Final Output

**Provide summary:**
- App screens implemented
- Navigation structure
- Run commands:
  ```bash
  # Start development
  npx expo start
  
  # Build preview
  eas build --platform all --profile preview
  
  # Submit to stores
  eas submit --platform ios
  ```

## Utility Commands

- `/mobile:add-navigation` - Add navigation only
- `/mobile:add-auth` - Add mobile auth
- `/mobile:add-database` - Add Supabase integration
- `/mobile:add-pwa` - Convert to PWA
- `/mobile:deploy` - Configure app store deployment
