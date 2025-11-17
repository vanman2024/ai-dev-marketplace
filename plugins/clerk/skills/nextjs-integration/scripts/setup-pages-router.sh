#!/bin/bash

# setup-pages-router.sh
# Configures Clerk for Next.js Pages Router (12.x and earlier)

set -e

echo "=========================================="
echo "Clerk Pages Router Configuration"
echo "=========================================="

# Check if @clerk/nextjs is installed
if ! grep -q "@clerk/nextjs" package.json; then
  echo "Error: @clerk/nextjs not found in package.json"
  echo "Run: bash ./skills/nextjs-integration/scripts/install-clerk.sh first"
  exit 1
fi

# Detect project structure
if [ -d "pages" ]; then
  PAGES_DIR="pages"
elif [ -d "src/pages" ]; then
  PAGES_DIR="src/pages"
else
  echo "Error: Pages Router directory not found."
  echo "Looking for: ./pages or ./src/pages"
  exit 1
fi

echo "Detected Pages Router at: $PAGES_DIR"

# Update _app.tsx with ClerkProvider
echo ""
echo "Updating $PAGES_DIR/_app.tsx..."

APP_FILE="$PAGES_DIR/_app.tsx"

if [ -f "$APP_FILE" ]; then
  # Backup original _app
  cp "$APP_FILE" "$APP_FILE.backup"
  echo "✓ Backed up original _app to $APP_FILE.backup"
fi

cat > "$APP_FILE" << 'EOF'
import { ClerkProvider } from '@clerk/nextjs'
import type { AppProps } from 'next/app'
import '@/styles/globals.css'

function MyApp({ Component, pageProps }: AppProps) {
  return (
    <ClerkProvider {...pageProps}>
      <Component {...pageProps} />
    </ClerkProvider>
  )
}

export default MyApp
EOF
echo "✓ $APP_FILE updated with ClerkProvider"

# Create sign-in page
echo ""
echo "Creating sign-in page..."
mkdir -p "$PAGES_DIR/sign-in"
cat > "$PAGES_DIR/sign-in/[[...index]].tsx" << 'EOF'
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignIn />
    </div>
  );
}
EOF
echo "✓ Sign-in page created at $PAGES_DIR/sign-in/[[...index]].tsx"

# Create sign-up page
echo ""
echo "Creating sign-up page..."
mkdir -p "$PAGES_DIR/sign-up"
cat > "$PAGES_DIR/sign-up/[[...index]].tsx" << 'EOF'
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignUp />
    </div>
  );
}
EOF
echo "✓ Sign-up page created at $PAGES_DIR/sign-up/[[...index]].tsx"

# Create protected API route example
echo ""
echo "Creating protected API route..."
mkdir -p "$PAGES_DIR/api"
cat > "$PAGES_DIR/api/protected-example.ts" << 'EOF'
import { getAuth } from '@clerk/nextjs/server';
import type { NextApiRequest, NextApiResponse } from 'next';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const { userId } = getAuth(req);

  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // User is authenticated
  return res.status(200).json({
    message: 'Protected data',
    userId
  });
}
EOF
echo "✓ Protected API route created at $PAGES_DIR/api/protected-example.ts"

# Create example protected page with getServerSideProps
echo ""
echo "Creating example dashboard page..."
cat > "$PAGES_DIR/dashboard.tsx" << 'EOF'
import { getAuth } from '@clerk/nextjs/server';
import { useUser } from '@clerk/nextjs';
import type { GetServerSideProps } from 'next';

export const getServerSideProps: GetServerSideProps = async (ctx) => {
  const { userId } = getAuth(ctx.req);

  if (!userId) {
    return {
      redirect: {
        destination: '/sign-in',
        permanent: false,
      },
    };
  }

  return {
    props: { userId },
  };
};

export default function DashboardPage({ userId }: { userId: string }) {
  const { user } = useUser();

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
echo "✓ Example dashboard page created at $PAGES_DIR/dashboard.tsx"

# Create middleware.ts for route protection
echo ""
echo "Creating middleware.ts..."
cat > middleware.ts << 'EOF'
import { authMiddleware } from "@clerk/nextjs";

export default authMiddleware({
  publicRoutes: [
    "/",
    "/sign-in(.*)",
    "/sign-up(.*)",
    "/api/public(.*)",
  ],
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

echo ""
echo "=========================================="
echo "✓ Pages Router configuration complete!"
echo "=========================================="
echo ""
echo "Files created:"
echo "  - middleware.ts (route protection)"
echo "  - $PAGES_DIR/_app.tsx (ClerkProvider wrapper)"
echo "  - $PAGES_DIR/sign-in/[[...index]].tsx"
echo "  - $PAGES_DIR/sign-up/[[...index]].tsx"
echo "  - $PAGES_DIR/api/protected-example.ts"
echo "  - $PAGES_DIR/dashboard.tsx (protected page example)"
echo ""
echo "Next steps:"
echo "1. Update .env.local with your Clerk keys"
echo "2. Start development server: npm run dev"
echo "3. Visit http://localhost:3000/sign-in to test"
echo ""
echo "Server-side Auth (getServerSideProps):"
echo "  import { getAuth } from '@clerk/nextjs/server';"
echo "  const { userId } = getAuth(req);"
echo ""
echo "Client-side Auth (React hooks):"
echo "  import { useAuth } from '@clerk/nextjs';"
echo "  const { userId } = useAuth();"
echo ""
