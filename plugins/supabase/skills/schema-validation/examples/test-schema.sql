-- Test schema for validation demonstration
-- This file contains both good and bad patterns to test validators

-- GOOD: Proper table with all best practices
CREATE TABLE users (
  id UUID CONSTRAINT pk_users PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT CONSTRAINT uq_users_email UNIQUE NOT NULL,
  username TEXT CONSTRAINT uq_users_username UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS on public table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- RLS Policy with proper role specification
CREATE POLICY users_select_own ON users
  FOR SELECT
  TO authenticated
  USING (id = (SELECT auth.uid()));

-- Proper indexes
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_username ON users (username);

-- GOOD: Table with proper foreign key and constraints
CREATE TABLE blog_posts (
  id UUID CONSTRAINT pk_blog_posts PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  title TEXT NOT NULL,
  slug TEXT CONSTRAINT uq_blog_posts_slug UNIQUE NOT NULL,
  content TEXT NOT NULL,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT fk_blog_posts_users
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,

  CONSTRAINT ck_blog_posts_title_length
    CHECK (length(title) > 0 AND length(title) <= 200),

  CONSTRAINT ck_blog_posts_slug_format
    CHECK (slug ~ '^[a-z0-9-]+$')
);

ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY blog_posts_select_published ON blog_posts
  FOR SELECT
  TO authenticated
  USING (published_at IS NOT NULL OR user_id = (SELECT auth.uid()));

CREATE POLICY blog_posts_insert_own ON blog_posts
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY blog_posts_update_own ON blog_posts
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY blog_posts_delete_own ON blog_posts
  FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- Proper indexes for foreign key and RLS
CREATE INDEX idx_blog_posts_user_id ON blog_posts (user_id);
CREATE INDEX idx_blog_posts_published_at ON blog_posts (published_at)
  WHERE published_at IS NOT NULL;

-- GOOD: Table with JSONB and proper GIN index
CREATE TABLE user_preferences (
  id UUID CONSTRAINT pk_user_preferences PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT fk_user_preferences_users
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,

  CONSTRAINT uq_user_preferences_user_id
    UNIQUE (user_id)
);

ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_preferences_all_own ON user_preferences
  FOR ALL
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE INDEX idx_user_preferences_user_id ON user_preferences (user_id);
CREATE INDEX idx_user_preferences_preferences ON user_preferences USING GIN (preferences);

-- GOOD: Soft delete pattern with partial index
CREATE TABLE comments (
  id UUID CONSTRAINT pk_comments PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL,
  user_id UUID NOT NULL,
  content TEXT NOT NULL,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT fk_comments_posts
    FOREIGN KEY (post_id)
    REFERENCES blog_posts(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_comments_users
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,

  CONSTRAINT ck_comments_content_length
    CHECK (length(content) > 0 AND length(content) <= 1000)
);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY comments_select_not_deleted ON comments
  FOR SELECT
  TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY comments_insert_own ON comments
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY comments_update_own ON comments
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()) AND deleted_at IS NULL)
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY comments_delete_own ON comments
  FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- Indexes with partial index for soft deletes
CREATE INDEX idx_comments_post_id ON comments (post_id);
CREATE INDEX idx_comments_user_id ON comments (user_id);
CREATE INDEX idx_comments_active ON comments (post_id, created_at)
  WHERE deleted_at IS NULL;
