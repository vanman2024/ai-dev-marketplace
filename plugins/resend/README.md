# resend

Resend email API integration for sending transactional emails, managing contacts, broadcasts, templates, domains, and webhooks.

## Installation

```bash
/plugin install resend@ai-dev-marketplace
```

## Features

- **Email Sending**: Send single and batch transactional emails
- **Contacts Management**: Create, update, delete contacts and manage segments
- **Broadcasts**: Create and send email broadcasts to audiences
- **Templates**: Manage email templates with versioning
- **Domains**: Configure and verify sending domains
- **Webhooks**: Set up event notifications for email tracking
- **API Keys**: Manage API key lifecycle

## Commands

| Command | Description |
|---------|-------------|
| `/resend:init` | Initialize Resend SDK in project |
| `/resend:send-email` | Send transactional email |
| `/resend:add-contacts` | Add contact management |
| `/resend:add-broadcasts` | Add broadcast functionality |
| `/resend:add-templates` | Add template management |
| `/resend:add-domains` | Add domain configuration |
| `/resend:add-webhooks` | Add webhook handlers |
| `/resend:add-react-email` | Add React Email integration |

## Components

- **Commands**: Slash commands for Resend integration
- **Agents**: Specialized AI agents for email workflows
- **Skills**: Reusable email patterns and templates

## Environment Variables

```bash
# .env.example
RESEND_API_KEY=your_resend_api_key_here
```

Get your API key from: https://resend.com/api-keys

## License

MIT
