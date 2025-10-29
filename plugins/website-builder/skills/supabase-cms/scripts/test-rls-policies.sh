#!/bin/bash
# Test Row Level Security policies with different user roles

set -e

echo "🧪 Testing RLS policies..."

# Check for required dependencies
if ! command -v node &> /dev/null; then
  echo "❌ Error: Node.js not found"
  exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
  echo "❌ Error: .env file not found. Run setup-supabase-cms.sh first"
  exit 1
fi

# Create test script
cat > /tmp/test-rls.js << 'TESTSCRIPT'
import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Missing Supabase credentials in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testRLS() {
  console.log('🔍 Testing RLS policies...\n');

  // Test 1: Unauthenticated user can read published posts
  console.log('Test 1: Unauthenticated user reads published posts');
  try {
    const { data, error } = await supabase
      .from('posts')
      .select('*')
      .eq('status', 'published');

    if (error) {
      console.log('❌ Failed:', error.message);
    } else {
      console.log('✅ Passed: Retrieved', data.length, 'published posts');
    }
  } catch (err) {
    console.log('❌ Error:', err.message);
  }

  // Test 2: Unauthenticated user cannot read drafts
  console.log('\nTest 2: Unauthenticated user reads draft posts');
  try {
    const { data, error } = await supabase
      .from('posts')
      .select('*')
      .eq('status', 'draft');

    if (error) {
      console.log('✅ Passed: Access denied as expected');
    } else if (data.length === 0) {
      console.log('✅ Passed: No drafts returned (correct behavior)');
    } else {
      console.log('❌ Failed: Should not be able to read drafts');
    }
  } catch (err) {
    console.log('✅ Passed: Access denied as expected');
  }

  // Test 3: Unauthenticated user cannot insert
  console.log('\nTest 3: Unauthenticated user inserts post');
  try {
    const { data, error } = await supabase
      .from('posts')
      .insert({
        title: 'Test Post',
        slug: 'test-post',
        content: 'Test content',
        status: 'draft'
      });

    if (error) {
      console.log('✅ Passed: Insert denied as expected');
    } else {
      console.log('❌ Failed: Should not be able to insert without auth');
    }
  } catch (err) {
    console.log('✅ Passed: Insert denied as expected');
  }

  // Test 4: Unauthenticated user cannot update
  console.log('\nTest 4: Unauthenticated user updates post');
  try {
    const { data, error } = await supabase
      .from('posts')
      .update({ title: 'Updated Title' })
      .eq('status', 'published')
      .select();

    if (error) {
      console.log('✅ Passed: Update denied as expected');
    } else if (!data || data.length === 0) {
      console.log('✅ Passed: No rows updated (correct behavior)');
    } else {
      console.log('❌ Failed: Should not be able to update without auth');
    }
  } catch (err) {
    console.log('✅ Passed: Update denied as expected');
  }

  // Test 5: Unauthenticated user cannot delete
  console.log('\nTest 5: Unauthenticated user deletes post');
  try {
    const { data, error } = await supabase
      .from('posts')
      .delete()
      .eq('status', 'published')
      .select();

    if (error) {
      console.log('✅ Passed: Delete denied as expected');
    } else if (!data || data.length === 0) {
      console.log('✅ Passed: No rows deleted (correct behavior)');
    } else {
      console.log('❌ Failed: Should not be able to delete without auth');
    }
  } catch (err) {
    console.log('✅ Passed: Delete denied as expected');
  }

  console.log('\n📊 RLS policy tests complete!');
  console.log('\n⚠️  Note: These are basic tests. For authenticated user tests,');
  console.log('you need to provide test credentials or use Supabase Test Helpers.');
}

testRLS().catch(console.error);
TESTSCRIPT

# Run test
echo "Running tests with Node.js..."
node --input-type=module /tmp/test-rls.js

# Cleanup
trash-put /tmp/test-rls.js

echo ""
echo "✅ RLS policy testing complete!"
echo ""
echo "For comprehensive testing, consider:"
echo "1. Testing with authenticated users"
echo "2. Testing role-based permissions"
echo "3. Testing multi-tenant isolation"
echo "4. Using Supabase Test Helpers: https://supabase.com/docs/guides/testing"
