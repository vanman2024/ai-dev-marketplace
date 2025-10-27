/**
 * Authentication E2E Tests
 * Comprehensive tests for Supabase authentication flows
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from 'dotenv';

config({ path: '.env.test' });

const supabaseUrl = process.env.SUPABASE_TEST_URL!;
const supabaseKey = process.env.SUPABASE_TEST_ANON_KEY!;
const serviceRoleKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY!;

describe('Authentication E2E Tests', () => {
  let supabase: SupabaseClient;
  let supabaseAdmin: SupabaseClient;
  const testUsers: string[] = [];

  beforeAll(() => {
    supabase = createClient(supabaseUrl, supabaseKey);
    supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
  });

  afterAll(async () => {
    // Cleanup all test users
    for (const userId of testUsers) {
      try {
        await supabaseAdmin.auth.admin.deleteUser(userId);
      } catch (error) {
        console.warn(`Failed to delete user ${userId}:`, error);
      }
    }
  });

  describe('User Signup', () => {
    test('should sign up new user with email and password', async () => {
      const email = `test-${Date.now()}@example.com`;
      const password = 'TestPassword123!';

      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      });

      expect(error).toBeNull();
      expect(data.user).toBeDefined();
      expect(data.user?.email).toBe(email);

      if (data.user) testUsers.push(data.user.id);
    });

    test('should reject signup with weak password', async () => {
      const email = `test-${Date.now()}@example.com`;
      const password = '123'; // Too weak

      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      });

      expect(error).toBeDefined();
      expect(error?.message).toContain('Password');
    });

    test('should reject signup with invalid email', async () => {
      const email = 'invalid-email';
      const password = 'TestPassword123!';

      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      });

      expect(error).toBeDefined();
    });
  });

  describe('User Login', () => {
    const testEmail = `test-login-${Date.now()}@example.com`;
    const testPassword = 'TestPassword123!';

    beforeAll(async () => {
      // Create user for login tests
      const { data } = await supabase.auth.signUp({
        email: testEmail,
        password: testPassword,
      });

      if (data.user) testUsers.push(data.user.id);
    });

    test('should login with correct credentials', async () => {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: testEmail,
        password: testPassword,
      });

      expect(error).toBeNull();
      expect(data.session).toBeDefined();
      expect(data.user?.email).toBe(testEmail);

      // Cleanup session
      await supabase.auth.signOut();
    });

    test('should reject login with wrong password', async () => {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: testEmail,
        password: 'WrongPassword123!',
      });

      expect(error).toBeDefined();
      expect(error?.message).toContain('Invalid');
    });

    test('should reject login with non-existent email', async () => {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: 'nonexistent@example.com',
        password: testPassword,
      });

      expect(error).toBeDefined();
    });
  });

  describe('Session Management', () => {
    const testEmail = `test-session-${Date.now()}@example.com`;
    const testPassword = 'TestPassword123!';
    let accessToken: string;
    let refreshToken: string;

    beforeAll(async () => {
      // Create and login user
      const { data: signupData } = await supabase.auth.signUp({
        email: testEmail,
        password: testPassword,
      });

      if (signupData.user) testUsers.push(signupData.user.id);

      const { data: loginData } = await supabase.auth.signInWithPassword({
        email: testEmail,
        password: testPassword,
      });

      accessToken = loginData.session!.access_token;
      refreshToken = loginData.session!.refresh_token;
    });

    test('should get current user with valid session', async () => {
      const { data, error } = await supabase.auth.getUser();

      expect(error).toBeNull();
      expect(data.user).toBeDefined();
      expect(data.user?.email).toBe(testEmail);
    });

    test('should refresh session with refresh token', async () => {
      const { data, error } = await supabase.auth.refreshSession({
        refresh_token: refreshToken,
      });

      expect(error).toBeNull();
      expect(data.session).toBeDefined();
      expect(data.session?.access_token).toBeTruthy();
      expect(data.session?.access_token).not.toBe(accessToken);
    });

    test('should sign out and clear session', async () => {
      await supabase.auth.signOut();

      const { data, error } = await supabase.auth.getUser();

      expect(data.user).toBeNull();
    });
  });

  describe('Password Reset', () => {
    const testEmail = `test-reset-${Date.now()}@example.com`;
    const testPassword = 'TestPassword123!';

    beforeAll(async () => {
      const { data } = await supabase.auth.signUp({
        email: testEmail,
        password: testPassword,
      });

      if (data.user) testUsers.push(data.user.id);
    });

    test('should send password reset email', async () => {
      const { data, error } = await supabase.auth.resetPasswordForEmail(
        testEmail
      );

      expect(error).toBeNull();
      // Note: Actual email sending may not occur in test environment
    });
  });

  describe('Row Level Security (RLS)', () => {
    let userId: string;
    const testEmail = `test-rls-${Date.now()}@example.com`;
    const testPassword = 'TestPassword123!';

    beforeAll(async () => {
      // Create user
      const { data } = await supabase.auth.signUp({
        email: testEmail,
        password: testPassword,
      });

      userId = data.user!.id;
      testUsers.push(userId);

      // Login as user
      await supabase.auth.signInWithPassword({
        email: testEmail,
        password: testPassword,
      });
    });

    afterAll(async () => {
      await supabase.auth.signOut();
    });

    test('should only see own data with RLS', async () => {
      // This test assumes you have a table with RLS policies
      // Replace 'user_data' with your actual table name

      const { data, error } = await supabase
        .from('user_data')
        .select('*');

      expect(error).toBeNull();

      // All returned rows should belong to the authenticated user
      if (data && data.length > 0) {
        expect(data.every(row => row.user_id === userId)).toBe(true);
      }
    });

    test('should not access other users data', async () => {
      // Try to query data with a different user_id filter
      const { data, error } = await supabase
        .from('user_data')
        .select('*')
        .neq('user_id', userId);

      expect(error).toBeNull();
      expect(data).toHaveLength(0); // Should return no rows
    });
  });

  describe('Admin Operations', () => {
    test('should create user as admin', async () => {
      const email = `test-admin-${Date.now()}@example.com`;
      const password = 'TestPassword123!';

      const { data, error } = await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });

      expect(error).toBeNull();
      expect(data.user).toBeDefined();

      if (data.user) testUsers.push(data.user.id);
    });

    test('should list users as admin', async () => {
      const { data, error } = await supabaseAdmin.auth.admin.listUsers();

      expect(error).toBeNull();
      expect(data.users).toBeDefined();
      expect(Array.isArray(data.users)).toBe(true);
    });

    test('should update user metadata as admin', async () => {
      // Create a test user first
      const email = `test-meta-${Date.now()}@example.com`;
      const { data: createData } = await supabaseAdmin.auth.admin.createUser({
        email,
        password: 'TestPassword123!',
      });

      const userId = createData.user!.id;
      testUsers.push(userId);

      // Update metadata
      const { data, error } = await supabaseAdmin.auth.admin.updateUserById(
        userId,
        {
          user_metadata: { role: 'admin', test: true },
        }
      );

      expect(error).toBeNull();
      expect(data.user.user_metadata).toMatchObject({
        role: 'admin',
        test: true,
      });
    });
  });
});
