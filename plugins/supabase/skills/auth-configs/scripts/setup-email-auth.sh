#!/bin/bash

# setup-email-auth.sh - Configure email authentication with PKCE flow for Supabase
# Usage: ./setup-email-auth.sh [--magic-link] [--password] [--both]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

show_email_auth_overview() {
    cat <<EOF
${BLUE}Email Authentication Configuration${NC}

Supabase supports two primary email authentication methods:

${GREEN}1. Magic Link (Passwordless)${NC}
   - User receives email with one-time login link
   - No password to remember or manage
   - More secure (no password to steal)
   - Better user experience for non-technical users
   - Requires email delivery reliability

${GREEN}2. Email + Password${NC}
   - Traditional authentication method
   - User creates and manages password
   - Works offline after initial login
   - Familiar to most users
   - Requires password strength requirements

${GREEN}3. Combined Approach (Recommended for AI Apps)${NC}
   - Offer both methods for user choice
   - Magic link for quick access
   - Password for offline-capable apps
   - Best of both worlds

${YELLOW}PKCE Flow for SSR:${NC}

PKCE (Proof Key for Code Exchange) is REQUIRED for server-side
rendering (SSR) applications like Next.js, SvelteKit, Remix.

It prevents authorization code interception attacks by:
- Generating code verifier/challenge pairs
- Validating the exchange on the backend
- Storing session in secure HTTP-only cookies

EOF
}

prompt_auth_method() {
    echo ""
    print_info "Select email authentication method:"
    echo ""
    echo "  1) Magic Link only (passwordless)"
    echo "  2) Email + Password only"
    echo "  3) Both methods (recommended)"
    echo ""
    read -p "Enter choice [3]: " choice
    choice=${choice:-3}

    case $choice in
        1) echo "magic-link" ;;
        2) echo "password" ;;
        3) echo "both" ;;
        *) echo "both" ;;
    esac
}

prompt_pkce_config() {
    echo ""
    print_info "Configure PKCE flow for SSR:"
    echo ""
    read -p "Is this a server-side rendered app (Next.js, SvelteKit, etc)? [Y/n]: " is_ssr
    is_ssr=${is_ssr:-y}

    if [ "$is_ssr" = "y" ]; then
        echo ""
        print_info "PKCE flow will be enabled (required for SSR)"
        echo "pkce"
    else
        echo ""
        print_warning "Client-side apps should still use PKCE for security"
        read -p "Enable PKCE anyway? [Y/n]: " enable_pkce
        enable_pkce=${enable_pkce:-y}
        if [ "$enable_pkce" = "y" ]; then
            echo "pkce"
        else
            echo "implicit"
        fi
    fi
}

create_email_config() {
    local auth_method=$1
    local flow_type=$2
    local config_file="email-auth-config.json"

    cat > "$config_file" <<EOF
{
  "emailAuth": {
    "magicLink": $([ "$auth_method" = "magic-link" ] || [ "$auth_method" = "both" ] && echo "true" || echo "false"),
    "password": $([ "$auth_method" = "password" ] || [ "$auth_method" = "both" ] && echo "true" || echo "false"),
    "emailConfirmation": true,
    "flowType": "$flow_type"
  },
  "passwordRequirements": {
    "minimumLength": 8,
    "requireUppercase": true,
    "requireLowercase": true,
    "requireNumbers": true,
    "requireSpecialChars": false
  },
  "emailSettings": {
    "confirmationRequired": true,
    "allowUnconfirmedLogin": false,
    "magicLinkExpiration": "1 hour",
    "passwordResetExpiration": "1 hour",
    "emailChangeConfirmation": true
  },
  "security": {
    "pkceEnabled": $([ "$flow_type" = "pkce" ] && echo "true" || echo "false"),
    "sessionStorage": "cookie",
    "cookieOptions": {
      "httpOnly": true,
      "secure": true,
      "sameSite": "lax",
      "maxAge": 604800
    }
  },
  "redirects": {
    "afterSignIn": "/dashboard",
    "afterSignUp": "/onboarding",
    "afterPasswordReset": "/login",
    "afterEmailConfirm": "/welcome"
  }
}
EOF

    print_success "Email authentication config saved to $config_file"
}

copy_email_templates() {
    local templates_src="$TEMPLATES_DIR/email-templates"
    local templates_dest="./email-templates"

    if [ -d "$templates_src" ]; then
        print_info "Copying email templates..."
        cp -r "$templates_src" "$templates_dest"
        print_success "Email templates copied to $templates_dest"

        echo ""
        print_info "Customize these templates for your brand:"
        echo "  - confirmation.html (email verification)"
        echo "  - magic-link.html (passwordless login)"
        echo "  - password-reset.html (forgot password)"
        echo "  - invite.html (team invitations)"
    fi
}

create_ssr_middleware_config() {
    local flow_type=$1

    if [ "$flow_type" != "pkce" ]; then
        return
    fi

    print_info "Creating SSR middleware configuration..."

    local middleware_file="auth-middleware-config.ts"

    cat > "$middleware_file" <<'EOF'
// auth-middleware-config.ts
// Configuration for Supabase SSR authentication middleware

import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          request.cookies.set({
            name,
            value,
            ...options,
          })
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value,
            ...options,
          })
        },
        remove(name: string, options: CookieOptions) {
          request.cookies.set({
            name,
            value: '',
            ...options,
          })
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value: '',
            ...options,
          })
        },
      },
    }
  )

  // Refresh session if expired
  await supabase.auth.getUser()

  return response
}

// Protected routes configuration
export const protectedRoutes = [
  '/dashboard',
  '/profile',
  '/settings',
  '/api/protected',
]

// Public routes that require redirect if authenticated
export const authRoutes = [
  '/login',
  '/signup',
  '/reset-password',
]
EOF

    print_success "SSR middleware config created: $middleware_file"
}

show_implementation_guide() {
    local auth_method=$1
    local flow_type=$2

    cat <<EOF

${BLUE}Implementation Guide${NC}

${GREEN}1. Install Dependencies${NC}

npm install @supabase/supabase-js @supabase/ssr

# Or with yarn
yarn add @supabase/supabase-js @supabase/ssr

${GREEN}2. Environment Variables${NC}

Add to .env.local:

NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

EOF

    if [ "$auth_method" = "magic-link" ] || [ "$auth_method" = "both" ]; then
        cat <<'EOF'
${GREEN}3. Magic Link Authentication${NC}

// Sign in with magic link
const { data, error } = await supabase.auth.signInWithOtp({
  email: 'user@example.com',
  options: {
    emailRedirectTo: 'https://yourapp.com/auth/callback',
  },
})

// Handle callback in /auth/callback route
// The user is automatically signed in when clicking the magic link

EOF
    fi

    if [ "$auth_method" = "password" ] || [ "$auth_method" = "both" ]; then
        cat <<'EOF'
${GREEN}4. Email + Password Authentication${NC}

// Sign up
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'securePassword123',
  options: {
    emailRedirectTo: 'https://yourapp.com/auth/callback',
  },
})

// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'securePassword123',
})

// Password reset
const { data, error } = await supabase.auth.resetPasswordForEmail(
  'user@example.com',
  {
    redirectTo: 'https://yourapp.com/reset-password',
  }
)

EOF
    fi

    if [ "$flow_type" = "pkce" ]; then
        cat <<'EOF'
${GREEN}5. SSR Middleware Setup (PKCE Flow)${NC}

Create middleware.ts in your Next.js root:

import { updateSession } from './auth-middleware-config'

export async function middleware(request: NextRequest) {
  return await updateSession(request)
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}

${GREEN}6. Server Component Example${NC}

import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'

export default async function ServerComponent() {
  const supabase = createServerComponentClient({ cookies })
  const { data: { session } } = await supabase.auth.getSession()

  if (!session) {
    redirect('/login')
  }

  return <div>Welcome, {session.user.email}</div>
}

EOF
    fi

    cat <<EOF

${GREEN}7. Email Template Customization${NC}

Customize templates in Supabase Dashboard:
  Authentication > Email Templates

Or use the templates in ./email-templates/ directory

${GREEN}8. Testing${NC}

Test your setup:
  bash $(dirname "$SCRIPT_DIR")/scripts/test-auth-flow.sh --email

${YELLOW}Security Notes:${NC}

- Enable email confirmation in production
- Use strong password requirements
- Implement rate limiting on auth endpoints
- Monitor for suspicious login patterns
- Regularly rotate JWT secrets

EOF
}

main() {
    local auth_method="both"
    local flow_type="pkce"

    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --magic-link)
                auth_method="magic-link"
                ;;
            --password)
                auth_method="password"
                ;;
            --both)
                auth_method="both"
                ;;
            --help)
                echo "Usage: $0 [--magic-link|--password|--both]"
                echo ""
                echo "Options:"
                echo "  --magic-link   Configure magic link only"
                echo "  --password     Configure password auth only"
                echo "  --both         Configure both methods (default)"
                exit 0
                ;;
        esac
    done

    echo ""
    print_info "Email Authentication Setup for Supabase"
    echo ""

    # Show overview
    show_email_auth_overview

    # Prompt for auth method if not specified
    if [ $# -eq 0 ]; then
        auth_method=$(prompt_auth_method)
    fi

    # Prompt for PKCE configuration
    flow_type=$(prompt_pkce_config)

    # Create configuration
    create_email_config "$auth_method" "$flow_type"

    # Copy email templates
    copy_email_templates

    # Create SSR middleware if PKCE enabled
    create_ssr_middleware_config "$flow_type"

    # Show implementation guide
    show_implementation_guide "$auth_method" "$flow_type"

    # Summary
    echo ""
    print_success "Email authentication setup complete!"
    echo ""
    print_info "Configuration Summary:"
    echo "  Auth Method: $auth_method"
    echo "  Flow Type: $flow_type"
    echo "  Email Templates: ./email-templates/"
    if [ "$flow_type" = "pkce" ]; then
        echo "  SSR Middleware: auth-middleware-config.ts"
    fi
    echo ""
    print_info "Next steps:"
    echo "  1. Configure email settings in Supabase Dashboard"
    echo "  2. Customize email templates (./email-templates/)"
    echo "  3. Implement authentication in your app (see guide above)"
    echo "  4. Test the flow: bash $(dirname "$SCRIPT_DIR")/scripts/test-auth-flow.sh"
    echo ""
}

main "$@"
