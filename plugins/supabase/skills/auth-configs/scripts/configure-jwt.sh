#!/bin/bash

# configure-jwt.sh - Configure JWT settings for Supabase authentication
# Usage: ./configure-jwt.sh [--generate-secret] [--rotate]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

generate_jwt_secret() {
    # Generate cryptographically secure random string
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

show_jwt_config_info() {
    cat <<EOF
${BLUE}JWT Configuration Overview:${NC}

JSON Web Tokens (JWT) are used to authenticate users in your application.
Supabase uses JWTs to manage user sessions and API access.

${YELLOW}Key Concepts:${NC}

1. ${GREEN}JWT Secret${NC}
   - Used to sign and verify tokens
   - Must be kept secret and secure
   - Should be 32+ characters, random, and strong
   - Store in environment variables, NEVER in code

2. ${GREEN}Token Expiration${NC}
   - Access Token: Short-lived (default: 1 hour)
   - Refresh Token: Long-lived (default: 30 days)
   - Shorter = more secure, but more frequent refreshes

3. ${GREEN}Custom Claims${NC}
   - Add user metadata to JWT payload
   - Use for role-based access control (RBAC)
   - Example: { "role": "admin", "plan": "pro" }

4. ${GREEN}Signing Algorithm${NC}
   - Supabase uses HS256 (HMAC with SHA-256)
   - Symmetric algorithm (same secret for sign/verify)

EOF
}

prompt_jwt_settings() {
    echo ""
    print_info "Configure JWT settings:"
    echo ""

    # Access token expiration
    echo "Access token expiration (in seconds):"
    echo "  300 = 5 minutes (high security)"
    echo "  3600 = 1 hour (recommended)"
    echo "  86400 = 24 hours (convenience)"
    read -p "Enter value [3600]: " access_token_exp
    access_token_exp=${access_token_exp:-3600}

    # Refresh token expiration
    echo ""
    echo "Refresh token expiration (in seconds):"
    echo "  604800 = 7 days"
    echo "  2592000 = 30 days (recommended)"
    echo "  7776000 = 90 days"
    read -p "Enter value [2592000]: " refresh_token_exp
    refresh_token_exp=${refresh_token_exp:-2592000}

    # Custom claims
    echo ""
    read -p "Enable custom JWT claims for RBAC? [y/N]: " enable_claims
    enable_claims=${enable_claims:-n}

    echo "$access_token_exp|$refresh_token_exp|$enable_claims"
}

create_jwt_config_file() {
    local access_exp=$1
    local refresh_exp=$2
    local enable_claims=$3
    local jwt_secret=$4

    local config_file="jwt-config.json"

    cat > "$config_file" <<EOF
{
  "jwt": {
    "secret": "$jwt_secret",
    "algorithm": "HS256",
    "expirationTime": {
      "accessToken": $access_exp,
      "refreshToken": $refresh_exp
    },
    "customClaims": $([ "$enable_claims" = "y" ] && echo "true" || echo "false")
  },
  "security": {
    "rotateSecretPeriodically": true,
    "recommendedRotationInterval": "90 days",
    "requireSecureConnection": true,
    "allowedOrigins": [
      "http://localhost:3000",
      "https://yourdomain.com"
    ]
  },
  "notes": {
    "secretManagement": "Store JWT_SECRET in environment variables",
    "expirationNote": "Shorter expiration = more secure but more frequent refreshes",
    "customClaimsInfo": "Add user metadata to JWT for role-based access control"
  }
}
EOF

    print_success "JWT configuration saved to $config_file"
}

save_to_env() {
    local jwt_secret=$1
    local env_file=".env.local"

    touch "$env_file"

    # Remove existing JWT_SECRET if present
    sed -i '/^JWT_SECRET=/d' "$env_file"
    sed -i '/^SUPABASE_JWT_SECRET=/d' "$env_file"

    # Add new secret
    echo "JWT_SECRET=$jwt_secret" >> "$env_file"
    echo "SUPABASE_JWT_SECRET=$jwt_secret" >> "$env_file"

    print_success "JWT secret saved to $env_file"
    print_warning "Ensure $env_file is in .gitignore"

    # Check if in git
    if [ -d .git ] && git check-ignore "$env_file" > /dev/null 2>&1; then
        print_success "$env_file is already in .gitignore"
    else
        print_warning "Add $env_file to .gitignore to prevent committing secrets"
        echo ""
        echo "Run: echo '.env.local' >> .gitignore"
    fi
}

show_custom_claims_example() {
    cat <<EOF

${BLUE}Custom JWT Claims Example:${NC}

Custom claims allow you to add user metadata to JWT tokens for authorization.

${GREEN}1. Database Function to Add Claims:${NC}

-- Add this to your Supabase SQL editor
CREATE OR REPLACE FUNCTION custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS \$\$
DECLARE
  claims jsonb;
  user_role text;
BEGIN
  -- Fetch user role from profiles table
  SELECT role INTO user_role
  FROM public.profiles
  WHERE id = (event->>'user_id')::uuid;

  -- Add custom claim to JWT
  claims := event->'claims';
  claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));

  event := jsonb_set(event, '{claims}', claims);

  RETURN event;
END;
\$\$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION custom_access_token_hook TO supabase_auth_admin;

${GREEN}2. Configure Hook in Supabase Dashboard:${NC}

   Settings > Auth > JWT Settings > Access Token Hook
   Add: custom_access_token_hook

${GREEN}3. Access Claims in Your App:${NC}

   // JavaScript/TypeScript
   const { data: { session } } = await supabase.auth.getSession()
   const userRole = session?.user?.user_metadata?.user_role

   // Use in RLS policies
   -- SQL
   CREATE POLICY "Users can only see their own data"
   ON documents
   FOR SELECT
   USING (auth.jwt() ->> 'user_role' = 'admin' OR user_id = auth.uid());

${GREEN}4. Example Claims for AI Application:${NC}

   {
     "user_id": "abc-123",
     "email": "user@example.com",
     "role": "pro",
     "plan": "premium",
     "ai_model_access": ["gpt-4", "claude-3"],
     "rate_limit": 1000,
     "features": ["rag", "vision", "code"]
   }

EOF
}

show_security_best_practices() {
    cat <<EOF

${BLUE}JWT Security Best Practices:${NC}

${GREEN}1. Secret Management${NC}
   ✓ Use strong random secrets (32+ characters)
   ✓ Store in environment variables, never in code
   ✓ Rotate secrets every 90 days
   ✓ Use different secrets for dev/staging/prod

${GREEN}2. Token Expiration${NC}
   ✓ Short access token lifetime (1 hour recommended)
   ✓ Longer refresh token lifetime (30 days)
   ✓ Implement automatic token refresh
   ✓ Revoke refresh tokens on logout

${GREEN}3. Claims Validation${NC}
   ✓ Validate claims on backend, not just frontend
   ✓ Use row-level security (RLS) policies
   ✓ Don't store sensitive data in JWT
   ✓ Verify token signature before trusting claims

${GREEN}4. Transport Security${NC}
   ✓ Always use HTTPS in production
   ✓ Set secure cookie flags (httpOnly, secure, sameSite)
   ✓ Validate redirect URLs
   ✓ Implement CSRF protection

${RED}5. Common Mistakes to Avoid${NC}
   ✗ Hardcoding JWT secrets
   ✗ Storing secrets in frontend code
   ✗ Using weak or predictable secrets
   ✗ Trusting JWT claims without verification
   ✗ Not rotating secrets regularly

EOF
}

main() {
    local generate_secret=false
    local rotate=false

    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --generate-secret)
                generate_secret=true
                ;;
            --rotate)
                rotate=true
                generate_secret=true
                ;;
            --help)
                echo "Usage: $0 [--generate-secret] [--rotate]"
                echo ""
                echo "Options:"
                echo "  --generate-secret  Generate new JWT secret"
                echo "  --rotate          Rotate existing JWT secret"
                exit 0
                ;;
        esac
    done

    echo ""
    print_info "JWT Configuration Tool for Supabase"
    echo ""

    # Show overview
    show_jwt_config_info

    # Generate or use existing secret
    local jwt_secret=""
    if [ "$generate_secret" = true ]; then
        jwt_secret=$(generate_jwt_secret)
        print_success "Generated new JWT secret"

        if [ "$rotate" = true ]; then
            print_warning "Rotating JWT secret will invalidate all existing tokens"
            print_warning "Users will need to re-authenticate"
            read -p "Continue? [y/N]: " confirm
            if [ "$confirm" != "y" ]; then
                print_info "Rotation cancelled"
                exit 0
            fi
        fi
    else
        # Check if secret exists in env
        if [ -n "${JWT_SECRET:-}" ]; then
            print_info "Found existing JWT_SECRET in environment"
            read -p "Use existing secret? [Y/n]: " use_existing
            if [ "$use_existing" != "n" ]; then
                jwt_secret="$JWT_SECRET"
            else
                jwt_secret=$(generate_jwt_secret)
                print_success "Generated new JWT secret"
            fi
        else
            jwt_secret=$(generate_jwt_secret)
            print_success "Generated new JWT secret"
        fi
    fi

    # Prompt for JWT settings
    local settings=$(prompt_jwt_settings)
    local access_exp=$(echo "$settings" | cut -d'|' -f1)
    local refresh_exp=$(echo "$settings" | cut -d'|' -f2)
    local enable_claims=$(echo "$settings" | cut -d'|' -f3)

    # Create config file
    create_jwt_config_file "$access_exp" "$refresh_exp" "$enable_claims" "$jwt_secret"

    # Save to environment
    save_to_env "$jwt_secret"

    # Show custom claims example if enabled
    if [ "$enable_claims" = "y" ]; then
        show_custom_claims_example
    fi

    # Show security best practices
    show_security_best_practices

    # Summary
    echo ""
    print_success "JWT configuration complete!"
    echo ""
    print_info "Configuration Summary:"
    echo "  Access Token Expiration: ${access_exp}s ($(($access_exp / 3600)) hours)"
    echo "  Refresh Token Expiration: ${refresh_exp}s ($(($refresh_exp / 86400)) days)"
    echo "  Custom Claims: $([ "$enable_claims" = "y" ] && echo "Enabled" || echo "Disabled")"
    echo "  JWT Secret: Saved to .env.local"
    echo ""
    print_info "Next steps:"
    echo "  1. Update Supabase project settings with new JWT secret"
    echo "  2. Configure custom claims function (if enabled)"
    echo "  3. Test authentication flow: bash $(dirname "$SCRIPT_DIR")/scripts/test-auth-flow.sh"
    echo ""
}

main "$@"
