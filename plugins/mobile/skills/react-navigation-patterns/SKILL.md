# react-navigation-patterns

Navigation patterns for React Native apps using Expo Router and React Navigation.

## Contents

- Expo Router file-based routing
- Stack, Tab, Drawer navigators
- Deep linking configuration
- Authentication flow patterns
- Navigation state persistence

## Usage

Reference this skill when implementing navigation in mobile apps.

## Key Patterns

### Expo Router Structure
- app/_layout.tsx for root navigation
- Route groups: (tabs), (auth), (drawer)
- Dynamic routes: [id].tsx
- Modal presentation

### React Navigation
- createStackNavigator for screen stacks
- createBottomTabNavigator for tabs
- createDrawerNavigator for side menus

### Auth Flow
- Protected route groups
- Redirect to login when unauthenticated
- Navigation after sign-in

## Security

Never pass sensitive data through navigation params.
