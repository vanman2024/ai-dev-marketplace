/**
 * Clerk Unit Test Examples
 *
 * Comprehensive unit testing examples for Clerk components and hooks.
 * Demonstrates mocking patterns, testing strategies, and best practices.
 *
 * Security: Uses mock data, no real credentials needed.
 */

import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { useAuth, useUser, useClerk } from '@clerk/clerk-react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';

// Mock Clerk hooks
vi.mock('@clerk/clerk-react', () => ({
  useAuth: vi.fn(),
  useUser: vi.fn(),
  useClerk: vi.fn(),
  ClerkProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
  SignInButton: ({ children }: { children: React.ReactNode }) => (
    <button data-testid="sign-in-button">{children}</button>
  ),
  UserButton: () => <div data-testid="user-button">User Button</div>,
}));

// Example Components to Test
function ProtectedDashboard() {
  const { isSignedIn, isLoaded } = useAuth();
  const { user } = useUser();

  if (!isLoaded) {
    return <div>Loading...</div>;
  }

  if (!isSignedIn) {
    return <div>Please sign in to access the dashboard</div>;
  }

  return (
    <div>
      <h1>Dashboard</h1>
      <p>Welcome, {user?.firstName}!</p>
      <p>Email: {user?.emailAddresses[0].emailAddress}</p>
    </div>
  );
}

function UserProfileCard() {
  const { user, isLoaded } = useUser();

  if (!isLoaded) {
    return <div role="status">Loading profile...</div>;
  }

  if (!user) {
    return <div>No user data available</div>;
  }

  return (
    <div data-testid="profile-card">
      <img src={user.imageUrl} alt={`${user.firstName}'s avatar`} />
      <h2>
        {user.firstName} {user.lastName}
      </h2>
      <p>{user.emailAddresses[0].emailAddress}</p>
      <button onClick={() => console.log('Edit profile')}>Edit Profile</button>
    </div>
  );
}

function SignOutButton() {
  const { signOut } = useClerk();

  return (
    <button onClick={() => signOut()} data-testid="sign-out-button">
      Sign Out
    </button>
  );
}

function ConditionalContent() {
  const { isSignedIn } = useAuth();

  return (
    <div>
      {isSignedIn ? (
        <div data-testid="authenticated-content">
          <h1>Welcome back!</h1>
          <p>You have access to premium features.</p>
        </div>
      ) : (
        <div data-testid="public-content">
          <h1>Welcome!</h1>
          <p>Sign in to access premium features.</p>
        </div>
      )}
    </div>
  );
}

describe('Clerk Component Unit Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('ProtectedDashboard Component', () => {
    it('should show loading state when auth is not loaded', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: false,
      });

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        user: null,
        isLoaded: false,
      });

      render(<ProtectedDashboard />);

      expect(screen.getByText('Loading...')).toBeInTheDocument();
    });

    it('should show sign-in prompt when user is not authenticated', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: true,
      });

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        user: null,
        isLoaded: true,
      });

      render(<ProtectedDashboard />);

      expect(
        screen.getByText('Please sign in to access the dashboard')
      ).toBeInTheDocument();
    });

    it('should display dashboard content when user is authenticated', () => {
      const mockUser = {
        id: 'user_123',
        firstName: 'John',
        lastName: 'Doe',
        emailAddresses: [{ emailAddress: 'john.doe@example.com', id: 'email_123' }],
        imageUrl: 'https://example.com/avatar.jpg',
      };

      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
      });

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        user: mockUser,
        isLoaded: true,
      });

      render(<ProtectedDashboard />);

      expect(screen.getByText('Dashboard')).toBeInTheDocument();
      expect(screen.getByText('Welcome, John!')).toBeInTheDocument();
      expect(screen.getByText('Email: john.doe@example.com')).toBeInTheDocument();
    });

    it('should handle missing user data gracefully', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
      });

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        user: null,
        isLoaded: true,
      });

      // Component should handle null user without crashing
      const { container } = render(<ProtectedDashboard />);
      expect(container).toBeInTheDocument();
    });
  });

  describe('UserProfileCard Component', () => {
    it('should display loading state', () => {
      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        user: null,
        isLoaded: false,
      });

      render(<UserProfileCard />);

      expect(screen.getByRole('status')).toHaveTextContent('Loading profile...');
    });

    it('should display user profile information', () => {
      const mockUser = {
        id: 'user_456',
        firstName: 'Jane',
        lastName: 'Smith',
        emailAddresses: [{ emailAddress: 'jane.smith@example.com', id: 'email_456' }],
        imageUrl: 'https://example.com/jane-avatar.jpg',
      };

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        user: mockUser,
        isLoaded: true,
      });

      render(<UserProfileCard />);

      const profileCard = screen.getByTestId('profile-card');
      expect(profileCard).toBeInTheDocument();

      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
      expect(screen.getByText('jane.smith@example.com')).toBeInTheDocument();

      const avatar = screen.getByAltText("Jane's avatar");
      expect(avatar).toHaveAttribute('src', 'https://example.com/jane-avatar.jpg');
    });

    it('should show no data message when user is null', () => {
      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        user: null,
        isLoaded: true,
      });

      render(<UserProfileCard />);

      expect(screen.getByText('No user data available')).toBeInTheDocument();
    });

    it('should have edit profile button', () => {
      const mockUser = {
        id: 'user_789',
        firstName: 'Alice',
        lastName: 'Johnson',
        emailAddresses: [
          { emailAddress: 'alice.johnson@example.com', id: 'email_789' },
        ],
        imageUrl: 'https://example.com/alice-avatar.jpg',
      };

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        user: mockUser,
        isLoaded: true,
      });

      render(<UserProfileCard />);

      const editButton = screen.getByText('Edit Profile');
      expect(editButton).toBeInTheDocument();
    });
  });

  describe('SignOutButton Component', () => {
    it('should call signOut when clicked', () => {
      const mockSignOut = vi.fn();

      (useClerk as ReturnType<typeof vi.fn>).mockReturnValue({
        signOut: mockSignOut,
      });

      render(<SignOutButton />);

      const signOutButton = screen.getByTestId('sign-out-button');
      fireEvent.click(signOutButton);

      expect(mockSignOut).toHaveBeenCalledTimes(1);
    });

    it('should render with correct text', () => {
      (useClerk as ReturnType<typeof vi.fn>).mockReturnValue({
        signOut: vi.fn(),
      });

      render(<SignOutButton />);

      expect(screen.getByText('Sign Out')).toBeInTheDocument();
    });
  });

  describe('ConditionalContent Component', () => {
    it('should show authenticated content when signed in', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
      });

      render(<ConditionalContent />);

      expect(screen.getByTestId('authenticated-content')).toBeInTheDocument();
      expect(screen.getByText('Welcome back!')).toBeInTheDocument();
      expect(
        screen.getByText('You have access to premium features.')
      ).toBeInTheDocument();

      expect(screen.queryByTestId('public-content')).not.toBeInTheDocument();
    });

    it('should show public content when not signed in', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: true,
      });

      render(<ConditionalContent />);

      expect(screen.getByTestId('public-content')).toBeInTheDocument();
      expect(screen.getByText('Welcome!')).toBeInTheDocument();
      expect(
        screen.getByText('Sign in to access premium features.')
      ).toBeInTheDocument();

      expect(
        screen.queryByTestId('authenticated-content')
      ).not.toBeInTheDocument();
    });

    it('should switch content when auth state changes', () => {
      const { rerender } = render(<ConditionalContent />);

      // Initially not signed in
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: false,
        isLoaded: true,
      });

      rerender(<ConditionalContent />);
      expect(screen.getByTestId('public-content')).toBeInTheDocument();

      // Then sign in
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
      });

      rerender(<ConditionalContent />);
      expect(screen.getByTestId('authenticated-content')).toBeInTheDocument();
      expect(screen.queryByTestId('public-content')).not.toBeInTheDocument();
    });
  });
});

describe('Clerk Hook Testing Patterns', () => {
  describe('useAuth Hook', () => {
    it('should provide authentication state', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
        userId: 'user_abc123',
        sessionId: 'sess_xyz789',
        orgId: null,
        orgRole: null,
      });

      function TestComponent() {
        const auth = useAuth();
        return (
          <div>
            <p>Signed In: {auth.isSignedIn ? 'Yes' : 'No'}</p>
            <p>User ID: {auth.userId}</p>
          </div>
        );
      }

      render(<TestComponent />);

      expect(screen.getByText('Signed In: Yes')).toBeInTheDocument();
      expect(screen.getByText('User ID: user_abc123')).toBeInTheDocument();
    });

    it('should handle organization context', () => {
      (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
        isSignedIn: true,
        isLoaded: true,
        userId: 'user_123',
        orgId: 'org_456',
        orgRole: 'admin',
      });

      function OrgComponent() {
        const { orgId, orgRole } = useAuth();
        return (
          <div>
            <p>Org ID: {orgId}</p>
            <p>Role: {orgRole}</p>
          </div>
        );
      }

      render(<OrgComponent />);

      expect(screen.getByText('Org ID: org_456')).toBeInTheDocument();
      expect(screen.getByText('Role: admin')).toBeInTheDocument();
    });
  });

  describe('useUser Hook', () => {
    it('should provide user data', () => {
      const mockUser = {
        id: 'user_test',
        firstName: 'Test',
        lastName: 'User',
        emailAddresses: [{ emailAddress: 'test@example.com', id: 'email_1' }],
        imageUrl: 'https://example.com/test.jpg',
      };

      (useUser as ReturnType<typeof vi.fn>).mockReturnValue({
        user: mockUser,
        isLoaded: true,
        isSignedIn: true,
      });

      function UserComponent() {
        const { user } = useUser();
        return <div>Name: {user?.firstName}</div>;
      }

      render(<UserComponent />);

      expect(screen.getByText('Name: Test')).toBeInTheDocument();
    });
  });
});

describe('Error Handling', () => {
  it('should handle auth errors gracefully', () => {
    (useAuth as ReturnType<typeof vi.fn>).mockReturnValue({
      isSignedIn: false,
      isLoaded: true,
      error: new Error('Authentication failed'),
    });

    function ErrorComponent() {
      const auth = useAuth();
      return <div>{auth.error ? `Error: ${auth.error.message}` : 'No error'}</div>;
    }

    render(<ErrorComponent />);

    expect(screen.getByText('Error: Authentication failed')).toBeInTheDocument();
  });
});
