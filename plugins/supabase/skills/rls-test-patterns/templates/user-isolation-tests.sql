-- SQL-based RLS tests using pgTAP
-- Place in supabase/tests/database/rls-user-isolation.test.sql

BEGIN;

SELECT plan(12); -- Adjust based on number of tests

-- Setup test data
INSERT INTO auth.users (id, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'test-user-1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'test-user-2@example.com')
ON CONFLICT DO NOTHING;

-- Test 1: User can create their own records
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims.sub = '11111111-1111-1111-1111-111111111111';

INSERT INTO public.conversations (id, user_id, title) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Test Conversation');

SELECT results_eq(
  'SELECT user_id FROM public.conversations WHERE id = ''aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa''',
  $$VALUES ('11111111-1111-1111-1111-111111111111'::uuid)$$,
  'User 1 can create their own conversation'
);

-- Test 2: User cannot read other user's records
SET LOCAL request.jwt.claims.sub = '22222222-2222-2222-2222-222222222222';

SELECT results_eq(
  'SELECT COUNT(*)::int FROM public.conversations WHERE user_id = ''11111111-1111-1111-1111-111111111111''',
  $$VALUES (0)$$,
  'User 2 cannot read User 1''s conversations'
);

-- Test 3: User cannot update other user's records
UPDATE public.conversations
SET title = 'Hacked Title'
WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

SELECT results_eq(
  'SELECT title FROM public.conversations WHERE id = ''aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa''',
  $$VALUES ('Test Conversation'::text)$$,
  'User 2 cannot update User 1''s conversation'
);

-- Test 4: User cannot delete other user's records
DELETE FROM public.conversations
WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

SELECT results_eq(
  'SELECT COUNT(*)::int FROM public.conversations WHERE id = ''aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa''',
  $$VALUES (1)$$,
  'User 2 cannot delete User 1''s conversation'
);

-- Test 5: User cannot insert records with another user_id
INSERT INTO public.conversations (user_id, title) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Spoofed Conversation');

SELECT results_eq(
  'SELECT COUNT(*)::int FROM public.conversations WHERE user_id = ''11111111-1111-1111-1111-111111111111'' AND title = ''Spoofed Conversation''',
  $$VALUES (0)$$,
  'User 2 cannot create conversations for User 1'
);

-- Test 6: Anonymous users cannot read protected data
RESET ROLE;
SET LOCAL ROLE anon;

SELECT results_eq(
  'SELECT COUNT(*)::int FROM public.conversations',
  $$VALUES (0)$$,
  'Anonymous users cannot read conversations'
);

-- Test 7: Anonymous users cannot insert data
INSERT INTO public.conversations (title) VALUES ('Anonymous Conversation');

SELECT results_eq(
  'SELECT COUNT(*)::int FROM public.conversations WHERE title = ''Anonymous Conversation''',
  $$VALUES (0)$$,
  'Anonymous users cannot insert conversations'
);

-- Test 8: Check RLS is enabled
SELECT has_table_privilege('anon', 'public.conversations', 'SELECT') = false AS result
WHERE (
  SELECT relrowsecurity
  FROM pg_class
  WHERE oid = 'public.conversations'::regclass
) = true;

SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.conversations'::regclass),
  'RLS is enabled on conversations table'
);

-- Test 9: Verify SELECT policy exists
SELECT policies_are(
  'public',
  'conversations',
  ARRAY['Users can read own conversations']
);

-- Test 10: Verify INSERT policy exists
SELECT results_eq(
  $$SELECT COUNT(*)::int FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'conversations'
    AND cmd = 'INSERT'$$,
  $$VALUES (1)$$,
  'INSERT policy exists on conversations'
);

-- Test 11: Verify UPDATE policy exists
SELECT results_eq(
  $$SELECT COUNT(*)::int FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'conversations'
    AND cmd = 'UPDATE'$$,
  $$VALUES (1)$$,
  'UPDATE policy exists on conversations'
);

-- Test 12: Verify DELETE policy exists
SELECT results_eq(
  $$SELECT COUNT(*)::int FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'conversations'
    AND cmd = 'DELETE'$$,
  $$VALUES (1)$$,
  'DELETE policy exists on conversations'
);

-- Cleanup
RESET ROLE;
DELETE FROM public.conversations WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
DELETE FROM auth.users WHERE id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222'
);

SELECT * FROM finish();

ROLLBACK;
