#!/bin/bash

# Install Stripe React dependencies for Next.js payment integration
# Usage: bash install-stripe-react.sh

set -e

echo "Installing Stripe React dependencies..."

# Check if package.json exists
if [ ! -f "package.json" ]; then
  echo "Error: package.json not found. Are you in a Next.js project directory?"
  exit 1
fi

# Check if npm or yarn is available
if command -v npm &> /dev/null; then
  PKG_MANAGER="npm"
elif command -v yarn &> /dev/null; then
  PKG_MANAGER="yarn"
else
  echo "Error: Neither npm nor yarn found. Please install Node.js."
  exit 1
fi

echo "Using package manager: $PKG_MANAGER"

# Install Stripe dependencies
if [ "$PKG_MANAGER" = "npm" ]; then
  npm install @stripe/stripe-js @stripe/react-stripe-js
  npm install --save-dev @types/stripe-v3
else
  yarn add @stripe/stripe-js @stripe/react-stripe-js
  yarn add -D @types/stripe-v3
fi

echo ""
echo "✅ Stripe React dependencies installed successfully!"
echo ""
echo "Installed packages:"
echo "  - @stripe/stripe-js (Stripe.js loader)"
echo "  - @stripe/react-stripe-js (React Elements components)"
echo "  - @types/stripe-v3 (TypeScript definitions)"
echo ""
echo "Next steps:"
echo "  1. Set up environment variables (NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY)"
echo "  2. Run: bash scripts/setup-stripe-provider.sh"
echo "  3. Generate components: bash scripts/generate-component.sh checkout-form"
echo ""
