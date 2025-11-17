'use client';

import { useAuth, useUser, useClerk } from '@clerk/nextjs';
import { useRouter } from 'next/navigation';

/**
 * Client Component authentication example
 *
 * This demonstrates:
 * - useAuth() hook for auth state
 * - useUser() hook for user data
 * - useClerk() for Clerk methods
 * - Loading states and conditional rendering
 * - Sign out functionality
 *
 * @see https://clerk.com/docs/references/react/use-auth
 * @see https://clerk.com/docs/references/react/use-user
 */
export default function ClientComponentAuthExample() {
  const router = useRouter();

  // Get authentication state
  const { userId, isLoaded, isSignedIn } = useAuth();

  // Get user data
  const { user } = useUser();

  // Get Clerk instance for methods like signOut
  const { signOut } = useClerk();

  // Handle sign out
  const handleSignOut = async () => {
    await signOut();
    router.push('/');
  };

  // Loading state
  if (!isLoaded) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading authentication...</p>
        </div>
      </div>
    );
  }

  // Not signed in state
  if (!isSignedIn) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="bg-white rounded-lg shadow-lg p-8 max-w-md">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">
            Authentication Required
          </h1>
          <p className="text-gray-600 mb-6">
            Please sign in to access this page.
          </p>
          <button
            onClick={() => router.push('/sign-in')}
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors"
          >
            Sign In
          </button>
        </div>
      </div>
    );
  }

  // Signed in state
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-8">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              {user?.imageUrl && (
                <img
                  src={user.imageUrl}
                  alt="Profile"
                  className="w-16 h-16 rounded-full"
                />
              )}
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  {user?.firstName} {user?.lastName}
                </h1>
                <p className="text-sm text-gray-600">
                  {user?.emailAddresses[0]?.emailAddress}
                </p>
              </div>
            </div>
            <button
              onClick={handleSignOut}
              className="bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 transition-colors"
            >
              Sign Out
            </button>
          </div>
        </div>

        {/* Auth State Details */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4">Authentication State</h2>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-green-50 border border-green-200 rounded-md p-4">
              <p className="text-sm font-medium text-green-900 mb-1">
                Signed In
              </p>
              <p className="text-2xl font-bold text-green-700">
                {isSignedIn ? 'Yes' : 'No'}
              </p>
            </div>

            <div className="bg-blue-50 border border-blue-200 rounded-md p-4">
              <p className="text-sm font-medium text-blue-900 mb-1">
                User ID
              </p>
              <p className="text-xs font-mono text-blue-700 break-all">
                {userId}
              </p>
            </div>
          </div>
        </div>

        {/* User Information */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4">User Information</h2>

          <div className="space-y-3">
            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-gray-600">Full Name:</span>
              <span className="text-gray-900">
                {user?.fullName || 'Not set'}
              </span>
            </div>

            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-gray-600">Username:</span>
              <span className="text-gray-900">
                {user?.username || 'Not set'}
              </span>
            </div>

            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-gray-600">Primary Email:</span>
              <span className="text-gray-900">
                {user?.primaryEmailAddress?.emailAddress || 'Not set'}
              </span>
            </div>

            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-gray-600">Email Verified:</span>
              <span className="text-gray-900">
                {user?.primaryEmailAddress?.verification?.status === 'verified'
                  ? '✓ Verified'
                  : '✗ Not Verified'}
              </span>
            </div>

            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-gray-600">Phone Number:</span>
              <span className="text-gray-900">
                {user?.primaryPhoneNumber?.phoneNumber || 'Not set'}
              </span>
            </div>

            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-gray-600">Created At:</span>
              <span className="text-gray-900">
                {user?.createdAt
                  ? new Date(user.createdAt).toLocaleDateString()
                  : 'Unknown'}
              </span>
            </div>

            <div className="flex justify-between">
              <span className="font-medium text-gray-600">Last Sign In:</span>
              <span className="text-gray-900">
                {user?.lastSignInAt
                  ? new Date(user.lastSignInAt).toLocaleString()
                  : 'Unknown'}
              </span>
            </div>
          </div>
        </div>

        {/* Code Examples */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4">Hook Usage Examples</h2>

          <div className="space-y-4">
            <div>
              <h3 className="font-medium mb-2 text-gray-900">
                1. useAuth() - Authentication State
              </h3>
              <pre className="bg-gray-900 text-gray-100 p-4 rounded-md overflow-x-auto text-sm">
{`'use client';
import { useAuth } from '@clerk/nextjs';

const { userId, isLoaded, isSignedIn } = useAuth();

if (!isLoaded) return <div>Loading...</div>;
if (!isSignedIn) return <div>Please sign in</div>;`}
              </pre>
            </div>

            <div>
              <h3 className="font-medium mb-2 text-gray-900">
                2. useUser() - User Data
              </h3>
              <pre className="bg-gray-900 text-gray-100 p-4 rounded-md overflow-x-auto text-sm">
{`'use client';
import { useUser } from '@clerk/nextjs';

const { user, isLoaded } = useUser();

if (!isLoaded) return <div>Loading user...</div>;

return <div>Hello {user.firstName}</div>;`}
              </pre>
            </div>

            <div>
              <h3 className="font-medium mb-2 text-gray-900">
                3. useClerk() - Clerk Methods
              </h3>
              <pre className="bg-gray-900 text-gray-100 p-4 rounded-md overflow-x-auto text-sm">
{`'use client';
import { useClerk } from '@clerk/nextjs';

const { signOut, openSignIn, openUserProfile } = useClerk();

const handleSignOut = () => signOut();
const handleProfile = () => openUserProfile();`}
              </pre>
            </div>
          </div>
        </div>

        {/* Best Practices */}
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
          <h2 className="text-xl font-semibold mb-3 text-yellow-900">
            Client Component Best Practices
          </h2>
          <ul className="space-y-2 text-sm text-yellow-900">
            <li className="flex items-start">
              <span className="mr-2">✓</span>
              <span>
                Always use <code className="bg-yellow-100 px-1 rounded">'use client'</code>{' '}
                directive at the top of the file
              </span>
            </li>
            <li className="flex items-start">
              <span className="mr-2">✓</span>
              <span>
                Check <code className="bg-yellow-100 px-1 rounded">isLoaded</code>{' '}
                before rendering auth-dependent content
              </span>
            </li>
            <li className="flex items-start">
              <span className="mr-2">✓</span>
              <span>
                Use <code className="bg-yellow-100 px-1 rounded">useAuth()</code> for auth state,{' '}
                <code className="bg-yellow-100 px-1 rounded">useUser()</code> for user data
              </span>
            </li>
            <li className="flex items-start">
              <span className="mr-2">✓</span>
              <span>
                Don't use client hooks in Server Components - use{' '}
                <code className="bg-yellow-100 px-1 rounded">auth()</code> instead
              </span>
            </li>
            <li className="flex items-start">
              <span className="mr-2">✓</span>
              <span>
                Handle loading, signed-in, and signed-out states separately
              </span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
}
