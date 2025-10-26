# CATS MCP Server - Quick Reference

## Tool Names & Endpoints

### Candidates
```python
list_candidates(limit=20, offset=0, status=None, search=None, job_id=None)
# GET /candidates

get_candidate(candidate_id)
# GET /candidates/{candidate_id}

create_candidate(first_name, last_name, email, phone=None, resume_url=None, ...)
# POST /candidates

update_candidate(candidate_id, first_name=None, last_name=None, email=None, ...)
# PUT /candidates/{candidate_id}

delete_candidate(candidate_id)
# DELETE /candidates/{candidate_id}
```

### Jobs
```python
list_jobs(limit=20, offset=0, status=None, department=None, location=None)
# GET /jobs

get_job(job_id)
# GET /jobs/{job_id}

create_job(title, description, department, location, employment_type="full-time", ...)
# POST /jobs

update_job(job_id, title=None, description=None, status=None, ...)
# PUT /jobs/{job_id}

delete_job(job_id)
# DELETE /jobs/{job_id}
```

### Applications
```python
list_applications(limit=20, offset=0, job_id=None, candidate_id=None, status=None)
# GET /applications

get_application(application_id)
# GET /applications/{application_id}

create_application(candidate_id, job_id, cover_letter=None, referral_source=None)
# POST /applications

update_application_status(application_id, status, notes=None)
# PUT /applications/{application_id}/status

withdraw_application(application_id, reason=None)
# POST /applications/{application_id}/withdraw
```

### Interviews
```python
list_interviews(limit=20, offset=0, application_id=None, candidate_id=None,
                status=None, interviewer_id=None)
# GET /interviews

get_interview(interview_id)
# GET /interviews/{interview_id}

schedule_interview(application_id, scheduled_at, duration_minutes=60,
                   interview_type="technical", interviewer_ids=[], ...)
# POST /interviews

update_interview(interview_id, scheduled_at=None, status=None, location=None, ...)
# PUT /interviews/{interview_id}

cancel_interview(interview_id, reason=None)
# POST /interviews/{interview_id}/cancel

submit_interview_feedback(interview_id, interviewer_id, rating, feedback,
                          recommendation, strengths=None, weaknesses=None)
# POST /interviews/{interview_id}/feedback
```

## Common Workflows

### Hire a Candidate
```python
# 1. Search for candidates
candidates = await list_candidates(search="john@example.com")

# 2. Get candidate details
candidate = await get_candidate(candidates["candidates"][0]["id"])

# 3. Find open jobs
jobs = await list_jobs(status="open", department="Engineering")

# 4. Create application
app = await create_application(
    candidate_id=candidate["id"],
    job_id=jobs["jobs"][0]["id"]
)

# 5. Move to interview
await update_application_status(app["id"], "interview")

# 6. Schedule interview
interview = await schedule_interview(
    application_id=app["id"],
    scheduled_at="2025-11-01T14:00:00Z",
    interviewer_ids=[101, 102]
)

# 7. Submit feedback
await submit_interview_feedback(
    interview_id=interview["id"],
    interviewer_id=101,
    rating=5,
    recommendation="strong_hire"
)

# 8. Make offer
await update_application_status(app["id"], "offer")
```

### Post a Job
```python
# 1. Create job posting
job = await create_job(
    title="Senior Software Engineer",
    description="We are seeking...",
    department="Engineering",
    location="Remote",
    salary_min=150000,
    salary_max=200000,
    status="draft"
)

# 2. Review and publish
await update_job(job["id"], status="open")

# 3. Check applications
apps = await list_applications(job_id=job["id"])

# 4. Close when filled
await update_job(job["id"], status="filled")
```

### Manage Interviews
```python
# List upcoming interviews
upcoming = await list_interviews(status="scheduled")

# Reschedule an interview
await update_interview(
    interview_id=123,
    scheduled_at="2025-11-02T10:00:00Z",
    status="rescheduled"
)

# Cancel if needed
await cancel_interview(123, reason="Candidate unavailable")

# Get all interviews for a candidate
candidate_interviews = await list_interviews(candidate_id=456)
```

## Status Values

### Candidate
- `active` | `archived` | `hired` | `rejected` | `withdrawn`

### Application
- `submitted` | `reviewing` | `interview` | `offer` | `accepted` | `rejected` | `withdrawn`

### Job
- `draft` | `open` | `closed` | `filled` | `cancelled`

### Interview
- `scheduled` | `completed` | `cancelled` | `rescheduled`

## Error Codes

- **400**: Bad request - check parameters
- **401**: Unauthorized - check API key
- **403**: Forbidden - insufficient permissions
- **404**: Not found - resource doesn't exist
- **429**: Rate limited - slow down requests
- **500+**: Server error - retry later

## Environment Setup

```bash
# .env file
CATS_API_BASE_URL=https://api.your-cats-instance.com/v1
CATS_API_KEY=your_bearer_token_here
```

## Start Server

```bash
cd /home/vanman2025/Projects/ai-dev-marketplace/cats-mcp-server
./start.sh
```

Or:
```bash
python server.py
```

Server runs on: `http://localhost:8000`

## Claude Desktop Config

```json
{
  "mcpServers": {
    "cats-api": {
      "url": "http://localhost:8000/mcp"
    }
  }
}
```
