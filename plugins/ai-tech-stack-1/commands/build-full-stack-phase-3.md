---
description: "Phase 3: Integration - Wire services, add UI components, deployment configs"
argument-hint: none
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

Goal: Wire services together + add UI components + deployment configs.

Phase 1: Load State
- Load .ai-stack-config.json
- Verify phase2Complete is true
- Extract appName
- Create Phase 3 todo list

Phase 2: Task Orchestration
- Execute immediately: !{slashcommand /iterate:tasks phase-3-integration}
- After completion, save execution plan to .ai-stack-phase-3-tasks.json

Phase 3: Add UI Components
- Execute immediately: !{slashcommand /nextjs-frontend:add-component button}
- After completion, execute immediately: !{slashcommand /nextjs-frontend:add-component input}
- After completion, execute immediately: !{slashcommand /nextjs-frontend:add-component card}
- After completion, execute immediately: !{slashcommand /nextjs-frontend:search-components "chat"}

Phase 4: Setup Payments (Stripe)
- Execute immediately: !{slashcommand /payments:init}
- After completion, verify: !{bash grep -q "STRIPE" ".env.example" && echo "✅ Stripe configured" || echo "❌ Missing Stripe config"}

Phase 5: Wire Frontend to Backend
- Create API client: !{bash mkdir -p "$APP_NAME/lib" && cat > "$APP_NAME/lib/api-client.ts" << 'EOF'
export const api = {
  baseUrl: process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000',
  async fetch(endpoint: string, options?: RequestInit) {
    const res = await fetch(`${this.baseUrl}${endpoint}`, options);
    return res.json();
  }
};
EOF
}
- Add CORS to backend: !{bash cd "$APP_NAME-backend" && pip install fastapi-cors}

Phase 6: Deployment Configs
- Execute immediately: !{slashcommand /deployment:prepare}
- After completion, verify deployment readiness

Phase 7: Refactor Integration Code
- Execute immediately: !{slashcommand /iterate:refactor src/integration}
- After completion, verify code quality

Phase 8: Validation
- Execute immediately: !{slashcommand /planning:analyze-project}
- After completion, execute immediately: !{slashcommand /iterate:sync phase-3-complete}

Phase 9: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 3 | .phase3Complete = true | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display: "✅ Phase 3 Complete - Integration done"

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 3
