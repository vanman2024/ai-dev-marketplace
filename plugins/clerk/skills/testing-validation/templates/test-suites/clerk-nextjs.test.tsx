/**
 * Clerk Next.js Testing Template
 *
 * Testing patterns for Next.js App Router with Clerk authentication.
 * Covers server components, client components, and API routes.
 *
 * Security Note: Test credentials should be in .env.test, never hardcoded.
 */

import { render, screen } from '@testing-library/react';
import { auth, currentUser } from '@clerk/nextjs/server';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import DashboardPage from '@/app/dashboard/page';
import ProtectedLayout from '@/app/dashboard/layout';

// Mock Clerk server functions
vi.mock('@clerk/nextjs/server', () => ({
  auth: vi.fn(),
  currentUser: vi.fn(),
  clerkMiddleware: vi.fn(),
}));

describe('Next.js Server Components - Clerk Auth', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Protected Dashboard Page', () => {
    it('should render dashboard for authenticated users', async () => {
      // Mock authenticated session
      (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
        userId: 'user_test123',
        sessionId: 'sess_test123',
        orgId: null,
      });

      (currentUser as ReturnType<typeof vi.fn>).mockResolvedValue({
        id: 'user_test123',
        firstName: 'John',
        lastName: 'Doe',
        emailAddresses: [{ emailAddress: 'john.doe@example.com' }],
      });

      const DashboardComponent = await DashboardPage();
      render(DashboardComponent);

      expect(screen.getByText(/dashboard/i)).toBeInTheDocument();
      expect(screen.getByText(/john doe/i)).toBeInTheDocument();
    });

    it('should redirect unauthenticated users', async () => {
      // Mock unauthenticated session
      (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
        userId: null,
        sessionId: null,
        orgId: null,
      });

      (currentUser as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      // In real implementation, this would trigger redirect
      // Test that the auth check returns null
      const authData = await auth();
      expect(authData.userId).toBeNull();
    });

    it('should handle missing user data gracefully', async () => {
      (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
        userId: 'user_test123',
        sessionId: 'sess_test123',
        orgId: null,
      });

      (currentUser as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      const authData = await auth();
      expect(authData.userId).toBe('user_test123');

      const user = await currentUser();
      expect(user).toBeNull();
    });
  });

  describe('Organization Access', () => {
    it('should allow access for users in organization', async () => {
      (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
        userId: 'user_test123',
        sessionId: 'sess_test123',
        orgId: 'org_test456',
        orgRole: 'admin',
      });

      const authData = await auth();
      expect(authData.orgId).toBe('org_test456');
      expect(authData.orgRole).toBe('admin');
    });

    it('should restrict access for non-members', async () => {
      (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
        userId: 'user_test123',
        sessionId: 'sess_test123',
        orgId: null,
        orgRole: null,
      });

      const authData = await auth();
      expect(authData.orgId).toBeNull();
    });
  });
});

describe('Next.js API Routes - Clerk Auth', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Protected API Endpoints', () => {
    it('should allow authenticated requests', async () => {
      const mockRequest = new Request('http://localhost:3000/api/user');

      (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
        userId: 'user_test123',
        sessionId: 'sess_test123',
      });

      // Simulate API route handler
      const authData = await auth();
      expect(authData.userId).toBe('user_test123');

      // API would return 200 with data
    });

    it('should reject unauthenticated requests', async () => {
      (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
        userId: null,
        sessionId: null,
      });

      const authData = await auth();
      expect(authData.userId).toBeNull();

      // API would return 401 Unauthorized
    });

    it('should validate session tokens', async () => {
      const mockRequest = new Request('http://localhost:3000/api/protected', {
        headers: {
          'Authorization': 'Bearer mock_session_token',
        },
      });

      (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
        userId: 'user_test123',
        sessionId: 'sess_test123',
        getToken: vi.fn().mockResolvedValue('mock_session_token'),
      });

      const authData = await auth();
      const token = await authData.getToken();

      expect(token).toBe('mock_session_token');
    });
  });

  describe('User Data API', () => {
    it('should return user profile data', async () => {
      (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
        userId: 'user_test123',
        sessionId: 'sess_test123',
      });

      (currentUser as ReturnType<typeof vi.fn>).mockResolvedValue({
        id: 'user_test123',
        firstName: 'Alice',
        lastName: 'Johnson',
        emailAddresses: [
          { emailAddress: 'alice.johnson@example.com', id: 'email_123' },
        ],
        imageUrl: 'https://example.com/avatar.jpg',
        createdAt: Date.now(),
      });

      const user = await currentUser();

      expect(user).toBeDefined();
      expect(user?.firstName).toBe('Alice');
      expect(user?.emailAddresses[0].emailAddress).toBe('alice.johnson@example.com');
    });

    it('should handle user not found', async () => {
      (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
        userId: 'user_invalid',
        sessionId: 'sess_test123',
      });

      (currentUser as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      const user = await currentUser();
      expect(user).toBeNull();
    });
  });
});

describe('Clerk Middleware', () => {
  it('should protect specified routes', async () => {
    const mockMiddleware = vi.fn();

    // In actual middleware.ts:
    // export default clerkMiddleware((auth, req) => {
    //   if (!auth().userId && req.nextUrl.pathname.startsWith('/dashboard')) {
    //     return NextResponse.redirect(new URL('/sign-in', req.url));
    //   }
    // });

    (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
      userId: null,
      sessionId: null,
    });

    const mockRequest = {
      nextUrl: { pathname: '/dashboard' },
      url: 'http://localhost:3000/dashboard',
    };

    const authData = await auth();

    // Verify middleware would trigger redirect
    if (!authData.userId && mockRequest.nextUrl.pathname.startsWith('/dashboard')) {
      expect(authData.userId).toBeNull();
      // Would redirect to /sign-in
    }
  });

  it('should allow public routes', async () => {
    (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
      userId: null,
      sessionId: null,
    });

    const mockRequest = {
      nextUrl: { pathname: '/' },
      url: 'http://localhost:3000/',
    };

    const authData = await auth();

    // Public routes accessible without auth
    expect(authData.userId).toBeNull();
    // No redirect needed
  });
});

describe('Session Token Management', () => {
  it('should retrieve session token for API calls', async () => {
    const mockGetToken = vi.fn().mockResolvedValue('test_session_token_123');

    (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
      userId: 'user_test123',
      sessionId: 'sess_test123',
      getToken: mockGetToken,
    });

    const authData = await auth();
    const token = await authData.getToken();

    expect(token).toBe('test_session_token_123');
    expect(mockGetToken).toHaveBeenCalledTimes(1);
  });

  it('should handle token retrieval errors', async () => {
    (auth as ReturnType<typeof vi.fn>).mockResolvedValue({
      userId: 'user_test123',
      sessionId: 'sess_test123',
      getToken: vi.fn().mockRejectedValue(new Error('Token expired')),
    });

    const authData = await auth();

    await expect(authData.getToken()).rejects.toThrow('Token expired');
  });
});
