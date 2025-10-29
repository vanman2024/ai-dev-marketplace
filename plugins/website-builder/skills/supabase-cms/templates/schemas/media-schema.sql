-- Media assets table for image/file management
CREATE TABLE IF NOT EXISTS media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  filename TEXT NOT NULL,
  url TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,

  -- Metadata
  alt_text TEXT,
  caption TEXT,
  width INTEGER,
  height INTEGER,

  -- Organization
  folder TEXT DEFAULT 'uploads',
  tags TEXT[],

  -- Ownership
  uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_media_folder ON media(folder);
CREATE INDEX idx_media_uploaded_by ON media(uploaded_by);
CREATE INDEX idx_media_tags ON media USING GIN(tags);
