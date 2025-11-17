# Make.com Complete API & SDK Reference

**Generated:** November 10, 2025  
**Source:** https://developers.make.com/api-documentation/api-reference

---

## 🎯 What Make.com Offers

### 1. **Make API** - REST API for automation

- Full CRUD operations on scenarios, organizations, teams, etc.
- Authentication via API tokens
- Webhook management, data stores, connections

### 2. **Custom Apps SDK** - Build your own integrations

- Create custom app modules for Make.com
- Web-based editor or local development
- Publish apps for your organization or public marketplace

### 3. **MCP Server** - AI Agent Integration (Early Access)

- Allow AI systems to trigger Make workflows
- Already integrated (we're using it!)

---

## 📚 Complete API Endpoints Reference

### **Affiliate**

- `/api-documentation/api-reference/affiliate`
- Manage affiliate program and partnerships

### **Agents**

- `/api-documentation/api-reference/agents`
- Manage Make agents

### **AI Agents**

- `/api-documentation/api-reference/ai-agents`
- `/api-documentation/api-reference/ai-agents-greater-than-context` - AI agent context
- `/api-documentation/api-reference/ai-agents-greater-than-llm-providers` - LLM providers

### **Analytics**

- `/api-documentation/api-reference/analytics`
- Get usage analytics and statistics

### **Audit Logs**

- `/api-documentation/api-reference/audit-logs`
- Access audit trail of activities

### **Cashier**

- `/api-documentation/api-reference/cashier`
- Billing and payment operations

### **Connections**

- `/api-documentation/api-reference/connections`
- **What we have via MCP**: `mcp_make_com_connections_get`, `mcp_make_com_connections_list`
- Manage app connections (OAuth, API keys, etc.)

### **Custom Properties**

- `/api-documentation/api-reference/custom-properties`
- `/api-documentation/api-reference/custom-properties-greater-than-structure-items`
- Define custom fields and metadata

### **Data Stores**

- `/api-documentation/api-reference/data-stores`
- `/api-documentation/api-reference/data-stores-greater-than-data`
- **Available via MCP activation**
- Create/manage NoSQL data storage
- CRUD operations on data store records

### **Data Structures**

- `/api-documentation/api-reference/data-structures`
- **Available via MCP activation**
- Define reusable data schemas

### **Devices**

- `/api-documentation/api-reference/devices`
- `/api-documentation/api-reference/devices-greater-than-incomings`
- `/api-documentation/api-reference/devices-greater-than-outgoing`
- Mobile device integrations

### **Enums**

- `/api-documentation/api-reference/enums`
- **Available via MCP activation**
- Get countries, regions, timezones lists

### **Custom Functions**

- `/api-documentation/api-reference/custom-functions`
- Create reusable JavaScript functions

### **General**

- `/api-documentation/api-reference/general`
- General API utilities

### **Hooks (Webhooks)**

- `/api-documentation/api-reference/hooks`
- `/api-documentation/api-reference/hooks-greater-than-incomings`
- `/api-documentation/api-reference/hooks-greater-than-logs`
- **Available via MCP activation**
- Create, manage, and monitor webhooks

### **Incomplete Executions**

- `/api-documentation/api-reference/incomplete-executions`
- Handle paused or incomplete scenario runs

### **Keys**

- `/api-documentation/api-reference/keys`
- **Available via MCP activation**
- Manage API keys and credentials

### **Notifications**

- `/api-documentation/api-reference/notifications`
- User notifications management

### **Organizations**

- `/api-documentation/api-reference/organizations`
- `/api-documentation/api-reference/organizations-greater-than-user-organization-roles`
- **What we have via MCP**: Full CRUD via `mcp_make_com_organizations_*`
- Create, manage organizations and user roles

### **Remote Procedures**

- `/api-documentation/api-reference/remote-procedures`
- Execute remote procedure calls (RPCs)

### **Scenarios** ⭐ MOST IMPORTANT

- `/api-documentation/api-reference/scenarios`
- **What we have via MCP**: Limited (activate, deactivate, run, delete, get, list)
- **What's available via API**: Full CRUD + more!

#### Scenarios Endpoints:

- `GET /api/v2/scenarios` - List all scenarios
- `POST /api/v2/scenarios` - **CREATE new scenario** ✅
- `GET /api/v2/scenarios/{scenarioId}` - Get scenario details
- `PATCH /api/v2/scenarios/{scenarioId}` - **UPDATE scenario** ✅
- `DELETE /api/v2/scenarios/{scenarioId}` - Delete scenario
- `POST /api/v2/scenarios/{scenarioId}/start` - Activate scenario
- `POST /api/v2/scenarios/{scenarioId}/stop` - Deactivate scenario
- `POST /api/v2/scenarios/{scenarioId}/run` - **Run scenario with data** ✅
- `POST /api/v2/scenarios/{scenarioId}/replay` - Replay execution
- `POST /api/v2/scenarios/{scenarioId}/clone` - **Clone scenario** ✅
- `GET /api/v2/scenarios/{scenarioId}/triggers` - Get trigger details
- `GET /api/v2/scenarios/{scenarioId}/interface` - Get inputs/outputs
- `PATCH /api/v2/scenarios/{scenarioId}/interface` - Update inputs/outputs
- `GET /api/v2/scenarios/{scenarioId}/usage` - Get usage statistics
- `GET /api/v2/scenarios/{scenarioId}/data/{moduleId}` - Check module data
- `GET /api/v2/scenarios/{scenarioId}/build-variables` - List buildtime variables
- `POST /api/v2/scenarios/{scenarioId}/build-variables` - Add variables
- `PUT /api/v2/scenarios/{scenarioId}/build-variables` - Update variables
- `DELETE /api/v2/scenarios/{scenarioId}/build-variables` - Delete variable

### **Scenarios > Logs**

- `/api-documentation/api-reference/scenarios-greater-than-logs`
- Access scenario execution logs

### **Scenarios > Blueprints**

- `/api-documentation/api-reference/scenarios-greater-than-blueprints`
- **Get/update scenario JSON blueprints** ✅
- This is the core of scenario building!

### **Scenarios > Consumptions**

- `/api-documentation/api-reference/scenarios-greater-than-consumptions`
- Track operations and data transfer usage

### **Scenarios > Tools**

- `/api-documentation/api-reference/scenarios-greater-than-tools`
- Scenario utilities and helpers

### **Scenarios > Custom Properties Data**

- `/api-documentation/api-reference/scenarios-greater-than-custom-properties-data`
- Manage custom metadata on scenarios

### **Scenarios Folders**

- `/api-documentation/api-reference/scenarios-folders`
- **Available via MCP activation**
- Organize scenarios into folders

### **SDK Apps** ⭐ THIS IS THE SDK!

- `/api-documentation/api-reference/sdk-apps`
- `/api-documentation/api-reference/sdk-apps-greater-than-invites`
- `/api-documentation/api-reference/sdk-apps-greater-than-modules`
- `/api-documentation/api-reference/sdk-apps-greater-than-rpcs`
- `/api-documentation/api-reference/sdk-apps-greater-than-functions`
- `/api-documentation/api-reference/sdk-apps-greater-than-connections`
- `/api-documentation/api-reference/sdk-apps-greater-than-webhooks`

**SDK Purpose**: Build custom apps/integrations FOR Make.com

- Create new modules (actions, triggers, searches)
- Define custom connections
- Add webhooks
- Build RPCs (Remote Procedure Calls)
- Package and publish to Make marketplace

### **SSO Certificates**

- `/api-documentation/api-reference/sso-certificates`
- Single Sign-On certificate management

### **Teams**

- `/api-documentation/api-reference/teams`
- `/api-documentation/api-reference/teams-greater-than-user-team-roles`
- **What we have via MCP**: Full CRUD via `mcp_make_com_teams_*`
- Manage teams and user roles

### **Templates**

- `/api-documentation/api-reference/templates`
- `/api-documentation/api-reference/templates-greater-than-public`
- Access and create scenario templates

### **Users**

- `/api-documentation/api-reference/users`
- `/api-documentation/api-reference/users-greater-than-me` - Current user info
- `/api-documentation/api-reference/users-greater-than-api-tokens` - Manage API tokens
- `/api-documentation/api-reference/users-greater-than-user-team-roles` - Team roles
- `/api-documentation/api-reference/users-greater-than-user-team-notifications` - Notifications
- `/api-documentation/api-reference/users-greater-than-user-organization-roles` - Org roles
- `/api-documentation/api-reference/users-greater-than-roles` - All roles
- `/api-documentation/api-reference/users-greater-than-unread-notifications` - Unread notifications
- `/api-documentation/api-reference/users-greater-than-user-email-preferences-mailhub` - Email preferences
- **What we have via MCP**: `mcp_make_com_users_me`

---

## 🔑 What's the SDK For?

**SDK Apps** are for **building NEW integrations** for Make.com, NOT for automating Make itself.

### SDK Use Cases:

1. **Build a custom Stripe integration**

   - Define modules: "Create Customer", "Get Invoice", etc.
   - Handle OAuth connection
   - Publish to your org or Make marketplace

2. **Create a proprietary API integration**

   - Your company's internal API
   - Custom authentication
   - Private within your organization

3. **Extend existing apps**
   - Add missing features to existing integrations
   - Custom data transformations

### SDK ≠ Scenario Building

- **SDK** = Build apps/modules FOR Make.com
- **API** = Automate Make.com itself (what we want!)

---

## 🎯 What We Need to Build

### Make.com Scenario Builder CLI

**Core Features:**

1. **Create Scenarios** via `POST /api/v2/scenarios`
2. **Update Scenarios** via `PATCH /api/v2/scenarios/{id}`
3. **Get Blueprints** to learn from existing scenarios
4. **Test/Run Scenarios** with custom data
5. **Clone Scenarios** for templates

**Example Usage:**

```bash
# Create from natural language
make-cli create "Webhook receives data, save to Airtable"

# Create from template
make-cli create --template webhook-to-airtable

# Update existing scenario
make-cli update 3330187 --add-module gmail:send-email

# Test run
make-cli run 3330187 --data '{"email":"test@example.com"}'

# Get blueprint to learn
make-cli get-blueprint 1566659 --output skylead-example.json
```

---

## 📊 What MCP Server Currently Provides

### ✅ Available Now:

- Connections (get, list)
- Executions (get, list)
- Organizations (CRUD)
- Scenarios (get, list, activate, deactivate, delete, run, interface)
- Teams (CRUD)
- Users (current user info)

### ❌ Missing from MCP (but available via API):

- **Scenario CREATE** - This is the big one!
- **Scenario UPDATE** - Modify existing scenarios
- **Blueprint operations** - Core building blocks
- Data stores, hooks, keys management
- Templates access
- Analytics and usage data
- Audit logs

---

## 🚀 Next Steps

1. **Build CLI Tool** that uses direct API calls for:
   - Creating scenarios from descriptions
   - Generating blueprint JSON
   - Testing scenarios
2. **Blueprint Library** - Study existing scenarios to build templates

3. **Wrap CLI in MCP later** - Make it AI-accessible

4. **Use existing MCP** for:
   - Listing scenarios
   - Running scenarios
   - Getting execution results

---

## 🔗 Key Documentation Links

- **API Reference**: https://developers.make.com/api-documentation/api-reference
- **Scenarios API**: https://developers.make.com/api-documentation/api-reference/scenarios
- **Blueprints**: https://developers.make.com/api-documentation/api-reference/scenarios-greater-than-blueprints
- **Custom Apps SDK**: https://developers.make.com/custom-apps-documentation/get-started/overview
- **MCP Server**: https://developers.make.com/mcp-server
- **Authentication**: https://developers.make.com/api-documentation/authentication

---

## 💡 Blueprint Structure Example

Every scenario has a blueprint (JSON) with:

```json
{
  "name": "My Scenario",
  "flow": [
    {
      "id": 1,
      "module": "gateway:webhook",
      "version": 1,
      "parameters": { ... },
      "mapper": { ... },
      "metadata": { ... }
    },
    {
      "id": 2,
      "module": "airtable:createRecord",
      "version": 1,
      "parameters": { ... },
      "mapper": { ... }
    }
  ],
  "metadata": {
    "version": 1,
    "scenario": { ... },
    "designer": { ... }
  }
}
```

This is what we'll generate programmatically! 🎉
