import { auth, currentUser } from '@clerk/nextjs';
import { redirect } from 'next/navigation';

/**
 * Protected route example for App Router
 *
 * This Server Component demonstrates:
 * - Authentication check with auth()
 * - Fetching user data with currentUser()
 * - Redirecting unauthenticated users
 * - Displaying user information
 *
 * @see https://clerk.com/docs/references/nextjs/auth
 */
export default async function ProtectedPage() {
  // Get authentication state (Server Component only)
  const { userId } = auth();

  // Redirect to sign-in if not authenticated
  if (!userId) {
    redirect('/sign-in');
  }

  // Fetch full user object (optional)
  const user = await currentUser();

  // Get user's email address
  const email = user?.emailAddresses[0]?.emailAddress;

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100 p-8">
      <div className="max-w-2xl mx-auto">
        <div className="bg-white rounded-lg shadow-md p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">
            Protected Dashboard
          </h1>

          <div className="space-y-4">
            <div className="border-l-4 border-blue-500 pl-4">
              <p className="text-sm text-gray-600">Welcome back!</p>
              <p className="text-xl font-semibold text-gray-900">
                {user?.firstName} {user?.lastName}
              </p>
            </div>

            <div className="bg-gray-50 rounded-md p-4 space-y-2">
              <div className="flex justify-between">
                <span className="text-sm font-medium text-gray-600">
                  User ID:
                </span>
                <span className="text-sm text-gray-900 font-mono">
                  {userId}
                </span>
              </div>

              {email && (
                <div className="flex justify-between">
                  <span className="text-sm font-medium text-gray-600">
                    Email:
                  </span>
                  <span className="text-sm text-gray-900">
                    {email}
                  </span>
                </div>
              )}

              <div className="flex justify-between">
                <span className="text-sm font-medium text-gray-600">
                  Created:
                </span>
                <span className="text-sm text-gray-900">
                  {user?.createdAt
                    ? new Date(user.createdAt).toLocaleDateString()
                    : 'N/A'}
                </span>
              </div>
            </div>

            <div className="pt-4">
              <p className="text-sm text-gray-600 mb-2">
                This is a protected route. Only authenticated users can access this page.
              </p>
              <p className="text-xs text-gray-500">
                Protected using Clerk's <code className="bg-gray-100 px-1 rounded">auth()</code> helper in a Server Component.
              </p>
            </div>
          </div>
        </div>

        {/* Additional protected content examples */}
        <div className="mt-8 grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold mb-2">Profile Settings</h2>
            <p className="text-sm text-gray-600">
              Manage your account settings and preferences.
            </p>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold mb-2">Security</h2>
            <p className="text-sm text-gray-600">
              Update your password and security settings.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
