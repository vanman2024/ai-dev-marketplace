-- Basic RLS policies for public read, authenticated write

-- Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Public can read all content
CREATE POLICY "Public read access"
ON posts FOR SELECT
TO public
USING (true);

-- Authenticated users can insert
CREATE POLICY "Authenticated can insert"
ON posts FOR INSERT
TO authenticated
WITH CHECK (true);

-- Authenticated users can update
CREATE POLICY "Authenticated can update"
ON posts FOR UPDATE
TO authenticated
USING (true);

-- Authenticated users can delete
CREATE POLICY "Authenticated can delete"
ON posts FOR DELETE
TO authenticated
USING (true);
