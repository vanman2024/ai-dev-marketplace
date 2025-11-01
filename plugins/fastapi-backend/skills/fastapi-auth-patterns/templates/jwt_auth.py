"""
jwt_auth.py - Complete JWT Authentication Implementation for FastAPI

This template provides a production-ready JWT authentication system.

Usage:
1. Run setup-jwt.sh to initialize the authentication structure
2. Copy this file to your FastAPI project
3. Replace fake_users_db with your database
4. Import and use in main.py

Dependencies:
    pip install fastapi python-jose[cryptography] pwdlib[argon2] python-multipart
"""

from datetime import datetime, timedelta, timezone
from typing import Annotated
import os

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from pydantic import BaseModel
from pwdlib import PasswordHash

# Configuration from environment variables
SECRET_KEY = os.getenv("SECRET_KEY")  # Generate with: openssl rand -hex 32
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))

# Initialize password hasher (Argon2)
password_hash = PasswordHash.recommended()

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

app = FastAPI()

# ============================================================================
# Models
# ============================================================================

class Token(BaseModel):
    """OAuth2 token response."""
    access_token: str
    token_type: str


class TokenData(BaseModel):
    """Decoded token data."""
    username: str | None = None


class User(BaseModel):
    """User model for API responses."""
    username: str
    email: str | None = None
    full_name: str | None = None
    disabled: bool | None = None


class UserInDB(User):
    """User model with hashed password (database)."""
    hashed_password: str


# ============================================================================
# Mock Database - Replace with Real Database
# ============================================================================

# Example hashed password: "secret"
# Generate with: password_hash.hash("secret")
fake_users_db = {
    "johndoe": {
        "username": "johndoe",
        "full_name": "John Doe",
        "email": "johndoe@example.com",
        "hashed_password": "$argon2id$v=19$m=65536,t=3,p=4$z1mLsXZOCSGkdE4pJeScEw$Rw+jl1lCXB7CgPAdFKHl0JxCIGU/4xqnT7u7mJBMv4Y",
        "disabled": False,
    },
    "alice": {
        "username": "alice",
        "full_name": "Alice Wonderland",
        "email": "alice@example.com",
        "hashed_password": "$argon2id$v=19$m=65536,t=3,p=4$z1mLsXZOCSGkdE4pJeScEw$Rw+jl1lCXB7CgPAdFKHl0JxCIGU/4xqnT7u7mJBMv4Y",
        "disabled": True,
    },
}


# ============================================================================
# Password & Token Utilities
# ============================================================================

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return password_hash.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """
    Hash a password using Argon2.

    Example:
        hashed = get_password_hash("my_secure_password")
    """
    return password_hash.hash(password)


def create_access_token(data: dict, expires_delta: timedelta | None = None):
    """
    Create a JWT access token.

    Args:
        data: Dictionary to encode in token (typically {"sub": username})
        expires_delta: Optional expiration time delta

    Returns:
        Encoded JWT token string
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


# ============================================================================
# Database Functions - Replace with Real Database Queries
# ============================================================================

def get_user(db, username: str):
    """Retrieve user from database by username."""
    if username in db:
        user_dict = db[username]
        return UserInDB(**user_dict)


def authenticate_user(fake_db, username: str, password: str):
    """
    Authenticate user with username and password.

    Args:
        fake_db: Database (replace with real database)
        username: User's username
        password: Plain text password

    Returns:
        User object if authentication successful, False otherwise
    """
    user = get_user(fake_db, username)
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user


# ============================================================================
# Dependencies
# ============================================================================

async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)]):
    """
    Dependency to extract and validate current user from JWT token.

    Raises:
        HTTPException: If token is invalid or user not found

    Returns:
        User object
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception

    user = get_user(fake_users_db, username=token_data.username)
    if user is None:
        raise credentials_exception
    return user


async def get_current_active_user(
    current_user: Annotated[User, Depends(get_current_user)],
):
    """
    Dependency to ensure current user is active (not disabled).

    Raises:
        HTTPException: If user is disabled

    Returns:
        Active user object
    """
    if current_user.disabled:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


# ============================================================================
# API Endpoints
# ============================================================================

@app.post("/token")
async def login(form_data: Annotated[OAuth2PasswordRequestForm, Depends()]) -> Token:
    """
    OAuth2 compatible token login endpoint.

    Accepts username and password via form data and returns JWT access token.

    Usage:
        curl -X POST "http://localhost:8000/token" \\
            -d "username=johndoe&password=secret"
    """
    user = authenticate_user(fake_users_db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return Token(access_token=access_token, token_type="bearer")


@app.get("/users/me", response_model=User)
async def read_users_me(
    current_user: Annotated[User, Depends(get_current_active_user)],
):
    """
    Get current authenticated user information.

    Protected endpoint - requires valid JWT token in Authorization header.

    Usage:
        curl -X GET "http://localhost:8000/users/me" \\
            -H "Authorization: Bearer <your_token>"
    """
    return current_user


@app.get("/")
async def root():
    """Public endpoint - no authentication required."""
    return {"message": "Welcome to the API. Login at /token to get access token."}


# ============================================================================
# Example: Creating a new user (for testing)
# ============================================================================

@app.post("/users/register")
async def register_user(username: str, password: str, email: str, full_name: str = None):
    """
    Example user registration endpoint.

    In production, add proper validation and security checks:
    - Email verification
    - Password strength requirements
    - Rate limiting
    - CAPTCHA
    """
    if username in fake_users_db:
        raise HTTPException(status_code=400, detail="Username already registered")

    hashed_password = get_password_hash(password)
    user_dict = {
        "username": username,
        "email": email,
        "full_name": full_name,
        "hashed_password": hashed_password,
        "disabled": False,
    }

    # In production, save to database instead
    fake_users_db[username] = user_dict

    return {"message": "User created successfully"}


# ============================================================================
# Run Application
# ============================================================================

if __name__ == "__main__":
    import uvicorn

    # Check if SECRET_KEY is set
    if not SECRET_KEY:
        print("ERROR: SECRET_KEY environment variable not set!")
        print("Generate one with: openssl rand -hex 32")
        print("Add to .env file: SECRET_KEY=your_generated_key")
        exit(1)

    uvicorn.run(app, host="0.0.0.0", port=8000)
