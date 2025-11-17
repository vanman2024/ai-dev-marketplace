#!/usr/bin/env bash

# setup-provider.sh - Configure OAuth provider for Clerk
# Usage: ./setup-provider.sh <provider> [provider2] [provider3] ...
#        ./setup-provider.sh --interactive

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SKILL_DIR/templates"

# Supported providers
SUPPORTED_PROVIDERS=(
  "google" "github" "discord" "apple" "microsoft" "facebook"
  "linkedin" "twitter" "gitlab" "bitbucket" "dropbox" "notion"
  "slack" "linear" "coinbase" "tiktok" "twitch" "hubspot"
)

# Function to print colored messages
print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate provider
validate_provider() {
  local provider="$1"
  for supported in "${SUPPORTED_PROVIDERS[@]}"; do
    if [[ "$provider" == "$supported" ]]; then
      return 0
    fi
  done
  return 1
}

# Function to check dependencies
check_dependencies() {
  local missing_deps=()

  if ! command -v jq &> /dev/null; then
    missing_deps+=("jq")
  fi

  if [ ${#missing_deps[@]} -ne 0 ]; then
    print_error "Missing required dependencies: ${missing_deps[*]}"
    print_info "Install with: sudo apt-get install ${missing_deps[*]}"
    exit 1
  fi
}

# Function to detect Clerk configuration
detect_clerk_config() {
  local clerk_found=false

  # Check for Clerk environment variables
  if [[ -f ".env" ]] && grep -q "CLERK_" .env; then
    clerk_found=true
    print_success "Found Clerk configuration in .env"
  fi

  # Check for package.json with Clerk dependencies
  if [[ -f "package.json" ]] && grep -q "@clerk" package.json; then
    clerk_found=true
    print_success "Found Clerk packages in package.json"
  fi

  if [[ "$clerk_found" == false ]]; then
    print_warning "No Clerk configuration detected"
    print_info "Make sure you have Clerk set up in your project"
  fi
}

# Function to generate provider configuration
generate_provider_config() {
  local provider="$1"
  local provider_upper=$(echo "$provider" | tr '[:lower:]' '[:upper:]')
  local output_dir="${2:-.clerk/providers}"

  print_info "Generating configuration for $provider..."

  # Create output directory
  mkdir -p "$output_dir"

  # Generate configuration file
  local config_file="$output_dir/${provider}-config.json"

  cat > "$config_file" <<EOF
{
  "provider": "$provider",
  "enabled": true,
  "clientId": "\${${provider_upper}_CLIENT_ID}",
  "clientSecret": "\${${provider_upper}_CLIENT_SECRET}",
  "redirectUri": "\${${provider_upper}_REDIRECT_URI}",
  "scopes": $(get_default_scopes "$provider"),
  "options": $(get_provider_options "$provider")
}
EOF

  print_success "Created configuration: $config_file"

  # Generate environment variables template
  local env_file="$output_dir/${provider}.env.example"

  cat > "$env_file" <<EOF
# $provider OAuth Configuration
# DO NOT commit actual credentials - use placeholders only

# Client credentials from $provider developer console
${provider_upper}_CLIENT_ID=${provider}_dev_your_client_id_here
${provider_upper}_CLIENT_SECRET=${provider}_dev_your_client_secret_here

# Redirect URI (update with your domain)
${provider_upper}_REDIRECT_URI=http://localhost:3000/api/auth/callback/$provider

# Production redirect URI
# ${provider_upper}_REDIRECT_URI=https://yourdomain.com/api/auth/callback/$provider
EOF

  print_success "Created environment template: $env_file"

  # Copy provider-specific template if exists
  if [[ -d "$TEMPLATES_DIR/$provider" ]]; then
    print_info "Copying provider templates..."
    cp -r "$TEMPLATES_DIR/$provider"/* "$output_dir/" 2>/dev/null || true
  fi
}

# Function to get default scopes for provider
get_default_scopes() {
  local provider="$1"

  case "$provider" in
    google)
      echo '["profile", "email", "openid"]'
      ;;
    github)
      echo '["read:user", "user:email"]'
      ;;
    discord)
      echo '["identify", "email"]'
      ;;
    microsoft)
      echo '["openid", "profile", "email", "User.Read"]'
      ;;
    apple)
      echo '["name", "email"]'
      ;;
    facebook)
      echo '["email", "public_profile"]'
      ;;
    linkedin)
      echo '["r_liteprofile", "r_emailaddress"]'
      ;;
    twitter)
      echo '["users.read", "tweet.read"]'
      ;;
    gitlab)
      echo '["read_user", "email"]'
      ;;
    slack)
      echo '["identity.basic", "identity.email"]'
      ;;
    *)
      echo '["profile", "email"]'
      ;;
  esac
}

# Function to get provider-specific options
get_provider_options() {
  local provider="$1"

  case "$provider" in
    google)
      echo '{"accessType": "offline", "prompt": "consent"}'
      ;;
    github)
      echo '{"allowSignup": true}'
      ;;
    discord)
      echo '{"permissions": "0"}'
      ;;
    microsoft)
      echo '{"tenant": "common"}'
      ;;
    apple)
      echo '{"responseMode": "form_post"}'
      ;;
    *)
      echo '{}'
      ;;
  esac
}

# Function to generate setup instructions
generate_setup_instructions() {
  local provider="$1"
  local output_dir="${2:-.clerk/providers}"
  local instructions_file="$output_dir/${provider}-SETUP.md"

  cat > "$instructions_file" <<EOF
# $provider OAuth Setup Instructions

## Step 1: Create OAuth Application

$(get_provider_setup_step1 "$provider")

## Step 2: Configure Redirect URIs

Add the following redirect URIs in your $provider OAuth application:

**Development:**
\`\`\`
http://localhost:3000/api/auth/callback/$provider
\`\`\`

**Production:**
\`\`\`
https://yourdomain.com/api/auth/callback/$provider
\`\`\`

**Clerk Default:**
\`\`\`
https://your-clerk-domain.clerk.accounts.dev/v1/oauth_callback
\`\`\`

## Step 3: Obtain Credentials

1. Copy the Client ID
2. Generate/copy the Client Secret
3. Save both credentials securely

## Step 4: Configure Clerk

1. Navigate to Clerk Dashboard
2. Go to User & Authentication > Social Connections
3. Enable $provider provider
4. Paste Client ID and Client Secret
5. Save configuration

## Step 5: Update Environment Variables

Add to your \`.env\` file (DO NOT commit):

\`\`\`bash
$(cat "$output_dir/${provider}.env.example")
\`\`\`

## Step 6: Test OAuth Flow

Run the test script to verify configuration:

\`\`\`bash
bash scripts/test-oauth-flow.sh $provider
\`\`\`

## Required Scopes

$(get_scope_descriptions "$provider")

## Troubleshooting

$(get_troubleshooting_tips "$provider")

---

**Provider:** $provider
**Documentation:** $(get_provider_docs_url "$provider")
EOF

  print_success "Created setup instructions: $instructions_file"
}

# Function to get provider setup step 1
get_provider_setup_step1() {
  local provider="$1"

  case "$provider" in
    google)
      echo "1. Navigate to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Go to Credentials > Create Credentials > OAuth 2.0 Client ID
5. Configure OAuth consent screen
6. Select Web application type"
      ;;
    github)
      echo "1. Navigate to [GitHub Settings](https://github.com/settings/developers)
2. Click Developer Settings > OAuth Apps
3. Click New OAuth App
4. Fill in application details
5. Set Homepage URL to your application URL"
      ;;
    discord)
      echo "1. Navigate to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click New Application
3. Go to OAuth2 section
4. Add redirect URIs
5. Copy Client ID and generate Client Secret"
      ;;
    microsoft)
      echo "1. Navigate to [Azure Portal](https://portal.azure.com/)
2. Go to Azure Active Directory > App registrations
3. Click New registration
4. Configure platform settings (Web)
5. Add redirect URIs
6. Go to Certificates & secrets > New client secret"
      ;;
    apple)
      echo "1. Navigate to [Apple Developer Portal](https://developer.apple.com/)
2. Go to Certificates, Identifiers & Profiles
3. Create App ID with Sign in with Apple capability
4. Create Service ID
5. Configure domains and redirect URLs
6. Create private key for authentication"
      ;;
    *)
      echo "1. Navigate to $provider developer console
2. Create new OAuth application
3. Configure application settings
4. Add redirect URIs
5. Generate client credentials"
      ;;
  esac
}

# Function to get scope descriptions
get_scope_descriptions() {
  local provider="$1"

  case "$provider" in
    google)
      echo "- \`profile\`: User profile information
- \`email\`: Email address
- \`openid\`: OpenID Connect authentication"
      ;;
    github)
      echo "- \`read:user\`: Read user profile data
- \`user:email\`: Access email addresses"
      ;;
    discord)
      echo "- \`identify\`: User identity information
- \`email\`: Email address
- \`guilds\`: Server list (optional)"
      ;;
    *)
      echo "Default scopes for user profile and email access"
      ;;
  esac
}

# Function to get troubleshooting tips
get_troubleshooting_tips() {
  local provider="$1"

  echo "**Redirect URI Mismatch:**
- Verify exact URL match in $provider console
- Check for trailing slashes
- Validate protocol (http vs https)

**Invalid Credentials:**
- Verify Client ID and Secret are correct
- Check for whitespace in credentials
- Ensure credentials match environment

**Authorization Failed:**
- Verify scopes are supported
- Check provider API version
- Request app review if needed"
}

# Function to get provider documentation URL
get_provider_docs_url() {
  local provider="$1"

  case "$provider" in
    google)
      echo "https://developers.google.com/identity/protocols/oauth2"
      ;;
    github)
      echo "https://docs.github.com/en/developers/apps/building-oauth-apps"
      ;;
    discord)
      echo "https://discord.com/developers/docs/topics/oauth2"
      ;;
    microsoft)
      echo "https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow"
      ;;
    apple)
      echo "https://developer.apple.com/sign-in-with-apple/"
      ;;
    *)
      echo "https://clerk.com/docs"
      ;;
  esac
}

# Function for interactive setup
interactive_setup() {
  print_info "Interactive OAuth Provider Setup"
  echo ""
  echo "Supported providers:"
  for i in "${!SUPPORTED_PROVIDERS[@]}"; do
    printf "  %2d. %s\n" $((i+1)) "${SUPPORTED_PROVIDERS[$i]}"
  done
  echo ""

  read -p "Enter provider number (or 'all' for all providers): " selection

  if [[ "$selection" == "all" ]]; then
    for provider in "${SUPPORTED_PROVIDERS[@]}"; do
      setup_provider "$provider"
    done
  elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#SUPPORTED_PROVIDERS[@]}" ]; then
    local provider="${SUPPORTED_PROVIDERS[$((selection-1))]}"
    setup_provider "$provider"
  else
    print_error "Invalid selection"
    exit 1
  fi
}

# Function to setup a provider
setup_provider() {
  local provider="$1"

  print_info "Setting up $provider OAuth provider..."
  echo ""

  # Generate configuration
  generate_provider_config "$provider"

  # Generate setup instructions
  generate_setup_instructions "$provider"

  echo ""
  print_success "$provider setup complete!"
  print_info "Next steps:"
  echo "  1. Read setup instructions: .clerk/providers/${provider}-SETUP.md"
  echo "  2. Configure OAuth app in $provider developer console"
  echo "  3. Add credentials to .env file"
  echo "  4. Test flow: bash scripts/test-oauth-flow.sh $provider"
  echo ""
}

# Main execution
main() {
  print_info "Clerk OAuth Provider Setup"
  echo ""

  # Check dependencies
  check_dependencies

  # Detect Clerk configuration
  detect_clerk_config
  echo ""

  # Parse arguments
  if [ $# -eq 0 ] || [[ "$1" == "--interactive" ]]; then
    interactive_setup
  else
    # Setup each specified provider
    for provider in "$@"; do
      if validate_provider "$provider"; then
        setup_provider "$provider"
      else
        print_error "Unsupported provider: $provider"
        print_info "Supported providers: ${SUPPORTED_PROVIDERS[*]}"
        exit 1
      fi
    done
  fi

  print_success "All providers configured successfully!"
}

# Run main function
main "$@"
