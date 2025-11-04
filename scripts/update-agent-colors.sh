#!/bin/bash

# Agent Color Update Script
# Updates agent colors based on domain/plugin type

# Color scheme based on docs/frameworks/claude/agents/agent-color-standard.md:
# 🟢 Green - Database Operations (Supabase, database-related)
# 🟡 Yellow - RAG Operations (RAG pipeline, ML training)
# 🔵 Blue - Builders/Generators
# 🟣 Purple - Architects/Designers
# 🟠 Orange - Deployers/Publishers
# 🔴 Red - Fixers/Adjusters
# 🩷 Pink - Testers/Runners
# 🔵 Cyan - Analyzers/Scanners

MARKETPLACE_DIR="/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins"

echo "=============================================="
echo "Agent Color Update - Domain-Based Assignment"
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

    # Check if color field exists
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

echo "🟢 GREEN - Database Operations (Supabase)"
echo "=========================================="
for agent in "$MARKETPLACE_DIR/supabase/agents"/*.md; do
    update_agent_color "$agent" "green" "DATABASE"
done
echo ""

echo "🟡 YELLOW - RAG Operations"
echo "=========================="
for agent in "$MARKETPLACE_DIR/rag-pipeline/agents"/*.md; do
    update_agent_color "$agent" "yellow" "RAG"
done
echo ""

echo "🟡 YELLOW - ML Training (RAG-like operations)"
echo "============================================="
for agent in "$MARKETPLACE_DIR/ml-training/agents"/*.md; do
    update_agent_color "$agent" "yellow" "ML/RAG"
done
echo ""

echo "🔵 CYAN - Memory Operations (Mem0)"
echo "==================================="
for agent in "$MARKETPLACE_DIR/mem0/agents"/*.md; do
    update_agent_color "$agent" "cyan" "MEMORY"
done
echo ""

echo "🟣 PURPLE - API/LLM Integration"
echo "==============================="
for agent in "$MARKETPLACE_DIR/openrouter/agents"/*.md; do
    update_agent_color "$agent" "purple" "LLM-API"
done
echo ""

echo "🔵 BLUE - Frontend Builders"
echo "==========================="
for agent in "$MARKETPLACE_DIR/nextjs-frontend/agents"/*.md; do
    update_agent_color "$agent" "blue" "FRONTEND"
done
for agent in "$MARKETPLACE_DIR/website-builder/agents"/*.md; do
    update_agent_color "$agent" "blue" "FRONTEND"
done
echo ""

echo "🟠 ORANGE - Backend API Builders"
echo "================================="
for agent in "$MARKETPLACE_DIR/fastapi-backend/agents"/*.md; do
    update_agent_color "$agent" "orange" "BACKEND"
done
echo ""

echo "🟣 PURPLE - AI SDK Integration"
echo "==============================="
for agent in "$MARKETPLACE_DIR/vercel-ai-sdk/agents"/*.md; do
    update_agent_color "$agent" "purple" "AI-SDK"
done
for agent in "$MARKETPLACE_DIR/claude-agent-sdk/agents"/*.md; do
    update_agent_color "$agent" "purple" "AI-SDK"
done
echo ""

echo "🩷 PINK - Voice/Audio Operations"
echo "================================="
for agent in "$MARKETPLACE_DIR/elevenlabs/agents"/*.md; do
    update_agent_color "$agent" "pink" "VOICE"
done
echo ""

echo "🔵 CYAN - Documentation/Analysis"
echo "================================="
for agent in "$MARKETPLACE_DIR/plugin-docs-loader/agents"/*.md; do
    update_agent_color "$agent" "cyan" "DOCS"
done
echo ""

echo "=============================================="
echo "✅ Agent color update complete!"
echo "=============================================="
