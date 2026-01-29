# Basic Expo Setup Example

## Create New Project

```bash
./scripts/init-expo-project.sh my-mobile-app
cd my-mobile-app
```

## Configure Environment

```bash
cp .env.example .env.local
# Edit .env.local with your values
```

## Run Development

```bash
npx expo start
# Press 'i' for iOS simulator
# Press 'a' for Android emulator
```

## Build for Testing

```bash
eas build --platform ios --profile development
eas build --platform android --profile preview
```
