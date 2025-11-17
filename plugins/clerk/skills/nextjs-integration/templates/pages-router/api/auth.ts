import { getAuth } from '@clerk/nextjs/server';
import type { NextApiRequest, NextApiResponse } from 'next';

/**
 * Protected API route example for Pages Router
 *
 * This demonstrates how to protect API routes and access
 * user authentication data in Pages Router.
 *
 * @see https://clerk.com/docs/references/nextjs/get-auth
 */
export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // Get authentication state from request
  const { userId, sessionId, getToken } = getAuth(req);

  // Check if user is authenticated
  if (!userId) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'You must be signed in to access this endpoint'
    });
  }

  // Optional: Get session token for external API calls
  // const token = await getToken({ template: 'your-template' });

  // Return protected data
  return res.status(200).json({
    message: 'Successfully accessed protected route',
    userId,
    sessionId,
    timestamp: new Date().toISOString(),
  });
}
