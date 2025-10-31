# Supabase Integration Guide for Marketing Automation

## Overview

This document provides comprehensive guidance on integrating Supabase with the marketing automation MCP server. It covers database operations, real-time subscriptions, authentication, storage, and production deployment patterns.

---

## Table of Contents

1. [Python Client Setup](#python-client-setup)
2. [Database Operations](#database-operations)
3. [Real-Time Subscriptions](#real-time-subscriptions)
4. [Authentication](#authentication)
5. [Storage Operations](#storage-operations)
6. [Production Architecture](#production-architecture)
7. [Performance Considerations](#performance-considerations)

---

## Python Client Setup

### Installation

```bash
pip install supabase>=2.0.0
```

### Basic Initialization

```python
import os
from supabase import create_client, Client

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(url, key)
```

### Async Client (Required for Realtime)

```python
import asyncio
from supabase import acreate_client, AsyncClient

async def create_supabase():
    url: str = os.environ.get("SUPABASE_URL")
    key: str = os.environ.get("SUPABASE_KEY")
    supabase: AsyncClient = await acreate_client(url, key)
    return supabase
```

### With Timeout Option

```python
from supabase import create_client, Client
from supabase.lib.client_options import ClientOptions

supabase: Client = create_client(
    url
    key
    options=ClientOptions(
        postgrest_client_timeout=10
        storage_client_timeout=10
    )
)
```

---

## Database Operations

### Fetch Data

#### Get All Records

```python
response = (
    supabase.table("campaigns")
    .select("*")
    .execute()
)
```

#### Select Specific Columns

```python
response = (
    supabase.table("campaigns")
    .select("id, name, campaign_type, created_at")
    .execute()
)
```

#### Query Referenced Tables (Foreign Keys)

```python
# Get campaigns with their content assets
response = (
    supabase.table("campaigns")
    .select("*, content_assets(*)")
    .execute()
)
```

#### Filtering

```python
# Equal to
response = (
    supabase.table("campaigns")
    .select("*")
    .eq("campaign_type", "job_recruitment")
    .execute()
)

# Greater than
response = (
    supabase.table("campaigns")
    .select("*")
    .gt("budget", 1000)
    .execute()
)

# Less than
response = (
    supabase.table("campaigns")
    .select("*")
    .lt("budget", 5000)
    .execute()
)

# Pattern matching (LIKE)
response = (
    supabase.table("campaigns")
    .select("*")
    .like("name", "%marketing%")
    .execute()
)

# In array
response = (
    supabase.table("campaigns")
    .select("*")
    .in_("campaign_type", ["job_recruitment", "event_promotion"])
    .execute()
)
```

### Insert Data

#### Single Record

```python
response = (
    supabase.table("campaigns")
    .insert({
        "name": "Summer Job Fair"
        "campaign_type": "job_recruitment"
        "budget": 2000.00
        "status": "draft"
    })
    .execute()
)
```

#### Bulk Insert

```python
response = (
    supabase.table("campaigns")
    .insert([
        {"name": "Campaign 1", "campaign_type": "job_recruitment"}
        {"name": "Campaign 2", "campaign_type": "product_launch"}
        {"name": "Campaign 3", "campaign_type": "event_promotion"}
    ])
    .execute()
)
```

### Update Data

```python
response = (
    supabase.table("campaigns")
    .update({"status": "active"})
    .eq("id", 1)
    .execute()
)
```

### Upsert Data

```python
response = (
    supabase.table("campaigns")
    .upsert({"id": 1, "name": "Updated Campaign"})
    .execute()
)
```

### Delete Data

```python
response = (
    supabase.table("campaigns")
    .delete()
    .eq("id", 1)
    .execute()
)
```

### Call RPC Functions

```python
response = (
    supabase.rpc("categorize_campaign", {"campaign_id": 1})
    .execute()
)
```

---

## Real-Time Subscriptions

### Enable Realtime for Tables

First, enable replication for your tables:

```sql
alter publication supabase_realtime
add table campaigns;

alter publication supabase_realtime
add table content_assets;
```

### Listen to All Database Changes

```python
async def setup_realtime():
    supabase = await acreate_client(url, key)
    
    def handle_changes(payload):
        print("Database change:", payload)
    
    channel = supabase.channel("db-changes")
    await channel.on_postgres_changes(
        event="*"
        schema="public"
        callback=handle_changes
    ).subscribe()
```

### Listen to Specific Tables

```python
def handle_campaign_changes(payload):
    print("Campaign changed:", payload)

channel = supabase.channel("campaign-changes")
await channel.on_postgres_changes(
    event="*"
    schema="public"
    table="campaigns"
    callback=handle_campaign_changes
).subscribe()
```

### Listen to INSERT Events Only

```python
channel = supabase.channel("new-campaigns")
await channel.on_postgres_changes(
    event="INSERT"
    schema="public"
    table="campaigns"
    callback=lambda payload: print("New campaign:", payload)
).subscribe()
```

### Listen to UPDATE Events Only

```python
channel = supabase.channel("updated-campaigns")
await channel.on_postgres_changes(
    event="UPDATE"
    schema="public"
    table="campaigns"
    callback=lambda payload: print("Campaign updated:", payload)
).subscribe()
```

### Listen to DELETE Events Only

```python
channel = supabase.channel("deleted-campaigns")
await channel.on_postgres_changes(
    event="DELETE"
    schema="public"
    table="campaigns"
    callback=lambda payload: print("Campaign deleted:", payload)
).subscribe()
```

### Filter Changes by Column Value

```python
channel = supabase.channel("active-campaigns")
await channel.on_postgres_changes(
    event="UPDATE"
    schema="public"
    table="campaigns"
    filter="status=eq.active"
    callback=lambda payload: print("Campaign activated:", payload)
).subscribe()
```

### Multiple Listeners on Same Channel

```python
channel = supabase.channel("multi-listener")

# Listen to campaigns
await channel.on_postgres_changes(
    event="*"
    schema="public"
    table="campaigns"
    callback=lambda p: print("Campaign change:", p)
)

# Listen to content assets
await channel.on_postgres_changes(
    event="INSERT"
    schema="public"
    table="content_assets"
    callback=lambda p: print("New asset:", p)
)

await channel.subscribe()
```

### Broadcast Messages

```python
channel = supabase.channel("notifications")

def on_subscribe(status, err):
    if status == RealtimeSubscribeStates.SUBSCRIBED:
        asyncio.create_task(channel.send_broadcast(
            "campaign-update"
            {"campaign_id": 1, "message": "Campaign published!"}
        ))

await channel.on_broadcast(
    event="campaign-update"
    callback=lambda payload: print("Broadcast:", payload)
).subscribe(on_subscribe)
```

### Presence Tracking

```python
channel = supabase.channel("online-users")

def on_presence_sync():
    state = channel.presence_state()
    print("Online users:", state)

def on_presence_join(key, current, new):
    print("User joined:", key)

def on_presence_leave(key, current, left):
    print("User left:", key)

await channel.on_presence_sync(on_presence_sync)
await channel.on_presence_join(on_presence_join)
await channel.on_presence_leave(on_presence_leave)
await channel.track({"user": "alice", "status": "online"})
await channel.subscribe()
```

### Unsubscribe from Channels

```python
# Remove single channel
await supabase.remove_channel(my_channel)

# Remove all channels
await supabase.remove_all_channels()
```

### Get Old Records on UPDATE/DELETE

To receive the previous state of records:

```sql
alter table campaigns replica identity full;
```

**Warning**: RLS policies are NOT applied to DELETE statements. When RLS is enabled with `replica identity full`, the old record contains only primary keys.

---

## Authentication

### Sign Up

```python
response = supabase.auth.sign_up({
    "email": "user@example.com"
    "password": "secure_password"
})
```

### Sign In

```python
response = supabase.auth.sign_in_with_password({
    "email": "user@example.com"
    "password": "secure_password"
})
```

### Sign Out

```python
response = supabase.auth.sign_out()
```

### Get Current User

```python
user = supabase.auth.get_user()
```

### Get Session

```python
session = supabase.auth.get_session()
```

### Refresh Session

```python
response = supabase.auth.refresh_session()
```

### Update User

```python
response = supabase.auth.update_user({
    "email": "new@email.com"
})
```

### Custom JWT Tokens

```python
# Set custom token
supabase.realtime.setAuth('your-custom-jwt')

# Then subscribe to channels
channel = supabase.channel('secure-channel').subscribe()
```

---

## Storage Operations

### Create Bucket

```python
response = supabase.storage.create_bucket(
    "campaign-assets"
    options={
        "public": False
        "allowed_mime_types": ["image/png", "image/jpeg"]
        "file_size_limit": 10485760  # 10MB
    }
)
```

### Upload File

```python
with open("./assets/banner.png", "rb") as f:
    response = (
        supabase.storage
        .from_("campaign-assets")
        .upload(
            file=f
            path="banners/summer-2024.png"
            file_options={"cache-control": "3600", "upsert": "false"}
        )
    )
```

### Download File

```python
with open("./downloaded-banner.png", "wb+") as f:
    response = (
        supabase.storage
        .from_("campaign-assets")
        .download("banners/summer-2024.png")
    )
    f.write(response)
```

### List Files

```python
response = (
    supabase.storage
    .from_("campaign-assets")
    .list(
        "banners"
        {
            "limit": 100
            "offset": 0
            "sortBy": {"column": "name", "order": "desc"}
        }
    )
)
```

### Get Public URL

```python
response = (
    supabase.storage
    .from_("campaign-assets")
    .get_public_url("banners/summer-2024.png")
)
```

### Create Signed URL

```python
response = (
    supabase.storage
    .from_("campaign-assets")
    .create_signed_url(
        "banners/summer-2024.png"
        60  # Valid for 60 seconds
    )
)
```

### Delete Files

```python
response = (
    supabase.storage
    .from_("campaign-assets")
    .remove(["banners/old-banner.png"])
)
```

---

## Production Architecture

### FastAPI Integration Layer

For production, use FastAPI between MCP server and Supabase:

```python
from fastapi import FastAPI, HTTPException, Depends, Header
from supabase import create_client, Client
from typing import Optional
import os

app = FastAPI()

def get_supabase_client() -> Client:
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")  # Use service role key
    return create_client(url, key)

def verify_api_key(x_api_key: str = Header(...)) -> bool:
    # Implement your API key verification
    if x_api_key != os.environ.get("MCP_API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API key")
    return True

@app.post("/campaigns")
async def create_campaign(
    campaign_data: dict
    supabase: Client = Depends(get_supabase_client)
    verified: bool = Depends(verify_api_key)
):
    try:
        response = supabase.table("campaigns").insert(campaign_data).execute()
        return {"success": True, "data": response.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/campaigns/{campaign_id}")
async def get_campaign(
    campaign_id: int
    supabase: Client = Depends(get_supabase_client)
    verified: bool = Depends(verify_api_key)
):
    try:
        response = (
            supabase.table("campaigns")
            .select("*")
            .eq("id", campaign_id)
            .single()
            .execute()
        )
        return {"success": True, "data": response.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

### MCP Server Integration

```python
from fastmcp import FastMCP
import httpx

mcp = FastMCP("Marketing Automation")

@mcp.tool()
async def create_campaign(name: str, campaign_type: str, budget: float) -> dict:
    """Create a new marketing campaign"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://your-fastapi-server.com/campaigns"
            headers={"X-API-Key": os.environ.get("MCP_API_KEY")}
            json={
                "name": name
                "campaign_type": campaign_type
                "budget": budget
            }
        )
        return response.json()

@mcp.tool()
async def get_campaign(campaign_id: int) -> dict:
    """Get campaign details"""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"https://your-fastapi-server.com/campaigns/{campaign_id}"
            headers={"X-API-Key": os.environ.get("MCP_API_KEY")}
        )
        return response.json()
```

### Caching Layer

```python
from redis import asyncio as aioredis
import json
from typing import Optional

class CacheManager:
    def __init__(self, redis_url: str):
        self.redis = aioredis.from_url(redis_url)
    
    async def get(self, key: str) -> Optional[dict]:
        """Get cached value"""
        value = await self.redis.get(key)
        if value:
            return json.loads(value)
        return None
    
    async def set(self, key: str, value: dict, ttl: int = 3600):
        """Set cached value with TTL"""
        await self.redis.setex(
            key
            ttl
            json.dumps(value)
        )
    
    async def delete(self, key: str):
        """Delete cached value"""
        await self.redis.delete(key)

# Usage
cache = CacheManager("redis://localhost:6379")

async def get_campaign_with_cache(campaign_id: int, supabase: Client):
    # Try cache first
    cache_key = f"campaign:{campaign_id}"
    cached = await cache.get(cache_key)
    if cached:
        return cached
    
    # Fetch from database
    response = (
        supabase.table("campaigns")
        .select("*")
        .eq("id", campaign_id)
        .single()
        .execute()
    )
    
    # Cache result
    await cache.set(cache_key, response.data, ttl=3600)
    return response.data
```

---

## Performance Considerations

### Real-Time Subscriptions

1. **Single-threaded Processing**: Postgres Changes are processed on a single thread to maintain order. Compute upgrades don't significantly improve throughput.

2. **RLS Overhead**: Every change event must be checked against RLS policies. If 100 users subscribe to a table with 1 insert, that's 100 reads.

3. **Optimization Strategies**:
   - Use separate "public" tables without RLS for broadcast scenarios
   - Use server-side Realtime only, then re-stream via Broadcast
   - Implement custom authorization logic in FastAPI layer

### Database Queries

1. **Use Indexes**: Ensure proper indexes on frequently queried columns:
   ```sql
   CREATE INDEX idx_campaigns_type ON campaigns(campaign_type);
   CREATE INDEX idx_campaigns_status ON campaigns(status);
   ```

2. **Limit Result Sets**: Always use `.limit()` to prevent large payloads:
   ```python
   response = supabase.table("campaigns").select("*").limit(50).execute()
   ```

3. **Pagination**: Use `range()` for pagination:
   ```python
   response = (
       supabase.table("campaigns")
       .select("*")
       .range(0, 9)  # First 10 records
       .execute()
   )
   ```

### Connection Pooling

For production, use connection pooling:

```python
from supabase import create_client, Client
from supabase.lib.client_options import ClientOptions

supabase: Client = create_client(
    url
    key
    options=ClientOptions(
        postgrest_client_timeout=10
        storage_client_timeout=10
        auto_refresh_token=True
        persist_session=True
    )
)
```

---

## Complete Example: Marketing Automation Integration

```python
import asyncio
from supabase import acreate_client, AsyncClient
from typing import List, Dict, Optional
import os

class MarketingAutomationDB:
    def __init__(self):
        self.supabase: Optional[AsyncClient] = None
    
    async def initialize(self):
        """Initialize Supabase client"""
        url = os.environ.get("SUPABASE_URL")
        key = os.environ.get("SUPABASE_KEY")
        self.supabase = await acreate_client(url, key)
    
    async def create_campaign(self, campaign_data: dict) -> dict:
        """Create new campaign"""
        response = await self.supabase.table("campaigns").insert(campaign_data).execute()
        return response.data[0]
    
    async def get_campaigns(self, campaign_type: Optional[str] = None) -> List[dict]:
        """Get campaigns with optional filtering"""
        query = self.supabase.table("campaigns").select("*")
        
        if campaign_type:
            query = query.eq("campaign_type", campaign_type)
        
        response = await query.execute()
        return response.data
    
    async def update_campaign_status(self, campaign_id: int, status: str) -> dict:
        """Update campaign status"""
        response = await (
            self.supabase.table("campaigns")
            .update({"status": status})
            .eq("id", campaign_id)
            .execute()
        )
        return response.data[0]
    
    async def subscribe_to_campaign_changes(self, callback):
        """Subscribe to real-time campaign changes"""
        channel = self.supabase.channel("campaign-updates")
        await channel.on_postgres_changes(
            event="*"
            schema="public"
            table="campaigns"
            callback=callback
        ).subscribe()
    
    async def store_content_asset(self, file_path: str, asset_data: dict) -> dict:
        """Store content asset with metadata"""
        # Upload file to storage
        with open(file_path, "rb") as f:
            storage_response = await (
                self.supabase.storage
                .from_("campaign-assets")
                .upload(
                    file=f
                    path=f"assets/{asset_data['filename']}"
                    file_options={"cache-control": "3600"}
                )
            )
        
        # Store metadata in database
        asset_data["storage_path"] = storage_response.path
        db_response = await self.supabase.table("content_assets").insert(asset_data).execute()
        return db_response.data[0]

# Usage
async def main():
    db = MarketingAutomationDB()
    await db.initialize()
    
    # Create campaign
    campaign = await db.create_campaign({
        "name": "Summer Job Fair 2024"
        "campaign_type": "job_recruitment"
        "budget": 2000.00
        "status": "draft"
    })
    print(f"Created campaign: {campaign}")
    
    # Subscribe to changes
    def handle_changes(payload):
        print(f"Campaign changed: {payload}")
    
    await db.subscribe_to_campaign_changes(handle_changes)
    
    # Keep running
    await asyncio.sleep(3600)

if __name__ == "__main__":
    asyncio.run(main())
```

---

## References

- **Official Supabase Python Docs**: https://supabase.com/docs/reference/python/introduction
- **Realtime Guide**: https://supabase.com/docs/guides/realtime/postgres-changes
- **Supabase Python Client GitHub**: https://github.com/supabase/supabase-py
- **Database Architecture Doc**: See `DATABASE_ARCHITECTURE.md` in this directory
- **MCP Server Guide**: See `MCP_SERVER_GUIDE.md` in this directory
