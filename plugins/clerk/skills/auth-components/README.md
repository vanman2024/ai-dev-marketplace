# Clerk Auth Components Skill

Pre-built and custom authentication component templates with comprehensive theming and customization patterns for Clerk.

## Overview

This skill provides everything needed to implement beautiful, customizable authentication UI with Clerk, including:

- **Pre-built Components**: Ready-to-use SignIn, SignUp, UserButton components
- **Custom Components**: Clerk Elements for complete control
- **Theming System**: 9+ pre-configured themes with full customization
- **Scripts**: Automated generation of auth pages and theme configs
- **Templates**: Production-ready component templates
- **Examples**: Real-world implementations with OAuth, custom flows, and advanced theming

## Quick Start

### 1. Generate Authentication Pages

```bash
# Generate complete auth UI (recommended)
./scripts/generate-auth-ui.sh ./app all

# Generate only sign-in page
./scripts/generate-auth-ui.sh ./app signin

# Generate sign-in and sign-up
./scripts/generate-auth-ui.sh ./app both
```

### 2. Apply Theme Configuration

```bash
# Generate dark theme
./scripts/customize-appearance.sh ./lib/clerk-config.ts dark

# Generate custom theme with brand colors
BRAND_COLOR="#8b5cf6" ./scripts/customize-appearance.sh ./lib/clerk-config.ts custom

# Use pre-built themes
./scripts/customize-appearance.sh ./lib/clerk-config.ts neobrutalist
```

### 3. Apply to Your App

```typescript
// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs'
import { clerkAppearance } from '@/lib/clerk-config'

export default function RootLayout({ children }) {
  return (
    <ClerkProvider appearance={clerkAppearance}>
      <html>
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}
```

## Directory Structure

```
auth-components/
├── SKILL.md                          # Skill documentation
├── README.md                         # This file
├── scripts/
│   ├── generate-auth-ui.sh          # Generate auth pages
│   └── customize-appearance.sh       # Generate theme configs
├── templates/
│   ├── sign-in-page.tsx             # SignIn page template
│   ├── sign-up-page.tsx             # SignUp page template
│   ├── user-button-custom.tsx       # UserButton with custom menu
│   └── protected-wrapper.tsx        # Route protection HOC
└── examples/
    ├── custom-sign-in.tsx           # Custom sign-in with Elements
    ├── social-buttons.tsx           # OAuth provider buttons
    └── theme-config.tsx             # 9 theme configurations
```

## Available Scripts

### `generate-auth-ui.sh`

Generates authentication UI pages with proper routing.

**Usage:**
```bash
./scripts/generate-auth-ui.sh <output-dir> <component-type>
```

**Component Types:**
- `signin` - Sign-in page only
- `signup` - Sign-up page only
- `both` - Both sign-in and sign-up
- `profile` - User profile page
- `all` - Complete auth UI set (recommended)

**Generated Files:**
- `app/sign-in/[[...sign-in]]/page.tsx`
- `app/sign-up/[[...sign-up]]/page.tsx`
- `app/profile/[[...profile]]/page.tsx`
- `components/auth/protected-wrapper.tsx`

### `customize-appearance.sh`

Generates theme configuration files.

**Usage:**
```bash
./scripts/customize-appearance.sh <config-file> <theme-preset>
```

**Theme Presets:**
- `default` - Clean, modern light theme
- `dark` - Professional dark theme
- `neobrutalist` - Bold, brutalist design
- `shadesOfPurple` - Purple-themed design
- `custom` - Custom theme with environment variables

**Environment Variables (for custom theme):**
- `BRAND_COLOR` - Primary brand color (default: #6366f1)
- `BACKGROUND` - Background color (default: #ffffff)
- `TEXT_COLOR` - Text color (default: #1f2937)

**Example:**
```bash
BRAND_COLOR="#8b5cf6" BACKGROUND="#fafafa" ./scripts/customize-appearance.sh ./lib/clerk-config.ts custom
```

## Templates

### 1. Sign-In Page (`sign-in-page.tsx`)

Production-ready sign-in page with:
- Centered layout with responsive design
- Custom appearance configuration
- After sign-in redirect
- Social authentication support

### 2. Sign-Up Page (`sign-up-page.tsx`)

Production-ready sign-up page with:
- Matching design to sign-in
- After sign-up redirect
- Social authentication support

### 3. Custom User Button (`user-button-custom.tsx`)

Three UserButton variants:
- **CustomUserButton**: With custom menu items (Dashboard, Settings, Billing, Help)
- **SimpleUserButton**: Minimal version with basic styling
- **LargeUserButton**: Larger avatar for headers

### 4. Protected Wrapper (`protected-wrapper.tsx`)

Route protection utilities:
- **ProtectedRoute**: Component wrapper for protected pages
- **withProtectedRoute**: HOC for protected components
- **RoleProtectedRoute**: Role-based access control

## Examples

### Custom Sign-In (`custom-sign-in.tsx`)

Complete custom sign-in implementation using Clerk Elements:
- Full control over UI and flow
- Multi-step authentication
- Password and email code strategies
- OAuth provider integration
- Forgot password flow
- Custom styling and branding

**Key Features:**
- Step-based flow (start, verifications, choose-strategy, forgot-password, reset-password)
- Strategy selection (password, email code, OAuth)
- Custom form validation
- Loading states
- Error handling

### Social Buttons (`social-buttons.tsx`)

OAuth provider integration examples:
- **SocialAuthButtons**: Full-width buttons with icons and labels
- **CompactSocialButtons**: Icon-only buttons for headers
- **SocialButtonGrid**: 2x2 grid layout

**Supported Providers:**
- Google
- GitHub
- Discord
- Microsoft
- Facebook
- Apple

**Features:**
- Loading states
- Error handling
- Custom redirect URLs
- Custom styling per provider

### Theme Configuration (`theme-config.tsx`)

9 complete theme configurations:

1. **Light Theme**: Default clean, modern light theme
2. **Dark Theme**: Professional dark mode with @clerk/themes
3. **Brand Theme**: Custom purple brand with gradient effects
4. **Minimal Theme**: Clean, minimal black and white
5. **Neobrutalist**: Bold brutalist design with heavy borders
6. **Purple Theme**: Shades of Purple preset
7. **Glassmorphism**: Modern glass effect with blur
8. **Responsive Theme**: Mobile-first responsive design
9. **Custom Theme**: Template for building your own

**Usage Examples:**
- Global application via ClerkProvider
- Component-specific themes
- Dynamic theme switching (light/dark)
- Tailwind CSS v4 integration

## Customization Guide

### Appearance Prop Structure

```typescript
appearance={{
  baseTheme: dark,           // Pre-built theme
  layout: {                  // Layout options
    shimmer: true,
    logoPlacement: 'inside',
    socialButtonsPlacement: 'bottom'
  },
  variables: {               // CSS variables
    colorPrimary: '#6366f1',
    colorBackground: '#ffffff',
    borderRadius: '0.5rem',
    fontFamily: 'system-ui'
  },
  elements: {                // Element-specific styles
    card: 'shadow-lg',
    formButtonPrimary: 'bg-blue-500',
    formFieldInput: 'border-gray-300'
  }
}}
```

### Common Element Selectors

- `rootBox` - Root container
- `card` - Main card wrapper
- `headerTitle` - Header text
- `headerSubtitle` - Subtitle text
- `formButtonPrimary` - Primary buttons
- `formFieldInput` - Input fields
- `formFieldLabel` - Input labels
- `socialButtonsBlockButton` - Social OAuth buttons
- `footerActionLink` - Footer links
- `userButtonAvatarBox` - User avatar
- `userButtonPopoverCard` - Dropdown menu

### Tailwind CSS Integration

For Tailwind CSS v4, set the CSS layer name:

```typescript
<ClerkProvider
  appearance={{
    cssLayerName: 'clerk',  // Ensures Tailwind utilities override
    ...yourTheme
  }}
>
```

## Environment Setup

Required environment variables:

```bash
# .env.local
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_key_here
CLERK_SECRET_KEY=sk_test_your_key_here

# Optional: Custom sign-in/sign-up URLs
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/onboarding
```

## Best Practices

1. **Start with Pre-built Components**: Use `<SignIn />` and `<SignUp />` before building custom flows
2. **Apply Global Themes**: Configure appearance at `<ClerkProvider>` for consistency
3. **Use CSS Variables**: Customize with `variables` prop for easy brand alignment
4. **Element Overrides for Fine-Tuning**: Use `elements` prop for specific styling needs
5. **Protect Routes Properly**: Always wrap protected content in authentication checks
6. **Handle Loading States**: Show indicators during auth state transitions
7. **Configure Redirects**: Set appropriate redirect URLs for better UX
8. **Test Responsive Design**: Verify components work on mobile and desktop

## Dependencies

- `@clerk/nextjs` - Clerk Next.js SDK
- `@clerk/types` - TypeScript types
- `@clerk/themes` - Pre-built themes (optional)
- `@clerk/elements` - Custom component primitives (for advanced customization)
- Next.js 13+ with App Router
- React 18+
- Tailwind CSS (recommended for styling)

## Resources

- [Clerk Documentation](https://clerk.com/docs)
- [Clerk Components Reference](https://clerk.com/docs/components/overview)
- [Clerk Appearance Customization](https://clerk.com/docs/customization/overview)
- [Clerk Elements Guide](https://clerk.com/docs/customization/elements)
- [Clerk Themes Package](https://clerk.com/docs/customization/themes)

## Security

- All examples use placeholder API keys
- Environment variables required for real keys
- No hardcoded secrets in templates
- Protected route wrappers included
- OAuth redirect validation built-in

## Support

For issues or questions:
- Clerk Discord: [Join Server](https://clerk.com/discord)
- Clerk Support: support@clerk.com
- GitHub Issues: [Report Issue](https://github.com/clerk/clerk-docs/issues)
