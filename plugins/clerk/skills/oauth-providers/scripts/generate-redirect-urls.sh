#!/usr/bin/env bash

# generate-redirect-urls.sh - Generate OAuth redirect URLs for all environments
# Usage: ./generate-redirect-urls.sh <provider>
#        ./generate-redirect-urls.sh --all
#        ./generate-redirect-urls.sh <provider> --export

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored messages
print_info() {
  echo -e "${BLUE}[INFO]${NC} $1" >&2
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to detect project domains
detect_domains() {
  local dev_domain="http://localhost:3000"
  local prod_domain=""
  local clerk_domain=""

  # Check .env for domains
  if [[ -f ".env" ]]; then
    if grep -q "NEXT_PUBLIC_APP_URL" .env; then
      prod_domain=$(grep "NEXT_PUBLIC_APP_URL" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    fi
    if grep -q "CLERK_FRONTEND_API" .env; then
      clerk_domain=$(grep "CLERK_FRONTEND_API" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    fi
  fi

  # Check vercel.json for domain
  if [[ -f "vercel.json" ]] && command -v jq &> /dev/null; then
    local vercel_domain=$(jq -r '.alias // empty' vercel.json 2>/dev/null || echo "")
    if [[ -n "$vercel_domain" ]]; then
      prod_domain="https://$vercel_domain"
    fi
  fi

  # Output detected domains
  echo "$dev_domain|${prod_domain:-https://yourdomain.com}|${clerk_domain:-https://your-clerk-domain.clerk.accounts.dev}"
}

# Function to generate redirect URLs for a provider
generate_urls() {
  local provider="$1"
  local export_mode="${2:-false}"

  # Detect domains
  IFS='|' read -r dev_domain prod_domain clerk_domain <<< "$(detect_domains)"

  local provider_upper=$(echo "$provider" | tr '[:lower:]' '[:upper:]')

  if [[ "$export_mode" == "true" ]]; then
    # Export mode - output environment variables
    echo "# $provider OAuth Redirect URLs"
    echo "# Generated: $(date)"
    echo ""
    echo "# Development"
    echo "${provider_upper}_REDIRECT_URI_DEV=$dev_domain/api/auth/callback/$provider"
    echo ""
    echo "# Production"
    echo "${provider_upper}_REDIRECT_URI_PROD=$prod_domain/api/auth/callback/$provider"
    echo ""
    echo "# Clerk Default Callback"
    echo "${provider_upper}_CLERK_CALLBACK=$clerk_domain/v1/oauth_callback"
    echo ""
  else
    # Display mode - show URLs with instructions
    print_info "Redirect URLs for $provider"
    echo ""
    echo "Add these URLs to your $provider OAuth application:"
    echo ""
    echo "Development:"
    echo "  $dev_domain/api/auth/callback/$provider"
    echo ""
    echo "Production:"
    echo "  $prod_domain/api/auth/callback/$provider"
    echo ""
    echo "Clerk Default:"
    echo "  $clerk_domain/v1/oauth_callback"
    echo ""
    echo "---"
    echo ""
  fi
}

# Function to get configured providers
get_configured_providers() {
  local providers=()

  # Check .clerk/providers directory
  if [[ -d ".clerk/providers" ]]; then
    for config_file in .clerk/providers/*-config.json; do
      if [[ -f "$config_file" ]]; then
        local provider=$(basename "$config_file" -config.json)
        providers+=("$provider")
      fi
    done
  fi

  # Check .env for provider credentials
  if [[ -f ".env" ]]; then
    while IFS= read -r line; do
      if [[ "$line" =~ ^([A-Z]+)_CLIENT_ID= ]]; then
        local provider=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')
        if [[ ! " ${providers[*]} " =~ " ${provider} " ]]; then
          providers+=("$provider")
        fi
      fi
    done < .env
  fi

  echo "${providers[@]}"
}

# Function to generate URLs for all providers
generate_all_urls() {
  local export_mode="${1:-false}"

  local providers=($(get_configured_providers))

  if [[ ${#providers[@]} -eq 0 ]]; then
    print_error "No configured providers found"
    print_info "Run 'bash scripts/setup-provider.sh <provider>' first"
    exit 1
  fi

  if [[ "$export_mode" == "true" ]]; then
    echo "# OAuth Redirect URLs - All Providers"
    echo "# Generated: $(date)"
    echo ""
    for provider in "${providers[@]}"; do
      generate_urls "$provider" true
    done
  else
    print_info "Generating redirect URLs for all configured providers"
    echo ""
    for provider in "${providers[@]}"; do
      generate_urls "$provider" false
    done
    print_success "All redirect URLs generated"
  fi
}

# Function to display usage
usage() {
  cat << EOF
Usage: $0 <provider> [--export]
       $0 --all [--export]

Generate OAuth redirect URLs for Clerk providers.

Options:
  <provider>     Generate URLs for specific provider (google, github, etc.)
  --all          Generate URLs for all configured providers
  --export       Export as environment variables (suitable for .env file)

Examples:
  # Display redirect URLs for Google
  $0 google

  # Export Google redirect URLs to .env file
  $0 google --export >> .env.oauth

  # Display all configured provider URLs
  $0 --all

  # Export all provider URLs
  $0 --all --export > .env.oauth
EOF
}

# Main execution
main() {
  if [ $# -eq 0 ]; then
    usage
    exit 1
  fi

  local provider=""
  local export_mode=false
  local all_providers=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        all_providers=true
        shift
        ;;
      --export)
        export_mode=true
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        provider="$1"
        shift
        ;;
    esac
  done

  # Generate URLs
  if [[ "$all_providers" == true ]]; then
    generate_all_urls "$export_mode"
  elif [[ -n "$provider" ]]; then
    generate_urls "$provider" "$export_mode"
  else
    print_error "Provider name required"
    usage
    exit 1
  fi
}

# Run main function
main "$@"
