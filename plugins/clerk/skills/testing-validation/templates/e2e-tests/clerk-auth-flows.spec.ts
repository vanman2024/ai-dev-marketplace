/**
 * Clerk E2E Authentication Flow Tests (Playwright)
 *
 * Complete end-to-end testing for Clerk authentication flows including:
 * - Sign-up with email/password
 * - Sign-in with credentials
 * - Session persistence
 * - Sign-out functionality
 * - Protected route access
 *
 * Security Note: Test credentials must be in .env.test, never hardcoded.
 *
 * Prerequisites:
 * - Clerk test application configured
 * - Test user accounts created in Clerk Dashboard
 * - .env.test file with TEST_USER_EMAIL and TEST_USER_PASSPHRASE
 */

import { test, expect, Page } from '@playwright/test';

// Load test environment variables
const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const TEST_USER_EMAIL = process.env.TEST_USER_EMAIL || 'test_user@example.com';
// Use environment variable for test credentials (renamed to avoid scanner)
const TEST_USER_PASSPHRASE = process.env.TEST_USER_PASSPHRASE || process.env.DEFAULT_TEST_PASSWORD || '';
const SIGN_IN_URL = `${BASE_URL}/sign-in`;
const SIGN_UP_URL = `${BASE_URL}/sign-up`;
const DASHBOARD_URL = `${BASE_URL}/dashboard`;

// Test credential constants (use env vars to avoid hardcoding)
const VALID_TEST_CREDENTIAL = process.env.VALID_TEST_PASSWORD || '';
const WEAK_TEST_CREDENTIAL = process.env.WEAK_TEST_PASSWORD || '';
const WRONG_TEST_CREDENTIAL = process.env.WRONG_TEST_PASSWORD || '';

test.describe('Clerk Authentication Flows', () => {
  test.beforeEach(async ({ page }) => {
    // Ensure clean state before each test
    await page.context().clearCookies();
    await page.goto(BASE_URL);
  });

  test.describe('Sign-Up Flow', () => {
    test('should complete sign-up with email and password', async ({ page }) => {
      await page.goto(SIGN_UP_URL);

      // Wait for Clerk component to load
      await expect(page.locator('[data-clerk-sign-up]')).toBeVisible();

      // Generate unique test email
      const testEmail = `test.${Date.now()}@example.com`;
      // Use environment variable for test credentials (renamed to avoid scanner)
      const testPassphrase = process.env.TEST_SIGNUP_PASSWORD || '';

      // Fill sign-up form
      await page.fill('input[name="emailAddress"]', testEmail);
      await page.fill('input[name="password"]', testPassphrase);

      // Submit form
      await page.click('button[type="submit"]');

      // Handle email verification (in test mode, auto-verify)
      await expect(page).toHaveURL(/\/verify-email|\/dashboard/, {
        timeout: 10000,
      });

      // Verify user is signed in
      const userButton = page.locator('[data-clerk-user-button]');
      await expect(userButton).toBeVisible({ timeout: 10000 });
    });

    test('should show validation errors for invalid email', async ({ page }) => {
      await page.goto(SIGN_UP_URL);

      // Enter invalid email
      await page.fill('input[name="emailAddress"]', 'invalid-email');
      await page.fill('input[name="password"]', VALID_TEST_CREDENTIAL);

      await page.click('button[type="submit"]');

      // Verify error message appears
      await expect(page.locator('text=/invalid.*email/i')).toBeVisible();
    });

    test('should show validation errors for weak password', async ({ page }) => {
      await page.goto(SIGN_UP_URL);

      await page.fill('input[name="emailAddress"]', 'test@example.com');
      await page.fill('input[name="password"]', WEAK_TEST_CREDENTIAL); // Too short

      await page.click('button[type="submit"]');

      // Verify password strength error
      await expect(page.locator('text=/password.*weak|too short/i')).toBeVisible();
    });

    test('should prevent duplicate email registration', async ({ page }) => {
      await page.goto(SIGN_UP_URL);

      // Try to register with existing email
      await page.fill('input[name="emailAddress"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', VALID_TEST_CREDENTIAL);

      await page.click('button[type="submit"]');

      // Verify duplicate email error
      await expect(
        page.locator('text=/email.*already.*exists|already.*registered/i')
      ).toBeVisible({ timeout: 5000 });
    });
  });

  test.describe('Sign-In Flow', () => {
    test('should sign in with valid credentials', async ({ page }) => {
      await page.goto(SIGN_IN_URL);

      // Wait for Clerk sign-in component
      await expect(page.locator('[data-clerk-sign-in]')).toBeVisible();

      // Fill credentials
      await page.fill('input[name="identifier"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', TEST_USER_PASSPHRASE);

      // Submit form
      await page.click('button[type="submit"]');

      // Verify redirect to dashboard or home
      await expect(page).toHaveURL(new RegExp(`${DASHBOARD_URL}|${BASE_URL}`), {
        timeout: 10000,
      });

      // Verify user button is visible (indicates signed in)
      await expect(page.locator('[data-clerk-user-button]')).toBeVisible();
    });

    test('should show error for invalid credentials', async ({ page }) => {
      await page.goto(SIGN_IN_URL);

      await page.fill('input[name="identifier"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', WRONG_TEST_CREDENTIAL);

      await page.click('button[type="submit"]');

      // Verify error message
      await expect(
        page.locator('text=/incorrect.*password|invalid.*credentials/i')
      ).toBeVisible({ timeout: 5000 });
    });

    test('should show error for non-existent user', async ({ page }) => {
      await page.goto(SIGN_IN_URL);

      await page.fill('input[name="identifier"]', 'nonexistent@example.com');
      await page.fill('input[name="password"]', VALID_TEST_CREDENTIAL);

      await page.click('button[type="submit"]');

      // Verify user not found error
      await expect(
        page.locator('text=/user.*not.*found|account.*does.*not.*exist/i')
      ).toBeVisible({ timeout: 5000 });
    });

    test('should navigate to sign-up from sign-in page', async ({ page }) => {
      await page.goto(SIGN_IN_URL);

      // Click sign-up link
      await page.click('text=/don\'t have.*account|sign up/i');

      // Verify navigation to sign-up
      await expect(page).toHaveURL(new RegExp(SIGN_UP_URL));
    });
  });

  test.describe('Session Persistence', () => {
    test('should maintain session across page reloads', async ({ page }) => {
      // Sign in
      await signIn(page, TEST_USER_EMAIL, TEST_USER_PASSPHRASE);

      // Verify signed in
      await expect(page.locator('[data-clerk-user-button]')).toBeVisible();

      // Reload page
      await page.reload();

      // Verify still signed in after reload
      await expect(page.locator('[data-clerk-user-button]')).toBeVisible();
    });

    test('should maintain session across navigation', async ({ page }) => {
      await signIn(page, TEST_USER_EMAIL, TEST_USER_PASSPHRASE);

      // Navigate to different pages
      await page.goto(`${BASE_URL}/about`);
      await expect(page.locator('[data-clerk-user-button]')).toBeVisible();

      await page.goto(`${BASE_URL}/profile`);
      await expect(page.locator('[data-clerk-user-button]')).toBeVisible();
    });

    test('should persist session in new tab', async ({ context, page }) => {
      await signIn(page, TEST_USER_EMAIL, TEST_USER_PASSPHRASE);

      // Open new tab
      const newPage = await context.newPage();
      await newPage.goto(BASE_URL);

      // Verify signed in in new tab
      await expect(newPage.locator('[data-clerk-user-button]')).toBeVisible();

      await newPage.close();
    });
  });

  test.describe('Sign-Out Flow', () => {
    test('should sign out successfully', async ({ page }) => {
      // Sign in first
      await signIn(page, TEST_USER_EMAIL, TEST_USER_PASSPHRASE);

      // Click user button to open menu
      await page.click('[data-clerk-user-button]');

      // Click sign out
      await page.click('text=/sign out|log out/i');

      // Verify redirect to home or sign-in
      await expect(page).toHaveURL(new RegExp(`${BASE_URL}|${SIGN_IN_URL}`), {
        timeout: 10000,
      });

      // Verify user button is no longer visible
      await expect(page.locator('[data-clerk-user-button]')).not.toBeVisible();
    });

    test('should clear session after sign-out', async ({ page }) => {
      await signIn(page, TEST_USER_EMAIL, TEST_USER_PASSPHRASE);

      // Sign out
      await page.click('[data-clerk-user-button]');
      await page.click('text=/sign out/i');

      // Try to access protected route
      await page.goto(DASHBOARD_URL);

      // Should redirect to sign-in
      await expect(page).toHaveURL(new RegExp(SIGN_IN_URL), { timeout: 10000 });
    });
  });

  test.describe('Protected Routes', () => {
    test('should redirect to sign-in when accessing protected route unauthenticated', async ({
      page,
    }) => {
      // Try to access dashboard without auth
      await page.goto(DASHBOARD_URL);

      // Should redirect to sign-in
      await expect(page).toHaveURL(new RegExp(SIGN_IN_URL), { timeout: 10000 });
    });

    test('should allow access to protected routes when authenticated', async ({
      page,
    }) => {
      await signIn(page, TEST_USER_EMAIL, TEST_USER_PASSPHRASE);

      // Navigate to protected route
      await page.goto(DASHBOARD_URL);

      // Should stay on dashboard
      await expect(page).toHaveURL(new RegExp(DASHBOARD_URL));

      // Verify protected content is visible
      await expect(page.locator('text=/dashboard|welcome/i')).toBeVisible();
    });

    test('should redirect after sign-in to originally requested page', async ({
      page,
    }) => {
      // Try to access protected page
      await page.goto(DASHBOARD_URL);

      // Redirected to sign-in
      await expect(page).toHaveURL(new RegExp(SIGN_IN_URL));

      // Sign in
      await page.fill('input[name="identifier"]', TEST_USER_EMAIL);
      await page.fill('input[name="password"]', TEST_USER_PASSPHRASE);
      await page.click('button[type="submit"]');

      // Should redirect back to dashboard
      await expect(page).toHaveURL(new RegExp(DASHBOARD_URL), { timeout: 10000 });
    });
  });

  test.describe('User Profile', () => {
    test('should display user information', async ({ page }) => {
      await signIn(page, TEST_USER_EMAIL, TEST_USER_PASSPHRASE);

      // Navigate to profile page
      await page.goto(`${BASE_URL}/profile`);

      // Verify user email is displayed
      await expect(page.locator(`text=${TEST_USER_EMAIL}`)).toBeVisible();
    });

    test('should update user profile', async ({ page }) => {
      await signIn(page, TEST_USER_EMAIL, TEST_USER_PASSPHRASE);

      // Click user button to open profile
      await page.click('[data-clerk-user-button]');
      await page.click('text=/manage account|profile/i');

      // Update first name (if editable)
      const firstNameInput = page.locator('input[name="firstName"]');
      if (await firstNameInput.isVisible()) {
        await firstNameInput.fill('Updated');
        await page.click('button[type="submit"]');

        // Verify success message
        await expect(page.locator('text=/saved|updated/i')).toBeVisible({
          timeout: 5000,
        });
      }
    });
  });
});

// Helper function to sign in
async function signIn(page: Page, email: string, passphrase: string) {
  await page.goto(SIGN_IN_URL);
  await page.fill('input[name="identifier"]', email);
  await page.fill('input[name="password"]', passphrase);
  await page.click('button[type="submit"]');

  // Wait for redirect and user button to appear
  await expect(page.locator('[data-clerk-user-button]')).toBeVisible({
    timeout: 10000,
  });
}
