#!/bin/bash

# setup-oauth-provider.sh - Configure OAuth provider for Supabase authentication
# Usage: ./setup-oauth-provider.sh <provider>
# Example: ./setup-oauth-provider.sh google

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates/oauth-providers"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Supported providers
SUPPORTED_PROVIDERS=("google" "github" "discord" "facebook" "apple" "twitter" "linkedin" "slack")

print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

show_usage() {
    echo "Usage: $0 <provider>"
    echo ""
    echo "Supported providers:"
    for provider in "${SUPPORTED_PROVIDERS[@]}"; do
        echo "  - $provider"
    done
    echo ""
    echo "Example:"
    echo "  $0 google"
    exit 1
}

check_dependencies() {
    local missing_deps=()

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Install with: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
}

check_env_vars() {
    local missing_vars=()

    if [ -z "${SUPABASE_URL:-}" ]; then
        missing_vars+=("SUPABASE_URL")
    fi

    if [ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
        missing_vars+=("SUPABASE_SERVICE_ROLE_KEY")
    fi

    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_warning "Missing environment variables: ${missing_vars[*]}"
        print_info "These are required for automated configuration"
        print_info "You can still proceed with manual setup"
        echo ""
    fi
}

get_provider_config() {
    local provider=$1
    local config_file="$TEMPLATES_DIR/${provider}-oauth-config.json"

    if [ ! -f "$config_file" ]; then
        print_error "Configuration template not found for provider: $provider"
        print_info "Available templates:"
        ls -1 "$TEMPLATES_DIR" | grep -o '^[^-]*' | sort -u
        exit 1
    fi

    cat "$config_file"
}

show_provider_instructions() {
    local provider=$1

    echo ""
    print_info "Setting up OAuth for: $provider"
    echo ""

    case $provider in
        google)
            cat <<EOF
${BLUE}Google OAuth Setup Instructions:${NC}

1. Go to Google Cloud Console: https://console.cloud.google.com/
2. Create a new project or select existing project
3. Navigate to "APIs & Services" > "Credentials"
4. Click "Create Credentials" > "OAuth client ID"
5. Select "Web application" as application type
6. Add authorized redirect URIs:
   ${GREEN}https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback${NC}
   ${GREEN}http://localhost:3000/auth/callback${NC} (for local development)

7. Copy the Client ID and Client Secret

Required Scopes:
   - email
   - profile
   - openid

EOF
            ;;
        github)
            cat <<EOF
${BLUE}GitHub OAuth Setup Instructions:${NC}

1. Go to GitHub Settings: https://github.com/settings/developers
2. Click "New OAuth App" (or "New GitHub App" for advanced features)
3. Fill in application details:
   - Application name: Your App Name
   - Homepage URL: https://yourapp.com
   - Authorization callback URL:
     ${GREEN}https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback${NC}

4. Click "Register application"
5. Generate a new client secret
6. Copy Client ID and Client Secret

Default Scopes:
   - user:email
   - read:user

EOF
            ;;
        discord)
            cat <<EOF
${BLUE}Discord OAuth Setup Instructions:${NC}

1. Go to Discord Developer Portal: https://discord.com/developers/applications
2. Click "New Application"
3. Give your application a name
4. Navigate to "OAuth2" section
5. Add redirect URIs:
   ${GREEN}https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback${NC}
   ${GREEN}http://localhost:3000/auth/callback${NC}

6. Copy Client ID and Client Secret from OAuth2 page

Required Scopes:
   - identify
   - email

EOF
            ;;
        facebook)
            cat <<EOF
${BLUE}Facebook OAuth Setup Instructions:${NC}

1. Go to Facebook Developers: https://developers.facebook.com/
2. Create a new app or use existing app
3. Add "Facebook Login" product
4. Configure OAuth redirect URIs:
   ${GREEN}https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback${NC}

5. Copy App ID (Client ID) and App Secret

Required Permissions:
   - email
   - public_profile

EOF
            ;;
        *)
            print_info "Manual setup required for: $provider"
            print_info "Check template file: $TEMPLATES_DIR/${provider}-oauth-config.json"
            ;;
    esac
}

prompt_credentials() {
    local provider=$1

    echo ""
    print_info "Enter OAuth credentials for $provider:"
    echo ""

    read -p "Client ID: " client_id
    read -s -p "Client Secret: " client_secret
    echo ""

    if [ -z "$client_id" ] || [ -z "$client_secret" ]; then
        print_error "Client ID and Secret are required"
        exit 1
    fi

    echo "$client_id|$client_secret"
}

save_to_env_file() {
    local provider=$1
    local client_id=$2
    local client_secret=$3
    local env_file=".env.local"

    # Convert provider name to uppercase for env var
    local provider_upper=$(echo "$provider" | tr '[:lower:]' '[:upper:]')

    # Create .env.local if it doesn't exist
    touch "$env_file"

    # Remove existing entries for this provider
    sed -i "/^${provider_upper}_CLIENT_ID=/d" "$env_file"
    sed -i "/^${provider_upper}_CLIENT_SECRET=/d" "$env_file"

    # Add new entries
    echo "${provider_upper}_CLIENT_ID=$client_id" >> "$env_file"
    echo "${provider_upper}_CLIENT_SECRET=$client_secret" >> "$env_file"

    print_success "Credentials saved to $env_file"
    print_warning "Add $env_file to .gitignore to prevent committing secrets"
}

configure_supabase_provider() {
    local provider=$1
    local client_id=$2
    local client_secret=$3

    if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
        print_warning "Cannot configure Supabase automatically (missing env vars)"
        print_info "Manually add credentials in Supabase Dashboard:"
        print_info "  Authentication > Providers > $provider"
        return
    fi

    print_info "Configuring $provider in Supabase..."

    # Extract project ref from Supabase URL
    local project_ref=$(echo "$SUPABASE_URL" | sed 's|https://\([^.]*\).*|\1|')

    # Configuration payload
    local payload=$(cat <<EOF
{
  "enabled": true,
  "client_id": "$client_id",
  "secret": "$client_secret"
}
EOF
)

    # Use Supabase Management API to configure provider
    local response=$(curl -s -X PUT \
        "${SUPABASE_URL}/auth/v1/admin/config/providers/${provider}" \
        -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>&1)

    if echo "$response" | grep -q "error"; then
        print_warning "Automatic configuration failed"
        print_info "Please configure manually in Supabase Dashboard"
    else
        print_success "$provider OAuth configured in Supabase"
    fi
}

show_next_steps() {
    local provider=$1

    echo ""
    print_success "OAuth setup complete for $provider!"
    echo ""
    print_info "Next steps:"
    echo "  1. Test OAuth flow: bash $(dirname "$SCRIPT_DIR")/scripts/test-auth-flow.sh $provider"
    echo "  2. Add auth button to your app:"
    echo ""
    echo "     ${BLUE}// React/Next.js example${NC}"
    echo "     import { createClient } from '@supabase/supabase-js'"
    echo ""
    echo "     const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)"
    echo ""
    echo "     const handleLogin = async () => {"
    echo "       await supabase.auth.signInWithOAuth({"
    echo "         provider: '$provider'"
    echo "       })"
    echo "     }"
    echo ""
    echo "  3. Handle callback in your app (see examples directory)"
    echo ""
}

main() {
    # Check arguments
    if [ $# -eq 0 ]; then
        show_usage
    fi

    local provider=$1

    # Validate provider
    if [[ ! " ${SUPPORTED_PROVIDERS[@]} " =~ " ${provider} " ]]; then
        print_error "Unsupported provider: $provider"
        echo ""
        show_usage
    fi

    # Check dependencies
    check_dependencies

    # Check environment variables
    check_env_vars

    # Show provider-specific instructions
    show_provider_instructions "$provider"

    # Prompt for credentials
    local credentials=$(prompt_credentials "$provider")
    local client_id=$(echo "$credentials" | cut -d'|' -f1)
    local client_secret=$(echo "$credentials" | cut -d'|' -f2)

    # Save to .env.local
    save_to_env_file "$provider" "$client_id" "$client_secret"

    # Configure in Supabase (if possible)
    configure_supabase_provider "$provider" "$client_id" "$client_secret"

    # Show next steps
    show_next_steps "$provider"
}

main "$@"
