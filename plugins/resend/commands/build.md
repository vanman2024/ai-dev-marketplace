---
description: Build complete Resend email system for new or existing projects with transactional emails, templates, broadcasts, and audience management
argument-hint: [project-name] [--existing]
---

# Build Resend Email System

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(resend-setup-agent) Analyze project for Resend setup.

Detect: Framework (Next.js, FastAPI), existing email
Check: Email requirements, templates needed
Output: Email strategy
```

---

## Phase 2: Core Setup

**Goal:** Set up Resend client

**Actions:**

```
Task(resend-setup-agent) Set up Resend core.

Requirements:
- Configure API key
- Set up Resend client
- Verify domain
- Configure sender addresses
- Test email sending
```

---

## Phase 3: Email Templates

**Goal:** Create email templates

**Actions:**

```
Task(resend-templates-agent) Set up email templates.

Requirements:
- Create React Email templates
- Set up template structure
- Add base components
- Configure styling
- Create preview system
```

---

## Phase 4: Transactional Emails

**Goal:** Set up transactional emails

**Actions:**

```
Task(resend-email-agent) Configure transactional emails.

Requirements:
- Create email functions
- Set up welcome email
- Add password reset email
- Configure notification emails
- Add email queuing
```

---

## Phase 5: Contact Management

**Goal:** Set up audience/contacts

**Actions:**

```
Task(resend-contacts-agent) Configure contacts.

Requirements:
- Set up audience lists
- Create contact management
- Add subscription handling
- Configure preferences
```

---

## Phase 6: Webhooks

**Goal:** Set up email webhooks

**Actions:**

```
Task(resend-domains-webhooks-agent) Configure webhooks.

Requirements:
- Create webhook endpoint
- Handle delivery events
- Track bounces/complaints
- Add analytics
```

---

## Summary

**Output:**

```
✅ Resend Email System Complete

To add features:
  /resend:add template <name>          # Email template
  /resend:add email <type>             # Transactional email
  /resend:add broadcast                # Marketing broadcast
  /resend:add contacts                 # Contact management
  /resend:add webhook                  # Email webhooks

To test:
  npm run email:preview
```
