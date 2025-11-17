# Custom Sign-In Implementation Guide

This guide demonstrates how to build a completely custom sign-in flow using Clerk Elements.

## Overview

Clerk Elements provides granular control over the authentication UI, allowing you to create fully branded sign-in experiences while maintaining all of Clerk's security and functionality.

## Implementation

See `custom-sign-in.tsx` for the complete implementation.

## Key Features

### Multi-Step Flow

The custom sign-in implementation uses a step-based approach:

1. **Start Step**: Email/username input with social OAuth buttons
2. **Verifications Step**: Password or email code verification
3. **Choose Strategy Step**: Select verification method
4. **Forgot Password Step**: Request password reset
5. **Reset Password Step**: Create new password

### Authentication Strategies

```typescript
// Password authentication
<SignIn.Strategy name="password">
  <SignIn.Input type="password" name="password" />
  <SignIn.Action submit>Sign in</SignIn.Action>
</SignIn.Strategy>

// Email code authentication
<SignIn.Strategy name="email_code">
  <SignIn.Action submit>Send code</SignIn.Action>
  <SignIn.Input type="text" name="code" />
</SignIn.Strategy>

// OAuth authentication
<SignIn.Strategy name="oauth_google">
  <button>Continue with Google</button>
</SignIn.Strategy>
```

## Customization Points

### Styling

All elements support custom className for complete styling control:

```typescript
<SignIn.Input
  className="w-full px-4 py-3 border rounded-lg focus:ring-2"
/>
```

### Branding

- Custom logo placement
- Brand colors throughout
- Custom form layouts
- Tailored messaging

### Navigation

Control flow between steps:

```typescript
<SignIn.Action navigate="forgot-password">
  Forgot password?
</SignIn.Action>
```

## When to Use Custom Sign-In

**Use Custom Sign-In When:**
- You need complete control over UI/UX
- Matching existing design system
- Custom form validation
- Multi-step flows with custom logic
- Unique branding requirements

**Use Pre-built Component When:**
- Quick implementation needed
- Standard auth flow is sufficient
- Minimal customization required
- Using Clerk's default theming

## Setup Steps

1. **Install Clerk Elements**:
```bash
npm install @clerk/elements
```

2. **Import Components**:
```typescript
import * as SignIn from '@clerk/elements/sign-in'
```

3. **Wrap with SignIn.Root**:
```typescript
<SignIn.Root>
  {/* Your custom UI */}
</SignIn.Root>
```

4. **Implement Steps**:
```typescript
<SignIn.Step name="start">
  {/* Start step UI */}
</SignIn.Step>
```

## Best Practices

1. **Progressive Enhancement**: Start with pre-built components, customize as needed
2. **Error Handling**: Display validation errors clearly
3. **Loading States**: Show progress during authentication
4. **Accessibility**: Maintain proper labels and ARIA attributes
5. **Mobile Responsive**: Test on all device sizes
6. **Social OAuth**: Provide multiple authentication options
7. **Security**: Never bypass Clerk's security features for UI customization

## Example: Minimal Custom Sign-In

```typescript
import * as SignIn from '@clerk/elements/sign-in'

export default function MinimalSignIn() {
  return (
    <SignIn.Root>
      <SignIn.Step name="start">
        <SignIn.Input type="text" name="identifier" />
        <SignIn.Action submit>Continue</SignIn.Action>
      </SignIn.Step>

      <SignIn.Step name="verifications">
        <SignIn.Strategy name="password">
          <SignIn.Input type="password" name="password" />
          <SignIn.Action submit>Sign in</SignIn.Action>
        </SignIn.Strategy>
      </SignIn.Step>
    </SignIn.Root>
  )
}
```

## Framework Support

Clerk Elements currently supports:
- Next.js App Router
- Clerk Core 2

Additional framework support coming soon.

## Resources

- Full implementation: `custom-sign-in.tsx`
- [Clerk Elements Documentation](https://clerk.com/docs/customization/elements)
- [Sign-In Element Reference](https://clerk.com/docs/customization/elements/reference/sign-in)
- [Sign-In Guide](https://clerk.com/docs/customization/elements/guides/sign-in)
