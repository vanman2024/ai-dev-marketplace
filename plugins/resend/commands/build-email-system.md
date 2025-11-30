---
description: Build complete email system with Resend - SDK setup, API routes, React Email templates, webhooks, and contact management
argument-hint: [--frontend-only] [--backend-only] [--with-contacts] [--with-broadcasts]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite, AskUserQuestion, WebFetch
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools
- ✅ Complete ALL phases before considering this command done
- ❌ DON'T wait for "the command to complete" - YOU complete it by executing the phases

---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:
- Never hardcode API keys - use `RESEND_API_KEY=your_resend_api_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only

**Arguments**: $ARGUMENTS

## Goal

Build a complete, production-ready email system using Resend API that integrates with your existing project. This orchestrator coordinates multiple specialized agents in parallel to build:

1. **Backend**: API routes for email operations (Next.js API routes or FastAPI endpoints)
2. **Frontend**: React Email templates, email composer UI components
3. **Infrastructure**: Webhooks, domain configuration, contact management
4. **Integration**: Connects with existing auth, database, and UI systems

---

## Phase 1: Discovery & Project Analysis

**Goal**: Understand project structure and determine what needs to be built

**Actions**:

1. Detect project type and existing infrastructure:

!{bash ls package.json pyproject.toml next.config.* tsconfig.json requirements.txt 2>/dev/null}

!{bash test -f package.json && cat package.json | grep -E '"(next|react|express|fastify)"' | head -5}

2. Check for existing Resend setup:

!{bash test -f .env.example && grep -i resend .env.example || echo "No Resend config found"}

!{bash find . -name "*.ts" -o -name "*.tsx" -o -name "*.py" 2>/dev/null | xargs grep -l "resend" 2>/dev/null | head -5}

3. Detect existing integrations:
- Supabase: !{bash grep -r "supabase" package.json .env.example 2>/dev/null | head -3}
- Clerk/Auth: !{bash grep -r "clerk\|nextauth\|auth" package.json 2>/dev/null | head -3}
- Database: !{bash test -d prisma && echo "Prisma detected" || echo "No Prisma"}

4. Parse $ARGUMENTS for flags:
- `--frontend-only`: Skip backend API routes
- `--backend-only`: Skip React Email templates and UI
- `--with-contacts`: Include contact management system
- `--with-broadcasts`: Include broadcast/campaign functionality

---

## Phase 2: Requirements Gathering

**Goal**: Clarify what email features the user needs

**Actions**:

Use AskUserQuestion to gather requirements:

```
AskUserQuestion([
  {
    question: "What email features do you need?",
    header: "Features",
    options: [
      { label: "Transactional only", description: "Password reset, welcome, confirmations" },
      { label: "Marketing + Transactional", description: "Newsletters, broadcasts + transactional" },
      { label: "Full suite", description: "All features including contacts, segments, analytics" }
    ],
    multiSelect: false
  },
  {
    question: "What's your project stack?",
    header: "Stack",
    options: [
      { label: "Next.js Full-stack", description: "Next.js with API routes" },
      { label: "Next.js + FastAPI", description: "Next.js frontend, FastAPI backend" },
      { label: "React + Express", description: "React SPA with Express backend" },
      { label: "Python only", description: "FastAPI or Flask backend" }
    ],
    multiSelect: false
  },
  {
    question: "Do you want React Email for templates?",
    header: "Templates",
    options: [
      { label: "Yes - React Email", description: "Component-based email templates" },
      { label: "No - HTML templates", description: "Simple HTML email templates" }
    ],
    multiSelect: false
  }
])
```

Store responses for agent coordination.

---

## Phase 3: Create Implementation Plan

**Goal**: Design the build plan and create tracking todos

**Actions**:

Based on discovery and requirements, create TodoWrite entries:

```
TodoWrite([
  { content: "Initialize Resend SDK and environment", status: "pending", activeForm: "Initializing Resend SDK" },
  { content: "Build backend API routes for email operations", status: "pending", activeForm: "Building backend API routes" },
  { content: "Create React Email templates", status: "pending", activeForm: "Creating React Email templates" },
  { content: "Build frontend email UI components", status: "pending", activeForm: "Building frontend UI components" },
  { content: "Setup webhook handlers for email events", status: "pending", activeForm: "Setting up webhook handlers" },
  { content: "Configure domain and DNS (optional)", status: "pending", activeForm: "Configuring domain" },
  { content: "Add contact management (if requested)", status: "pending", activeForm: "Adding contact management" },
  { content: "Integration testing and verification", status: "pending", activeForm: "Running integration tests" }
])
```

---

## Phase 4: Parallel Agent Execution - Core Setup

**Goal**: Run foundational agents in parallel

**CRITICAL: Launch ALL these Task() calls in a SINGLE message for parallel execution!**

**Task 1: Resend SDK Setup**
```
Task(
  description="Initialize Resend SDK",
  subagent_type="resend:resend-setup-agent",
  prompt="Initialize Resend SDK in this project.

Context:
- Project type: [detected from Phase 1]
- Framework: [Next.js/FastAPI/Express]

Requirements:
1. Install resend SDK (npm or pip)
2. Create .env.example with RESEND_API_KEY=your_resend_api_key_here
3. Add .env to .gitignore
4. Create lib/resend.ts or utils/resend.py client initialization
5. Add TypeScript types for email payloads

Deliverable: Working Resend client setup with proper environment configuration."
)
```

**Task 2: Backend API Routes** (if Next.js or needs API)
```
Task(
  description="Build email API routes",
  subagent_type="nextjs-frontend:api-route-generator-agent",
  prompt="Create Next.js API routes for Resend email operations.

Create these API routes in app/api/emails/:
1. POST /api/emails/send - Send single transactional email
2. POST /api/emails/batch - Send batch emails (up to 100)
3. GET /api/emails/[id] - Get email status
4. POST /api/emails/[id]/cancel - Cancel scheduled email

Each route should:
- Validate request body with zod
- Use Resend SDK from lib/resend.ts
- Handle errors properly (rate limits, validation)
- Return proper status codes
- Include TypeScript types

Security: Read RESEND_API_KEY from environment, never expose in responses."
)
```

**Task 3: FastAPI Endpoints** (if Python backend detected)
```
Task(
  description="Build FastAPI email endpoints",
  subagent_type="fastapi-backend:endpoint-generator-agent",
  prompt="Create FastAPI endpoints for Resend email operations.

Create these endpoints in app/routers/emails.py:
1. POST /api/emails/send - Send single email
2. POST /api/emails/batch - Send batch emails
3. GET /api/emails/{email_id} - Get email status
4. POST /api/emails/{email_id}/cancel - Cancel scheduled email

Requirements:
- Pydantic models for request/response validation
- Async Resend client usage
- Proper error handling with HTTPException
- Rate limit handling with retry logic
- OpenAPI documentation

Security: Read RESEND_API_KEY from environment using python-dotenv."
)
```

**Wait for all Task() calls to complete before proceeding to Phase 5.**

---

## Phase 5: Parallel Agent Execution - Templates & UI

**Goal**: Build email templates and UI components in parallel

**CRITICAL: Launch ALL these Task() calls in a SINGLE message!**

**Task 4: React Email Templates**
```
Task(
  description="Create React Email templates",
  subagent_type="resend:resend-templates-agent",
  prompt="Create React Email templates for the project.

Install and setup:
1. Install @react-email/components and react-email
2. Create emails/ directory structure

Create these templates:
1. emails/welcome.tsx - Welcome email with branding
2. emails/password-reset.tsx - Password reset with secure link
3. emails/notification.tsx - Generic notification template
4. emails/receipt.tsx - Order/payment receipt (if e-commerce)

Each template should:
- Use @react-email/components (Html, Head, Body, Container, Text, Button, etc.)
- Be responsive (mobile-friendly)
- Include proper styling with Tailwind classes
- Export props interface for type safety
- Include preview text

Add npm script: 'email:dev' for preview server."
)
```

**Task 5: Frontend UI Components**
```
Task(
  description="Build email UI components",
  subagent_type="nextjs-frontend:component-builder-agent",
  prompt="Create React components for email functionality.

Create these components in components/email/:
1. EmailComposer.tsx - Rich text email composer with:
   - To, CC, BCC fields with email validation
   - Subject line
   - Rich text editor (use existing editor or textarea)
   - Template selection dropdown
   - Attachment upload
   - Schedule send option
   - Send button with loading state

2. EmailStatus.tsx - Email delivery status display:
   - Show sent, delivered, opened, clicked, bounced
   - Timeline view of events
   - Resend option for failed emails

3. EmailList.tsx - List of sent emails:
   - Sortable table with recipient, subject, status, date
   - Pagination
   - Search/filter
   - Click to view details

Use shadcn/ui components (Button, Input, Card, Table, Badge, etc.).
Follow existing design system patterns in the project."
)
```

**Task 6: Webhook Handlers**
```
Task(
  description="Setup webhook handlers",
  subagent_type="resend:resend-domains-webhooks-agent",
  prompt="Create webhook handlers for Resend email events.

Create webhook endpoint at app/api/webhooks/resend/route.ts:

1. Verify webhook signature using Resend signing secret
2. Handle all event types:
   - email.sent
   - email.delivered
   - email.delivery_delayed
   - email.complained
   - email.bounced
   - email.opened
   - email.clicked

3. For each event:
   - Log to database (if Prisma/Supabase detected)
   - Update email status in your system
   - Trigger notifications if needed (bounces, complaints)

4. Create .env entry: RESEND_WEBHOOK_SECRET=your_webhook_secret_here

Security: Always verify signatures before processing events."
)
```

**Wait for all Task() calls to complete before proceeding to Phase 6.**

---

## Phase 6: Optional Features (Based on Flags)

**Goal**: Add optional features based on user request

**If --with-contacts flag or "Full suite" selected:**

```
Task(
  description="Add contact management",
  subagent_type="resend:resend-contacts-agent",
  prompt="Add contact management system for Resend.

Create:
1. lib/contacts.ts - Contact management utilities:
   - createContact(email, name, properties)
   - updateContact(id, data)
   - deleteContact(id)
   - addToSegment(contactId, segmentId)
   - updateTopicPreferences(contactId, topics)

2. API routes in app/api/contacts/:
   - POST /api/contacts - Create contact
   - GET /api/contacts - List contacts with pagination
   - PATCH /api/contacts/[id] - Update contact
   - DELETE /api/contacts/[id] - Delete contact
   - POST /api/contacts/[id]/segments - Add to segment

3. UI components:
   - ContactList.tsx - Searchable contact table
   - ContactForm.tsx - Add/edit contact form
   - SegmentManager.tsx - Manage segments

Integrate with existing user/customer tables if detected."
)
```

**If --with-broadcasts flag or "Marketing + Transactional" selected:**

```
Task(
  description="Add broadcast functionality",
  subagent_type="resend:resend-broadcasts-agent",
  prompt="Add broadcast/campaign functionality for Resend.

Create:
1. lib/broadcasts.ts - Broadcast management:
   - createBroadcast(name, subject, template, audienceId)
   - sendBroadcast(broadcastId)
   - scheduleBroadcast(broadcastId, sendAt)
   - getBroadcastStats(broadcastId)

2. API routes in app/api/broadcasts/:
   - POST /api/broadcasts - Create broadcast
   - GET /api/broadcasts - List broadcasts
   - POST /api/broadcasts/[id]/send - Send broadcast
   - GET /api/broadcasts/[id]/stats - Get analytics

3. UI components:
   - BroadcastComposer.tsx - Campaign builder
   - AudienceSelector.tsx - Select segments/audiences
   - CampaignAnalytics.tsx - Open rates, click rates, etc.

Include A/B testing support for subject lines."
)
```

---

## Phase 7: Integration & Wiring

**Goal**: Connect all pieces together

**Actions**:

1. Create central email service that ties everything together:

!{Write app/services/email-service.ts with:
- Unified interface for all email operations
- Template rendering with React Email
- Contact lookup integration
- Event logging
- Error handling with retries
}

2. Add email hooks/utilities:

!{Write lib/hooks/useEmailStatus.ts - React hook for real-time email status}
!{Write lib/hooks/useContacts.ts - React hook for contact management}

3. Update existing pages to include email functionality:
- Add email buttons to user profiles
- Add notification preferences to settings
- Add email history to admin dashboard

---

## Phase 8: Verification & Testing

**Goal**: Ensure everything works

**Actions**:

1. Verify all files were created:
!{bash find . -path ./node_modules -prune -o -name "*.ts" -o -name "*.tsx" | xargs grep -l "resend" 2>/dev/null | head -20}

2. Check TypeScript compilation:
!{bash npx tsc --noEmit 2>&1 | head -20}

3. Verify environment setup:
!{bash test -f .env.example && grep -E "RESEND" .env.example}

4. List all created files:
!{bash git status --short | grep -E "^\?\?" | head -30}

---

## Phase 9: Summary & Next Steps

**Goal**: Provide completion summary and guidance

**Display**:

```
## ✅ Email System Built Successfully

### Files Created:

**Backend (API Routes)**:
- app/api/emails/send/route.ts
- app/api/emails/batch/route.ts
- app/api/emails/[id]/route.ts
- app/api/webhooks/resend/route.ts

**Frontend (Templates & UI)**:
- emails/welcome.tsx
- emails/password-reset.tsx
- emails/notification.tsx
- components/email/EmailComposer.tsx
- components/email/EmailStatus.tsx
- components/email/EmailList.tsx

**Infrastructure**:
- lib/resend.ts (SDK client)
- lib/email-service.ts (unified service)
- .env.example (with RESEND_API_KEY placeholder)

### Setup Required:

1. **Get API Key**: https://resend.com/api-keys
2. **Add to .env**:
   ```
   RESEND_API_KEY=re_xxxxxxxxx
   RESEND_WEBHOOK_SECRET=whsec_xxxxxxxxx
   ```

3. **Configure Domain** (for production):
   Run: /resend:add-domains yourdomain.com

4. **Setup Webhooks** (for tracking):
   - Go to https://resend.com/webhooks
   - Add endpoint: https://yourdomain.com/api/webhooks/resend

### Quick Test:

```typescript
// Test sending an email
const response = await fetch('/api/emails/send', {
  method: 'POST',
  body: JSON.stringify({
    to: 'test@example.com',
    subject: 'Hello from Resend!',
    template: 'welcome'
  })
});
```

### Related Commands:
- /resend:add-templates - Add more email templates
- /resend:add-contacts - Enhance contact management
- /resend:add-broadcasts - Add campaign features
```

Mark all todos as completed.
