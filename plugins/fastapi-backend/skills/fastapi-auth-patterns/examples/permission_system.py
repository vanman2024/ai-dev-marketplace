"""
permission_system.py - Role-Based Access Control (RBAC) and Permission System

This file demonstrates a complete permission system implementation for FastAPI
with roles, permissions, and hierarchical access control.

Features:
1. Role-based access control (RBAC)
2. Fine-grained permissions
3. Permission inheritance
4. Dynamic permission checking
5. Permission decorators
6. Multi-tenancy support
"""

from enum import Enum
from typing import Annotated, List, Set
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel

app = FastAPI()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


# ============================================================================
# Models
# ============================================================================

class Role(str, Enum):
    """User roles with hierarchical permissions."""
    SUPER_ADMIN = "super_admin"      # Full system access
    ADMIN = "admin"                  # Organization admin
    MANAGER = "manager"              # Team manager
    USER = "user"                    # Regular user
    GUEST = "guest"                  # Limited access


class Permission(str, Enum):
    """Granular permissions."""
    # User permissions
    USER_READ = "user:read"
    USER_WRITE = "user:write"
    USER_DELETE = "user:delete"

    # Item permissions
    ITEM_READ = "item:read"
    ITEM_WRITE = "item:write"
    ITEM_DELETE = "item:delete"

    # Admin permissions
    ADMIN_READ = "admin:read"
    ADMIN_WRITE = "admin:write"
    ADMIN_DELETE = "admin:delete"

    # Organization permissions
    ORG_READ = "org:read"
    ORG_WRITE = "org:write"
    ORG_MANAGE = "org:manage"


class User(BaseModel):
    """User with role and permissions."""
    id: int
    username: str
    email: str
    role: Role
    permissions: Set[Permission] = set()
    organization_id: int | None = None
    team_id: int | None = None


class Organization(BaseModel):
    """Organization for multi-tenancy."""
    id: int
    name: str
    owner_id: int


# ============================================================================
# Permission Hierarchy & Role Definitions
# ============================================================================

# Define permissions for each role
ROLE_PERMISSIONS = {
    Role.SUPER_ADMIN: {
        # Super admin has all permissions
        Permission.USER_READ, Permission.USER_WRITE, Permission.USER_DELETE,
        Permission.ITEM_READ, Permission.ITEM_WRITE, Permission.ITEM_DELETE,
        Permission.ADMIN_READ, Permission.ADMIN_WRITE, Permission.ADMIN_DELETE,
        Permission.ORG_READ, Permission.ORG_WRITE, Permission.ORG_MANAGE,
    },
    Role.ADMIN: {
        # Admin has most permissions except super admin functions
        Permission.USER_READ, Permission.USER_WRITE, Permission.USER_DELETE,
        Permission.ITEM_READ, Permission.ITEM_WRITE, Permission.ITEM_DELETE,
        Permission.ADMIN_READ, Permission.ADMIN_WRITE,
        Permission.ORG_READ, Permission.ORG_WRITE,
    },
    Role.MANAGER: {
        # Manager can read/write but not delete users
        Permission.USER_READ, Permission.USER_WRITE,
        Permission.ITEM_READ, Permission.ITEM_WRITE, Permission.ITEM_DELETE,
        Permission.ADMIN_READ,
        Permission.ORG_READ,
    },
    Role.USER: {
        # Regular user can read and manage their own items
        Permission.USER_READ,
        Permission.ITEM_READ, Permission.ITEM_WRITE,
    },
    Role.GUEST: {
        # Guest can only read
        Permission.USER_READ,
        Permission.ITEM_READ,
    },
}


def get_role_permissions(role: Role) -> Set[Permission]:
    """Get all permissions for a given role."""
    return ROLE_PERMISSIONS.get(role, set())


def has_permission(user: User, permission: Permission) -> bool:
    """
    Check if user has a specific permission.

    Permission can come from:
    1. User's role (via ROLE_PERMISSIONS)
    2. User's explicit permissions (custom grants)
    """
    # Get role-based permissions
    role_perms = get_role_permissions(user.role)

    # Check if user has permission from role or explicit grant
    return permission in role_perms or permission in user.permissions


def has_any_permission(user: User, permissions: List[Permission]) -> bool:
    """Check if user has ANY of the specified permissions."""
    return any(has_permission(user, perm) for perm in permissions)


def has_all_permissions(user: User, permissions: List[Permission]) -> bool:
    """Check if user has ALL of the specified permissions."""
    return all(has_permission(user, perm) for perm in permissions)


# ============================================================================
# Mock Data & User Retrieval
# ============================================================================

fake_users_db = {
    "admin": User(
        id=1,
        username="admin",
        email="admin@example.com",
        role=Role.ADMIN,
        organization_id=1,
    ),
    "manager": User(
        id=2,
        username="manager",
        email="manager@example.com",
        role=Role.MANAGER,
        organization_id=1,
        team_id=1,
    ),
    "user": User(
        id=3,
        username="user",
        email="user@example.com",
        role=Role.USER,
        organization_id=1,
        team_id=1,
    ),
    "guest": User(
        id=4,
        username="guest",
        email="guest@example.com",
        role=Role.GUEST,
    ),
}


async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    """Get current user from token."""
    # In production, decode JWT and fetch from database
    # For demo, returning mock user based on token
    username = token  # Simplified for example
    user = fake_users_db.get(username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    return user


# ============================================================================
# Permission Dependencies
# ============================================================================

def require_permission(permission: Permission):
    """
    Dependency factory that requires a specific permission.

    Usage:
        @app.get("/admin/users")
        async def list_users(user: User = Depends(require_permission(Permission.USER_READ))):
            ...
    """
    async def permission_checker(
        current_user: Annotated[User, Depends(get_current_user)]
    ) -> User:
        if not has_permission(current_user, permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied. Required: {permission.value}"
            )
        return current_user

    return permission_checker


def require_any_permission(*permissions: Permission):
    """
    Dependency factory that requires ANY of the specified permissions.

    Usage:
        @app.get("/content")
        async def get_content(
            user: User = Depends(require_any_permission(
                Permission.ITEM_READ,
                Permission.ADMIN_READ
            ))
        ):
            ...
    """
    async def permission_checker(
        current_user: Annotated[User, Depends(get_current_user)]
    ) -> User:
        if not has_any_permission(current_user, list(permissions)):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied. Required one of: {[p.value for p in permissions]}"
            )
        return current_user

    return permission_checker


def require_all_permissions(*permissions: Permission):
    """
    Dependency factory that requires ALL of the specified permissions.
    """
    async def permission_checker(
        current_user: Annotated[User, Depends(get_current_user)]
    ) -> User:
        if not has_all_permissions(current_user, list(permissions)):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied. Required all: {[p.value for p in permissions]}"
            )
        return current_user

    return permission_checker


def require_role(role: Role):
    """
    Dependency factory that requires a specific role.

    Usage:
        @app.get("/admin/dashboard")
        async def admin_dashboard(user: User = Depends(require_role(Role.ADMIN))):
            ...
    """
    async def role_checker(
        current_user: Annotated[User, Depends(get_current_user)]
    ) -> User:
        if current_user.role != role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required role: {role.value}"
            )
        return current_user

    return role_checker


def require_role_or_higher(minimum_role: Role):
    """
    Dependency factory that requires a minimum role level.

    Role hierarchy: SUPER_ADMIN > ADMIN > MANAGER > USER > GUEST
    """
    role_hierarchy = [Role.GUEST, Role.USER, Role.MANAGER, Role.ADMIN, Role.SUPER_ADMIN]

    async def role_checker(
        current_user: Annotated[User, Depends(get_current_user)]
    ) -> User:
        user_role_index = role_hierarchy.index(current_user.role)
        required_role_index = role_hierarchy.index(minimum_role)

        if user_role_index < required_role_index:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Minimum role required: {minimum_role.value}"
            )
        return current_user

    return role_checker


# ============================================================================
# Organization & Team-Based Access Control
# ============================================================================

def require_same_organization(resource_org_id: int):
    """
    Dependency that ensures user belongs to the same organization as the resource.

    Use for multi-tenancy isolation.
    """
    async def org_checker(
        current_user: Annotated[User, Depends(get_current_user)]
    ) -> User:
        # Super admins can access all organizations
        if current_user.role == Role.SUPER_ADMIN:
            return current_user

        if current_user.organization_id != resource_org_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied. Resource belongs to different organization"
            )
        return current_user

    return org_checker


def require_team_member(team_id: int):
    """
    Dependency that ensures user is a member of the specified team.
    """
    async def team_checker(
        current_user: Annotated[User, Depends(get_current_user)]
    ) -> User:
        # Admins can access all teams
        if current_user.role in [Role.SUPER_ADMIN, Role.ADMIN]:
            return current_user

        if current_user.team_id != team_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied. Must be a team member"
            )
        return current_user

    return team_checker


# ============================================================================
# Example Protected Endpoints
# ============================================================================

@app.get("/users/")
async def list_users(
    current_user: Annotated[User, Depends(require_permission(Permission.USER_READ))]
):
    """
    List users - requires USER_READ permission.

    Accessible to: GUEST, USER, MANAGER, ADMIN, SUPER_ADMIN
    """
    return {"users": list(fake_users_db.values())}


@app.post("/users/")
async def create_user(
    username: str,
    email: str,
    current_user: Annotated[User, Depends(require_permission(Permission.USER_WRITE))]
):
    """
    Create user - requires USER_WRITE permission.

    Accessible to: MANAGER, ADMIN, SUPER_ADMIN
    """
    return {"message": f"User {username} created by {current_user.username}"}


@app.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: Annotated[User, Depends(require_permission(Permission.USER_DELETE))]
):
    """
    Delete user - requires USER_DELETE permission.

    Accessible to: ADMIN, SUPER_ADMIN
    """
    return {"message": f"User {user_id} deleted by {current_user.username}"}


@app.get("/admin/dashboard")
async def admin_dashboard(
    current_user: Annotated[User, Depends(require_role(Role.ADMIN))]
):
    """
    Admin dashboard - requires ADMIN role.

    Accessible to: ADMIN only (not SUPER_ADMIN unless explicitly ADMIN)
    """
    return {"dashboard": "admin", "user": current_user.username}


@app.get("/manager/reports")
async def manager_reports(
    current_user: Annotated[User, Depends(require_role_or_higher(Role.MANAGER))]
):
    """
    Manager reports - requires MANAGER role or higher.

    Accessible to: MANAGER, ADMIN, SUPER_ADMIN
    """
    return {"reports": "manager level", "user": current_user.username}


@app.get("/items/sensitive")
async def get_sensitive_items(
    current_user: Annotated[User, Depends(
        require_all_permissions(Permission.ITEM_READ, Permission.ADMIN_READ)
    )]
):
    """
    Sensitive items - requires BOTH item:read AND admin:read permissions.

    Accessible to: MANAGER, ADMIN, SUPER_ADMIN
    """
    return {"sensitive_items": ["item1", "item2"]}


@app.get("/organizations/{org_id}/data")
async def get_org_data(
    org_id: int,
    current_user: Annotated[User, Depends(require_same_organization(org_id))]
):
    """
    Organization data - requires user to belong to the same organization.

    Demonstrates multi-tenancy isolation.
    """
    return {
        "organization_id": org_id,
        "data": "organization specific data",
        "accessed_by": current_user.username,
    }


@app.get("/teams/{team_id}/dashboard")
async def team_dashboard(
    team_id: int,
    current_user: Annotated[User, Depends(require_team_member(team_id))]
):
    """
    Team dashboard - requires team membership.

    Accessible to: Team members, ADMIN, SUPER_ADMIN
    """
    return {
        "team_id": team_id,
        "dashboard": "team data",
        "member": current_user.username,
    }


# ============================================================================
# Permission Management Endpoints
# ============================================================================

@app.post("/users/{user_id}/permissions")
async def grant_permission(
    user_id: int,
    permission: Permission,
    current_user: Annotated[User, Depends(require_role(Role.ADMIN))]
):
    """
    Grant a permission to a user.

    Only admins can grant permissions.
    """
    # In production, update database
    return {
        "message": f"Permission {permission.value} granted to user {user_id}",
        "granted_by": current_user.username,
    }


@app.delete("/users/{user_id}/permissions/{permission}")
async def revoke_permission(
    user_id: int,
    permission: Permission,
    current_user: Annotated[User, Depends(require_role(Role.ADMIN))]
):
    """
    Revoke a permission from a user.

    Only admins can revoke permissions.
    """
    # In production, update database
    return {
        "message": f"Permission {permission.value} revoked from user {user_id}",
        "revoked_by": current_user.username,
    }


@app.get("/users/{user_id}/permissions")
async def list_user_permissions(
    user_id: int,
    current_user: Annotated[User, Depends(require_permission(Permission.USER_READ))]
):
    """
    List all permissions for a user.

    Shows both role-based and explicit permissions.
    """
    # Fetch user from database
    user = fake_users_db.get(str(user_id))
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    role_permissions = list(get_role_permissions(user.role))
    explicit_permissions = list(user.permissions)

    return {
        "user_id": user_id,
        "role": user.role.value,
        "role_permissions": [p.value for p in role_permissions],
        "explicit_permissions": [p.value for p in explicit_permissions],
        "all_permissions": [p.value for p in set(role_permissions + explicit_permissions)],
    }


# ============================================================================
# Permission Check Endpoint
# ============================================================================

@app.post("/check-permission")
async def check_permission_endpoint(
    permission: Permission,
    current_user: Annotated[User, Depends(get_current_user)]
):
    """
    Check if current user has a specific permission.

    Useful for frontend to determine which UI elements to show.
    """
    has_perm = has_permission(current_user, permission)
    return {
        "user": current_user.username,
        "permission": permission.value,
        "has_permission": has_perm,
    }


# ============================================================================
# Summary & Best Practices
# ============================================================================

"""
Permission System Best Practices:

1. **Use Permission-Based Access** (not just roles)
   - More flexible than role-only systems
   - Allows custom permission grants

2. **Define Clear Permission Hierarchy**
   - Document what each permission grants
   - Use hierarchical permissions (read < write < delete)

3. **Implement Multi-Level Checks**
   - Role checks (require_role)
   - Permission checks (require_permission)
   - Resource ownership (require_same_organization)
   - Team membership (require_team_member)

4. **Separate Permissions from Business Logic**
   - Use dependencies for permission checking
   - Keep permission logic reusable

5. **Audit Permission Changes**
   - Log when permissions are granted/revoked
   - Track who made the changes

6. **Consider Multi-Tenancy**
   - Isolate data by organization
   - Prevent cross-organization access

7. **Document Permission Requirements**
   - Clearly state required permissions in docstrings
   - Keep permission documentation up to date

8. **Test Permission Boundaries**
   - Test that users can't access unauthorized resources
   - Test permission inheritance
   - Test multi-tenancy isolation
"""
