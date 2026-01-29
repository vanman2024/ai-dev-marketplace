---
description: Add a specific feature to an existing mobile project. Features include screen, auth, navigation, database, pwa, deploy.
argument-hint: <feature> [options]
---

# Add Mobile Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Screen Features

**If `$0` = "screen":**

```
Task(expo-specialist) Add SCREEN.

Requirements:
- Screen name: $1 (required)
- Screen type: $2 (list, detail, form, modal - default: basic)
- Create screen component
- Add to navigation
- Set up types
- Add base layout
```

**If `$0` = "component":**

```
Task(responsive-design-specialist) Add COMPONENT.

Requirements:
- Component name: $1 (required)
- Component type: $2 (button, card, input, list - default: basic)
- Create component file
- Add styling
- Set up props
- Add variants
```

### Navigation Features

**If `$0` = "navigation":**

```
Task(mobile-navigation-specialist) Add NAVIGATION.

Requirements:
- Nav type: $1 (stack, tabs, drawer, modal - required)
- Screens: $2 (comma-separated screen names)
- Create navigator
- Configure routes
- Add types
- Set up deep links
```

### Auth Features

**If `$0` = "auth":**

```
Task(mobile-auth-specialist) Add AUTHENTICATION.

Requirements:
- Auth type: $1 (clerk, supabase, firebase, custom - default: clerk)
- Features: $2 (biometrics, social, mfa - default: basic)
- Set up auth provider
- Create auth screens
- Add secure storage
- Configure session
```

### Data Features

**If `$0` = "database":**

```
Task(mobile-database-specialist) Add DATABASE.

Requirements:
- Database type: $1 (supabase, firebase, sqlite, realm - default: supabase)
- Offline: $2 (true/false - default: true)
- Set up database client
- Configure offline storage
- Add sync logic
- Create hooks
```

**If `$0` = "api":**

```
Task(mobile-database-specialist) Add API client.

Requirements:
- API type: $1 (rest, graphql, trpc - default: rest)
- Create API client
- Add request hooks
- Configure caching
- Set up error handling
```

### PWA Features

**If `$0` = "pwa":**

```
Task(pwa-specialist) Add PWA support.

Requirements:
- Features: $1 (offline, push, install - default: all)
- Configure service worker
- Add manifest
- Set up offline support
- Add install prompt
```

### Deployment Features

**If `$0` = "deploy":**

```
Task(app-store-deployer) Add DEPLOYMENT.

Requirements:
- Platform: $1 (ios, android, both - default: both)
- Service: $2 (eas, manual - default: eas)
- Configure EAS Build
- Set up app signing
- Create store metadata
- Configure CI/CD
```

---

## Usage Examples

```bash
# Screens & Components
/mobile:add screen Home list
/mobile:add screen Profile detail
/mobile:add component Button

# Navigation
/mobile:add navigation tabs Home,Profile,Settings
/mobile:add navigation stack Auth,Login,Register

# Auth
/mobile:add auth clerk biometrics
/mobile:add auth supabase social

# Data
/mobile:add database supabase true
/mobile:add api rest

# PWA & Deploy
/mobile:add pwa offline
/mobile:add deploy both eas
```

---

## Feature Reference

| Feature      | Agent                 | $1 Options                     | Description      |
| ------------ | --------------------- | ------------------------------ | ---------------- |
| `screen`     | expo-specialist       | screen-name (required)         | New screen       |
| `component`  | design-specialist     | component-name (required)      | UI component     |
| `navigation` | navigation-specialist | stack/tabs/drawer/modal        | Navigation setup |
| `auth`       | auth-specialist       | clerk/supabase/firebase/custom | Authentication   |
| `database`   | database-specialist   | supabase/firebase/sqlite/realm | Database setup   |
| `api`        | database-specialist   | rest/graphql/trpc              | API client       |
| `pwa`        | pwa-specialist        | offline/push/install/all       | PWA features     |
| `deploy`     | app-store-deployer    | ios/android/both               | App store deploy |
