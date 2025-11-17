#!/bin/bash
# Generate Clerk appearance configuration
# Usage: ./customize-appearance.sh <config-file> <theme-preset>

set -euo pipefail

CONFIG_FILE="${1:-./lib/clerk-config.ts}"
THEME_PRESET="${2:-default}"

# Environment variables for custom theme
BRAND_COLOR="${BRAND_COLOR:-#6366f1}"
BACKGROUND="${BACKGROUND:-#ffffff}"
TEXT_COLOR="${TEXT_COLOR:-#1f2937}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Create config directory
CONFIG_DIR="$(dirname "$CONFIG_FILE")"
mkdir -p "$CONFIG_DIR"

echo "=== Clerk Appearance Customization ==="
echo "Config file: $CONFIG_FILE"
echo "Theme preset: $THEME_PRESET"
echo ""

case "$THEME_PRESET" in
    default)
        cat > "$CONFIG_FILE" <<'EOF'
import { Appearance } from '@clerk/types'

export const clerkAppearance: Appearance = {
  layout: {
    shimmer: true,
    logoPlacement: 'inside'
  },
  variables: {
    colorPrimary: '#6366f1',
    colorBackground: '#ffffff',
    colorText: '#1f2937',
    colorTextSecondary: '#6b7280',
    colorDanger: '#ef4444',
    borderRadius: '0.5rem',
    fontFamily: 'system-ui, -apple-system, sans-serif'
  }
}
EOF
        log_info "Generated default theme configuration"
        ;;

    dark)
        cat > "$CONFIG_FILE" <<'EOF'
import { Appearance } from '@clerk/types'
import { dark } from '@clerk/themes'

export const clerkAppearance: Appearance = {
  baseTheme: dark,
  layout: {
    shimmer: true,
    logoPlacement: 'inside'
  },
  variables: {
    colorPrimary: '#818cf8',
    colorBackground: '#111827',
    colorText: '#f9fafb',
    colorTextSecondary: '#9ca3af',
    colorDanger: '#f87171',
    borderRadius: '0.5rem'
  }
}
EOF
        log_info "Generated dark theme configuration"
        log_warn "Install @clerk/themes: npm install @clerk/themes"
        ;;

    neobrutalist)
        cat > "$CONFIG_FILE" <<'EOF'
import { Appearance } from '@clerk/types'
import { neobrutalist } from '@clerk/themes'

export const clerkAppearance: Appearance = {
  baseTheme: neobrutalist,
  variables: {
    colorPrimary: '#000000',
    borderRadius: '0rem'
  }
}
EOF
        log_info "Generated neobrutalist theme configuration"
        log_warn "Install @clerk/themes: npm install @clerk/themes"
        ;;

    shadesOfPurple)
        cat > "$CONFIG_FILE" <<'EOF'
import { Appearance } from '@clerk/types'
import { shadesOfPurple } from '@clerk/themes'

export const clerkAppearance: Appearance = {
  baseTheme: shadesOfPurple,
  variables: {
    colorPrimary: '#a78bfa',
    borderRadius: '0.5rem'
  }
}
EOF
        log_info "Generated Shades of Purple theme configuration"
        log_warn "Install @clerk/themes: npm install @clerk/themes"
        ;;

    custom)
        cat > "$CONFIG_FILE" <<EOF
import { Appearance } from '@clerk/types'

export const clerkAppearance: Appearance = {
  layout: {
    shimmer: true,
    logoPlacement: 'inside'
  },
  variables: {
    colorPrimary: '${BRAND_COLOR}',
    colorBackground: '${BACKGROUND}',
    colorText: '${TEXT_COLOR}',
    colorTextSecondary: '#6b7280',
    colorDanger: '#ef4444',
    colorSuccess: '#10b981',
    borderRadius: '0.5rem',
    fontFamily: 'system-ui, -apple-system, sans-serif',
    fontSize: '1rem',
    fontWeight: {
      normal: 400,
      medium: 500,
      bold: 700
    }
  },
  elements: {
    card: 'shadow-lg border border-gray-200',
    headerTitle: 'text-2xl font-bold',
    headerSubtitle: 'text-gray-600',
    formButtonPrimary: 'bg-primary hover:bg-primary/90 transition-colors',
    formFieldInput: 'border-gray-300 focus:border-primary focus:ring-primary',
    footerActionLink: 'text-primary hover:text-primary/90',
    socialButtonsBlockButton: 'border-2 border-gray-300 hover:border-primary'
  }
}
EOF
        log_info "Generated custom theme configuration"
        log_info "Brand color: $BRAND_COLOR"
        log_info "Background: $BACKGROUND"
        log_info "Text color: $TEXT_COLOR"
        ;;

    *)
        echo "Invalid theme preset: $THEME_PRESET"
        echo "Valid presets: default, dark, neobrutalist, shadesOfPurple, custom"
        exit 1
        ;;
esac

# Generate usage example
USAGE_FILE="$(dirname "$CONFIG_FILE")/clerk-usage-example.tsx"
cat > "$USAGE_FILE" <<'EOF'
// Example: Apply appearance globally in app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs'
import { clerkAppearance } from '@/lib/clerk-config'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider appearance={clerkAppearance}>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}

// Example: Apply appearance to specific component
import { SignIn } from '@clerk/nextjs'
import { clerkAppearance } from '@/lib/clerk-config'

export default function SignInPage() {
  return <SignIn appearance={clerkAppearance} />
}
EOF

log_info "Generated usage example: $USAGE_FILE"

echo ""
log_info "Appearance configuration complete!"
echo ""
echo "Next steps:"
echo "1. Import appearance config in app/layout.tsx"
echo "2. Apply to <ClerkProvider> for global styling"
echo "3. Or apply to individual components like <SignIn />"
echo "4. Customize variables and elements as needed"
