"""
CATS MCP Server - Data & Configuration Toolsets

This module contains 7 toolset registration functions for data and configuration
management in the CATS API v3:

1. Tags - 2 tools
2. Webhooks - 4 tools
3. Users - 2 tools
4. Triggers - 2 tools
5. Attachments - 4 tools
6. Backups - 3 tools
7. Events - 5 tools

Total: 22 tools across 7 toolsets
"""

from typing import Any, Optional
from fastmcp import FastMCP


async def make_request(method: str, endpoint: str, params: dict = None, json_data: dict = None) -> dict:
    """Make authenticated request to CATS API"""
    # This is imported from server.py at runtime
    pass


def register_tags_tools(mcp: FastMCP) -> None:
    """
    Register tag management tools.

    Tags are labels that can be attached to candidates, jobs, and other entities.
    Tags are managed at the entity level (e.g., /candidates/{id}/tags).
    This toolset provides read access to the global tags list.
    """

    @mcp.tool()
    async def list_tags(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all tags in the system.

        Tags are labels used to categorize candidates, jobs, and other entities.
        To attach/detach tags, use the entity-specific endpoints:
        - POST /candidates/{id}/tags
        - DELETE /candidates/{id}/tags
        - POST /jobs/{id}/tags
        - DELETE /jobs/{id}/tags

        Wraps: GET /tags

        Args:
            per_page: Number of results per page (default: 25, max: 100)
            page: Page number to retrieve (default: 1)

        Returns:
            dict containing:
            - tags: List of tag objects with id, name, color
            - total_count: Total number of tags
            - page: Current page number
            - per_page: Results per page

        Example:
            >>> tags = await list_tags(per_page=50)
            >>> print(tags["tags"][0])
            {"id": 101, "name": "Python Developer", "color": "#3498db"}
        """
        return await make_request("GET", "/tags", params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def get_tag(tag_id: int) -> dict[str, Any]:
        """
        Get details of a specific tag.

        Wraps: GET /tags/{id}

        Args:
            tag_id: The unique identifier of the tag

        Returns:
            dict containing:
            - id: Tag ID
            - name: Tag name
            - color: Tag color (hex code)
            - usage_count: Number of entities using this tag
            - created_at: Tag creation timestamp

        Example:
            >>> tag = await get_tag(101)
            >>> print(f"{tag['name']}: Used {tag['usage_count']} times")
        """
        return await make_request("GET", f"/tags/{tag_id}")


def register_webhooks_tools(mcp: FastMCP) -> None:
    """
    Register webhook management tools.

    Webhooks allow real-time notifications when events occur in CATS.
    Supports 24+ event types across candidates, jobs, applications, etc.

    Security: Webhooks include HMAC-SHA256 signatures for verification.
    """

    @mcp.tool()
    async def list_webhooks(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all configured webhooks.

        Wraps: GET /webhooks

        Available webhook events (24 types):
        - candidate.created, candidate.updated, candidate.deleted
        - job.created, job.updated, job.deleted, job.status_changed
        - application.created, application.updated, application.status_changed
        - pipeline.status_changed
        - activity.created, activity.updated
        - task.created, task.completed
        - interview.scheduled, interview.completed, interview.cancelled
        - attachment.uploaded, attachment.deleted
        - email.sent, email.received
        - tag.attached, tag.detached
        - trigger.fired

        Args:
            per_page: Number of results per page (default: 25, max: 100)
            page: Page number to retrieve (default: 1)

        Returns:
            dict containing:
            - webhooks: List of webhook configurations
            - total_count: Total number of webhooks
            - page: Current page
            - per_page: Results per page

        Example:
            >>> webhooks = await list_webhooks()
            >>> for wh in webhooks["webhooks"]:
            ...     print(f"{wh['url']}: {len(wh['events'])} events")
        """
        return await make_request("GET", "/webhooks", params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def get_webhook(webhook_id: int) -> dict[str, Any]:
        """
        Get details of a specific webhook configuration.

        Wraps: GET /webhooks/{id}

        Args:
            webhook_id: The unique identifier of the webhook

        Returns:
            dict containing:
            - id: Webhook ID
            - url: Target URL for webhook POSTs
            - events: List of subscribed event types
            - active: Whether webhook is enabled
            - secret: Secret key for HMAC signature verification
            - created_at: Creation timestamp
            - last_triggered: Last successful trigger timestamp
            - failure_count: Number of consecutive failures

        Security Note:
            Verify webhook signatures using HMAC-SHA256:
            signature = HMAC-SHA256(secret, request_body)
            Compare with X-CATS-Signature header

        Example:
            >>> webhook = await get_webhook(18128)
            >>> print(f"Status: {'Active' if webhook['active'] else 'Inactive'}")
            >>> print(f"Events: {', '.join(webhook['events'])}")
        """
        return await make_request("GET", f"/webhooks/{webhook_id}")

    @mcp.tool()
    async def create_webhook(
        url: str,
        events: list[str],
        active: bool = True,
        description: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Create a new webhook subscription.

        Wraps: POST /webhooks

        The webhook will receive POST requests with JSON payloads when subscribed
        events occur. Each request includes:
        - X-CATS-Signature: HMAC-SHA256 signature for verification
        - X-CATS-Event: Event type that triggered the webhook
        - X-CATS-Delivery: Unique delivery ID

        Args:
            url: Target URL for webhook POST requests (must be HTTPS in production)
            events: List of event types to subscribe to (e.g., ["candidate.created", "job.updated"])
            active: Whether webhook should be active immediately (default: True)
            description: Optional description for the webhook

        Returns:
            dict containing:
            - id: New webhook ID
            - url: Configured URL
            - events: Subscribed events
            - active: Active status
            - secret: Generated secret key for signature verification (save this!)
            - created_at: Creation timestamp

        Example:
            >>> webhook = await create_webhook(
            ...     url="https://myapp.com/webhooks/cats",
            ...     events=["candidate.created", "candidate.updated"],
            ...     description="Sync candidates to CRM"
            ... )
            >>> print(f"Webhook created! Secret: {webhook['secret']}")
            >>> # Save the secret securely for signature verification
        """
        payload = {
            "url": url,
            "events": events,
            "active": active
        }
        if description:
            payload["description"] = description
        return await make_request("POST", "/webhooks", json_data=payload)

    @mcp.tool()
    async def delete_webhook(webhook_id: int) -> dict[str, Any]:
        """
        Delete a webhook subscription.

        This permanently removes the webhook configuration. All pending deliveries
        will be cancelled.

        Wraps: DELETE /webhooks/{id}

        Args:
            webhook_id: The unique identifier of the webhook to delete

        Returns:
            dict containing:
            - success: True if deletion succeeded
            - message: Confirmation message

        Example:
            >>> result = await delete_webhook(18128)
            >>> print(result["message"])
            "Webhook successfully deleted"
        """
        return await make_request("DELETE", f"/webhooks/{webhook_id}")


def register_users_tools(mcp: FastMCP) -> None:
    """
    Register user management tools.

    Users are team members with access to the CATS system.
    Access levels: read_only, edit, admin
    """

    @mcp.tool()
    async def list_users(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all users in the organization.

        Wraps: GET /users

        Args:
            per_page: Number of results per page (default: 25, max: 100)
            page: Page number to retrieve (default: 1)

        Returns:
            dict containing:
            - users: List of user objects
            - total_count: Total number of users
            - page: Current page
            - per_page: Results per page

        User object contains:
        - id: User ID
        - first_name: First name
        - last_name: Last name
        - email: Email address
        - access_level: read_only, edit, or admin
        - active: Whether user account is active
        - last_login: Last login timestamp
        - created_at: Account creation timestamp

        Example:
            >>> users = await list_users()
            >>> admins = [u for u in users["users"] if u["access_level"] == "admin"]
            >>> print(f"Found {len(admins)} admin users")
        """
        return await make_request("GET", "/users", params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def get_user(user_id: int) -> dict[str, Any]:
        """
        Get details of a specific user.

        Wraps: GET /users/{id}

        Args:
            user_id: The unique identifier of the user

        Returns:
            dict containing:
            - id: User ID
            - first_name: First name
            - last_name: Last name
            - email: Email address
            - access_level: read_only, edit, or admin
            - active: Whether user account is active
            - department: User's department
            - title: Job title
            - phone: Phone number
            - permissions: List of specific permissions
            - last_login: Last login timestamp
            - created_at: Account creation timestamp

        Example:
            >>> user = await get_user(80808)
            >>> print(f"{user['first_name']} {user['last_name']} ({user['access_level']})")
            >>> print(f"Last login: {user['last_login']}")
        """
        return await make_request("GET", f"/users/{user_id}")


def register_triggers_tools(mcp: FastMCP) -> None:
    """
    Register trigger management tools (read-only).

    Triggers are automated actions that fire when pipeline statuses change.
    They are configured through the CATS UI and cannot be created via API.
    This toolset provides read access for monitoring trigger configurations.
    """

    @mcp.tool()
    async def list_triggers(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all configured triggers.

        Triggers automatically fire actions when candidates move through pipeline
        stages. Common uses:
        - Send automated emails when status changes
        - Create tasks for recruiters
        - Update custom fields
        - Fire webhooks

        Note: Triggers are configured in CATS UI, not via API.

        Wraps: GET /triggers

        Args:
            per_page: Number of results per page (default: 25, max: 100)
            page: Page number to retrieve (default: 1)

        Returns:
            dict containing:
            - triggers: List of trigger configurations
            - total_count: Total number of triggers
            - page: Current page
            - per_page: Results per page

        Trigger object contains:
        - id: Trigger ID
        - name: Trigger name
        - event: Event type (e.g., "pipeline.status_changed")
        - conditions: Trigger conditions (status changes, field values)
        - actions: Actions to perform (send_email, create_task, etc.)
        - active: Whether trigger is enabled
        - fire_count: Number of times trigger has fired
        - created_at: Creation timestamp

        Example:
            >>> triggers = await list_triggers()
            >>> for t in triggers["triggers"]:
            ...     print(f"{t['name']}: Fired {t['fire_count']} times")
        """
        return await make_request("GET", "/triggers", params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def get_trigger(trigger_id: int) -> dict[str, Any]:
        """
        Get details of a specific trigger configuration.

        Wraps: GET /triggers/{id}

        Args:
            trigger_id: The unique identifier of the trigger

        Returns:
            dict containing:
            - id: Trigger ID
            - name: Trigger name
            - description: Trigger description
            - event: Event type that fires the trigger
            - conditions: Detailed trigger conditions
            - actions: Actions performed when triggered
            - active: Whether trigger is enabled
            - fire_count: Total number of times fired
            - last_fired: Last fire timestamp
            - created_at: Creation timestamp
            - created_by: User who created the trigger

        Example:
            >>> trigger = await get_trigger(70707)
            >>> print(f"Trigger: {trigger['name']}")
            >>> print(f"Fires on: {trigger['event']}")
            >>> print(f"Actions: {len(trigger['actions'])} configured")
        """
        return await make_request("GET", f"/triggers/{trigger_id}")


def register_attachments_tools(mcp: FastMCP) -> None:
    """
    Register attachment management tools.

    Attachments include resumes, cover letters, and other documents.
    Special feature: parse_resume endpoint for AI-powered resume parsing.
    """

    @mcp.tool()
    async def get_attachment(attachment_id: int) -> dict[str, Any]:
        """
        Get metadata for a specific attachment.

        Returns attachment details but not the file content itself.
        Use download_attachment() to retrieve the actual file.

        Wraps: GET /attachments/{id}

        Args:
            attachment_id: The unique identifier of the attachment

        Returns:
            dict containing:
            - id: Attachment ID
            - filename: Original filename
            - content_type: MIME type (e.g., "application/pdf")
            - size: File size in bytes
            - entity_type: Type of entity (candidate, job, etc.)
            - entity_id: ID of the entity this is attached to
            - uploaded_by: User ID who uploaded
            - uploaded_at: Upload timestamp
            - download_url: URL to download the file

        Example:
            >>> attachment = await get_attachment(44444)
            >>> print(f"File: {attachment['filename']} ({attachment['size']} bytes)")
            >>> print(f"Type: {attachment['content_type']}")
        """
        return await make_request("GET", f"/attachments/{attachment_id}")

    @mcp.tool()
    async def delete_attachment(attachment_id: int) -> dict[str, Any]:
        """
        Delete an attachment.

        This permanently removes the attachment file and its metadata.
        The file cannot be recovered after deletion.

        Wraps: DELETE /attachments/{id}

        Args:
            attachment_id: The unique identifier of the attachment to delete

        Returns:
            dict containing:
            - success: True if deletion succeeded
            - message: Confirmation message

        Example:
            >>> result = await delete_attachment(44444)
            >>> print(result["message"])
            "Attachment successfully deleted"
        """
        return await make_request("DELETE", f"/attachments/{attachment_id}")

    @mcp.tool()
    async def download_attachment(attachment_id: int) -> dict[str, Any]:
        """
        Download an attachment file.

        Returns a pre-signed URL for downloading the file. The URL is temporary
        and expires after 1 hour.

        Wraps: GET /attachments/{id}/download

        Args:
            attachment_id: The unique identifier of the attachment

        Returns:
            dict containing:
            - download_url: Pre-signed URL for downloading (expires in 1 hour)
            - filename: Original filename
            - content_type: MIME type
            - size: File size in bytes
            - expires_at: URL expiration timestamp

        Example:
            >>> download = await download_attachment(44444)
            >>> print(f"Download URL: {download['download_url']}")
            >>> print(f"Expires: {download['expires_at']}")
            >>> # Use the URL to download the file within 1 hour
        """
        return await make_request("GET", f"/attachments/{attachment_id}/download")

    @mcp.tool()
    async def parse_resume(file_content: str, filename: str) -> dict[str, Any]:
        """
        Parse a resume using AI to extract structured data.

        This is a special endpoint that parses resume content without creating
        a candidate record. The extracted data can be used to pre-fill candidate
        creation forms or validate resume quality.

        Wraps: POST /attachments/parse

        Supported formats: PDF, DOC, DOCX, TXT, RTF

        Args:
            file_content: Base64-encoded file content
            filename: Original filename with extension

        Returns:
            dict containing extracted data:
            - name: Full name
            - first_name: First name
            - last_name: Last name
            - email: Email address(es)
            - phone: Phone number(s)
            - address: Physical address
            - summary: Professional summary
            - experience: List of work history entries
              - company: Company name
              - title: Job title
              - start_date: Start date
              - end_date: End date (or "Present")
              - description: Job description
            - education: List of education entries
              - institution: School name
              - degree: Degree earned
              - field: Field of study
              - graduation_date: Graduation date
            - skills: List of skills
            - certifications: List of certifications
            - languages: List of languages
            - linkedin_url: LinkedIn profile URL
            - confidence_score: Overall parsing confidence (0-100)

        Note: This endpoint does NOT create a candidate record or attachment.
        It only parses and returns the extracted data. Use create_candidate()
        separately if you want to create a candidate record.

        Example:
            >>> import base64
            >>> with open("resume.pdf", "rb") as f:
            ...     content = base64.b64encode(f.read()).decode()
            >>> parsed = await parse_resume(content, "resume.pdf")
            >>> print(f"Candidate: {parsed['name']}")
            >>> print(f"Email: {parsed['email']}")
            >>> print(f"Experience: {len(parsed['experience'])} jobs")
            >>> print(f"Confidence: {parsed['confidence_score']}%")
        """
        payload = {
            "file": file_content,
            "filename": filename
        }
        return await make_request("POST", "/attachments/parse", json_data=payload)


def register_backups_tools(mcp: FastMCP) -> None:
    """
    Register backup management tools.

    Backups create snapshots of your CATS data for disaster recovery.
    Options: include_attachments, include_emails
    Statuses: pending, processing, completed, expired
    """

    @mcp.tool()
    async def list_backups(
        per_page: int = 25,
        page: int = 1,
        status: Optional[str] = None
    ) -> dict[str, Any]:
        """
        List all system backups.

        Wraps: GET /backups

        Args:
            per_page: Number of results per page (default: 25, max: 100)
            page: Page number to retrieve (default: 1)
            status: Filter by status (pending, processing, completed, expired)

        Returns:
            dict containing:
            - backups: List of backup objects
            - total_count: Total number of backups
            - page: Current page
            - per_page: Results per page

        Backup object contains:
        - id: Backup ID
        - status: pending, processing, completed, or expired
        - type: full or incremental
        - size: Backup size in bytes
        - includes_attachments: Whether attachments are included
        - includes_emails: Whether emails are included
        - created_at: Backup creation timestamp
        - completed_at: Backup completion timestamp
        - expires_at: Expiration timestamp (backups expire after 90 days)
        - download_url: Pre-signed download URL (for completed backups)

        Example:
            >>> backups = await list_backups(status="completed")
            >>> latest = backups["backups"][0]
            >>> print(f"Latest backup: {latest['created_at']}")
            >>> print(f"Size: {latest['size'] / 1024 / 1024:.2f} MB")
        """
        params = {"per_page": per_page, "page": page}
        if status:
            params["status"] = status
        return await make_request("GET", "/backups", params=params)

    @mcp.tool()
    async def get_backup(backup_id: int) -> dict[str, Any]:
        """
        Get details of a specific backup.

        Wraps: GET /backups/{id}

        Args:
            backup_id: The unique identifier of the backup

        Returns:
            dict containing:
            - id: Backup ID
            - status: pending, processing, completed, or expired
            - type: full or incremental
            - size: Backup size in bytes
            - includes_attachments: Whether attachments are included
            - includes_emails: Whether emails are included
            - record_counts: Breakdown of records by type
              - candidates: Number of candidates
              - jobs: Number of jobs
              - applications: Number of applications
              - activities: Number of activities
              - etc.
            - created_at: Backup creation timestamp
            - started_at: Processing start timestamp
            - completed_at: Completion timestamp
            - expires_at: Expiration timestamp
            - download_url: Pre-signed download URL (if completed)
            - created_by: User who created the backup

        Example:
            >>> backup = await get_backup(10001)
            >>> print(f"Status: {backup['status']}")
            >>> if backup['status'] == 'completed':
            ...     print(f"Download: {backup['download_url']}")
            ...     print(f"Records: {backup['record_counts']['candidates']} candidates")
        """
        return await make_request("GET", f"/backups/{backup_id}")

    @mcp.tool()
    async def create_backup(
        include_attachments: bool = True,
        include_emails: bool = True,
        description: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Create a new system backup.

        Creates a full backup of all CATS data. The backup process is asynchronous
        and may take several minutes to hours depending on data volume.

        Backups expire after 90 days and are automatically deleted.

        Wraps: POST /backups

        Args:
            include_attachments: Include attachment files (default: True)
            include_emails: Include email history (default: True)
            description: Optional description for the backup

        Returns:
            dict containing:
            - id: New backup ID
            - status: "pending" (backup is queued for processing)
            - type: "full"
            - includes_attachments: Whether attachments are included
            - includes_emails: Whether emails are included
            - created_at: Creation timestamp
            - expires_at: Expiration timestamp (90 days from now)
            - created_by: User who created the backup

        Note: Monitor backup progress using get_backup() to check status.
        The backup status will change: pending -> processing -> completed

        Example:
            >>> backup = await create_backup(
            ...     include_attachments=True,
            ...     include_emails=False,
            ...     description="Pre-migration backup"
            ... )
            >>> print(f"Backup created with ID: {backup['id']}")
            >>> print(f"Status: {backup['status']}")
            >>> # Poll get_backup() to monitor progress
            >>> import asyncio
            >>> while True:
            ...     status = await get_backup(backup['id'])
            ...     if status['status'] == 'completed':
            ...         print(f"Backup complete! Download: {status['download_url']}")
            ...         break
            ...     await asyncio.sleep(30)  # Check every 30 seconds
        """
        payload = {
            "include_attachments": include_attachments,
            "include_emails": include_emails
        }
        if description:
            payload["description"] = description
        return await make_request("POST", "/backups", json_data=payload)


def register_events_tools(mcp: FastMCP) -> None:
    """
    Register event/calendar management tools.

    Events represent scheduled activities like interviews, meetings, calls.
    Full CRUD operations supported.
    """

    @mcp.tool()
    async def list_events(
        per_page: int = 25,
        page: int = 1,
        candidate_id: Optional[int] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None
    ) -> dict[str, Any]:
        """
        List all calendar events.

        Wraps: GET /events

        Args:
            per_page: Number of results per page (default: 25, max: 100)
            page: Page number to retrieve (default: 1)
            candidate_id: Filter by candidate ID
            start_date: Filter events starting after this date (ISO 8601)
            end_date: Filter events ending before this date (ISO 8601)

        Returns:
            dict containing:
            - events: List of event objects
            - total_count: Total number of events
            - page: Current page
            - per_page: Results per page

        Event object contains:
        - id: Event ID
        - title: Event title
        - description: Event description
        - type: interview, meeting, call, other
        - start_time: Event start timestamp (ISO 8601)
        - end_time: Event end timestamp (ISO 8601)
        - location: Physical or virtual location
        - candidate_id: Associated candidate ID (if applicable)
        - job_id: Associated job ID (if applicable)
        - attendees: List of attendee user IDs
        - created_by: User who created the event
        - created_at: Creation timestamp

        Example:
            >>> # Get upcoming events for next week
            >>> from datetime import datetime, timedelta
            >>> start = datetime.now().isoformat()
            >>> end = (datetime.now() + timedelta(days=7)).isoformat()
            >>> events = await list_events(start_date=start, end_date=end)
            >>> print(f"Upcoming events: {events['total_count']}")
            >>> for evt in events["events"]:
            ...     print(f"{evt['start_time']}: {evt['title']}")
        """
        params = {"per_page": per_page, "page": page}
        if candidate_id:
            params["candidate_id"] = candidate_id
        if start_date:
            params["start_date"] = start_date
        if end_date:
            params["end_date"] = end_date
        return await make_request("GET", "/events", params=params)

    @mcp.tool()
    async def get_event(event_id: int) -> dict[str, Any]:
        """
        Get details of a specific event.

        Wraps: GET /events/{id}

        Args:
            event_id: The unique identifier of the event

        Returns:
            dict containing:
            - id: Event ID
            - title: Event title
            - description: Event description
            - type: interview, meeting, call, other
            - start_time: Event start timestamp (ISO 8601)
            - end_time: Event end timestamp (ISO 8601)
            - duration_minutes: Event duration in minutes
            - location: Physical or virtual location
            - meeting_url: Virtual meeting URL (if applicable)
            - candidate_id: Associated candidate ID
            - candidate_name: Candidate name
            - job_id: Associated job ID
            - job_title: Job title
            - attendees: List of attendee objects
              - user_id: User ID
              - name: Attendee name
              - email: Attendee email
              - response: accepted, declined, tentative, no_response
            - reminders: Reminder settings
            - created_by: User who created the event
            - created_at: Creation timestamp
            - updated_at: Last update timestamp

        Example:
            >>> event = await get_event(60606)
            >>> print(f"Event: {event['title']}")
            >>> print(f"Time: {event['start_time']} to {event['end_time']}")
            >>> print(f"Attendees: {len(event['attendees'])}")
            >>> for att in event['attendees']:
            ...     print(f"  - {att['name']}: {att['response']}")
        """
        return await make_request("GET", f"/events/{event_id}")

    @mcp.tool()
    async def create_event(
        title: str,
        start_time: str,
        end_time: str,
        event_type: str = "meeting",
        description: Optional[str] = None,
        location: Optional[str] = None,
        meeting_url: Optional[str] = None,
        candidate_id: Optional[int] = None,
        job_id: Optional[int] = None,
        attendee_ids: Optional[list[int]] = None
    ) -> dict[str, Any]:
        """
        Create a new calendar event.

        Wraps: POST /events

        Args:
            title: Event title
            start_time: Event start timestamp (ISO 8601, e.g., "2025-11-01T14:00:00Z")
            end_time: Event end timestamp (ISO 8601)
            event_type: Type of event (interview, meeting, call, other)
            description: Event description
            location: Physical location or address
            meeting_url: Virtual meeting URL (e.g., Zoom, Google Meet)
            candidate_id: Associated candidate ID
            job_id: Associated job ID
            attendee_ids: List of user IDs to invite

        Returns:
            dict containing:
            - id: New event ID
            - title: Event title
            - type: Event type
            - start_time: Start timestamp
            - end_time: End timestamp
            - location: Location
            - attendees: List of attendee objects
            - created_at: Creation timestamp
            - calendar_invite_sent: Whether calendar invites were sent

        Example:
            >>> event = await create_event(
            ...     title="Technical Interview - Jane Doe",
            ...     start_time="2025-11-01T14:00:00Z",
            ...     end_time="2025-11-01T15:00:00Z",
            ...     event_type="interview",
            ...     meeting_url="https://zoom.us/j/123456789",
            ...     candidate_id=407373086,
            ...     job_id=16456911,
            ...     attendee_ids=[80808, 80809]
            ... )
            >>> print(f"Event created with ID: {event['id']}")
            >>> print(f"Calendar invites sent: {event['calendar_invite_sent']}")
        """
        payload = {
            "title": title,
            "start_time": start_time,
            "end_time": end_time,
            "type": event_type
        }
        if description:
            payload["description"] = description
        if location:
            payload["location"] = location
        if meeting_url:
            payload["meeting_url"] = meeting_url
        if candidate_id:
            payload["candidate_id"] = candidate_id
        if job_id:
            payload["job_id"] = job_id
        if attendee_ids:
            payload["attendee_ids"] = attendee_ids
        return await make_request("POST", "/events", json_data=payload)

    @mcp.tool()
    async def update_event(
        event_id: int,
        title: Optional[str] = None,
        start_time: Optional[str] = None,
        end_time: Optional[str] = None,
        description: Optional[str] = None,
        location: Optional[str] = None,
        meeting_url: Optional[str] = None,
        attendee_ids: Optional[list[int]] = None
    ) -> dict[str, Any]:
        """
        Update an existing calendar event.

        Only provided fields will be updated. Omitted fields remain unchanged.

        Wraps: PUT /events/{id}

        Args:
            event_id: The unique identifier of the event to update
            title: Updated event title
            start_time: Updated start timestamp (ISO 8601)
            end_time: Updated end timestamp (ISO 8601)
            description: Updated description
            location: Updated location
            meeting_url: Updated virtual meeting URL
            attendee_ids: Updated list of attendee user IDs

        Returns:
            dict containing:
            - id: Event ID
            - title: Updated title
            - start_time: Updated start time
            - end_time: Updated end time
            - updated_at: Update timestamp
            - calendar_update_sent: Whether update notifications were sent

        Example:
            >>> updated = await update_event(
            ...     event_id=60606,
            ...     start_time="2025-11-01T15:00:00Z",  # Reschedule
            ...     end_time="2025-11-01T16:00:00Z",
            ...     location="Conference Room B"
            ... )
            >>> print(f"Event updated: {updated['title']}")
            >>> print(f"New time: {updated['start_time']}")
        """
        payload = {}
        if title is not None:
            payload["title"] = title
        if start_time is not None:
            payload["start_time"] = start_time
        if end_time is not None:
            payload["end_time"] = end_time
        if description is not None:
            payload["description"] = description
        if location is not None:
            payload["location"] = location
        if meeting_url is not None:
            payload["meeting_url"] = meeting_url
        if attendee_ids is not None:
            payload["attendee_ids"] = attendee_ids
        return await make_request("PUT", f"/events/{event_id}", json_data=payload)

    @mcp.tool()
    async def delete_event(event_id: int) -> dict[str, Any]:
        """
        Delete a calendar event.

        This permanently removes the event. Attendees will receive cancellation
        notifications.

        Wraps: DELETE /events/{id}

        Args:
            event_id: The unique identifier of the event to delete

        Returns:
            dict containing:
            - success: True if deletion succeeded
            - message: Confirmation message
            - cancellation_sent: Whether cancellation notifications were sent

        Example:
            >>> result = await delete_event(60606)
            >>> print(result["message"])
            "Event successfully deleted and attendees notified"
        """
        return await make_request("DELETE", f"/events/{event_id}")


# Export all registration functions
__all__ = [
    "register_tags_tools",
    "register_webhooks_tools",
    "register_users_tools",
    "register_triggers_tools",
    "register_attachments_tools",
    "register_backups_tools",
    "register_events_tools",
]
