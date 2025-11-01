"""
User Management API Example

This example demonstrates user management with:
- User registration and authentication
- Profile management
- Role-based access
- Password handling (simulated)
- User listing and filtering
- Account deactivation (soft delete)
"""

from fastapi import APIRouter, HTTPException, Depends, status, Query
from pydantic import BaseModel, Field, EmailStr, validator
from typing import List, Optional
from datetime import datetime
from enum import Enum
import hashlib

# ============================================================================
# MODELS
# ============================================================================

class UserRole(str, Enum):
    """User role enumeration"""
    user = "user"
    moderator = "moderator"
    admin = "admin"


class UserBase(BaseModel):
    """Base user model"""
    email: EmailStr = Field(..., description="User email address")
    username: str = Field(..., min_length=3, max_length=50, description="Username")
    full_name: Optional[str] = Field(None, max_length=100)
    bio: Optional[str] = Field(None, max_length=500)
    role: UserRole = Field(default=UserRole.user)

    @validator('username')
    def username_alphanumeric(cls, v):
        """Validate username is alphanumeric"""
        if not v.replace('_', '').replace('-', '').isalnum():
            raise ValueError('Username must be alphanumeric (- and _ allowed)')
        return v


class UserCreate(UserBase):
    """Model for user registration"""
    password: str = Field(..., min_length=8, description="Password (min 8 characters)")

    @validator('password')
    def password_strength(cls, v):
        """Basic password validation"""
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not any(c.islower() for c in v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain at least one digit')
        return v


class UserUpdate(BaseModel):
    """Model for updating user profile"""
    full_name: Optional[str] = Field(None, max_length=100)
    bio: Optional[str] = Field(None, max_length=500)


class PasswordChange(BaseModel):
    """Model for password change"""
    current_password: str = Field(..., description="Current password")
    new_password: str = Field(..., min_length=8, description="New password")


class UserInDB(UserBase):
    """User model with database fields"""
    id: int
    hashed_password: str
    is_active: bool = True
    is_verified: bool = False
    created_at: datetime
    updated_at: datetime
    last_login: Optional[datetime] = None


class User(BaseModel):
    """Public user model (no sensitive data)"""
    id: int
    email: EmailStr
    username: str
    full_name: Optional[str]
    bio: Optional[str]
    role: UserRole
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class UserProfile(User):
    """Extended user profile with additional info"""
    last_login: Optional[datetime]


class PaginatedUsers(BaseModel):
    """Paginated users response"""
    users: List[User]
    total: int
    page: int
    page_size: int
    pages: int


# ============================================================================
# ROUTER SETUP
# ============================================================================

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "User not found"}},
)


# ============================================================================
# IN-MEMORY DATABASE
# ============================================================================

users_db: dict[int, dict] = {}
email_index: dict[str, int] = {}  # email -> user_id
username_index: dict[str, int] = {}  # username -> user_id
next_user_id = 1


def get_current_time():
    return datetime.utcnow()


def hash_password(password: str) -> str:
    """Hash password (simplified - use proper hashing in production)"""
    return hashlib.sha256(password.encode()).hexdigest()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash"""
    return hash_password(plain_password) == hashed_password


# ============================================================================
# AUTHENTICATION (SIMULATED)
# ============================================================================

async def get_current_user(user_id: int = Query(..., description="Current user ID")) -> dict:
    """
    Simulated authentication dependency.
    In production, this would validate JWT token and return user.
    """
    if user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )

    user = users_db[user_id]

    if not user["is_active"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated"
        )

    return user


async def get_current_admin(
    current_user: dict = Depends(get_current_user)
) -> dict:
    """Require admin role"""
    if current_user["role"] != UserRole.admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


# ============================================================================
# ENDPOINTS
# ============================================================================

@router.post(
    "/register",
    response_model=User,
    status_code=status.HTTP_201_CREATED,
    summary="Register new user",
)
async def register_user(user: UserCreate):
    """
    Register a new user account.

    - **email**: Valid email address (must be unique)
    - **username**: Username (3-50 chars, alphanumeric, must be unique)
    - **password**: Strong password (min 8 chars, uppercase, lowercase, digit)
    - **full_name**: Optional full name
    - **bio**: Optional biography
    """
    global next_user_id

    # Check if email already exists
    if user.email.lower() in email_index:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Email '{user.email}' already registered"
        )

    # Check if username already exists
    if user.username.lower() in username_index:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Username '{user.username}' already taken"
        )

    # Create user
    current_time = get_current_time()
    user_data = user.model_dump(exclude={'password'})
    user_data.update({
        "id": next_user_id,
        "hashed_password": hash_password(user.password),
        "is_active": True,
        "is_verified": False,
        "created_at": current_time,
        "updated_at": current_time,
        "last_login": None,
    })

    users_db[next_user_id] = user_data
    email_index[user.email.lower()] = next_user_id
    username_index[user.username.lower()] = next_user_id
    next_user_id += 1

    return User(**user_data)


@router.get(
    "/me",
    response_model=UserProfile,
    summary="Get current user profile",
)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    """Get the authenticated user's profile"""
    return UserProfile(**current_user)


@router.patch(
    "/me",
    response_model=User,
    summary="Update current user profile",
)
async def update_my_profile(
    update: UserUpdate,
    current_user: dict = Depends(get_current_user)
):
    """Update the authenticated user's profile"""
    user_id = current_user["id"]

    # Update fields
    update_data = update.model_dump(exclude_unset=True)
    users_db[user_id].update(update_data)
    users_db[user_id]["updated_at"] = get_current_time()

    return User(**users_db[user_id])


@router.post(
    "/me/change-password",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Change password",
)
async def change_password(
    password_change: PasswordChange,
    current_user: dict = Depends(get_current_user)
):
    """Change the authenticated user's password"""
    # Verify current password
    if not verify_password(password_change.current_password, current_user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )

    # Update password
    user_id = current_user["id"]
    users_db[user_id]["hashed_password"] = hash_password(password_change.new_password)
    users_db[user_id]["updated_at"] = get_current_time()


@router.get(
    "/{user_id}",
    response_model=User,
    summary="Get user by ID",
)
async def get_user(user_id: int):
    """Get a user's public profile by ID"""
    if user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with id {user_id} not found"
        )

    user = users_db[user_id]

    if not user["is_active"]:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return User(**user)


@router.get(
    "/",
    response_model=PaginatedUsers,
    summary="List users",
)
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    role: Optional[UserRole] = Query(None, description="Filter by role"),
    is_verified: Optional[bool] = Query(None, description="Filter by verification status"),
    search: Optional[str] = Query(None, description="Search in username and full name"),
):
    """
    List users with filtering and pagination.

    Filters:
    - **role**: Filter by user role
    - **is_verified**: Filter by verification status
    - **search**: Search in username and full name
    """
    # Start with active users
    filtered_users = [u for u in users_db.values() if u["is_active"]]

    # Apply filters
    if role:
        filtered_users = [u for u in filtered_users if u["role"] == role]

    if is_verified is not None:
        filtered_users = [u for u in filtered_users if u["is_verified"] == is_verified]

    if search:
        search_lower = search.lower()
        filtered_users = [
            u for u in filtered_users
            if (search_lower in u["username"].lower() or
                (u["full_name"] and search_lower in u["full_name"].lower()))
        ]

    # Sort by creation time (newest first)
    filtered_users.sort(key=lambda u: u["created_at"], reverse=True)

    # Paginate
    total = len(filtered_users)
    pages = (total + page_size - 1) // page_size if total > 0 else 0
    skip = (page - 1) * page_size
    paginated = filtered_users[skip : skip + page_size]

    return PaginatedUsers(
        users=[User(**u) for u in paginated],
        total=total,
        page=page,
        page_size=page_size,
        pages=pages,
    )


@router.get(
    "/username/{username}",
    response_model=User,
    summary="Get user by username",
)
async def get_user_by_username(username: str):
    """Get a user by username"""
    user_id = username_index.get(username.lower())

    if not user_id or user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User '{username}' not found"
        )

    user = users_db[user_id]

    if not user["is_active"]:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return User(**user)


@router.delete(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Deactivate account",
)
async def deactivate_account(
    current_user: dict = Depends(get_current_user)
):
    """Deactivate the authenticated user's account (soft delete)"""
    user_id = current_user["id"]
    users_db[user_id]["is_active"] = False
    users_db[user_id]["updated_at"] = get_current_time()


# ============================================================================
# ADMIN ENDPOINTS
# ============================================================================

@router.patch(
    "/{user_id}/role",
    response_model=User,
    summary="Update user role (admin only)",
)
async def update_user_role(
    user_id: int,
    role: UserRole,
    admin: dict = Depends(get_current_admin)
):
    """Update a user's role (admin only)"""
    if user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with id {user_id} not found"
        )

    users_db[user_id]["role"] = role
    users_db[user_id]["updated_at"] = get_current_time()

    return User(**users_db[user_id])


@router.post(
    "/{user_id}/verify",
    response_model=User,
    summary="Verify user account (admin only)",
)
async def verify_user(
    user_id: int,
    admin: dict = Depends(get_current_admin)
):
    """Verify a user's account (admin only)"""
    if user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with id {user_id} not found"
        )

    users_db[user_id]["is_verified"] = True
    users_db[user_id]["updated_at"] = get_current_time()

    return User(**users_db[user_id])


@router.delete(
    "/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Deactivate user (admin only)",
)
async def deactivate_user(
    user_id: int,
    admin: dict = Depends(get_current_admin)
):
    """Deactivate a user's account (admin only)"""
    if user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with id {user_id} not found"
        )

    # Cannot deactivate yourself
    if user_id == admin["id"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot deactivate your own account"
        )

    users_db[user_id]["is_active"] = False
    users_db[user_id]["updated_at"] = get_current_time()
