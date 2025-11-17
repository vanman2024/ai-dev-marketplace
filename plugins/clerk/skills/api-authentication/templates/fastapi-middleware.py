# fastapi-middleware.py - Clerk authentication middleware for FastAPI

from fastapi import Depends, HTTPException, Request, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from clerk_backend_api import Clerk
import os
from typing import Optional, List
from functools import wraps

# Initialize Clerk client
clerk = Clerk(bearer_auth=os.getenv("CLERK_SECRET_KEY"))
security = HTTPBearer()

# ============================================================================
# Authentication Dependencies
# ============================================================================

async def require_auth(
    credentials: HTTPAuthorizationCredentials = Security(security)
) -> str:
    """
    Require authentication for FastAPI routes
    Returns userId if valid, raises HTTPException if not
    """
    if not credentials:
        raise HTTPException(status_code=401, detail="Unauthorized")

    token = credentials.credentials

    try:
        # Verify JWT token with Clerk
        payload = await clerk.verify_token(token)
        return payload.get("sub")  # User ID
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail=f"Invalid token: {str(e)}"
        )


async def optional_auth(
    request: Request,
    credentials: Optional[HTTPAuthorizationCredentials] = Security(security, auto_error=False)
) -> Optional[str]:
    """
    Optional authentication - allows both authenticated and anonymous requests
    Returns userId if authenticated, None if not
    """
    if not credentials:
        return None

    try:
        payload = await clerk.verify_token(credentials.credentials)
        return payload.get("sub")
    except:
        return None


async def get_current_user(user_id: str = Depends(require_auth)):
    """
    Get full user object from Clerk
    """
    try:
        user = await clerk.users.get_user(user_id)
        return user
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch user: {str(e)}"
        )

# ============================================================================
# Role-Based Access Control
# ============================================================================

def require_role(role: str):
    """
    Require specific role for route access
    """
    async def role_checker(user_id: str = Depends(require_auth)):
        try:
            user = await clerk.users.get_user(user_id)
            user_role = user.public_metadata.get("role")

            if user_role != role:
                raise HTTPException(
                    status_code=403,
                    detail=f"Forbidden - requires role: {role}"
                )

            return user_id
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Role check failed: {str(e)}"
            )

    return role_checker


def require_any_role(roles: List[str]):
    """
    Require any of the specified roles
    """
    async def role_checker(user_id: str = Depends(require_auth)):
        try:
            user = await clerk.users.get_user(user_id)
            user_role = user.public_metadata.get("role")

            if user_role not in roles:
                raise HTTPException(
                    status_code=403,
                    detail=f"Forbidden - requires one of: {', '.join(roles)}"
                )

            return user_id
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Role check failed: {str(e)}"
            )

    return role_checker


def require_permission(permission: str):
    """
    Require specific permission
    """
    async def permission_checker(user_id: str = Depends(require_auth)):
        try:
            user = await clerk.users.get_user(user_id)
            permissions = user.public_metadata.get("permissions", [])

            if permission not in permissions:
                raise HTTPException(
                    status_code=403,
                    detail=f"Forbidden - requires permission: {permission}"
                )

            return user_id
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Permission check failed: {str(e)}"
            )

    return permission_checker

# ============================================================================
# Organization Membership
# ============================================================================

def require_organization(org_id: str):
    """
    Require user to be member of specific organization
    """
    async def org_checker(user_id: str = Depends(require_auth)):
        try:
            memberships = await clerk.users.get_organization_membership_list(
                user_id=user_id
            )

            org_ids = [m.organization.id for m in memberships.data]

            if org_id not in org_ids:
                raise HTTPException(
                    status_code=403,
                    detail=f"Forbidden - not member of organization"
                )

            return user_id
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Organization check failed: {str(e)}"
            )

    return org_checker

# ============================================================================
# Usage Examples
# ============================================================================

"""
# Basic authentication
@app.get("/protected")
async def protected_route(user_id: str = Depends(require_auth)):
    return {"message": "Protected data", "user_id": user_id}


# Optional authentication
@app.get("/posts/{id}")
async def get_post(
    id: int,
    user_id: Optional[str] = Depends(optional_auth)
):
    post = {"id": id, "title": "Post Title"}
    if user_id:
        post["user_specific_data"] = "Extra data for authenticated users"
    return post


# Get current user
@app.get("/user/profile")
async def get_profile(user = Depends(get_current_user)):
    return {
        "id": user.id,
        "email": user.email_addresses[0].email_address,
        "name": f"{user.first_name} {user.last_name}"
    }


# Role-based access
@app.delete("/admin/users/{id}")
async def delete_user(
    id: str,
    user_id: str = Depends(require_role("admin"))
):
    return {"message": f"User {id} deleted"}


# Multiple roles
@app.get("/reports")
async def get_reports(
    user_id: str = Depends(require_any_role(["admin", "manager"]))
):
    return {"reports": []}


# Permission-based access
@app.post("/content")
async def create_content(
    data: dict,
    user_id: str = Depends(require_permission("content:write"))
):
    return {"message": "Content created"}


# Organization membership
@app.get("/org/{org_id}/data")
async def get_org_data(
    org_id: str,
    user_id: str = Depends(require_organization(org_id))
):
    return {"org_data": "sensitive data"}
"""
