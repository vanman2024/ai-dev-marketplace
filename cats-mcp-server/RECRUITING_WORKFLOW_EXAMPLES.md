# CATS Recruiting Toolsets - Workflow Examples

Practical examples showing how to use the recruiting toolsets for common recruiting workflows.

## Workflow 1: Company Onboarding

Complete workflow for onboarding a new client company.

```python
# 1. Create the company
company = await create_company(
    name="TechCorp Inc.",
    website="https://techcorp.com",
    phone="+1-555-0100",
    address="123 Tech Street",
    city="San Francisco",
    state="CA",
    zip_code="94102",
    notes="Growing tech startup, 50-100 employees"
)
company_id = company["id"]

# 2. Add company departments
engineering_dept = await create_company_department(
    company_id=company_id,
    name="Engineering",
    description="Software development and infrastructure"
)

sales_dept = await create_company_department(
    company_id=company_id,
    name="Sales",
    description="B2B sales and account management"
)

# 3. Add primary contact
primary_contact = await create_contact(
    first_name="Jane",
    last_name="Smith",
    email="jane.smith@techcorp.com",
    company_id=company_id,
    title="VP of Engineering",
    phone="+1-555-0101",
    notes="Primary hiring manager for engineering roles"
)

# 4. Add hiring manager contact
hiring_manager = await create_contact(
    first_name="John",
    last_name="Doe",
    email="john.doe@techcorp.com",
    company_id=company_id,
    title="Senior Engineering Manager",
    phone="+1-555-0102"
)

# 5. Tag the company
await attach_company_tags(
    company_id=company_id,
    tag_ids=[101, 102, 103]  # Tags: "Active Client", "Tech", "San Francisco"
)

# 6. Create initial activity
await create_company_activity(
    company_id=company_id,
    activity_type="meeting",
    description="Initial kickoff meeting",
    notes="Discussed hiring needs: 3 Senior Engineers, 2 Product Managers"
)
```

---

## Workflow 2: Contact Management

Managing contacts and their communication channels.

```python
# 1. Create contact with basic info
contact = await create_contact(
    first_name="Sarah",
    last_name="Johnson",
    email="sarah.johnson@example.com",
    company_id=12345,
    title="Director of HR"
)
contact_id = contact["id"]

# 2. Add additional email addresses
await create_contact_email(
    contact_id=contact_id,
    email="sjohnson@example.com",
    email_type="work"
)

await create_contact_email(
    contact_id=contact_id,
    email="sarah.j.personal@gmail.com",
    email_type="personal"
)

# 3. Add phone numbers
await create_contact_phone(
    contact_id=contact_id,
    phone="+1-555-1234",
    phone_type="work"
)

await create_contact_phone(
    contact_id=contact_id,
    phone="+1-555-5678",
    phone_type="mobile"
)

# 4. List all contact methods
emails = await list_contact_emails(contact_id=contact_id)
phones = await list_contact_phones(contact_id=contact_id)

print(f"Contact has {len(emails)} email addresses and {len(phones)} phone numbers")

# 5. Update primary email if needed
if emails[0]["email"] != "sarah.johnson@example.com":
    await update_contact_email(
        contact_id=contact_id,
        email_id=emails[0]["id"],
        email="sarah.johnson@example.com",
        email_type="work"
    )
```

---

## Workflow 3: Activity Tracking

Tracking all interactions with companies and contacts.

```python
# 1. Log initial outreach
outreach_activity = await create_company_activity(
    company_id=12345,
    activity_type="email",
    description="Sent introduction email",
    notes="Introduced our recruiting services, shared case studies"
)

# 2. Log follow-up call
call_activity = await create_contact_activity(
    contact_id=67890,
    activity_type="call_talked",
    description="Discovery call with hiring manager",
    notes="Discussed Q4 hiring needs: 5 engineers, 2 designers. Budget approved."
)

# 3. Schedule meeting
meeting_activity = await create_company_activity(
    company_id=12345,
    activity_type="meeting",
    description="Calendly meeting scheduled for 2025-11-01 at 2 PM PST",
    notes="Will discuss technical requirements and interview process"
)

# 4. Search all activities for a company
company_activities = await list_company_activities(
    company_id=12345,
    per_page=50,
    page=1
)

print(f"Total activities for company: {len(company_activities)}")

# 5. Filter activities by type
email_activities = await filter_activities(
    filters={
        "type": "email",
        "company_id": 12345
    },
    per_page=25
)

print(f"Email activities: {len(email_activities)}")

# 6. Update activity after meeting
await update_activity(
    activity_id=meeting_activity["id"],
    completed=True,
    notes="Meeting completed. Client agreed to move forward with 3 positions."
)
```

---

## Workflow 4: Job Portal Management

Publishing jobs to external portals and tracking applications.

```python
# 1. List available portals
portals = await list_portals(per_page=50)
print(f"Configured portals: {len(portals)}")

# Find Indeed portal
indeed_portal = next((p for p in portals if p["name"] == "Indeed"), None)
linkedin_portal = next((p for p in portals if p["name"] == "LinkedIn"), None)

# 2. Publish job to multiple portals
job_id = 16456911  # Existing job posting

# Publish to Indeed
await publish_job_to_portal(
    portal_id=indeed_portal["id"],
    job_id=job_id
)

# Publish to LinkedIn
await publish_job_to_portal(
    portal_id=linkedin_portal["id"],
    job_id=job_id
)

# 3. Check jobs on a portal
indeed_jobs = await list_portal_jobs(
    portal_id=indeed_portal["id"],
    per_page=50
)

print(f"Jobs on Indeed: {len(indeed_jobs)}")

# 4. Monitor applications from portal
# Applications come through the portal API
# Use submit_job_application for programmatic submissions

# 5. Unpublish job when filled
await unpublish_job_from_portal(
    portal_id=indeed_portal["id"],
    job_id=job_id
)

await unpublish_job_from_portal(
    portal_id=linkedin_portal["id"],
    job_id=job_id
)

# 6. Configure new portal
registration_info = await get_portal_registration(portal_id=999)
print(f"Registration requirements: {registration_info}")

# Submit registration
await submit_portal_registration(
    portal_id=999,
    registration_data={
        "api_key": "portal_api_key_here",
        "company_name": "Your Recruiting Agency",
        "contact_email": "admin@agency.com"
    }
)
```

---

## Workflow 5: Work History Management

Managing candidate work history through the candidate profile.

```python
# 1. Add work history to candidate (via candidate sub-resource)
# Note: Creation happens via POST /candidates/{id}/work_history
# This is handled in the candidates toolset, not recruiting toolsets

# 2. Get work history details
work_history = await get_work_history(work_history_id=99999)
print(f"Position: {work_history['title']} at {work_history['company_name']}")
print(f"Duration: {work_history['start_date']} to {work_history['end_date']}")

# 3. Update work history (e.g., candidate still employed)
await update_work_history(
    work_history_id=99999,
    end_date=None,
    currently_employed=True,
    description="Updated: Promoted to Senior Engineer in 2024"
)

# 4. Correct work history details
await update_work_history(
    work_history_id=99999,
    company_name="TechCorp Inc. (formerly StartupXYZ)",
    title="Senior Software Engineer",
    start_date="2020-06-01"
)

# 5. Remove outdated work history
await delete_work_history(work_history_id=88888)
```

---

## Workflow 6: Company Search & Filtering

Finding and filtering companies based on various criteria.

```python
# 1. Simple search by name
results = await search_companies(
    query="Tech",
    per_page=25
)
print(f"Companies matching 'Tech': {len(results)}")

# 2. Advanced filtering by location
sf_companies = await filter_companies(
    filters={
        "city": "San Francisco",
        "state": "CA"
    },
    per_page=50,
    page=1
)

# 3. Filter by multiple criteria
target_companies = await filter_companies(
    filters={
        "state": "CA",
        "tags": ["Active Client", "Tech"],
        "has_open_jobs": True
    },
    per_page=100,
    page=1
)

# 4. Get all companies with pagination
all_companies = []
page = 1
while True:
    batch = await list_companies(per_page=100, page=page)
    all_companies.extend(batch["companies"])

    if len(batch["companies"]) < 100:
        break
    page += 1

print(f"Total companies: {len(all_companies)}")

# 5. Search within specific company data
for company in all_companies:
    if "engineering" in company.get("notes", "").lower():
        print(f"Engineering company: {company['name']}")
```

---

## Workflow 7: Contact Search & Management

Finding and organizing contacts.

```python
# 1. Search contacts by name
contacts = await search_contacts(
    query="Sarah",
    per_page=25
)

# 2. Find contacts at specific company
company_contacts = await list_company_contacts(
    company_id=12345,
    per_page=50
)

# 3. Filter hiring managers
hiring_managers = await filter_contacts(
    filters={
        "title_contains": "Manager",
        "tags": ["Hiring Manager"]
    },
    per_page=100
)

# 4. Get all contacts with email addresses
for contact in company_contacts:
    contact_id = contact["id"]

    # Get detailed info
    full_contact = await get_contact(contact_id)

    # Get all emails
    emails = await list_contact_emails(contact_id)

    print(f"{full_contact['first_name']} {full_contact['last_name']}")
    print(f"  Emails: {[e['email'] for e in emails]}")

    # Get all phones
    phones = await list_contact_phones(contact_id)
    print(f"  Phones: {[p['phone'] for p in phones]}")
```

---

## Workflow 8: Tagging Strategy

Organizing companies and contacts with tags.

```python
# 1. List all company tags
company_tags = await list_company_tags(company_id=12345)
print(f"Current tags: {[t['name'] for t in company_tags]}")

# 2. Replace all tags (replaces existing)
await replace_company_tags(
    company_id=12345,
    tag_ids=[101, 102, 103]  # "Active", "Tech", "Priority"
)

# 3. Add additional tags (additive)
await attach_company_tags(
    company_id=12345,
    tag_ids=[104, 105]  # Add "San Francisco", "Series B"
)

# 4. Remove specific tags
await delete_company_tags(
    company_id=12345,
    tag_ids=[102]  # Remove "Tech" tag
)

# 5. Apply same tags to multiple companies
priority_companies = [12345, 67890, 11111]
priority_tag_ids = [103]  # "Priority" tag

for company_id in priority_companies:
    await attach_company_tags(
        company_id=company_id,
        tag_ids=priority_tag_ids
    )

# 6. Tag contacts similarly
await attach_contact_tags(
    contact_id=67890,
    tag_ids=[201, 202]  # "Decision Maker", "Engineering"
)
```

---

## Workflow 9: Multi-Channel Communication

Tracking all communication channels with a contact.

```python
# Get contact
contact = await get_contact(contact_id=67890)

# 1. Get all communication activities
activities = await list_contact_activities(
    contact_id=67890,
    per_page=100
)

# 2. Segment by activity type
emails = [a for a in activities if a["type"] == "email"]
calls = [a for a in activities if a["type"] in ["call_talked", "call_lvm", "call_missed"]]
meetings = [a for a in activities if a["type"] == "meeting"]

print(f"Communication breakdown:")
print(f"  Emails: {len(emails)}")
print(f"  Calls: {len(calls)}")
print(f"  Meetings: {len(meetings)}")

# 3. Get all contact methods
emails_list = await list_contact_emails(contact_id=67890)
phones_list = await list_contact_phones(contact_id=67890)

print(f"\nContact methods:")
print(f"  Email addresses: {len(emails_list)}")
print(f"  Phone numbers: {len(phones_list)}")

# 4. Add new activity for each channel
# Email outreach
await create_contact_activity(
    contact_id=67890,
    activity_type="email",
    description="Sent job opportunity email"
)

# Phone follow-up
await create_contact_activity(
    contact_id=67890,
    activity_type="call_talked",
    description="Discussed candidate requirements",
    notes="Looking for senior-level with React experience"
)

# Schedule meeting
await create_contact_activity(
    contact_id=67890,
    activity_type="meeting",
    description="Technical discussion meeting scheduled"
)
```

---

## Error Handling Example

```python
from server import CATSAPIError

async def safe_company_onboarding(company_data):
    """Onboard company with comprehensive error handling"""

    try:
        # Create company
        company = await create_company(**company_data)
        company_id = company["id"]
        print(f"✓ Created company: {company['name']} (ID: {company_id})")

    except CATSAPIError as e:
        if "duplicate" in str(e).lower():
            print("✗ Company already exists")
            # Search for existing
            results = await search_companies(query=company_data["name"])
            if results:
                company_id = results[0]["id"]
                print(f"  Using existing company ID: {company_id}")
        else:
            print(f"✗ Error creating company: {e}")
            raise

    try:
        # Add departments
        dept = await create_company_department(
            company_id=company_id,
            name="Engineering"
        )
        print(f"✓ Created department: {dept['name']}")

    except CATSAPIError as e:
        print(f"⚠ Warning: Could not create department: {e}")
        # Continue anyway

    try:
        # Add tags
        await attach_company_tags(
            company_id=company_id,
            tag_ids=[101, 102]
        )
        print(f"✓ Applied tags to company")

    except CATSAPIError as e:
        print(f"⚠ Warning: Could not apply tags: {e}")
        # Continue anyway

    return company_id

# Usage
company_data = {
    "name": "TechCorp Inc.",
    "website": "https://techcorp.com",
    "city": "San Francisco",
    "state": "CA"
}

company_id = await safe_company_onboarding(company_data)
print(f"\n✓ Company onboarding complete: ID {company_id}")
```

---

## Best Practices

### 1. Pagination
Always use pagination for list endpoints to avoid timeouts:
```python
# Good
companies = await list_companies(per_page=100, page=1)

# Bad (could timeout with large datasets)
companies = await list_companies(per_page=10000)
```

### 2. Error Handling
Wrap API calls in try-except blocks:
```python
try:
    company = await create_company(name="Test Corp")
except CATSAPIError as e:
    print(f"Error: {e}")
    # Handle error appropriately
```

### 3. Search Before Create
Avoid duplicates by searching first:
```python
# Search for existing
results = await search_companies(query="TechCorp")
if results:
    company = results[0]
else:
    company = await create_company(name="TechCorp Inc.")
```

### 4. Batch Operations
Use pagination to process large datasets:
```python
page = 1
while True:
    batch = await list_companies(per_page=100, page=page)
    for company in batch["companies"]:
        # Process each company
        pass

    if len(batch["companies"]) < 100:
        break
    page += 1
```

### 5. Activity Logging
Log all interactions for audit trail:
```python
# Always log activities after interactions
await create_company_activity(
    company_id=company_id,
    activity_type="meeting",
    description="Kickoff call completed",
    notes="Discussed hiring timeline and requirements"
)
```

---

**Note**: These examples assume you have the recruiting toolsets registered with your MCP server. See `INTEGRATION_EXAMPLE.py` for setup instructions.
