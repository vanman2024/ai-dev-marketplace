#!/bin/bash

# setup-app-router.sh
# Configures Clerk for Next.js App Router (13.4+)

set -e

echo "=========================================="
echo "Clerk App Router Configuration"
echo "=========================================="

# Check if @clerk/nextjs is installed
if ! grep -q "@clerk/nextjs" package.json; then
  echo "Error: @clerk/nextjs not found in package.json"
  echo "Run: bash ./skills/nextjs-integration/scripts/install-clerk.sh first"
  exit 1
fi

# Detect project structure
if [ -d "app" ]; then
  APP_DIR="app"
elif [ -d "src/app" ]; then
  APP_DIR="src/app"
else
  echo "Error: App Router directory not found. Is this a Next.js 13+ project?"
  echo "Looking for: ./app or ./src/app"
  exit 1
fi

echo "Detected App Router at: $APP_DIR"

# Create middleware.ts at project root
echo ""
echo "Creating middleware.ts..."
cat > middleware.ts << 'EOF'
import { authMiddleware } from "@clerk/nextjs";

// This middleware protects routes and handles authentication
export default authMiddleware({
  // Routes that can be accessed while signed out
  publicRoutes: [
    "/",
    "/sign-in(.*)",
    "/sign-up(.*)",
    "/api/public(.*)",
  ],

  // Routes that are completely ignored by Clerk (no auth checks)
  ignoredRoutes: [
    "/api/webhook(.*)",
    "/_next(.*)",
    "/favicon.ico",
  ],
});

export const config = {
  matcher: ['/((?!.+\\.[\\w]+$|_next).*)', '/', '/(api|trpc)(.*)'],
};
EOF
echo "✓ middleware.ts created"

# Update root layout with ClerkProvider
echo ""
echo "Updating $APP_DIR/layout.tsx..."

LAYOUT_FILE="$APP_DIR/layout.tsx"

if [ -f "$LAYOUT_FILE" ]; then
  # Backup original layout
  cp "$LAYOUT_FILE" "$LAYOUT_FILE.backup"
  echo "✓ Backed up original layout to $LAYOUT_FILE.backup"
fi

cat > "$LAYOUT_FILE" << 'EOF'
import { ClerkProvider } from '@clerk/nextjs'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata = {
  title: 'My App',
  description: 'App with Clerk authentication',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body className={inter.className}>{children}</body>
      </html>
    </ClerkProvider>
  )
}
EOF
echo "✓ $LAYOUT_FILE updated with ClerkProvider"

# Create sign-in page
echo ""
echo "Creating sign-in page..."
mkdir -p "$APP_DIR/sign-in/[[...sign-in]]"
cat > "$APP_DIR/sign-in/[[...sign-in]]/page.tsx" << 'EOF'
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignIn />
    </div>
  );
}
EOF
echo "✓ Sign-in page created at $APP_DIR/sign-in/[[...sign-in]]/page.tsx"

# Create sign-up page
echo ""
echo "Creating sign-up page..."
mkdir -p "$APP_DIR/sign-up/[[...sign-up]]"
cat > "$APP_DIR/sign-up/[[...sign-up]]/page.tsx" << 'EOF'
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignUp />
    </div>
  );
}
EOF
echo "✓ Sign-up page created at $APP_DIR/sign-up/[[...sign-up]]/page.tsx"

# Create example protected page
echo ""
echo "Creating example dashboard page..."
mkdir -p "$APP_DIR/dashboard"
cat > "$APP_DIR/dashboard/page.tsx" << 'EOF'
import { auth, currentUser } from '@clerk/nextjs';
import { redirect } from 'next/navigation';

export default async function DashboardPage() {
  const { userId } = auth();

  // Redirect to sign-in if not authenticated
  if (!userId) {
    redirect('/sign-in');
  }

  // Get full user object (optional)
  const user = await currentUser();

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-4">Dashboard</h1>
      <p className="text-lg">
        Welcome, {user?.firstName || 'User'}!
      </p>
      <p className="text-sm text-gray-600 mt-2">
        User ID: {userId}
      </p>
    </div>
  );
}
EOF
echo "✓ Example dashboard page created at $APP_DIR/dashboard/page.tsx"

echo ""
echo "=========================================="
echo "✓ App Router configuration complete!"
echo "=========================================="
echo ""
echo "Files created:"
echo "  - middleware.ts (route protection)"
echo "  - $APP_DIR/layout.tsx (ClerkProvider wrapper)"
echo "  - $APP_DIR/sign-in/[[...sign-in]]/page.tsx"
echo "  - $APP_DIR/sign-up/[[...sign-up]]/page.tsx"
echo "  - $APP_DIR/dashboard/page.tsx (protected route example)"
echo ""
echo "Next steps:"
echo "1. Update .env.local with your Clerk keys"
echo "2. Start development server: npm run dev"
echo "3. Visit http://localhost:3000/sign-in to test"
echo ""
echo "Server Component Auth:"
echo "  import { auth } from '@clerk/nextjs';"
echo "  const { userId } = auth();"
echo ""
echo "Client Component Auth:"
echo "  'use client';"
echo "  import { useAuth } from '@clerk/nextjs';"
echo "  const { userId } = useAuth();"
echo ""
