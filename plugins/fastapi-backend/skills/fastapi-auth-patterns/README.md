# FastAPI Authentication Patterns Skill

Complete authentication and authorization patterns for FastAPI applications.

## Overview

This skill provides production-ready authentication implementations for FastAPI, including JWT tokens, OAuth2 flows, permission systems, and Supabase integration. It autonomously implements, validates, and debugs authentication systems based on your requirements.

## What This Skill Does

The `fastapi-auth-patterns` skill:

- **Implements JWT Authentication** - Complete token-based auth with secure password hashing
- **Configures OAuth2 Flows** - Password flow with scopes for fine-grained permissions
- **Integrates Supabase** - Managed authentication with OAuth providers
- **Validates Configurations** - Checks environment setup, packages, and security
- **Creates Permission Systems** - Role-based and scope-based access control
- **Protects Endpoints** - Multiple patterns for securing routes

## When to Use This Skill

Claude will automatically activate this skill when you:

- Implement user authentication in FastAPI
- Secure API endpoints with JWT tokens
- Configure OAuth2 flows
- Set up permission systems
- Integrate Supabase authentication
- Debug authentication errors (401, 403)
- Manage user roles and permissions

## Quick Start

### 1. Setup JWT Authentication

```bash
# Run the setup script
./scripts/setup-jwt.sh

# This will:
# - Install required packages (fastapi, python-jose, pwdlib)
# - Generate a secure SECRET_KEY
# - Create .env file with configuration
# - Set up authentication directory structure
# - Create auth models, dependencies, and utilities
```

### 2. Validate Configuration

```bash
# Validate your authentication setup
./scripts/validate-auth.sh

# Checks:
# - Required packages installed
# - Environment variables configured
# - Security settings (SECRET_KEY length, .gitignore)
# - Authentication files and functions present
```

### 3. Use Templates

Copy the appropriate template to your project:

```bash
# JWT authentication
cp templates/jwt_auth.py app/main.py

# OAuth2 with scopes
cp templates/oauth2_flow.py app/main.py

# Supabase integration
cp templates/supabase_auth.py app/main.py
```

## Directory Structure

```
fastapi-auth-patterns/
├── SKILL.md                      # Skill definition and patterns
├── README.md                     # This file
├── scripts/
│   ├── setup-jwt.sh             # Initialize JWT authentication
│   └── validate-auth.sh         # Validate configuration
├── templates/
│   ├── jwt_auth.py              # Complete JWT implementation
│   ├── oauth2_flow.py           # OAuth2 password flow with scopes
│   └── supabase_auth.py         # Supabase integration
└── examples/
    ├── protected_routes.py      # Protected endpoint patterns
    └── permission_system.py     # RBAC and permission system
```

## Authentication Strategies

### 1. JWT Token Authentication

**Best for:** Stateless APIs, mobile apps, microservices

```python
# Token generation
access_token = create_access_token(
    data={"sub": username},
    expires_delta=timedelta(minutes=30)
)

# Protected endpoint
@app.get("/users/me")
async def read_users_me(
    current_user: User = Depends(get_current_active_user)
):
    return current_user
```

**Features:**
- Argon2 password hashing (recommended by OWASP)
- JWT token generation and validation
- Configurable token expiration
- Secure secret key management

### 2. OAuth2 Password Flow

**Best for:** First-party applications, standard OAuth2 compliance

```python
# Login endpoint
@app.post("/token")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(form_data.username, form_data.password)
    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}
```

**Features:**
- OAuth2 standard compliance
- OpenAPI documentation integration
- Form-based authentication
- Bearer token scheme

### 3. OAuth2 Scopes (Permissions)

**Best for:** Fine-grained access control, multi-tenant systems

```python
# Define scopes
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="token",
    scopes={
        "items:read": "Read items",
        "items:write": "Create and modify items"
    }
)

# Protected with scope
@app.post("/items/")
async def create_item(
    current_user: User = Security(get_current_user, scopes=["items:write"])
):
    return create_item_for_user(current_user)
```

**Features:**
- Fine-grained permissions
- Scope-based authorization
- Hierarchical permission model
- Client-requested scope filtering

### 4. Supabase Authentication

**Best for:** Managed auth, OAuth providers (Google, GitHub), user dashboards

```python
# Initialize Supabase
supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)

# Signup
response = supabase.auth.sign_up({
    "email": "user@example.com",
    "password": "secure_password"
})

# Validate token
user = supabase.auth.get_user(token)
```

**Features:**
- Managed authentication service
- Built-in OAuth providers
- User management dashboard
- Row-level security (RLS)

## Protected Route Patterns

See `examples/protected_routes.py` for complete examples:

1. **Public Routes** - No authentication required
2. **Basic Auth** - Requires valid token
3. **Admin-Only** - Requires admin role
4. **Scope-Based** - Requires specific permissions
5. **Resource Owner** - Requires ownership validation
6. **Optional Auth** - Different behavior based on auth status
7. **Combined Auth** - Multiple authorization checks
8. **Rate Limited** - Authentication + rate limiting

## Permission System

See `examples/permission_system.py` for complete implementation:

**Role-Based Access Control (RBAC):**

```python
class Role(str, Enum):
    SUPER_ADMIN = "super_admin"
    ADMIN = "admin"
    MANAGER = "manager"
    USER = "user"
    GUEST = "guest"

# Require specific role
@app.get("/admin/users")
async def list_users(
    admin: User = Depends(require_role(Role.ADMIN))
):
    return get_all_users()
```

**Permission-Based Access:**

```python
class Permission(str, Enum):
    USER_READ = "user:read"
    USER_WRITE = "user:write"
    USER_DELETE = "user:delete"

# Require specific permission
@app.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: User = Depends(require_permission(Permission.USER_DELETE))
):
    return delete_user_by_id(user_id)
```

## Configuration

### Environment Variables

```bash
# JWT Configuration
SECRET_KEY=your_secret_key_here  # Generate with: openssl rand -hex 32
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Supabase Configuration (if using Supabase)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_anon_key
```

### Required Packages

```bash
pip install fastapi
pip install python-jose[cryptography]
pip install pwdlib[argon2]
pip install python-multipart

# For Supabase
pip install supabase python-dotenv
```

## Security Best Practices

1. **Password Hashing**
   - Use Argon2 (recommended by OWASP)
   - Never store passwords in plaintext
   - Use `pwdlib.PasswordHash.recommended()`

2. **Secret Key Management**
   - Generate with: `openssl rand -hex 32`
   - Store in environment variables
   - Never commit to version control
   - Add `.env` to `.gitignore`

3. **Token Expiration**
   - Short access tokens (15-30 minutes)
   - Long refresh tokens (7-30 days)
   - Implement token rotation
   - Add token revocation for logout

4. **HTTPS Required**
   - Always use HTTPS in production
   - Tokens are vulnerable over HTTP
   - Configure reverse proxy (nginx, Caddy)

5. **Rate Limiting**
   - Limit login attempts
   - Prevent brute force attacks
   - Use libraries like `slowapi`

## Common Issues & Solutions

### Missing SECRET_KEY

```bash
# Generate secure key
openssl rand -hex 32

# Add to .env
echo 'SECRET_KEY=generated_key' >> .env
```

### Token Expired (401)

- Increase `ACCESS_TOKEN_EXPIRE_MINUTES`
- Implement refresh token pattern
- Check server/client time synchronization

### Invalid Credentials

- Verify password hashing algorithm
- Check user exists in database
- Validate password comparison logic

### Missing Permissions (403)

- Verify user has required scopes
- Check scope encoding in token
- Validate `SecurityScopes` configuration

### Supabase Connection Failed

- Verify `SUPABASE_URL` and `SUPABASE_KEY`
- Check project settings in dashboard
- Validate network connectivity

## Validation

The skill includes comprehensive validation:

```bash
./scripts/validate-auth.sh

# Checks:
✅ Required packages installed
✅ Environment variables configured
✅ SECRET_KEY length and format
✅ .env in .gitignore
✅ Authentication files present
✅ OAuth2 scheme configured
✅ Token and password utilities
```

## Testing

Example test patterns:

```python
def test_login():
    response = client.post("/token", data={
        "username": "testuser",
        "password": "testpass"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_protected_route():
    # Without token
    response = client.get("/users/me")
    assert response.status_code == 401

    # With token
    token = get_test_token()
    response = client.get("/users/me", headers={
        "Authorization": f"Bearer {token}"
    })
    assert response.status_code == 200
```

## Integration with Other Skills

This skill works well with:

- **fastapi-database-patterns** - User storage and queries
- **fastapi-deployment-config** - Production deployment
- **fastapi-testing-patterns** - Authentication testing
- **fastapi-middleware-patterns** - CORS and security headers

## Resources

**Documentation:**
- FastAPI Security: https://fastapi.tiangolo.com/tutorial/security/
- OAuth2 Scopes: https://fastapi.tiangolo.com/advanced/security/oauth2-scopes/
- Supabase Auth: https://supabase.com/docs/guides/auth

**Files in This Skill:**
- `SKILL.md` - Complete authentication patterns and workflows
- `scripts/setup-jwt.sh` - Automated JWT setup
- `scripts/validate-auth.sh` - Configuration validation
- `templates/jwt_auth.py` - Production-ready JWT implementation
- `templates/oauth2_flow.py` - OAuth2 with scopes
- `templates/supabase_auth.py` - Supabase integration
- `examples/protected_routes.py` - 8 protection patterns
- `examples/permission_system.py` - Complete RBAC system

## Version

- **Version:** 1.0.0
- **FastAPI Compatibility:** 0.100+
- **Python:** 3.10+

## License

Part of the fastapi-backend plugin in the ai-dev-marketplace.

---

**Need help?** Claude will automatically use this skill when you mention authentication, JWT, OAuth2, Supabase, or permissions in your FastAPI project.
