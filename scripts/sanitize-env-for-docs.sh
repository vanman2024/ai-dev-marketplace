#!/usr/bin/env bash
# Script to sanitize environment variables for documentation
#
# Usage:
#   source scripts/sanitize-env-for-docs.sh
#   echo $SANITIZED_GOOGLE_API_KEY  # Output: "your_google_api_key_here"
#
# Or use in doc generation:
#   SANITIZED_ENV=$(bash scripts/sanitize-env-for-docs.sh)

set -euo pipefail

# Function to sanitize a key by replacing it with a placeholder
sanitize_key() {
  local key_name="$1"
  local key_value="${!key_name:-}"
  local placeholder="your_${key_name,,}_here"

  if [[ -n "$key_value" ]]; then
    echo "$placeholder"
  else
    echo "$placeholder"
  fi
}

# Export sanitized versions of all API keys
echo "# Sanitized Environment Variables for Documentation"
echo "# NEVER use real credentials in documentation!"
echo ""

# Google API Keys
if [[ -n "${GOOGLE_API_KEY:-}" ]]; then
  echo "export SANITIZED_GOOGLE_API_KEY='your_google_api_key_here'"
fi

if [[ -n "${GEMINI_API_KEY:-}" ]]; then
  echo "export SANITIZED_GEMINI_API_KEY='your_gemini_api_key_here'"
fi

# Supabase Keys
if [[ -n "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "export SANITIZED_SUPABASE_ANON_KEY='your_supabase_anon_key_here'"
fi

if [[ -n "${SUPABASE_SERVICE_KEY:-}" ]]; then
  echo "export SANITIZED_SUPABASE_SERVICE_KEY='your_supabase_service_key_here'"
fi

# Clerk Keys
if [[ -n "${CLERK_SECRET_KEY:-}" ]]; then
  echo "export SANITIZED_CLERK_SECRET_KEY='sk_test_your_clerk_secret_key_here'"
fi

# Stripe Keys
if [[ -n "${STRIPE_SECRET_KEY:-}" ]]; then
  echo "export SANITIZED_STRIPE_SECRET_KEY='sk_test_your_stripe_secret_key_here'"
fi

# Airtable Keys
if [[ -n "${AIRTABLE_API_KEY:-}" ]]; then
  echo "export SANITIZED_AIRTABLE_API_KEY='your_airtable_api_key_here'"
fi

# Generic API Keys
for var in RESEND_API_KEY GROQ_API_KEY MEM0_API_KEY NGROK_AUTHTOKEN UNSPLASH_ACCESS_KEY; do
  if [[ -n "${!var:-}" ]]; then
    placeholder="your_${var,,}_here"
    echo "export SANITIZED_${var}='$placeholder'"
  fi
done

echo ""
echo "# Usage in documentation:"
echo "# Instead of: GOOGLE_API_KEY=\$GOOGLE_API_KEY"
echo "# Use:        GOOGLE_API_KEY=\$SANITIZED_GOOGLE_API_KEY"
