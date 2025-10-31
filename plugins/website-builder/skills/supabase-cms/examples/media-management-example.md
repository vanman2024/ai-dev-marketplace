# Media Management Example

This example demonstrates how to implement a complete media management system with Supabase Storage, including upload, optimization, CDN delivery, and metadata tracking.

## Prerequisites

- Supabase project with Storage enabled
- Media bucket created in Supabase Storage
- RLS policies configured for Storage

## Database Schema

```sql
-- Media metadata table
CREATE TABLE IF NOT EXISTS media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY
  filename TEXT NOT NULL
  storage_path TEXT NOT NULL UNIQUE
  url TEXT NOT NULL
  mime_type TEXT NOT NULL
  size_bytes INTEGER NOT NULL
  alt_text TEXT
  caption TEXT
  width INTEGER
  height INTEGER
  tags TEXT[]
  uploaded_by UUID REFERENCES auth.users(id)
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_media_organization ON media(organization_id);
CREATE INDEX idx_media_tags ON media USING GIN(tags);
CREATE INDEX idx_media_mime_type ON media(mime_type);
CREATE INDEX idx_media_uploaded_by ON media(uploaded_by);

-- Enable full-text search on filename and caption
ALTER TABLE media ADD COLUMN search_vector tsvector;
CREATE INDEX idx_media_search ON media USING GIN(search_vector);

CREATE OR REPLACE FUNCTION update_media_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', COALESCE(NEW.filename, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.caption, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.alt_text, '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER media_search_vector_update
BEFORE INSERT OR UPDATE ON media
FOR EACH ROW
EXECUTE FUNCTION update_media_search_vector();
```

## Storage RLS Policies

```sql
-- Storage bucket: 'media'
-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Public read access for published content
CREATE POLICY "Public can view media"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'media');

-- Authenticated users can upload
CREATE POLICY "Authenticated users can upload media"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'media');

-- Users can update their own uploads
CREATE POLICY "Users can update own media"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'media' AND
  auth.uid() = owner
);

-- Users can delete their own uploads
CREATE POLICY "Users can delete own media"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'media' AND
  auth.uid() = owner
);
```

## TypeScript Implementation

### 1. Media Upload Service

```typescript
// src/lib/supabase/media-upload.ts
import { supabase } from './client';

interface UploadOptions {
  file: File;
  alt_text?: string;
  caption?: string;
  tags?: string[];
  organizationId?: string;
  onProgress?: (progress: number) => void;
}

export async function uploadMedia({
  file
  alt_text
  caption
  tags = []
  organizationId
  onProgress
}: UploadOptions) {
  // Generate unique filename
  const fileExt = file.name.split('.').pop();
  const fileName = `${Date.now()}-${crypto.randomUUID()}.${fileExt}`;
  const filePath = `uploads/${fileName}`;

  // Get image dimensions if it's an image
  let width: number | undefined;
  let height: number | undefined;

  if (file.type.startsWith('image/')) {
    const dimensions = await getImageDimensions(file);
    width = dimensions.width;
    height = dimensions.height;
  }

  // Upload to Supabase Storage
  const { data: uploadData, error: uploadError } = await supabase.storage
    .from('media')
    .upload(filePath, file, {
      cacheControl: '3600'
      upsert: false
    });

  if (uploadError) throw uploadError;

  // Get public URL
  const { data: urlData } = supabase.storage
    .from('media')
    .getPublicUrl(filePath);

  // Get current user
  const { data: { user } } = await supabase.auth.getUser();

  // Save metadata to database
  const { data: mediaData, error: dbError } = await supabase
    .from('media')
    .insert({
      filename: file.name
      storage_path: filePath
      url: urlData.publicUrl
      mime_type: file.type
      size_bytes: file.size
      alt_text
      caption
      tags
      width
      height
      uploaded_by: user?.id
      organization_id: organizationId
    })
    .select()
    .single();

  if (dbError) {
    // Clean up uploaded file if database insert fails
    await supabase.storage.from('media').remove([filePath]);
    throw dbError;
  }

  return mediaData;
}

async function getImageDimensions(file: File): Promise<{ width: number; height: number }> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);

    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve({ width: img.width, height: img.height });
    };

    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Failed to load image'));
    };

    img.src = url;
  });
}
```

### 2. Media Query Functions

```typescript
// src/lib/supabase/media-queries.ts
import { supabase } from './client';

export async function getMedia(options: {
  organizationId?: string;
  mimeType?: string;
  tags?: string[];
  limit?: number;
  offset?: number;
}) {
  let query = supabase
    .from('media')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false });

  if (options.organizationId) {
    query = query.eq('organization_id', options.organizationId);
  }

  if (options.mimeType) {
    query = query.like('mime_type', `${options.mimeType}%`);
  }

  if (options.tags && options.tags.length > 0) {
    query = query.overlaps('tags', options.tags);
  }

  if (options.limit) {
    query = query.limit(options.limit);
  }

  if (options.offset) {
    query = query.range(options.offset, options.offset + (options.limit || 10) - 1);
  }

  const { data, error, count } = await query;

  if (error) throw error;

  return { media: data, totalCount: count };
}

export async function searchMedia(searchQuery: string, organizationId?: string) {
  let query = supabase
    .from('media')
    .select('*')
    .textSearch('search_vector', searchQuery)
    .order('created_at', { ascending: false });

  if (organizationId) {
    query = query.eq('organization_id', organizationId);
  }

  const { data, error } = await query;

  if (error) throw error;
  return data;
}

export async function getMediaById(id: string) {
  const { data, error } = await supabase
    .from('media')
    .select('*')
    .eq('id', id)
    .single();

  if (error) throw error;
  return data;
}

export async function updateMedia(
  id: string
  updates: {
    alt_text?: string;
    caption?: string;
    tags?: string[];
  }
) {
  const { data, error } = await supabase
    .from('media')
    .update({
      ...updates
      updated_at: new Date().toISOString()
    })
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function deleteMedia(id: string) {
  // First get the storage path
  const { data: media } = await supabase
    .from('media')
    .select('storage_path')
    .eq('id', id)
    .single();

  if (!media) throw new Error('Media not found');

  // Delete from storage
  const { error: storageError } = await supabase.storage
    .from('media')
    .remove([media.storage_path]);

  if (storageError) throw storageError;

  // Delete from database
  const { error: dbError } = await supabase
    .from('media')
    .delete()
    .eq('id', id);

  if (dbError) throw dbError;
}
```

### 3. Image Transformation

```typescript
// src/lib/supabase/image-transform.ts
export function getTransformedImageUrl(
  publicUrl: string
  options: {
    width?: number;
    height?: number;
    quality?: number;
    format?: 'jpeg' | 'webp' | 'avif';
    resize?: 'cover' | 'contain' | 'fill';
  } = {}
): string {
  const url = new URL(publicUrl);

  // Supabase uses Imgproxy for transformations
  const params = new URLSearchParams();

  if (options.width) params.set('width', options.width.toString());
  if (options.height) params.set('height', options.height.toString());
  if (options.quality) params.set('quality', options.quality.toString());
  if (options.format) params.set('format', options.format);
  if (options.resize) params.set('resize', options.resize);

  url.search = params.toString();
  return url.toString();
}

export function getResponsiveImageUrls(publicUrl: string) {
  return {
    small: getTransformedImageUrl(publicUrl, { width: 640, quality: 80 })
    medium: getTransformedImageUrl(publicUrl, { width: 1024, quality: 85 })
    large: getTransformedImageUrl(publicUrl, { width: 1920, quality: 90 })
    webp: getTransformedImageUrl(publicUrl, { width: 1024, format: 'webp' })
    avif: getTransformedImageUrl(publicUrl, { width: 1024, format: 'avif' })
  };
}
```

### 4. Media Upload Component

```typescript
// src/components/MediaUploader.tsx
import { useState } from 'react';
import { uploadMedia } from '@/lib/supabase/media-upload';

export function MediaUploader({ organizationId }: { organizationId?: string }) {
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [uploadedMedia, setUploadedMedia] = useState<any[]>([]);

  async function handleUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    setUploading(true);

    try {
      for (const file of Array.from(files)) {
        const media = await uploadMedia({
          file
          organizationId
          onProgress: setProgress
        });

        setUploadedMedia((prev) => [...prev, media]);
      }
    } catch (error) {
      console.error('Upload failed:', error);
      alert('Upload failed. Please try again.');
    } finally {
      setUploading(false);
      setProgress(0);
    }
  }

  return (
    <div className="space-y-4">
      <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
        <input
          type="file"
          multiple
          accept="image/*,video/*"
          onChange={handleUpload}
          disabled={uploading}
          className="hidden"
          id="media-upload"
        />
        <label
          htmlFor="media-upload"
          className="cursor-pointer text-blue-500 hover:text-blue-600"
        >
          {uploading ? `Uploading... ${progress}%` : 'Click to upload media'}
        </label>
      </div>

      {uploadedMedia.length > 0 && (
        <div className="grid grid-cols-4 gap-4">
          {uploadedMedia.map((media) => (
            <div key={media.id} className="relative">
              <img
                src={media.url}
                alt={media.alt_text || media.filename}
                className="w-full h-32 object-cover rounded"
              />
              <p className="text-xs truncate mt-1">{media.filename}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

### 5. Media Gallery Component

```typescript
// src/components/MediaGallery.tsx
import { useState, useEffect } from 'react';
import { getMedia, deleteMedia } from '@/lib/supabase/media-queries';
import { getTransformedImageUrl } from '@/lib/supabase/image-transform';

export function MediaGallery({ organizationId }: { organizationId?: string }) {
  const [media, setMedia] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);

  useEffect(() => {
    loadMedia();
  }, [organizationId, selectedTags]);

  async function loadMedia() {
    setIsLoading(true);
    const { media: data } = await getMedia({
      organizationId
      tags: selectedTags.length > 0 ? selectedTags : undefined
      limit: 50
    });
    setMedia(data || []);
    setIsLoading(false);
  }

  async function handleDelete(id: string) {
    if (!confirm('Are you sure you want to delete this media?')) return;

    await deleteMedia(id);
    setMedia((prev) => prev.filter((m) => m.id !== id));
  }

  if (isLoading) {
    return <div>Loading media...</div>;
  }

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
        {media.map((item) => (
          <div key={item.id} className="relative group">
            {item.mime_type.startsWith('image/') ? (
              <img
                src={getTransformedImageUrl(item.url, { width: 300, quality: 80 })}
                alt={item.alt_text || item.filename}
                className="w-full h-48 object-cover rounded"
              />
            ) : (
              <div className="w-full h-48 bg-gray-200 rounded flex items-center justify-center">
                <span className="text-gray-500">{item.mime_type}</span>
              </div>
            )}

            <div className="absolute inset-0 bg-black bg-opacity-50 opacity-0 group-hover:opacity-100 transition-opacity rounded flex items-center justify-center gap-2">
              <button
                onClick={() => window.open(item.url, '_blank')}
                className="px-3 py-1 bg-white rounded text-sm"
              >
                View
              </button>
              <button
                onClick={() => handleDelete(item.id)}
                className="px-3 py-1 bg-red-500 text-white rounded text-sm"
              >
                Delete
              </button>
            </div>

            <div className="mt-2">
              <p className="text-xs truncate">{item.filename}</p>
              <p className="text-xs text-gray-500">
                {(item.size_bytes / 1024).toFixed(1)} KB
              </p>
              {item.tags && item.tags.length > 0 && (
                <div className="flex flex-wrap gap-1 mt-1">
                  {item.tags.map((tag: string) => (
                    <span
                      key={tag}
                      className="text-xs bg-blue-100 px-2 py-0.5 rounded"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

## Setup Steps

1. Create media bucket in Supabase:
   ```bash
   # In Supabase dashboard: Storage → New bucket → "media"
   # Enable public access for read operations
   ```

2. Apply media schema:
   ```bash
   ./scripts/apply-migration.sh skills/supabase-cms/templates/schemas/media-schema.sql
   ```

3. Configure storage policies in Supabase dashboard or via SQL

4. Test media upload:
   ```typescript
   const media = await uploadMedia({
     file: selectedFile
     alt_text: 'Test image'
     tags: ['test']
   });
   ```

## Best Practices

- **Optimize images** before upload (use client-side compression)
- **Generate thumbnails** for faster loading
- **Use CDN transformations** for responsive images
- **Tag media** for better organization and search
- **Set storage limits** per organization/user
- **Clean up orphaned files** regularly
- **Use signed URLs** for private media
- **Implement virus scanning** for user uploads
- **Monitor storage usage** and costs
