#!/bin/bash

# Agent Color Update Script - FOLLOWING STANDARD FRAMEWORK
# Based on docs/frameworks/claude/agents/agent-color-standard.md

# Standard Color Scheme:
# 🔵 Blue - Builders/Generators (create, generate, build, scaffold)
# 🟡 Yellow - Validators/Checkers (validate, verify, check, audit)
# 🟢 Green - Integrators/Installers (integrate, install, connect, setup)
# 🟣 Purple - Architects/Designers (design, architect, plan, specify)
# 🟠 Orange - Deployers/Publishers (deploy, publish, release, upload)
# 🔴 Red - Fixers/Adjusters (fix, refactor, adjust, optimize)
# 🩷 Pink - Testers/Runners (test, run, execute, validate)
# 🔵 Cyan - Analyzers/Scanners (analyze, scan, examine, assess)

MARKETPLACE_DIR="/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins"

echo "=============================================="
echo "Agent Color Update - STANDARD FRAMEWORK"
echo "=============================================="
echo ""

# Function to update agent color
update_agent_color() {
    local agent_file="$1"
    local new_color="$2"
    local reason="$3"

    if [ ! -f "$agent_file" ]; then
        return
    fi

    if grep -q "^color:" "$agent_file"; then
        current_color=$(grep "^color:" "$agent_file" | awk '{print $2}')
        if [ "$current_color" != "$new_color" ]; then
            sed -i "s/^color:.*/color: $new_color/" "$agent_file"
            echo "✅ $(basename $agent_file): $current_color → $new_color ($reason)"
        else
            echo "⏭️  $(basename $agent_file): Already $new_color"
        fi
    else
        echo "⚠️  $(basename $agent_file): No color field found"
    fi
}

echo "🔵 BLUE - Builders/Generators"
echo "============================="
# Agents that CREATE/BUILD/GENERATE
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-realtime-builder.md" "blue" "builds realtime"
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-ui-generator.md" "blue" "generates UI"
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-ai-specialist.md" "blue" "builds AI features"
update_agent_color "$MARKETPLACE_DIR/nextjs-frontend/agents/component-builder-agent.md" "blue" "builds components"
update_agent_color "$MARKETPLACE_DIR/nextjs-frontend/agents/page-generator-agent.md" "blue" "generates pages"
update_agent_color "$MARKETPLACE_DIR/nextjs-frontend/agents/nextjs-setup-agent.md" "blue" "builds setup"
update_agent_color "$MARKETPLACE_DIR/website-builder/agents/website-setup.md" "blue" "builds setup"
update_agent_color "$MARKETPLACE_DIR/website-builder/agents/website-content.md" "blue" "builds content"
update_agent_color "$MARKETPLACE_DIR/website-builder/agents/website-ai-generator.md" "blue" "generates AI content"
update_agent_color "$MARKETPLACE_DIR/fastapi-backend/agents/fastapi-setup-agent.md" "blue" "builds setup"
update_agent_color "$MARKETPLACE_DIR/fastapi-backend/agents/endpoint-generator-agent.md" "blue" "generates endpoints"
update_agent_color "$MARKETPLACE_DIR/elevenlabs/agents/elevenlabs-agents-builder.md" "blue" "builds agents"
update_agent_color "$MARKETPLACE_DIR/claude-agent-sdk/agents/claude-agent-setup.md" "blue" "builds setup"
update_agent_color "$MARKETPLACE_DIR/rag-pipeline/agents/document-processor.md" "blue" "processes/builds docs"
update_agent_color "$MARKETPLACE_DIR/rag-pipeline/agents/web-scraper-agent.md" "blue" "builds scrapers"
echo ""

echo "🟡 YELLOW - Validators/Checkers"
echo "================================"
# Agents that VALIDATE/VERIFY/CHECK/AUDIT
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-schema-validator.md" "yellow" "validates schemas"
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-code-reviewer.md" "yellow" "reviews/checks code"
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-security-auditor.md" "yellow" "audits security"
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-validator.md" "yellow" "validates setup"
update_agent_color "$MARKETPLACE_DIR/nextjs-frontend/agents/design-enforcer-agent.md" "yellow" "validates design"
update_agent_color "$MARKETPLACE_DIR/website-builder/agents/website-verifier.md" "yellow" "verifies site"
update_agent_color "$MARKETPLACE_DIR/vercel-ai-sdk/agents/vercel-ai-verifier-js.md" "yellow" "verifies setup"
update_agent_color "$MARKETPLACE_DIR/vercel-ai-sdk/agents/vercel-ai-verifier-py.md" "yellow" "verifies setup"
update_agent_color "$MARKETPLACE_DIR/vercel-ai-sdk/agents/vercel-ai-verifier-ts.md" "yellow" "verifies setup"
update_agent_color "$MARKETPLACE_DIR/claude-agent-sdk/agents/claude-agent-verifier-py.md" "yellow" "verifies setup"
update_agent_color "$MARKETPLACE_DIR/claude-agent-sdk/agents/claude-agent-verifier-ts.md" "yellow" "verifies setup"
update_agent_color "$MARKETPLACE_DIR/mem0/agents/mem0-verifier.md" "yellow" "verifies setup"
echo ""

echo "🟢 GREEN - Integrators/Installers"
echo "=================================="
# Agents that INTEGRATE/INSTALL/CONNECT/SETUP
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-security-specialist.md" "green" "integrates auth"
update_agent_color "$MARKETPLACE_DIR/nextjs-frontend/agents/ai-sdk-integration-agent.md" "green" "integrates AI SDK"
update_agent_color "$MARKETPLACE_DIR/nextjs-frontend/agents/supabase-integration-agent.md" "green" "integrates Supabase"
update_agent_color "$MARKETPLACE_DIR/openrouter/agents/openrouter-setup-agent.md" "green" "integrates OpenRouter"
update_agent_color "$MARKETPLACE_DIR/openrouter/agents/openrouter-vercel-integration-agent.md" "green" "integrates Vercel"
update_agent_color "$MARKETPLACE_DIR/openrouter/agents/openrouter-langchain-agent.md" "green" "integrates LangChain"
update_agent_color "$MARKETPLACE_DIR/elevenlabs/agents/elevenlabs-setup.md" "green" "integrates ElevenLabs"
update_agent_color "$MARKETPLACE_DIR/elevenlabs/agents/elevenlabs-stt-integrator.md" "green" "integrates STT"
update_agent_color "$MARKETPLACE_DIR/elevenlabs/agents/elevenlabs-tts-integrator.md" "green" "integrates TTS"
update_agent_color "$MARKETPLACE_DIR/elevenlabs/agents/elevenlabs-voice-manager.md" "green" "integrates voice"
update_agent_color "$MARKETPLACE_DIR/mem0/agents/mem0-integrator.md" "green" "integrates Mem0"
update_agent_color "$MARKETPLACE_DIR/vercel-ai-sdk/agents/vercel-ai-ui-agent.md" "green" "integrates UI features"
update_agent_color "$MARKETPLACE_DIR/vercel-ai-sdk/agents/vercel-ai-data-agent.md" "green" "integrates data features"
update_agent_color "$MARKETPLACE_DIR/rag-pipeline/agents/langchain-specialist.md" "green" "integrates LangChain"
update_agent_color "$MARKETPLACE_DIR/rag-pipeline/agents/llamaindex-specialist.md" "green" "integrates LlamaIndex"
echo ""

echo "🟣 PURPLE - Architects/Designers"
echo "================================="
# Agents that DESIGN/ARCHITECT/PLAN/SPECIFY
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-architect.md" "purple" "designs schemas"
update_agent_color "$MARKETPLACE_DIR/website-builder/agents/website-architect.md" "purple" "designs architecture"
update_agent_color "$MARKETPLACE_DIR/fastapi-backend/agents/database-architect-agent.md" "purple" "designs database"
update_agent_color "$MARKETPLACE_DIR/fastapi-backend/agents/deployment-architect-agent.md" "purple" "designs deployment"
update_agent_color "$MARKETPLACE_DIR/rag-pipeline/agents/rag-architect.md" "purple" "designs RAG systems"
update_agent_color "$MARKETPLACE_DIR/mem0/agents/mem0-memory-architect.md" "purple" "designs memory"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/ml-architect.md" "purple" "designs ML pipeline"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/training-architect.md" "purple" "designs training"
echo ""

echo "🟠 ORANGE - Deployers/Publishers"
echo "================================="
# Agents that DEPLOY/PUBLISH/RELEASE/UPLOAD
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-migration-applier.md" "orange" "deploys migrations"
update_agent_color "$MARKETPLACE_DIR/rag-pipeline/agents/rag-deployment-agent.md" "orange" "deploys RAG"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/inference-deployer.md" "orange" "deploys inference"
update_agent_color "$MARKETPLACE_DIR/elevenlabs/agents/elevenlabs-production-agent.md" "orange" "deploys to prod"
update_agent_color "$MARKETPLACE_DIR/vercel-ai-sdk/agents/vercel-ai-production-agent.md" "orange" "deploys to prod"
echo ""

echo "🔴 RED - Fixers/Adjusters"
echo "=========================="
# Agents that FIX/REFACTOR/ADJUST/OPTIMIZE
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-performance-analyzer.md" "red" "optimizes performance"
update_agent_color "$MARKETPLACE_DIR/rag-pipeline/agents/retrieval-optimizer.md" "red" "optimizes retrieval"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/cost-optimizer.md" "red" "optimizes cost"
update_agent_color "$MARKETPLACE_DIR/openrouter/agents/openrouter-routing-agent.md" "red" "optimizes routing"
echo ""

echo "🩷 PINK - Testers/Runners"
echo "=========================="
# Agents that TEST/RUN/EXECUTE
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-tester.md" "pink" "runs tests"
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-database-executor.md" "pink" "executes SQL"
update_agent_color "$MARKETPLACE_DIR/rag-pipeline/agents/rag-tester.md" "pink" "runs tests"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/ml-tester.md" "pink" "runs tests"
echo ""

echo "🔵 CYAN - Analyzers/Scanners"
echo "============================="
# Agents that ANALYZE/SCAN/EXAMINE/ASSESS
update_agent_color "$MARKETPLACE_DIR/supabase/agents/supabase-project-manager.md" "cyan" "analyzes projects"
update_agent_color "$MARKETPLACE_DIR/nextjs-frontend/agents/ui-search-agent.md" "cyan" "searches/analyzes UI"
update_agent_color "$MARKETPLACE_DIR/plugin-docs-loader/agents/doc-loader-agent.md" "cyan" "analyzes docs"
update_agent_color "$MARKETPLACE_DIR/rag-pipeline/agents/embedding-specialist.md" "cyan" "analyzes embeddings"
update_agent_color "$MARKETPLACE_DIR/rag-pipeline/agents/vector-db-engineer.md" "cyan" "analyzes vectors"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/data-engineer.md" "cyan" "analyzes data"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/data-specialist.md" "cyan" "analyzes data"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/training-monitor.md" "cyan" "monitors/analyzes"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/distributed-training-specialist.md" "cyan" "analyzes distributed"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/peft-specialist.md" "cyan" "analyzes PEFT"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/lambda-specialist.md" "cyan" "analyzes Lambda"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/modal-specialist.md" "cyan" "analyzes Modal"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/runpod-specialist.md" "cyan" "analyzes RunPod"
update_agent_color "$MARKETPLACE_DIR/ml-training/agents/integration-specialist.md" "cyan" "analyzes integration"
update_agent_color "$MARKETPLACE_DIR/vercel-ai-sdk/agents/vercel-ai-advanced-agent.md" "cyan" "analyzes advanced"
update_agent_color "$MARKETPLACE_DIR/claude-agent-sdk/agents/claude-agent-features.md" "cyan" "analyzes features"
echo ""

echo "=============================================="
echo "✅ Agent color update complete (STANDARD)!"
echo "=============================================="
