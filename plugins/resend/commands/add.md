---
description: Add a specific feature to an existing Resend project. Features include template, email, broadcast, contacts, webhook, domain.
argument-hint: <feature> [options]
---

# Add Resend Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Template Features

**If `$0` = "template":**

```
Task(resend-templates-agent) Add EMAIL TEMPLATE.

Requirements:
- Template name: $1 (required)
- Template type: $2 (welcome, notification, receipt, custom - default: custom)
- Create React Email template
- Add props interface
- Configure styling
- Add to preview
```

### Email Features

**If `$0` = "email":**

```
Task(resend-email-agent) Add TRANSACTIONAL EMAIL.

Requirements:
- Email type: $1 (welcome, reset, verify, notification - required)
- Template: $2 (template name or inline)
- Create email function
- Add to email service
- Configure triggers
- Add error handling
```

### Broadcast Features

**If `$0` = "broadcast":**

```
Task(resend-broadcasts-agent) Add BROADCAST email.

Requirements:
- Broadcast type: $1 (newsletter, announcement, marketing - default: newsletter)
- Audience: $2 (audience ID or all)
- Create broadcast template
- Set up scheduling
- Add analytics tracking
- Configure unsubscribe
```

### Contact Features

**If `$0` = "contacts":**

```
Task(resend-contacts-agent) Add CONTACT management.

Requirements:
- Feature: $1 (audience, subscribe, preferences - default: audience)
- Create audience list
- Add subscription forms
- Configure preferences
- Handle unsubscribes
```

### Webhook Features

**If `$0` = "webhook":**

```
Task(resend-domains-webhooks-agent) Add WEBHOOK handler.

Requirements:
- Events: $1 (delivery, bounce, complaint, all - default: all)
- Create webhook endpoint
- Verify signatures
- Handle events
- Add logging
```

### Domain Features

**If `$0` = "domain":**

```
Task(resend-domains-webhooks-agent) Add DOMAIN configuration.

Requirements:
- Domain: $1 (domain name - required)
- Action: $2 (verify, configure - default: verify)
- Verify domain ownership
- Configure DNS records
- Set up DKIM/SPF
```

---

## Usage Examples

```bash
# Templates
/resend:add template WelcomeEmail welcome
/resend:add template InvoiceEmail receipt
/resend:add template NotificationEmail notification

# Transactional emails
/resend:add email welcome WelcomeEmail
/resend:add email reset PasswordResetEmail
/resend:add email verify VerificationEmail

# Broadcasts
/resend:add broadcast newsletter
/resend:add broadcast announcement main-audience

# Contacts
/resend:add contacts audience
/resend:add contacts subscribe
/resend:add contacts preferences

# Webhooks & Domains
/resend:add webhook all
/resend:add domain example.com verify
```

---

## Feature Reference

| Feature     | Agent            | $1 Options                        | Description          |
| ----------- | ---------------- | --------------------------------- | -------------------- |
| `template`  | templates-agent  | template-name (required)          | Email template       |
| `email`     | email-agent      | welcome/reset/verify/notification | Transactional email  |
| `broadcast` | broadcasts-agent | newsletter/announcement/marketing | Marketing broadcast  |
| `contacts`  | contacts-agent   | audience/subscribe/preferences    | Contact management   |
| `webhook`   | webhooks-agent   | delivery/bounce/complaint/all     | Webhook handler      |
| `domain`    | webhooks-agent   | domain-name (required)            | Domain configuration |
