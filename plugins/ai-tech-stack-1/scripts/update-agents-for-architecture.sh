#!/bin/bash

# Systematic update of all agents to read architecture documentation
# This script adds architecture reading to agents based on their domain

set -euo pipefail

MARKETPLACE="/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins"

# Define which agents need which architecture docs
declare -A AGENT_ARCHITECTURE_MAP

# NextJS Frontend Agents → frontend.md, data.md
AGENT_ARCHITECTURE_MAP["nextjs-frontend/agents/page-generator-agent.md"]="frontend.md data.md"
AGENT_ARCHITECTURE_MAP["nextjs-frontend/agents/component-builder-agent.md"]="frontend.md"
AGENT_ARCHITECTURE_MAP["nextjs-frontend/agents/ai-sdk-integration-agent.md"]="ai.md frontend.md"
AGENT_ARCHITECTURE_MAP["nextjs-frontend/agents/supabase-integration-agent.md"]="data.md security.md"
AGENT_ARCHITECTURE_MAP["nextjs-frontend/agents/design-enforcer-agent.md"]="frontend.md"

# FastAPI Backend Agents → backend.md, data.md, ai.md
AGENT_ARCHITECTURE_MAP["fastapi-backend/agents/endpoint-generator-agent.md"]="backend.md data.md"
AGENT_ARCHITECTURE_MAP["fastapi-backend/agents/database-architect-agent.md"]="data.md backend.md"
AGENT_ARCHITECTURE_MAP["fastapi-backend/agents/deployment-architect-agent.md"]="infrastructure.md backend.md"
AGENT_ARCHITECTURE_MAP["fastapi-backend/agents/fastapi-setup-agent.md"]="backend.md data.md ai.md"

# Supabase Agents → data.md, security.md
AGENT_ARCHITECTURE_MAP["supabase/agents/supabase-architect.md"]="data.md"
AGENT_ARCHITECTURE_MAP["supabase/agents/supabase-security-specialist.md"]="security.md data.md"
AGENT_ARCHITECTURE_MAP["supabase/agents/supabase-ai-specialist.md"]="ai.md data.md"

# Vercel AI SDK Agents → ai.md
AGENT_ARCHITECTURE_MAP["vercel-ai-sdk/agents/vercel-ai-data-agent.md"]="ai.md data.md"
AGENT_ARCHITECTURE_MAP["vercel-ai-sdk/agents/vercel-ai-ui-agent.md"]="ai.md frontend.md"
AGENT_ARCHITECTURE_MAP["vercel-ai-sdk/agents/vercel-ai-advanced-agent.md"]="ai.md"

# Claude Agent SDK Agents → ai.md
AGENT_ARCHITECTURE_MAP["claude-agent-sdk/agents/claude-agent-builder.md"]="ai.md backend.md"

# Mem0 Agents → ai.md, data.md
AGENT_ARCHITECTURE_MAP["mem0/agents/mem0-integrator.md"]="ai.md data.md"
AGENT_ARCHITECTURE_MAP["mem0/agents/mem0-memory-architect.md"]="ai.md data.md"

echo "🔧 Updating agents to read architecture documentation..."
echo ""

update_count=0

for agent_path in "${!AGENT_ARCHITECTURE_MAP[@]}"; do
    full_path="$MARKETPLACE/$agent_path"

    if [ ! -f "$full_path" ]; then
        echo "⚠️  Skipping $agent_path (file not found)"
        continue
    fi

    arch_docs="${AGENT_ARCHITECTURE_MAP[$agent_path]}"

    # Check if already updated
    if grep -q "## Architecture & Documentation Discovery" "$full_path" 2>/dev/null; then
        echo "✓  Already updated: $agent_path"
        continue
    fi

    # Find where to insert (look for "## Project Approach" or first "###")
    if grep -q "^## Project Approach" "$full_path"; then
        insert_marker="^## Project Approach"
    elif grep -q "^### 1\." "$full_path"; then
        insert_marker="^### 1\."
    else
        echo "⚠️  No insertion point found: $agent_path"
        continue
    fi

    # Build architecture reading section
    arch_section="## Architecture \\& Documentation Discovery\n\nBefore building, check for project architecture documentation:\n\n"

    for doc in $arch_docs; do
        case $doc in
            frontend.md)
                arch_section+="- Read: docs/architecture/frontend.md (if exists - contains pages, components, routing, UI requirements)\n"
                ;;
            backend.md)
                arch_section+="- Read: docs/architecture/backend.md (if exists - contains API endpoints, services, routes)\n"
                ;;
            data.md)
                arch_section+="- Read: docs/architecture/data.md (if exists - contains database schema, models, relationships)\n"
                ;;
            ai.md)
                arch_section+="- Read: docs/architecture/ai.md (if exists - contains AI agents, tools, prompts, memory architecture)\n"
                ;;
            security.md)
                arch_section+="- Read: docs/architecture/security.md (if exists - contains auth requirements, RLS policies, security rules)\n"
                ;;
            infrastructure.md)
                arch_section+="- Read: docs/architecture/infrastructure.md (if exists - contains deployment, scaling, monitoring)\n"
                ;;
        esac
    done

    arch_section+="- Extract requirements specific to this task from architecture\n"
    arch_section+="- If architecture docs exist: Build from specifications\n"
    arch_section+="- If no architecture docs: Use defaults and best practices\n\n"

    # Create backup
    cp "$full_path" "${full_path}.bak"

    # Insert the section
    sed -i "/$insert_marker/i\\$arch_section" "$full_path"

    echo "✅ Updated: $agent_path"
    echo "   Architecture docs: $arch_docs"
    ((update_count++))

done

echo ""
echo "🎉 Updated $update_count agents"
echo ""
echo "Backup files created with .bak extension"
echo "Review changes and remove backups when satisfied"
