# .ai-stack-config.json Schema Documentation

## Overview

`.ai-stack-config.json` is the **state tracking and configuration file** used by the ai-tech-stack-1 plugin to:
1. **Track phase completion** across the 6-phase deployment lifecycle
2. **Store user configuration** (app type, features, auth, AI architecture)
3. **Enable resumption** with fresh context when needed
4. **Validate readiness** before proceeding to next phase

## File Location

```
project-root/
├── .ai-stack-config.json    ← Created during Phase 1
├── app-name/                # Next.js frontend
└── app-name-backend/        # FastAPI backend
```

## Complete Schema

```json
{
  // Application Identity
  "appName": "string",              // App name (from $ARGUMENTS)
  "mode": "spec-driven" | "interactive",  // Configuration mode

  // Phase Tracking (0-6)
  "phase": 0-6,                     // Current phase number
  "phase0Complete": true | false,   // Phase 0: Dev lifecycle foundation
  "phase1Complete": true | false,   // Phase 1: Foundation (Next.js, FastAPI, Supabase)
  "phase2Complete": true | false,   // Phase 2: AI Features
  "phase3Complete": true | false,   // Phase 3: Integration
  "phase4Complete": true | false,   // Phase 4: Testing & Quality
  "phase5Complete": true | false,   // Phase 5: Production Deployment
  "phase6Complete": true | false,   // Phase 6: Versioning & Summary
  "allPhasesComplete": true | false, // All phases done

  // User Configuration (from Phase 1)
  "specId": "string",               // Spec ID if spec-driven mode (e.g., "001-red-seal-ai")
  "appType": "string",              // App type: "Red AI", "Chatbot", "RAG System", "Multi-Agent Platform"
  "backend": ["string"],            // Backend features: ["REST API", "GraphQL", "WebSockets", "Background tasks"]
  "database": ["string"],           // Database features: ["Multi-tenant", "Vector search", "Realtime", "File storage"]
  "auth": ["string"],               // Auth methods: ["Email/password", "OAuth providers", "Magic link", "MFA"]

  // AI Architecture Configuration
  "aiArchitecture": {
    "claudeAgentSDK": true | false,  // Use Claude Agent SDK for orchestration
    "mcpServers": ["string"],        // MCP servers: ["supabase", "memory", "filesystem"]
    "mem0": true | false,            // Use Mem0 for memory persistence
    "vercelAISDK": true | false      // Use Vercel AI SDK for streaming
  },

  // Testing Results (Phase 4)
  "testsPassedNewman": true | false,    // Newman API tests passed
  "testsPassedPlaywright": true | false, // Playwright E2E tests passed
  "securityPassed": true | false,        // Security scans passed

  // Deployment Info (Phase 5)
  "deployed": true | false,          // Deployment successful
  "frontendUrl": "string",           // Frontend URL (Vercel)
  "backendUrl": "string",            // Backend URL (Fly.io)
  "deploymentTimestamp": "string",   // ISO 8601 timestamp
  "validationPassed": true | false,  // Deployment validation passed

  // Timestamps
  "timestamp": "string",             // Created timestamp (ISO 8601)
  "completedAt": "string",           // Completion timestamp (ISO 8601)

  // Next Phase Guidance
  "nextPhase": "string"              // Next phase to run (e.g., "Phase 2 - AI Features")
}
```

## Field Descriptions

### Application Identity

#### `appName` (string, required)
- **Created in:** Phase 1
- **Source:** `$ARGUMENTS` passed to `/ai-tech-stack-1:build-full-stack [app-name]`
- **Example:** `"red-ai"`
- **Usage:** Used to create directory names (`red-ai/`, `red-ai-backend/`)

#### `mode` (string, required)
- **Created in:** Phase 1
- **Values:**
  - `"spec-driven"` - Auto-configured from `specs/` directory
  - `"interactive"` - User answers questions via `AskUserQuestion`
- **Detection Logic:**
  ```bash
  if [ -d "specs" ] && [ "$(ls -A specs 2>/dev/null)" ]; then
    echo "spec-driven"
  else
    echo "interactive"
  fi
  ```

### Phase Tracking

#### `phase` (number, required)
- **Created in:** Phase 1 (set to 1)
- **Updated in:** Every phase transition
- **Range:** 0-6
- **Usage:** Determines which phase to run next on resume
- **Example:** `2` means Phase 2 is in progress or just completed

#### `phase0Complete` through `phase6Complete` (boolean)
- **Created in:** End of each respective phase
- **Default:** `false`
- **Set to `true`:** When phase completes successfully
- **Usage:** Validation gates before proceeding to next phase
- **Example:**
  ```json
  {
    "phase0Complete": true,  // ✅ Phase 0 done
    "phase1Complete": true,  // ✅ Phase 1 done
    "phase2Complete": false  // ⏸️ Phase 2 not started/incomplete
  }
  ```

#### `allPhasesComplete` (boolean)
- **Created in:** Phase 6 (final phase)
- **Set to `true`:** When all 6 phases complete
- **Usage:** Indicates full deployment finished

### User Configuration

#### `specId` (string, optional)
- **Created in:** Phase 1 (spec-driven mode only)
- **Source:** Directory name from `specs/001-red-seal-ai/` → `"001-red-seal-ai"`
- **Usage:** References which spec was used for auto-configuration
- **Example:** `"001-red-seal-ai"`

#### `appType` (string, required)
- **Created in:** Phase 1
- **Source:**
  - Spec-driven: Parsed from `spec.md` (searches for "platform", "chatbot", "RAG", "multi-agent")
  - Interactive: User selection via `AskUserQuestion`
- **Common Values:**
  - `"Red AI"` - Multi-pillar AI platform
  - `"Chatbot"` - Conversational AI
  - `"RAG System"` - Vector search application
  - `"Multi-Agent Platform"` - Complex agent orchestration
- **Example:** `"Red AI"`

#### `backend` (array of strings, required)
- **Created in:** Phase 1
- **Source:**
  - Spec-driven: Parsed from spec (searches for "REST", "GraphQL", "WebSockets", "FastAPI")
  - Interactive: User multi-select via `AskUserQuestion`
- **Common Values:**
  - `"REST API"` - RESTful endpoints
  - `"GraphQL"` - GraphQL API
  - `"WebSockets"` - Real-time communication
  - `"Background tasks"` - Async job processing
- **Example:** `["REST API", "WebSockets", "Background tasks"]`

#### `database` (array of strings, required)
- **Created in:** Phase 1
- **Source:**
  - Spec-driven: Parsed from spec (searches for "vector", "pgvector", "multi-tenant", "realtime")
  - Interactive: User multi-select via `AskUserQuestion`
- **Common Values:**
  - `"Multi-tenant"` - Multi-tenant architecture
  - `"Vector search"` - pgvector for RAG
  - `"Realtime"` - Supabase realtime subscriptions
  - `"File storage"` - Supabase Storage buckets
- **Example:** `["Multi-tenant", "Vector search", "Realtime"]`

#### `auth` (array of strings, required)
- **Created in:** Phase 1
- **Source:**
  - Spec-driven: Parsed from spec (searches for "OAuth", "email", "authentication", "MFA")
  - Interactive: User multi-select via `AskUserQuestion`
- **Common Values:**
  - `"Email/password"` - Email-based auth
  - `"OAuth providers"` - Google, GitHub, etc.
  - `"Magic link"` - Passwordless email login
  - `"MFA"` - Multi-factor authentication
- **Example:** `["Email/password", "OAuth providers"]`

### AI Architecture Configuration

#### `aiArchitecture` (object, required)
Container for AI-related architecture decisions.

##### `claudeAgentSDK` (boolean, required)
- **Created in:** Phase 1
- **Source:** Parsed from spec or user selection
- **Usage:** Determines if Claude Agent SDK will be integrated in Phase 2
- **Example:** `true`

##### `mcpServers` (array of strings, required)
- **Created in:** Phase 1
- **Source:** Detected from spec or user selection
- **Common Values:**
  - `"supabase"` - Supabase MCP server
  - `"memory"` - Mem0 OpenMemory MCP server
  - `"filesystem"` - Filesystem MCP server
- **Usage:** Determines which MCP servers to configure in `.mcp.json`
- **Example:** `["supabase", "memory", "filesystem"]`

##### `mem0` (boolean, required)
- **Created in:** Phase 1
- **Source:** Parsed from spec or user selection
- **Usage:** Determines if Mem0 memory persistence will be integrated in Phase 2
- **Example:** `true`

##### `vercelAISDK` (boolean, required)
- **Created in:** Phase 1
- **Source:** Parsed from spec or user selection
- **Usage:** Determines if Vercel AI SDK will be integrated in Phase 2
- **Example:** `true`

### Testing Results (Phase 4)

#### `testsPassedNewman` (boolean, optional)
- **Created in:** Phase 4 (Testing & Quality)
- **Source:** Result of `/quality:test newman` command
- **Usage:** Gates deployment - must be `true` to proceed to Phase 5
- **Example:** `true`

#### `testsPassedPlaywright` (boolean, optional)
- **Created in:** Phase 4 (Testing & Quality)
- **Source:** Result of `/quality:test playwright` command
- **Usage:** Gates deployment - must be `true` to proceed to Phase 5
- **Example:** `true`

#### `securityPassed` (boolean, optional)
- **Created in:** Phase 4 (Testing & Quality)
- **Source:** Result of `/quality:security` command
- **Usage:** Gates deployment - must be `true` to proceed to Phase 5
- **Example:** `true`

### Deployment Info (Phase 5)

#### `deployed` (boolean, optional)
- **Created in:** Phase 5 (Production Deployment)
- **Set to `true`:** When both frontend and backend deploy successfully
- **Usage:** Indicates successful production deployment
- **Example:** `true`

#### `frontendUrl` (string, optional)
- **Created in:** Phase 5
- **Source:** Vercel deployment URL
- **Format:** `https://{app-name}.vercel.app`
- **Example:** `"https://red-ai.vercel.app"`

#### `backendUrl` (string, optional)
- **Created in:** Phase 5
- **Source:** Fly.io deployment URL
- **Format:** `https://{app-name}-backend.fly.dev`
- **Example:** `"https://red-ai-backend.fly.dev"`

#### `deploymentTimestamp` (string, optional)
- **Created in:** Phase 5
- **Format:** ISO 8601 timestamp
- **Example:** `"2025-10-31T15:30:00Z"`

#### `validationPassed` (boolean, optional)
- **Created in:** Phase 5
- **Source:** Result of `/deployment:validate` command
- **Usage:** Confirms deployment is healthy (endpoints accessible, health checks pass)
- **Example:** `true`

### Timestamps

#### `timestamp` (string, required)
- **Created in:** Phase 1 (file creation)
- **Format:** ISO 8601 timestamp
- **Usage:** Records when deployment started
- **Example:** `"2025-10-31T12:00:00Z"`
- **Command:**
  ```bash
  date -u +%Y-%m-%dT%H:%M:%SZ
  ```

#### `completedAt` (string, optional)
- **Created in:** Updated at end of each phase, final value in Phase 6
- **Format:** ISO 8601 timestamp
- **Usage:** Records when current phase completed
- **Example:** `"2025-10-31T15:00:00Z"`

### Next Phase Guidance

#### `nextPhase` (string, optional)
- **Created in:** End of each phase
- **Updated in:** Every phase transition
- **Usage:** Tells user which phase to run next
- **Examples:**
  - `"Phase 1 - Foundation"`
  - `"Phase 2 - AI Features"`
  - `"Phase 3 - Integration"`
  - `"Phase 4 - Testing & Quality"`
  - `"Phase 5 - Production Deployment"`
  - `"Phase 6 - Versioning & Summary"`
  - `"Deployment Complete!"`

## Example Configurations

### Spec-Driven Mode (Red AI)

```json
{
  "appName": "red-ai",
  "mode": "spec-driven",
  "specId": "001-red-seal-ai",
  "appType": "Red AI",
  "backend": ["REST API", "WebSockets", "Background tasks"],
  "database": ["Multi-tenant", "Vector search", "Realtime", "File storage"],
  "auth": ["Email/password", "OAuth providers"],
  "aiArchitecture": {
    "claudeAgentSDK": true,
    "mcpServers": ["supabase", "memory", "filesystem"],
    "mem0": true,
    "vercelAISDK": true
  },
  "phase": 2,
  "phase0Complete": true,
  "phase1Complete": true,
  "phase2Complete": false,
  "timestamp": "2025-10-31T12:00:00Z",
  "completedAt": "2025-10-31T12:45:00Z",
  "nextPhase": "Phase 2 - AI Features"
}
```

### Interactive Mode (Chatbot)

```json
{
  "appName": "my-chatbot",
  "mode": "interactive",
  "appType": "Chatbot",
  "backend": ["REST API"],
  "database": ["Realtime"],
  "auth": ["Email/password", "Magic link"],
  "aiArchitecture": {
    "claudeAgentSDK": false,
    "mcpServers": ["supabase"],
    "mem0": true,
    "vercelAISDK": true
  },
  "phase": 1,
  "phase0Complete": true,
  "phase1Complete": true,
  "timestamp": "2025-10-31T14:00:00Z",
  "completedAt": "2025-10-31T14:20:00Z",
  "nextPhase": "Phase 2 - AI Features"
}
```

### Complete Deployment (All Phases Done)

```json
{
  "appName": "red-ai",
  "mode": "spec-driven",
  "specId": "001-red-seal-ai",
  "appType": "Red AI",
  "backend": ["REST API", "WebSockets", "Background tasks"],
  "database": ["Multi-tenant", "Vector search", "Realtime", "File storage"],
  "auth": ["Email/password", "OAuth providers"],
  "aiArchitecture": {
    "claudeAgentSDK": true,
    "mcpServers": ["supabase", "memory", "filesystem"],
    "mem0": true,
    "vercelAISDK": true
  },
  "phase": 6,
  "phase0Complete": true,
  "phase1Complete": true,
  "phase2Complete": true,
  "phase3Complete": true,
  "phase4Complete": true,
  "phase5Complete": true,
  "phase6Complete": true,
  "allPhasesComplete": true,
  "testsPassedNewman": true,
  "testsPassedPlaywright": true,
  "securityPassed": true,
  "deployed": true,
  "frontendUrl": "https://red-ai.vercel.app",
  "backendUrl": "https://red-ai-backend.fly.dev",
  "deploymentTimestamp": "2025-10-31T15:30:00Z",
  "validationPassed": true,
  "timestamp": "2025-10-31T12:00:00Z",
  "completedAt": "2025-10-31T15:45:00Z",
  "nextPhase": "Deployment Complete!"
}
```

## Usage Patterns

### Creating the Config (Phase 1)

**Spec-Driven Mode:**
```bash
# Phase 1 detects specs/ directory
# Parses spec.md and plan.md
# Auto-fills configuration

cat > .ai-stack-config.json << 'EOF'
{
  "appName": "red-ai",
  "mode": "spec-driven",
  "specId": "001-red-seal-ai",
  "appType": "Red AI",
  "backend": ["REST API", "WebSockets"],
  "database": ["Multi-tenant", "Vector search"],
  "auth": ["Email/password", "OAuth providers"],
  "aiArchitecture": {
    "claudeAgentSDK": true,
    "mcpServers": ["supabase", "memory", "filesystem"],
    "mem0": true,
    "vercelAISDK": true
  },
  "phase": 1,
  "phase0Complete": true,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

**Interactive Mode:**
```bash
# Phase 1 asks questions via AskUserQuestion
# Fills configuration from answers

cat > .ai-stack-config.json << 'EOF'
{
  "appName": "my-chatbot",
  "mode": "interactive",
  "appType": "[from answer]",
  "backend": ["[from answer]"],
  "database": ["[from answer]"],
  "auth": ["[from answer]"],
  "aiArchitecture": {
    "claudeAgentSDK": "[from answer]",
    "mcpServers": ["[from answer]"],
    "mem0": "[from answer]",
    "vercelAISDK": "[from answer]"
  },
  "phase": 1,
  "phase0Complete": true,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

### Reading the Config

**Load in Commands:**
```markdown
Phase 1: Load State

Actions:
- Check config exists:
  !{bash test -f .ai-stack-config.json && echo "Found" || echo "Not found"}
- Load config:
  @.ai-stack-config.json
- Verify phase1Complete is true
- Extract appName and features
```

**Bash Script:**
```bash
# Check if config exists
if [ ! -f .ai-stack-config.json ]; then
  echo "❌ Error: .ai-stack-config.json not found"
  exit 1
fi

# Load values using jq
APP_NAME=$(jq -r '.appName' .ai-stack-config.json)
MODE=$(jq -r '.mode' .ai-stack-config.json)
PHASE=$(jq -r '.phase' .ai-stack-config.json)
```

### Updating the Config

**Mark Phase Complete:**
```bash
# Update phase number and mark complete
jq '.phase = 2 | .phase2Complete = true | .completedAt = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' \
  .ai-stack-config.json > .ai-stack-config.tmp && \
  mv .ai-stack-config.tmp .ai-stack-config.json
```

**Add Deployment Info:**
```bash
# Add deployment URLs
jq '.deployed = true | .frontendUrl = "https://red-ai.vercel.app" | .backendUrl = "https://red-ai-backend.fly.dev" | .deploymentTimestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' \
  .ai-stack-config.json > .ai-stack-config.tmp && \
  mv .ai-stack-config.tmp .ai-stack-config.json
```

### Validation Gates

**Before Phase 2:**
```bash
# Verify Phase 1 is complete
if ! jq -e '.phase1Complete == true' .ai-stack-config.json >/dev/null 2>&1; then
  echo "❌ Error: Phase 1 not complete. Run Phase 1 first."
  exit 1
fi
```

**Before Phase 5 (Deployment):**
```bash
# Verify all tests passed
if ! jq -e '.testsPassedNewman == true and .testsPassedPlaywright == true and .securityPassed == true' \
  .ai-stack-config.json >/dev/null 2>&1; then
  echo "❌ Error: Tests must pass before deployment"
  exit 1
fi
```

## Resumption Pattern

The `/ai-tech-stack-1:resume` command uses this config to continue from the last completed phase:

```bash
# Load state
PHASE=$(jq -r '.phase' .ai-stack-config.json)

# Determine what to run next
if [ "$PHASE" -eq 1 ]; then
  echo "Resuming from Phase 2 - AI Features"
  /ai-tech-stack-1:build-full-stack-phase-2
elif [ "$PHASE" -eq 2 ]; then
  echo "Resuming from Phase 3 - Integration"
  /ai-tech-stack-1:build-full-stack-phase-3
# ... etc
fi
```

## File Lifecycle

```
Phase 0: Dev Lifecycle Foundation
  └─ No config yet (specs/ detection happens here)

Phase 1: Foundation
  ├─ Creates .ai-stack-config.json
  ├─ Sets mode (spec-driven or interactive)
  ├─ Fills user configuration
  ├─ Sets phase = 1
  └─ Sets phase0Complete = true, phase1Complete = true

Phase 2: AI Features
  ├─ Reads .ai-stack-config.json
  ├─ Verifies phase1Complete = true
  ├─ Updates phase = 2
  └─ Sets phase2Complete = true

Phase 3: Integration
  ├─ Reads .ai-stack-config.json
  ├─ Verifies phase2Complete = true
  ├─ Updates phase = 3
  └─ Sets phase3Complete = true

Phase 4: Testing & Quality
  ├─ Reads .ai-stack-config.json
  ├─ Verifies phase3Complete = true
  ├─ Updates phase = 4
  ├─ Sets testsPassedNewman, testsPassedPlaywright, securityPassed
  └─ Sets phase4Complete = true

Phase 5: Production Deployment
  ├─ Reads .ai-stack-config.json
  ├─ Verifies all tests passed
  ├─ Updates phase = 5
  ├─ Sets deployed = true
  ├─ Sets frontendUrl, backendUrl, deploymentTimestamp
  ├─ Sets validationPassed = true
  └─ Sets phase5Complete = true

Phase 6: Versioning & Summary
  ├─ Reads .ai-stack-config.json
  ├─ Verifies phase5Complete = true
  ├─ Updates phase = 6
  ├─ Sets allPhasesComplete = true
  └─ Sets phase6Complete = true
```

## Troubleshooting

### Config File Missing
```bash
Error: .ai-stack-config.json not found
Solution: Run Phase 1 first to create the config
```

### Invalid JSON
```bash
Error: parse error in .ai-stack-config.json
Solution: Validate JSON syntax with `jq . .ai-stack-config.json`
```

### Phase Not Complete
```bash
Error: Phase 1 not complete
Solution: Verify phase1Complete = true before running Phase 2
```

### Mode Detection Issues
```bash
Issue: Spec-driven mode not detecting specs
Solution: Ensure specs/ directory has spec.md or plan.md files
```

## Best Practices

1. **Never manually edit** - Let commands update the config
2. **Always validate** - Use `jq . .ai-stack-config.json` to verify JSON is valid
3. **Check before proceeding** - Verify previous phase complete before running next
4. **Backup before major changes** - Copy config before risky operations
5. **Use resumption** - If context becomes large, use `/ai-tech-stack-1:resume`

## Related Files

- `PHASE-1-SUMMARY.md` - Phase 1 completion summary
- `PHASE-2-SUMMARY.md` - Phase 2 completion summary
- `DEPLOYMENT-COMPLETE.md` - Final deployment summary
- `ENVIRONMENT.md` - Environment variables documentation
- `VALIDATION-REPORT.md` - Validation results

## Version History

- **v1.0.0** - Initial schema (6 phases)
- **v1.1.0** - Added Phase 0 (Dev lifecycle foundation)
- **v1.2.0** - Standardized on `.ai-stack-config.json` (removed `.deployment-config.json`)
