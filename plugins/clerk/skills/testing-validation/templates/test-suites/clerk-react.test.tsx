/**
 * Clerk React Component Testing Template
 *
 * This template demonstrates how to test React components that use Clerk hooks
 * and authentication features. Uses React Testing Library and Jest/Vitest.
 *
 * Security Note: Never hardcode API keys. Use environment variables.
 */

import { render, screen, waitFor } from '@testing-library/react';
import { useAuth, useUser, useClerk } from '@clerk/clerk-react';
import { describe, it, expect, vi, beforeEach } from 'vitest'; // or 'jest' for Jest
import ProtectedComponent from '@/components/ProtectedComponent';
import ProfilePage from '@/app/profile/page';

// Mock Clerk hooks
vi.mock('@clerk/clerk-react', () => ({
  useAuth: vi.fn(),
  useUser: vi.fn(),
  useClerk: vi.fn(),
  ClerkProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

describe('Clerk Authentication - Protected Component', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Authenticated State', () => {
    it('should render protected content when user is authenticated', async () => {
      // Mock authenticated user
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
        userId: 'user_test123',
      });

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
        user: {
          id: 'user_test123',
          firstName: 'Test',
          lastName: 'User',
          emailAddresses: [{ emailAddress: 'test_user@example.com' }],
        },
      });

      render(<ProtectedComponent />);

      await waitFor(() => {
        expect(screen.getByText(/welcome/i)).toBeInTheDocument();
      });
    });

    it('should display user information correctly', async () => {
      const mockUser = {
        id: 'user_test123',
        firstName: 'John',
        lastName: 'Doe',
        emailAddresses: [{ emailAddress: 'john.doe@example.com' }],
        imageUrl: 'https://example.com/avatar.jpg',
      };

      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
        userId: mockUser.id,
      });

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
        user: mockUser,
      });

      render(<ProfilePage />);

      await waitFor(() => {
        expect(screen.getByText('John Doe')).toBeInTheDocument();
        expect(screen.getByText('john.doe@example.com')).toBeInTheDocument();
      });
    });

    it('should call sign out when logout button is clicked', async () => {
      const mockSignOut = vi.fn();

      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
        userId: 'user_test123',
      });

      (useClerk as ReturnType<typeof vi.fn>).mockReturnValue({
        signOut: mockSignOut,
      });

      render(<ProtectedComponent />);

      const logoutButton = screen.getByRole('button', { name: /sign out/i });
      logoutButton.click();

      await waitFor(() => {
        expect(mockSignOut).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('Unauthenticated State', () => {
    it('should redirect to sign-in when user is not authenticated', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: true,
        userId: null,
      });

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: true,
        user: null,
      });

      render(<ProtectedComponent />);

      expect(screen.queryByText(/welcome/i)).not.toBeInTheDocument();
      // Verify redirect or sign-in prompt
      expect(screen.getByText(/sign in/i)).toBeInTheDocument();
    });

    it('should display sign-in prompt for unauthenticated users', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: true,
        userId: null,
      });

      render(<ProtectedComponent />);

      expect(screen.getByText(/please sign in/i)).toBeInTheDocument();
    });
  });

  describe('Loading State', () => {
    it('should display loading indicator while auth is loading', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: false,
        userId: null,
      });

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: false,
        user: null,
      });

      render(<ProtectedComponent />);

      expect(screen.getByText(/loading/i)).toBeInTheDocument();
    });

    it('should not render protected content while loading', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: false,
        userId: null,
      });

      render(<ProtectedComponent />);

      expect(screen.queryByText(/welcome/i)).not.toBeInTheDocument();
    });
  });

  describe('Error Handling', () => {
    it('should handle authentication errors gracefully', async () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: true,
        userId: null,
        error: new Error('Authentication failed'),
      });

      render(<ProtectedComponent />);

      await waitFor(() => {
        expect(screen.getByText(/error/i)).toBeInTheDocument();
      });
    });
  });

  describe('Session Management', () => {
    it('should handle session updates', async () => {
      const { rerender } = render(<ProtectedComponent />);

      // Initial: not signed in
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: true,
        userId: null,
      });

      rerender(<ProtectedComponent />);
      expect(screen.getByText(/sign in/i)).toBeInTheDocument();

      // After sign-in
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
        userId: 'user_test123',
      });

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
        user: {
          id: 'user_test123',
          firstName: 'Test',
          emailAddresses: [{ emailAddress: 'test_user@example.com' }],
        },
      });

      rerender(<ProtectedComponent />);

      await waitFor(() => {
        expect(screen.getByText(/welcome/i)).toBeInTheDocument();
      });
    });
  });
});

describe('Clerk Hooks - useAuth', () => {
  it('should provide authentication state', () => {
    (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
      isSignedIn: true,
      isLoaded: true,
      userId: 'user_123',
      sessionId: 'sess_123',
      orgId: null,
    });

    function TestComponent() {
      const { isSignedIn, userId } = useAuth();
      return <div>{isSignedIn ? `User: ${userId}` : 'Not signed in'}</div>;
    }

    render(<TestComponent />);
    expect(screen.getByText('User: user_123')).toBeInTheDocument();
  });
});

describe('Clerk Hooks - useUser', () => {
  it('should provide user data', () => {
    const mockUser = {
      id: 'user_123',
      firstName: 'Jane',
      lastName: 'Smith',
      emailAddresses: [{ emailAddress: 'jane.smith@example.com' }],
    };

    (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
      isSignedIn: true,
      isLoaded: true,
      user: mockUser,
    });

    function TestComponent() {
      const { user } = useUser();
      return <div>{user?.firstName} {user?.lastName}</div>;
    }

    render(<TestComponent />);
    expect(screen.getByText('Jane Smith')).toBeInTheDocument();
  });
});
