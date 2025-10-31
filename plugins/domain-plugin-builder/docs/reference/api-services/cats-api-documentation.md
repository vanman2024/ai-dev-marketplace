# CATS API v3 - Complete Endpoint Reference

**Base URL:** `https://api.catsone.com/v3`  
**Authentication:** `Authorization: Token <Your API Key>`  
**Content-Type:** `application/json`  
**Rate Limit:** 500 requests per hour (rolling basis)

---

## Overview

- **Host:** https://api.catsone.com/v3
- **Authentication:** Token-based (v3 API Key required)
- **Format:** JSON only (input/output)
- **Date Format:** RFC 3339 (ISO-8601 UTC) - `YYYY-MM-DDThh:mm:ssZ`
- **Country Codes:** ISO 3166 Alpha-2 (e.g., US, NL)
- **HAL:** Hypertext Application Language (`_links` and `_embedded` keys)
- **Pagination:** `page` (default: 1), `per_page` (default: 25, max: 100)
- **Rate Limiting:** 500 requests/hour with `X-Rate-Limit-Limit` and `X-Rate-Limit-Remaining` headers

---

## 1. Activities

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/activities{?page,per_page}` | List all activities |
| GET | `/activities/{id}` | Get an activity |
| PUT | `/activities/{id}` | Update an activity |
| DELETE | `/activities/{id}` | Delete an activity |
| GET | `/activities/search{?query,page,per_page}` | Search activities |
| POST | `/activities/search{?query,page,per_page}` | Filter activities |

### Activity Types
- `email`
- `meeting`
- `call_talked`
- `call_lvm`
- `call_missed`
- `text_message`
- `other`

### Filterable Fields
- `id` - greater_than, less_than, between, exactly, is_empty
- `data_item.id` - greater_than, less_than, between, exactly, is_empty
- `data_item.type` - exactly, is_empty
- `date` - greater_than, less_than, between, is_empty
- `regarding_id` - greater_than, less_than, between, exactly, is_empty
- `type` - exactly, is_empty
- `notes` - contains, exactly, is_empty
- `entered_by_id` - greater_than, less_than, between, exactly, is_empty
- `date_created` - greater_than, less_than, between, is_empty
- `date_modified` - greater_than, less_than, between, is_empty

---

## 2. Attachments

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/attachments/{id}` | Get an attachment |
| DELETE | `/attachments/{id}` | Delete an attachment |
| GET | `/attachments/{id}/download` | Download an attachment |
| POST | `/attachments/parse` | Parse a resume (returns candidate object without creating record) |

### Resume Parsing
- **Content-Type:** `application/octet-stream`
- **Method:** POST with `--data-binary @filename.txt`
- **Returns:** Parsed candidate data (no record created)
- **Next Step:** POST to `/candidates{?check_duplicate=true}` to create record

---

## 3. Backups

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/backups{?page,per_page}` | List all backups |
| GET | `/backups/{id}` | Get a backup |
| POST | `/backups` | Create a backup |

### Backup Options
- `include_attachments` (boolean) - Default: false
- `include_emails` (boolean) - Default: true

### Backup Statuses
- `pending`
- `processing`
- `completed`
- `expired`

---

## 4. Candidates

### Main Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/candidates{?page,per_page}` | List all candidates |
| GET | `/candidates/{id}` | Get a candidate |
| POST | `/candidates{?check_duplicate}` | Create a candidate |
| PUT | `/candidates/{id}` | Update a candidate |
| DELETE | `/candidates/{id}` | Delete a candidate |
| POST | `/candidates/authorization` | Authorize a candidate (login) |
| GET | `/candidates/{id}/pipelines{?page,per_page}` | List pipelines by candidate |
| GET | `/candidates/search{?query,page,per_page}` | Search candidates |
| POST | `/candidates/search{?query,page,per_page}` | Filter candidates |

### Candidate Sub-Resources

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/candidates/{id}/activities{?page,per_page}` | List candidate activities |
| POST | `/candidates/{id}/activities` | Create candidate activity |
| GET | `/candidates/{id}/attachments{?page,per_page}` | List candidate attachments |
| POST | `/candidates/{id}/attachments` | Upload candidate attachment |
| GET | `/candidates/{id}/custom_fields{?page,per_page}` | List candidate custom fields |
| GET | `/candidates/{id}/emails{?page,per_page}` | List candidate emails |
| POST | `/candidates/{id}/emails` | Create candidate email |
| PUT | `/candidates/{id}/emails/{email_id}` | Update candidate email |
| DELETE | `/candidates/{id}/emails/{email_id}` | Delete candidate email |
| GET | `/candidates/{id}/phones{?page,per_page}` | List candidate phones |
| POST | `/candidates/{id}/phones` | Create candidate phone |
| PUT | `/candidates/{id}/phones/{phone_id}` | Update candidate phone |
| DELETE | `/candidates/{id}/phones/{phone_id}` | Delete candidate phone |
| GET | `/candidates/{id}/tags{?page,per_page}` | List candidate tags |
| POST | `/candidates/{id}/tags` | Replace candidate tags |
| PUT | `/candidates/{id}/tags` | Attach candidate tags |
| DELETE | `/candidates/{id}/tags/{tag_id}` | Delete candidate tag |
| GET | `/candidates/{id}/work_history{?page,per_page}` | List work history |
| POST | `/candidates/{id}/work_history` | Create work history |

### Key Features
- **Duplicate Checking:** `check_duplicate=true` parameter on create
- **Registration:** Set `password` field to enable candidate portal login
- **Authorization:** POST to `/candidates/authorization` with email/password
- **Custom Fields:** Support for custom field types (text, number, date, dropdown, radio, checkboxes, checkbox, user)

### Filterable Fields
Extensive filtering on all standard fields plus custom fields by ID.

---

## 5. Companies

### Main Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/companies{?page,per_page}` | List all companies |
| GET | `/companies/{id}` | Get a company |
| POST | `/companies{?check_duplicate}` | Create a company |
| PUT | `/companies/{id}` | Update a company |
| DELETE | `/companies/{id}` | Delete a company |
| GET | `/companies/search{?query,page,per_page}` | Search companies |
| POST | `/companies/search{?query,page,per_page}` | Filter companies |

### Company Sub-Resources

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/companies/{id}/activities{?page,per_page}` | List company activities |
| POST | `/companies/{id}/activities` | Create company activity |
| GET | `/companies/{id}/attachments{?page,per_page}` | List company attachments |
| POST | `/companies/{id}/attachments` | Upload company attachment |
| GET | `/companies/{id}/contacts{?page,per_page}` | List company contacts |
| GET | `/companies/{id}/custom_fields{?page,per_page}` | List company custom fields |
| GET | `/companies/{id}/departments{?page,per_page}` | List company departments |
| POST | `/companies/{id}/departments` | Create company department |
| PUT | `/companies/{id}/departments/{department_id}` | Update company department |
| DELETE | `/companies/{id}/departments/{department_id}` | Delete company department |
| GET | `/companies/{id}/pipelines{?page,per_page}` | List company pipelines |
| GET | `/companies/{id}/tags{?page,per_page}` | List company tags |
| POST | `/companies/{id}/tags` | Replace company tags |
| PUT | `/companies/{id}/tags` | Attach company tags |
| DELETE | `/companies/{id}/tags/{tag_id}` | Delete company tag |

---

## 6. Contacts

### Main Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/contacts{?page,per_page}` | List all contacts |
| GET | `/contacts/{id}` | Get a contact |
| POST | `/contacts{?check_duplicate}` | Create a contact |
| PUT | `/contacts/{id}` | Update a contact |
| DELETE | `/contacts/{id}` | Delete a contact |
| GET | `/contacts/search{?query,page,per_page}` | Search contacts |
| POST | `/contacts/search{?query,page,per_page}` | Filter contacts |

### Contact Sub-Resources

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/contacts/{id}/activities{?page,per_page}` | List contact activities |
| POST | `/contacts/{id}/activities` | Create contact activity |
| GET | `/contacts/{id}/attachments{?page,per_page}` | List contact attachments |
| POST | `/contacts/{id}/attachments` | Upload contact attachment |
| GET | `/contacts/{id}/custom_fields{?page,per_page}` | List contact custom fields |
| GET | `/contacts/{id}/emails{?page,per_page}` | List contact emails |
| POST | `/contacts/{id}/emails` | Create contact email |
| PUT | `/contacts/{id}/emails/{email_id}` | Update contact email |
| DELETE | `/contacts/{id}/emails/{email_id}` | Delete contact email |
| GET | `/contacts/{id}/phones{?page,per_page}` | List contact phones |
| POST | `/contacts/{id}/phones` | Create contact phone |
| PUT | `/contacts/{id}/phones/{phone_id}` | Update contact phone |
| DELETE | `/contacts/{id}/phones/{phone_id}` | Delete contact phone |
| GET | `/contacts/{id}/pipelines{?page,per_page}` | List contact pipelines |
| GET | `/contacts/{id}/tags{?page,per_page}` | List contact tags |
| POST | `/contacts/{id}/tags` | Replace contact tags |
| PUT | `/contacts/{id}/tags` | Attach contact tags |
| DELETE | `/contacts/{id}/tags/{tag_id}` | Delete contact tag |

---

## 7. Events

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/events{?page,per_page}` | List all events |
| GET | `/events/{id}` | Get an event |
| POST | `/events` | Create an event |
| PUT | `/events/{id}` | Update an event |
| DELETE | `/events/{id}` | Delete an event |

---

## 8. Jobs

### Main Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/jobs{?page,per_page}` | List all jobs |
| GET | `/jobs/{id}` | Get a job |
| POST | `/jobs` | Create a job |
| PUT | `/jobs/{id}` | Update a job |
| DELETE | `/jobs/{id}` | Delete a job |
| GET | `/jobs/search{?query,page,per_page}` | Search jobs |
| POST | `/jobs/search{?query,page,per_page}` | Filter jobs |

### Job Sub-Resources

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/jobs/{id}/activities{?page,per_page}` | List job activities |
| POST | `/jobs/{id}/activities` | Create job activity |
| GET | `/jobs/{id}/attachments{?page,per_page}` | List job attachments |
| POST | `/jobs/{id}/attachments` | Upload job attachment |
| GET | `/jobs/{id}/custom_fields{?page,per_page}` | List job custom fields |
| GET | `/jobs/{id}/departments{?page,per_page}` | List job departments |
| GET | `/jobs/{id}/interviews{?page,per_page}` | List job interviews |
| POST | `/jobs/{id}/interviews` | Create job interview |
| PUT | `/jobs/{id}/interviews/{interview_id}` | Update job interview |
| DELETE | `/jobs/{id}/interviews/{interview_id}` | Delete job interview |
| GET | `/jobs/{id}/pipelines{?page,per_page}` | List job pipelines |
| GET | `/jobs/{id}/questionnaires{?page,per_page}` | List job questionnaires |
| GET | `/jobs/{id}/scorecards{?page,per_page}` | List job scorecards |
| POST | `/jobs/{id}/scorecards` | Create job scorecard |
| PUT | `/jobs/{id}/scorecards/{scorecard_id}` | Update job scorecard |
| DELETE | `/jobs/{id}/scorecards/{scorecard_id}` | Delete job scorecard |
| GET | `/jobs/{id}/tags{?page,per_page}` | List job tags |
| POST | `/jobs/{id}/tags` | Replace job tags |
| PUT | `/jobs/{id}/tags` | Attach job tags |
| DELETE | `/jobs/{id}/tags/{tag_id}` | Delete job tag |
| GET | `/jobs/{id}/workflows{?page,per_page}` | List job workflows |

### Job Lists

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/jobs/lists{?page,per_page}` | List all job lists |
| GET | `/jobs/lists/{id}` | Get a job list |
| POST | `/jobs/lists` | Create a job list |
| PUT | `/jobs/lists/{id}` | Update a job list |
| DELETE | `/jobs/lists/{id}` | Delete a job list |
| GET | `/jobs/lists/{id}/items{?page,per_page}` | List all job list items |
| GET | `/jobs/lists/{list_id}/items/{item_id}` | Get a job list item |
| POST | `/jobs/lists/{id}/items` | Create job list items (attach jobs) |
| DELETE | `/jobs/lists/{list_id}/items/{item_id}` | Delete a job list item (remove job) |

### Job Applications

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/jobs/{job_id}/applications{?page,per_page}` | List applications by job |
| GET | `/jobs/applications/{application_id}` | Get a job application |
| GET | `/jobs/applications/{application_id}/fields{?page,per_page}` | List job application fields |

---

## 9. Pipelines

### Main Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/pipelines{?page,per_page}` | List all pipelines |
| GET | `/pipelines/{id}` | Get a pipeline |
| POST | `/pipelines{?create_activity}` | Create a pipeline |
| PUT | `/pipelines/{id}` | Update a pipeline |
| DELETE | `/pipelines/{id}{?create_activity}` | Delete a pipeline |
| POST | `/pipelines/search{?page,per_page}` | Filter pipelines |

### Workflow Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/pipelines/workflows{?page,per_page}` | List workflows |
| GET | `/pipelines/workflows/{id}` | Get a workflow |
| GET | `/pipelines/workflows/{workflow_id}/statuses{?page,per_page}` | List workflow statuses |
| GET | `/pipelines/workflows/{workflow_id}/statuses/{status_id}` | Get a workflow status |

### Pipeline Status Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/pipelines/{id}/statuses` | Get pipeline historical statuses |
| POST | `/pipelines/{id}/status{?create_activity}` | Change pipeline status |

### Key Features
- **Activity Creation:** `create_activity=true` parameter to automatically create activity
- **Ratings:** 0-5 rating system for candidate/job fit
- **Triggers:** Optional trigger firing when changing status
- **Prerequisites:** Status prerequisites must be met before advancing

### Filterable Fields
- `id` - greater_than, less_than, between, exactly, is_empty
- `candidate_id` - greater_than, less_than, between, exactly, is_empty
- `job_id` - greater_than, less_than, between, exactly, is_empty
- `status_id` - greater_than, less_than, between, exactly, is_empty
- `rating` - greater_than, less_than, between, exactly, is_empty
- `date_created` - greater_than, less_than, between, is_empty
- `date_modified` - greater_than, less_than, between, is_empty

---

## 10. Portals

### Main Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/portals{?page,per_page}` | List all portals |
| GET | `/portals/{id}` | Get a portal |
| GET | `/portals/{id}/jobs{?page,per_page}` | List portal jobs |
| POST | `/portals/{portal_id}/jobs/{job_id}` | Submit job application |
| PUT | `/portals/{portal_id}/jobs/{job_id}` | Publish job to portal |
| DELETE | `/portals/{portal_id}/jobs/{job_id}` | Unpublish job from portal |

### Portal Registration

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/portals/{id}/registration` | Get portal registration application |
| POST | `/portals/{id}/registration` | Submit portal registration application |

### Application Submission
**Field Types:**
- **file:** Base64 encoded string with `filename` parameter
- **text:** String value
- **multiline:** String with `\r\n` line breaks
- **checkbox:** Boolean value
- **checkboxes:** Object with answer IDs as keys (e.g., `{"3251": true, "3991": true}`)
- **radio/select:** Object with single answer ID as key (e.g., `{"4126": true}`)

**Optional Source Parameter:**
- If applicant is new: sets their source
- If applicant exists: does NOT overwrite existing source
- Default: "Career Portal"

---

## 11. Site

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/site` | Get site information (associated with API token) |

**Returns:**
- Site ID
- Mode (`recruiter` or other)
- Subdomain

---

## 12. Tags

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/tags{?page,per_page}` | List all tags |
| GET | `/tags/{id}` | Get a tag |

**Note:** Tags are attached/detached via sub-resource endpoints on candidates, contacts, companies, and jobs.

---

## 13. Tasks

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/tasks{?page,per_page}` | List all tasks |
| GET | `/tasks/{id}` | Get a task |
| POST | `/tasks` | Create a task |
| PUT | `/tasks/{id}` | Update a task |
| DELETE | `/tasks/{id}` | Delete a task |

### Task Properties
- **Priority:** 1-5 (1 = lowest)
- **Data Item:** Optional link to candidate/contact/company/job
- **Assigned To:** User ID
- **Date Due:** Optional (null = ASAP)
- **Is Completed:** Boolean flag

---

## 14. Triggers

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/triggers{?page,per_page}` | List all triggers |
| GET | `/triggers/{id}` | Get a trigger |

**Note:** Triggers are read-only via API and are fired when changing pipeline statuses.

---

## 15. Users

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users{?page,per_page}` | List all users |
| GET | `/users/{id}` | Get a user |

**Access Levels:**
- `read_only`
- `edit`
- `admin`
- (other levels as configured)

---

## 16. Webhooks

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/webhooks{?page,per_page}` | List all webhooks |
| GET | `/webhooks/{id}` | Get a webhook |
| POST | `/webhooks` | Create a webhook |
| DELETE | `/webhooks/{id}` | Delete a webhook |

### Webhook Events (24 types)

**Created Events:**
- `candidate.created`
- `job.created`
- `contact.created`
- `company.created`
- `activity.created`
- `user.created`
- `pipeline.created`

**Updated Events:**
- `candidate.updated`
- `job.updated`
- `contact.updated`
- `company.updated`
- `activity.updated`
- `user.updated`

**Deleted Events:**
- `candidate.deleted`
- `job.deleted`
- `contact.deleted`
- `company.deleted`
- `activity.deleted`
- `user.deleted`
- `pipeline.deleted`

**Status Changed Events:**
- `job.status_changed`
- `contact.status_changed`
- `company.status_changed`
- `pipeline.status_changed`

### Webhook Security
**Signature Verification (Highly Recommended):**
1. Set `secret` parameter when creating webhook
2. Webhooks include `X-Signature` header
3. Verification process:
   - Take webhook body
   - Append `X-Request-Id` header value
   - Generate HMAC-SHA256 hash using your secret as key
   - Compare with `X-Signature` header

**Example:**
```php
$secret = 'yourSecretHere';
$webhookBody = '{}';
$requestId = '5d6ce3f9-cce8-4b5b-a26e-396a6161eb99'; // X-Request-Id header
$signature = 'HMAC-SHA256 affc8d589...'; // X-Signature header
$hash = hash_hmac('sha256', $webhookBody . $requestId, $secret, false);
if ($signature !== 'HMAC-SHA256 ' . $hash) {
    // Reject it
}
```

### Webhook Behavior
- **Automatic Deletion:** Returns 410 status code to delete webhook
- **Failure Handling:** 50 consecutive 500 errors within 30 minutes disables webhook
- **Embed Limit:** Webhooks return up to 1,000 of each embed type (vs API's 25 limit)
- **Mass Updates:** Mass record updates fire individual webhooks for ALL affected records

---

## 17. Work History

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/work_history/{work_history_id}` | Get a work history |
| PUT | `/work_history/{work_history_id}` | Update a work history |
| DELETE | `/work_history/{work_history_id}` | Delete a work history |

**Note:** Work history is created via candidate sub-resource endpoint: `POST /candidates/{id}/work_history`

### Employer Linking
**Unlinked:**
```json
{
  "linked": false
  "name": "Company Name"
  "location": {
    "city": "City"
    "state": "State"
  }
}
```

**Linked:**
```json
{
  "linked": true
  "company_id": 465
}
```

### Supervisor Linking
**Unlinked:**
```json
{
  "linked": false
  "name": "Supervisor Name"
  "phone": "+1234567890"
}
```

**Linked:**
```json
{
  "linked": true
  "contact_id": 6864
}
```

---

## Search Filters

### Filter Types
- `exactly` - string, int, or boolean
- `contains` - string
- `between` - object with `gte` and `lte` keys (int or date string)
- `greater_than` - int or date string
- `less_than` - int or date string
- `is_empty` - boolean (must be `true`)
- `geo_distance` - object with `postal_code`, `distance`, `unit` (`km` or `miles`)

### Boolean Operators
- `and` - List of filters/booleans
- `or` - List of filters/booleans
- `not` - Single filter

### Custom Field Filters
- **Text:** contains, exactly, is_empty
- **Number:** exactly, greater_than, less_than, between, is_empty
- **Date:** greater_than, less_than, between, is_empty
- **Dropdown:** exactly, is_empty
- **Radio:** exactly, is_empty
- **Checkboxes:** exactly, is_empty
- **Checkbox:** exactly
- **User:** exactly, is_empty

### Example Filter
```json
{
  "and": [
    {"field": "first_name", "filter": "exactly", "value": "Scott"}
    {"field": "last_name", "filter": "exactly", "value": "Summers"}
    {"not": {"field": "middle_name", "filter": "exactly", "value": "Joseph"}}
    {
      "or": [
        {"field": "title", "filter": "contains", "value": "team leader"}
        {"field": "title", "filter": "contains", "value": "squad leader"}
      ]
    }
    {"not": {"field": "key_skills", "filter": "contains", "value": "subtlety"}}
  ]
}
```

---

## Common Data Types

### DataItem Object
```json
{
  "id": 5019
  "type": "candidate"
}
```

**Types:** `candidate`, `contact`, `company`, `job`

### HAL Structure
```json
{
  "_links": {
    "self": {"href": "/candidates/749"}
    "owner": {"href": "/users/5459"}
    "activities": {"href": "/candidates/749/activities"}
  }
  "_embedded": {
    "custom_fields": [
      {"id": 170911, "value": "marquise"}
    ]
  }
}
```

---

## Error Handling

### Rate Limiting
**Headers:**
- `X-Rate-Limit-Limit: <Total limit allowed>`
- `X-Rate-Limit-Remaining: <Remaining requests>`

**429 Response:**
```
429 Too Many Requests
Retry-After: <Number of seconds until another request may be made>
```

### Common Status Codes
- **200 OK** - Successful GET request
- **201 Created** - Successful POST request (includes `Location` header)
- **204 No Content** - Successful PUT/DELETE request
- **400 Bad Request** - Invalid request data
- **401 Unauthorized** - Invalid or missing API key
- **404 Not Found** - Resource not found
- **409 Conflict** - Duplicate record (with `check_duplicate=true`)
- **429 Too Many Requests** - Rate limit exceeded
- **500 Internal Server Error** - Server error

---

## Best Practices

1. **Use `check_duplicate` parameter** when creating candidates/contacts/companies
2. **Set webhook secrets** for security verification
3. **Monitor rate limits** via response headers
4. **Use filtering** instead of fetching all records and filtering client-side
5. **Leverage HAL `_embedded` data** to reduce additional API calls
6. **Set `create_activity` parameter** when working with pipelines to mirror UI behavior
7. **Use pagination** with appropriate `per_page` values (max 100)
8. **Parse resumes first** with `/attachments/parse` before creating candidates
9. **Link work history to companies/contacts** when possible for data integrity
10. **Subscribe to webhooks** for real-time updates instead of polling

---

## Changelog & Support

- **Changelog:** https://docs.catsone.com/api/v3/changelog.html
- **Mailing List:** Sign up at https://docs.catsone.com/api/v3/#mailing-list
- **Community Forums:** https://groups.google.com/forum/#!forum/cats-api-v3

---

## Total Endpoint Count

**Main Resources:** 17 categories  
**Total Endpoints:** 150+ endpoints including all sub-resources

**Breakdown by Category:**
- Activities: 6 endpoints
- Attachments: 4 endpoints
- Backups: 3 endpoints
- Candidates: 28+ endpoints (including sub-resources)
- Companies: 18+ endpoints (including sub-resources)
- Contacts: 18+ endpoints (including sub-resources)
- Events: 5 endpoints
- Jobs: 40+ endpoints (including sub-resources, lists, applications)
- Pipelines: 13 endpoints (including workflows and status management)
- Portals: 8 endpoints (including registration)
- Site: 1 endpoint
- Tags: 2 endpoints
- Tasks: 5 endpoints
- Triggers: 2 endpoints
- Users: 2 endpoints
- Webhooks: 4 endpoints
- Work History: 3 endpoints

---

**Generated:** 2025-01-22  
**API Version:** v3  
**Documentation Source:** https://docs.catsone.com/api/v3/
