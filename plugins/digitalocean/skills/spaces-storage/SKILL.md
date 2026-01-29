---
name: spaces-storage
description: DigitalOcean Spaces (S3-compatible) object storage patterns
---

# Spaces Object Storage Skill

## Overview

DigitalOcean Spaces provides S3-compatible object storage. Use it for:

- File uploads (images, documents, media)
- Static asset hosting
- Application backups
- Data lake storage

## Setup

### Create Space

```bash
doctl spaces create my-space --region nyc3
```

### CDN (Built-in)

Enable CDN for faster global access to your assets.

```bash
# CDN endpoint
https://my-space.nyc3.cdn.digitaloceanspaces.com/file.jpg

# Direct endpoint
https://my-space.nyc3.digitaloceanspaces.com/file.jpg
```

## SDK Integration

### Node.js (@aws-sdk/client-s3)

```typescript
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  ListObjectsV2Command,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const s3 = new S3Client({
  endpoint: 'https://nyc3.digitaloceanspaces.com',
  region: 'nyc3',
  credentials: {
    accessKeyId: process.env.DIGITALOCEAN_SPACES_ACCESS_KEY!,
    secretAccessKey: process.env.DIGITALOCEAN_SPACES_SECRET_KEY!,
  },
});

const BUCKET = 'my-space';

// Upload file
async function uploadFile(key: string, body: Buffer, contentType: string) {
  await s3.send(
    new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: body,
      ContentType: contentType,
      ACL: 'public-read', // or "private"
    })
  );

  return `https://${BUCKET}.nyc3.cdn.digitaloceanspaces.com/${key}`;
}

// Download file
async function downloadFile(key: string) {
  const response = await s3.send(
    new GetObjectCommand({
      Bucket: BUCKET,
      Key: key,
    })
  );

  return response.Body;
}

// Generate presigned URL (for private uploads)
async function getPresignedUploadUrl(key: string, expiresIn = 3600) {
  const command = new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
  });

  return getSignedUrl(s3, command, { expiresIn });
}

// Generate presigned download URL (for private files)
async function getPresignedDownloadUrl(key: string, expiresIn = 3600) {
  const command = new GetObjectCommand({
    Bucket: BUCKET,
    Key: key,
  });

  return getSignedUrl(s3, command, { expiresIn });
}

// List files
async function listFiles(prefix = '') {
  const response = await s3.send(
    new ListObjectsV2Command({
      Bucket: BUCKET,
      Prefix: prefix,
    })
  );

  return response.Contents || [];
}

// Delete file
async function deleteFile(key: string) {
  await s3.send(
    new DeleteObjectCommand({
      Bucket: BUCKET,
      Key: key,
    })
  );
}
```

### Python (boto3)

```python
import boto3
from botocore.config import Config

session = boto3.session.Session()
s3 = session.client(
    's3',
    region_name='nyc3',
    endpoint_url='https://nyc3.digitaloceanspaces.com',
    aws_access_key_id=os.environ['DIGITALOCEAN_SPACES_ACCESS_KEY'],
    aws_secret_access_key=os.environ['DIGITALOCEAN_SPACES_SECRET_KEY']
)

BUCKET = 'my-space'

# Upload file
def upload_file(key: str, file_path: str, content_type: str = None):
    extra_args = {'ACL': 'public-read'}
    if content_type:
        extra_args['ContentType'] = content_type

    s3.upload_file(file_path, BUCKET, key, ExtraArgs=extra_args)
    return f'https://{BUCKET}.nyc3.cdn.digitaloceanspaces.com/{key}'

# Upload from memory
def upload_bytes(key: str, data: bytes, content_type: str):
    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=data,
        ContentType=content_type,
        ACL='public-read'
    )
    return f'https://{BUCKET}.nyc3.cdn.digitaloceanspaces.com/{key}'

# Download file
def download_file(key: str, file_path: str):
    s3.download_file(BUCKET, key, file_path)

# Generate presigned URL
def get_presigned_url(key: str, expires_in: int = 3600):
    return s3.generate_presigned_url(
        'get_object',
        Params={'Bucket': BUCKET, 'Key': key},
        ExpiresIn=expires_in
    )

# List files
def list_files(prefix: str = ''):
    response = s3.list_objects_v2(Bucket=BUCKET, Prefix=prefix)
    return response.get('Contents', [])

# Delete file
def delete_file(key: str):
    s3.delete_object(Bucket=BUCKET, Key=key)
```

## Next.js Integration

### API Route for File Upload

```typescript
// app/api/upload/route.ts
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { nanoid } from 'nanoid';

const s3 = new S3Client({
  endpoint: 'https://nyc3.digitaloceanspaces.com',
  region: 'nyc3',
  credentials: {
    accessKeyId: process.env.DIGITALOCEAN_SPACES_ACCESS_KEY!,
    secretAccessKey: process.env.DIGITALOCEAN_SPACES_SECRET_KEY!,
  },
});

export async function POST(request: Request) {
  const { filename, contentType } = await request.json();

  const key = `uploads/${nanoid()}-${filename}`;

  const command = new PutObjectCommand({
    Bucket: process.env.DIGITALOCEAN_SPACES_BUCKET!,
    Key: key,
    ContentType: contentType,
    ACL: 'public-read',
  });

  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 3600 });
  const publicUrl = `https://${process.env.DIGITALOCEAN_SPACES_BUCKET}.nyc3.cdn.digitaloceanspaces.com/${key}`;

  return Response.json({ uploadUrl, publicUrl, key });
}
```

### Client Upload Component

```typescript
"use client";

import { useState } from "react";

export function FileUpload({ onUpload }: { onUpload: (url: string) => void }) {
  const [uploading, setUploading] = useState(false);

  async function handleUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);

    try {
      // Get presigned URL
      const response = await fetch("/api/upload", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          filename: file.name,
          contentType: file.type,
        }),
      });

      const { uploadUrl, publicUrl } = await response.json();

      // Upload directly to Spaces
      await fetch(uploadUrl, {
        method: "PUT",
        headers: { "Content-Type": file.type },
        body: file,
      });

      onUpload(publicUrl);
    } finally {
      setUploading(false);
    }
  }

  return (
    <input
      type="file"
      onChange={handleUpload}
      disabled={uploading}
    />
  );
}
```

## FastAPI Integration

```python
from fastapi import FastAPI, UploadFile
import boto3
from nanoid import generate

app = FastAPI()

s3 = boto3.client(
    's3',
    region_name='nyc3',
    endpoint_url='https://nyc3.digitaloceanspaces.com',
    aws_access_key_id=os.environ['DIGITALOCEAN_SPACES_ACCESS_KEY'],
    aws_secret_access_key=os.environ['DIGITALOCEAN_SPACES_SECRET_KEY']
)

BUCKET = os.environ['DIGITALOCEAN_SPACES_BUCKET']

@app.post("/upload")
async def upload_file(file: UploadFile):
    key = f"uploads/{generate()}-{file.filename}"

    s3.upload_fileobj(
        file.file,
        BUCKET,
        key,
        ExtraArgs={
            'ACL': 'public-read',
            'ContentType': file.content_type
        }
    )

    return {
        "url": f"https://{BUCKET}.nyc3.cdn.digitaloceanspaces.com/{key}",
        "key": key
    }
```

## Environment Variables

```bash
# .env
DIGITALOCEAN_SPACES_ACCESS_KEY=your_access_key
DIGITALOCEAN_SPACES_SECRET_KEY=your_secret_key
DIGITALOCEAN_SPACES_BUCKET=my-space
DIGITALOCEAN_SPACES_REGION=nyc3
DIGITALOCEAN_SPACES_ENDPOINT=https://nyc3.digitaloceanspaces.com
```

## CORS Configuration

Configure CORS via the DigitalOcean console or API:

```json
{
  "CORSRules": [
    {
      "AllowedOrigins": ["https://myapp.com"],
      "AllowedMethods": ["GET", "PUT", "POST"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3000
    }
  ]
}
```
