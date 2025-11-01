"""
protected_routes.py - Examples of Protected Route Patterns in FastAPI

This file demonstrates various patterns for protecting FastAPI endpoints
with different authentication and authorization requirements.

Patterns Included:
1. Public routes (no authentication)
2. Authenticated routes (requires valid token)
3. Admin-only routes
4. Scope-based protected routes
5. Resource ownership validation
6. Conditional protection (optional authentication)
"""

from typing import Annotated
from fastapi import Depends, FastAPI, HTTPException, Security, status
from fastapi.security import OAuth2PasswordBearer, SecurityScopes
from pydantic import BaseModel

app = FastAPI()

# Assume these are defined elsewhere (from jwt_auth.py or oauth2_flow.py)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


# ============================================================================
# Models
# ============================================================================

class User(BaseModel):
    """User model."""
    id: int
    username: str
    email: str
    is_admin: bool = False
    scopes: list[str] = []


class Item(BaseModel):
    """Item model."""
    id: int
    name: str
    description: str
    owner_id: int


class Post(BaseModel):
    """Post model."""
    id: int
    title: str
    content: str
    author_id: int
    is_published: bool


# ============================================================================
# Mock Dependencies (replace with real implementations)
# ============================================================================

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    """Get current authenticated user from token."""
    # This would decode JWT and fetch user from database
    # For demo purposes, returning mock user
    return User(id=1, username="johndoe", email="john@example.com", is_admin=False)


async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """Ensure user is active (not disabled)."""
    # Check if user is disabled in database
    return current_user


async def get_current_admin_user(current_user: User = Depends(get_current_user)) -> User:
    """Ensure current user is an admin."""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


async def get_user_with_scopes(
    security_scopes: SecurityScopes,
    current_user: User = Depends(get_current_user)
) -> User:
    """Validate user has required scopes."""
    for scope in security_scopes.scopes:
        if scope not in current_user.scopes:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient permissions. Required: {scope}"
            )
    return current_user


def get_optional_user(token: str | None = Depends(oauth2_scheme)) -> User | None:
    """Get current user if authenticated, None otherwise."""
    if not token:
        return None
    # Decode token and return user
    return User(id=1, username="johndoe", email="john@example.com")


# ============================================================================
# Pattern 1: Public Routes (No Authentication)
# ============================================================================

@app.get("/")
async def root():
    """
    Public endpoint - accessible to anyone without authentication.

    Use for: Landing pages, documentation, health checks
    """
    return {
        "message": "Welcome to the API",
        "docs": "/docs",
        "login": "/token"
    }


@app.get("/public/posts")
async def list_public_posts():
    """
    Public endpoint - list published posts.

    Use for: Content that should be accessible without login
    """
    # Return only published posts
    return [
        {"id": 1, "title": "Public Post 1", "excerpt": "..."},
        {"id": 2, "title": "Public Post 2", "excerpt": "..."},
    ]


# ============================================================================
# Pattern 2: Basic Authentication Required
# ============================================================================

@app.get("/users/me")
async def read_current_user(
    current_user: Annotated[User, Depends(get_current_active_user)]
):
    """
    Protected endpoint - requires valid authentication token.

    Use for: User profile, settings, personal data
    """
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
    }


@app.get("/dashboard")
async def get_dashboard(
    current_user: Annotated[User, Depends(get_current_active_user)]
):
    """
    Protected endpoint - user dashboard.

    Returns personalized data for authenticated user.
    """
    return {
        "user": current_user.username,
        "notifications": [],
        "recent_activity": [],
    }


# ============================================================================
# Pattern 3: Admin-Only Routes
# ============================================================================

@app.get("/admin/users")
async def list_all_users(
    admin_user: Annotated[User, Depends(get_current_admin_user)]
):
    """
    Admin-only endpoint - list all users.

    Use for: Administrative functions, user management
    """
    return [
        {"id": 1, "username": "johndoe", "email": "john@example.com"},
        {"id": 2, "username": "alice", "email": "alice@example.com"},
    ]


@app.delete("/admin/users/{user_id}")
async def delete_user(
    user_id: int,
    admin_user: Annotated[User, Depends(get_current_admin_user)]
):
    """
    Admin-only endpoint - delete user account.

    Use for: Privileged operations requiring admin access
    """
    # Delete user from database
    return {"message": f"User {user_id} deleted by admin {admin_user.username}"}


@app.post("/admin/announcements")
async def create_announcement(
    title: str,
    content: str,
    admin_user: Annotated[User, Depends(get_current_admin_user)]
):
    """
    Admin-only endpoint - create system announcement.
    """
    return {
        "id": 123,
        "title": title,
        "content": content,
        "created_by": admin_user.username,
    }


# ============================================================================
# Pattern 4: Scope-Based Protection (Fine-Grained Permissions)
# ============================================================================

@app.get("/items/")
async def read_items(
    current_user: Annotated[User, Security(get_user_with_scopes, scopes=["items:read"])]
):
    """
    Protected with scope - requires "items:read" permission.

    Use for: Operations requiring specific permissions
    """
    return [
        {"id": 1, "name": "Item 1"},
        {"id": 2, "name": "Item 2"},
    ]


@app.post("/items/")
async def create_item(
    item: Item,
    current_user: Annotated[User, Security(get_user_with_scopes, scopes=["items:write"])]
):
    """
    Protected with scope - requires "items:write" permission.

    Use for: Create/update operations with specific permissions
    """
    return {
        "id": item.id,
        "name": item.name,
        "owner": current_user.username,
    }


@app.delete("/items/{item_id}")
async def delete_item(
    item_id: int,
    current_user: Annotated[User, Security(get_user_with_scopes, scopes=["items:delete"])]
):
    """
    Protected with scope - requires "items:delete" permission.

    Use for: Destructive operations requiring explicit permission
    """
    return {"message": f"Item {item_id} deleted"}


# ============================================================================
# Pattern 5: Resource Ownership Validation
# ============================================================================

async def get_post_or_404(post_id: int) -> Post:
    """Get post by ID or raise 404."""
    # Fetch from database
    # If not found, raise HTTPException(404)
    return Post(
        id=post_id,
        title="My Post",
        content="Post content",
        author_id=1,
        is_published=True
    )


async def verify_post_owner(
    post: Post = Depends(get_post_or_404),
    current_user: User = Depends(get_current_active_user)
) -> Post:
    """
    Verify that current user owns the post.

    Use for: Ensuring users can only modify their own resources
    """
    if post.author_id != current_user.id and not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to access this post"
        )
    return post


@app.get("/posts/{post_id}")
async def read_post(post: Post = Depends(get_post_or_404)):
    """
    Public endpoint - read published post.

    Anyone can read published posts, authentication not required.
    """
    if not post.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    return post


@app.put("/posts/{post_id}")
async def update_post(
    title: str,
    content: str,
    post: Post = Depends(verify_post_owner)
):
    """
    Protected endpoint - update post (owner or admin only).

    Validates that current user is the post owner or an admin.
    """
    post.title = title
    post.content = content
    # Save to database
    return post


@app.delete("/posts/{post_id}")
async def delete_post(
    post: Post = Depends(verify_post_owner)
):
    """
    Protected endpoint - delete post (owner or admin only).
    """
    # Delete from database
    return {"message": f"Post {post.id} deleted"}


# ============================================================================
# Pattern 6: Optional Authentication (Different Behavior for Authenticated Users)
# ============================================================================

@app.get("/feed")
async def get_feed(
    current_user: User | None = Depends(get_optional_user)
):
    """
    Optional authentication - returns personalized feed if authenticated.

    Use for: Content that can be viewed publicly but is personalized when logged in
    """
    if current_user:
        # Return personalized feed
        return {
            "type": "personalized",
            "user": current_user.username,
            "posts": ["personalized", "content"],
        }
    else:
        # Return generic feed
        return {
            "type": "public",
            "posts": ["public", "content"],
        }


@app.get("/posts/{post_id}/comments")
async def get_comments(
    post_id: int,
    current_user: User | None = Depends(get_optional_user)
):
    """
    Optional authentication - shows different data based on auth status.

    Authenticated users see more details (e.g., edit buttons, vote status).
    """
    comments = [
        {"id": 1, "text": "Great post!", "author": "alice"},
        {"id": 2, "text": "Thanks for sharing", "author": "bob"},
    ]

    if current_user:
        # Add additional fields for authenticated users
        for comment in comments:
            comment["can_edit"] = comment["author"] == current_user.username
            comment["has_voted"] = False  # Check from database

    return comments


# ============================================================================
# Pattern 7: Combined Authorization (Multiple Checks)
# ============================================================================

async def require_admin_or_owner(
    resource_owner_id: int,
    current_user: User = Depends(get_current_active_user)
) -> User:
    """
    Require user to be admin OR owner of the resource.

    Use for: Operations that should be available to resource owner or admins
    """
    if not (current_user.id == resource_owner_id or current_user.is_admin):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access or resource ownership required"
        )
    return current_user


@app.put("/items/{item_id}")
async def update_item(
    item_id: int,
    name: str,
    description: str,
    # Assume item.owner_id = 1 for this example
    current_user: User = Depends(lambda cu=Depends(get_current_active_user): require_admin_or_owner(1, cu))
):
    """
    Protected endpoint - update item (owner or admin).

    Either the item owner or an admin can update the item.
    """
    return {
        "id": item_id,
        "name": name,
        "description": description,
        "updated_by": current_user.username,
    }


# ============================================================================
# Pattern 8: Rate-Limited Protected Routes
# ============================================================================

# Note: This would typically use a rate limiting library like slowapi

@app.post("/api/expensive-operation")
async def expensive_operation(
    data: dict,
    current_user: Annotated[User, Depends(get_current_active_user)]
):
    """
    Protected and rate-limited endpoint.

    Combines authentication with rate limiting to prevent abuse.
    Add @limiter.limit("5/minute") with slowapi or similar.
    """
    # Perform expensive operation
    return {
        "status": "completed",
        "user": current_user.username,
    }


# ============================================================================
# Summary
# ============================================================================

"""
Protection Patterns Summary:

1. Public Routes: No protection, anyone can access
2. Basic Auth: Requires valid token, any authenticated user
3. Admin Only: Requires admin role/permission
4. Scope-Based: Requires specific OAuth2 scopes
5. Resource Owner: Requires ownership of specific resource
6. Optional Auth: Different behavior based on auth status
7. Combined: Multiple authorization checks (owner OR admin)
8. Rate Limited: Authentication + rate limiting

Choose the appropriate pattern based on:
- Data sensitivity
- Operation risk level
- User permissions model
- Business requirements
"""
