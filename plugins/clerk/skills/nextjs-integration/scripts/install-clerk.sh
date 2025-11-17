#!/bin/bash

# install-clerk.sh
# Installs and configures Clerk for Next.js projects

set -e

echo "=========================================="
echo "Clerk Installation for Next.js"
echo "=========================================="

# Check if we're in a Next.js project
if [ ! -f "package.json" ]; then
  echo "Error: package.json not found. Are you in a Next.js project directory?"
  exit 1
fi

# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"
  INSTALL_CMD="pnpm add"
elif [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"
  INSTALL_CMD="yarn add"
elif [ -f "bun.lockb" ]; then
  PKG_MANAGER="bun"
  INSTALL_CMD="bun add"
else
  PKG_MANAGER="npm"
  INSTALL_CMD="npm install"
fi

echo "Detected package manager: $PKG_MANAGER"

# Install Clerk Next.js SDK
echo ""
echo "Installing @clerk/nextjs..."
$INSTALL_CMD @clerk/nextjs

# Create .env.local if it doesn't exist
if [ ! -f ".env.local" ]; then
  echo ""
  echo "Creating .env.local file..."
  cat > .env.local << 'EOF'
# Clerk API Keys
# Get your keys from: https://dashboard.clerk.com
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key_here
CLERK_SECRET_KEY=your_clerk_secret_key_here

# Optional: Customize sign-in/sign-up URLs
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/onboarding
EOF
  echo "✓ .env.local created with placeholder keys"
else
  echo ""
  echo "✓ .env.local already exists, skipping creation"
fi

# Create .env.example for git
if [ ! -f ".env.example" ]; then
  echo ""
  echo "Creating .env.example file..."
  cat > .env.example << 'EOF'
# Clerk API Keys
# Get your keys from: https://dashboard.clerk.com
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key_here
CLERK_SECRET_KEY=your_clerk_secret_key_here

# Optional: Customize sign-in/sign-up URLs
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/onboarding
EOF
  echo "✓ .env.example created (safe to commit)"
else
  echo "✓ .env.example already exists"
fi

# Ensure .env.local is in .gitignore
if [ -f ".gitignore" ]; then
  if ! grep -q "^\.env\.local$" .gitignore; then
    echo "" >> .gitignore
    echo "# Clerk environment variables" >> .gitignore
    echo ".env.local" >> .gitignore
    echo "✓ Added .env.local to .gitignore"
  else
    echo "✓ .env.local already in .gitignore"
  fi
else
  echo "Warning: .gitignore not found. Create it and add .env.local to prevent committing secrets"
fi

echo ""
echo "=========================================="
echo "✓ Clerk installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Get your Clerk keys from: https://dashboard.clerk.com"
echo "2. Update .env.local with your actual keys"
echo "3. Run setup script for your Next.js version:"
echo "   - App Router: bash ./skills/nextjs-integration/scripts/setup-app-router.sh"
echo "   - Pages Router: bash ./skills/nextjs-integration/scripts/setup-pages-router.sh"
echo "4. Start development server: $PKG_MANAGER dev"
echo ""
