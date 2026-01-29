# Responsive Design Setup

## Copy Utilities

```bash
cp templates/responsive.ts lib/responsive.ts
cp templates/safe-view.tsx components/SafeView.tsx
```

## Usage

```typescript
import { wp, hp, moderateScale, isTablet } from '@/lib/responsive';
import { SafeView } from '@/components/SafeView';

export default function Screen() {
  return (
    <SafeView>
      <View style={{ padding: wp(4), marginTop: hp(2) }}>
        <Text style={{ fontSize: moderateScale(16) }}>
          Responsive text
        </Text>
      </View>
    </SafeView>
  );
}
```
