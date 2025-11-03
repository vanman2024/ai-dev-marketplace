#!/bin/bash
# Script to add architecture doc loading to all agents
# Usage: ./add-architecture-docs.sh <plugin-name>

set -e

PLUGIN=$1

if [ -z "$PLUGIN" ]; then
  echo "Usage: $0 <plugin-name>"
  echo "Example: $0 supabase"
  exit 1
fi

# Architecture doc mapping by plugin
get_docs_for_plugin() {
  case "$1" in
    openrouter)
      echo "ai.md, ROADMAP.md"
      ;;
    rag-pipeline)
      echo "ai.md, data.md, ROADMAP.md"
      ;;
    elevenlabs)
      echo "ai.md, frontend.md, ROADMAP.md"
      ;;
    supabase)
      echo "data.md, security.md, ROADMAP.md"
      ;;
    vercel-ai-sdk)
      echo "ai.md, frontend.md, ROADMAP.md"
      ;;
    nextjs-frontend)
      echo "frontend.md, data.md, ROADMAP.md"
      ;;
    fastapi-backend)
      echo "backend.md, data.md, ROADMAP.md"
      ;;
    claude-agent-sdk)
      echo "ai.md, ROADMAP.md"
      ;;
    mem0)
      echo "ai.md, data.md, ROADMAP.md"
      ;;
    *)
      echo "ai.md, ROADMAP.md"  # Default fallback
      ;;
  esac
}

# Get doc descriptions
get_doc_descriptions() {
  local plugin=$1
  case "$plugin" in
    supabase)
      cat <<EOF
- Read: docs/architecture/data.md (if exists - database schema, tables, RLS policies, storage)
- Read: docs/architecture/security.md (if exists - authentication, authorization, encryption, compliance)
- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)
EOF
      ;;
    vercel-ai-sdk)
      cat <<EOF
- Read: docs/architecture/ai.md (if exists - AI/ML architecture, model configuration, streaming setup)
- Read: docs/architecture/frontend.md (if exists - Next.js architecture, API routes, component patterns)
- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)
EOF
      ;;
    nextjs-frontend)
      cat <<EOF
- Read: docs/architecture/frontend.md (if exists - pages, components, routing, state management)
- Read: docs/architecture/data.md (if exists - API integration, data fetching, caching)
- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)
EOF
      ;;
    fastapi-backend)
      cat <<EOF
- Read: docs/architecture/backend.md (if exists - API endpoints, services, business logic)
- Read: docs/architecture/data.md (if exists - database models, repositories, migrations)
- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)
EOF
      ;;
    claude-agent-sdk)
      cat <<EOF
- Read: docs/architecture/ai.md (if exists - AI/ML architecture, agent orchestration, tool configuration)
- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)
EOF
      ;;
    mem0)
      cat <<EOF
- Read: docs/architecture/ai.md (if exists - AI/ML architecture, memory configuration, persistence)
- Read: docs/architecture/data.md (if exists - memory storage, vector database, caching)
- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)
EOF
      ;;
    openrouter|rag-pipeline|elevenlabs)
      # Already done
      echo "# Already completed"
      ;;
    *)
      cat <<EOF
- Read: docs/architecture/ai.md (if exists - AI/ML architecture, configuration)
- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)
EOF
      ;;
  esac
}

AGENT_DIR="plugins/$PLUGIN/agents"

if [ ! -d "$AGENT_DIR" ]; then
  echo "Error: Directory $AGENT_DIR not found"
  exit 1
fi

echo "Processing agents in $AGENT_DIR..."
DOCS=$(get_docs_for_plugin "$PLUGIN")
echo "Architecture docs: $DOCS"
echo ""

count=0
for agent in "$AGENT_DIR"/*.md; do
  [ -f "$agent" ] || continue

  # Check if already has architecture section
  if grep -q "### 1. Architecture & Documentation Discovery" "$agent"; then
    echo "⏩ $(basename $agent) - already has architecture section"
    continue
  fi

  # Find "## Project Approach"
  if ! grep -q "^## Project Approach" "$agent"; then
    echo "⚠️  $(basename $agent) - no '## Project Approach' section found"
    continue
  fi

  # Create temp file
  tmpfile=$(mktemp)

  # Process file
  awk '
    /^## Project Approach/ {
      print
      print ""
      print "### 1. Architecture & Documentation Discovery"
      print ""
      print "Before building, check for project architecture documentation:"
      print ""
      while ((getline line < "/tmp/arch_docs.txt") > 0) {
        print line
      }
      close("/tmp/arch_docs.txt")
      print "- Extract requirements from architecture"
      print "- If architecture exists: Build from specifications"
      print "- If no architecture: Use defaults and best practices"
      print ""
      in_project_approach=1
      next
    }
    in_project_approach && /^### 1\./ {
      sub(/^### 1\./, "### 2.")
    }
    in_project_approach && /^### 2\./ && !/^### 2\. Discovery/ {
      sub(/^### 2\./, "### 3.")
    }
    in_project_approach && /^### 3\./ && !/^### 3\. Analysis/ {
      sub(/^### 3\./, "### 4.")
    }
    in_project_approach && /^### 4\./ && !/^### 4\. Planning/ {
      sub(/^### 4\./, "### 5.")
    }
    in_project_approach && /^### 5\./ && !/^### 5\. Implementation/ {
      sub(/^### 5\./, "### 6.")
    }
    { print }
  ' "$agent" > "$tmpfile"

  # Write doc descriptions to temp file for awk
  get_doc_descriptions "$PLUGIN" > /tmp/arch_docs.txt

  # Process again to inject docs
  awk '
    /^## Project Approach/ {
      print
      print ""
      print "### 1. Architecture & Documentation Discovery"
      print ""
      print "Before building, check for project architecture documentation:"
      print ""
      while ((getline line < "/tmp/arch_docs.txt") > 0) {
        print line
      }
      close("/tmp/arch_docs.txt")
      print "- Extract requirements from architecture"
      print "- If architecture exists: Build from specifications"
      print "- If no architecture: Use defaults and best practices"
      print ""
      in_project_approach=1
      next
    }
    in_project_approach && /^### 1\./ && !/^### 1\. Architecture/ {
      sub(/^### 1\./, "### 2.")
    }
    in_project_approach && /^### 2\. Analysis/ {
      sub(/^### 2\./, "### 3.")
    }
    in_project_approach && /^### 3\. Planning/ {
      sub(/^### 3\./, "### 4.")
    }
    in_project_approach && /^### 4\. Implementation/ {
      sub(/^### 4\./, "### 5.")
    }
    in_project_approach && /^### 5\. Verification/ {
      sub(/^### 5\./, "### 6.")
    }
    { print }
  ' "$agent" > "$tmpfile"

  mv "$tmpfile" "$agent"
  count=$((count + 1))
  echo "✓ $(basename $agent)"
done

echo ""
echo "Updated $count agents in $PLUGIN"
