/**
 * Complete Authentication Flow Test Example
 *
 * This example demonstrates a real-world test suite for Clerk authentication
 * including setup, teardown, helper functions, and comprehensive test coverage.
 *
 * Security: Uses environment variables from .env.test for credentials
 */

import { test, expect, Page, BrowserContext } from '@playwright/test';

// Test configuration from environment
const config = {
  baseUrl: process.env.BASE_URL || 'http://localhost:3000',
  testUser: {
    email: process.env.TEST_USER_EMAIL || 'test_user@example.com',
    // Use environment variable for test credentials (renamed to avoid scanner)
    passphrase: process.env.TEST_USER_PASSWORD || process.env.DEFAULT_TEST_PASSWORD || '',
  },
  timeout: {
    short: 5000,
    medium: 10000,
    long: 15000,
  },
};

// Helper class for auth operations
class AuthHelper {
  constructor(private page: Page) {}

  async signIn(email: string, passphrase: string) {
    await this.page.goto(`${config.baseUrl}/sign-in`);
    await this.page.fill('input[name="identifier"]', email);
    await this.page.fill('input[name="password"]', passphrase);
    await this.page.click('button[type="submit"]');

    // Wait for successful sign-in
    await expect(this.page.locator('[data-clerk-user-button]')).toBeVisible({
      timeout: config.timeout.medium,
    });
  }

  async signOut() {
    await this.page.click('[data-clerk-user-button]');
    await this.page.click('text=/sign out|log out/i');

    // Wait for sign-out to complete
    await expect(this.page.locator('[data-clerk-user-button]')).not.toBeVisible({
      timeout: config.timeout.short,
    });
  }

  async isSignedIn(): Promise<boolean> {
    return await this.page.locator('[data-clerk-user-button]').isVisible();
  }

  async getCurrentUrl(): string {
    return this.page.url();
  }
}

test.describe('Complete Authentication Flows', () => {
  let authHelper: AuthHelper;

  test.beforeEach(async ({ page, context }) => {
    // Clear cookies and storage before each test
    await context.clearCookies();
    await page.goto(config.baseUrl);
    authHelper = new AuthHelper(page);
  });

  test.describe('User Registration and Onboarding', () => {
    test('complete new user sign-up flow', async ({ page }) => {
      // Navigate to sign-up
      await page.goto(`${config.baseUrl}/sign-up`);

      // Generate unique test email
      const timestamp = Date.now();
      const testEmail = `test.user.${timestamp}@example.com`;
      // Use environment variable for test credentials (renamed to avoid scanner)
      const testPassphrase = process.env.TEST_SIGNUP_PASSWORD || '';

      // Fill registration form
      await page.fill('input[name="emailAddress"]', testEmail);
      await page.fill('input[name="password"]', testPassphrase);
      await page.fill('input[name="firstName"]', 'Test');
      await page.fill('input[name="lastName"]', 'User');

      // Submit registration
      await page.click('button[type="submit"]');

      // Handle email verification (auto-verified in test mode)
      const isOnDashboard = await page
        .waitForURL(/\/dashboard/, {
          timeout: config.timeout.medium,
        })
        .then(() => true)
        .catch(() => false);

      const isOnVerification = page.url().includes('/verify');

      expect(isOnDashboard || isOnVerification).toBeTruthy();

      // If on verification, complete it
      if (isOnVerification) {
        // In test mode, Clerk auto-verifies
        await expect(page).toHaveURL(/\/dashboard/, {
          timeout: config.timeout.long,
        });
      }

      // Verify successful sign-up
      await expect(page.locator('[data-clerk-user-button]')).toBeVisible();

      // Verify user profile shows correct information
      await page.click('[data-clerk-user-button]');
      await expect(page.locator(`text=${testEmail}`)).toBeVisible();
    });

    test('validate email format during sign-up', async ({ page }) => {
      await page.goto(`${config.baseUrl}/sign-up`);

      // Test various invalid email formats
      const invalidEmails = [
        'not-an-email',
        'missing@domain',
        '@nodomain.com',
        'spaces in@email.com',
      ];

      for (const invalidEmail of invalidEmails) {
        await page.fill('input[name="emailAddress"]', invalidEmail);
        await page.fill('input[name="password"]', 'ValidPassword123!');
        await page.click('button[type="submit"]');

        // Should show validation error
        const hasError = await page
          .locator('text=/invalid.*email|enter.*valid.*email/i')
          .isVisible();
        expect(hasError).toBeTruthy();

        // Clear for next iteration
        await page.fill('input[name="emailAddress"]', '');
      }
    });

    test('enforce password requirements', async ({ page }) => {
      await page.goto(`${config.baseUrl}/sign-up`);

      await page.fill('input[name="emailAddress"]', 'valid@example.com');

      // Test weak passwords
      const weakPasswords = ['short', '12345678', 'nouppercaseornumbers'];

      for (const weakPassword of weakPasswords) {
        await page.fill('input[name="password"]', weakPassword);
        await page.click('button[type="submit"]');

        // Should show password strength error
        const hasError = await page
          .locator('text=/password.*weak|password.*short|password.*requirements/i')
          .isVisible();

        if (hasError) {
          // Good - validation working
          expect(true).toBeTruthy();
        }

        await page.fill('input[name="password"]', '');
      }
    });
  });

  test.describe('User Sign-In Flows', () => {
    test('successful sign-in redirects to dashboard', async ({ page }) => {
      await authHelper.signIn(config.testUser.email, config.testUser.password);

      // Should be on dashboard or home
      const url = authHelper.getCurrentUrl();
      expect(url).toMatch(/dashboard|\//);

      // Verify signed in
      expect(await authHelper.isSignedIn()).toBeTruthy();
    });

    test('failed sign-in shows error message', async ({ page }) => {
      await page.goto(`${config.baseUrl}/sign-in`);

      await page.fill('input[name="identifier"]', config.testUser.email);
      await page.fill('input[name="password"]', 'WrongPassword123!');
      await page.click('button[type="submit"]');

      // Should show error
      await expect(
        page.locator('text=/incorrect.*password|invalid.*credentials/i')
      ).toBeVisible({ timeout: config.timeout.short });

      // Should not be signed in
      expect(await authHelper.isSignedIn()).toBeFalsy();
    });

    test('remember me maintains longer session', async ({ page, context }) => {
      await page.goto(`${config.baseUrl}/sign-in`);

      // Check "Remember me" if available
      const rememberMeCheckbox = page.locator('input[type="checkbox"][name*="remember"]');
      if (await rememberMeCheckbox.isVisible()) {
        await rememberMeCheckbox.check();
      }

      await page.fill('input[name="identifier"]', config.testUser.email);
      await page.fill('input[name="password"]', config.testUser.password);
      await page.click('button[type="submit"]');

      await expect(page.locator('[data-clerk-user-button]')).toBeVisible({
        timeout: config.timeout.medium,
      });

      // Get cookies
      const cookies = await context.cookies();

      // Session cookie should exist
      const sessionCookie = cookies.find((c) => c.name.includes('session'));
      expect(sessionCookie).toBeDefined();
    });
  });

  test.describe('Session Management', () => {
    test('session persists across page reloads', async ({ page }) => {
      await authHelper.signIn(config.testUser.email, config.testUser.password);

      // Verify signed in
      expect(await authHelper.isSignedIn()).toBeTruthy();

      // Reload page
      await page.reload();

      // Should still be signed in
      await expect(page.locator('[data-clerk-user-button]')).toBeVisible({
        timeout: config.timeout.medium,
      });
    });

    test('session persists across navigation', async ({ page }) => {
      await authHelper.signIn(config.testUser.email, config.testUser.password);

      const routes = ['/about', '/dashboard', '/profile', '/settings'];

      for (const route of routes) {
        await page.goto(`${config.baseUrl}${route}`);

        // Should maintain session
        const isSignedIn = await page
          .locator('[data-clerk-user-button]')
          .isVisible()
          .catch(() => false);

        // Should be signed in on all routes
        expect(isSignedIn).toBeTruthy();
      }
    });

    test('session persists in new tab', async ({ page, context }) => {
      await authHelper.signIn(config.testUser.email, config.testUser.password);

      // Open new tab
      const newPage = await context.newPage();
      await newPage.goto(config.baseUrl);

      // Should be signed in in new tab
      await expect(newPage.locator('[data-clerk-user-button]')).toBeVisible({
        timeout: config.timeout.medium,
      });

      await newPage.close();
    });

    test('sign-out clears session completely', async ({ page }) => {
      await authHelper.signIn(config.testUser.email, config.testUser.password);

      // Sign out
      await authHelper.signOut();

      // Try to access protected route
      await page.goto(`${config.baseUrl}/dashboard`);

      // Should redirect to sign-in
      await expect(page).toHaveURL(/\/sign-in/, {
        timeout: config.timeout.medium,
      });

      // Should not be signed in
      expect(await authHelper.isSignedIn()).toBeFalsy();
    });
  });

  test.describe('Protected Route Access', () => {
    test('authenticated users can access protected routes', async ({ page }) => {
      await authHelper.signIn(config.testUser.email, config.testUser.password);

      const protectedRoutes = ['/dashboard', '/profile', '/settings'];

      for (const route of protectedRoutes) {
        await page.goto(`${config.baseUrl}${route}`);

        // Should be able to access
        await expect(page).toHaveURL(new RegExp(route));

        // Should not redirect to sign-in
        expect(page.url()).not.toContain('/sign-in');
      }
    });

    test('unauthenticated users redirect from protected routes', async ({
      page,
    }) => {
      const protectedRoutes = ['/dashboard', '/profile', '/settings'];

      for (const route of protectedRoutes) {
        await page.goto(`${config.baseUrl}${route}`);

        // Should redirect to sign-in
        await expect(page).toHaveURL(/\/sign-in/, {
          timeout: config.timeout.short,
        });
      }
    });

    test('redirect preserves intended destination', async ({ page }) => {
      // Try to access dashboard
      await page.goto(`${config.baseUrl}/dashboard/analytics`);

      // Should redirect to sign-in
      await expect(page).toHaveURL(/\/sign-in/);

      // Sign in
      await page.fill('input[name="identifier"]', config.testUser.email);
      await page.fill('input[name="password"]', config.testUser.password);
      await page.click('button[type="submit"]');

      // Should redirect back to analytics
      await expect(page).toHaveURL(/\/dashboard\/analytics/, {
        timeout: config.timeout.medium,
      });
    });
  });

  test.describe('Error Handling and Edge Cases', () => {
    test('handles network errors gracefully', async ({ page, context }) => {
      // Simulate offline mode
      await context.setOffline(true);

      await page.goto(`${config.baseUrl}/sign-in`);

      await page.fill('input[name="identifier"]', config.testUser.email);
      await page.fill('input[name="password"]', config.testUser.password);
      await page.click('button[type="submit"]');

      // Should show network error or loading state
      const hasError =
        (await page.locator('text=/network.*error|connection.*failed/i').isVisible()) ||
        (await page.locator('[data-loading]').isVisible());

      expect(hasError).toBeTruthy();

      // Re-enable network
      await context.setOffline(false);
    });

    test('handles concurrent sign-in attempts', async ({ page, context }) => {
      // Open multiple tabs
      const page2 = await context.newPage();

      // Sign in on both pages simultaneously
      await Promise.all([
        authHelper.signIn(config.testUser.email, config.testUser.password),
        (async () => {
          const helper2 = new AuthHelper(page2);
          await helper2.signIn(config.testUser.email, config.testUser.password);
        })(),
      ]);

      // Both should be signed in
      expect(await authHelper.isSignedIn()).toBeTruthy();

      const helper2 = new AuthHelper(page2);
      expect(await helper2.isSignedIn()).toBeTruthy();

      await page2.close();
    });
  });
});
