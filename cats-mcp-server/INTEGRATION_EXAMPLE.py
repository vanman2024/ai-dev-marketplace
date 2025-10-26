"""
Example: Integrating Recruiting Toolsets with CATS MCP Server

This demonstrates how to integrate the recruiting toolsets into the main server.py
"""

import os
from typing import Any
import httpx
from dotenv import load_dotenv
from fastmcp import FastMCP
from toolsets_recruiting import register_all_recruiting_toolsets

load_dotenv()

# Initialize MCP server
mcp = FastMCP("CATS API v3 - Complete")

# Configuration
CATS_API_BASE_URL = os.getenv("CATS_API_BASE_URL", "https://api.catsone.com/v3")
CATS_API_KEY = os.getenv("CATS_API_KEY", "")


class CATSAPIError(Exception):
    """CATS API error"""
    pass


async def make_request(method: str, endpoint: str, params: dict = None, json_data: dict = None) -> dict:
    """Make authenticated request to CATS API"""
    if not CATS_API_KEY:
        raise CATSAPIError("CATS_API_KEY not configured")

    url = f"{CATS_API_BASE_URL.rstrip('/')}/{endpoint.lstrip('/')}"
    headers = {
        "Authorization": f"Token {CATS_API_KEY}",
        "Content-Type": "application/json",
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            response = await client.request(method, url, headers=headers, params=params, json=json_data)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise CATSAPIError(f"API error: {e}")


# Register all recruiting toolsets (64 tools)
register_all_recruiting_toolsets(mcp, make_request)


# Example: Add some existing tools from server.py
@mcp.tool()
async def list_candidates(per_page: int = 25, page: int = 1) -> dict[str, Any]:
    """List candidates. GET /candidates"""
    return await make_request("GET", "/candidates", params={"per_page": per_page, "page": page})


@mcp.tool()
async def get_candidate(candidate_id: int) -> dict[str, Any]:
    """Get candidate details. GET /candidates/{id}"""
    return await make_request("GET", f"/candidates/{candidate_id}")


@mcp.tool()
async def list_jobs(per_page: int = 25, page: int = 1) -> dict[str, Any]:
    """List jobs. GET /jobs"""
    return await make_request("GET", "/jobs", params={"per_page": per_page, "page": page})


@mcp.tool()
async def get_job(job_id: int) -> dict[str, Any]:
    """Get job details. GET /jobs/{id}"""
    return await make_request("GET", f"/jobs/{job_id}")


# Start server
if __name__ == "__main__":
    print("Starting CATS MCP Server with Recruiting Toolsets...")
    print("Total tools registered: 64 (recruiting) + additional tools")
    print("\nToolsets:")
    print("  - Companies (22 tools)")
    print("  - Contacts (25 tools)")
    print("  - Activities (6 tools)")
    print("  - Portals (8 tools)")
    print("  - Work History (3 tools)")
    print("\nServer starting on http://localhost:8000")
    mcp.run(transport="http")
