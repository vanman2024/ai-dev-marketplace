# CATS MCP Server

FastMCP server providing production-ready MCP tools for the CATS (Complete Applicant Tracking System) API.

## Overview

This MCP server wraps the CATS applicant tracking system API endpoints, enabling AI assistants to interact with candidate data, job postings, applications, and interview management through the Model Context Protocol.

**Status**: Production-ready with 20 comprehensive API wrapper tools covering all major ATS functionality.

## Features

- **Complete ATS Coverage**: 20 tools covering candidates, jobs, applications, and interviews
- **Type-Safe**: Full type hints and Pydantic validation
- **Production-Ready**: Comprehensive error handling for all HTTP status codes
- **Well-Documented**: Detailed docstrings with examples for every tool
- **Async Support**: Built with httpx for high-performance async operations
- **Security**: Bearer token authentication from environment variables

## Prerequisites

- Python 3.10 or higher
- CATS API access and API key
- `uv` or `pip` for package management

## Installation

### 1. Clone or Navigate to Project

```bash
cd /home/vanman2025/Projects/ai-dev-marketplace/cats-mcp-server
```

### 2. Create Virtual Environment

Using `uv` (recommended):
```bash
uv venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

Or using standard `venv`:
```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

### 3. Install Dependencies

Using `uv`:
```bash
uv pip install -e .
```

Or using `pip`:
```bash
pip install -e .
```

### 4. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:
```bash
CATS_API_BASE_URL=https://api.your-cats-instance.com/v1
CATS_API_KEY=your_actual_cats_api_key
```

**IMPORTANT**: Never commit `.env` to version control. It's already in `.gitignore`.

## Usage

### Start the Server

Run the FastMCP server with HTTP transport:

```bash
python server.py
```

By default, the server runs on `http://localhost:8000`.

For convenience, you can also use the startup script:

```bash
./start.sh
```

## Available Tools

### Candidate Management (5 tools)

#### 1. list_candidates
List candidates with filtering and pagination.

**Parameters:**
- `limit` (int, default=20): Maximum number of candidates to return (max: 100)
- `offset` (int, default=0): Number of candidates to skip for pagination
- `status` (str, optional): Filter by status (active, archived, hired, rejected)
- `search` (str, optional): Search by candidate name or email
- `job_id` (int, optional): Filter candidates by job posting ID

**API Endpoint:** `GET /candidates`

**Example:**
```python
result = await list_candidates(limit=10, status="active", search="john")
```

#### 2. get_candidate
Get detailed candidate profile by ID.

**Parameters:**
- `candidate_id` (int): Unique identifier for the candidate

**API Endpoint:** `GET /candidates/{candidate_id}`

**Example:**
```python
candidate = await get_candidate(12345)
```

#### 3. create_candidate
Create a new candidate profile.

**Parameters:**
- `first_name` (str): Candidate's first name
- `last_name` (str): Candidate's last name
- `email` (str): Email address (must be unique)
- `phone` (str, optional): Phone number
- `resume_url` (str, optional): URL to resume document
- `linkedin_url` (str, optional): LinkedIn profile URL
- `source` (str, optional): Source of candidate (e.g., 'referral', 'job_board')
- `notes` (str, optional): Additional notes

**API Endpoint:** `POST /candidates`

**Example:**
```python
new_candidate = await create_candidate(
    first_name="Jane",
    last_name="Smith",
    email="jane@example.com",
    phone="+1-555-0100"
)
```

#### 4. update_candidate
Update existing candidate profile.

**Parameters:**
- `candidate_id` (int): ID of candidate to update
- `first_name` (str, optional): Updated first name
- `last_name` (str, optional): Updated last name
- `email` (str, optional): Updated email
- `phone` (str, optional): Updated phone
- `status` (str, optional): Updated status
- `resume_url` (str, optional): Updated resume URL
- `linkedin_url` (str, optional): Updated LinkedIn URL
- `notes` (str, optional): Updated notes

**API Endpoint:** `PUT /candidates/{candidate_id}`

**Example:**
```python
updated = await update_candidate(12345, status="hired", notes="Hired for SWE role")
```

#### 5. delete_candidate
Delete a candidate from the system (permanent).

**Parameters:**
- `candidate_id` (int): ID of candidate to delete

**API Endpoint:** `DELETE /candidates/{candidate_id}`

**Example:**
```python
result = await delete_candidate(12345)
```

---

### Job Management (5 tools)

#### 6. list_jobs
List job postings with filtering and pagination.

**Parameters:**
- `limit` (int, default=20): Maximum number of jobs to return (max: 100)
- `offset` (int, default=0): Number of jobs to skip for pagination
- `status` (str, optional): Filter by status (draft, open, closed, filled)
- `department` (str, optional): Filter by department name
- `location` (str, optional): Filter by job location

**API Endpoint:** `GET /jobs`

**Example:**
```python
jobs = await list_jobs(status="open", department="Engineering")
```

#### 7. get_job
Get detailed job posting by ID.

**Parameters:**
- `job_id` (int): Unique identifier for the job posting

**API Endpoint:** `GET /jobs/{job_id}`

**Example:**
```python
job = await get_job(5678)
```

#### 8. create_job
Create a new job posting.

**Parameters:**
- `title` (str): Job title
- `description` (str): Full job description
- `department` (str): Department name
- `location` (str): Job location
- `employment_type` (str, default="full-time"): Type (full-time, part-time, contract)
- `experience_level` (str, optional): Required level (entry, mid, senior)
- `salary_min` (int, optional): Minimum salary
- `salary_max` (int, optional): Maximum salary
- `requirements` (str, optional): Job requirements
- `benefits` (str, optional): Job benefits
- `status` (str, default="draft"): Initial status (draft or open)

**API Endpoint:** `POST /jobs`

**Example:**
```python
job = await create_job(
    title="Senior Software Engineer",
    description="We are seeking an experienced...",
    department="Engineering",
    location="San Francisco, CA",
    salary_min=150000,
    salary_max=200000
)
```

#### 9. update_job
Update existing job posting.

**Parameters:**
- `job_id` (int): ID of job to update
- `title` (str, optional): Updated job title
- `description` (str, optional): Updated description
- `status` (str, optional): Updated status
- `location` (str, optional): Updated location
- `salary_min` (int, optional): Updated minimum salary
- `salary_max` (int, optional): Updated maximum salary
- `requirements` (str, optional): Updated requirements

**API Endpoint:** `PUT /jobs/{job_id}`

**Example:**
```python
updated = await update_job(5678, status="open", salary_max=180000)
```

#### 10. delete_job
Delete a job posting (permanent).

**Parameters:**
- `job_id` (int): ID of job to delete

**API Endpoint:** `DELETE /jobs/{job_id}`

**Example:**
```python
result = await delete_job(5678)
```

---

### Application Management (5 tools)

#### 11. list_applications
List job applications with filtering and pagination.

**Parameters:**
- `limit` (int, default=20): Maximum number of applications to return (max: 100)
- `offset` (int, default=0): Number of applications to skip for pagination
- `job_id` (int, optional): Filter by specific job posting
- `candidate_id` (int, optional): Filter by specific candidate
- `status` (str, optional): Filter by status (submitted, reviewing, interview, offer, etc.)

**API Endpoint:** `GET /applications`

**Example:**
```python
apps = await list_applications(job_id=5678, status="interview")
```

#### 12. get_application
Get detailed application information by ID.

**Parameters:**
- `application_id` (int): Unique identifier for the application

**API Endpoint:** `GET /applications/{application_id}`

**Example:**
```python
app = await get_application(11111)
```

#### 13. create_application
Submit a new job application.

**Parameters:**
- `candidate_id` (int): ID of the candidate applying
- `job_id` (int): ID of the job posting
- `cover_letter` (str, optional): Cover letter text
- `referral_source` (str, optional): How candidate heard about position

**API Endpoint:** `POST /applications`

**Example:**
```python
app = await create_application(
    candidate_id=12345,
    job_id=5678,
    cover_letter="I am excited to apply..."
)
```

#### 14. update_application_status
Update application status with optional notes.

**Parameters:**
- `application_id` (int): ID of application to update
- `status` (str): New status (submitted, reviewing, interview, offer, accepted, rejected)
- `notes` (str, optional): Notes about the status change

**API Endpoint:** `PUT /applications/{application_id}/status`

**Example:**
```python
updated = await update_application_status(
    11111,
    "interview",
    "Moving to technical interview round"
)
```

#### 15. withdraw_application
Withdraw a job application.

**Parameters:**
- `application_id` (int): ID of application to withdraw
- `reason` (str, optional): Reason for withdrawal

**API Endpoint:** `POST /applications/{application_id}/withdraw`

**Example:**
```python
result = await withdraw_application(11111, "Accepted another offer")
```

---

### Interview Management (6 tools)

#### 16. list_interviews
List scheduled interviews with filtering and pagination.

**Parameters:**
- `limit` (int, default=20): Maximum number of interviews to return (max: 100)
- `offset` (int, default=0): Number of interviews to skip for pagination
- `application_id` (int, optional): Filter by specific application
- `candidate_id` (int, optional): Filter by specific candidate
- `status` (str, optional): Filter by status (scheduled, completed, cancelled)
- `interviewer_id` (int, optional): Filter by specific interviewer

**API Endpoint:** `GET /interviews`

**Example:**
```python
interviews = await list_interviews(status="scheduled", limit=10)
```

#### 17. get_interview
Get detailed interview information by ID.

**Parameters:**
- `interview_id` (int): Unique identifier for the interview

**API Endpoint:** `GET /interviews/{interview_id}`

**Example:**
```python
interview = await get_interview(33333)
```

#### 18. schedule_interview
Schedule a new interview.

**Parameters:**
- `application_id` (int): ID of the application
- `scheduled_at` (str): Interview datetime in ISO 8601 format (e.g., '2025-11-01T14:00:00Z')
- `duration_minutes` (int, default=60): Interview duration in minutes
- `interview_type` (str, default="technical"): Type (phone, technical, behavioral, onsite)
- `interviewer_ids` (list[int]): List of interviewer user IDs
- `location` (str, optional): Interview location or video call link
- `notes` (str, optional): Additional notes

**API Endpoint:** `POST /interviews`

**Example:**
```python
interview = await schedule_interview(
    application_id=11111,
    scheduled_at="2025-11-01T14:00:00Z",
    interview_type="technical",
    interviewer_ids=[101, 102],
    location="https://zoom.us/j/123456"
)
```

#### 19. update_interview
Update interview details.

**Parameters:**
- `interview_id` (int): ID of interview to update
- `scheduled_at` (str, optional): Updated interview datetime
- `status` (str, optional): Updated status (scheduled, completed, cancelled, rescheduled)
- `location` (str, optional): Updated location or video link
- `notes` (str, optional): Updated notes

**API Endpoint:** `PUT /interviews/{interview_id}`

**Example:**
```python
updated = await update_interview(
    33333,
    scheduled_at="2025-11-02T10:00:00Z",
    status="rescheduled"
)
```

#### 20. cancel_interview
Cancel a scheduled interview.

**Parameters:**
- `interview_id` (int): ID of interview to cancel
- `reason` (str, optional): Cancellation reason

**API Endpoint:** `POST /interviews/{interview_id}/cancel`

**Example:**
```python
result = await cancel_interview(33333, "Candidate no longer available")
```

#### 21. submit_interview_feedback
Submit feedback for a completed interview.

**Parameters:**
- `interview_id` (int): ID of the interview
- `interviewer_id` (int): ID of interviewer submitting feedback
- `rating` (int): Overall rating (1-5 scale)
- `feedback` (str): Detailed feedback text
- `recommendation` (str): Hiring recommendation (hire, no_hire, maybe, strong_hire)
- `strengths` (str, optional): Candidate strengths
- `weaknesses` (str, optional): Areas for improvement

**API Endpoint:** `POST /interviews/{interview_id}/feedback`

**Example:**
```python
feedback = await submit_interview_feedback(
    interview_id=33333,
    interviewer_id=101,
    rating=4,
    feedback="Strong technical skills, excellent communication",
    recommendation="hire"
)
```

---

## API Endpoint Mapping

| MCP Tool | HTTP Method | API Endpoint | Description |
|----------|-------------|--------------|-------------|
| **Candidates** ||||
| list_candidates | GET | /candidates | List candidates with filters |
| get_candidate | GET | /candidates/{id} | Get candidate by ID |
| create_candidate | POST | /candidates | Create new candidate |
| update_candidate | PUT | /candidates/{id} | Update candidate |
| delete_candidate | DELETE | /candidates/{id} | Delete candidate |
| **Jobs** ||||
| list_jobs | GET | /jobs | List job postings |
| get_job | GET | /jobs/{id} | Get job by ID |
| create_job | POST | /jobs | Create new job posting |
| update_job | PUT | /jobs/{id} | Update job posting |
| delete_job | DELETE | /jobs/{id} | Delete job posting |
| **Applications** ||||
| list_applications | GET | /applications | List applications |
| get_application | GET | /applications/{id} | Get application by ID |
| create_application | POST | /applications | Submit application |
| update_application_status | PUT | /applications/{id}/status | Update status |
| withdraw_application | POST | /applications/{id}/withdraw | Withdraw application |
| **Interviews** ||||
| list_interviews | GET | /interviews | List interviews |
| get_interview | GET | /interviews/{id} | Get interview by ID |
| schedule_interview | POST | /interviews | Schedule new interview |
| update_interview | PUT | /interviews/{id} | Update interview |
| cancel_interview | POST | /interviews/{id}/cancel | Cancel interview |
| submit_interview_feedback | POST | /interviews/{id}/feedback | Submit feedback |

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `CATS_API_BASE_URL` | Yes | Base URL for CATS API (e.g., https://api.cats.com/v1) |
| `CATS_API_KEY` | Yes | API key for authentication (Bearer token) |
| `MCP_HOST` | No | HTTP server host (default: localhost) |
| `MCP_PORT` | No | HTTP server port (default: 8000) |
| `LOG_LEVEL` | No | Logging level (default: INFO) |

### Security Best Practices

- Never hardcode API keys in source code
- Always load credentials from environment variables using `python-dotenv`
- Keep `.env` file out of version control (.gitignore configured)
- Use different API keys for development/production environments
- Rotate API keys periodically
- Use HTTPS endpoints only (enforced in production)

## Claude Desktop Integration

### HTTP Transport (Recommended)

Add to your Claude Desktop configuration (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "cats-api": {
      "url": "http://localhost:8000/mcp",
      "transport": {
        "type": "http"
      }
    }
  }
}
```

Then start the server:
```bash
cd /home/vanman2025/Projects/ai-dev-marketplace/cats-mcp-server
./start.sh
```

### STDIO Transport (Alternative)

For STDIO transport, modify `server.py`:

```python
if __name__ == "__main__":
    mcp.run()  # Uses STDIO by default
```

Then configure Claude Desktop:

```json
{
  "mcpServers": {
    "cats-api": {
      "command": "python",
      "args": ["/absolute/path/to/cats-mcp-server/server.py"],
      "env": {
        "CATS_API_BASE_URL": "https://api.your-cats-instance.com/v1",
        "CATS_API_KEY": "your_api_key"
      }
    }
  }
}
```

## Error Handling

All tools include comprehensive error handling:

- **400 Bad Request**: Invalid parameters or data validation errors
- **401 Unauthorized**: Invalid or expired API key
- **403 Forbidden**: Insufficient permissions for the operation
- **404 Not Found**: Resource (candidate, job, etc.) not found
- **409 Conflict**: Duplicate resource or constraint violation
- **429 Rate Limited**: Too many requests, retry with exponential backoff
- **500+ Server Errors**: CATS API service issues

Errors are returned in a consistent format:
```json
{
  "error": "Detailed error message",
  "success": false
}
```

## Development

### Install Development Dependencies

```bash
uv pip install -e ".[dev]"
```

### Run Tests

```bash
pytest
```

### Linting and Formatting

```bash
ruff check .
ruff format .
```

### Type Checking

```bash
mypy server.py
```

### Project Structure

```
cats-mcp-server/
├── server.py                      # Main FastMCP server (1,310 lines)
├── pyproject.toml                 # Project dependencies and metadata
├── README.md                      # This file
├── .env.example                   # Environment variable template
├── .gitignore                     # Git ignore patterns
├── requirements.txt               # Python dependencies
├── requirements-dev.txt           # Development dependencies
├── start.sh                       # Startup script
├── verify_setup.py                # Setup verification script
├── claude_desktop_config.example.json  # Claude Desktop config example
└── tests/                         # Test directory
    ├── __init__.py
    ├── conftest.py                # Pytest configuration
    └── test_server.py             # Server tests
```

## Verification

Verify your setup:

```bash
python verify_setup.py
```

This checks:
- Python version compatibility
- Required dependencies installed
- Environment variables configured
- Server can start successfully
- Basic tool functionality

## Troubleshooting

### API Connection Issues

```bash
# Test API connectivity (requires configured .env)
python -c "
import asyncio
from server import make_cats_request
asyncio.run(make_cats_request('GET', '/health'))
"
```

### Environment Variables Not Loading

- Verify `.env` file exists in project root
- Check file permissions (should be readable)
- Ensure `python-dotenv` is installed
- Try absolute path: `load_dotenv('/absolute/path/.env')`

### Import Errors

```bash
# Reinstall dependencies
uv pip install -e .

# Verify FastMCP installation
python -c "import fastmcp; print(fastmcp.__version__)"
```

### Server Won't Start

```bash
# Check if port 8000 is available
lsof -i :8000

# Try different port
export MCP_PORT=8001
python server.py
```

## Performance Considerations

- **Pagination**: Use `limit` and `offset` parameters for large result sets
- **Filtering**: Apply filters server-side to reduce response size
- **Rate Limits**: CATS API may enforce rate limits (429 errors)
- **Timeouts**: HTTP client timeout set to 30 seconds (configurable)
- **Async**: All operations are async for optimal performance

## Common Use Cases

### Recruiting Workflow

```python
# 1. Find open positions
jobs = await list_jobs(status="open", department="Engineering")

# 2. Create candidate profile
candidate = await create_candidate(
    first_name="John",
    last_name="Doe",
    email="john@example.com",
    resume_url="https://..."
)

# 3. Submit application
app = await create_application(
    candidate_id=candidate["id"],
    job_id=jobs["jobs"][0]["id"]
)

# 4. Schedule interview
interview = await schedule_interview(
    application_id=app["id"],
    scheduled_at="2025-11-01T14:00:00Z",
    interviewer_ids=[101, 102]
)

# 5. Submit feedback
await submit_interview_feedback(
    interview_id=interview["id"],
    interviewer_id=101,
    rating=4,
    recommendation="hire"
)

# 6. Update application status
await update_application_status(app["id"], "offer")
```

## Resources

- [FastMCP Documentation](https://docs.fastmcp.com/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [httpx Documentation](https://www.python-httpx.org/)
- [Pydantic Documentation](https://docs.pydantic.dev/)

## License

[Specify your license here]

## Contributing

[Add contribution guidelines]

## Support

For issues or questions:
- GitHub Issues: [your-repo-url]
- Email: [your-email]

---

**Note**: This server implements production-ready API wrappers following FastMCP best practices. All 20 tools include comprehensive error handling, type safety, and detailed documentation.
