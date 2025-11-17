#!/usr/bin/env bash

# test-oauth-flow.sh - Test OAuth provider configuration and flows
# Usage: ./test-oauth-flow.sh <provider>
#        ./test-oauth-flow.sh --all
#        ./test-oauth-flow.sh <provider> --report

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test results
declare -A test_results

# Function to print colored messages
print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
  echo -e "${RED}[✗]${NC} $1"
}

# Function to test provider configuration
test_configuration() {
  local provider="$1"
  local provider_upper=$(echo "$provider" | tr '[:lower:]' '[:upper:]')
  local passed=0
  local failed=0

  print_info "Testing $provider configuration..."

  # Test 1: Check environment variables
  if [[ -f ".env" ]]; then
    if grep -q "${provider_upper}_CLIENT_ID" .env && \
       grep -q "${provider_upper}_CLIENT_SECRET" .env; then
      print_success "Environment variables configured"
      ((passed++))
    else
      print_error "Missing environment variables"
      print_info "Required: ${provider_upper}_CLIENT_ID, ${provider_upper}_CLIENT_SECRET"
      ((failed++))
    fi
  else
    print_error ".env file not found"
    ((failed++))
  fi

  # Test 2: Check provider config file
  if [[ -f ".clerk/providers/${provider}-config.json" ]]; then
    if command -v jq &> /dev/null; then
      local is_enabled=$(jq -r '.enabled' ".clerk/providers/${provider}-config.json")
      if [[ "$is_enabled" == "true" ]]; then
        print_success "Provider configuration file valid"
        ((passed++))
      else
        print_warning "Provider is disabled in config"
        ((failed++))
      fi
    else
      print_success "Provider configuration file exists"
      ((passed++))
    fi
  else
    print_error "Provider configuration file not found"
    print_info "Run: bash scripts/setup-provider.sh $provider"
    ((failed++))
  fi

  # Test 3: Check Clerk configuration
  if [[ -f ".env" ]] && grep -q "CLERK_PUBLISHABLE_KEY" .env && \
     grep -q "CLERK_SECRET_KEY" .env; then
    print_success "Clerk credentials configured"
    ((passed++))
  else
    print_error "Missing Clerk credentials"
    print_info "Required: CLERK_PUBLISHABLE_KEY, CLERK_SECRET_KEY"
    ((failed++))
  fi

  # Test 4: Check redirect URI configuration
  if [[ -f ".env" ]] && grep -q "${provider_upper}_REDIRECT_URI" .env; then
    local redirect_uri=$(grep "${provider_upper}_REDIRECT_URI" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    if [[ "$redirect_uri" =~ ^https?:// ]]; then
      print_success "Redirect URI configured: $redirect_uri"
      ((passed++))
    else
      print_warning "Invalid redirect URI format"
      ((failed++))
    fi
  else
    print_warning "Redirect URI not configured (using default)"
    ((passed++))
  fi

  # Store results
  test_results["$provider"]="$passed/$((passed + failed))"

  echo ""
  if [[ $failed -eq 0 ]]; then
    print_success "$provider configuration: ALL TESTS PASSED ($passed/$((passed + failed)))"
    return 0
  else
    print_error "$provider configuration: SOME TESTS FAILED ($passed/$((passed + failed)))"
    return 1
  fi
}

# Function to test OAuth flow
test_oauth_flow() {
  local provider="$1"
  local provider_upper=$(echo "$provider" | tr '[:lower:]' '[:upper:]')

  print_info "Testing $provider OAuth flow..."

  # Load environment variables
  if [[ -f ".env" ]]; then
    set -a
    source .env
    set +a
  fi

  # Get credentials
  local client_id_var="${provider_upper}_CLIENT_ID"
  local client_key_var="${provider_upper}_CLIENT_SECRET"
  local redirect_uri_var="${provider_upper}_REDIRECT_URI"

  local client_id="${!client_id_var:-}"
  local client_key="${!client_key_var:-}"
  local redirect_uri="${!redirect_uri_var:-http://localhost:3000/api/auth/callback/$provider}"

  # Validate credentials are not placeholders
  if [[ -z "$client_id" ]] || [[ "$client_id" =~ your_.*_here ]]; then
    print_error "Client ID not configured or using placeholder"
    print_info "Update $client_id_var in .env with actual credentials"
    return 1
  fi

  # Check if oauth key is placeholder or empty
  if [[ -z "$client_key" ]] || [[ "$client_key" =~ your_.*_here ]]; then
    print_error "OAuth credentials not configured or using placeholder"
    print_info "Update $client_key_var in .env with actual credentials"
    return 1
  fi

  print_success "Credentials validated (not placeholders)"

  # Test authorization URL generation
  local auth_url=$(generate_auth_url "$provider" "$client_id" "$redirect_uri")
  if [[ -n "$auth_url" ]]; then
    print_success "Authorization URL generated"
    print_info "URL: $auth_url"
  else
    print_error "Failed to generate authorization URL"
    return 1
  fi

  # Test redirect URI accessibility
  if [[ "$redirect_uri" =~ ^http://localhost ]]; then
    print_warning "Redirect URI is localhost - manual browser test required"
  else
    if curl -s -o /dev/null -w "%{http_code}" "$redirect_uri" | grep -q "200\|404"; then
      print_success "Redirect URI is accessible"
    else
      print_warning "Redirect URI may not be accessible"
    fi
  fi

  echo ""
  print_success "$provider OAuth flow: TESTS PASSED"
  return 0
}

# Function to generate authorization URL
generate_auth_url() {
  local provider="$1"
  local client_id="$2"
  local redirect_uri="$3"

  case "$provider" in
    google)
      echo "https://accounts.google.com/o/oauth2/v2/auth?client_id=$client_id&redirect_uri=$(urlencode "$redirect_uri")&response_type=code&scope=profile%20email"
      ;;
    github)
      echo "https://github.com/login/oauth/authorize?client_id=$client_id&redirect_uri=$(urlencode "$redirect_uri")&scope=read:user%20user:email"
      ;;
    discord)
      echo "https://discord.com/api/oauth2/authorize?client_id=$client_id&redirect_uri=$(urlencode "$redirect_uri")&response_type=code&scope=identify%20email"
      ;;
    microsoft)
      echo "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=$client_id&redirect_uri=$(urlencode "$redirect_uri")&response_type=code&scope=openid%20profile%20email"
      ;;
    facebook)
      echo "https://www.facebook.com/v12.0/dialog/oauth?client_id=$client_id&redirect_uri=$(urlencode "$redirect_uri")&scope=email,public_profile"
      ;;
    linkedin)
      echo "https://www.linkedin.com/oauth/v2/authorization?client_id=$client_id&redirect_uri=$(urlencode "$redirect_uri")&response_type=code&scope=r_liteprofile%20r_emailaddress"
      ;;
    twitter)
      echo "https://twitter.com/i/oauth2/authorize?client_id=$client_id&redirect_uri=$(urlencode "$redirect_uri")&response_type=code&scope=users.read%20tweet.read"
      ;;
    *)
      echo ""
      ;;
  esac
}

# Function to URL encode
urlencode() {
  local string="$1"
  echo "$string" | jq -sRr @uri
}

# Function to generate test report
generate_report() {
  local output_file="oauth-test-report.md"

  cat > "$output_file" <<EOF
# OAuth Provider Test Report

Generated: $(date)

## Summary

EOF

  for provider in "${!test_results[@]}"; do
    echo "- **$provider**: ${test_results[$provider]} tests passed" >> "$output_file"
  done

  cat >> "$output_file" <<EOF

## Configuration Checklist

### Environment Variables

Verify all provider credentials are configured in \`.env\`:

$(for provider in "${!test_results[@]}"; do
    provider_upper=$(echo "$provider" | tr '[:lower:]' '[:upper:]')
    echo "- [ ] ${provider_upper}_CLIENT_ID"
    echo "- [ ] ${provider_upper}_CLIENT_SECRET"
    echo "- [ ] ${provider_upper}_REDIRECT_URI"
  done)

### Clerk Dashboard

Verify providers are enabled in Clerk Dashboard:

$(for provider in "${!test_results[@]}"; do
    echo "- [ ] $provider OAuth provider enabled"
  done)

### Provider Consoles

Verify redirect URIs are configured in each provider's console:

$(for provider in "${!test_results[@]}"; do
    echo "- [ ] $provider: Redirect URIs added"
  done)

## Next Steps

1. Fix any failed tests
2. Update Clerk Dashboard configuration
3. Verify redirect URIs in provider consoles
4. Test authentication flow in browser
5. Monitor Clerk logs for authentication events

---

**Report:** $output_file
EOF

  print_success "Test report generated: $output_file"
}

# Function to test all providers
test_all_providers() {
  local generate_report_flag="${1:-false}"

  # Get configured providers
  local providers=()
  if [[ -d ".clerk/providers" ]]; then
    for config_file in .clerk/providers/*-config.json; do
      if [[ -f "$config_file" ]]; then
        local provider=$(basename "$config_file" -config.json)
        providers+=("$provider")
      fi
    done
  fi

  if [[ ${#providers[@]} -eq 0 ]]; then
    print_error "No configured providers found"
    print_info "Run: bash scripts/setup-provider.sh <provider>"
    exit 1
  fi

  print_info "Testing ${#providers[@]} configured providers..."
  echo ""

  for provider in "${providers[@]}"; do
    test_configuration "$provider"
    test_oauth_flow "$provider" || true
    echo ""
  done

  if [[ "$generate_report_flag" == "true" ]]; then
    generate_report
  fi

  print_success "All provider tests complete"
}

# Function to display usage
usage() {
  cat << EOF
Usage: $0 <provider>
       $0 --all [--report]

Test OAuth provider configuration and flows.

Options:
  <provider>     Test specific provider (google, github, etc.)
  --all          Test all configured providers
  --report       Generate test report (use with --all)

Examples:
  # Test Google OAuth
  $0 google

  # Test all providers
  $0 --all

  # Test all and generate report
  $0 --all --report
EOF
}

# Main execution
main() {
  if [ $# -eq 0 ]; then
    usage
    exit 1
  fi

  local provider=""
  local all_providers=false
  local generate_report_flag=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        all_providers=true
        shift
        ;;
      --report)
        generate_report_flag=true
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

  # Run tests
  if [[ "$all_providers" == true ]]; then
    test_all_providers "$generate_report_flag"
  elif [[ -n "$provider" ]]; then
    test_configuration "$provider"
    echo ""
    test_oauth_flow "$provider"
  else
    print_error "Provider name required"
    usage
    exit 1
  fi
}

# Run main function
main "$@"
