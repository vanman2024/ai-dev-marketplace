/**
 * RLS Test Suite Template
 * TypeScript-based RLS testing using Supabase Client
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js'
import { describe, it, expect, beforeAll, afterAll } from '@jest/globals'

// Environment configuration
const SUPABASE_URL = process.env.SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY!
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY!

// Test user credentials
const TEST_USER_1 = {
  email: 'test-user-1@example.com',
  password: 'test-password-123'
}

const TEST_USER_2 = {
  email: 'test-user-2@example.com',
  password: 'test-password-456'
}

interface TestContext {
  anonClient: SupabaseClient
  serviceClient: SupabaseClient
  user1Client: SupabaseClient
  user2Client: SupabaseClient
  user1Id: string
  user2Id: string
}

describe('RLS Policy Tests', () => {
  let ctx: TestContext

  beforeAll(async () => {
    // Initialize clients
    const anonClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
    const serviceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    // Create test users
    const { data: user1, error: user1Error } = await serviceClient.auth.admin.createUser({
      email: TEST_USER_1.email,
      password: TEST_USER_1.password,
      email_confirm: true
    })

    const { data: user2, error: user2Error } = await serviceClient.auth.admin.createUser({
      email: TEST_USER_2.email,
      password: TEST_USER_2.password,
      email_confirm: true
    })

    if (user1Error || user2Error) {
      throw new Error('Failed to create test users')
    }

    // Sign in as each user
    const { data: session1 } = await anonClient.auth.signInWithPassword({
      email: TEST_USER_1.email,
      password: TEST_USER_1.password
    })

    const { data: session2 } = await anonClient.auth.signInWithPassword({
      email: TEST_USER_2.email,
      password: TEST_USER_2.password
    })

    if (!session1?.session || !session2?.session) {
      throw new Error('Failed to sign in test users')
    }

    // Create authenticated clients
    const user1Client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: {
        headers: {
          Authorization: `Bearer ${session1.session.access_token}`
        }
      }
    })

    const user2Client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: {
        headers: {
          Authorization: `Bearer ${session2.session.access_token}`
        }
      }
    })

    ctx = {
      anonClient,
      serviceClient,
      user1Client,
      user2Client,
      user1Id: user1.user!.id,
      user2Id: user2.user!.id
    }
  })

  afterAll(async () => {
    // Cleanup test users
    await ctx.serviceClient.auth.admin.deleteUser(ctx.user1Id)
    await ctx.serviceClient.auth.admin.deleteUser(ctx.user2Id)
  })

  describe('User Isolation Tests', () => {
    const TABLE_NAME = 'conversations' // Change to your table name

    it('should allow users to create their own records', async () => {
      const { data, error } = await ctx.user1Client
        .from(TABLE_NAME)
        .insert({ user_id: ctx.user1Id, title: 'Test Conversation' })
        .select()
        .single()

      expect(error).toBeNull()
      expect(data).toBeDefined()
      expect(data.user_id).toBe(ctx.user1Id)

      // Cleanup
      await ctx.serviceClient.from(TABLE_NAME).delete().eq('id', data.id)
    })

    it('should prevent users from reading other users data', async () => {
      // Create record as user 1
      const { data: created } = await ctx.user1Client
        .from(TABLE_NAME)
        .insert({ user_id: ctx.user1Id, title: 'Private Conversation' })
        .select()
        .single()

      // Try to read as user 2
      const { data: readData, error } = await ctx.user2Client
        .from(TABLE_NAME)
        .select()
        .eq('id', created!.id)

      expect(readData).toHaveLength(0)

      // Cleanup
      await ctx.serviceClient.from(TABLE_NAME).delete().eq('id', created!.id)
    })

    it('should prevent users from updating other users data', async () => {
      // Create record as user 1
      const { data: created } = await ctx.user1Client
        .from(TABLE_NAME)
        .insert({ user_id: ctx.user1Id, title: 'Original Title' })
        .select()
        .single()

      // Try to update as user 2
      const { error } = await ctx.user2Client
        .from(TABLE_NAME)
        .update({ title: 'Hacked Title' })
        .eq('id', created!.id)

      expect(error).toBeDefined()

      // Verify not updated
      const { data: verified } = await ctx.serviceClient
        .from(TABLE_NAME)
        .select()
        .eq('id', created!.id)
        .single()

      expect(verified!.title).toBe('Original Title')

      // Cleanup
      await ctx.serviceClient.from(TABLE_NAME).delete().eq('id', created!.id)
    })

    it('should prevent users from deleting other users data', async () => {
      // Create record as user 1
      const { data: created } = await ctx.user1Client
        .from(TABLE_NAME)
        .insert({ user_id: ctx.user1Id, title: 'Permanent Record' })
        .select()
        .single()

      // Try to delete as user 2
      const { error } = await ctx.user2Client
        .from(TABLE_NAME)
        .delete()
        .eq('id', created!.id)

      expect(error).toBeDefined()

      // Verify still exists
      const { data: verified } = await ctx.serviceClient
        .from(TABLE_NAME)
        .select()
        .eq('id', created!.id)

      expect(verified).toHaveLength(1)

      // Cleanup
      await ctx.serviceClient.from(TABLE_NAME).delete().eq('id', created!.id)
    })

    it('should prevent users from inserting data with another user_id', async () => {
      const { data, error } = await ctx.user2Client
        .from(TABLE_NAME)
        .insert({ user_id: ctx.user1Id, title: 'Spoofed Record' })
        .select()

      expect(error).toBeDefined()
      expect(data).toBeNull()
    })
  })

  describe('Anonymous Access Tests', () => {
    const TABLE_NAME = 'conversations'

    it('should block anonymous reads on protected tables', async () => {
      const { data, error } = await ctx.anonClient
        .from(TABLE_NAME)
        .select()

      // Should either error or return no data
      expect(data === null || data.length === 0).toBe(true)
    })

    it('should block anonymous inserts on protected tables', async () => {
      const { error } = await ctx.anonClient
        .from(TABLE_NAME)
        .insert({ title: 'Anonymous Record' })

      expect(error).toBeDefined()
    })
  })

  describe('Multi-Tenant Isolation Tests', () => {
    const TABLE_NAME = 'projects' // Change to your multi-tenant table

    it('should isolate data between organizations', async () => {
      // This test requires organization setup
      // Implement based on your multi-tenant schema

      // Example:
      // 1. Create org1 and add user1
      // 2. Create org2 and add user2
      // 3. Create project in org1 as user1
      // 4. Verify user2 cannot read org1's project
    })
  })

  describe('Role-Based Access Tests', () => {
    const TABLE_NAME = 'admin_settings'

    it('should allow admin role full access', async () => {
      // Requires setting up user with admin role in app_metadata
      // Test CREATE, READ, UPDATE, DELETE operations
    })

    it('should allow editor role read/write but not delete', async () => {
      // Requires setting up user with editor role
      // Test READ and UPDATE succeed, DELETE fails
    })

    it('should allow viewer role read-only access', async () => {
      // Requires setting up user with viewer role
      // Test READ succeeds, CREATE/UPDATE/DELETE fail
    })
  })
})

/**
 * Helper functions
 */

export async function createTestUser(
  serviceClient: SupabaseClient,
  email: string,
  password: string,
  metadata?: Record<string, any>
) {
  return await serviceClient.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: metadata
  })
}

export async function signInUser(
  client: SupabaseClient,
  email: string,
  password: string
) {
  return await client.auth.signInWithPassword({ email, password })
}

export async function cleanupTestData(
  serviceClient: SupabaseClient,
  tableName: string,
  userIds: string[]
) {
  await serviceClient.from(tableName).delete().in('user_id', userIds)
}
