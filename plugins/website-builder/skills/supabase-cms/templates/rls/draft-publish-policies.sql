-- Row Level Security policies for draft/publish workflow
-- Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Public can read published posts
CREATE POLICY "Public can view published posts"
ON posts FOR SELECT
TO public
USING (status = 'published');

-- Authors can view their own drafts
CREATE POLICY "Authors can view own drafts"
ON posts FOR SELECT
TO authenticated
USING (auth.uid() = author_id);

-- Authors can create posts
CREATE POLICY "Authors can create posts"
ON posts FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = author_id);

-- Authors can update their own posts
CREATE POLICY "Authors can update own posts"
ON posts FOR UPDATE
TO authenticated
USING (auth.uid() = author_id)
WITH CHECK (auth.uid() = author_id);

-- Authors can delete their own posts
CREATE POLICY "Authors can delete own posts"
ON posts FOR DELETE
TO authenticated
USING (auth.uid() = author_id);
