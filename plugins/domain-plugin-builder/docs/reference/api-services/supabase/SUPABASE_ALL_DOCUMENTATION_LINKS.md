# Complete Supabase Documentation Links

> Extracted from official Supabase documentation site navigation menus
> Last updated: October 26, 2025

## Table of Contents
- [Platform Documentation](#platform-documentation)
- [Deployment Documentation](#deployment-documentation)
- [Database Documentation](#database-documentation)
- [Auth Documentation](#auth-documentation)
- [Realtime Documentation](#realtime-documentation)
- [Storage Documentation](#storage-documentation)
- [Edge Functions Documentation](#edge-functions-documentation)
- [API Reference (Management API)](#api-reference-management-api)
- [REST API Guides](#rest-api-guides)
- [Supabase UI Library](#supabase-ui-library)

---

## Platform Documentation
**Base URL:** `https://supabase.com/docs/guides/platform`

### Core Links
- Overview: `/docs/guides/platform`

### Organizations
- Organizations: (link in navigation)

### Add-ons
- Custom Domains
- Database Backups
- IPv4 Address
- Read Replicas

### Upgrades & Migrations
- Upgrading
- Migrating within Supabase (dropdown with multiple pages)
- Migrating to Supabase (dropdown with multiple pages)

### Project & Account Management
- Access Control
- Multi-factor Authentication (dropdown)
- Transfer Project
- Restore to new project
- Single Sign-On (dropdown)

### Platform Configuration
- Regions
- Compute and Disk
- Database Size
- HIPAA Projects
- Network Restrictions
- Performance Tuning
- SSL Enforcement
- Default Platform Permissions
- PrivateLink

### Billing
- About billing on Supabase
- Get set up for billing
- Manage your subscription
- Manage your usage (dropdown)
- Your monthly invoice
- Control your costs
- Credits
- AWS Marketplace (dropdown)
- Billing FAQ

---

## Deployment Documentation
**Base URL:** `https://supabase.com/docs/guides/deployment`

### Core
- Overview: `/docs/guides/deployment`

### Environments
- Managing environments
- Database migrations

### Branching
- Overview: `/docs/guides/deployment/branching/*`
- Branching via GitHub
- Branching via dashboard
- Working with branches
- Configuration
- Integrations
- Troubleshooting
- Billing

### Terraform
- Terraform provider
- Terraform tutorial
- Terraform reference

### Production Readiness
- Shared responsibility model
- Maturity model
- Production checklist
- SOC 2 compliance

### CI/CD
- Generate types from your database
- Automated testing
- Back up your database

---

## Database Documentation
**Base URL:** `https://supabase.com/docs/guides/database`

### Overview
- Overview: `/docs/guides/database/overview`

### Fundamentals
- Connecting to your database: `/docs/guides/database/connecting-to-postgres`
- Importing data
- Securing your data

### Working with Database (Basics)
- Managing tables, views, and data: `/docs/guides/database/tables`
- Working with arrays: `/docs/guides/database/arrays`
- Managing indexes: `/docs/guides/database/indexes`
- Querying joins and nested tables: `/docs/guides/database/joins-and-nesting`
- JSON and unstructured data: `/docs/guides/database/json`

### Working with Database (Intermediate)
- Implementing cascade deletes: `/docs/guides/database/cascade-deletes`
- Managing enums: `/docs/guides/database/enums`
- Managing database functions: `/docs/guides/database/functions`
- Managing database triggers: `/docs/guides/database/triggers`
- Managing database webhooks: `/docs/guides/database/webhooks`
- Using Full Text Search: `/docs/guides/database/full-text-search`
- Partitioning your tables: `/docs/guides/database/partitions`
- Managing connections: `/docs/guides/database/connections`

### OrioleDB
- Overview

### Access & Security
- Row Level Security (RLS): `/docs/guides/database/postgres/row-level-security`
- Column Level Security
- Hardening the Data API
- Custom Claims & RBAC
- Managing Postgres Roles
- Using Custom Postgres Roles
- Managing secrets with Vault
- Superuser Access and Unsupported Operations

### Configuration, Optimization, Testing
- Database configuration
- Query optimization: `/docs/guides/database/query-optimization`
- Database Advisors
- Testing your database
- Customizing Postgres config

### Debugging
- Timeouts
- Debugging and monitoring
- Debugging performance issues: `/docs/guides/database/debugging-performance`
- Supavisor
- Troubleshooting

### ORM Quickstarts
- Prisma (dropdown)
- Drizzle
- Postgres.js

### GUI Quickstarts
- pgAdmin
- PSQL
- DBeaver
- Metabase
- Beekeeper Studio

### Database Replication
- Overview
- Setting up replication
- Monitoring replication
- FAQ

### Extensions (30+ extensions)
- Overview: `/docs/guides/database/extensions`
- HypoPG: `/docs/guides/database/extensions/hypopg`
- plv8 (deprecated): `/docs/guides/database/extensions/plv8`
- http: `/docs/guides/database/extensions/http`
- index_advisor: `/docs/guides/database/extensions/index_advisor`
- PGAudit: `/docs/guides/database/extensions/pgaudit`
- pgjwt (deprecated): `/docs/guides/database/extensions/pgjwt`
- PGroonga: `/docs/guides/database/extensions/pgroonga`
- pgRouting: `/docs/guides/database/extensions/pgrouting`
- pg_cron: `/docs/guides/database/extensions/pg_cron` **← CRITICAL FOR MARKETING AUTOMATION**
- pg_graphql: `/docs/guides/database/extensions/pg_graphql`
- pg_hashids: `/docs/guides/database/extensions/pg_hashids`
- pg_jsonschema: `/docs/guides/database/extensions/pg_jsonschema`
- pg_net: `/docs/guides/database/extensions/pg_net`
- pg_plan_filter: `/docs/guides/database/extensions/pg_plan_filter`
- postgres_fdw: `/docs/guides/database/extensions/postgres_fdw`
- **pgvector: `/docs/guides/database/extensions/pgvector`** **← CRITICAL FOR AI CATEGORIZATION**
- pg_stat_statements: `/docs/guides/database/extensions/pg_stat_statements`
- pg_repack: `/docs/guides/database/extensions/pg_repack`
- PostGIS: `/docs/guides/database/extensions/postgis`
- pgmq: `/docs/guides/database/extensions/pgmq`
- pgsodium: `/docs/guides/database/extensions/pgsodium`
- pgTAP: `/docs/guides/database/extensions/pgtap`
- plpgsql_check: `/docs/guides/database/extensions/plpgsql_check`
- timescaledb (deprecated): `/docs/guides/database/extensions/timescaledb`
- uuid-ossp: `/docs/guides/database/extensions/uuid-ossp`
- RUM: `/docs/guides/database/extensions/rum`

### Foreign Data Wrappers (15+ wrappers)
- Overview: `/docs/guides/database/extensions/wrappers/overview`
- Auth0: `/docs/guides/database/extensions/wrappers/auth0`
- Airtable: `/docs/guides/database/extensions/wrappers/airtable`
- AWS Cognito: `/docs/guides/database/extensions/wrappers/cognito`
- AWS S3: `/docs/guides/database/extensions/wrappers/s3`
- BigQuery: `/docs/guides/database/extensions/wrappers/bigquery`
- Clerk: `/docs/guides/database/extensions/wrappers/clerk`
- ClickHouse: `/docs/guides/database/extensions/wrappers/clickhouse`
- DuckDB: `/docs/guides/database/extensions/wrappers/duckdb`
- Firebase: `/docs/guides/database/extensions/wrappers/firebase`
- Iceberg: `/docs/guides/database/extensions/wrappers/iceberg`
- Logflare: `/docs/guides/database/extensions/wrappers/logflare`
- MSSQL: `/docs/guides/database/extensions/wrappers/mssql`
- Notion: `/docs/guides/database/extensions/wrappers/notion`
- Paddle: `/docs/guides/database/extensions/wrappers/paddle`
- Redis: `/docs/guides/database/extensions/wrappers/redis`
- Snowflake: `/docs/guides/database/extensions/wrappers/snowflake`
- Stripe: `/docs/guides/database/extensions/wrappers/stripe`

### Examples
- Drop All Tables in Schema
- Select First Row per Group
- Print PostgreSQL Version
- Replicating from Supabase to External Postgres

---

## Auth Documentation
**Base URL:** `https://supabase.com/docs/guides/auth`

### Core
- Overview: `/docs/guides/auth`
- Architecture

### Getting Started
- Next.js
- React
- React Native
- React Native with Expo & Social Auth

### Concepts
- Users
- Identities
- Sessions (dropdown)

### Flows (How-tos)
- Server-Side Rendering (dropdown): `/docs/guides/auth/server-side/*`
- Password-based: `/docs/guides/auth/password-based`
- Email (Magic Link or OTP): `/docs/guides/auth/email`
- Phone Login: `/docs/guides/auth/phone`
- Social Login (OAuth) (dropdown): `/docs/guides/auth/social-login/*`
- Enterprise SSO (dropdown): `/docs/guides/auth/enterprise-sso/*`
- Anonymous Sign-Ins: `/docs/guides/auth/anonymous`
- Web3 (Ethereum or Solana): `/docs/guides/auth/web3`
- Mobile Deep Linking: `/docs/guides/auth/deep-linking`
- Identity Linking: `/docs/guides/auth/identity-linking`
- Multi-Factor Authentication (dropdown): `/docs/guides/auth/mfa/*`
- Signout: `/docs/guides/auth/signout`

### Debugging
- Error Codes: `/docs/guides/auth/error-codes`
- Troubleshooting: `/docs/guides/auth/troubleshooting`

### Third-party Auth
- Overview
- Clerk: `/docs/guides/auth/third-party/clerk`
- Firebase Auth: `/docs/guides/auth/third-party/firebase`
- Auth0: `/docs/guides/auth/third-party/auth0`
- AWS Cognito (Amplify): `/docs/guides/auth/third-party/amplify`
- WorkOS: `/docs/guides/auth/third-party/workos`

### Configuration
- General Configuration: `/docs/guides/auth/config`
- Email Templates: `/docs/guides/auth/email-templates`
- Redirect URLs: `/docs/guides/auth/redirect-urls`
- Auth Hooks (dropdown): `/docs/guides/auth/hooks/*`
- Custom SMTP: `/docs/guides/auth/custom-smtp`
- User Management: `/docs/guides/auth/managing-user-data`

### Security
- Password Security: `/docs/guides/auth/password-security`
- Rate Limits: `/docs/guides/auth/rate-limits`
- Bot Detection (CAPTCHA): `/docs/guides/auth/captcha`
- Audit Logs: `/docs/guides/auth/audit-logs`
- JSON Web Tokens (JWT) (dropdown): `/docs/guides/auth/jwts/*`
- JWT Signing Keys: `/docs/guides/auth/jwt-signing-keys`
- Row Level Security: `/docs/guides/auth/row-level-security`
- Column Level Security: `/docs/guides/auth/column-level-security`
- Custom Claims & RBAC: `/docs/guides/auth/custom-claims-and-rbac`

### Auth UI
- Auth UI (Deprecated)
- Flutter Auth UI

### Social Auth Providers (19 providers)
- Apple: `/docs/guides/auth/social-login/auth-apple`
- Azure (Microsoft): `/docs/guides/auth/social-login/auth-azure`
- Bitbucket: `/docs/guides/auth/social-login/auth-bitbucket`
- Discord: `/docs/guides/auth/social-login/auth-discord`
- Facebook: `/docs/guides/auth/social-login/auth-facebook`
- Figma: `/docs/guides/auth/social-login/auth-figma`
- GitHub: `/docs/guides/auth/social-login/auth-github`
- GitLab: `/docs/guides/auth/social-login/auth-gitlab`
- Google: `/docs/guides/auth/social-login/auth-google`
- Kakao: `/docs/guides/auth/social-login/auth-kakao`
- Keycloak: `/docs/guides/auth/social-login/auth-keycloak`
- LinkedIn: `/docs/guides/auth/social-login/auth-linkedin`
- Notion: `/docs/guides/auth/social-login/auth-notion`
- Slack: `/docs/guides/auth/social-login/auth-slack`
- Spotify: `/docs/guides/auth/social-login/auth-spotify`
- Twitter: `/docs/guides/auth/social-login/auth-twitter`
- Twitch: `/docs/guides/auth/social-login/auth-twitch`
- WorkOS: `/docs/guides/auth/social-login/auth-workos`
- Zoom: `/docs/guides/auth/social-login/auth-zoom`

### Phone Auth Providers (3 providers)
- MessageBird: `/docs/guides/auth/phone-login/messagebird`
- Twilio: `/docs/guides/auth/phone-login/twilio`
- Vonage: `/docs/guides/auth/phone-login/vonage`

### Pricing
- MAU (Monthly Active Users)
- Third-Party MAU
- SSO MAU
- Advanced MFA - Phone

---

## Realtime Documentation
**Base URL:** `https://supabase.com/docs/guides/realtime`

### Core
- Overview: `/docs/guides/realtime`
- Getting Started: `/docs/guides/realtime/getting_started`

### Usage
- Broadcast: `/docs/guides/realtime/broadcast`
- Presence: `/docs/guides/realtime/presence`
- Postgres Changes: `/docs/guides/realtime/postgres-changes`
- Settings: `/docs/guides/realtime/settings`

### Security
- Authorization: `/docs/guides/realtime/authorization`

### Guides
- Subscribing to Database Changes: `/docs/guides/realtime/subscribing-to-database-changes`
- Using Realtime with Next.js: `/docs/guides/realtime/realtime-with-nextjs`
- Using Realtime Presence with Flutter: `/docs/guides/realtime/realtime-user-presence`
- Listening to Postgres Changes with Flutter: `/docs/guides/realtime/realtime-listening-flutter`

### Deep Dive
- Quotas: `/docs/guides/realtime/quotas`
- Pricing: `/docs/guides/realtime/pricing`
- Architecture: `/docs/guides/realtime/architecture`
- Concepts: `/docs/guides/realtime/concepts`
- Protocol: `/docs/guides/realtime/protocol`
- Benchmarks: `/docs/guides/realtime/benchmarks`

### Debugging
- Operational Error Codes: `/docs/guides/realtime/error_codes`
- Troubleshooting: `/docs/guides/realtime/troubleshooting`

---

## Storage Documentation
**Base URL:** `https://supabase.com/docs/guides/storage`

### Core
- Overview: `/docs/guides/storage`
- Quickstart: `/docs/guides/storage/quickstart`

### Buckets
- Fundamentals: `/docs/guides/storage/buckets/fundamentals`
- Creating Buckets: `/docs/guides/storage/buckets/creating-buckets`

### Security
- Ownership: `/docs/guides/storage/security/ownership`
- Access Control: `/docs/guides/storage/security/access-control`

### Uploads
- Standard Uploads: `/docs/guides/storage/uploads/standard-uploads`
- Resumable Uploads: `/docs/guides/storage/uploads/resumable-uploads`
- S3 Uploads: `/docs/guides/storage/uploads/s3-uploads`
- Limits: `/docs/guides/storage/uploads/file-limits`

### Serving
- Serving assets: `/docs/guides/storage/serving/downloads`
- Image Transformations: `/docs/guides/storage/serving/image-transformations`
- Bandwidth & Storage Egress: `/docs/guides/storage/serving/bandwidth`

### Management
- Copy / Move Objects: `/docs/guides/storage/management/copy-move-objects`
- Delete Objects: `/docs/guides/storage/management/delete-objects`
- Pricing: `/docs/guides/storage/management/pricing`

### S3
- Authentication: `/docs/guides/storage/s3/authentication`
- API Compatibility: `/docs/guides/storage/s3/compatibility`

### Analytics Buckets
- Introduction: `/docs/guides/storage/analytics/introduction`
- Creating Analytics Buckets: `/docs/guides/storage/analytics/creating-analytics-buckets`
- Connecting to Analytics Buckets: `/docs/guides/storage/analytics/connecting-to-analytics-bucket`
- Limits: `/docs/guides/storage/analytics/limits`

### CDN
- Fundamentals: `/docs/guides/storage/cdn/fundamentals`
- Smart CDN: `/docs/guides/storage/cdn/smart-cdn`
- Metrics: `/docs/guides/storage/cdn/metrics`

### Debugging
- Logs: `/docs/guides/storage/debugging/logs`
- Error Codes: `/docs/guides/storage/debugging/error-codes`
- Troubleshooting: `/docs/guides/storage/troubleshooting`

### Schema
- Database Design: `/docs/guides/storage/schema/design`
- Helper Functions: `/docs/guides/storage/schema/helper-functions`
- Custom Roles: `/docs/guides/storage/schema/custom-roles`

### Going to Production
- Scaling: `/docs/guides/storage/production/scaling`

---

## Edge Functions Documentation
**Base URL:** `https://supabase.com/docs/guides/functions`

### Core
- Overview: `/docs/guides/functions`

### Getting Started
- Quickstart (Dashboard): `/docs/guides/functions/quickstart-dashboard`
- Quickstart (CLI): `/docs/guides/functions/quickstart`
- Development Environment: `/docs/guides/functions/development-environment`
- Architecture: `/docs/guides/functions/architecture`

### Configuration
- Environment Variables: `/docs/guides/functions/secrets`
- Managing Dependencies: `/docs/guides/functions/dependencies`
- Function Configuration: `/docs/guides/functions/function-configuration`

### Development
- Error Handling: `/docs/guides/functions/error-handling`
- Routing: `/docs/guides/functions/routing`
- Deploy to Production: `/docs/guides/functions/deploy`

### Debugging
- Local Debugging with DevTools: `/docs/guides/functions/debugging-tools`
- Testing your Functions: `/docs/guides/functions/unit-test`
- Logging: `/docs/guides/functions/logging`
- Troubleshooting: `/docs/guides/functions/troubleshooting`

### Platform
- Regional invocations: `/docs/guides/functions/regional-invocation`
- Status codes: `/docs/guides/functions/status-codes`
- Limits: `/docs/guides/functions/limits`
- Pricing: `/docs/guides/functions/pricing`

### Integrations
- Supabase Auth: `/docs/guides/functions/auth`
- Supabase Database (Postgres): `/docs/guides/functions/connect-to-postgres`
- Supabase Storage: `/docs/guides/functions/storage-caching`

### Advanced Features
- Background Tasks: `/docs/guides/functions/background-tasks`
- File Storage: `/docs/guides/functions/ephemeral-storage`
- WebSockets: `/docs/guides/functions/websockets`
- Custom Routing: `/docs/guides/functions/routing`
- Wasm Modules: `/docs/guides/functions/wasm`
- AI Models: `/docs/guides/functions/ai-models`

### Examples (15+ examples)
- Auth Send Email Hook: `/docs/guides/functions/examples/auth-send-email-hook-react-email-resend`
- CORS support for invoking from the browser: `/docs/guides/functions/cors`
- Scheduling Functions: `/docs/guides/functions/schedule-functions`
- Sending Push Notifications: `/docs/guides/functions/examples/push-notifications`
- Generating AI images: `/docs/guides/functions/examples/amazon-bedrock-image-generator`
- Generating OG images: `/docs/guides/functions/examples/og-image`
- Semantic AI Search: `/docs/guides/functions/examples/semantic-search`
- CAPTCHA support with Cloudflare Turnstile: `/docs/guides/functions/examples/cloudflare-turnstile`
- Building a Discord Bot: `/docs/guides/functions/examples/discord-bot`
- Building a Telegram Bot: `/docs/guides/functions/examples/telegram-bot`
- Handling Stripe Webhooks: `/docs/guides/functions/examples/stripe-webhooks`
- Rate-limiting with Redis: `/docs/guides/functions/examples/rate-limiting`
- Taking Screenshots with Puppeteer: `/docs/guides/functions/examples/screenshots`
- Slack Bot responding to mentions: `/docs/guides/functions/examples/slack-bot-mention`
- Image Transformation & Optimization: `/docs/guides/functions/examples/image-manipulation`

### Third-Party Tools (11+ integrations)
- Dart Edge on Supabase: `/docs/guides/functions/dart-edge`
- Browserless.io: `/docs/guides/functions/examples/screenshots`
- Hugging Face: `/docs/guides/ai/examples/huggingface-image-captioning`
- Monitoring with Sentry: `/docs/guides/functions/examples/sentry-monitoring`
- OpenAI API: `/docs/guides/ai/examples/openai`
- React Email: `/docs/guides/functions/examples/auth-send-email-hook-react-email-resend`
- Sending Emails with Resend: `/docs/guides/functions/examples/send-emails`
- Upstash Redis: `/docs/guides/functions/examples/upstash-redis`
- Type-Safe SQL with Kysely: `/docs/guides/functions/kysely-postgres`
- Text To Speech with ElevenLabs: `/docs/guides/functions/examples/elevenlabs-generate-speech-stream`
- Speech Transcription with ElevenLabs: `/docs/guides/functions/examples/elevenlabs-transcribe-speech`

---

## API Reference (Management API)
**Base URL:** `https://supabase.com/docs/reference/api/introduction`

### Introduction
- Introduction: `/docs/reference/api/introduction`

### Advisors
- Get performance advisors: `/docs/reference/api/v1-get-performance-advisors`
- Get security advisors: `/docs/reference/api/v1-get-security-advisors`

### Analytics
- Get project function combined stats: `/docs/reference/api/v1-get-project-function-combined-stats`
- Get project logs: `/docs/reference/api/v1-get-project-logs`
- Get project usage api count: `/docs/reference/api/v1-get-project-usage-api-count`
- Get project usage request count: `/docs/reference/api/v1-get-project-usage-request-count`

### Auth (19 endpoints)
- Create a sso provider: `/docs/reference/api/v1-create-a-sso-provider`
- Create legacy signing key: `/docs/reference/api/v1-create-legacy-signing-key`
- Create project signing key: `/docs/reference/api/v1-create-project-signing-key`
- Create project tpa integration: `/docs/reference/api/v1-create-project-tpa-integration`
- Delete a sso provider: `/docs/reference/api/v1-delete-a-sso-provider`
- Delete project tpa integration: `/docs/reference/api/v1-delete-project-tpa-integration`
- Get a sso provider: `/docs/reference/api/v1-get-a-sso-provider`
- Get auth service config: `/docs/reference/api/v1-get-auth-service-config`
- Get legacy signing key: `/docs/reference/api/v1-get-legacy-signing-key`
- Get project signing key: `/docs/reference/api/v1-get-project-signing-key`
- Get project signing keys: `/docs/reference/api/v1-get-project-signing-keys`
- Get project tpa integration: `/docs/reference/api/v1-get-project-tpa-integration`
- List all sso provider: `/docs/reference/api/v1-list-all-sso-provider`
- List project tpa integrations: `/docs/reference/api/v1-list-project-tpa-integrations`
- Remove project signing key: `/docs/reference/api/v1-remove-project-signing-key`
- Update a sso provider: `/docs/reference/api/v1-update-a-sso-provider`
- Update auth service config: `/docs/reference/api/v1-update-auth-service-config`
- Update project signing key: `/docs/reference/api/v1-update-project-signing-key`

### Billing
- Apply project addon: `/docs/reference/api/v1-apply-project-addon`
- List project addons: `/docs/reference/api/v1-list-project-addons`
- Remove project addon: `/docs/reference/api/v1-remove-project-addon`

### Database (30+ endpoints)
- Apply a migration: `/docs/reference/api/v1-apply-a-migration`
- Authorize jit access: `/docs/reference/api/v1-authorize-jit-access`
- Create login role: `/docs/reference/api/v1-create-login-role`
- Delete jit access: `/docs/reference/api/v1-delete-jit-access`
- Delete login roles: `/docs/reference/api/v1-delete-login-roles`
- Disable readonly mode temporarily: `/docs/reference/api/v1-disable-readonly-mode-temporarily`
- Enable database webhook: `/docs/reference/api/v1-enable-database-webhook`
- Generate typescript types: `/docs/reference/api/v1-generate-typescript-types`
- Get a snippet: `/docs/reference/api/v1-get-a-snippet`
- Get database metadata: `/docs/reference/api/v1-get-database-metadata`
- Get jit access: `/docs/reference/api/v1-get-jit-access`
- Get pooler config: `/docs/reference/api/v1-get-pooler-config`
- Get postgres config: `/docs/reference/api/v1-get-postgres-config`
- Get project pgbouncer config: `/docs/reference/api/v1-get-project-pgbouncer-config`
- Get readonly mode status: `/docs/reference/api/v1-get-readonly-mode-status`
- Get ssl enforcement config: `/docs/reference/api/v1-get-ssl-enforcement-config`
- List all backups: `/docs/reference/api/v1-list-all-backups`
- List all snippets: `/docs/reference/api/v1-list-all-snippets`
- List jit access: `/docs/reference/api/v1-list-jit-access`
- List migration history: `/docs/reference/api/v1-list-migration-history`
- Remove a read replica: `/docs/reference/api/v1-remove-a-read-replica`
- Restore pitr backup: `/docs/reference/api/v1-restore-pitr-backup`
- Run a query: `/docs/reference/api/v1-run-a-query`
- Setup a read replica: `/docs/reference/api/v1-setup-a-read-replica`
- Update jit access: `/docs/reference/api/v1-update-jit-access`
- Update pooler config: `/docs/reference/api/v1-update-pooler-config`
- Update postgres config: `/docs/reference/api/v1-update-postgres-config`
- Update ssl enforcement config: `/docs/reference/api/v1-update-ssl-enforcement-config`
- Upsert a migration: `/docs/reference/api/v1-upsert-a-migration`

### Domains
- Activate custom hostname: `/docs/reference/api/v1-activate-custom-hostname`
- Activate vanity subdomain config: `/docs/reference/api/v1-activate-vanity-subdomain-config`
- Check vanity subdomain availability: `/docs/reference/api/v1-check-vanity-subdomain-availability`
- Deactivate vanity subdomain config: `/docs/reference/api/v1-deactivate-vanity-subdomain-config`
- Get hostname config: `/docs/reference/api/v1-get-hostname-config`
- Get vanity subdomain config: `/docs/reference/api/v1-get-vanity-subdomain-config`
- Update hostname config: `/docs/reference/api/v1-update-hostname-config`
- Verify dns config: `/docs/reference/api/v1-verify-dns-config`

### Edge Functions
- Bulk update functions: `/docs/reference/api/v1-bulk-update-functions`
- Create a function: `/docs/reference/api/v1-create-a-function`
- Delete a function: `/docs/reference/api/v1-delete-a-function`
- Deploy a function: `/docs/reference/api/v1-deploy-a-function`
- Get a function: `/docs/reference/api/v1-get-a-function`
- Get a function body: `/docs/reference/api/v1-get-a-function-body`
- List all functions: `/docs/reference/api/v1-list-all-functions`
- Update a function: `/docs/reference/api/v1-update-a-function`

### Environments (Branching)
- Count action runs: `/docs/reference/api/v1-count-action-runs`
- Create a branch: `/docs/reference/api/v1-create-a-branch`
- Delete a branch: `/docs/reference/api/v1-delete-a-branch`
- Diff a branch: `/docs/reference/api/v1-diff-a-branch`
- Disable preview branching: `/docs/reference/api/v1-disable-preview-branching`
- Get a branch: `/docs/reference/api/v1-get-a-branch`
- Get a branch config: `/docs/reference/api/v1-get-a-branch-config`
- Get action run: `/docs/reference/api/v1-get-action-run`
- Get action run logs: `/docs/reference/api/v1-get-action-run-logs`
- List action runs: `/docs/reference/api/v1-list-action-runs`
- List all branches: `/docs/reference/api/v1-list-all-branches`
- Merge a branch: `/docs/reference/api/v1-merge-a-branch`
- Push a branch: `/docs/reference/api/v1-push-a-branch`
- Reset a branch: `/docs/reference/api/v1-reset-a-branch`
- Update a branch config: `/docs/reference/api/v1-update-a-branch-config`
- Update action run status: `/docs/reference/api/v1-update-action-run-status`

### OAuth
- Authorize user: `/docs/reference/api/v1-authorize-user`
- Exchange oauth token: `/docs/reference/api/v1-exchange-oauth-token`
- Oauth authorize project claim: `/docs/reference/api/v1-oauth-authorize-project-claim`
- Revoke token: `/docs/reference/api/v1-revoke-token`

### Organizations
- Create an organization: `/docs/reference/api/v1-create-an-organization`
- Get an organization: `/docs/reference/api/v1-get-an-organization`
- List all organizations: `/docs/reference/api/v1-list-all-organizations`
- List organization members: `/docs/reference/api/v1-list-organization-members`

### Projects (20+ endpoints)
- Cancel a project restoration: `/docs/reference/api/v1-cancel-a-project-restoration`
- Create a project: `/docs/reference/api/v1-create-a-project`
- Delete a project: `/docs/reference/api/v1-delete-a-project`
- Delete network bans: `/docs/reference/api/v1-delete-network-bans`
- Get available regions: `/docs/reference/api/v1-get-available-regions`
- Get network restrictions: `/docs/reference/api/v1-get-network-restrictions`
- Get postgres upgrade eligibility: `/docs/reference/api/v1-get-postgres-upgrade-eligibility`
- Get postgres upgrade status: `/docs/reference/api/v1-get-postgres-upgrade-status`
- Get project: `/docs/reference/api/v1-get-project`
- Get services health: `/docs/reference/api/v1-get-services-health`
- List all network bans: `/docs/reference/api/v1-list-all-network-bans`
- List all network bans enriched: `/docs/reference/api/v1-list-all-network-bans-enriched`
- List all projects: `/docs/reference/api/v1-list-all-projects`
- List available restore versions: `/docs/reference/api/v1-list-available-restore-versions`
- Patch network restrictions: `/docs/reference/api/v1-patch-network-restrictions`
- Pause a project: `/docs/reference/api/v1-pause-a-project`
- Restore a project: `/docs/reference/api/v1-restore-a-project`
- Update network restrictions: `/docs/reference/api/v1-update-network-restrictions`
- Upgrade postgres version: `/docs/reference/api/v1-upgrade-postgres-version`

### Rest
- Get postgrest service config: `/docs/reference/api/v1-get-postgrest-service-config`
- Update postgrest service config: `/docs/reference/api/v1-update-postgrest-service-config`

### Secrets
- Bulk create secrets: `/docs/reference/api/v1-bulk-create-secrets`
- Bulk delete secrets: `/docs/reference/api/v1-bulk-delete-secrets`
- Create project api key: `/docs/reference/api/v1-create-project-api-key`
- Delete project api key: `/docs/reference/api/v1-delete-project-api-key`
- Get pgsodium config: `/docs/reference/api/v1-get-pgsodium-config`
- Get project api key: `/docs/reference/api/v1-get-project-api-key`
- Get project api keys: `/docs/reference/api/v1-get-project-api-keys`
- Get project legacy api keys: `/docs/reference/api/v1-get-project-legacy-api-keys`
- List all secrets: `/docs/reference/api/v1-list-all-secrets`
- Update pgsodium config: `/docs/reference/api/v1-update-pgsodium-config`
- Update project api key: `/docs/reference/api/v1-update-project-api-key`
- Update project legacy api keys: `/docs/reference/api/v1-update-project-legacy-api-keys`

### Storage
- Get storage config: `/docs/reference/api/v1-get-storage-config`
- List all buckets: `/docs/reference/api/v1-list-all-buckets`
- Update storage config: `/docs/reference/api/v1-update-storage-config`

---

## REST API Guides
**Base URL:** `https://supabase.com/docs/guides/api`

### Core
- Overview: `/docs/guides/api`
- Quickstart: `/docs/guides/api/quickstart`
- Client Libraries: `/docs/guides/api/rest/client-libs`
- Auto-generated Docs: `/docs/guides/api/rest/auto-generated-docs`
- Generating TypeScript Types: `/docs/guides/api/rest/generating-types`

### Tools
- SQL to REST API Translator: `/docs/guides/api/sql-to-rest`

### Guides
- Creating API routes: `/docs/guides/api/creating-routes`
- How API Keys work: `/docs/guides/api/api-keys`
- Securing your API: `/docs/guides/api/securing-your-api`

### Using the Data APIs
- Managing tables, views, and data: `/docs/guides/database/tables`
- Querying joins and nested tables: `/docs/guides/database/joins-and-nesting`
- JSON and unstructured data: `/docs/guides/database/json`
- Managing database functions: `/docs/guides/database/functions`
- Using full-text search: `/docs/guides/database/full-text-search`
- Debugging performance issues: `/docs/guides/database/debugging-performance`
- Using custom schemas: `/docs/guides/api/using-custom-schemas`
- Converting from SQL to JavaScript API: `/docs/guides/api/sql-to-api`

---

## Supabase UI Library
**Base URL:** `https://supabase.com/ui`

### Getting Started
- Introduction: `/ui/docs/getting-started/introduction`
- Quick Start: `/ui/docs/getting-started/quickstart`
- FAQ: `/ui/docs/getting-started/faq`

### Blocks (9 components)
- Client: `/ui/docs/nextjs/client`
- Password-Based Auth: `/ui/docs/nextjs/password-based-auth`
- Social Auth (NEW): `/ui/docs/nextjs/social-auth`
- Dropzone: `/ui/docs/nextjs/dropzone`
- Realtime Cursor: `/ui/docs/nextjs/realtime-cursor`
- Current User Avatar: `/ui/docs/nextjs/current-user-avatar`
- Realtime Avatar Stack: `/ui/docs/nextjs/realtime-avatar-stack`
- Realtime Chat: `/ui/docs/nextjs/realtime-chat`
- Infinite Query Hook (NEW): `/ui/docs/infinite-query-hook`

### AI Editors Rules
- Prompts: `/ui/docs/ai-editors-rules/prompts`

### Platform
- Platform Kit: `/ui/docs/platform/platform-kit`

---

## Additional Resources

### External Resources
- PostgREST Docs: `https://postgrest.org/`
- PostgREST GitHub: `https://github.com/PostgREST/postgrest`
- Supabase GitHub: `https://github.com/supabase/supabase`
- Supabase UI Library GitHub: `https://github.com/supabase/supabase/tree/master/apps/ui-library`
- Storage API Swagger: `https://supabase.github.io/storage/`
- Management API OpenAPI: `https://api.supabase.com/api/v1`
- Management API JSON: `https://api.supabase.com/api/v1-json`

### Priority Links for Marketing Automation
1. **pgvector Extension**: `/docs/guides/database/extensions/pgvector` (AI-powered categorization)
2. **pg_cron Extension**: `/docs/guides/database/extensions/pg_cron` (Scheduled campaigns)
3. **Realtime Postgres Changes**: `/docs/guides/realtime/postgres-changes` (Campaign monitoring)
4. **Storage**: `/docs/guides/storage` (Asset management)
5. **Auth + RLS**: `/docs/guides/auth` + `/docs/guides/database/postgres/row-level-security`
6. **Database Triggers**: `/docs/guides/database/triggers` (Automated workflows)
7. **Edge Functions AI Models**: `/docs/guides/functions/ai-models` (AI integration)

---

## Total Link Count

- **Platform**: 30+ pages
- **Deployment**: 20+ pages
- **Database**: 100+ pages (including 30 extensions + 15 FDWs)
- **Auth**: 70+ pages (including 19 social + 3 phone providers)
- **Realtime**: 20+ pages
- **Storage**: 30+ pages
- **Edge Functions**: 50+ pages
- **Management API**: 200+ endpoints
- **REST API Guides**: 12+ pages
- **Supabase UI**: 15+ pages

**Grand Total: 550+ documentation pages/endpoints**
