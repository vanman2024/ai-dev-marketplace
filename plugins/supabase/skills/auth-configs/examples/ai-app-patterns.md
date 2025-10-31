# Authentication Patterns for AI Applications

Specific authentication patterns and best practices for AI-powered applications using Supabase.

## Table of Contents

1. [AI Chat Applications](#ai-chat-applications)
2. [RAG Systems](#rag-systems)
3. [Multi-Tenant AI Platforms](#multi-tenant-ai-platforms)
4. [API Key Management](#api-key-management)
5. [Usage Tracking & Rate Limiting](#usage-tracking--rate-limiting)
6. [Conversation Ownership](#conversation-ownership)

---

## AI Chat Applications

### Pattern: User-Scoped Conversations

Each conversation belongs to a specific user with row-level security.

#### Database Schema

```sql
-- Conversations table
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
  title TEXT
  model TEXT DEFAULT 'gpt-4'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE
  role TEXT CHECK (role IN ('user', 'assistant', 'system'))
  content TEXT
  tokens_used INTEGER
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users can only see their own conversations
CREATE POLICY "Users can view own conversations"
  ON conversations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own conversations"
  ON conversations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only see messages from their conversations
CREATE POLICY "Users can view own messages"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
      AND conversations.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own messages"
  ON messages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
      AND conversations.user_id = auth.uid()
    )
  );
```

#### Implementation

```typescript
// lib/chat.ts
import { createClient } from '@/lib/supabase'

export async function createConversation(title: string, model: string = 'gpt-4') {
  const supabase = createClient()

  // Get authenticated user
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    throw new Error('Not authenticated')
  }

  // Create conversation
  const { data, error } = await supabase
    .from('conversations')
    .insert({
      user_id: user.id
      title
      model
    })
    .select()
    .single()

  if (error) throw error
  return data
}

export async function sendMessage(
  conversationId: string
  message: string
) {
  const supabase = createClient()

  // Insert user message
  const { error: insertError } = await supabase
    .from('messages')
    .insert({
      conversation_id: conversationId
      role: 'user'
      content: message
    })

  if (insertError) throw insertError

  // Get conversation context
  const { data: messages } = await supabase
    .from('messages')
    .select('role, content')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: true })

  // Call AI API (OpenAI, Anthropic, etc)
  const aiResponse = await callAIAPI(messages || [])

  // Store AI response
  const { error: responseError } = await supabase
    .from('messages')
    .insert({
      conversation_id: conversationId
      role: 'assistant'
      content: aiResponse.content
      tokens_used: aiResponse.tokens
    })

  if (responseError) throw responseError

  return aiResponse
}

async function callAIAPI(messages: any[]) {
  // Your AI API integration
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST'
    headers: {
      'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
      'Content-Type': 'application/json'
    }
    body: JSON.stringify({
      model: 'gpt-4'
      messages
    })
  })

  const data = await response.json()

  return {
    content: data.choices[0].message.content
    tokens: data.usage.total_tokens
  }
}
```

---

## RAG Systems

### Pattern: Document Ownership with Vector Embeddings

Users upload documents that are embedded and searchable only by them.

#### Database Schema

```sql
-- User documents
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
  title TEXT
  content TEXT
  file_url TEXT
  metadata JSONB
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Document chunks with embeddings
CREATE TABLE document_chunks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE
  content TEXT
  embedding vector(1536), -- OpenAI ada-002 dimension
  metadata JSONB
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for similarity search
CREATE INDEX ON document_chunks USING ivfflat (embedding vector_cosine_ops);

-- Row Level Security
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_chunks ENABLE ROW LEVEL SECURITY;

-- Users can only access their own documents
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only access chunks from their documents
CREATE POLICY "Users can view own chunks"
  ON document_chunks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = document_chunks.document_id
      AND documents.user_id = auth.uid()
    )
  );
```

#### Implementation

```typescript
// lib/rag.ts
import { createClient } from '@/lib/supabase'
import OpenAI from 'openai'

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
})

export async function uploadDocument(
  file: File
  title: string
) {
  const supabase = createClient()

  // Get user
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Not authenticated')

  // Upload file to Supabase Storage
  const fileExt = file.name.split('.').pop()
  const fileName = `${user.id}/${Date.now()}.${fileExt}`

  const { error: uploadError } = await supabase.storage
    .from('documents')
    .upload(fileName, file)

  if (uploadError) throw uploadError

  // Get public URL
  const { data: { publicUrl } } = supabase.storage
    .from('documents')
    .getPublicUrl(fileName)

  // Extract text from file
  const text = await extractTextFromFile(file)

  // Create document record
  const { data: document, error } = await supabase
    .from('documents')
    .insert({
      user_id: user.id
      title
      content: text
      file_url: publicUrl
    })
    .select()
    .single()

  if (error) throw error

  // Chunk and embed document
  await chunkAndEmbedDocument(document.id, text)

  return document
}

async function chunkAndEmbedDocument(documentId: string, text: string) {
  const supabase = createClient()

  // Split text into chunks (simple implementation)
  const chunkSize = 1000
  const chunks = []

  for (let i = 0; i < text.length; i += chunkSize) {
    chunks.push(text.slice(i, i + chunkSize))
  }

  // Generate embeddings
  for (const chunk of chunks) {
    const embedding = await openai.embeddings.create({
      model: 'text-embedding-ada-002'
      input: chunk
    })

    await supabase.from('document_chunks').insert({
      document_id: documentId
      content: chunk
      embedding: embedding.data[0].embedding
    })
  }
}

export async function queryDocuments(query: string, limit: number = 5) {
  const supabase = createClient()

  // Get user
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Not authenticated')

  // Generate query embedding
  const queryEmbedding = await openai.embeddings.create({
    model: 'text-embedding-ada-002'
    input: query
  })

  // Search for similar chunks (only from user's documents)
  const { data: chunks, error } = await supabase.rpc('match_documents', {
    query_embedding: queryEmbedding.data[0].embedding
    match_threshold: 0.78
    match_count: limit
  })

  if (error) throw error

  return chunks
}

async function extractTextFromFile(file: File): Promise<string> {
  // Implement text extraction based on file type
  // For PDFs: use pdf-parse
  // For DOCX: use mammoth
  // For plain text: just read the file
  const text = await file.text()
  return text
}
```

#### Similarity Search Function

```sql
-- Create function for similarity search
CREATE OR REPLACE FUNCTION match_documents(
  query_embedding vector(1536)
  match_threshold float
  match_count int
)
RETURNS TABLE (
  id uuid
  document_id uuid
  content text
  similarity float
)
LANGUAGE sql STABLE
AS $$
  SELECT
    document_chunks.id
    document_chunks.document_id
    document_chunks.content
    1 - (document_chunks.embedding <=> query_embedding) AS similarity
  FROM document_chunks
  JOIN documents ON documents.id = document_chunks.document_id
  WHERE documents.user_id = auth.uid()
    AND 1 - (document_chunks.embedding <=> query_embedding) > match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
$$;
```

---

## Multi-Tenant AI Platforms

### Pattern: Organization-Based Access with Role Management

#### Database Schema

```sql
-- Organizations
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
  name TEXT NOT NULL
  plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'pro', 'enterprise'))
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Organization members
CREATE TABLE organization_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member'))
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  UNIQUE(organization_id, user_id)
);

-- AI model access based on plan
CREATE TABLE ai_models (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
  name TEXT NOT NULL
  provider TEXT NOT NULL
  required_plan TEXT DEFAULT 'free' CHECK (required_plan IN ('free', 'pro', 'enterprise'))
  rate_limit INTEGER DEFAULT 100 -- requests per day
);

-- Organization AI usage
CREATE TABLE ai_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE
  user_id UUID REFERENCES auth.users(id)
  model_id UUID REFERENCES ai_models(id)
  tokens_used INTEGER
  cost DECIMAL(10, 4)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;

-- Users can see organizations they're members of
CREATE POLICY "Members can view organization"
  ON organizations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_members.organization_id = organizations.id
      AND organization_members.user_id = auth.uid()
    )
  );

-- Users can see fellow organization members
CREATE POLICY "Members can view other members"
  ON organization_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members AS om
      WHERE om.organization_id = organization_members.organization_id
      AND om.user_id = auth.uid()
    )
  );
```

#### Custom JWT Claims for Organization Access

```sql
-- Function to add organization to JWT claims
CREATE OR REPLACE FUNCTION custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  claims jsonb;
  user_orgs jsonb;
BEGIN
  -- Fetch user's organizations
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', o.id
      'role', om.role
      'plan', o.plan
    )
  )
  INTO user_orgs
  FROM organization_members om
  JOIN organizations o ON o.id = om.organization_id
  WHERE om.user_id = (event->>'user_id')::uuid;

  -- Add to JWT claims
  claims := event->'claims';
  claims := jsonb_set(claims, '{organizations}', COALESCE(user_orgs, '[]'::jsonb));

  event := jsonb_set(event, '{claims}', claims);

  RETURN event;
END;
$$;

GRANT EXECUTE ON FUNCTION custom_access_token_hook TO supabase_auth_admin;
```

---

## API Key Management

### Pattern: User-Generated API Keys for AI Platform Access

```sql
-- API Keys table
CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
  key_hash TEXT NOT NULL UNIQUE, -- Store hashed version
  name TEXT
  last_used_at TIMESTAMP WITH TIME ZONE
  expires_at TIMESTAMP WITH TIME ZONE
  is_active BOOLEAN DEFAULT true
  scopes TEXT[] DEFAULT ARRAY['read', 'write']
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX ON api_keys(key_hash);

ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own API keys"
  ON api_keys FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

#### Implementation

```typescript
// lib/api-keys.ts
import { createClient } from '@/lib/supabase'
import crypto from 'crypto'

export async function generateAPIKey(name: string, expiresInDays?: number) {
  const supabase = createClient()

  // Generate random API key
  const apiKey = `sk_${crypto.randomBytes(32).toString('hex')}`

  // Hash for storage
  const keyHash = crypto
    .createHash('sha256')
    .update(apiKey)
    .digest('hex')

  // Calculate expiration
  const expiresAt = expiresInDays
    ? new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000)
    : null

  // Get user
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Not authenticated')

  // Store hashed key
  const { error } = await supabase.from('api_keys').insert({
    user_id: user.id
    key_hash: keyHash
    name
    expires_at: expiresAt
  })

  if (error) throw error

  // Return plaintext key (only time it's shown)
  return {
    apiKey, // Show to user ONCE
    expiresAt
  }
}

export async function validateAPIKey(apiKey: string) {
  const supabase = createClient()

  // Hash provided key
  const keyHash = crypto
    .createHash('sha256')
    .update(apiKey)
    .digest('hex')

  // Look up key
  const { data, error } = await supabase
    .from('api_keys')
    .select('*, user:auth.users(*)')
    .eq('key_hash', keyHash)
    .eq('is_active', true)
    .single()

  if (error || !data) return null

  // Check expiration
  if (data.expires_at && new Date(data.expires_at) < new Date()) {
    return null
  }

  // Update last used
  await supabase
    .from('api_keys')
    .update({ last_used_at: new Date().toISOString() })
    .eq('id', data.id)

  return data.user
}
```

---

## Usage Tracking & Rate Limiting

```typescript
// lib/rate-limit.ts
import { createClient } from '@/lib/supabase'

export async function checkRateLimit(
  userId: string
  model: string
  limit: number = 100
): Promise<boolean> {
  const supabase = createClient()

  // Count usage in last 24 hours
  const { count } = await supabase
    .from('ai_usage')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('model_id', model)
    .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())

  return (count || 0) < limit
}

export async function trackUsage(
  userId: string
  organizationId: string
  modelId: string
  tokensUsed: number
  cost: number
) {
  const supabase = createClient()

  await supabase.from('ai_usage').insert({
    user_id: userId
    organization_id: organizationId
    model_id: modelId
    tokens_used: tokensUsed
    cost
  })
}
```

---

## Conversation Ownership

### Pattern: Shared Conversations with Permissions

```sql
-- Conversation permissions
CREATE TABLE conversation_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
  permission TEXT DEFAULT 'read' CHECK (permission IN ('read', 'write', 'admin'))
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  UNIQUE(conversation_id, user_id)
);

-- Update RLS policy for shared access
DROP POLICY "Users can view own conversations" ON conversations;

CREATE POLICY "Users can view accessible conversations"
  ON conversations FOR SELECT
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM conversation_permissions
      WHERE conversation_permissions.conversation_id = conversations.id
      AND conversation_permissions.user_id = auth.uid()
    )
  );
```

---

## Best Practices

1. **Always use RLS** - Database-level security prevents data leaks
2. **Hash API keys** - Never store plaintext keys
3. **Track usage** - Monitor costs per user/organization
4. **Implement rate limiting** - Prevent abuse
5. **Use JWT claims** - Reduce database queries for authorization
6. **Audit access** - Log who accessed what and when
7. **Expire sessions** - Force re-authentication periodically

## Example: Complete AI Chat App

See [complete example implementation](https://github.com/supabase/supabase/tree/master/examples/ai-chat) for a full working example.
