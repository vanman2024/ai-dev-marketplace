#!/bin/bash
# Interactive advisor for choosing the right memory type
# Usage: ./suggest-memory-type.sh "<use_case_description>"

set -e

USE_CASE="${1}"

if [ -z "$USE_CASE" ]; then
    echo "Memory Type Advisor"
    echo "==================="
    echo ""
    echo "Describe your use case, and I'll recommend the appropriate memory type."
    echo ""
    echo "Usage: $0 \"<use_case_description>\""
    echo ""
    echo "Examples:"
    echo "  $0 \"store user's dietary preferences\""
    echo "  $0 \"remember current conversation topic\""
    echo "  $0 \"agent's standard operating procedures\""
    echo ""
    read -p "Enter your use case: " USE_CASE
fi

echo ""
echo "Analyzing use case: $USE_CASE"
echo "================================"
echo ""

# Convert to lowercase for pattern matching
USE_CASE_LOWER=$(echo "$USE_CASE" | tr '[:upper:]' '[:lower:]')

# Pattern matching for recommendations
SUGGESTED_TYPE=""
CONFIDENCE="medium"
REASONING=""

# User memory patterns
if echo "$USE_CASE_LOWER" | grep -qE "user|preference|profile|personal|dietary|birthday|favorite|likes|dislikes|location|language|timezone"; then
    SUGGESTED_TYPE="user"
    CONFIDENCE="high"
    REASONING="This appears to be persistent user-specific information that should be retained across all sessions and agents."

# Agent memory patterns
elif echo "$USE_CASE_LOWER" | grep -qE "agent|capability|behavior|procedure|sop|knowledge|limitation|instruction|protocol|how to|process"; then
    SUGGESTED_TYPE="agent"
    CONFIDENCE="high"
    REASONING="This appears to be agent-specific knowledge or behavior that applies across all users interacting with this agent."

# Session memory patterns
elif echo "$USE_CASE_LOWER" | grep -qE "current|session|conversation|topic|temporary|task|context|discussing|working on|right now"; then
    SUGGESTED_TYPE="session"
    CONFIDENCE="high"
    REASONING="This appears to be temporary context specific to the current conversation or task session."

# Ambiguous cases requiring more analysis
elif echo "$USE_CASE_LOWER" | grep -qE "remember|store|save|keep"; then
    SUGGESTED_TYPE="user"
    CONFIDENCE="low"
    REASONING="The use case mentions storing information, but lacks specificity. If this is long-term personal data, use USER memory. If temporary, use SESSION memory."

# Support/ticket patterns
elif echo "$USE_CASE_LOWER" | grep -qE "ticket|issue|problem|support|question|inquiry"; then
    SUGGESTED_TYPE="session"
    CONFIDENCE="medium"
    REASONING="Support interactions are typically session-scoped. However, if you need to remember resolution patterns, consider promoting important insights to USER memory after resolution."

else
    SUGGESTED_TYPE="user"
    CONFIDENCE="low"
    REASONING="Unable to confidently categorize. Defaulting to USER memory for persistent storage, but please review the decision criteria below."
fi

# Display recommendation
echo "RECOMMENDATION:"
echo "==============="
echo "Suggested Memory Type: ${SUGGESTED_TYPE^^}"
echo "Confidence: $CONFIDENCE"
echo ""
echo "Reasoning:"
echo "$REASONING"
echo ""

# Display characteristics of suggested type
case "$SUGGESTED_TYPE" in
    user)
        echo "USER MEMORY Characteristics:"
        echo "----------------------------"
        echo "✓ Persists indefinitely (or until user deletes)"
        echo "✓ Shared across all agents for this user"
        echo "✓ Best for: preferences, profile data, long-term context"
        echo "✓ Typical volume: 10-50 memories per user"
        echo "✓ Retention: Indefinite"
        echo ""
        echo "Example implementation:"
        echo "  memory.add(\"User prefers dark mode\", user_id=\"alice\")"
        ;;
    agent)
        echo "AGENT MEMORY Characteristics:"
        echo "-----------------------------"
        echo "✓ Shared across all users for this agent"
        echo "✓ Contains agent-specific procedures and knowledge"
        echo "✓ Best for: capabilities, SOPs, learned behaviors"
        echo "✓ Typical volume: 50-200 memories per agent"
        echo "✓ Retention: 90-180 days"
        echo ""
        echo "Example implementation:"
        echo "  memory.add(\"Check order date before refund\", agent_id=\"support_v2\")"
        ;;
    session)
        echo "SESSION MEMORY Characteristics:"
        echo "-------------------------------"
        echo "✓ Temporary, session-scoped context"
        echo "✓ Isolated to specific conversation or task"
        echo "✓ Best for: current topic, task state, working memory"
        echo "✓ Typical volume: 5-20 memories per session"
        echo "✓ Retention: 1-24 hours"
        echo ""
        echo "Example implementation:"
        echo "  memory.add(\"Discussing payment issue\", run_id=\"session_123\")"
        ;;
esac

echo ""
echo "Alternative Considerations:"
echo "---------------------------"

# Suggest alternatives or combinations
case "$SUGGESTED_TYPE" in
    user)
        echo "• If this is temporary context: Consider SESSION memory instead"
        echo "• If this applies to all users: Consider AGENT memory instead"
        echo "• If this should expire: Set retention policy on USER memory"
        ;;
    agent)
        echo "• If this is user-specific: Consider USER memory instead"
        echo "• If this is per-conversation: Consider SESSION memory instead"
        echo "• If agent learns from interactions: Use AGENT memory with versioning"
        ;;
    session)
        echo "• If this should persist long-term: Promote to USER memory after session"
        echo "• If this is common pattern: Extract to AGENT memory"
        echo "• If this is preference: Store in USER memory from the start"
        ;;
esac

echo ""
echo "Decision Flowchart:"
echo "-------------------"
cat <<'EOF'
┌─────────────────────────────────────┐
│ Does this persist across sessions?  │
└────────────┬────────────────────────┘
             │
        Yes──┤──No──> SESSION MEMORY
             │
             ▼
┌─────────────────────────────────────┐
│ Is this user-specific?              │
└────────────┬────────────────────────┘
             │
        Yes──┤──No──> AGENT MEMORY
             │
             ▼
       USER MEMORY
EOF

echo ""
echo "Next Steps:"
echo "-----------"
echo "1. Review the recommendation and reasoning"
echo "2. Consider alternative memory types if confidence is low"
echo "3. Implement using the example code provided"
echo "4. Test with sample data before production"
echo "5. Monitor access patterns and adjust if needed"
echo ""

if [ "$CONFIDENCE" = "low" ]; then
    echo "⚠️  Confidence is LOW. Please review decision criteria carefully."
    echo "   Consider running this analysis with a more specific use case description."
fi
