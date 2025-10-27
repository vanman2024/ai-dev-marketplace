/**
 * Test Suite Template for Supabase E2E Testing
 * This template provides a complete Jest/Vitest test structure
 * with proper setup, teardown, and helper utilities
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from 'dotenv';

// Load test environment
config({ path: '.env.test' });

// Test configuration
const testConfig = {
  supabaseUrl: process.env.SUPABASE_TEST_URL!,
  supabaseAnonKey: process.env.SUPABASE_TEST_ANON_KEY!,
  supabaseServiceRoleKey: process.env.SUPABASE_TEST_SERVICE_ROLE_KEY!,
};

// Validate required environment variables
if (!testConfig.supabaseUrl || !testConfig.supabaseAnonKey) {
  throw new Error('Missing required environment variables. Check .env.test');
}

describe('Supabase E2E Test Suite', () => {
  let supabase: SupabaseClient;
  let supabaseAdmin: SupabaseClient;

  // Setup: Create clients before all tests
  beforeAll(() => {
    supabase = createClient(
      testConfig.supabaseUrl,
      testConfig.supabaseAnonKey
    );

    if (testConfig.supabaseServiceRoleKey) {
      supabaseAdmin = createClient(
        testConfig.supabaseUrl,
        testConfig.supabaseServiceRoleKey
      );
    }
  });

  // Teardown: Cleanup after all tests
  afterAll(async () => {
    // Sign out any authenticated sessions
    await supabase.auth.signOut();

    // Close connections (if needed)
    // await supabase.removeAllChannels();
  });

  describe('Test Group 1: Feature Tests', () => {
    // Setup before each test in this group
    beforeEach(async () => {
      // Setup test data
    });

    // Cleanup after each test in this group
    afterEach(async () => {
      // Cleanup test data
    });

    test('should pass example test', async () => {
      // Arrange
      const testData = { foo: 'bar' };

      // Act
      const result = testData.foo;

      // Assert
      expect(result).toBe('bar');
    });

    test('should test async operation', async () => {
      // Arrange
      const email = 'test@example.com';

      // Act
      const { data, error } = await supabase
        .from('users')
        .select('email')
        .eq('email', email)
        .maybeSingle();

      // Assert
      expect(error).toBeNull();
      // Add more assertions based on expected behavior
    });
  });

  describe('Test Group 2: Error Handling', () => {
    test('should handle invalid input gracefully', async () => {
      // Arrange
      const invalidData = null;

      // Act & Assert
      await expect(async () => {
        await supabase
          .from('users')
          .insert({ email: invalidData });
      }).rejects.toThrow();
    });
  });
});

// Helper Functions
export const testHelpers = {
  /**
   * Wait for a condition to be true
   */
  waitFor: async (
    condition: () => boolean | Promise<boolean>,
    timeout: number = 5000,
    interval: number = 100
  ): Promise<void> => {
    const startTime = Date.now();

    while (Date.now() - startTime < timeout) {
      if (await condition()) {
        return;
      }
      await new Promise(resolve => setTimeout(resolve, interval));
    }

    throw new Error(`Timeout waiting for condition after ${timeout}ms`);
  },

  /**
   * Generate random test email
   */
  randomEmail: (): string => {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(7);
    return `test-${timestamp}-${random}@example.com`;
  },

  /**
   * Generate random test data
   */
  randomString: (length: number = 10): string => {
    return Math.random()
      .toString(36)
      .substring(2, length + 2);
  },

  /**
   * Sleep for specified milliseconds
   */
  sleep: (ms: number): Promise<void> => {
    return new Promise(resolve => setTimeout(resolve, ms));
  },

  /**
   * Create test user
   */
  createTestUser: async (
    client: SupabaseClient,
    email?: string,
    password: string = 'TestPassword123!'
  ) => {
    const userEmail = email || testHelpers.randomEmail();

    const { data, error } = await client.auth.signUp({
      email: userEmail,
      password: password,
    });

    if (error) throw error;

    return {
      user: data.user!,
      session: data.session!,
      email: userEmail,
      password,
    };
  },

  /**
   * Delete test user (requires admin client)
   */
  deleteTestUser: async (
    adminClient: SupabaseClient,
    userId: string
  ): Promise<void> => {
    const { error } = await adminClient.auth.admin.deleteUser(userId);
    if (error) throw error;
  },

  /**
   * Generate random vector for testing
   */
  randomVector: (dimensions: number): number[] => {
    return Array.from({ length: dimensions }, () => Math.random());
  },

  /**
   * Normalize vector (for embeddings)
   */
  normalizeVector: (vector: number[]): number[] => {
    const magnitude = Math.sqrt(
      vector.reduce((sum, val) => sum + val * val, 0)
    );
    return vector.map(val => val / magnitude);
  },
};

// Export for use in other test files
export { supabase, supabaseAdmin, testConfig };
