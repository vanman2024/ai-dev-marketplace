#!/bin/bash

# test-sessions.sh
# Clerk session validation and JWT verification testing

set -e

TEST_TYPE="${1:-basic}"

echo "=== Clerk Session Testing ==="
echo "Test Type: $TEST_TYPE"
echo ""

# Check for .env.local
if [ ! -f ".env.local" ]; then
    echo "Error: .env.local not found"
    echo "Create .env.local with:"
    echo "  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_key_here"
    echo "  CLERK_SECRET_KEY=sk_test_your_key_here"
    exit 1
fi

# Source environment variables
set -a
source .env.local
set +a

# Verify required keys
if [ -z "$CLERK_SECRET_KEY" ]; then
    echo "Error: CLERK_SECRET_KEY not set in .env.local"
    exit 1
fi

if [ -z "$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" ]; then
    echo "Error: NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY not set in .env.local"
    exit 1
fi

echo "✓ Environment variables loaded"
echo ""

# Helper function to check if server is running
check_server() {
    if ! curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo "Warning: Development server not running at http://localhost:3000"
        echo "Start with: npm run dev"
        return 1
    fi
    return 0
}

# Test functions
test_basic() {
    echo "Running Basic Session Tests"
    echo "============================"
    echo ""

    echo "Checking Clerk SDK installation..."
    if npm list @clerk/nextjs > /dev/null 2>&1; then
        VERSION=$(npm list @clerk/nextjs --depth=0 | grep @clerk/nextjs | awk '{print $2}')
        echo "✓ @clerk/nextjs installed: $VERSION"
    else
        echo "✗ @clerk/nextjs not installed"
        echo "  Install with: npm install @clerk/nextjs"
    fi
    echo ""

    echo "Checking middleware configuration..."
    if [ -f "middleware.ts" ] || [ -f "middleware.js" ]; then
        echo "✓ Middleware file found"
        if grep -q "clerkMiddleware" middleware.* 2>/dev/null; then
            echo "✓ Clerk middleware configured"
        else
            echo "⚠ Middleware exists but may not use Clerk"
        fi
    else
        echo "⚠ No middleware.ts found - create with ./scripts/configure-sessions.sh"
    fi
    echo ""

    echo "Checking environment configuration..."
    echo "  CLERK_SECRET_KEY: ${CLERK_SECRET_KEY:0:10}..."
    echo "  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: ${NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY:0:10}..."

    # Validate key formats
    if [[ $CLERK_SECRET_KEY == sk_test_* ]] || [[ $CLERK_SECRET_KEY == sk_live_* ]]; then
        echo "✓ Secret key format valid"
    else
        echo "✗ Secret key format invalid (should start with sk_test_ or sk_live_)"
    fi

    if [[ $NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY == pk_test_* ]] || [[ $NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY == pk_live_* ]]; then
        echo "✓ Publishable key format valid"
    else
        echo "✗ Publishable key format invalid (should start with pk_test_ or pk_live_)"
    fi
    echo ""

    echo "Test Checklist:"
    echo "- [ ] User can sign in successfully"
    echo "- [ ] Session persists across page refreshes"
    echo "- [ ] Protected routes redirect when not authenticated"
    echo "- [ ] User can sign out"
    echo ""
}

test_jwt_verify() {
    echo "Running JWT Verification Tests"
    echo "=============================="
    echo ""

    if ! check_server; then
        echo "Cannot test JWT verification without running server"
        return 1
    fi

    echo "Testing JWT verification endpoint..."

    # Create test endpoint if it doesn't exist
    API_DIR="app/api/test-jwt"
    mkdir -p "$API_DIR"

    cat > "$API_DIR/route.ts" <<'EOF'
import { auth } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const { userId, sessionId, sessionClaims } = await auth();

    if (!userId) {
      return NextResponse.json(
        { error: 'Unauthorized', valid: false },
        { status: 401 }
      );
    }

    return NextResponse.json({
      valid: true,
      userId,
      sessionId,
      claims: {
        iss: sessionClaims?.iss,
        sub: sessionClaims?.sub,
        exp: sessionClaims?.exp,
        iat: sessionClaims?.iat,
      },
    });
  } catch (error) {
    return NextResponse.json(
      { error: error.message, valid: false },
      { status: 500 }
    );
  }
}
EOF

    echo "✓ Created test endpoint: /api/test-jwt"
    echo ""
    echo "Manual Test Steps:"
    echo "1. Sign in to your app at http://localhost:3000"
    echo "2. Visit http://localhost:3000/api/test-jwt"
    echo "3. Verify you see valid: true with userId and sessionId"
    echo "4. Sign out and retry - should see 401 Unauthorized"
    echo ""
}

test_custom_claims() {
    echo "Running Custom Claims Tests"
    echo "==========================="
    echo ""

    if ! check_server; then
        echo "Cannot test custom claims without running server"
        return 1
    fi

    # Create test endpoint
    API_DIR="app/api/test-claims"
    mkdir -p "$API_DIR"

    cat > "$API_DIR/route.ts" <<'EOF'
import { auth } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

export async function GET() {
  const { userId, sessionClaims } = await auth();

  if (!userId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // Extract custom claims
  const customClaims = {
    userId: sessionClaims?.sub,
    email: sessionClaims?.email,
    role: sessionClaims?.role,
    orgId: sessionClaims?.org_id,
    orgRole: sessionClaims?.org_role,
    permissions: sessionClaims?.permissions,
    metadata: sessionClaims?.metadata,

    // Check for Hasura claims
    hasura: sessionClaims?.['https://hasura.io/jwt/claims'],
  };

  return NextResponse.json({
    userId,
    customClaims,
    allClaims: sessionClaims,
  });
}
EOF

    echo "✓ Created claims test endpoint: /api/test-claims"
    echo ""
    echo "Manual Test Steps:"
    echo "1. Configure JWT template in Clerk Dashboard"
    echo "2. Sign OUT and sign IN again (required for new claims)"
    echo "3. Visit http://localhost:3000/api/test-claims"
    echo "4. Verify custom claims are present in response"
    echo ""
    echo "Common Issues:"
    echo "- Claims undefined → JWT template not set as default"
    echo "- Old claims present → User hasn't re-authenticated"
    echo "- Metadata missing → User publicMetadata not set"
    echo ""
}

test_multi_session() {
    echo "Running Multi-Session Tests"
    echo "==========================="
    echo ""

    echo "Multi-session testing requires:"
    echo "1. Enable multi-session in Dashboard (Settings → Sessions)"
    echo "2. Sign in from multiple browsers/devices"
    echo "3. Use session management UI to verify"
    echo ""

    # Create session list component
    COMPONENT_DIR="app/components"
    mkdir -p "$COMPONENT_DIR"

    cat > "$COMPONENT_DIR/SessionList.tsx" <<'EOF'
'use client';

import { useClerk } from '@clerk/nextjs';

export function SessionList() {
  const { client } = useClerk();
  const sessions = client?.sessions || [];

  if (sessions.length === 0) {
    return <p>No active sessions</p>;
  }

  return (
    <div>
      <h3>Active Sessions ({sessions.length})</h3>
      {sessions.map((session) => (
        <div key={session.id} style={{ border: '1px solid #ccc', padding: '10px', margin: '10px 0' }}>
          <p><strong>Session ID:</strong> {session.id}</p>
          <p><strong>Status:</strong> {session.status}</p>
          <p><strong>Last Active:</strong> {session.lastActiveAt?.toLocaleString()}</p>
          <p><strong>Expires:</strong> {session.expireAt?.toLocaleString()}</p>
          {session.id === client?.session?.id && <p><em>(Current session)</em></p>}
        </div>
      ))}
    </div>
  );
}
EOF

    echo "✓ Created SessionList component"
    echo ""
    echo "Add to your page:"
    echo "  import { SessionList } from '@/app/components/SessionList';"
    echo "  <SessionList />"
    echo ""
}

test_refresh() {
    echo "Running Session Refresh Tests"
    echo "============================="
    echo ""

    # Create refresh hook
    HOOKS_DIR="app/hooks"
    mkdir -p "$HOOKS_DIR"

    cat > "$HOOKS_DIR/useSessionRefresh.ts" <<'EOF'
import { useSession } from '@clerk/nextjs';
import { useEffect } from 'react';

export function useSessionRefresh() {
  const { session } = useSession();

  useEffect(() => {
    if (!session) return;

    const expiresAt = session.expireAt?.getTime() || 0;
    const createdAt = session.createdAt?.getTime() || 0;
    const sessionDuration = expiresAt - createdAt;

    // Refresh in last 10% of session lifetime
    const refreshThreshold = 0.1;
    const refreshAt = expiresAt - (sessionDuration * refreshThreshold);
    const now = Date.now();

    if (refreshAt > now) {
      const timeout = setTimeout(() => {
        console.log('Auto-refreshing session...');
        session.touch();
      }, refreshAt - now);

      return () => clearTimeout(timeout);
    }
  }, [session]);

  return session;
}
EOF

    echo "✓ Created useSessionRefresh hook"
    echo ""
    echo "Usage in component:"
    echo "  import { useSessionRefresh } from '@/app/hooks/useSessionRefresh';"
    echo "  const session = useSessionRefresh();"
    echo ""
    echo "Manual verification:"
    echo "1. Shorten session lifetime in Dashboard (e.g., 5 minutes)"
    echo "2. Sign in and monitor console logs"
    echo "3. Verify session.touch() called before expiration"
    echo "4. Check session.expireAt is extended"
    echo ""
}

test_expiration() {
    echo "Running Session Expiration Tests"
    echo "================================"
    echo ""

    echo "To test session expiration:"
    echo "1. Set short session lifetime in Dashboard (e.g., 2 minutes)"
    echo "2. Sign in to your application"
    echo "3. Wait for session to expire"
    echo "4. Attempt to access protected route"
    echo "5. Verify redirect to sign-in page"
    echo ""

    # Create expiration monitor
    cat > "app/components/SessionMonitor.tsx" <<'EOF'
'use client';

import { useSession } from '@clerk/nextjs';
import { useEffect, useState } from 'react';

export function SessionMonitor() {
  const { session } = useSession();
  const [timeLeft, setTimeLeft] = useState<number>(0);

  useEffect(() => {
    if (!session?.expireAt) return;

    const interval = setInterval(() => {
      const now = Date.now();
      const expiresAt = session.expireAt.getTime();
      const left = Math.max(0, expiresAt - now);
      setTimeLeft(left);

      if (left === 0) {
        console.log('Session expired!');
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [session]);

  if (!session) return <p>No active session</p>;

  const minutes = Math.floor(timeLeft / 60000);
  const seconds = Math.floor((timeLeft % 60000) / 1000);

  return (
    <div style={{ padding: '10px', border: '1px solid #ccc' }}>
      <h4>Session Status</h4>
      <p>Time until expiration: {minutes}m {seconds}s</p>
      <p>Session ID: {session.id}</p>
      <button onClick={() => session.touch()}>
        Extend Session
      </button>
    </div>
  );
}
EOF

    echo "✓ Created SessionMonitor component"
    echo "Add to your page to monitor expiration in real-time"
    echo ""
}

# Run the appropriate test
case $TEST_TYPE in
    basic)
        test_basic
        ;;
    jwt-verify)
        test_jwt_verify
        ;;
    custom-claims)
        test_custom_claims
        ;;
    multi-session)
        test_multi_session
        ;;
    refresh)
        test_refresh
        ;;
    expiration)
        test_expiration
        ;;
    all)
        test_basic
        echo ""
        test_jwt_verify
        echo ""
        test_custom_claims
        echo ""
        test_multi_session
        echo ""
        test_refresh
        echo ""
        test_expiration
        ;;
    *)
        echo "Error: Unknown test type '$TEST_TYPE'"
        echo ""
        echo "Available tests:"
        echo "  basic         - Environment and configuration validation"
        echo "  jwt-verify    - JWT verification endpoint testing"
        echo "  custom-claims - Custom claims validation"
        echo "  multi-session - Multi-session handling"
        echo "  refresh       - Session refresh patterns"
        echo "  expiration    - Session expiration testing"
        echo "  all           - Run all tests"
        echo ""
        echo "Usage: $0 <test-type>"
        exit 1
        ;;
esac

echo ""
echo "Test completed: $TEST_TYPE"
echo ""
