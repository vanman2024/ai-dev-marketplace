# Marketing Automation Database Architecture

**Date:** 2025-10-26  
**Purpose:** SQLite (dev) + PostgreSQL/Supabase (production) with automated categorization, tagging, and caching

---

## 🏗️ Architecture Overview

### Development vs Production

| Aspect | Development | Production |
|--------|------------|------------|
| **Database** | SQLite (local file) | PostgreSQL (Supabase hosted) |
| **Connection** | Direct file access | Supabase Python client |
| **Migrations** | Auto-apply on startup | Supabase migrations |
| **Caching** | In-memory dict | Redis + Supabase caching |
| **Access** | FastMCP server local | FastMCP server + FastAPI |

### Why This Split?

**SQLite for Development:**
- ✅ Zero configuration - just a file
- ✅ Fast local testing
- ✅ Easy to reset/wipe
- ✅ No network latency
- ✅ Perfect for agent development

**PostgreSQL/Supabase for Production:**
- ✅ Multi-user concurrent access
- ✅ Pgvector for AI embeddings
- ✅ Row-level security
- ✅ Real-time subscriptions
- ✅ Automatic backups
- ✅ RESTful API auto-generated

---

## 📊 Database Schema

### Core Tables

#### 1. `campaigns`
Stores campaign metadata and configuration.

```sql
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    campaign_type VARCHAR(50) NOT NULL, -- job_recruitment, product_launch, event_promotion, etc.
    status VARCHAR(20) NOT NULL DEFAULT 'draft', -- draft, active, paused, completed
    target_platforms TEXT[], -- array of platform names
    content_style TEXT,
    visual_style TEXT,
    hashtag_strategy TEXT,
    cta_pattern TEXT,
    
    -- Budget tracking
    estimated_cost DECIMAL(10,2),
    actual_cost DECIMAL(10,2) DEFAULT 0,
    
    -- Scheduling
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    posting_frequency VARCHAR(100),
    optimal_times TEXT[], -- array of time strings
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(255),
    
    -- AI embeddings for semantic search
    embedding VECTOR(1536) -- OpenAI ada-002 dimensions
);

CREATE INDEX idx_campaigns_type ON campaigns(campaign_type);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_embedding ON campaigns USING ivfflat (embedding vector_cosine_ops);
```

#### 2. `content_assets`
Stores generated content (text, images, videos).

```sql
CREATE TABLE content_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    
    -- Content identification
    asset_type VARCHAR(20) NOT NULL, -- text, image, video
    content TEXT, -- for text content
    file_path VARCHAR(500), -- for media files
    file_url VARCHAR(500), -- public URL if uploaded
    
    -- Generation details
    generator VARCHAR(50), -- claude_sonnet, imagen3, veo2, gemini_pro
    prompt TEXT, -- original generation prompt
    parameters JSONB, -- generation parameters
    generation_cost DECIMAL(10,4),
    generation_time_ms INTEGER,
    
    -- Categorization (automated by AI)
    primary_category VARCHAR(100),
    tags TEXT[], -- automated tags
    sentiment VARCHAR(20), -- positive, neutral, negative, mixed
    target_audience VARCHAR(100),
    
    -- Quality metrics
    quality_score DECIMAL(3,2), -- 0-1 score from AI analysis
    revision_count INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- AI embeddings
    embedding VECTOR(1536)
);

CREATE INDEX idx_content_campaign ON content_assets(campaign_id);
CREATE INDEX idx_content_type ON content_assets(asset_type);
CREATE INDEX idx_content_category ON content_assets(primary_category);
CREATE INDEX idx_content_tags ON content_assets USING GIN (tags);
CREATE INDEX idx_content_embedding ON content_assets USING ivfflat (embedding vector_cosine_ops);
```

#### 3. `social_posts`
Tracks social media posts and their performance.

```sql
CREATE TABLE social_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    content_asset_id UUID REFERENCES content_assets(id),
    
    -- Post details
    platform VARCHAR(50) NOT NULL, -- linkedin, x, instagram, etc.
    post_text TEXT,
    media_urls TEXT[], -- array of media URLs
    scheduled_time TIMESTAMP,
    posted_time TIMESTAMP,
    
    -- Post configuration
    hashtags TEXT[],
    mentions TEXT[],
    post_url VARCHAR(500), -- URL after posting
    
    -- Status
    status VARCHAR(20) DEFAULT 'scheduled', -- scheduled, posted, failed, deleted
    error_message TEXT,
    
    -- Analytics (updated via Ayrshare webhook or polling)
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    engagement_rate DECIMAL(5,4), -- calculated metric
    
    -- Cost tracking
    posting_cost DECIMAL(10,4), -- Ayrshare posting cost
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_analytics_update TIMESTAMP
);

CREATE INDEX idx_posts_campaign ON social_posts(campaign_id);
CREATE INDEX idx_posts_platform ON social_posts(platform);
CREATE INDEX idx_posts_status ON social_posts(status);
CREATE INDEX idx_posts_scheduled ON social_posts(scheduled_time);
```

#### 4. `categories`
Master list of categories for automated categorization.

```sql
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    parent_id UUID REFERENCES categories(id), -- hierarchical categories
    description TEXT,
    keywords TEXT[], -- keywords for auto-categorization
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    
    -- AI embeddings for semantic matching
    embedding VECTOR(1536),
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_embedding ON categories USING ivfflat (embedding vector_cosine_ops);
```

#### 5. `tags`
Master list of tags with auto-suggestion.

```sql
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    tag_type VARCHAR(50), -- industry, audience, emotion, format, etc.
    description TEXT,
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    related_tags TEXT[], -- suggested related tags
    
    -- AI embeddings
    embedding VECTOR(1536),
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_tags_type ON tags(tag_type);
CREATE INDEX idx_tags_usage ON tags(usage_count DESC);
CREATE INDEX idx_tags_embedding ON tags USING ivfflat (embedding vector_cosine_ops);
```

#### 6. `automation_rules`
Rules for automated categorization and tagging.

```sql
CREATE TABLE automation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    rule_type VARCHAR(50) NOT NULL, -- categorization, tagging, scheduling, approval
    
    -- Conditions (JSON for flexibility)
    conditions JSONB, -- {"content_type": "image", "contains_keyword": "product"}
    
    -- Actions (JSON for flexibility)
    actions JSONB, -- {"add_category": "product_marketing", "add_tags": ["product", "launch"]}
    
    -- Priority and status
    priority INTEGER DEFAULT 0, -- higher = runs first
    enabled BOOLEAN DEFAULT true,
    
    -- Performance tracking
    execution_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    last_execution TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_rules_type ON automation_rules(rule_type);
CREATE INDEX idx_rules_priority ON automation_rules(priority DESC);
CREATE INDEX idx_rules_enabled ON automation_rules(enabled) WHERE enabled = true;
```

#### 7. `cache_entries`
Caching layer for expensive operations.

```sql
CREATE TABLE cache_entries (
    cache_key VARCHAR(255) PRIMARY KEY,
    cache_value JSONB NOT NULL,
    
    -- Cache metadata
    cache_type VARCHAR(50), -- ai_analysis, api_response, embeddings
    ttl_seconds INTEGER DEFAULT 3600,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    last_accessed TIMESTAMP DEFAULT NOW(),
    access_count INTEGER DEFAULT 0
);

CREATE INDEX idx_cache_expires ON cache_entries(expires_at);
CREATE INDEX idx_cache_type ON cache_entries(cache_type);
```

---

## 🤖 Automated Categorization System

### How It Works

```python
# Pseudo-code for automated categorization pipeline

async def categorize_content(content_asset_id: UUID):
    """
    Automated categorization using AI + rules engine.
    """
    # 1. Get content
    content = await db.fetch_content_asset(content_asset_id)
    
    # 2. Generate embedding (cache if exists)
    cache_key = f"embedding:{content_asset_id}"
    embedding = await cache.get(cache_key)
    
    if not embedding:
        embedding = await generate_embedding(content.text or content.prompt)
        await cache.set(cache_key, embedding, ttl=86400)  # 24 hours
    
    # 3. Find similar categories using vector search
    similar_categories = await db.execute("""
        SELECT name, similarity
        FROM categories
        ORDER BY embedding <-> $1
        LIMIT 5
    """, embedding)
    
    # 4. Apply automation rules
    applicable_rules = await db.fetch_automation_rules(
        rule_type="categorization",
        conditions_match=content
    )
    
    # 5. AI analysis for categorization
    cache_key = f"ai_category:{content_asset_id}"
    ai_category = await cache.get(cache_key)
    
    if not ai_category:
        ai_category = await claude.analyze(
            prompt=f"Categorize this content: {content.text}",
            choices=similar_categories
        )
        await cache.set(cache_key, ai_category, ttl=3600)  # 1 hour
    
    # 6. Combine rule-based + AI categorization
    final_category = resolve_category(
        rule_categories=[r.actions["category"] for r in applicable_rules],
        ai_category=ai_category,
        similar_categories=similar_categories
    )
    
    # 7. Update content asset
    await db.update_content_asset(
        content_asset_id,
        primary_category=final_category,
        embedding=embedding
    )
    
    # 8. Update category usage count
    await db.increment_category_usage(final_category)
```

### Automated Tagging System

```python
async def auto_tag_content(content_asset_id: UUID):
    """
    Automated tagging using AI + NLP.
    """
    # 1. Get content
    content = await db.fetch_content_asset(content_asset_id)
    
    # 2. Extract keywords (cached)
    cache_key = f"keywords:{content_asset_id}"
    keywords = await cache.get(cache_key)
    
    if not keywords:
        keywords = await extract_keywords(content.text)
        await cache.set(cache_key, keywords, ttl=3600)
    
    # 3. Match to existing tags via embeddings
    content_embedding = content.embedding
    similar_tags = await db.execute("""
        SELECT name, similarity
        FROM tags
        WHERE embedding <-> $1 < 0.3  -- similarity threshold
        ORDER BY embedding <-> $1
        LIMIT 10
    """, content_embedding)
    
    # 4. AI-suggested tags
    cache_key = f"ai_tags:{content_asset_id}"
    ai_tags = await cache.get(cache_key)
    
    if not ai_tags:
        ai_tags = await claude.generate_tags(
            content=content.text,
            existing_tags=similar_tags,
            max_tags=8
        )
        await cache.set(cache_key, ai_tags, ttl=3600)
    
    # 5. Apply automation rules
    rule_tags = []
    for rule in await db.fetch_tagging_rules():
        if rule.matches(content):
            rule_tags.extend(rule.actions["add_tags"])
    
    # 6. Combine and deduplicate
    final_tags = deduplicate_tags(
        keyword_tags=keywords,
        similar_tags=[t["name"] for t in similar_tags],
        ai_tags=ai_tags,
        rule_tags=rule_tags
    )
    
    # 7. Update content asset
    await db.update_content_asset(
        content_asset_id,
        tags=final_tags
    )
    
    # 8. Update tag usage counts
    for tag in final_tags:
        await db.increment_tag_usage(tag)
```

---

## 🔄 Caching Strategy

### Multi-Layer Caching

```python
class CacheManager:
    """
    Three-tier caching system.
    """
    
    def __init__(self):
        # Layer 1: In-memory (fastest, smallest)
        self.memory_cache = {}  # Limited to 1000 items
        
        # Layer 2: SQLite/Postgres cache table (persistent)
        self.db_cache = DatabaseCache()
        
        # Layer 3: Redis (production only, shared across instances)
        self.redis_cache = RedisCache() if IS_PRODUCTION else None
    
    async def get(self, key: str) -> Any:
        """Get from cache with fallback."""
        # Try memory first
        if key in self.memory_cache:
            return self.memory_cache[key]
        
        # Try Redis (production only)
        if self.redis_cache:
            value = await self.redis_cache.get(key)
            if value:
                self.memory_cache[key] = value  # Promote to memory
                return value
        
        # Try database cache
        value = await self.db_cache.get(key)
        if value:
            self.memory_cache[key] = value  # Promote to memory
            if self.redis_cache:
                await self.redis_cache.set(key, value)  # Promote to Redis
            return value
        
        return None
    
    async def set(self, key: str, value: Any, ttl: int = 3600):
        """Set in all cache layers."""
        # Store in memory
        self.memory_cache[key] = value
        
        # Evict oldest if memory cache is full
        if len(self.memory_cache) > 1000:
            oldest_key = next(iter(self.memory_cache))
            del self.memory_cache[oldest_key]
        
        # Store in Redis (production)
        if self.redis_cache:
            await self.redis_cache.set(key, value, ttl)
        
        # Store in database cache
        await self.db_cache.set(key, value, ttl)
```

### What Gets Cached

| Data Type | TTL | Storage |
|-----------|-----|---------|
| **AI embeddings** | 24 hours | All layers |
| **AI categorization** | 1 hour | All layers |
| **AI tag suggestions** | 1 hour | All layers |
| **API responses** (Ayrshare) | 5 minutes | Memory + Redis |
| **Analytics data** | 30 minutes | All layers |
| **Campaign configs** | 1 hour | Memory only |
| **Automation rules** | 5 minutes | Memory only |

---

## 🔌 Production Architecture

### FastAPI + Supabase Integration

```python
"""
production_server.py - FastAPI server for production use
"""

from fastapi import FastAPI, Depends, HTTPException
from supabase import create_client, Client
import os
from typing import List, Dict, Any
from uuid import UUID

# Initialize FastAPI
app = FastAPI(title="Marketing Automation API")

# Initialize Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Dependency injection for database
async def get_db():
    return supabase

@app.post("/campaigns")
async def create_campaign(
    campaign_data: Dict[str, Any],
    db: Client = Depends(get_db)
):
    """Create a new campaign."""
    # Generate AI embedding for campaign
    embedding = await generate_embedding(campaign_data["name"])
    campaign_data["embedding"] = embedding
    
    # Insert into Supabase
    result = db.table("campaigns").insert(campaign_data).execute()
    
    # Trigger automated categorization
    await categorize_campaign(result.data[0]["id"])
    
    return result.data[0]

@app.get("/campaigns/{campaign_id}/content")
async def get_campaign_content(
    campaign_id: UUID,
    db: Client = Depends(get_db)
):
    """Get all content for a campaign."""
    result = db.table("content_assets") \
        .select("*") \
        .eq("campaign_id", campaign_id) \
        .execute()
    
    return result.data

@app.post("/content/categorize")
async def categorize_content_endpoint(
    content_id: UUID,
    db: Client = Depends(get_db)
):
    """Manually trigger categorization."""
    await categorize_content(content_id)
    
    # Get updated content
    result = db.table("content_assets") \
        .select("*") \
        .eq("id", content_id) \
        .single() \
        .execute()
    
    return result.data

@app.get("/search/semantic")
async def semantic_search(
    query: str,
    limit: int = 10,
    db: Client = Depends(get_db)
):
    """Semantic search using embeddings."""
    # Generate query embedding
    query_embedding = await generate_embedding(query)
    
    # Use Supabase RPC for vector search
    result = db.rpc(
        "semantic_search_content",
        {
            "query_embedding": query_embedding,
            "match_count": limit
        }
    ).execute()
    
    return result.data
```

### Supabase RPC Functions

```sql
-- SQL function for semantic search
CREATE OR REPLACE FUNCTION semantic_search_content(
    query_embedding VECTOR(1536),
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    primary_category VARCHAR(100),
    tags TEXT[],
    similarity FLOAT
)
LANGUAGE SQL
AS $$
    SELECT
        id,
        content,
        primary_category,
        tags,
        1 - (embedding <-> query_embedding) AS similarity
    FROM content_assets
    WHERE embedding IS NOT NULL
    ORDER BY embedding <-> query_embedding
    LIMIT match_count;
$$;
```

---

## 🛠️ MCP Server Integration

### Development Mode (SQLite)

```python
"""
mcp_server_dev.py - MCP server using SQLite
"""

from fastmcp import FastMCP
import sqlite3
import asyncio

mcp = FastMCP("Marketing Automation Dev")

# SQLite connection
DB_PATH = "marketing_automation.db"

def get_db():
    return sqlite3.connect(DB_PATH)

@mcp.tool()
def create_campaign(name: str, campaign_type: str) -> Dict[str, Any]:
    """Create a new campaign (development mode)."""
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute("""
        INSERT INTO campaigns (name, campaign_type, status)
        VALUES (?, ?, 'draft')
    """, (name, campaign_type))
    
    campaign_id = cursor.lastrowid
    db.commit()
    db.close()
    
    # Trigger automated categorization
    asyncio.create_task(categorize_campaign(campaign_id))
    
    return {"id": campaign_id, "name": name, "status": "draft"}

if __name__ == "__main__":
    mcp.run()
```

### Production Mode (Supabase via FastAPI)

```python
"""
mcp_server_prod.py - MCP server using Supabase via FastAPI
"""

from fastmcp import FastMCP
import httpx
import os

mcp = FastMCP("Marketing Automation Production")

# FastAPI server URL
API_URL = os.getenv("API_URL", "https://api.example.com")

@mcp.tool()
async def create_campaign(name: str, campaign_type: str) -> Dict[str, Any]:
    """Create a new campaign (production mode via API)."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{API_URL}/campaigns",
            json={"name": name, "campaign_type": campaign_type}
        )
        return response.json()

@mcp.tool()
async def search_content(query: str, limit: int = 10) -> List[Dict]:
    """Semantic search for content."""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{API_URL}/search/semantic",
            params={"query": query, "limit": limit}
        )
        return response.json()

if __name__ == "__main__":
    mcp.run()
```

---

## 📝 Agent Responsibilities

### Agent: `database-schema-agent`
**Responsibility:** Create and manage database schema

**Tasks:**
- Initialize SQLite database for development
- Create Supabase migration files for production
- Ensure schema parity between SQLite and PostgreSQL
- Add indexes for performance
- Create RPC functions for complex queries

### Agent: `categorization-agent`
**Responsibility:** Automated categorization system

**Tasks:**
- Implement categorization pipeline
- Train/fine-tune categorization models
- Create automation rules
- Monitor categorization accuracy
- Update category embeddings

### Agent: `cache-manager-agent`
**Responsibility:** Caching strategy and implementation

**Tasks:**
- Implement three-tier cache system
- Set appropriate TTLs
- Monitor cache hit rates
- Implement cache invalidation
- Handle cache warming

### Agent: `supabase-integration-agent`
**Responsibility:** Supabase setup and configuration

**Tasks:**
- Create Supabase project
- Configure Row-Level Security (RLS)
- Set up authentication
- Create storage buckets
- Configure webhooks

---

## 🚀 Next Steps

1. **Phase 1: SQLite Development**
   - Create SQLite schema
   - Implement basic CRUD operations
   - Test MCP server locally

2. **Phase 2: Automated Categorization**
   - Implement AI categorization
   - Add automation rules engine
   - Test tagging accuracy

3. **Phase 3: Caching Layer**
   - Add in-memory cache
   - Implement database cache table
   - Monitor performance improvements

4. **Phase 4: Supabase Migration**
   - Create Supabase project
   - Run migrations
   - Test with Supabase Python client

5. **Phase 5: FastAPI Production Server**
   - Build REST API
   - Add authentication
   - Deploy to production

---

**This architecture ensures:**
- ✅ Fast development with SQLite
- ✅ Scalable production with Supabase
- ✅ Automated categorization/tagging
- ✅ Multi-layer caching
- ✅ Flexible MCP + FastAPI access
