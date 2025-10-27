"""
CATS MCP Server - Default Toolsets
Comprehensive toolset registration functions for candidates, jobs, pipelines, context, and tasks.
Based on CATS API v3: https://api.catsone.com/v3
"""

from typing import Any, Optional
from fastmcp import FastMCP


# ============================================================================
# HELPER: Will be imported from server.py
# ============================================================================
# async def make_request(method: str, endpoint: str, params: dict = None, json_data: dict = None) -> dict:
#     """Make authenticated request to CATS API"""
#     pass


# ============================================================================
# TOOLSET 1: CANDIDATES (28 tools)
# ============================================================================

def register_candidates_tools(mcp: FastMCP, make_request):
    """Register all candidate management tools"""

    # ========== MAIN CANDIDATE OPERATIONS ==========

    @mcp.tool()
    async def list_candidates(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all candidates with pagination.
        Wraps: GET /candidates

        Args:
            per_page: Number of results per page (default: 25)
            page: Page number to retrieve (default: 1)

        Returns:
            dict: List of candidates with pagination metadata
        """
        return await make_request("GET", "/candidates", params={"per_page": per_page, "page": page})


    @mcp.tool()
    async def get_candidate(candidate_id: int) -> dict[str, Any]:
        """
        Get detailed information about a specific candidate.
        Wraps: GET /candidates/{id}

        Args:
            candidate_id: The unique identifier of the candidate

        Returns:
            dict: Complete candidate profile with applications and interviews
        """
        return await make_request("GET", f"/candidates/{candidate_id}")


    @mcp.tool()
    async def create_candidate(
        first_name: str,
        last_name: str,
        email: str,
        phone: Optional[str] = None,
        resume_url: Optional[str] = None,
        linkedin_url: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Create a new candidate in the system.
        Wraps: POST /candidates

        Args:
            first_name: Candidate's first name
            last_name: Candidate's last name
            email: Email address
            phone: Phone number (optional)
            resume_url: URL to resume document (optional)
            linkedin_url: LinkedIn profile URL (optional)

        Returns:
            dict: Created candidate object with ID
        """
        payload = {
            "first_name": first_name,
            "last_name": last_name,
            "email": email
        }
        if phone:
            payload["phone"] = phone
        if resume_url:
            payload["resume_url"] = resume_url
        if linkedin_url:
            payload["linkedin_url"] = linkedin_url

        return await make_request("POST", "/candidates", json_data=payload)


    @mcp.tool()
    async def update_candidate(
        candidate_id: int,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        email: Optional[str] = None,
        phone: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Update an existing candidate's information.
        Wraps: PUT /candidates/{id}

        Args:
            candidate_id: The unique identifier of the candidate
            first_name: Updated first name (optional)
            last_name: Updated last name (optional)
            email: Updated email address (optional)
            phone: Updated phone number (optional)

        Returns:
            dict: Updated candidate object
        """
        payload = {}
        if first_name:
            payload["first_name"] = first_name
        if last_name:
            payload["last_name"] = last_name
        if email:
            payload["email"] = email
        if phone:
            payload["phone"] = phone

        return await make_request("PUT", f"/candidates/{candidate_id}", json_data=payload)


    @mcp.tool()
    async def delete_candidate(candidate_id: int) -> dict[str, Any]:
        """
        Permanently delete a candidate from the system.
        Wraps: DELETE /candidates/{id}

        WARNING: This is permanent. Consider archiving instead.

        Args:
            candidate_id: The unique identifier of the candidate

        Returns:
            dict: Confirmation of deletion
        """
        return await make_request("DELETE", f"/candidates/{candidate_id}")


    @mcp.tool()
    async def search_candidates(query: str, per_page: int = 25) -> dict[str, Any]:
        """
        Search candidates by name, email, or other fields.
        Wraps: GET /candidates/search

        Args:
            query: Search query string
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of matching candidates
        """
        return await make_request("GET", "/candidates/search", params={"q": query, "per_page": per_page})


    @mcp.tool()
    async def filter_candidates(
        status: Optional[str] = None,
        job_id: Optional[int] = None,
        per_page: int = 25,
        page: int = 1
    ) -> dict[str, Any]:
        """
        Filter candidates with advanced criteria.
        Wraps: POST /candidates/search

        Args:
            status: Filter by candidate status (optional)
            job_id: Filter by specific job ID (optional)
            per_page: Number of results per page (default: 25)
            page: Page number to retrieve (default: 1)

        Returns:
            dict: List of filtered candidates
        """
        payload = {}
        if status:
            payload["status"] = status
        if job_id:
            payload["job_id"] = job_id

        params = {"per_page": per_page, "page": page}
        return await make_request("POST", "/candidates/search", params=params, json_data=payload)


    @mcp.tool()
    async def authorize_candidate(candidate_id: int, action: str) -> dict[str, Any]:
        """
        Authorize a candidate action (e.g., portal access).
        Wraps: POST /candidates/authorization

        Args:
            candidate_id: The unique identifier of the candidate
            action: The authorization action to perform

        Returns:
            dict: Authorization result
        """
        payload = {"candidate_id": candidate_id, "action": action}
        return await make_request("POST", "/candidates/authorization", json_data=payload)


    # ========== CANDIDATE SUB-RESOURCES ==========

    @mcp.tool()
    async def list_candidate_pipelines(candidate_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all pipelines associated with a candidate.
        Wraps: GET /candidates/{id}/pipelines

        Args:
            candidate_id: The unique identifier of the candidate
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of candidate's pipelines
        """
        return await make_request("GET", f"/candidates/{candidate_id}/pipelines",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def list_candidate_activities(candidate_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all activities for a candidate.
        Wraps: GET /candidates/{id}/activities

        Args:
            candidate_id: The unique identifier of the candidate
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of candidate activities
        """
        return await make_request("GET", f"/candidates/{candidate_id}/activities",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def create_candidate_activity(
        candidate_id: int,
        activity_type: str,
        description: str,
        date: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Create a new activity for a candidate.
        Wraps: POST /activities (with candidate_id)

        Args:
            candidate_id: The unique identifier of the candidate
            activity_type: Type of activity (e.g., 'meeting_scheduled', 'email_sent')
            description: Description of the activity
            date: Activity date in ISO format (optional)

        Returns:
            dict: Created activity object
        """
        payload = {
            "candidate_id": candidate_id,
            "type": activity_type,
            "description": description
        }
        if date:
            payload["date"] = date

        return await make_request("POST", "/activities", json_data=payload)


    @mcp.tool()
    async def list_candidate_attachments(candidate_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all attachments for a candidate (resume, cover letter, etc).
        Wraps: GET /candidates/{id}/attachments

        Args:
            candidate_id: The unique identifier of the candidate
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of candidate attachments
        """
        return await make_request("GET", f"/candidates/{candidate_id}/attachments",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def upload_candidate_attachment(
        candidate_id: int,
        file_name: str,
        file_type: str,
        file_url: str
    ) -> dict[str, Any]:
        """
        Upload an attachment for a candidate.
        Wraps: POST /attachments

        Args:
            candidate_id: The unique identifier of the candidate
            file_name: Name of the file
            file_type: Type of file (e.g., 'resume', 'cover_letter')
            file_url: URL to the file to upload

        Returns:
            dict: Created attachment object
        """
        payload = {
            "candidate_id": candidate_id,
            "file_name": file_name,
            "file_type": file_type,
            "file_url": file_url
        }
        return await make_request("POST", "/attachments", json_data=payload)


    @mcp.tool()
    async def list_candidate_custom_fields(candidate_id: int) -> dict[str, Any]:
        """
        Get all custom fields for a candidate.
        Wraps: GET /candidates/{id}/custom_fields

        Args:
            candidate_id: The unique identifier of the candidate

        Returns:
            dict: Candidate's custom field values
        """
        return await make_request("GET", f"/candidates/{candidate_id}/custom_fields")


    @mcp.tool()
    async def list_candidate_emails(candidate_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all email addresses for a candidate.
        Wraps: GET /candidates/{id}/emails

        Args:
            candidate_id: The unique identifier of the candidate
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of candidate email addresses
        """
        return await make_request("GET", f"/candidates/{candidate_id}/emails",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def create_candidate_email(
        candidate_id: int,
        email: str,
        email_type: str = "personal"
    ) -> dict[str, Any]:
        """
        Add a new email address for a candidate.
        Wraps: POST /candidates/{id}/emails

        Args:
            candidate_id: The unique identifier of the candidate
            email: Email address to add
            email_type: Type of email (e.g., 'personal', 'work') (default: 'personal')

        Returns:
            dict: Created email object
        """
        payload = {"email": email, "type": email_type}
        return await make_request("POST", f"/candidates/{candidate_id}/emails", json_data=payload)


    @mcp.tool()
    async def update_candidate_email(
        candidate_id: int,
        email_id: int,
        email: str,
        email_type: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Update a candidate's email address.
        Wraps: PUT /emails/{id}

        Args:
            candidate_id: The unique identifier of the candidate
            email_id: The unique identifier of the email
            email: Updated email address
            email_type: Updated email type (optional)

        Returns:
            dict: Updated email object
        """
        payload = {"email": email, "candidate_id": candidate_id}
        if email_type:
            payload["type"] = email_type

        return await make_request("PUT", f"/emails/{email_id}", json_data=payload)


    @mcp.tool()
    async def delete_candidate_email(email_id: int) -> dict[str, Any]:
        """
        Delete a candidate's email address.
        Wraps: DELETE /emails/{id}

        Args:
            email_id: The unique identifier of the email to delete

        Returns:
            dict: Confirmation of deletion
        """
        return await make_request("DELETE", f"/emails/{email_id}")


    @mcp.tool()
    async def list_candidate_phones(candidate_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all phone numbers for a candidate.
        Wraps: GET /candidates/{id}/phones

        Args:
            candidate_id: The unique identifier of the candidate
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of candidate phone numbers
        """
        return await make_request("GET", f"/candidates/{candidate_id}/phones",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def create_candidate_phone(
        candidate_id: int,
        phone: str,
        phone_type: str = "mobile"
    ) -> dict[str, Any]:
        """
        Add a new phone number for a candidate.
        Wraps: POST /phones

        Args:
            candidate_id: The unique identifier of the candidate
            phone: Phone number to add
            phone_type: Type of phone (e.g., 'mobile', 'home', 'work') (default: 'mobile')

        Returns:
            dict: Created phone object
        """
        payload = {
            "candidate_id": candidate_id,
            "phone": phone,
            "type": phone_type
        }
        return await make_request("POST", "/phones", json_data=payload)


    @mcp.tool()
    async def update_candidate_phone(
        phone_id: int,
        phone: str,
        phone_type: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Update a candidate's phone number.
        Wraps: PUT /phones/{id}

        Args:
            phone_id: The unique identifier of the phone
            phone: Updated phone number
            phone_type: Updated phone type (optional)

        Returns:
            dict: Updated phone object
        """
        payload = {"phone": phone}
        if phone_type:
            payload["type"] = phone_type

        return await make_request("PUT", f"/phones/{phone_id}", json_data=payload)


    @mcp.tool()
    async def delete_candidate_phone(phone_id: int) -> dict[str, Any]:
        """
        Delete a candidate's phone number.
        Wraps: DELETE /phones/{id}

        Args:
            phone_id: The unique identifier of the phone to delete

        Returns:
            dict: Confirmation of deletion
        """
        return await make_request("DELETE", f"/phones/{phone_id}")


    @mcp.tool()
    async def list_candidate_tags(candidate_id: int) -> dict[str, Any]:
        """
        List all tags assigned to a candidate.
        Wraps: GET /candidates/{id}/tags

        Args:
            candidate_id: The unique identifier of the candidate

        Returns:
            dict: List of candidate tags
        """
        return await make_request("GET", f"/candidates/{candidate_id}/tags")


    @mcp.tool()
    async def replace_candidate_tags(candidate_id: int, tag_ids: list[int]) -> dict[str, Any]:
        """
        Replace all tags for a candidate (removes existing, adds new).
        Wraps: PUT /candidates/{id}/tags

        Args:
            candidate_id: The unique identifier of the candidate
            tag_ids: List of tag IDs to assign

        Returns:
            dict: Updated list of candidate tags
        """
        payload = {"tag_ids": tag_ids}
        return await make_request("PUT", f"/candidates/{candidate_id}/tags", json_data=payload)


    @mcp.tool()
    async def attach_candidate_tags(candidate_id: int, tag_ids: list[int]) -> dict[str, Any]:
        """
        Add tags to a candidate (keeps existing tags).
        Wraps: POST /candidates/{id}/tags

        Args:
            candidate_id: The unique identifier of the candidate
            tag_ids: List of tag IDs to add

        Returns:
            dict: Updated list of candidate tags
        """
        payload = {"tag_ids": tag_ids}
        return await make_request("POST", f"/candidates/{candidate_id}/tags", json_data=payload)


    @mcp.tool()
    async def delete_candidate_tag(candidate_id: int, tag_id: int) -> dict[str, Any]:
        """
        Remove a specific tag from a candidate.
        Wraps: DELETE /candidates/{id}/tags

        Args:
            candidate_id: The unique identifier of the candidate
            tag_id: The unique identifier of the tag to remove

        Returns:
            dict: Confirmation of tag removal
        """
        payload = {"tag_id": tag_id}
        return await make_request("DELETE", f"/candidates/{candidate_id}/tags", json_data=payload)


    @mcp.tool()
    async def list_candidate_work_history(candidate_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all work history entries for a candidate.
        Wraps: GET /candidates/{id}/work_history

        Args:
            candidate_id: The unique identifier of the candidate
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of work history entries
        """
        return await make_request("GET", f"/candidates/{candidate_id}/work_history",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def create_candidate_work_history(
        candidate_id: int,
        company: str,
        title: str,
        start_date: str,
        end_date: Optional[str] = None,
        description: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Add a work history entry for a candidate.
        Wraps: POST /candidates/{id}/work_history

        Args:
            candidate_id: The unique identifier of the candidate
            company: Company name
            title: Job title
            start_date: Start date in ISO format (YYYY-MM-DD)
            end_date: End date in ISO format (optional, null for current)
            description: Job description (optional)

        Returns:
            dict: Created work history object
        """
        payload = {
            "company": company,
            "title": title,
            "start_date": start_date
        }
        if end_date:
            payload["end_date"] = end_date
        if description:
            payload["description"] = description

        return await make_request("POST", f"/candidates/{candidate_id}/work_history", json_data=payload)


# ============================================================================
# TOOLSET 2: JOBS (40 tools)
# ============================================================================

def register_jobs_tools(mcp: FastMCP, make_request):
    """Register all job management tools"""

    # ========== MAIN JOB OPERATIONS ==========

    @mcp.tool()
    async def list_jobs(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all jobs with pagination.
        Wraps: GET /jobs

        Args:
            per_page: Number of results per page (default: 25)
            page: Page number to retrieve (default: 1)

        Returns:
            dict: List of jobs with pagination metadata
        """
        return await make_request("GET", "/jobs", params={"per_page": per_page, "page": page})


    @mcp.tool()
    async def get_job(job_id: int) -> dict[str, Any]:
        """
        Get detailed information about a specific job.
        Wraps: GET /jobs/{id}

        Args:
            job_id: The unique identifier of the job

        Returns:
            dict: Complete job details with application counts
        """
        return await make_request("GET", f"/jobs/{job_id}")


    @mcp.tool()
    async def create_job(
        title: str,
        description: str,
        department: Optional[str] = None,
        location: Optional[str] = None,
        employment_type: str = "full-time",
        salary_min: Optional[int] = None,
        salary_max: Optional[int] = None
    ) -> dict[str, Any]:
        """
        Create a new job posting.
        Wraps: POST /jobs

        Args:
            title: Job title
            description: Job description
            department: Department name (optional)
            location: Job location (optional)
            employment_type: Type of employment (default: 'full-time')
            salary_min: Minimum salary (optional)
            salary_max: Maximum salary (optional)

        Returns:
            dict: Created job object with ID
        """
        payload = {
            "title": title,
            "description": description,
            "employment_type": employment_type
        }
        if department:
            payload["department"] = department
        if location:
            payload["location"] = location
        if salary_min:
            payload["salary_min"] = salary_min
        if salary_max:
            payload["salary_max"] = salary_max

        return await make_request("POST", "/jobs", json_data=payload)


    @mcp.tool()
    async def update_job(
        job_id: int,
        title: Optional[str] = None,
        description: Optional[str] = None,
        status: Optional[str] = None,
        location: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Update an existing job posting.
        Wraps: PUT /jobs/{id}

        Args:
            job_id: The unique identifier of the job
            title: Updated job title (optional)
            description: Updated job description (optional)
            status: Updated job status (optional)
            location: Updated job location (optional)

        Returns:
            dict: Updated job object
        """
        payload = {}
        if title:
            payload["title"] = title
        if description:
            payload["description"] = description
        if status:
            payload["status"] = status
        if location:
            payload["location"] = location

        return await make_request("PUT", f"/jobs/{job_id}", json_data=payload)


    @mcp.tool()
    async def delete_job(job_id: int) -> dict[str, Any]:
        """
        Permanently delete a job posting.
        Wraps: DELETE /jobs/{id}

        WARNING: This is permanent. Consider closing the job instead.

        Args:
            job_id: The unique identifier of the job

        Returns:
            dict: Confirmation of deletion
        """
        return await make_request("DELETE", f"/jobs/{job_id}")


    @mcp.tool()
    async def search_jobs(query: str, per_page: int = 25) -> dict[str, Any]:
        """
        Search jobs by title, description, or other fields.
        Wraps: GET /jobs/search

        Args:
            query: Search query string
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of matching jobs
        """
        return await make_request("GET", "/jobs/search", params={"q": query, "per_page": per_page})


    @mcp.tool()
    async def filter_jobs(
        status: Optional[str] = None,
        department: Optional[str] = None,
        location: Optional[str] = None,
        per_page: int = 25,
        page: int = 1
    ) -> dict[str, Any]:
        """
        Filter jobs with advanced criteria.
        Wraps: POST /jobs/search

        Args:
            status: Filter by job status (optional)
            department: Filter by department (optional)
            location: Filter by location (optional)
            per_page: Number of results per page (default: 25)
            page: Page number to retrieve (default: 1)

        Returns:
            dict: List of filtered jobs
        """
        payload = {}
        if status:
            payload["status"] = status
        if department:
            payload["department"] = department
        if location:
            payload["location"] = location

        params = {"per_page": per_page, "page": page}
        return await make_request("POST", "/jobs/search", params=params, json_data=payload)


    # ========== JOB SUB-RESOURCES ==========

    @mcp.tool()
    async def list_job_pipelines(job_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all pipelines for a job.
        Wraps: GET /jobs/{id}/pipelines

        Args:
            job_id: The unique identifier of the job
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of job pipelines
        """
        return await make_request("GET", f"/jobs/{job_id}/pipelines",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def list_job_candidates(job_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all candidates who applied to a job.
        Wraps: GET /jobs/{id}/candidates

        Args:
            job_id: The unique identifier of the job
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of candidates for the job
        """
        return await make_request("GET", f"/jobs/{job_id}/candidates",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def list_job_activities(job_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all activities for a job.
        Wraps: GET /jobs/{id}/activities

        Args:
            job_id: The unique identifier of the job
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of job activities
        """
        return await make_request("GET", f"/jobs/{job_id}/activities",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def list_job_attachments(job_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all attachments for a job.
        Wraps: GET /jobs/{id}/attachments

        Args:
            job_id: The unique identifier of the job
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of job attachments
        """
        return await make_request("GET", f"/jobs/{job_id}/attachments",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def list_job_custom_fields(job_id: int) -> dict[str, Any]:
        """
        Get all custom fields for a job.
        Wraps: GET /jobs/{id}/custom_fields

        Args:
            job_id: The unique identifier of the job

        Returns:
            dict: Job's custom field values
        """
        return await make_request("GET", f"/jobs/{job_id}/custom_fields")


    @mcp.tool()
    async def update_job_custom_fields(job_id: int, fields: dict[str, Any]) -> dict[str, Any]:
        """
        Update custom fields for a job.
        Wraps: PUT /jobs/{id}/custom_fields

        Args:
            job_id: The unique identifier of the job
            fields: Dictionary of custom field key-value pairs

        Returns:
            dict: Updated custom fields
        """
        return await make_request("PUT", f"/jobs/{job_id}/custom_fields", json_data=fields)


    @mcp.tool()
    async def list_job_tags(job_id: int) -> dict[str, Any]:
        """
        List all tags assigned to a job.
        Wraps: GET /jobs/{id}/tags

        Args:
            job_id: The unique identifier of the job

        Returns:
            dict: List of job tags
        """
        return await make_request("GET", f"/jobs/{job_id}/tags")


    @mcp.tool()
    async def attach_job_tags(job_id: int, tag_ids: list[int]) -> dict[str, Any]:
        """
        Add tags to a job (keeps existing tags).
        Wraps: POST /jobs/{id}/tags

        Args:
            job_id: The unique identifier of the job
            tag_ids: List of tag IDs to add

        Returns:
            dict: Updated list of job tags
        """
        payload = {"tag_ids": tag_ids}
        return await make_request("POST", f"/jobs/{job_id}/tags", json_data=payload)


    @mcp.tool()
    async def delete_job_tag(job_id: int, tag_id: int) -> dict[str, Any]:
        """
        Remove a specific tag from a job.
        Wraps: DELETE /jobs/{id}/tags

        Args:
            job_id: The unique identifier of the job
            tag_id: The unique identifier of the tag to remove

        Returns:
            dict: Confirmation of tag removal
        """
        payload = {"tag_id": tag_id}
        return await make_request("DELETE", f"/jobs/{job_id}/tags", json_data=payload)


    @mcp.tool()
    async def list_job_tasks(job_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all tasks associated with a job.
        Wraps: GET /jobs/{id}/tasks

        Args:
            job_id: The unique identifier of the job
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of job tasks
        """
        return await make_request("GET", f"/jobs/{job_id}/tasks",
                                 params={"per_page": per_page})


    # ========== JOB LISTS ==========

    @mcp.tool()
    async def list_job_lists(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all job lists/collections.
        Wraps: GET /lists (filtered for jobs)

        Args:
            per_page: Number of results per page (default: 25)
            page: Page number to retrieve (default: 1)

        Returns:
            dict: List of job lists
        """
        return await make_request("GET", "/lists", params={"per_page": per_page, "page": page})


    @mcp.tool()
    async def get_job_list(list_id: int) -> dict[str, Any]:
        """
        Get details of a specific job list.
        Wraps: GET /lists/{id}

        Args:
            list_id: The unique identifier of the list

        Returns:
            dict: Job list details
        """
        return await make_request("GET", f"/lists/{list_id}")


    @mcp.tool()
    async def create_job_list(name: str, description: Optional[str] = None) -> dict[str, Any]:
        """
        Create a new job list/collection.
        Wraps: POST /lists

        Args:
            name: Name of the job list
            description: Description of the list (optional)

        Returns:
            dict: Created job list object
        """
        payload = {"name": name, "type": "job"}
        if description:
            payload["description"] = description

        return await make_request("POST", "/lists", json_data=payload)


    @mcp.tool()
    async def update_job_list(
        list_id: int,
        name: Optional[str] = None,
        description: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Update a job list's properties.
        Wraps: PUT /lists/{id}

        Args:
            list_id: The unique identifier of the list
            name: Updated list name (optional)
            description: Updated description (optional)

        Returns:
            dict: Updated job list object
        """
        payload = {}
        if name:
            payload["name"] = name
        if description:
            payload["description"] = description

        return await make_request("PUT", f"/lists/{list_id}", json_data=payload)


    @mcp.tool()
    async def delete_job_list(list_id: int) -> dict[str, Any]:
        """
        Delete a job list.
        Wraps: DELETE /lists/{id}

        Args:
            list_id: The unique identifier of the list

        Returns:
            dict: Confirmation of deletion
        """
        return await make_request("DELETE", f"/lists/{list_id}")


    @mcp.tool()
    async def list_job_list_items(list_id: int, per_page: int = 25) -> dict[str, Any]:
        """
        List all jobs in a specific job list.
        Wraps: GET /lists/{id}/candidates (reused for jobs)

        Args:
            list_id: The unique identifier of the list
            per_page: Number of results per page (default: 25)

        Returns:
            dict: List of jobs in the list
        """
        return await make_request("GET", f"/lists/{list_id}/candidates",
                                 params={"per_page": per_page})


    @mcp.tool()
    async def get_job_list_item(list_id: int, job_id: int) -> dict[str, Any]:
        """
        Get a specific job from a job list.
        Wraps: GET /lists/{list_id}/candidates/{job_id}

        Args:
            list_id: The unique identifier of the list
            job_id: The unique identifier of the job

        Returns:
            dict: Job details within the list context
        """
        return await make_request("GET", f"/lists/{list_id}/candidates/{job_id}")


    @mcp.tool()
    async def create_job_list_items(list_id: int, job_ids: list[int]) -> dict[str, Any]:
        """
        Add jobs to a job list.
        Wraps: POST /lists/{id}/candidates

        Args:
            list_id: The unique identifier of the list
            job_ids: List of job IDs to add

        Returns:
            dict: Confirmation of jobs added
        """
        payload = {"candidate_ids": job_ids}  # API uses 'candidate_ids' generically
        return await make_request("POST", f"/lists/{list_id}/candidates", json_data=payload)


    @mcp.tool()
    async def delete_job_list_item(list_id: int, job_id: int) -> dict[str, Any]:
        """
        Remove a job from a job list.
        Wraps: DELETE /lists/{id}/candidates

        Args:
            list_id: The unique identifier of the list
            job_id: The unique identifier of the job to remove

        Returns:
            dict: Confirmation of job removal
        """
        payload = {"candidate_id": job_id}
        return await make_request("DELETE", f"/lists/{list_id}/candidates", json_data=payload)


    # ========== JOB APPLICATIONS ==========

    @mcp.tool()
    async def list_job_applications(job_id: int, per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all applications for a specific job.
        Wraps: GET /jobs/{id}/applications

        Args:
            job_id: The unique identifier of the job
            per_page: Number of results per page (default: 25)
            page: Page number to retrieve (default: 1)

        Returns:
            dict: List of applications for the job
        """
        return await make_request("GET", f"/jobs/{job_id}/applications",
                                 params={"per_page": per_page, "page": page})


    @mcp.tool()
    async def get_job_application(application_id: int) -> dict[str, Any]:
        """
        Get details of a specific application.
        Wraps: GET /applications/{id}

        Args:
            application_id: The unique identifier of the application

        Returns:
            dict: Application details with candidate and job info
        """
        return await make_request("GET", f"/applications/{application_id}")


    @mcp.tool()
    async def list_job_application_fields(job_id: int) -> dict[str, Any]:
        """
        List all application form fields for a job.
        Wraps: GET /jobs/{id}/application_fields

        Args:
            job_id: The unique identifier of the job

        Returns:
            dict: List of application form fields
        """
        return await make_request("GET", f"/jobs/{job_id}/application_fields")


# ============================================================================
# TOOLSET 3: PIPELINES (13 tools)
# ============================================================================

def register_pipelines_tools(mcp: FastMCP, make_request):
    """Register all pipeline management tools"""

    @mcp.tool()
    async def list_pipelines(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all pipelines with pagination.
        Wraps: GET /pipelines

        Args:
            per_page: Number of results per page (default: 25)
            page: Page number to retrieve (default: 1)

        Returns:
            dict: List of pipelines with pagination metadata
        """
        return await make_request("GET", "/pipelines", params={"per_page": per_page, "page": page})


    @mcp.tool()
    async def get_pipeline(pipeline_id: int) -> dict[str, Any]:
        """
        Get detailed information about a specific pipeline.
        Wraps: GET /pipelines/{id}

        Args:
            pipeline_id: The unique identifier of the pipeline

        Returns:
            dict: Complete pipeline details with stages
        """
        return await make_request("GET", f"/pipelines/{pipeline_id}")


    @mcp.tool()
    async def create_pipeline(
        name: str,
        job_id: Optional[int] = None,
        candidate_id: Optional[int] = None,
        status_id: Optional[int] = None
    ) -> dict[str, Any]:
        """
        Create a new pipeline entry (candidate in job pipeline).
        Wraps: POST /pipelines

        Args:
            name: Pipeline name
            job_id: Associated job ID (optional)
            candidate_id: Associated candidate ID (optional)
            status_id: Initial status/stage ID (optional)

        Returns:
            dict: Created pipeline object
        """
        payload = {"name": name}
        if job_id:
            payload["job_id"] = job_id
        if candidate_id:
            payload["candidate_id"] = candidate_id
        if status_id:
            payload["status_id"] = status_id

        return await make_request("POST", "/pipelines", json_data=payload)


    @mcp.tool()
    async def update_pipeline(
        pipeline_id: int,
        name: Optional[str] = None,
        status_id: Optional[int] = None
    ) -> dict[str, Any]:
        """
        Update a pipeline's properties.
        Wraps: PUT /pipelines/{id}

        Args:
            pipeline_id: The unique identifier of the pipeline
            name: Updated pipeline name (optional)
            status_id: Updated status/stage ID (optional)

        Returns:
            dict: Updated pipeline object
        """
        payload = {}
        if name:
            payload["name"] = name
        if status_id:
            payload["status_id"] = status_id

        return await make_request("PUT", f"/pipelines/{pipeline_id}", json_data=payload)


    @mcp.tool()
    async def delete_pipeline(pipeline_id: int) -> dict[str, Any]:
        """
        Delete a pipeline entry.
        Wraps: DELETE /pipelines/{id}

        Args:
            pipeline_id: The unique identifier of the pipeline

        Returns:
            dict: Confirmation of deletion
        """
        return await make_request("DELETE", f"/pipelines/{pipeline_id}")


    @mcp.tool()
    async def filter_pipelines(
        job_id: Optional[int] = None,
        candidate_id: Optional[int] = None,
        status_id: Optional[int] = None,
        per_page: int = 25,
        page: int = 1
    ) -> dict[str, Any]:
        """
        Filter pipelines by job, candidate, or status.
        Wraps: GET /pipelines with query parameters

        Args:
            job_id: Filter by job ID (optional)
            candidate_id: Filter by candidate ID (optional)
            status_id: Filter by status/stage ID (optional)
            per_page: Number of results per page (default: 25)
            page: Page number to retrieve (default: 1)

        Returns:
            dict: List of filtered pipelines
        """
        params = {"per_page": per_page, "page": page}
        if job_id:
            params["job_id"] = job_id
        if candidate_id:
            params["candidate_id"] = candidate_id
        if status_id:
            params["status_id"] = status_id

        return await make_request("GET", "/pipelines", params=params)


    @mcp.tool()
    async def list_pipeline_workflows(pipeline_id: int) -> dict[str, Any]:
        """
        List all workflows for a pipeline.
        Wraps: GET /pipelines/{id}/workflows

        Args:
            pipeline_id: The unique identifier of the pipeline

        Returns:
            dict: List of pipeline workflows
        """
        return await make_request("GET", f"/pipelines/{pipeline_id}/workflows")


    @mcp.tool()
    async def get_pipeline_workflow(pipeline_id: int, workflow_id: int) -> dict[str, Any]:
        """
        Get details of a specific pipeline workflow.
        Wraps: GET /pipelines/{id}/workflows/{workflow_id}

        Args:
            pipeline_id: The unique identifier of the pipeline
            workflow_id: The unique identifier of the workflow

        Returns:
            dict: Workflow details
        """
        return await make_request("GET", f"/pipelines/{pipeline_id}/workflows/{workflow_id}")


    @mcp.tool()
    async def list_pipeline_workflow_statuses(workflow_id: int) -> dict[str, Any]:
        """
        List all statuses/stages in a workflow.
        Wraps: GET /workflows/{id}/statuses

        Args:
            workflow_id: The unique identifier of the workflow

        Returns:
            dict: List of workflow statuses
        """
        return await make_request("GET", f"/workflows/{workflow_id}/statuses")


    @mcp.tool()
    async def get_pipeline_workflow_status(workflow_id: int, status_id: int) -> dict[str, Any]:
        """
        Get details of a specific workflow status.
        Wraps: GET /workflows/{id}/statuses/{status_id}

        Args:
            workflow_id: The unique identifier of the workflow
            status_id: The unique identifier of the status

        Returns:
            dict: Status details
        """
        return await make_request("GET", f"/workflows/{workflow_id}/statuses/{status_id}")


    @mcp.tool()
    async def get_pipeline_statuses(pipeline_id: int) -> dict[str, Any]:
        """
        Get available statuses for a pipeline.
        Wraps: GET /pipelines/{id}/statuses

        Args:
            pipeline_id: The unique identifier of the pipeline

        Returns:
            dict: List of available pipeline statuses
        """
        return await make_request("GET", f"/pipelines/{pipeline_id}/statuses")


    @mcp.tool()
    async def change_pipeline_status(
        pipeline_id: int,
        status_id: int,
        notes: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Move a pipeline to a different status/stage.
        Wraps: PUT /pipelines/{id}/status

        Args:
            pipeline_id: The unique identifier of the pipeline
            status_id: The target status/stage ID
            notes: Optional notes about the status change

        Returns:
            dict: Updated pipeline with new status
        """
        payload = {"status_id": status_id}
        if notes:
            payload["notes"] = notes

        return await make_request("PUT", f"/pipelines/{pipeline_id}/status", json_data=payload)


# ============================================================================
# TOOLSET 4: CONTEXT (3 tools)
# ============================================================================

def register_context_tools(mcp: FastMCP, make_request):
    """Register context and authentication tools"""

    @mcp.tool()
    async def get_site() -> dict[str, Any]:
        """
        Get current CATS site information and settings.
        Wraps: GET /site

        Returns:
            dict: Site configuration and metadata
        """
        return await make_request("GET", "/site")


    @mcp.tool()
    async def get_me() -> dict[str, Any]:
        """
        Get current authenticated user's information.
        Wraps: GET /users/current

        Returns:
            dict: Current user profile and permissions
        """
        return await make_request("GET", "/users/current")


    @mcp.tool()
    async def authorize_user(user_id: int, action: str) -> dict[str, Any]:
        """
        Check if a user is authorized for a specific action.
        Wraps: POST /authorization

        Args:
            user_id: The unique identifier of the user
            action: The action to authorize (e.g., 'read', 'write', 'delete')

        Returns:
            dict: Authorization result
        """
        payload = {"user_id": user_id, "action": action}
        return await make_request("POST", "/authorization", json_data=payload)


# ============================================================================
# TOOLSET 5: TASKS (5 tools)
# ============================================================================

def register_tasks_tools(mcp: FastMCP, make_request):
    """Register task management tools"""

    @mcp.tool()
    async def list_tasks(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all tasks with pagination.
        Wraps: GET /tasks

        Args:
            per_page: Number of results per page (default: 25)
            page: Page number to retrieve (default: 1)

        Returns:
            dict: List of tasks with pagination metadata
        """
        return await make_request("GET", "/tasks", params={"per_page": per_page, "page": page})


    @mcp.tool()
    async def get_task(task_id: int) -> dict[str, Any]:
        """
        Get detailed information about a specific task.
        Wraps: GET /tasks/{id}

        Args:
            task_id: The unique identifier of the task

        Returns:
            dict: Complete task details
        """
        return await make_request("GET", f"/tasks/{task_id}")


    @mcp.tool()
    async def create_task(
        title: str,
        due_date: Optional[str] = None,
        candidate_id: Optional[int] = None,
        job_id: Optional[int] = None,
        assigned_to: Optional[int] = None,
        description: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Create a new task.
        Wraps: POST /tasks

        Args:
            title: Task title
            due_date: Due date in ISO format (optional)
            candidate_id: Associated candidate ID (optional)
            job_id: Associated job ID (optional)
            assigned_to: User ID to assign task to (optional)
            description: Task description (optional)

        Returns:
            dict: Created task object with ID
        """
        payload = {"title": title}
        if due_date:
            payload["due_date"] = due_date
        if candidate_id:
            payload["candidate_id"] = candidate_id
        if job_id:
            payload["job_id"] = job_id
        if assigned_to:
            payload["assigned_to"] = assigned_to
        if description:
            payload["description"] = description

        return await make_request("POST", "/tasks", json_data=payload)


    @mcp.tool()
    async def update_task(
        task_id: int,
        title: Optional[str] = None,
        due_date: Optional[str] = None,
        status: Optional[str] = None,
        assigned_to: Optional[int] = None,
        description: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Update an existing task.
        Wraps: PUT /tasks/{id}

        Args:
            task_id: The unique identifier of the task
            title: Updated task title (optional)
            due_date: Updated due date (optional)
            status: Updated task status (optional)
            assigned_to: Updated assignee user ID (optional)
            description: Updated description (optional)

        Returns:
            dict: Updated task object
        """
        payload = {}
        if title:
            payload["title"] = title
        if due_date:
            payload["due_date"] = due_date
        if status:
            payload["status"] = status
        if assigned_to:
            payload["assigned_to"] = assigned_to
        if description:
            payload["description"] = description

        return await make_request("PUT", f"/tasks/{task_id}", json_data=payload)


    @mcp.tool()
    async def delete_task(task_id: int) -> dict[str, Any]:
        """
        Delete a task.
        Wraps: DELETE /tasks/{id}

        Args:
            task_id: The unique identifier of the task

        Returns:
            dict: Confirmation of deletion
        """
        return await make_request("DELETE", f"/tasks/{task_id}")
