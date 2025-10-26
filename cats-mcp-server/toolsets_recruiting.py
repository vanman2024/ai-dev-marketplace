"""
CATS MCP Server - Recruiting Toolsets
Complete recruiting-focused toolsets for CATS API v3
"""

from typing import Any, Optional
from fastmcp import FastMCP


# =============================================================================
# COMPANIES TOOLSET (18 tools)
# =============================================================================

def register_companies_tools(mcp: FastMCP, make_request):
    """Register all companies-related tools"""

    # Main Company Operations
    @mcp.tool()
    async def list_companies(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all companies with pagination.

        GET /companies

        Args:
            per_page: Number of companies per page (default: 25, max: 100)
            page: Page number for pagination (default: 1)

        Returns:
            List of companies with pagination metadata
        """
        return await make_request("GET", "/companies", params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def get_company(company_id: int) -> dict[str, Any]:
        """
        Get detailed information about a specific company.

        GET /companies/{id}

        Args:
            company_id: Unique identifier for the company

        Returns:
            Complete company details including contacts and jobs
        """
        return await make_request("GET", f"/companies/{company_id}")

    @mcp.tool()
    async def create_company(
        name: str,
        website: Optional[str] = None,
        phone: Optional[str] = None,
        address: Optional[str] = None,
        city: Optional[str] = None,
        state: Optional[str] = None,
        zip_code: Optional[str] = None,
        notes: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Create a new company record.

        POST /companies

        Args:
            name: Company name (required)
            website: Company website URL
            phone: Company phone number
            address: Street address
            city: City
            state: State/province
            zip_code: ZIP or postal code
            notes: Additional notes about the company

        Returns:
            Created company details with ID
        """
        payload = {"name": name}
        if website:
            payload["website"] = website
        if phone:
            payload["phone"] = phone
        if address:
            payload["address"] = address
        if city:
            payload["city"] = city
        if state:
            payload["state"] = state
        if zip_code:
            payload["zip_code"] = zip_code
        if notes:
            payload["notes"] = notes
        return await make_request("POST", "/companies", json_data=payload)

    @mcp.tool()
    async def update_company(
        company_id: int,
        name: Optional[str] = None,
        website: Optional[str] = None,
        phone: Optional[str] = None,
        address: Optional[str] = None,
        city: Optional[str] = None,
        state: Optional[str] = None,
        zip_code: Optional[str] = None,
        notes: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Update an existing company record.

        PUT /companies/{id}

        Args:
            company_id: ID of company to update
            name: Updated company name
            website: Updated website URL
            phone: Updated phone number
            address: Updated street address
            city: Updated city
            state: Updated state/province
            zip_code: Updated ZIP/postal code
            notes: Updated notes

        Returns:
            Updated company details
        """
        payload = {}
        if name:
            payload["name"] = name
        if website:
            payload["website"] = website
        if phone:
            payload["phone"] = phone
        if address:
            payload["address"] = address
        if city:
            payload["city"] = city
        if state:
            payload["state"] = state
        if zip_code:
            payload["zip_code"] = zip_code
        if notes:
            payload["notes"] = notes
        return await make_request("PUT", f"/companies/{company_id}", json_data=payload)

    @mcp.tool()
    async def delete_company(company_id: int) -> dict[str, Any]:
        """
        Delete a company record (permanent).

        DELETE /companies/{id}

        Args:
            company_id: ID of company to delete

        Returns:
            Deletion confirmation

        Warning:
            This is a permanent deletion. Consider archiving instead.
        """
        return await make_request("DELETE", f"/companies/{company_id}")

    @mcp.tool()
    async def search_companies(query: str, per_page: int = 25) -> dict[str, Any]:
        """
        Search companies by name or other criteria.

        GET /companies/search

        Args:
            query: Search query string
            per_page: Number of results per page (max: 100)

        Returns:
            List of matching companies
        """
        return await make_request("GET", "/companies/search", params={"q": query, "per_page": per_page})

    @mcp.tool()
    async def filter_companies(
        filters: dict[str, Any],
        per_page: int = 25,
        page: int = 1
    ) -> dict[str, Any]:
        """
        Filter companies using advanced criteria.

        POST /companies/search

        Args:
            filters: Dictionary of filter criteria (e.g., {"city": "San Francisco", "state": "CA"})
            per_page: Results per page (max: 100)
            page: Page number

        Returns:
            Filtered list of companies
        """
        payload = {**filters, "per_page": per_page, "page": page}
        return await make_request("POST", "/companies/search", json_data=payload)

    # Company Sub-Resources
    @mcp.tool()
    async def list_company_activities(company_id: int, per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all activities for a specific company.

        GET /companies/{id}/activities

        Args:
            company_id: Company ID
            per_page: Results per page
            page: Page number

        Returns:
            List of company activities
        """
        return await make_request("GET", f"/companies/{company_id}/activities",
                                 params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def create_company_activity(
        company_id: int,
        activity_type: str,
        description: str,
        notes: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Create an activity for a company.

        POST /companies/{id}/activities

        Args:
            company_id: Company ID
            activity_type: Type (email, meeting, call_talked, call_lvm, call_missed, text_message, other)
            description: Activity description
            notes: Additional notes

        Returns:
            Created activity details
        """
        payload = {"type": activity_type, "description": description}
        if notes:
            payload["notes"] = notes
        return await make_request("POST", f"/companies/{company_id}/activities", json_data=payload)

    @mcp.tool()
    async def list_company_attachments(company_id: int, per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all attachments for a company.

        GET /companies/{id}/attachments

        Args:
            company_id: Company ID
            per_page: Results per page
            page: Page number

        Returns:
            List of company attachments
        """
        return await make_request("GET", f"/companies/{company_id}/attachments",
                                 params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def upload_company_attachment(
        company_id: int,
        file_data: dict[str, Any]
    ) -> dict[str, Any]:
        """
        Upload an attachment to a company.

        POST /companies/{id}/attachments

        Args:
            company_id: Company ID
            file_data: File upload data (multipart/form-data)

        Returns:
            Created attachment details

        Note:
            File upload requires multipart/form-data handling
        """
        return await make_request("POST", f"/companies/{company_id}/attachments", json_data=file_data)

    @mcp.tool()
    async def list_company_contacts(company_id: int, per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all contacts associated with a company.

        GET /companies/{id}/contacts

        Args:
            company_id: Company ID
            per_page: Results per page
            page: Page number

        Returns:
            List of company contacts
        """
        return await make_request("GET", f"/companies/{company_id}/contacts",
                                 params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def get_company_custom_fields(company_id: int) -> dict[str, Any]:
        """
        Get custom fields for a company.

        GET /companies/{id}/custom_fields

        Args:
            company_id: Company ID

        Returns:
            Company custom field values
        """
        return await make_request("GET", f"/companies/{company_id}/custom_fields")

    @mcp.tool()
    async def list_company_departments(company_id: int) -> dict[str, Any]:
        """
        List all departments within a company.

        GET /companies/{id}/departments

        Args:
            company_id: Company ID

        Returns:
            List of company departments
        """
        return await make_request("GET", f"/companies/{company_id}/departments")

    @mcp.tool()
    async def create_company_department(company_id: int, name: str, description: Optional[str] = None) -> dict[str, Any]:
        """
        Create a new department for a company.

        POST /companies/{id}/departments

        Args:
            company_id: Company ID
            name: Department name
            description: Department description

        Returns:
            Created department details
        """
        payload = {"name": name}
        if description:
            payload["description"] = description
        return await make_request("POST", f"/companies/{company_id}/departments", json_data=payload)

    @mcp.tool()
    async def update_company_department(
        company_id: int,
        department_id: int,
        name: Optional[str] = None,
        description: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Update a company department.

        PUT /companies/{id}/departments/{dept_id}

        Args:
            company_id: Company ID
            department_id: Department ID
            name: Updated name
            description: Updated description

        Returns:
            Updated department details
        """
        payload = {}
        if name:
            payload["name"] = name
        if description:
            payload["description"] = description
        return await make_request("PUT", f"/companies/{company_id}/departments/{department_id}", json_data=payload)

    @mcp.tool()
    async def delete_company_department(company_id: int, department_id: int) -> dict[str, Any]:
        """
        Delete a company department.

        DELETE /companies/{id}/departments/{dept_id}

        Args:
            company_id: Company ID
            department_id: Department ID

        Returns:
            Deletion confirmation
        """
        return await make_request("DELETE", f"/companies/{company_id}/departments/{department_id}")

    @mcp.tool()
    async def list_company_pipelines(company_id: int) -> dict[str, Any]:
        """
        List all pipelines associated with a company.

        GET /companies/{id}/pipelines

        Args:
            company_id: Company ID

        Returns:
            List of company pipelines
        """
        return await make_request("GET", f"/companies/{company_id}/pipelines")

    @mcp.tool()
    async def list_company_tags(company_id: int) -> dict[str, Any]:
        """
        List all tags applied to a company.

        GET /companies/{id}/tags

        Args:
            company_id: Company ID

        Returns:
            List of company tags
        """
        return await make_request("GET", f"/companies/{company_id}/tags")

    @mcp.tool()
    async def replace_company_tags(company_id: int, tag_ids: list[int]) -> dict[str, Any]:
        """
        Replace all tags on a company (replaces existing tags).

        PUT /companies/{id}/tags

        Args:
            company_id: Company ID
            tag_ids: List of tag IDs to apply

        Returns:
            Updated tag list
        """
        return await make_request("PUT", f"/companies/{company_id}/tags", json_data={"tag_ids": tag_ids})

    @mcp.tool()
    async def attach_company_tags(company_id: int, tag_ids: list[int]) -> dict[str, Any]:
        """
        Attach additional tags to a company (additive).

        POST /companies/{id}/tags

        Args:
            company_id: Company ID
            tag_ids: List of tag IDs to add

        Returns:
            Updated tag list
        """
        return await make_request("POST", f"/companies/{company_id}/tags", json_data={"tag_ids": tag_ids})

    @mcp.tool()
    async def delete_company_tags(company_id: int, tag_ids: list[int]) -> dict[str, Any]:
        """
        Remove specific tags from a company.

        DELETE /companies/{id}/tags

        Args:
            company_id: Company ID
            tag_ids: List of tag IDs to remove

        Returns:
            Updated tag list
        """
        return await make_request("DELETE", f"/companies/{company_id}/tags", json_data={"tag_ids": tag_ids})


# =============================================================================
# CONTACTS TOOLSET (18 tools)
# =============================================================================

def register_contacts_tools(mcp: FastMCP, make_request):
    """Register all contacts-related tools"""

    # Main Contact Operations
    @mcp.tool()
    async def list_contacts(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all contacts with pagination.

        GET /contacts

        Args:
            per_page: Number of contacts per page (default: 25, max: 100)
            page: Page number for pagination (default: 1)

        Returns:
            List of contacts with pagination metadata
        """
        return await make_request("GET", "/contacts", params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def get_contact(contact_id: int) -> dict[str, Any]:
        """
        Get detailed information about a specific contact.

        GET /contacts/{id}

        Args:
            contact_id: Unique identifier for the contact

        Returns:
            Complete contact details including company association
        """
        return await make_request("GET", f"/contacts/{contact_id}")

    @mcp.tool()
    async def create_contact(
        first_name: str,
        last_name: str,
        email: str,
        company_id: Optional[int] = None,
        title: Optional[str] = None,
        phone: Optional[str] = None,
        notes: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Create a new contact record.

        POST /contacts

        Args:
            first_name: Contact's first name (required)
            last_name: Contact's last name (required)
            email: Contact's email address (required)
            company_id: Associated company ID
            title: Job title
            phone: Phone number
            notes: Additional notes

        Returns:
            Created contact details with ID
        """
        payload = {
            "first_name": first_name,
            "last_name": last_name,
            "email": email
        }
        if company_id:
            payload["company_id"] = company_id
        if title:
            payload["title"] = title
        if phone:
            payload["phone"] = phone
        if notes:
            payload["notes"] = notes
        return await make_request("POST", "/contacts", json_data=payload)

    @mcp.tool()
    async def update_contact(
        contact_id: int,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        email: Optional[str] = None,
        company_id: Optional[int] = None,
        title: Optional[str] = None,
        phone: Optional[str] = None,
        notes: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Update an existing contact record.

        PUT /contacts/{id}

        Args:
            contact_id: ID of contact to update
            first_name: Updated first name
            last_name: Updated last name
            email: Updated email address
            company_id: Updated company association
            title: Updated job title
            phone: Updated phone number
            notes: Updated notes

        Returns:
            Updated contact details
        """
        payload = {}
        if first_name:
            payload["first_name"] = first_name
        if last_name:
            payload["last_name"] = last_name
        if email:
            payload["email"] = email
        if company_id:
            payload["company_id"] = company_id
        if title:
            payload["title"] = title
        if phone:
            payload["phone"] = phone
        if notes:
            payload["notes"] = notes
        return await make_request("PUT", f"/contacts/{contact_id}", json_data=payload)

    @mcp.tool()
    async def delete_contact(contact_id: int) -> dict[str, Any]:
        """
        Delete a contact record (permanent).

        DELETE /contacts/{id}

        Args:
            contact_id: ID of contact to delete

        Returns:
            Deletion confirmation

        Warning:
            This is a permanent deletion.
        """
        return await make_request("DELETE", f"/contacts/{contact_id}")

    @mcp.tool()
    async def search_contacts(query: str, per_page: int = 25) -> dict[str, Any]:
        """
        Search contacts by name, email, or other criteria.

        GET /contacts/search

        Args:
            query: Search query string
            per_page: Number of results per page (max: 100)

        Returns:
            List of matching contacts
        """
        return await make_request("GET", "/contacts/search", params={"q": query, "per_page": per_page})

    @mcp.tool()
    async def filter_contacts(
        filters: dict[str, Any],
        per_page: int = 25,
        page: int = 1
    ) -> dict[str, Any]:
        """
        Filter contacts using advanced criteria.

        POST /contacts/search

        Args:
            filters: Dictionary of filter criteria (e.g., {"company_id": 123, "title": "Manager"})
            per_page: Results per page (max: 100)
            page: Page number

        Returns:
            Filtered list of contacts
        """
        payload = {**filters, "per_page": per_page, "page": page}
        return await make_request("POST", "/contacts/search", json_data=payload)

    # Contact Sub-Resources
    @mcp.tool()
    async def list_contact_activities(contact_id: int, per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all activities for a specific contact.

        GET /contacts/{id}/activities

        Args:
            contact_id: Contact ID
            per_page: Results per page
            page: Page number

        Returns:
            List of contact activities
        """
        return await make_request("GET", f"/contacts/{contact_id}/activities",
                                 params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def create_contact_activity(
        contact_id: int,
        activity_type: str,
        description: str,
        notes: Optional[str] = None
    ) -> dict[str, Any]:
        """
        Create an activity for a contact.

        POST /contacts/{id}/activities

        Args:
            contact_id: Contact ID
            activity_type: Type (email, meeting, call_talked, call_lvm, call_missed, text_message, other)
            description: Activity description
            notes: Additional notes

        Returns:
            Created activity details
        """
        payload = {"type": activity_type, "description": description}
        if notes:
            payload["notes"] = notes
        return await make_request("POST", f"/contacts/{contact_id}/activities", json_data=payload)

    @mcp.tool()
    async def list_contact_attachments(contact_id: int, per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all attachments for a contact.

        GET /contacts/{id}/attachments

        Args:
            contact_id: Contact ID
            per_page: Results per page
            page: Page number

        Returns:
            List of contact attachments
        """
        return await make_request("GET", f"/contacts/{contact_id}/attachments",
                                 params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def upload_contact_attachment(
        contact_id: int,
        file_data: dict[str, Any]
    ) -> dict[str, Any]:
        """
        Upload an attachment to a contact.

        POST /contacts/{id}/attachments

        Args:
            contact_id: Contact ID
            file_data: File upload data (multipart/form-data)

        Returns:
            Created attachment details

        Note:
            File upload requires multipart/form-data handling
        """
        return await make_request("POST", f"/contacts/{contact_id}/attachments", json_data=file_data)

    @mcp.tool()
    async def get_contact_custom_fields(contact_id: int) -> dict[str, Any]:
        """
        Get custom fields for a contact.

        GET /contacts/{id}/custom_fields

        Args:
            contact_id: Contact ID

        Returns:
            Contact custom field values
        """
        return await make_request("GET", f"/contacts/{contact_id}/custom_fields")

    @mcp.tool()
    async def list_contact_emails(contact_id: int, per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all email addresses for a contact.

        GET /contacts/{id}/emails

        Args:
            contact_id: Contact ID
            per_page: Results per page
            page: Page number

        Returns:
            List of contact email addresses
        """
        return await make_request("GET", f"/contacts/{contact_id}/emails",
                                 params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def create_contact_email(contact_id: int, email: str, email_type: str = "work") -> dict[str, Any]:
        """
        Add an email address to a contact.

        POST /contacts/{id}/emails

        Args:
            contact_id: Contact ID
            email: Email address
            email_type: Type (work, personal, other)

        Returns:
            Created email details
        """
        return await make_request("POST", f"/contacts/{contact_id}/emails",
                                json_data={"email": email, "type": email_type})

    @mcp.tool()
    async def update_contact_email(contact_id: int, email_id: int, email: str, email_type: str) -> dict[str, Any]:
        """
        Update a contact's email address.

        PUT /contacts/{id}/emails/{email_id}

        Args:
            contact_id: Contact ID
            email_id: Email record ID
            email: Updated email address
            email_type: Updated type (work, personal, other)

        Returns:
            Updated email details
        """
        return await make_request("PUT", f"/contacts/{contact_id}/emails/{email_id}",
                                json_data={"email": email, "type": email_type})

    @mcp.tool()
    async def delete_contact_email(contact_id: int, email_id: int) -> dict[str, Any]:
        """
        Delete a contact's email address.

        DELETE /contacts/{id}/emails/{email_id}

        Args:
            contact_id: Contact ID
            email_id: Email record ID

        Returns:
            Deletion confirmation
        """
        return await make_request("DELETE", f"/contacts/{contact_id}/emails/{email_id}")

    @mcp.tool()
    async def list_contact_phones(contact_id: int, per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all phone numbers for a contact.

        GET /contacts/{id}/phones

        Args:
            contact_id: Contact ID
            per_page: Results per page
            page: Page number

        Returns:
            List of contact phone numbers
        """
        return await make_request("GET", f"/contacts/{contact_id}/phones",
                                 params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def create_contact_phone(contact_id: int, phone: str, phone_type: str = "work") -> dict[str, Any]:
        """
        Add a phone number to a contact.

        POST /contacts/{id}/phones

        Args:
            contact_id: Contact ID
            phone: Phone number
            phone_type: Type (work, mobile, home, other)

        Returns:
            Created phone details
        """
        return await make_request("POST", f"/contacts/{contact_id}/phones",
                                json_data={"phone": phone, "type": phone_type})

    @mcp.tool()
    async def update_contact_phone(contact_id: int, phone_id: int, phone: str, phone_type: str) -> dict[str, Any]:
        """
        Update a contact's phone number.

        PUT /contacts/{id}/phones/{phone_id}

        Args:
            contact_id: Contact ID
            phone_id: Phone record ID
            phone: Updated phone number
            phone_type: Updated type (work, mobile, home, other)

        Returns:
            Updated phone details
        """
        return await make_request("PUT", f"/contacts/{contact_id}/phones/{phone_id}",
                                json_data={"phone": phone, "type": phone_type})

    @mcp.tool()
    async def delete_contact_phone(contact_id: int, phone_id: int) -> dict[str, Any]:
        """
        Delete a contact's phone number.

        DELETE /contacts/{id}/phones/{phone_id}

        Args:
            contact_id: Contact ID
            phone_id: Phone record ID

        Returns:
            Deletion confirmation
        """
        return await make_request("DELETE", f"/contacts/{contact_id}/phones/{phone_id}")

    @mcp.tool()
    async def list_contact_pipelines(contact_id: int) -> dict[str, Any]:
        """
        List all pipelines associated with a contact.

        GET /contacts/{id}/pipelines

        Args:
            contact_id: Contact ID

        Returns:
            List of contact pipelines
        """
        return await make_request("GET", f"/contacts/{contact_id}/pipelines")

    @mcp.tool()
    async def list_contact_tags(contact_id: int) -> dict[str, Any]:
        """
        List all tags applied to a contact.

        GET /contacts/{id}/tags

        Args:
            contact_id: Contact ID

        Returns:
            List of contact tags
        """
        return await make_request("GET", f"/contacts/{contact_id}/tags")

    @mcp.tool()
    async def replace_contact_tags(contact_id: int, tag_ids: list[int]) -> dict[str, Any]:
        """
        Replace all tags on a contact (replaces existing tags).

        PUT /contacts/{id}/tags

        Args:
            contact_id: Contact ID
            tag_ids: List of tag IDs to apply

        Returns:
            Updated tag list
        """
        return await make_request("PUT", f"/contacts/{contact_id}/tags", json_data={"tag_ids": tag_ids})

    @mcp.tool()
    async def attach_contact_tags(contact_id: int, tag_ids: list[int]) -> dict[str, Any]:
        """
        Attach additional tags to a contact (additive).

        POST /contacts/{id}/tags

        Args:
            contact_id: Contact ID
            tag_ids: List of tag IDs to add

        Returns:
            Updated tag list
        """
        return await make_request("POST", f"/contacts/{contact_id}/tags", json_data={"tag_ids": tag_ids})

    @mcp.tool()
    async def delete_contact_tags(contact_id: int, tag_ids: list[int]) -> dict[str, Any]:
        """
        Remove specific tags from a contact.

        DELETE /contacts/{id}/tags

        Args:
            contact_id: Contact ID
            tag_ids: List of tag IDs to remove

        Returns:
            Updated tag list
        """
        return await make_request("DELETE", f"/contacts/{contact_id}/tags", json_data={"tag_ids": tag_ids})


# =============================================================================
# ACTIVITIES TOOLSET (6 tools)
# =============================================================================

def register_activities_tools(mcp: FastMCP, make_request):
    """Register all activities-related tools"""

    @mcp.tool()
    async def list_activities(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all activities with pagination.

        GET /activities

        Activity types: email, meeting, call_talked, call_lvm, call_missed, text_message, other

        Args:
            per_page: Number of activities per page (default: 25, max: 100)
            page: Page number for pagination (default: 1)

        Returns:
            List of activities with pagination metadata
        """
        return await make_request("GET", "/activities", params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def get_activity(activity_id: int) -> dict[str, Any]:
        """
        Get detailed information about a specific activity.

        GET /activities/{id}

        Args:
            activity_id: Unique identifier for the activity

        Returns:
            Complete activity details including associated entities
        """
        return await make_request("GET", f"/activities/{activity_id}")

    @mcp.tool()
    async def update_activity(
        activity_id: int,
        activity_type: Optional[str] = None,
        description: Optional[str] = None,
        notes: Optional[str] = None,
        completed: Optional[bool] = None
    ) -> dict[str, Any]:
        """
        Update an existing activity.

        PUT /activities/{id}

        Args:
            activity_id: ID of activity to update
            activity_type: Updated type (email, meeting, call_talked, call_lvm, call_missed, text_message, other)
            description: Updated description
            notes: Updated notes
            completed: Mark as completed (true/false)

        Returns:
            Updated activity details
        """
        payload = {}
        if activity_type:
            payload["type"] = activity_type
        if description:
            payload["description"] = description
        if notes:
            payload["notes"] = notes
        if completed is not None:
            payload["completed"] = completed
        return await make_request("PUT", f"/activities/{activity_id}", json_data=payload)

    @mcp.tool()
    async def delete_activity(activity_id: int) -> dict[str, Any]:
        """
        Delete an activity record (permanent).

        DELETE /activities/{id}

        Args:
            activity_id: ID of activity to delete

        Returns:
            Deletion confirmation
        """
        return await make_request("DELETE", f"/activities/{activity_id}")

    @mcp.tool()
    async def search_activities(query: str, per_page: int = 25) -> dict[str, Any]:
        """
        Search activities by description or other criteria.

        GET /activities/search

        Args:
            query: Search query string
            per_page: Number of results per page (max: 100)

        Returns:
            List of matching activities
        """
        return await make_request("GET", "/activities/search", params={"q": query, "per_page": per_page})

    @mcp.tool()
    async def filter_activities(
        filters: dict[str, Any],
        per_page: int = 25,
        page: int = 1
    ) -> dict[str, Any]:
        """
        Filter activities using advanced criteria.

        POST /activities/search

        Args:
            filters: Dictionary of filter criteria (e.g., {"type": "meeting", "completed": false})
            per_page: Results per page (max: 100)
            page: Page number

        Returns:
            Filtered list of activities
        """
        payload = {**filters, "per_page": per_page, "page": page}
        return await make_request("POST", "/activities/search", json_data=payload)


# =============================================================================
# PORTALS TOOLSET (8 tools)
# =============================================================================

def register_portals_tools(mcp: FastMCP, make_request):
    """Register all portals-related tools"""

    @mcp.tool()
    async def list_portals(per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all job portals/boards.

        GET /portals

        Args:
            per_page: Number of portals per page (default: 25, max: 100)
            page: Page number for pagination (default: 1)

        Returns:
            List of configured job portals
        """
        return await make_request("GET", "/portals", params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def get_portal(portal_id: int) -> dict[str, Any]:
        """
        Get detailed information about a specific portal.

        GET /portals/{id}

        Args:
            portal_id: Unique identifier for the portal

        Returns:
            Complete portal details including configuration
        """
        return await make_request("GET", f"/portals/{portal_id}")

    @mcp.tool()
    async def list_portal_jobs(portal_id: int, per_page: int = 25, page: int = 1) -> dict[str, Any]:
        """
        List all jobs published to a specific portal.

        GET /portals/{id}/jobs

        Args:
            portal_id: Portal ID
            per_page: Results per page
            page: Page number

        Returns:
            List of jobs on the portal
        """
        return await make_request("GET", f"/portals/{portal_id}/jobs",
                                 params={"per_page": per_page, "page": page})

    @mcp.tool()
    async def submit_job_application(
        portal_id: int,
        job_id: int,
        candidate_data: dict[str, Any]
    ) -> dict[str, Any]:
        """
        Submit a job application through a portal.

        POST /portals/{portal_id}/jobs/{job_id}/apply

        Args:
            portal_id: Portal ID
            job_id: Job posting ID
            candidate_data: Candidate information (first_name, last_name, email, resume, etc.)

        Returns:
            Created application details
        """
        return await make_request("POST", f"/portals/{portal_id}/jobs/{job_id}/apply",
                                 json_data=candidate_data)

    @mcp.tool()
    async def publish_job_to_portal(portal_id: int, job_id: int) -> dict[str, Any]:
        """
        Publish a job posting to a portal.

        POST /portals/{portal_id}/jobs/{job_id}/publish

        Args:
            portal_id: Portal ID
            job_id: Job posting ID

        Returns:
            Publishing confirmation
        """
        return await make_request("POST", f"/portals/{portal_id}/jobs/{job_id}/publish")

    @mcp.tool()
    async def unpublish_job_from_portal(portal_id: int, job_id: int) -> dict[str, Any]:
        """
        Remove a job posting from a portal.

        DELETE /portals/{portal_id}/jobs/{job_id}/publish

        Args:
            portal_id: Portal ID
            job_id: Job posting ID

        Returns:
            Unpublishing confirmation
        """
        return await make_request("DELETE", f"/portals/{portal_id}/jobs/{job_id}/publish")

    @mcp.tool()
    async def get_portal_registration(portal_id: int) -> dict[str, Any]:
        """
        Get portal registration information and requirements.

        GET /portals/{id}/registration

        Args:
            portal_id: Portal ID

        Returns:
            Portal registration details
        """
        return await make_request("GET", f"/portals/{portal_id}/registration")

    @mcp.tool()
    async def submit_portal_registration(
        portal_id: int,
        registration_data: dict[str, Any]
    ) -> dict[str, Any]:
        """
        Submit portal registration information.

        POST /portals/{id}/registration

        Args:
            portal_id: Portal ID
            registration_data: Registration information (varies by portal)

        Returns:
            Registration confirmation
        """
        return await make_request("POST", f"/portals/{portal_id}/registration",
                                 json_data=registration_data)


# =============================================================================
# WORK HISTORY TOOLSET (3 tools)
# =============================================================================

def register_work_history_tools(mcp: FastMCP, make_request):
    """Register all work history-related tools"""

    @mcp.tool()
    async def get_work_history(work_history_id: int) -> dict[str, Any]:
        """
        Get detailed information about a specific work history entry.

        GET /work_history/{id}

        Args:
            work_history_id: Unique identifier for the work history entry

        Returns:
            Complete work history details

        Note:
            Work history entries are typically accessed through candidate sub-resources.
            Creation happens via: POST /candidates/{id}/work_history
        """
        return await make_request("GET", f"/work_history/{work_history_id}")

    @mcp.tool()
    async def update_work_history(
        work_history_id: int,
        company_name: Optional[str] = None,
        title: Optional[str] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        description: Optional[str] = None,
        currently_employed: Optional[bool] = None
    ) -> dict[str, Any]:
        """
        Update an existing work history entry.

        PUT /work_history/{id}

        Args:
            work_history_id: ID of work history to update
            company_name: Updated company name
            title: Updated job title
            start_date: Updated start date (YYYY-MM-DD)
            end_date: Updated end date (YYYY-MM-DD, null if currently employed)
            description: Updated job description
            currently_employed: Whether candidate is currently employed here

        Returns:
            Updated work history details
        """
        payload = {}
        if company_name:
            payload["company_name"] = company_name
        if title:
            payload["title"] = title
        if start_date:
            payload["start_date"] = start_date
        if end_date:
            payload["end_date"] = end_date
        if description:
            payload["description"] = description
        if currently_employed is not None:
            payload["currently_employed"] = currently_employed
        return await make_request("PUT", f"/work_history/{work_history_id}", json_data=payload)

    @mcp.tool()
    async def delete_work_history(work_history_id: int) -> dict[str, Any]:
        """
        Delete a work history entry (permanent).

        DELETE /work_history/{id}

        Args:
            work_history_id: ID of work history to delete

        Returns:
            Deletion confirmation
        """
        return await make_request("DELETE", f"/work_history/{work_history_id}")


# =============================================================================
# REGISTRATION FUNCTION
# =============================================================================

def register_all_recruiting_toolsets(mcp: FastMCP, make_request):
    """
    Register all recruiting toolsets with the MCP server.

    This includes:
    - Companies (18 tools)
    - Contacts (18 tools)
    - Activities (6 tools)
    - Portals (8 tools)
    - Work History (3 tools)

    Total: 53 tools

    Args:
        mcp: FastMCP server instance
        make_request: HTTP request helper function
    """
    register_companies_tools(mcp, make_request)
    register_contacts_tools(mcp, make_request)
    register_activities_tools(mcp, make_request)
    register_portals_tools(mcp, make_request)
    register_work_history_tools(mcp, make_request)
