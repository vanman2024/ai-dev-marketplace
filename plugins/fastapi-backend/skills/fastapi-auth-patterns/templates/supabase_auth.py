"""
supabase_auth.py - Supabase Authentication Integration for FastAPI

This template demonstrates how to integrate Supabase authentication with FastAPI,
including user signup, login, session management, and protected routes.

Key Features:
- Supabase authentication integration
- User signup and login
- JWT token validation
- Session management
- Protected endpoints with Supabase RLS

Dependencies:
    pip install fastapi supabase python-dotenv uvicorn
"""

from typing import Annotated
import os

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")  # Use anon key for client-side auth

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("SUPABASE_URL and SUPABASE_KEY must be set in environment variables")

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Security scheme
security = HTTPBearer()

app = FastAPI(title="FastAPI with Supabase Auth")


# ============================================================================
# Models
# ============================================================================

class UserSignup(BaseModel):
    """User signup request."""
    email: EmailStr
    password: str
    full_name: str | None = None
    metadata: dict | None = None


class UserLogin(BaseModel):
    """User login request."""
    email: EmailStr
    password: str


class Token(BaseModel):
    """Authentication token response."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class User(BaseModel):
    """User information."""
    id: str
    email: str
    email_confirmed_at: str | None = None
    created_at: str
    user_metadata: dict = {}


class PasswordReset(BaseModel):
    """Password reset request."""
    email: EmailStr


class PasswordUpdate(BaseModel):
    """Password update request."""
    new_password: str


# ============================================================================
# Dependencies
# ============================================================================

async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)]
) -> User:
    """
    Dependency to extract and validate current user from Supabase JWT token.

    Args:
        credentials: JWT token from Authorization header

    Returns:
        User object from Supabase

    Raises:
        HTTPException: If token is invalid or user not found
    """
    token = credentials.credentials

    try:
        # Get user from Supabase using the access token
        user_response = supabase.auth.get_user(token)

        if not user_response or not user_response.user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )

        user_data = user_response.user
        return User(
            id=user_data.id,
            email=user_data.email,
            email_confirmed_at=user_data.email_confirmed_at,
            created_at=user_data.created_at,
            user_metadata=user_data.user_metadata or {},
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not validate credentials: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


# ============================================================================
# Authentication Endpoints
# ============================================================================

@app.post("/auth/signup", response_model=Token)
async def signup(user_data: UserSignup):
    """
    Register a new user with Supabase.

    If email confirmation is enabled in Supabase, the user will receive
    a confirmation email before they can login.

    Usage:
        curl -X POST "http://localhost:8000/auth/signup" \\
            -H "Content-Type: application/json" \\
            -d '{"email": "user@example.com", "password": "secure_password", "full_name": "John Doe"}'
    """
    try:
        # Prepare user metadata
        options = {}
        if user_data.full_name or user_data.metadata:
            metadata = user_data.metadata or {}
            if user_data.full_name:
                metadata["full_name"] = user_data.full_name
            options["data"] = metadata

        # Sign up user with Supabase
        response = supabase.auth.sign_up({
            "email": user_data.email,
            "password": user_data.password,
            "options": options if options else None,
        })

        if not response.session:
            # Email confirmation required
            return {
                "message": "Signup successful. Please check your email for confirmation.",
                "access_token": "",
                "refresh_token": "",
                "expires_in": 0,
            }

        return Token(
            access_token=response.session.access_token,
            refresh_token=response.session.refresh_token,
            expires_in=response.session.expires_in or 3600,
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Signup failed: {str(e)}"
        )


@app.post("/auth/login", response_model=Token)
async def login(credentials: UserLogin):
    """
    Login with email and password.

    Returns JWT access token and refresh token.

    Usage:
        curl -X POST "http://localhost:8000/auth/login" \\
            -H "Content-Type: application/json" \\
            -d '{"email": "user@example.com", "password": "secure_password"}'
    """
    try:
        response = supabase.auth.sign_in_with_password({
            "email": credentials.email,
            "password": credentials.password,
        })

        if not response.session:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )

        return Token(
            access_token=response.session.access_token,
            refresh_token=response.session.refresh_token,
            expires_in=response.session.expires_in or 3600,
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Login failed: {str(e)}"
        )


@app.post("/auth/logout")
async def logout(current_user: Annotated[User, Depends(get_current_user)]):
    """
    Logout current user.

    Invalidates the current session.

    Requires: Authorization header with Bearer token
    """
    try:
        supabase.auth.sign_out()
        return {"message": "Logged out successfully"}

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Logout failed: {str(e)}"
        )


@app.post("/auth/refresh", response_model=Token)
async def refresh_token(refresh_token: str):
    """
    Refresh access token using refresh token.

    Usage:
        curl -X POST "http://localhost:8000/auth/refresh" \\
            -H "Content-Type: application/json" \\
            -d '{"refresh_token": "your_refresh_token"}'
    """
    try:
        response = supabase.auth.refresh_session(refresh_token)

        if not response.session:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )

        return Token(
            access_token=response.session.access_token,
            refresh_token=response.session.refresh_token,
            expires_in=response.session.expires_in or 3600,
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token refresh failed: {str(e)}"
        )


@app.post("/auth/password-reset")
async def request_password_reset(request: PasswordReset):
    """
    Request password reset email.

    Sends password reset link to user's email.
    """
    try:
        supabase.auth.reset_password_email(request.email)
        return {"message": "Password reset email sent"}

    except Exception as e:
        # Don't reveal if email exists
        return {"message": "If the email exists, a reset link will be sent"}


@app.post("/auth/password-update")
async def update_password(
    password_data: PasswordUpdate,
    current_user: Annotated[User, Depends(get_current_user)]
):
    """
    Update user password.

    Requires: Authorization header with Bearer token
    """
    try:
        supabase.auth.update_user({
            "password": password_data.new_password
        })
        return {"message": "Password updated successfully"}

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Password update failed: {str(e)}"
        )


# ============================================================================
# Protected Endpoints
# ============================================================================

@app.get("/users/me", response_model=User)
async def get_current_user_info(
    current_user: Annotated[User, Depends(get_current_user)]
):
    """
    Get current authenticated user information.

    Protected endpoint - requires valid JWT token.

    Usage:
        curl -X GET "http://localhost:8000/users/me" \\
            -H "Authorization: Bearer <your_token>"
    """
    return current_user


@app.put("/users/me")
async def update_user_metadata(
    metadata: dict,
    current_user: Annotated[User, Depends(get_current_user)]
):
    """
    Update user metadata.

    Usage:
        curl -X PUT "http://localhost:8000/users/me" \\
            -H "Authorization: Bearer <your_token>" \\
            -H "Content-Type: application/json" \\
            -d '{"metadata": {"theme": "dark", "language": "en"}}'
    """
    try:
        response = supabase.auth.update_user({
            "data": metadata
        })

        return {
            "message": "User metadata updated",
            "metadata": response.user.user_metadata
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Update failed: {str(e)}"
        )


@app.get("/protected/data")
async def get_protected_data(
    current_user: Annotated[User, Depends(get_current_user)]
):
    """
    Example protected endpoint.

    Only accessible with valid authentication token.
    """
    return {
        "message": "This is protected data",
        "user_id": current_user.id,
        "accessed_by": current_user.email,
    }


# ============================================================================
# Public Endpoints
# ============================================================================

@app.get("/")
async def root():
    """Public endpoint - no authentication required."""
    return {
        "message": "FastAPI with Supabase Authentication",
        "endpoints": {
            "signup": "/auth/signup",
            "login": "/auth/login",
            "logout": "/auth/logout",
            "refresh": "/auth/refresh",
            "me": "/users/me",
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "supabase": "connected" if SUPABASE_URL else "not configured"
    }


# ============================================================================
# Run Application
# ============================================================================

if __name__ == "__main__":
    import uvicorn

    print(f"Supabase URL: {SUPABASE_URL}")
    print("Starting FastAPI with Supabase Auth...")
    uvicorn.run(app, host="0.0.0.0", port=8000)
