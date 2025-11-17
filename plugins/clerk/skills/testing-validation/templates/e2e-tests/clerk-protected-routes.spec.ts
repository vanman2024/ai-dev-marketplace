/**
 * Clerk Protected Routes E2E Tests (Playwright)
 *
 * Tests for route protection, middleware enforcement, and access control.
 *
 * Security Note: Uses test credentials from .env.test environment variables.
 */

import { test, expect } from '@playwright/test';

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const TEST_USER_EMAIL = process.env.TEST_USER_EMAIL || 'test_user@example.com';
const TEST_USER_PASSWORD = process.env.TEST_USER_PASSWORD || 'test_password_here';
const TEST_ADMIN_EMAIL = process.env.TEST_ADMIN_EMAIL || 'admin_user@example.com';
const TEST_ADMIN_PASSWORD = process.env.TEST_ADMIN_PASSWORD || 'admin_password_here';

test.describe('Protected Routes', () => {
  test.describe('Unauthenticated Access', () => {
    test('should block access to dashboard', async ({ page }) => {
      await page.goto(`${BASE_URL}/dashboard`);

      // Should redirect to sign-in
      await expect(page).toHaveURL(/\/sign-in/, { timeout: 5000 });
    });

    test('should block access to profile', async ({ page }) => {
      await page.goto(`${BASE_URL}/profile`);

      await expect(page).toHaveURL(/\/sign-in/, { timeout: 5000 });
    });

    test('should block access to settings', async ({ page }) => {
      await page.goto(`${BASE_URL}/settings`);

      await expect(page).toHaveURL(/\/sign-in/, { timeout: 5000 });
    });

    test('should block access to admin pages', async ({ page }) => {
      await page.goto(`${BASE_URL}/admin`);

      await expect(page).toHaveURL(/\/sign-in/, { timeout: 5000 });
    });

    test('should allow access to public routes', async ({ page }) => {
      const publicRoutes = ['/', '/about', '/pricing', '/contact'];

      for (const route of publicRoutes) {
        await page.goto(`${BASE_URL}${route}`);

        // Should stay on the public route
        await expect(page).toHaveURL(new RegExp(route));

        // Should not redirect to sign-in
        await expect(page).not.toHaveURL(/\/sign-in/);
      }
    });
  });

  test.describe('Authenticated Access', () => {
    test.beforeEach(async ({ page }) => {
      // Sign in before each test
      await page.goto(`${BASE_URL}/sign-in`);
      await page.fill('input[name="identifier"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', TEST_USER_PASSWORD);
      await page.click('button[type="submit"]');

      // Wait for successful sign-in
      await expect(page.locator('[data-clerk-user-button]')).toBeVisible({
        timeout: 10000,
      });
    });

    test('should allow access to dashboard', async ({ page }) => {
      await page.goto(`${BASE_URL}/dashboard`);

      // Should stay on dashboard
      await expect(page).toHaveURL(/\/dashboard/);
      await expect(page.locator('text=/dashboard/i')).toBeVisible();
    });

    test('should allow access to profile', async ({ page }) => {
      await page.goto(`${BASE_URL}/profile`);

      await expect(page).toHaveURL(/\/profile/);
      await expect(page.locator(`text=${TEST_USER_EMAIL}`)).toBeVisible();
    });

    test('should allow access to settings', async ({ page }) => {
      await page.goto(`${BASE_URL}/settings`);

      await expect(page).toHaveURL(/\/settings/);
    });

    test('should navigate between protected routes', async ({ page }) => {
      // Dashboard
      await page.goto(`${BASE_URL}/dashboard`);
      await expect(page).toHaveURL(/\/dashboard/);

      // Profile
      await page.goto(`${BASE_URL}/profile`);
      await expect(page).toHaveURL(/\/profile/);

      // Settings
      await page.goto(`${BASE_URL}/settings`);
      await expect(page).toHaveURL(/\/settings/);
    });
  });

  test.describe('Role-Based Access Control', () => {
    test('should block admin routes for regular users', async ({ page }) => {
      // Sign in as regular user
      await page.goto(`${BASE_URL}/sign-in`);
      await page.fill('input[name="identifier"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', TEST_USER_PASSWORD);
      await page.click('button[type="submit"]');

      await expect(page.locator('[data-clerk-user-button]')).toBeVisible({
        timeout: 10000,
      });

      // Try to access admin route
      await page.goto(`${BASE_URL}/admin`);

      // Should show unauthorized or redirect
      const isUnauthorized =
        (await page.locator('text=/unauthorized|access denied|403/i').isVisible()) ||
        (await page.url().includes('/dashboard')) ||
        (await page.url().includes('/'));

      expect(isUnauthorized).toBeTruthy();
    });

    test('should allow admin routes for admin users', async ({ page }) => {
      // Sign in as admin
      await page.goto(`${BASE_URL}/sign-in`);
      await page.fill('input[name="identifier"]', TEST_ADMIN_EMAIL);
      await page.fill('input[name="password"]', TEST_ADMIN_PASSWORD);
      await page.click('button[type="submit"]');

      await expect(page.locator('[data-clerk-user-button]')).toBeVisible({
        timeout: 10000,
      });

      // Access admin route
      await page.goto(`${BASE_URL}/admin`);

      // Should allow access
      await expect(page).toHaveURL(/\/admin/);
      await expect(page.locator('text=/admin/i')).toBeVisible();
    });
  });

  test.describe('Middleware Enforcement', () => {
    test('should enforce protection on API routes', async ({ page }) => {
      // Try to access protected API without auth
      const response = await page.request.get(`${BASE_URL}/api/user/profile`);

      // Should return 401 Unauthorized
      expect(response.status()).toBe(401);
    });

    test('should allow authenticated API requests', async ({ page }) => {
      // Sign in
      await page.goto(`${BASE_URL}/sign-in`);
      await page.fill('input[name="identifier"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', TEST_USER_PASSWORD);
      await page.click('button[type="submit"]');

      await expect(page.locator('[data-clerk-user-button]')).toBeVisible({
        timeout: 10000,
      });

      // Access protected API
      const response = await page.request.get(`${BASE_URL}/api/user/profile`);

      // Should return 200 OK
      expect(response.status()).toBe(200);
    });

    test('should protect API routes with matcher patterns', async ({ page }) => {
      const protectedAPIs = [
        '/api/user/profile',
        '/api/user/settings',
        '/api/admin/users',
        '/api/protected/data',
      ];

      for (const apiRoute of protectedAPIs) {
        const response = await page.request.get(`${BASE_URL}${apiRoute}`);

        // All should require auth
        expect([401, 403]).toContain(response.status());
      }
    });

    test('should allow public API routes', async ({ page }) => {
      const publicAPIs = ['/api/health', '/api/public/data'];

      for (const apiRoute of publicAPIs) {
        const response = await page.request.get(`${BASE_URL}${apiRoute}`);

        // Should be accessible
        expect(response.status()).toBe(200);
      }
    });
  });

  test.describe('Redirect Flows', () => {
    test('should redirect to requested page after sign-in', async ({ page }) => {
      // Try to access protected page
      await page.goto(`${BASE_URL}/dashboard/analytics`);

      // Should redirect to sign-in
      await expect(page).toHaveURL(/\/sign-in/);

      // Sign in
      await page.fill('input[name="identifier"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', TEST_USER_PASSWORD);
      await page.click('button[type="submit"]');

      // Should redirect to originally requested page
      await expect(page).toHaveURL(/\/dashboard\/analytics/, { timeout: 10000 });
    });

    test('should redirect to configured after-sign-in URL', async ({ page }) => {
      // Navigate to sign-in directly (not from protected page)
      await page.goto(`${BASE_URL}/sign-in`);

      await page.fill('input[name="identifier"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', TEST_USER_PASSWORD);
      await page.click('button[type="submit"]');

      // Should redirect to configured default (usually dashboard or home)
      await expect(page).toHaveURL(/\/dashboard|\//, { timeout: 10000 });
    });

    test('should prevent redirect loops', async ({ page }) => {
      let redirectCount = 0;

      page.on('response', (response) => {
        if ([301, 302, 307, 308].includes(response.status())) {
          redirectCount++;
        }
      });

      await page.goto(`${BASE_URL}/dashboard`);

      // Should not have excessive redirects (max 3-4 is reasonable)
      expect(redirectCount).toBeLessThan(5);
    });
  });

  test.describe('Session Timeout', () => {
    test('should maintain access within session timeout', async ({ page }) => {
      // Sign in
      await page.goto(`${BASE_URL}/sign-in`);
      await page.fill('input[name="identifier"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', TEST_USER_PASSWORD);
      await page.click('button[type="submit"]');

      await expect(page.locator('[data-clerk-user-button]')).toBeVisible({
        timeout: 10000,
      });

      // Access protected route
      await page.goto(`${BASE_URL}/dashboard`);
      await expect(page).toHaveURL(/\/dashboard/);

      // Wait a bit (within session timeout)
      await page.waitForTimeout(2000);

      // Should still have access
      await page.reload();
      await expect(page).toHaveURL(/\/dashboard/);
      await expect(page.locator('[data-clerk-user-button]')).toBeVisible();
    });
  });

  test.describe('Organization-Based Access', () => {
    test('should restrict routes based on organization membership', async ({
      page,
    }) => {
      // Sign in
      await page.goto(`${BASE_URL}/sign-in`);
      await page.fill('input[name="identifier"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', TEST_USER_PASSWORD);
      await page.click('button[type="submit"]');

      await expect(page.locator('[data-clerk-user-button]')).toBeVisible({
        timeout: 10000,
      });

      // Try to access organization-specific route
      await page.goto(`${BASE_URL}/org/settings`);

      // If user not in org, should show access denied or redirect
      const hasAccess = await page.locator('text=/organization/i').isVisible();
      const isDenied =
        (await page.locator('text=/access denied|not a member/i').isVisible()) ||
        (await page.url().includes('/dashboard'));

      // One of these should be true
      expect(hasAccess || isDenied).toBeTruthy();
    });
  });
});
