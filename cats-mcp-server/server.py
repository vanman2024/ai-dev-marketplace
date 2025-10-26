"""
CATS MCP Server - FastMCP server for CATS API v3

Real CATS API endpoints from https://api.catsone.com/v3
"""

import os
from typing import Any, Optional
import httpx
from dotenv import load_dotenv
from fastmcp import FastMCP

load_dotenv()

mcp = FastMCP("CATS API v3")

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


# CANDIDATES
@mcp.tool()
async def list_candidates(per_page: int = 25, page: int = 1) -> dict[str, Any]:
    """List candidates. GET /candidates"""
    return await make_request("GET", "/candidates", params={"per_page": per_page, "page": page})


@mcp.tool()
async def get_candidate(candidate_id: int) -> dict[str, Any]:
    """Get candidate details. GET /candidates/{id}"""
    return await make_request("GET", f"/candidates/{candidate_id}")


@mcp.tool()
async def search_candidates(query: str, per_page: int = 25) -> dict[str, Any]:
    """Search candidates. GET /candidates/search"""
    return await make_request("GET", "/candidates/search", params={"q": query, "per_page": per_page})


# JOBS
@mcp.tool()
async def list_jobs(per_page: int = 25, page: int = 1) -> dict[str, Any]:
    """List jobs. GET /jobs"""
    return await make_request("GET", "/jobs", params={"per_page": per_page, "page": page})


@mcp.tool()
async def get_job(job_id: int) -> dict[str, Any]:
    """Get job details. GET /jobs/{id}"""
    return await make_request("GET", f"/jobs/{job_id}")


@mcp.tool()
async def search_jobs(query: str, per_page: int = 25) -> dict[str, Any]:
    """Search jobs. GET /jobs/search"""
    return await make_request("GET", "/jobs/search", params={"q": query, "per_page": per_page})


# COMPANIES
@mcp.tool()
async def list_companies(per_page: int = 25, page: int = 1) -> dict[str, Any]:
    """List companies. GET /companies"""
    return await make_request("GET", "/companies", params={"per_page": per_page, "page": page})


@mcp.tool()
async def get_company(company_id: int) -> dict[str, Any]:
    """Get company details. GET /companies/{id}"""
    return await make_request("GET", f"/companies/{company_id}")


# PIPELINES
@mcp.tool()
async def list_pipelines(per_page: int = 25, page: int = 1) -> dict[str, Any]:
    """List pipelines. GET /pipelines"""
    return await make_request("GET", "/pipelines", params={"per_page": per_page, "page": page})


@mcp.tool()
async def get_pipeline(pipeline_id: int) -> dict[str, Any]:
    """Get pipeline details. GET /pipelines/{id}"""
    return await make_request("GET", f"/pipelines/{pipeline_id}")


@mcp.tool()
async def update_pipeline_status(pipeline_id: int, status_id: int) -> dict[str, Any]:
    """Update pipeline status. PUT /pipelines/{id}/status"""
    return await make_request("PUT", f"/pipelines/{pipeline_id}/status", json_data={"status_id": status_id})


# ACTIVITIES
@mcp.tool()
async def list_activities(per_page: int = 25, page: int = 1) -> dict[str, Any]:
    """List activities. GET /activities"""
    return await make_request("GET", "/activities", params={"per_page": per_page, "page": page})


@mcp.tool()
async def get_activity(activity_id: int) -> dict[str, Any]:
    """Get activity details. GET /activities/{id}"""
    return await make_request("GET", f"/activities/{activity_id}")


# TASKS
@mcp.tool()
async def list_tasks(per_page: int = 25, page: int = 1) -> dict[str, Any]:
    """List tasks. GET /tasks"""
    return await make_request("GET", "/tasks", params={"per_page": per_page, "page": page})


@mcp.tool()
async def get_task(task_id: int) -> dict[str, Any]:
    """Get task details. GET /tasks/{id}"""
    return await make_request("GET", f"/tasks/{task_id}")


@mcp.tool()
async def create_task(title: str, due_date: Optional[str] = None, candidate_id: Optional[int] = None) -> dict[str, Any]:
    """Create task. POST /tasks"""
    payload = {"title": title}
    if due_date:
        payload["due_date"] = due_date
    if candidate_id:
        payload["candidate_id"] = candidate_id
    return await make_request("POST", "/tasks", json_data=payload)


if __name__ == "__main__":
    mcp.run(transport="http")
