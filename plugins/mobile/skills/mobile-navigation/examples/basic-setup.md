# Basic Navigation Setup

## Install Dependencies

```bash
./scripts/setup-navigation.sh
```

## Copy Templates

```bash
cp templates/root-layout.tsx app/_layout.tsx
cp templates/tabs-layout.tsx app/(tabs)/_layout.tsx
cp templates/navigation-types.ts types/navigation.ts
```

## Create Tab Screens

Create `app/(tabs)/index.tsx` and `app/(tabs)/profile.tsx` with your content.
