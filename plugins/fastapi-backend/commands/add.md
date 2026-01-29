---
description: Add a specific feature to an existing FastAPI project. Features include endpoint, auth, database, model, middleware, deploy.
argument-hint: <feature> [options]
---

# Add FastAPI Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2` `$3`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### API Features

**If `$0` = "endpoint":**

```
Task(endpoint-generator-agent) Add API ENDPOINT.

Requirements:
- Endpoint name: $1 (required)
- HTTP method: $2 (get, post, put, delete, crud - default: crud)
- Create route handler
- Add request/response models
- Implement business logic
- Add documentation
```

**If `$0` = "model":**

```
Task(database-architect-agent) Add DATABASE MODEL.

Requirements:
- Model name: $1 (required)
- Fields: $2 (optional field definitions)
- Create SQLAlchemy/SQLModel
- Add relationships
- Generate migration
- Create CRUD operations
```

### Auth Features

**If `$0` = "auth":**

```
Task(endpoint-generator-agent) Add AUTHENTICATION.

Requirements:
- Auth type: $1 (jwt, oauth, api-key, clerk - default: jwt)
- Configure auth scheme
- Create auth routes
- Add password handling
- Set up token generation
```

### Database Features

**If `$0` = "database":**

```
Task(database-architect-agent) Set up DATABASE.

Requirements:
- Database type: $1 (postgres, sqlite, mysql - default: postgres)
- ORM: $2 (sqlalchemy, sqlmodel - default: sqlmodel)
- Configure connection
- Set up session management
- Create base model
- Configure migrations
```

### Middleware Features

**If `$0` = "middleware":**

```
Task(fastapi-setup-agent) Add MIDDLEWARE.

Requirements:
- Middleware type: $1 (cors, logging, ratelimit, timing - required)
- Configure middleware
- Add to application
- Set parameters
```

### Deployment Features

**If `$0` = "deploy":**

```
Task(deployment-architect-agent) Add DEPLOYMENT config.

Requirements:
- Platform: $1 (docker, railway, render, aws - default: docker)
- Create deployment files
- Configure environment
- Set up health checks
- Add monitoring
```

---

## Usage Examples

```bash
# API endpoints
/fastapi-backend:add endpoint users crud
/fastapi-backend:add endpoint health get
/fastapi-backend:add endpoint products post

# Database
/fastapi-backend:add model User
/fastapi-backend:add database postgres sqlalchemy

# Auth
/fastapi-backend:add auth jwt
/fastapi-backend:add auth clerk

# Middleware
/fastapi-backend:add middleware cors
/fastapi-backend:add middleware ratelimit

# Deployment
/fastapi-backend:add deploy docker
/fastapi-backend:add deploy railway
```

---

## Feature Reference

| Feature      | Agent                | $1 Options                    | Description       |
| ------------ | -------------------- | ----------------------------- | ----------------- |
| `endpoint`   | endpoint-generator   | endpoint-name (required)      | API endpoint      |
| `model`      | database-architect   | model-name (required)         | Database model    |
| `auth`       | endpoint-generator   | jwt/oauth/api-key/clerk       | Authentication    |
| `database`   | database-architect   | postgres/sqlite/mysql         | Database setup    |
| `middleware` | fastapi-setup        | cors/logging/ratelimit/timing | Middleware        |
| `deploy`     | deployment-architect | docker/railway/render/aws     | Deployment config |
