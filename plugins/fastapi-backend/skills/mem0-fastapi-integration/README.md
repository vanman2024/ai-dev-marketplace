# Mem0 FastAPI Integration Skill

Complete memory layer integration patterns for FastAPI with Mem0, including client setup, memory service patterns, user tracking, conversation persistence, and background task integration.

## Overview

This skill provides comprehensive templates, scripts, and examples for integrating Mem0's AI memory capabilities into FastAPI applications. It supports both hosted Mem0 platform and self-hosted configurations.

## Structure

```
mem0-fastapi-integration/
├── SKILL.md                    # Main skill documentation
├── README.md                   # This file
├── scripts/
│   ├── setup-mem0.sh          # Installation and configuration
│   └── test-memory.sh         # Memory service testing
├── templates/
│   ├── memory_service.py      # Complete MemoryService implementation
│   ├── memory_client.py       # Client configuration examples
│   ├── memory_middleware.py   # Middleware and dependencies
│   └── memory_routes.py       # FastAPI routes for memory ops
└── examples/
    ├── chat_with_memory.py    # Complete chat implementation
    └── user_preferences.py    # User preference management
```

## Quick Start

### 1. Setup Mem0

```bash
cd skills/mem0-fastapi-integration
./scripts/setup-mem0.sh
```

This will:
- Install Mem0 and dependencies
- Create environment template
- Verify installation
- Provide next steps

### 2. Configure Environment

Copy `.env.example` to `.env` and configure:

**Option 1: Hosted Mem0 (Recommended)**
```bash
MEM0_API_KEY=your_mem0_api_key_here
```

**Option 2: Self-Hosted**
```bash
QDRANT_HOST=localhost
QDRANT_PORT=6333
QDRANT_API_KEY=your_qdrant_api_key
OPENAI_API_KEY=your_openai_api_key
```

### 3. Copy Templates to Your Project

```bash
# Copy memory service
cp templates/memory_service.py app/services/

# Copy routes
cp templates/memory_routes.py app/api/routes/

# Copy dependencies
cp templates/memory_middleware.py app/api/
```

### 4. Integrate with FastAPI

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.services.memory_service import MemoryService

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    memory_service = MemoryService(settings)
    app.state.memory_service = memory_service
    yield
    # Shutdown

app = FastAPI(lifespan=lifespan)

# Include memory routes
from app.api.routes import memory
app.include_router(
    memory.router,
    prefix="/api/v1/memory",
    tags=["memory"]
)
```

### 5. Test Memory Service

```bash
# Start your FastAPI server
uvicorn app.main:app --reload

# In another terminal, run tests
./scripts/test-memory.sh
```

## Key Features

### Memory Service
- **Conversation Persistence**: Automatically store chat history
- **Semantic Search**: Find relevant past conversations
- **User Preferences**: Track and retrieve user preferences
- **Memory Summary**: Get comprehensive user memory statistics

### API Endpoints
- `POST /memory/conversation` - Add conversation to memory
- `POST /memory/search` - Search memories
- `GET /memory/summary` - Get memory summary
- `POST /memory/preference` - Add user preference
- `DELETE /memory/user/{user_id}/all` - Clear user memories

### Background Task Integration
- Non-blocking memory storage
- Async memory operations
- Graceful failure handling

## Examples

### Chat with Memory

See `examples/chat_with_memory.py` for a complete chat implementation with:
- Conversation history retrieval
- Context-aware responses
- Session management
- Streaming support

### User Preferences

See `examples/user_preferences.py` for preference management with:
- Preference categorization
- Quick preference setting
- Learning from interactions
- Profile management

## Configuration Options

### Hosted Mem0 Platform
- Fully managed infrastructure
- No setup required
- Automatic scaling
- Higher cost

### Self-Hosted
- Full control over data
- Lower operational cost
- Requires infrastructure (vector DB)
- More configuration

## Supported Vector Databases

- **Qdrant** (Recommended for self-hosted)
- **Pinecone** (Fully managed)
- **Chroma** (Local development)

## Best Practices

1. **Start Simple**: Begin with hosted Mem0, migrate to self-hosted later
2. **Background Tasks**: Use FastAPI background tasks for memory storage
3. **Error Handling**: Implement graceful fallbacks for memory failures
4. **Rate Limiting**: Protect memory endpoints with rate limits
5. **Caching**: Cache frequent memory searches

## Dependencies

```
fastapi>=0.100.0
uvicorn[standard]>=0.24.0
mem0ai>=0.1.0
openai>=1.0.0
qdrant-client>=1.7.0  # If using Qdrant
python-jose[cryptography]>=3.3.0
```

## Documentation

- [Mem0 Documentation](https://docs.mem0.ai)
- [Hosted Platform Quickstart](https://docs.mem0.ai/platform/quickstart)
- [Self-Hosted Setup](https://docs.mem0.ai/open-source/overview)
- [FastAPI with Mem0 Guide](../docs/FASTAPI-VERCEL-AI-MEM0-STACK.md)

## Testing

Run the test script to verify your setup:

```bash
./scripts/test-memory.sh
```

Tests include:
- Add conversation
- Search memories
- Get summary
- Add preferences
- Memory persistence
- Error handling

## Troubleshooting

### Memory service fails to initialize
- Check environment variables are set
- Verify API keys are valid
- Ensure vector database is running (self-hosted)

### Search returns no results
- Verify conversations were stored
- Check user_id matches
- Ensure sufficient wait time after storage

### Background tasks not executing
- Verify FastAPI lifespan is properly configured
- Check logs for task errors
- Ensure memory service is in app state

## Support

For issues or questions:
- Check the main documentation in `SKILL.md`
- Review example implementations
- Consult Mem0 documentation
- Check FastAPI background tasks documentation

## License

This skill is part of the fastapi-backend plugin in the AI Dev Marketplace.
