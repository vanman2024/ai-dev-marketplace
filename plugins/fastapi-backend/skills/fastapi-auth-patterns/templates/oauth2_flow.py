"""
oauth2_flow.py - OAuth2 Password Flow with Scopes (Permission System)

This template demonstrates OAuth2 password flow with fine-grained permissions
using scopes for role-based access control.

Key Features:
- OAuth2 password flow
- Scope-based permissions
- Multiple security levels for different endpoints
- Integration with OpenAPI documentation

Dependencies:
    pip install fastapi python-jose[cryptography] pwdlib[argon2] python-multipart
"""

from datetime import datetime, timedelta, timezone
from typing import Annotated
import os

from fastapi import Depends, FastAPI, HTTPException, Security, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm, SecurityScopes
from jose import JWTError, jwt
from pydantic import BaseModel, ValidationError
from pwdlib import PasswordHash

# Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-here")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

password_hash = PasswordHash.recommended()

# OAuth2 scheme with scopes defined
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="token",
    scopes={
        "me": "Read information about the current user",
        "items": "Read items",
        "items:write": "Create and modify items",
        "admin": "Full administrative access",
    },
)

app = FastAPI()


# ============================================================================
# Models
# ============================================================================

class Token(BaseModel):
    """OAuth2 token response."""
    access_token: str
    token_type: str


class TokenData(BaseModel):
    """Decoded token data with scopes."""
    username: str | None = None
    scopes: list[str] = []


class User(BaseModel):
    """User model."""
    username: str
    email: str | None = None
    full_name: str | None = None
    disabled: bool | None = None
    scopes: list[str] = []


class UserInDB(User):
    """User model with hashed password."""
    hashed_password: str


# ============================================================================
# Mock Database with User Scopes
# ============================================================================

fake_users_db = {
    "johndoe": {
        "username": "johndoe",
        "full_name": "John Doe",
        "email": "johndoe@example.com",
        "hashed_password": "$argon2id$v=19$m=65536,t=3,p=4$z1mLsXZOCSGkdE4pJeScEw$Rw+jl1lCXB7CgPAdFKHl0JxCIGU/4xqnT7u7mJBMv4Y",
        "disabled": False,
        "scopes": ["me", "items"],  # Regular user permissions
    },
    "alice": {
        "username": "alice",
        "full_name": "Alice Admin",
        "email": "alice@example.com",
        "hashed_password": "$argon2id$v=19$m=65536,t=3,p=4$z1mLsXZOCSGkdE4pJeScEw$Rw+jl1lCXB7CgPAdFKHl0JxCIGU/4xqnT7u7mJBMv4Y",
        "disabled": False,
        "scopes": ["me", "items", "items:write", "admin"],  # Admin permissions
    },
}


# ============================================================================
# Utilities
# ============================================================================

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash."""
    return password_hash.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Hash a password."""
    return password_hash.hash(password)


def create_access_token(data: dict, expires_delta: timedelta | None = None):
    """Create JWT access token with scopes."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def get_user(db, username: str):
    """Get user from database."""
    if username in db:
        user_dict = db[username]
        return UserInDB(**user_dict)


def authenticate_user(db, username: str, password: str):
    """Authenticate user credentials."""
    user = get_user(db, username)
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user


# ============================================================================
# Dependencies with Security Scopes
# ============================================================================

async def get_current_user(
    security_scopes: SecurityScopes,
    token: Annotated[str, Depends(oauth2_scheme)]
):
    """
    Extract and validate current user from JWT token.

    Validates that the token contains all required scopes for the operation.

    Args:
        security_scopes: Required scopes for the operation
        token: JWT token from Authorization header

    Returns:
        User object if validation succeeds

    Raises:
        HTTPException: If authentication fails or insufficient permissions
    """
    if security_scopes.scopes:
        authenticate_value = f'Bearer scope="{security_scopes.scope_str}"'
    else:
        authenticate_value = "Bearer"

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": authenticate_value},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception

        token_scopes = payload.get("scopes", [])
        token_data = TokenData(username=username, scopes=token_scopes)

    except (JWTError, ValidationError):
        raise credentials_exception

    user = get_user(fake_users_db, username=token_data.username)
    if user is None:
        raise credentials_exception

    # Validate user has required scopes
    for scope in security_scopes.scopes:
        if scope not in token_data.scopes:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Not enough permissions. Required scope: {scope}",
                headers={"WWW-Authenticate": authenticate_value},
            )

    return user


async def get_current_active_user(
    current_user: Annotated[User, Security(get_current_user, scopes=["me"])],
):
    """Ensure current user is active."""
    if current_user.disabled:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


# ============================================================================
# API Endpoints
# ============================================================================

@app.post("/token")
async def login(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()]
) -> Token:
    """
    OAuth2 token endpoint with scope support.

    The client can request specific scopes during authentication.
    The token will only include scopes the user actually has.

    Usage:
        curl -X POST "http://localhost:8000/token" \\
            -d "username=johndoe&password=secret&scope=me items"
    """
    user = authenticate_user(fake_users_db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Filter requested scopes to only those the user has
    # SECURITY: Never grant scopes the user doesn't have!
    requested_scopes = form_data.scopes
    user_scopes = user.scopes
    granted_scopes = [scope for scope in requested_scopes if scope in user_scopes]

    # If no scopes requested, grant all user scopes
    if not granted_scopes and not requested_scopes:
        granted_scopes = user_scopes

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "scopes": granted_scopes},
        expires_delta=access_token_expires
    )

    return Token(access_token=access_token, token_type="bearer")


@app.get("/users/me", response_model=User)
async def read_users_me(
    current_user: Annotated[User, Depends(get_current_active_user)],
):
    """
    Get current user information.

    Required scope: "me"
    """
    return current_user


@app.get("/users/me/items")
async def read_own_items(
    current_user: Annotated[User, Security(get_current_active_user, scopes=["items"])],
):
    """
    Read items owned by current user.

    Required scope: "items"
    """
    return [
        {"item_id": "Foo", "owner": current_user.username},
        {"item_id": "Bar", "owner": current_user.username},
    ]


@app.post("/items/")
async def create_item(
    item_name: str,
    current_user: Annotated[User, Security(get_current_active_user, scopes=["items:write"])],
):
    """
    Create a new item.

    Required scope: "items:write"
    """
    return {
        "item_name": item_name,
        "owner": current_user.username,
        "created": datetime.now(timezone.utc),
    }


@app.get("/admin/users")
async def list_all_users(
    current_user: Annotated[User, Security(get_current_active_user, scopes=["admin"])],
):
    """
    List all users (admin only).

    Required scope: "admin"
    """
    return [
        {"username": user, "email": data.get("email")}
        for user, data in fake_users_db.items()
    ]


@app.get("/status")
async def get_status(
    current_user: Annotated[User, Security(get_current_user, scopes=[])],
):
    """
    Get API status.

    Requires authentication but no specific scopes.
    Any authenticated user can access this.
    """
    return {
        "status": "online",
        "user": current_user.username,
        "scopes": current_user.scopes,
    }


# ============================================================================
# Run Application
# ============================================================================

if __name__ == "__main__":
    import uvicorn

    print("OAuth2 Scopes available:")
    for scope, description in oauth2_scheme.model.flows.password.scopes.items():
        print(f"  - {scope}: {description}")

    uvicorn.run(app, host="0.0.0.0", port=8000)
