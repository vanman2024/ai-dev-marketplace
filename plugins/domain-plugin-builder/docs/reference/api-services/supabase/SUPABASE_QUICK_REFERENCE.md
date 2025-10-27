# Supabase Quick Reference - Marketing Automation

## Official Documentation Links

### Main Documentation
- **Homepage**: https://supabase.com/docs
- **Python Reference**: https://supabase.com/docs/reference/python/introduction
- **Realtime Overview**: https://supabase.com/docs/guides/realtime
- **Postgres Changes**: https://supabase.com/docs/guides/realtime/postgres-changes
- **Database Guide**: https://supabase.com/docs/guides/database
- **Auth Guide**: https://supabase.com/docs/guides/auth
- **Storage Guide**: https://supabase.com/docs/guides/storage

### Client Libraries
- **JavaScript**: https://supabase.com/docs/reference/javascript/introduction
- **Python**: https://supabase.com/docs/reference/python/introduction
- **Dart/Flutter**: https://supabase.com/docs/reference/dart/introduction
- **Swift**: https://supabase.com/docs/reference/swift/introduction
- **Kotlin**: https://supabase.com/docs/reference/kotlin/introduction
- **C#**: https://supabase.com/docs/reference/csharp/introduction

### GitHub Repositories
- **Supabase Main**: https://github.com/supabase/supabase
- **Python Client**: https://github.com/supabase/supabase-py
- **Realtime Server**: https://github.com/supabase/realtime

### Tools & Resources
- **Dashboard**: https://supabase.com/dashboard
- **Status Page**: https://status.supabase.com/
- **Support**: https://supabase.com/support
- **Changelog**: https://supabase.com/changelog

---

## Quick Start Code Snippets

### Initialize Client

```python
from supabase import create_client, Client
import os

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(url, key)
```

### Async Client (for Realtime)

```python
from supabase import acreate_client, AsyncClient
import asyncio

async def main():
    supabase: AsyncClient = await acreate_client(url, key)
```

---

## Database Operations Cheatsheet

| Operation | Code |
|-----------|------|
| **Select all** | `supabase.table("campaigns").select("*").execute()` |
| **Filter** | `supabase.table("campaigns").select("*").eq("status", "active").execute()` |
| **Insert** | `supabase.table("campaigns").insert({"name": "Campaign"}).execute()` |
| **Update** | `supabase.table("campaigns").update({"status": "active"}).eq("id", 1).execute()` |
| **Delete** | `supabase.table("campaigns").delete().eq("id", 1).execute()` |
| **RPC** | `supabase.rpc("function_name", {"param": "value"}).execute()` |

---

## Realtime Subscription Patterns

### Listen to All Changes

```python
channel = supabase.channel("db-changes")
await channel.on_postgres_changes(
    event="*",
    schema="public",
    table="campaigns",
    callback=lambda payload: print(payload)
).subscribe()
```

### Filter by Event Type

```python
# INSERT only
event="INSERT"

# UPDATE only
event="UPDATE"

# DELETE only
event="DELETE"

# All events
event="*"
```

### Filter by Column Value

```python
await channel.on_postgres_changes(
    event="UPDATE",
    schema="public",
    table="campaigns",
    filter="status=eq.active",  # Only active campaigns
    callback=handle_changes
).subscribe()
```

### Available Filters

- `eq` - Equal to: `filter="id=eq.1"`
- `neq` - Not equal: `filter="status=neq.draft"`
- `lt` - Less than: `filter="budget=lt.5000"`
- `lte` - Less than or equal: `filter="budget=lte.5000"`
- `gt` - Greater than: `filter="budget=gt.1000"`
- `gte` - Greater than or equal: `filter="budget=gte.1000"`
- `in` - In list: `filter="type=in.(job,event)"`

---

## Authentication Quick Reference

```python
# Sign up
supabase.auth.sign_up({"email": "user@example.com", "password": "password"})

# Sign in
supabase.auth.sign_in_with_password({"email": "user@example.com", "password": "password"})

# Get user
user = supabase.auth.get_user()

# Sign out
supabase.auth.sign_out()

# Refresh session
supabase.auth.refresh_session()
```

---

## Storage Quick Reference

```python
# Upload
with open("file.png", "rb") as f:
    supabase.storage.from_("bucket").upload(file=f, path="path/file.png")

# Download
response = supabase.storage.from_("bucket").download("path/file.png")

# Get public URL
url = supabase.storage.from_("bucket").get_public_url("path/file.png")

# Create signed URL (60 seconds)
url = supabase.storage.from_("bucket").create_signed_url("path/file.png", 60)

# Delete
supabase.storage.from_("bucket").remove(["path/file.png"])
```

---

## SQL Reference for Realtime

### Enable Replication

```sql
alter publication supabase_realtime
add table campaigns;
```

### Get Old Records on UPDATE/DELETE

```sql
alter table campaigns replica identity full;
```

### Create Indexes

```sql
CREATE INDEX idx_campaigns_type ON campaigns(campaign_type);
CREATE INDEX idx_campaigns_status ON campaigns(status);
```

---

## Production Architecture Summary

```
┌─────────────────┐
│  Claude Code    │
│   (MCP Client)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   MCP Server    │
│  (FastMCP)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    FastAPI      │
│  (REST Layer)   │
│  + Auth/Rate    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ Supabase Python │────▶│     Redis       │
│     Client      │     │    (Cache)      │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│   PostgreSQL    │
│   (Supabase)    │
│  + Realtime     │
└─────────────────┘
```

---

## Environment Variables

```bash
# Development (SQLite)
DATABASE_PATH=/path/to/marketing_automation.db

# Production (Supabase)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
REDIS_URL=redis://localhost:6379

# API Security
MCP_API_KEY=your-secure-api-key
```

---

## Common Patterns for Marketing Automation

### Campaign Creation with Assets

```python
async def create_campaign_with_assets(campaign_data: dict, asset_files: list):
    # Create campaign
    campaign = await supabase.table("campaigns").insert(campaign_data).execute()
    campaign_id = campaign.data[0]["id"]
    
    # Upload assets
    for file in asset_files:
        # Upload to storage
        with open(file, "rb") as f:
            storage_response = await supabase.storage.from_("campaign-assets").upload(
                file=f,
                path=f"campaigns/{campaign_id}/{os.path.basename(file)}"
            )
        
        # Store metadata
        await supabase.table("content_assets").insert({
            "campaign_id": campaign_id,
            "filename": os.path.basename(file),
            "storage_path": storage_response.path,
            "asset_type": "image"
        }).execute()
    
    return campaign.data[0]
```

### Real-time Campaign Monitoring

```python
async def monitor_campaign_performance(campaign_id: int):
    channel = supabase.channel(f"campaign-{campaign_id}")
    
    # Listen to post updates
    await channel.on_postgres_changes(
        event="*",
        schema="public",
        table="social_posts",
        filter=f"campaign_id=eq.{campaign_id}",
        callback=lambda p: print(f"Post updated: {p}")
    ).subscribe()
    
    # Send periodic updates
    while True:
        await asyncio.sleep(60)
        stats = await get_campaign_stats(campaign_id)
        await channel.send_broadcast("stats-update", stats)
```

### Automated Categorization with Caching

```python
from redis import asyncio as aioredis
import json

redis = aioredis.from_url("redis://localhost:6379")

async def categorize_campaign(campaign_id: int, campaign_text: str):
    # Check cache
    cache_key = f"category:{campaign_id}"
    cached = await redis.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Generate embedding
    embedding = await generate_embedding(campaign_text)
    
    # Find similar campaigns via vector search
    similar = await supabase.rpc("match_campaigns", {
        "query_embedding": embedding,
        "match_threshold": 0.8,
        "match_count": 5
    }).execute()
    
    # Determine category
    category = determine_category(similar.data)
    
    # Cache result (1 hour TTL)
    await redis.setex(cache_key, 3600, json.dumps(category))
    
    # Update database
    await supabase.table("campaigns").update({
        "category_id": category["id"]
    }).eq("id", campaign_id).execute()
    
    return category
```

---

## Performance Best Practices

1. **Always use indexes** on frequently queried columns
2. **Limit result sets** with `.limit()` to prevent large payloads
3. **Use caching** for AI-generated content (embeddings, categories, tags)
4. **Batch operations** when possible (bulk inserts, bulk updates)
5. **Use RLS carefully** - it adds overhead to realtime subscriptions
6. **Monitor connection pools** in production
7. **Use signed URLs** for temporary file access instead of public URLs
8. **Paginate** large result sets with `.range()`

---

## Troubleshooting

### Common Issues

**Issue**: Realtime not working
- **Solution**: Check if table is added to `supabase_realtime` publication
- **Command**: `alter publication supabase_realtime add table your_table;`

**Issue**: Old records not received on UPDATE
- **Solution**: Set replica identity to full
- **Command**: `alter table your_table replica identity full;`

**Issue**: RLS blocking subscriptions
- **Solution**: Check RLS policies allow SELECT for subscribed user
- **Command**: Grant appropriate permissions in RLS policies

**Issue**: Slow queries
- **Solution**: Add indexes on filtered columns
- **Command**: `CREATE INDEX idx_name ON table(column);`

**Issue**: Connection timeouts
- **Solution**: Adjust client timeout settings
- **Code**: Pass `postgrest_client_timeout` in `ClientOptions`

---

## Next Steps

1. ✅ Review `SUPABASE_INTEGRATION_GUIDE.md` for detailed examples
2. ✅ Check `DATABASE_ARCHITECTURE.md` for schema design
3. ✅ Read `MCP_SERVER_GUIDE.md` for architecture patterns
4. 🔲 Implement FastAPI REST layer
5. 🔲 Set up Redis caching
6. 🔲 Configure Supabase project
7. 🔲 Create database tables
8. 🔲 Enable realtime replication
9. 🔲 Test realtime subscriptions
10. 🔲 Deploy to production

---

## Support & Resources

- **Supabase Discord**: https://discord.supabase.com/
- **GitHub Issues**: https://github.com/supabase/supabase/issues
- **Stack Overflow**: Tag with `supabase`
- **Twitter**: @supabase
- **Support Form**: https://supabase.com/support
