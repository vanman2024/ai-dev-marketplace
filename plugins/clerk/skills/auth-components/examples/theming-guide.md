# Clerk Theming and Appearance Guide

This guide demonstrates comprehensive theming options for Clerk components using the appearance prop.

## Overview

Clerk provides a powerful theming system that allows complete customization of authentication components through the `appearance` prop. This includes pre-built themes, CSS variables, and element-specific styling.

## Implementation

See `theme-config.tsx` for 9 complete theme configurations ready to use.

## Theming Approaches

### 1. Pre-built Themes

Use themes from `@clerk/themes`:

```typescript
import { dark, neobrutalist, shadesOfPurple } from '@clerk/themes'

<ClerkProvider appearance={{ baseTheme: dark }}>
```

**Available Themes:**
- `dark` - Professional dark mode
- `neobrutalist` - Bold brutalist design
- `shadesOfPurple` - Purple-themed design

### 2. CSS Variables

Customize with color and typography variables:

```typescript
appearance={{
  variables: {
    colorPrimary: '#6366f1',
    colorBackground: '#ffffff',
    colorText: '#1f2937',
    borderRadius: '0.5rem',
    fontFamily: 'system-ui'
  }
}}
```

### 3. Element-Specific Styling

Target specific UI elements:

```typescript
appearance={{
  elements: {
    card: 'shadow-lg border border-gray-200',
    formButtonPrimary: 'bg-blue-600 hover:bg-blue-700',
    formFieldInput: 'border-gray-300 focus:border-blue-500'
  }
}}
```

### 4. Layout Configuration

Adjust component layout:

```typescript
appearance={{
  layout: {
    shimmer: true,
    logoPlacement: 'inside',
    socialButtonsPlacement: 'bottom',
    socialButtonsVariant: 'blockButton'
  }
}}
```

## Available Variables

### Colors

```typescript
variables: {
  // Primary colors
  colorPrimary: '#6366f1',
  colorBackground: '#ffffff',
  colorText: '#1f2937',
  colorTextSecondary: '#6b7280',

  // State colors
  colorDanger: '#ef4444',
  colorSuccess: '#10b981',
  colorWarning: '#f59e0b',

  // Input colors
  colorInputBackground: '#ffffff',
  colorInputText: '#1f2937'
}
```

### Typography

```typescript
variables: {
  fontFamily: 'system-ui, sans-serif',
  fontSize: '1rem',
  fontWeight: {
    normal: 400,
    medium: 500,
    semibold: 600,
    bold: 700
  }
}
```

### Spacing & Borders

```typescript
variables: {
  spacingUnit: '1rem',
  borderRadius: '0.5rem'
}
```

## Common Element Selectors

### Container Elements

| Selector | Description |
|----------|-------------|
| `rootBox` | Outermost container |
| `card` | Main card wrapper |

### Header Elements

| Selector | Description |
|----------|-------------|
| `headerTitle` | Main header text |
| `headerSubtitle` | Subtitle text |

### Form Elements

| Selector | Description |
|----------|-------------|
| `formButtonPrimary` | Primary submit button |
| `formFieldInput` | Text input fields |
| `formFieldLabel` | Input field labels |

### Social Authentication

| Selector | Description |
|----------|-------------|
| `socialButtonsBlockButton` | OAuth provider buttons |

### User Button

| Selector | Description |
|----------|-------------|
| `userButtonAvatarBox` | User avatar container |
| `userButtonPopoverCard` | Dropdown menu |

### Footer Elements

| Selector | Description |
|----------|-------------|
| `footerActionLink` | Footer links (sign up, etc.) |

## Complete Theme Examples

### Professional Light Theme

```typescript
export const professionalLight: Appearance = {
  variables: {
    colorPrimary: '#2563eb',
    colorBackground: '#ffffff',
    colorText: '#0f172a',
    borderRadius: '0.375rem',
    fontFamily: '"Inter", system-ui, sans-serif'
  },
  elements: {
    card: 'shadow-xl border border-gray-200',
    formButtonPrimary: 'bg-blue-600 hover:bg-blue-700 font-semibold',
    formFieldInput: 'border-gray-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20'
  }
}
```

### Modern Dark Theme

```typescript
export const modernDark: Appearance = {
  baseTheme: dark,
  variables: {
    colorPrimary: '#818cf8',
    colorBackground: '#0f172a',
    colorText: '#f1f5f9',
    borderRadius: '0.5rem'
  },
  elements: {
    card: 'bg-slate-900 border border-slate-800 shadow-2xl',
    formButtonPrimary: 'bg-indigo-500 hover:bg-indigo-600',
    formFieldInput: 'bg-slate-800 border-slate-700 text-white'
  }
}
```

### Gradient Brand Theme

```typescript
export const gradientBrand: Appearance = {
  variables: {
    colorPrimary: '#8b5cf6',
    borderRadius: '0.75rem'
  },
  elements: {
    headerTitle: 'text-3xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent',
    formButtonPrimary: 'bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 shadow-lg'
  }
}
```

## Application Patterns

### 1. Global Application

Apply to all Clerk components:

```typescript
// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs'
import { myTheme } from '@/lib/clerk-themes'

export default function RootLayout({ children }) {
  return (
    <ClerkProvider appearance={myTheme}>
      <html>
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}
```

### 2. Component-Specific

Override for specific components:

```typescript
import { SignIn } from '@clerk/nextjs'
import { darkTheme } from '@/lib/clerk-themes'

export default function SignInPage() {
  return <SignIn appearance={darkTheme} />
}
```

### 3. Dynamic Theme Switching

Switch between light/dark:

```typescript
'use client'

import { ClerkProvider } from '@clerk/nextjs'
import { useTheme } from 'next-themes'
import { lightTheme, darkTheme } from '@/lib/clerk-themes'

export function ThemeProvider({ children }) {
  const { theme } = useTheme()

  return (
    <ClerkProvider
      appearance={theme === 'dark' ? darkTheme : lightTheme}
    >
      {children}
    </ClerkProvider>
  )
}
```

### 4. Responsive Themes

Mobile-first responsive styling:

```typescript
export const responsiveTheme: Appearance = {
  elements: {
    rootBox: 'w-full max-w-md mx-auto px-4 sm:px-0',
    headerTitle: 'text-xl sm:text-2xl md:text-3xl',
    formButtonPrimary: 'py-2.5 sm:py-3 text-sm sm:text-base'
  }
}
```

## Advanced Customization

### Combining Themes

```typescript
import { dark } from '@clerk/themes'

const customTheme: Appearance = {
  baseTheme: dark,  // Start with dark theme
  variables: {
    colorPrimary: '#8b5cf6'  // Override primary color
  },
  elements: {
    card: 'custom-card-class'  // Add custom styling
  }
}
```

### CSS Layer Names (Tailwind v4)

```typescript
<ClerkProvider
  appearance={{
    ...myTheme,
    cssLayerName: 'clerk'  // Ensures Tailwind utilities override
  }}
>
```

### Conditional Styling

```typescript
const getTheme = (variant: 'light' | 'dark' | 'brand'): Appearance => {
  switch (variant) {
    case 'dark':
      return darkTheme
    case 'brand':
      return brandTheme
    default:
      return lightTheme
  }
}
```

## Best Practices

1. **Start with Pre-built Themes**: Use `@clerk/themes` as base, customize from there
2. **Use CSS Variables**: Prefer `variables` for colors and typography
3. **Element Overrides for Details**: Use `elements` for fine-grained control
4. **Maintain Consistency**: Apply global theme via `ClerkProvider`
5. **Test Dark Mode**: Ensure theme works in both light and dark modes
6. **Mobile Responsive**: Use responsive classes in element selectors
7. **Accessibility**: Maintain sufficient color contrast (WCAG AA: 4.5:1)
8. **Performance**: Avoid heavy CSS in `elements` prop

## Troubleshooting

### Styles Not Applying

1. Check `cssLayerName` for Tailwind conflicts
2. Verify class names in `elements` are valid
3. Ensure `@clerk/themes` is installed for pre-built themes
4. Check for CSS specificity conflicts

### Theme Not Switching

1. Verify `appearance` prop is passed correctly
2. Check theme provider re-renders on change
3. Ensure no cached styles

### Variables Not Working

1. Confirm variable names match Clerk's schema
2. Check color format (hex, rgb, hsl all supported)
3. Verify `borderRadius` units

## Resources

- Complete themes: `theme-config.tsx`
- [Clerk Appearance Documentation](https://clerk.com/docs/customization/overview)
- [CSS Variables Reference](https://clerk.com/docs/customization/variables)
- [Element Reference](https://clerk.com/docs/customization/elements)
- [Pre-built Themes](https://clerk.com/docs/customization/themes)
- [Layout Configuration](https://clerk.com/docs/customization/layout)
