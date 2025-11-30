---
description: Configure sending domains with DNS verification (SPF, DKIM, DMARC)
argument-hint: <domain-name>
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep
---

**Arguments**: $ARGUMENTS

Goal: Add and configure a sending domain in Resend with complete DNS verification setup

Core Principles:
- Understand the domain before configuration
- Generate clear DNS records with verification steps
- Provide actionable guidance for DNS setup
- Validate domain status after configuration

Phase 1: Discovery
Goal: Understand the domain configuration request

Actions:
- Parse $ARGUMENTS to extract domain name
- If domain unclear, prompt user for clarification
- Load Resend API documentation for domain endpoints
- Verify domain format is valid (basic DNS validation)

Phase 2: Analysis
Goal: Understand current setup and Resend capabilities

Actions:
- Read @plugins/resend/agents/resend-domains-webhooks-agent.md to understand agent capabilities
- Identify required DNS records (SPF, DKIM, DMARC)
- Plan verification workflow:
  - Add domain to Resend
  - Generate DNS records
  - Provide setup instructions
  - Check verification status

Phase 3: Configuration
Goal: Configure domain in Resend with complete DNS setup

Actions:

Task(description="Configure sending domain", subagent_type="resend-domains-webhooks-agent", prompt="You are the resend-domains-webhooks-agent. Configure the sending domain $ARGUMENTS in Resend with complete DNS verification setup.

Actions to perform:
1. Add domain to Resend using the Resend API
2. Generate DNS records needed for verification:
   - SPF record (Sender Policy Framework)
   - DKIM record (DomainKeys Identified Mail)
   - DMARC record (Domain-based Message Authentication)
3. Provide clear step-by-step instructions for:
   - Where to find DNS settings in domain registrar
   - Exact DNS records to add
   - TTL recommendations
   - Verification timeline expectations
4. Check domain verification status
5. Return domain configuration summary with:
   - Domain details (name, created date)
   - DNS records to add (with exact values)
   - Verification status
   - Next steps if verification needed

Required output format:
- Domain Configuration Summary
- DNS Records to Add (3 records minimum)
- Setup Instructions
- Verification Status
- Troubleshooting tips")

Phase 4: Summary
Goal: Document the domain configuration process

Actions:
- Summarize domain name and configuration status
- List all DNS records that need to be added
- Provide next steps for verification completion
- Suggest timeline for email delivery readiness
