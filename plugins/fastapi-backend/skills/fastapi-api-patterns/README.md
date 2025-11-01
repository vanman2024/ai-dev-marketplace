# fastapi-api-patterns

REST API design and implementation patterns for FastAPI endpoints including CRUD operations, pagination, filtering, error handling, and request/response models.

## Overview

This skill provides comprehensive patterns and templates for building production-ready REST APIs with FastAPI. It covers all essential aspects of API design from basic CRUD operations to advanced pagination, filtering, error handling, and OpenAPI documentation.

## What's Included

### 📝 SKILL.md
Complete guide covering:
- CRUD endpoint patterns
- Pagination strategies (offset, cursor, page-based)
- Filtering and sorting patterns
- Request/response model design
- Error handling and custom exceptions
- Dependency injection patterns
- API router organization
- OpenAPI documentation enhancement

### 🔧 Scripts
- **validate-endpoints.sh** - Validates endpoint structure and best practices
- **generate-openapi-docs.sh** - Generates enhanced OpenAPI documentation

### 📋 Templates
- **crud_endpoint.py** - Complete CRUD endpoint template
- **pagination.py** - Pagination utilities and patterns
- **error_handling.py** - Error handling utilities and custom exceptions

### 💡 Examples
- **chat_api.py** - Chat message API with full CRUD and search
- **user_management.py** - User management with authentication patterns
- **memory_endpoints.py** - AI context/memory management endpoints

## Quick Start

### 1. Create CRUD Endpoints

```bash
# Copy CRUD template
cp ./skills/fastapi-api-patterns/templates/crud_endpoint.py app/routers/items.py

# Customize for your model
# - Update Item model
# - Add database operations
# - Configure authentication
```

### 2. Add Pagination

```bash
# Copy pagination utilities
cp ./skills/fastapi-api-patterns/templates/pagination.py app/utils/pagination.py

# Use in your endpoints
from app.utils.pagination import PaginatedResponse
```

### 3. Implement Error Handling

```bash
# Copy error handling utilities
cp ./skills/fastapi-api-patterns/templates/error_handling.py app/utils/errors.py

# Register exception handlers in main.py
```

### 4. Validate Your API

```bash
# Check endpoint best practices
bash ./skills/fastapi-api-patterns/scripts/validate-endpoints.sh app/routers/items.py
```

## Use Cases

### Building New APIs
- Start with CRUD template for standard resources
- Add pagination for list endpoints
- Implement error handling from templates
- Document with OpenAPI patterns

### Improving Existing APIs
- Add pagination to unbounded list endpoints
- Standardize error responses
- Enhance OpenAPI documentation
- Implement filtering and sorting

### Learning Best Practices
- Study examples for patterns
- Understand Pydantic model organization
- Learn dependency injection
- Master error handling strategies

## Key Patterns

### CRUD Operations
```python
POST   /items/           # Create
GET    /items/{id}       # Read single
GET    /items/           # Read list
PUT    /items/{id}       # Update (full)
PATCH  /items/{id}       # Update (partial)
DELETE /items/{id}       # Delete
```

### Pagination
```python
# Offset-based
GET /items/?skip=0&limit=10

# Cursor-based
GET /items/?cursor=abc123&limit=10

# Page-based
GET /items/?page=1&page_size=10
```

### Filtering
```python
GET /items/?category=books&min_price=10&max_price=50&search=python
```

### Error Responses
```json
{
  "error": "not_found",
  "message": "Item with id 123 not found",
  "details": {"item_id": 123}
}
```

## Requirements

- **FastAPI**: 0.100+
- **Pydantic**: 2.0+
- **Python**: 3.10+

Optional:
- SQLAlchemy (database)
- python-jose (JWT auth)
- passlib (password hashing)

## File Structure

```
skills/fastapi-api-patterns/
├── SKILL.md                      # Complete guide
├── README.md                     # This file
├── scripts/
│   ├── validate-endpoints.sh     # Endpoint validation
│   └── generate-openapi-docs.sh  # OpenAPI generation
├── templates/
│   ├── crud_endpoint.py          # CRUD template
│   ├── pagination.py             # Pagination utilities
│   └── error_handling.py         # Error handling
└── examples/
    ├── chat_api.py               # Chat API example
    ├── user_management.py        # User management
    └── memory_endpoints.py       # AI memory endpoints
```

## Best Practices Enforced

✅ **Type Safety**: Pydantic models for all requests/responses
✅ **Validation**: Automatic validation with detailed errors
✅ **Documentation**: OpenAPI generation with examples
✅ **Error Handling**: Consistent HTTP error responses
✅ **Pagination**: Never return unbounded lists
✅ **Modularity**: APIRouter for organized code
✅ **Dependencies**: Reusable logic via dependency injection

## Related Skills

- **fastapi-auth-patterns** - Authentication and authorization
- **fastapi-database-integration** - Database patterns
- **fastapi-testing-patterns** - Testing strategies

## Support

For issues or questions about this skill:
1. Check SKILL.md for detailed patterns
2. Review examples for reference implementations
3. Run validation scripts to identify issues
4. Consult FastAPI documentation: https://fastapi.tiangolo.com

## Version

**1.0.0** - Initial release with comprehensive REST API patterns

---

**Plugin:** fastapi-backend
**Category:** API Development
**Skill Type:** REST API Patterns
