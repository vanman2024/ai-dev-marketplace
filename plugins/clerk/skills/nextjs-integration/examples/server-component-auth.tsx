import { auth, currentUser, clerkClient } from '@clerk/nextjs';
import { redirect } from 'next/navigation';

/**
 * Advanced Server Component authentication example
 *
 * This demonstrates:
 * - Multiple auth patterns in Server Components
 * - Using clerkClient for advanced queries
 * - Organization/team context
 * - Session claims and metadata
 * - Data fetching based on auth state
 *
 * @see https://clerk.com/docs/references/nextjs/auth
 * @see https://clerk.com/docs/references/backend/overview
 */

interface UserData {
  id: string;
  name: string;
  email: string;
  role: string;
  lastLogin: Date;
}

// Simulated data fetching function
async function fetchUserData(userId: string): Promise<UserData> {
  // In a real app, fetch from your database using the userId
  return {
    id: userId,
    name: 'John Doe',
    email: 'john@example.com',
    role: 'admin',
    lastLogin: new Date(),
  };
}

export default async function ServerComponentAuthExample() {
  // Method 1: Get basic auth state
  const { userId, sessionId, orgId } = auth();

  // Protect route - redirect if not authenticated
  if (!userId) {
    redirect('/sign-in');
  }

  // Method 2: Get full user object
  const user = await currentUser();

  // Method 3: Use Clerk Backend API for advanced queries
  // const sessions = await clerkClient.sessions.getSessionList({ userId });
  // const organizations = await clerkClient.organizations.getOrganizationList();

  // Fetch app-specific data using authenticated user ID
  const userData = await fetchUserData(userId);

  // Access session claims (custom metadata)
  // const sessionClaims = auth().sessionClaims;
  // const customRole = sessionClaims?.metadata?.role;

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header Section */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          <h1 className="text-2xl font-bold text-gray-900 mb-2">
            Server Component Authentication
          </h1>
          <p className="text-gray-600">
            Examples of authentication patterns in Next.js Server Components
          </p>
        </div>

        {/* Auth State Information */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          <h2 className="text-xl font-semibold mb-4">Authentication State</h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="border rounded-md p-4">
              <h3 className="font-medium text-gray-900 mb-2">
                Basic Auth (auth())
              </h3>
              <dl className="space-y-1 text-sm">
                <div className="flex justify-between">
                  <dt className="text-gray-600">User ID:</dt>
                  <dd className="font-mono text-xs">{userId}</dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-600">Session ID:</dt>
                  <dd className="font-mono text-xs">{sessionId}</dd>
                </div>
                {orgId && (
                  <div className="flex justify-between">
                    <dt className="text-gray-600">Organization:</dt>
                    <dd className="font-mono text-xs">{orgId}</dd>
                  </div>
                )}
              </dl>
            </div>

            <div className="border rounded-md p-4">
              <h3 className="font-medium text-gray-900 mb-2">
                User Object (currentUser())
              </h3>
              <dl className="space-y-1 text-sm">
                <div className="flex justify-between">
                  <dt className="text-gray-600">Name:</dt>
                  <dd>
                    {user?.firstName} {user?.lastName}
                  </dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-600">Email:</dt>
                  <dd className="text-xs">
                    {user?.emailAddresses[0]?.emailAddress}
                  </dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-600">Verified:</dt>
                  <dd>
                    {user?.emailAddresses[0]?.verification?.status === 'verified'
                      ? '✓ Yes'
                      : '✗ No'}
                  </dd>
                </div>
              </dl>
            </div>
          </div>
        </div>

        {/* App Data Section */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          <h2 className="text-xl font-semibold mb-4">Application Data</h2>

          <div className="bg-blue-50 border border-blue-200 rounded-md p-4">
            <p className="text-sm text-blue-900 mb-2">
              Data fetched from your database using authenticated user ID:
            </p>
            <dl className="space-y-1 text-sm">
              <div className="flex justify-between">
                <dt className="font-medium">Name:</dt>
                <dd>{userData.name}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="font-medium">Email:</dt>
                <dd>{userData.email}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="font-medium">Role:</dt>
                <dd className="uppercase text-xs font-semibold">
                  {userData.role}
                </dd>
              </div>
              <div className="flex justify-between">
                <dt className="font-medium">Last Login:</dt>
                <dd>{userData.lastLogin.toLocaleString()}</dd>
              </div>
            </dl>
          </div>
        </div>

        {/* Code Examples */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          <h2 className="text-xl font-semibold mb-4">Code Patterns</h2>

          <div className="space-y-4">
            <div>
              <h3 className="font-medium mb-2">1. Basic Authentication Check</h3>
              <pre className="bg-gray-900 text-gray-100 p-4 rounded-md overflow-x-auto text-sm">
{`import { auth } from '@clerk/nextjs';

const { userId } = auth();
if (!userId) redirect('/sign-in');`}
              </pre>
            </div>

            <div>
              <h3 className="font-medium mb-2">2. Get Current User</h3>
              <pre className="bg-gray-900 text-gray-100 p-4 rounded-md overflow-x-auto text-sm">
{`import { currentUser } from '@clerk/nextjs';

const user = await currentUser();
const email = user?.emailAddresses[0]?.emailAddress;`}
              </pre>
            </div>

            <div>
              <h3 className="font-medium mb-2">3. Organization Context</h3>
              <pre className="bg-gray-900 text-gray-100 p-4 rounded-md overflow-x-auto text-sm">
{`import { auth } from '@clerk/nextjs';

const { orgId, orgRole, orgSlug } = auth();
if (!orgId) {
  return <div>Please select an organization</div>;
}`}
              </pre>
            </div>

            <div>
              <h3 className="font-medium mb-2">4. Backend API Client</h3>
              <pre className="bg-gray-900 text-gray-100 p-4 rounded-md overflow-x-auto text-sm">
{`import { clerkClient } from '@clerk/nextjs';

// Get user sessions
const sessions = await clerkClient.sessions
  .getSessionList({ userId });

// Get organizations
const orgs = await clerkClient.organizations
  .getOrganizationList();`}
              </pre>
            </div>
          </div>
        </div>

        {/* Best Practices */}
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
          <h2 className="text-xl font-semibold mb-3">Best Practices</h2>
          <ul className="space-y-2 text-sm">
            <li className="flex items-start">
              <span className="text-yellow-600 mr-2">•</span>
              <span>
                Always check <code className="bg-yellow-100 px-1 rounded">userId</code>{' '}
                before accessing protected data
              </span>
            </li>
            <li className="flex items-start">
              <span className="text-yellow-600 mr-2">•</span>
              <span>
                Use <code className="bg-yellow-100 px-1 rounded">auth()</code> for basic checks,{' '}
                <code className="bg-yellow-100 px-1 rounded">currentUser()</code> when you need full user data
              </span>
            </li>
            <li className="flex items-start">
              <span className="text-yellow-600 mr-2">•</span>
              <span>
                Never use <code className="bg-yellow-100 px-1 rounded">useAuth()</code> or{' '}
                <code className="bg-yellow-100 px-1 rounded">useUser()</code> in Server Components
              </span>
            </li>
            <li className="flex items-start">
              <span className="text-yellow-600 mr-2">•</span>
              <span>
                For API routes, use <code className="bg-yellow-100 px-1 rounded">getAuth(req)</code>{' '}
                in Pages Router or <code className="bg-yellow-100 px-1 rounded">auth()</code> in App Router
              </span>
            </li>
            <li className="flex items-start">
              <span className="text-yellow-600 mr-2">•</span>
              <span>
                Cache expensive <code className="bg-yellow-100 px-1 rounded">clerkClient</code> calls when appropriate
              </span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
}
