"""
CATS MCP Server - FastMCP server for CATS Applicant Tracking System API

This server provides MCP tools to interact with the CATS API endpoints for
candidate management, job postings, applications, and interview scheduling.
"""

import os
from datetime import datetime
from enum import Enum
from typing import Any, Optional

import httpx
from dotenv import load_dotenv
from fastmcp import FastMCP
from pydantic import BaseModel, Field

# Load environment variables
load_dotenv()

# Initialize FastMCP server
mcp = FastMCP("CATS API Server")

# Configuration
CATS_API_BASE_URL = os.getenv("CATS_API_BASE_URL", "https://api.catsone.com/v3")
CATS_API_KEY = os.getenv("CATS_API_KEY", "")


# ============================================================================
# ENUMS AND MODELS
# ============================================================================


class CandidateStatus(str, Enum):
    """Candidate status options"""

    ACTIVE = "active"
    ARCHIVED = "archived"
    HIRED = "hired"
    REJECTED = "rejected"
    WITHDRAWN = "withdrawn"


class ApplicationStatus(str, Enum):
    """Application status options"""

    SUBMITTED = "submitted"
    REVIEWING = "reviewing"
    INTERVIEW = "interview"
    OFFER = "offer"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    WITHDRAWN = "withdrawn"


class JobStatus(str, Enum):
    """Job posting status options"""

    DRAFT = "draft"
    OPEN = "open"
    CLOSED = "closed"
    FILLED = "filled"
    CANCELLED = "cancelled"


class InterviewStatus(str, Enum):
    """Interview status options"""

    SCHEDULED = "scheduled"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    RESCHEDULED = "rescheduled"


# ============================================================================
# EXCEPTIONS
# ============================================================================


class CATSAPIError(Exception):
    """Custom exception for CATS API errors"""

    pass


# ============================================================================
# HTTP CLIENT
# ============================================================================


async def make_cats_request(
    method: str,
    endpoint: str,
    params: dict[str, Any] | None = None,
    json_data: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """
    Make authenticated request to CATS API

    Args:
        method: HTTP method (GET, POST, PUT, DELETE)
        endpoint: API endpoint path (without base URL)
        params: Query parameters
        json_data: JSON request body

    Returns:
        Response data as dictionary

    Raises:
        CATSAPIError: If API request fails
    """
    if not CATS_API_BASE_URL:
        raise CATSAPIError("CATS_API_BASE_URL not configured in environment variables")

    if not CATS_API_KEY:
        raise CATSAPIError("CATS_API_KEY not configured in environment variables")

    url = f"{CATS_API_BASE_URL.rstrip('/')}/{endpoint.lstrip('/')}"
    headers = {
        "Authorization": f"Token {CATS_API_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            response = await client.request(
                method=method,
                url=url,
                headers=headers,
                params=params,
                json=json_data,
            )
            response.raise_for_status()
            return response.json() if response.content else {}

        except httpx.HTTPStatusError as e:
            status_code = e.response.status_code
            error_text = e.response.text

            if status_code == 400:
                raise CATSAPIError(f"Bad Request: {error_text}") from e
            elif status_code == 401:
                raise CATSAPIError(
                    "Unauthorized: Invalid API key or expired token"
                ) from e
            elif status_code == 403:
                raise CATSAPIError(
                    f"Forbidden: Insufficient permissions - {error_text}"
                ) from e
            elif status_code == 404:
                raise CATSAPIError(f"Not Found: {error_text}") from e
            elif status_code == 409:
                raise CATSAPIError(f"Conflict: {error_text}") from e
            elif status_code == 429:
                raise CATSAPIError(
                    "Rate Limit Exceeded: Too many requests. Please retry later."
                ) from e
            elif status_code >= 500:
                raise CATSAPIError(
                    f"Server Error: CATS API is experiencing issues ({status_code})"
                ) from e
            else:
                raise CATSAPIError(
                    f"API error: {status_code} - {error_text}"
                ) from e

        except httpx.RequestError as e:
            raise CATSAPIError(f"Request failed: {str(e)}") from e


# ============================================================================
# CANDIDATE MANAGEMENT TOOLS
# ============================================================================


@mcp.tool()
async def list_candidates(
    limit: int = Field(default=20, description="Maximum number of candidates to return"),
    offset: int = Field(default=0, description="Number of candidates to skip"),
    status: Optional[str] = Field(
        default=None, description="Filter by status (active, archived, hired, rejected)"
    ),
    search: Optional[str] = Field(
        default=None, description="Search candidates by name or email"
    ),
    job_id: Optional[int] = Field(
        default=None, description="Filter candidates by job posting ID"
    ),
) -> dict[str, Any]:
    """
    List candidates from CATS system with filtering and pagination.

    Wraps: GET /candidates

    Args:
        limit: Maximum number of candidates to return (default: 20, max: 100)
        offset: Number of candidates to skip for pagination (default: 0)
        status: Filter by candidate status (active, archived, hired, rejected)
        search: Search by candidate name or email address
        job_id: Filter candidates who applied to specific job

    Returns:
        Dictionary containing:
        - candidates: List of candidate objects
        - total: Total number of matching candidates
        - limit: Applied limit
        - offset: Applied offset

    Example:
        >>> await list_candidates(limit=10, status="active")
        {
            "candidates": [...],
            "total": 45,
            "limit": 10,
            "offset": 0
        }
    """
    try:
        params = {"limit": min(limit, 100), "offset": offset}

        if status:
            params["status"] = status
        if search:
            params["search"] = search
        if job_id:
            params["job_id"] = job_id

        result = await make_cats_request("GET", "/candidates", params=params)
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def get_candidate(
    candidate_id: int = Field(description="Unique identifier for the candidate"),
) -> dict[str, Any]:
    """
    Get detailed candidate profile by ID.

    Wraps: GET /candidates/{candidate_id}

    Args:
        candidate_id: Unique identifier for the candidate

    Returns:
        Candidate profile including:
        - id: Candidate ID
        - name: Full name
        - email: Email address
        - phone: Phone number
        - resume_url: URL to resume document
        - applications: List of job applications
        - interviews: Scheduled interviews
        - status: Current status
        - created_at: Registration date
        - updated_at: Last update date

    Example:
        >>> await get_candidate(12345)
        {
            "id": 12345,
            "name": "John Doe",
            "email": "john@example.com",
            ...
        }
    """
    try:
        result = await make_cats_request("GET", f"/candidates/{candidate_id}")
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def create_candidate(
    first_name: str = Field(description="Candidate's first name"),
    last_name: str = Field(description="Candidate's last name"),
    email: str = Field(description="Email address"),
    phone: Optional[str] = Field(default=None, description="Phone number"),
    resume_url: Optional[str] = Field(default=None, description="URL to resume"),
    linkedin_url: Optional[str] = Field(default=None, description="LinkedIn profile URL"),
    source: Optional[str] = Field(
        default=None, description="Source of candidate (e.g., 'referral', 'job_board')"
    ),
    notes: Optional[str] = Field(default=None, description="Additional notes"),
) -> dict[str, Any]:
    """
    Create a new candidate profile in CATS system.

    Wraps: POST /candidates

    Args:
        first_name: Candidate's first name
        last_name: Candidate's last name
        email: Email address (must be unique)
        phone: Phone number (optional)
        resume_url: URL to resume document (optional)
        linkedin_url: LinkedIn profile URL (optional)
        source: Source of candidate (optional)
        notes: Additional notes about candidate (optional)

    Returns:
        Created candidate object with assigned ID

    Example:
        >>> await create_candidate(
        ...     first_name="Jane",
        ...     last_name="Smith",
        ...     email="jane@example.com",
        ...     phone="+1-555-0100"
        ... )
        {"id": 67890, "name": "Jane Smith", ...}
    """
    try:
        payload = {
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
        }

        if phone:
            payload["phone"] = phone
        if resume_url:
            payload["resume_url"] = resume_url
        if linkedin_url:
            payload["linkedin_url"] = linkedin_url
        if source:
            payload["source"] = source
        if notes:
            payload["notes"] = notes

        result = await make_cats_request("POST", "/candidates", json_data=payload)
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def update_candidate(
    candidate_id: int = Field(description="Candidate ID to update"),
    first_name: Optional[str] = Field(default=None, description="Updated first name"),
    last_name: Optional[str] = Field(default=None, description="Updated last name"),
    email: Optional[str] = Field(default=None, description="Updated email"),
    phone: Optional[str] = Field(default=None, description="Updated phone"),
    status: Optional[str] = Field(default=None, description="Updated status"),
    resume_url: Optional[str] = Field(default=None, description="Updated resume URL"),
    linkedin_url: Optional[str] = Field(default=None, description="Updated LinkedIn URL"),
    notes: Optional[str] = Field(default=None, description="Updated notes"),
) -> dict[str, Any]:
    """
    Update existing candidate profile.

    Wraps: PUT /candidates/{candidate_id}

    Args:
        candidate_id: ID of candidate to update
        first_name: Updated first name (optional)
        last_name: Updated last name (optional)
        email: Updated email address (optional)
        phone: Updated phone number (optional)
        status: Updated status (optional)
        resume_url: Updated resume URL (optional)
        linkedin_url: Updated LinkedIn URL (optional)
        notes: Updated notes (optional)

    Returns:
        Updated candidate object

    Example:
        >>> await update_candidate(12345, status="hired", notes="Hired for SWE role")
        {"id": 12345, "status": "hired", ...}
    """
    try:
        payload = {}

        if first_name:
            payload["first_name"] = first_name
        if last_name:
            payload["last_name"] = last_name
        if email:
            payload["email"] = email
        if phone:
            payload["phone"] = phone
        if status:
            payload["status"] = status
        if resume_url:
            payload["resume_url"] = resume_url
        if linkedin_url:
            payload["linkedin_url"] = linkedin_url
        if notes:
            payload["notes"] = notes

        if not payload:
            return {"error": "No fields provided for update", "success": False}

        result = await make_cats_request(
            "PUT", f"/candidates/{candidate_id}", json_data=payload
        )
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def delete_candidate(
    candidate_id: int = Field(description="Candidate ID to delete"),
) -> dict[str, Any]:
    """
    Delete a candidate from the system.

    Wraps: DELETE /candidates/{candidate_id}

    Note: This permanently removes the candidate. Consider archiving instead.

    Args:
        candidate_id: ID of candidate to delete

    Returns:
        Success confirmation

    Example:
        >>> await delete_candidate(12345)
        {"success": True, "message": "Candidate deleted successfully"}
    """
    try:
        result = await make_cats_request("DELETE", f"/candidates/{candidate_id}")
        return {"success": True, "message": "Candidate deleted successfully", **result}

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


# ============================================================================
# JOB MANAGEMENT TOOLS
# ============================================================================


@mcp.tool()
async def list_jobs(
    limit: int = Field(default=20, description="Maximum number of jobs to return"),
    offset: int = Field(default=0, description="Number of jobs to skip"),
    status: Optional[str] = Field(
        default=None, description="Filter by status (draft, open, closed, filled)"
    ),
    department: Optional[str] = Field(
        default=None, description="Filter by department"
    ),
    location: Optional[str] = Field(default=None, description="Filter by location"),
) -> dict[str, Any]:
    """
    List job postings with filtering and pagination.

    Wraps: GET /jobs

    Args:
        limit: Maximum number of jobs to return (default: 20, max: 100)
        offset: Number of jobs to skip for pagination (default: 0)
        status: Filter by job status (draft, open, closed, filled)
        department: Filter by department name
        location: Filter by job location

    Returns:
        Dictionary containing jobs list, total count, and pagination info

    Example:
        >>> await list_jobs(status="open", department="Engineering")
        {
            "jobs": [...],
            "total": 15,
            "limit": 20,
            "offset": 0
        }
    """
    try:
        params = {"limit": min(limit, 100), "offset": offset}

        if status:
            params["status"] = status
        if department:
            params["department"] = department
        if location:
            params["location"] = location

        result = await make_cats_request("GET", "/jobs", params=params)
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def get_job(
    job_id: int = Field(description="Unique identifier for the job posting"),
) -> dict[str, Any]:
    """
    Get detailed job posting by ID.

    Wraps: GET /jobs/{job_id}

    Args:
        job_id: Unique identifier for the job posting

    Returns:
        Job posting details including:
        - id: Job ID
        - title: Job title
        - description: Full job description
        - requirements: Job requirements
        - department: Department name
        - location: Job location
        - salary_range: Salary range (if available)
        - status: Current status
        - applications_count: Number of applications
        - created_at: Posted date
        - updated_at: Last update date

    Example:
        >>> await get_job(5678)
        {
            "id": 5678,
            "title": "Senior Software Engineer",
            ...
        }
    """
    try:
        result = await make_cats_request("GET", f"/jobs/{job_id}")
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def create_job(
    title: str = Field(description="Job title"),
    description: str = Field(description="Full job description"),
    department: str = Field(description="Department name"),
    location: str = Field(description="Job location"),
    employment_type: str = Field(
        default="full-time",
        description="Employment type (full-time, part-time, contract)",
    ),
    experience_level: Optional[str] = Field(
        default=None, description="Required experience level (entry, mid, senior)"
    ),
    salary_min: Optional[int] = Field(default=None, description="Minimum salary"),
    salary_max: Optional[int] = Field(default=None, description="Maximum salary"),
    requirements: Optional[str] = Field(default=None, description="Job requirements"),
    benefits: Optional[str] = Field(default=None, description="Job benefits"),
    status: str = Field(default="draft", description="Initial status (draft or open)"),
) -> dict[str, Any]:
    """
    Create a new job posting.

    Wraps: POST /jobs

    Args:
        title: Job title
        description: Full job description
        department: Department name
        location: Job location
        employment_type: Type of employment (default: full-time)
        experience_level: Required experience level (optional)
        salary_min: Minimum salary (optional)
        salary_max: Maximum salary (optional)
        requirements: Job requirements (optional)
        benefits: Job benefits (optional)
        status: Initial status - draft or open (default: draft)

    Returns:
        Created job posting with assigned ID

    Example:
        >>> await create_job(
        ...     title="Senior Software Engineer",
        ...     description="We are seeking...",
        ...     department="Engineering",
        ...     location="San Francisco, CA"
        ... )
        {"id": 9999, "title": "Senior Software Engineer", ...}
    """
    try:
        payload = {
            "title": title,
            "description": description,
            "department": department,
            "location": location,
            "employment_type": employment_type,
            "status": status,
        }

        if experience_level:
            payload["experience_level"] = experience_level
        if salary_min:
            payload["salary_min"] = salary_min
        if salary_max:
            payload["salary_max"] = salary_max
        if requirements:
            payload["requirements"] = requirements
        if benefits:
            payload["benefits"] = benefits

        result = await make_cats_request("POST", "/jobs", json_data=payload)
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def update_job(
    job_id: int = Field(description="Job ID to update"),
    title: Optional[str] = Field(default=None, description="Updated job title"),
    description: Optional[str] = Field(default=None, description="Updated description"),
    status: Optional[str] = Field(default=None, description="Updated status"),
    location: Optional[str] = Field(default=None, description="Updated location"),
    salary_min: Optional[int] = Field(default=None, description="Updated min salary"),
    salary_max: Optional[int] = Field(default=None, description="Updated max salary"),
    requirements: Optional[str] = Field(default=None, description="Updated requirements"),
) -> dict[str, Any]:
    """
    Update existing job posting.

    Wraps: PUT /jobs/{job_id}

    Args:
        job_id: ID of job to update
        title: Updated job title (optional)
        description: Updated description (optional)
        status: Updated status (optional)
        location: Updated location (optional)
        salary_min: Updated minimum salary (optional)
        salary_max: Updated maximum salary (optional)
        requirements: Updated requirements (optional)

    Returns:
        Updated job posting object

    Example:
        >>> await update_job(5678, status="open", salary_max=180000)
        {"id": 5678, "status": "open", "salary_max": 180000, ...}
    """
    try:
        payload = {}

        if title:
            payload["title"] = title
        if description:
            payload["description"] = description
        if status:
            payload["status"] = status
        if location:
            payload["location"] = location
        if salary_min is not None:
            payload["salary_min"] = salary_min
        if salary_max is not None:
            payload["salary_max"] = salary_max
        if requirements:
            payload["requirements"] = requirements

        if not payload:
            return {"error": "No fields provided for update", "success": False}

        result = await make_cats_request("PUT", f"/jobs/{job_id}", json_data=payload)
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def delete_job(
    job_id: int = Field(description="Job ID to delete"),
) -> dict[str, Any]:
    """
    Delete a job posting.

    Wraps: DELETE /jobs/{job_id}

    Note: This permanently removes the job posting. Consider closing instead.

    Args:
        job_id: ID of job to delete

    Returns:
        Success confirmation

    Example:
        >>> await delete_job(5678)
        {"success": True, "message": "Job deleted successfully"}
    """
    try:
        result = await make_cats_request("DELETE", f"/jobs/{job_id}")
        return {"success": True, "message": "Job deleted successfully", **result}

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


# ============================================================================
# APPLICATION MANAGEMENT TOOLS
# ============================================================================


@mcp.tool()
async def list_applications(
    limit: int = Field(default=20, description="Maximum number of applications to return"),
    offset: int = Field(default=0, description="Number of applications to skip"),
    job_id: Optional[int] = Field(default=None, description="Filter by job ID"),
    candidate_id: Optional[int] = Field(
        default=None, description="Filter by candidate ID"
    ),
    status: Optional[str] = Field(
        default=None,
        description="Filter by status (submitted, reviewing, interview, offer, etc.)",
    ),
) -> dict[str, Any]:
    """
    List job applications with filtering and pagination.

    Wraps: GET /applications

    Args:
        limit: Maximum number of applications to return (default: 20, max: 100)
        offset: Number of applications to skip for pagination (default: 0)
        job_id: Filter by specific job posting
        candidate_id: Filter by specific candidate
        status: Filter by application status

    Returns:
        Dictionary containing applications list, total count, and pagination info

    Example:
        >>> await list_applications(job_id=5678, status="interview")
        {
            "applications": [...],
            "total": 8,
            "limit": 20,
            "offset": 0
        }
    """
    try:
        params = {"limit": min(limit, 100), "offset": offset}

        if job_id:
            params["job_id"] = job_id
        if candidate_id:
            params["candidate_id"] = candidate_id
        if status:
            params["status"] = status

        result = await make_cats_request("GET", "/applications", params=params)
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def get_application(
    application_id: int = Field(description="Unique identifier for the application"),
) -> dict[str, Any]:
    """
    Get detailed application information by ID.

    Wraps: GET /applications/{application_id}

    Args:
        application_id: Unique identifier for the application

    Returns:
        Application details including candidate info, job info, status, and timeline

    Example:
        >>> await get_application(11111)
        {
            "id": 11111,
            "candidate": {...},
            "job": {...},
            "status": "interview",
            ...
        }
    """
    try:
        result = await make_cats_request("GET", f"/applications/{application_id}")
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def create_application(
    candidate_id: int = Field(description="ID of the candidate"),
    job_id: int = Field(description="ID of the job posting"),
    cover_letter: Optional[str] = Field(
        default=None, description="Cover letter text"
    ),
    referral_source: Optional[str] = Field(
        default=None, description="How candidate heard about position"
    ),
) -> dict[str, Any]:
    """
    Submit a new job application.

    Wraps: POST /applications

    Args:
        candidate_id: ID of the candidate applying
        job_id: ID of the job posting
        cover_letter: Cover letter text (optional)
        referral_source: How candidate heard about position (optional)

    Returns:
        Created application object with assigned ID

    Example:
        >>> await create_application(
        ...     candidate_id=12345,
        ...     job_id=5678,
        ...     cover_letter="I am excited to apply..."
        ... )
        {"id": 22222, "status": "submitted", ...}
    """
    try:
        payload = {
            "candidate_id": candidate_id,
            "job_id": job_id,
        }

        if cover_letter:
            payload["cover_letter"] = cover_letter
        if referral_source:
            payload["referral_source"] = referral_source

        result = await make_cats_request("POST", "/applications", json_data=payload)
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def update_application_status(
    application_id: int = Field(description="Application ID to update"),
    status: str = Field(
        description="New status (submitted, reviewing, interview, offer, accepted, rejected)"
    ),
    notes: Optional[str] = Field(
        default=None, description="Notes about the status change"
    ),
) -> dict[str, Any]:
    """
    Update application status.

    Wraps: PUT /applications/{application_id}/status

    Args:
        application_id: ID of application to update
        status: New status (submitted, reviewing, interview, offer, accepted, rejected)
        notes: Optional notes about the status change

    Returns:
        Updated application object

    Example:
        >>> await update_application_status(
        ...     11111,
        ...     "interview",
        ...     "Moving to technical interview round"
        ... )
        {"id": 11111, "status": "interview", ...}
    """
    try:
        payload = {"status": status}

        if notes:
            payload["notes"] = notes

        result = await make_cats_request(
            "PUT", f"/applications/{application_id}/status", json_data=payload
        )
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def withdraw_application(
    application_id: int = Field(description="Application ID to withdraw"),
    reason: Optional[str] = Field(default=None, description="Reason for withdrawal"),
) -> dict[str, Any]:
    """
    Withdraw a job application.

    Wraps: POST /applications/{application_id}/withdraw

    Args:
        application_id: ID of application to withdraw
        reason: Optional reason for withdrawal

    Returns:
        Updated application with withdrawn status

    Example:
        >>> await withdraw_application(11111, "Accepted another offer")
        {"id": 11111, "status": "withdrawn", ...}
    """
    try:
        payload = {}
        if reason:
            payload["reason"] = reason

        result = await make_cats_request(
            "POST", f"/applications/{application_id}/withdraw", json_data=payload
        )
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


# ============================================================================
# INTERVIEW MANAGEMENT TOOLS
# ============================================================================


@mcp.tool()
async def list_interviews(
    limit: int = Field(default=20, description="Maximum number of interviews to return"),
    offset: int = Field(default=0, description="Number of interviews to skip"),
    application_id: Optional[int] = Field(
        default=None, description="Filter by application ID"
    ),
    candidate_id: Optional[int] = Field(
        default=None, description="Filter by candidate ID"
    ),
    status: Optional[str] = Field(
        default=None, description="Filter by status (scheduled, completed, cancelled)"
    ),
    interviewer_id: Optional[int] = Field(
        default=None, description="Filter by interviewer ID"
    ),
) -> dict[str, Any]:
    """
    List scheduled interviews with filtering and pagination.

    Wraps: GET /interviews

    Args:
        limit: Maximum number of interviews to return (default: 20, max: 100)
        offset: Number of interviews to skip for pagination (default: 0)
        application_id: Filter by specific application
        candidate_id: Filter by specific candidate
        status: Filter by interview status
        interviewer_id: Filter by specific interviewer

    Returns:
        Dictionary containing interviews list, total count, and pagination info

    Example:
        >>> await list_interviews(status="scheduled", limit=10)
        {
            "interviews": [...],
            "total": 5,
            "limit": 10,
            "offset": 0
        }
    """
    try:
        params = {"limit": min(limit, 100), "offset": offset}

        if application_id:
            params["application_id"] = application_id
        if candidate_id:
            params["candidate_id"] = candidate_id
        if status:
            params["status"] = status
        if interviewer_id:
            params["interviewer_id"] = interviewer_id

        result = await make_cats_request("GET", "/interviews", params=params)
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def get_interview(
    interview_id: int = Field(description="Unique identifier for the interview"),
) -> dict[str, Any]:
    """
    Get detailed interview information by ID.

    Wraps: GET /interviews/{interview_id}

    Args:
        interview_id: Unique identifier for the interview

    Returns:
        Interview details including candidate, interviewers, schedule, and feedback

    Example:
        >>> await get_interview(33333)
        {
            "id": 33333,
            "candidate": {...},
            "scheduled_at": "2025-11-01T14:00:00Z",
            ...
        }
    """
    try:
        result = await make_cats_request("GET", f"/interviews/{interview_id}")
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def schedule_interview(
    application_id: int = Field(description="ID of the application"),
    scheduled_at: str = Field(
        description="Interview datetime in ISO 8601 format (e.g., '2025-11-01T14:00:00Z')"
    ),
    duration_minutes: int = Field(
        default=60, description="Interview duration in minutes"
    ),
    interview_type: str = Field(
        default="technical",
        description="Type of interview (phone, technical, behavioral, onsite)",
    ),
    interviewer_ids: list[int] = Field(
        default_factory=list, description="List of interviewer user IDs"
    ),
    location: Optional[str] = Field(
        default=None, description="Interview location or video call link"
    ),
    notes: Optional[str] = Field(default=None, description="Additional notes"),
) -> dict[str, Any]:
    """
    Schedule a new interview.

    Wraps: POST /interviews

    Args:
        application_id: ID of the application
        scheduled_at: Interview datetime in ISO 8601 format
        duration_minutes: Interview duration in minutes (default: 60)
        interview_type: Type of interview (phone, technical, behavioral, onsite)
        interviewer_ids: List of interviewer user IDs
        location: Interview location or video call link (optional)
        notes: Additional notes about the interview (optional)

    Returns:
        Created interview object with assigned ID

    Example:
        >>> await schedule_interview(
        ...     application_id=11111,
        ...     scheduled_at="2025-11-01T14:00:00Z",
        ...     interview_type="technical",
        ...     interviewer_ids=[101, 102],
        ...     location="https://zoom.us/j/123456"
        ... )
        {"id": 44444, "status": "scheduled", ...}
    """
    try:
        payload = {
            "application_id": application_id,
            "scheduled_at": scheduled_at,
            "duration_minutes": duration_minutes,
            "interview_type": interview_type,
            "interviewer_ids": interviewer_ids,
        }

        if location:
            payload["location"] = location
        if notes:
            payload["notes"] = notes

        result = await make_cats_request("POST", "/interviews", json_data=payload)
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def update_interview(
    interview_id: int = Field(description="Interview ID to update"),
    scheduled_at: Optional[str] = Field(
        default=None, description="Updated interview datetime"
    ),
    status: Optional[str] = Field(default=None, description="Updated status"),
    location: Optional[str] = Field(default=None, description="Updated location"),
    notes: Optional[str] = Field(default=None, description="Updated notes"),
) -> dict[str, Any]:
    """
    Update interview details.

    Wraps: PUT /interviews/{interview_id}

    Args:
        interview_id: ID of interview to update
        scheduled_at: Updated interview datetime (optional)
        status: Updated status (scheduled, completed, cancelled, rescheduled)
        location: Updated location or video link (optional)
        notes: Updated notes (optional)

    Returns:
        Updated interview object

    Example:
        >>> await update_interview(
        ...     33333,
        ...     scheduled_at="2025-11-02T10:00:00Z",
        ...     status="rescheduled"
        ... )
        {"id": 33333, "status": "rescheduled", ...}
    """
    try:
        payload = {}

        if scheduled_at:
            payload["scheduled_at"] = scheduled_at
        if status:
            payload["status"] = status
        if location:
            payload["location"] = location
        if notes:
            payload["notes"] = notes

        if not payload:
            return {"error": "No fields provided for update", "success": False}

        result = await make_cats_request(
            "PUT", f"/interviews/{interview_id}", json_data=payload
        )
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def cancel_interview(
    interview_id: int = Field(description="Interview ID to cancel"),
    reason: Optional[str] = Field(default=None, description="Cancellation reason"),
) -> dict[str, Any]:
    """
    Cancel a scheduled interview.

    Wraps: POST /interviews/{interview_id}/cancel

    Args:
        interview_id: ID of interview to cancel
        reason: Optional reason for cancellation

    Returns:
        Updated interview with cancelled status

    Example:
        >>> await cancel_interview(33333, "Candidate no longer available")
        {"id": 33333, "status": "cancelled", ...}
    """
    try:
        payload = {}
        if reason:
            payload["reason"] = reason

        result = await make_cats_request(
            "POST", f"/interviews/{interview_id}/cancel", json_data=payload
        )
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


@mcp.tool()
async def submit_interview_feedback(
    interview_id: int = Field(description="Interview ID"),
    interviewer_id: int = Field(description="ID of the interviewer submitting feedback"),
    rating: int = Field(description="Rating (1-5 scale)", ge=1, le=5),
    feedback: str = Field(description="Detailed feedback text"),
    recommendation: str = Field(
        description="Recommendation (hire, no_hire, maybe, strong_hire)"
    ),
    strengths: Optional[str] = Field(default=None, description="Candidate strengths"),
    weaknesses: Optional[str] = Field(default=None, description="Areas for improvement"),
) -> dict[str, Any]:
    """
    Submit feedback for a completed interview.

    Wraps: POST /interviews/{interview_id}/feedback

    Args:
        interview_id: ID of the interview
        interviewer_id: ID of interviewer submitting feedback
        rating: Overall rating on 1-5 scale
        feedback: Detailed feedback text
        recommendation: Hiring recommendation (hire, no_hire, maybe, strong_hire)
        strengths: Candidate strengths (optional)
        weaknesses: Areas for improvement (optional)

    Returns:
        Created feedback object

    Example:
        >>> await submit_interview_feedback(
        ...     interview_id=33333,
        ...     interviewer_id=101,
        ...     rating=4,
        ...     feedback="Strong technical skills...",
        ...     recommendation="hire"
        ... )
        {"id": 55555, "interview_id": 33333, ...}
    """
    try:
        payload = {
            "interviewer_id": interviewer_id,
            "rating": rating,
            "feedback": feedback,
            "recommendation": recommendation,
        }

        if strengths:
            payload["strengths"] = strengths
        if weaknesses:
            payload["weaknesses"] = weaknesses

        result = await make_cats_request(
            "POST", f"/interviews/{interview_id}/feedback", json_data=payload
        )
        return result

    except CATSAPIError as e:
        return {"error": str(e), "success": False}


# ============================================================================
# SERVER CONFIGURATION AND RESOURCES
# ============================================================================


@mcp.resource("config://settings")
def get_server_settings() -> dict[str, Any]:
    """
    Get CATS MCP server configuration and status.

    Returns server settings without exposing sensitive credentials.
    """
    return {
        "server_name": "CATS API Server",
        "version": "1.0.0",
        "api_configured": bool(CATS_API_BASE_URL and CATS_API_KEY),
        "api_base_url": CATS_API_BASE_URL if CATS_API_BASE_URL else "Not configured",
        "transport": "HTTP",
        "tools": {
            "candidates": [
                "list_candidates",
                "get_candidate",
                "create_candidate",
                "update_candidate",
                "delete_candidate",
            ],
            "jobs": [
                "list_jobs",
                "get_job",
                "create_job",
                "update_job",
                "delete_job",
            ],
            "applications": [
                "list_applications",
                "get_application",
                "create_application",
                "update_application_status",
                "withdraw_application",
            ],
            "interviews": [
                "list_interviews",
                "get_interview",
                "schedule_interview",
                "update_interview",
                "cancel_interview",
                "submit_interview_feedback",
            ],
        },
        "total_tools": 20,
    }


# ============================================================================
# SERVER STARTUP
# ============================================================================

if __name__ == "__main__":
    # Run server with HTTP transport
    # Default: http://localhost:8000
    mcp.run(transport="http")
