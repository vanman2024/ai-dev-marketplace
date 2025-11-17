"""
Flower Authentication Configuration

Provides multiple authentication methods for securing Flower access.
Choose the method that best fits your deployment requirements.

Authentication Methods:
    1. Basic Authentication (username/password)
    2. OAuth2 (Google, GitHub, etc.)
    3. Custom Authentication Provider

Security Best Practices:
    - Never hardcode credentials
    - Use environment variables for secrets
    - Enable HTTPS in production
    - Implement rate limiting
    - Use strong passwords
    - Rotate credentials regularly
"""

import os
from typing import Optional


# ============================================================================
# Method 1: Basic Authentication
# ============================================================================

def get_basic_auth_credentials() -> Optional[str]:
    """
    Get basic authentication credentials from environment.

    Environment Variable:
        FLOWER_BASIC_AUTH: Comma-separated list of username:password pairs
        Example: "admin:admin_password_here,viewer:viewer_password_here"

    Returns:
        Formatted credentials string or None

    Usage:
        # Start Flower with basic auth
        celery -A myapp flower --basic_auth=admin:admin_password_here

        # Or set in environment
        export FLOWER_BASIC_AUTH="admin:admin_password_here"
        celery -A myapp flower
    """
    credentials = os.getenv("FLOWER_BASIC_AUTH")

    if credentials:
        # Validate format
        pairs = credentials.split(",")
        for pair in pairs:
            if ":" not in pair:
                raise ValueError(
                    f"Invalid basic auth format: {pair}. "
                    "Expected format: username:password"
                )

        return credentials

    return None


# ============================================================================
# Method 2: OAuth2 Authentication (Google Example)
# ============================================================================

def get_oauth2_config() -> dict:
    """
    Get OAuth2 configuration for Google authentication.

    Environment Variables:
        FLOWER_OAUTH2_KEY: Google OAuth client ID
        FLOWER_OAUTH2_SECRET: Google OAuth client secret
        FLOWER_OAUTH2_REDIRECT_URI: Redirect URI after authentication
        FLOWER_AUTH_REGEX: Email regex for access control (e.g., .*@company\.com)

    Returns:
        OAuth2 configuration dictionary

    Setup Instructions:
        1. Create OAuth2 credentials in Google Cloud Console
        2. Add authorized redirect URI: http://localhost:5555/login
        3. Set environment variables with credentials
        4. Configure email regex to restrict access

    Usage:
        celery -A myapp flower \\
            --auth=".*@example\.com" \\
            --oauth2_key=your_client_id_here \\
            --oauth2_secret=your_client_secret_here \\
            --oauth2_redirect_uri=http://localhost:5555/login
    """
    config = {
        "oauth2_key": os.getenv("FLOWER_OAUTH2_KEY"),
        "oauth2_secret": os.getenv("FLOWER_OAUTH2_SECRET"),
        "oauth2_redirect_uri": os.getenv(
            "FLOWER_OAUTH2_REDIRECT_URI",
            "http://localhost:5555/login"
        ),
        "auth_regex": os.getenv("FLOWER_AUTH_REGEX", r".*@example\.com"),
    }

    # Validate OAuth2 configuration
    if config["oauth2_key"] and config["oauth2_secret"]:
        if not config["oauth2_redirect_uri"]:
            raise ValueError("FLOWER_OAUTH2_REDIRECT_URI is required for OAuth2")

        return config

    return {}


# ============================================================================
# Method 3: Custom Authentication Provider
# ============================================================================

class CustomAuthProvider:
    """
    Custom authentication provider for Flower.

    Implement your own authentication logic by subclassing this class.
    Useful for integrating with existing authentication systems.

    Example Use Cases:
        - LDAP/Active Directory authentication
        - Database-backed user authentication
        - JWT token validation
        - API key authentication
        - Integration with identity providers (Okta, Auth0)
    """

    def __init__(self):
        """Initialize custom auth provider with configuration."""
        self.allowed_users = self._load_allowed_users()

    def _load_allowed_users(self) -> set:
        """
        Load allowed users from configuration.

        Returns:
            Set of allowed usernames or emails
        """
        # Example: Load from environment variable
        users_str = os.getenv("FLOWER_ALLOWED_USERS", "")
        return set(users_str.split(",")) if users_str else set()

    def authenticate(self, username: str, password: str) -> bool:
        """
        Authenticate user with custom logic.

        Args:
            username: Username or email
            password: User password

        Returns:
            True if authentication successful, False otherwise

        Example Implementation:
            def authenticate(self, username, password):
                # Check against database
                user = db.query(User).filter_by(username=username).first()
                if user and user.check_password(password):
                    return True
                return False
        """
        # Example: Simple whitelist check
        if username in self.allowed_users:
            # In production, verify password against secure storage
            return self._verify_password(username, password)

        return False

    def _verify_password(self, username: str, password: str) -> bool:
        """
        Verify password for authenticated user.

        Args:
            username: Username to verify
            password: Password to check

        Returns:
            True if password is valid

        Implementation:
            - Use bcrypt/argon2 for password hashing
            - Implement rate limiting
            - Log authentication attempts
            - Use constant-time comparison
        """
        # SECURITY: Never implement password verification like this in production!
        # This is a placeholder. Use proper password hashing libraries.

        # Example with environment variable (for testing only):
        expected_password = os.getenv(f"FLOWER_PASSWORD_{username.upper()}")
        return password == expected_password if expected_password else False

    def authorize(self, username: str, resource: str) -> bool:
        """
        Check if user is authorized to access resource.

        Args:
            username: Authenticated username
            resource: Resource being accessed

        Returns:
            True if user is authorized

        Example Use Case:
            - Read-only users can view but not revoke tasks
            - Admin users have full access
            - Team-based access control
        """
        # Example: Role-based access control
        admin_users = os.getenv("FLOWER_ADMIN_USERS", "").split(",")

        if username in admin_users:
            return True  # Admins have full access

        # Regular users can only view
        return resource in ["view_tasks", "view_workers"]


# ============================================================================
# Authentication Configuration Builder
# ============================================================================

def build_flower_auth_args() -> list:
    """
    Build Flower command-line arguments for authentication.

    Returns:
        List of command-line arguments

    Usage:
        from flower_auth import build_flower_auth_args

        auth_args = build_flower_auth_args()
        # ['--basic_auth=admin:password', ...]
    """
    args = []

    # Basic auth
    basic_auth = get_basic_auth_credentials()
    if basic_auth:
        args.extend([f"--basic_auth={basic_auth}"])

    # OAuth2
    oauth_config = get_oauth2_config()
    if oauth_config:
        args.extend([
            f"--auth={oauth_config['auth_regex']}",
            f"--oauth2_key={oauth_config['oauth2_key']}",
            f"--oauth2_secret={oauth_config['oauth2_secret']}",
            f"--oauth2_redirect_uri={oauth_config['oauth2_redirect_uri']}",
        ])

    return args


# ============================================================================
# Configuration Validation
# ============================================================================

def validate_auth_config():
    """
    Validate authentication configuration.

    Raises:
        ValueError: If configuration is invalid or insecure
    """
    basic_auth = get_basic_auth_credentials()
    oauth_config = get_oauth2_config()

    if not basic_auth and not oauth_config:
        print("WARNING: No authentication configured! Flower will be publicly accessible.")
        print("Set FLOWER_BASIC_AUTH or configure OAuth2 to secure access.")

    # Check for insecure passwords
    if basic_auth:
        pairs = basic_auth.split(",")
        for pair in pairs:
            username, password = pair.split(":")
            if len(password) < 8:
                raise ValueError(
                    f"Password for user '{username}' is too short. "
                    "Use at least 8 characters."
                )
            if password in ["password", "admin", "12345678"]:
                raise ValueError(
                    f"Insecure password detected for user '{username}'. "
                    "Use a strong password."
                )


# ============================================================================
# Example Usage
# ============================================================================

if __name__ == "__main__":
    """
    Example: Test authentication configuration
    """
    print("Flower Authentication Configuration")
    print("=" * 50)

    # Validate configuration
    try:
        validate_auth_config()
        print("✓ Authentication configuration is valid")
    except ValueError as e:
        print(f"✗ Configuration error: {e}")
        exit(1)

    # Display configured authentication methods
    if get_basic_auth_credentials():
        print("✓ Basic authentication enabled")

    if get_oauth2_config():
        print("✓ OAuth2 authentication enabled")
        print(f"  Email regex: {get_oauth2_config()['auth_regex']}")

    # Build command-line arguments
    auth_args = build_flower_auth_args()
    if auth_args:
        print("\nFlower auth arguments:")
        for arg in auth_args:
            # Hide sensitive values in output
            if "secret" in arg or "password" in arg:
                key = arg.split("=")[0]
                print(f"  {key}=***")
            else:
                print(f"  {arg}")
    else:
        print("\nWARNING: No authentication arguments configured!")


# ============================================================================
# Environment Variable Template
# ============================================================================

"""
Required Environment Variables:

# Basic Authentication
FLOWER_BASIC_AUTH=admin:your_admin_password_here,viewer:your_viewer_password_here

# OAuth2 Authentication (Google)
FLOWER_OAUTH2_KEY=your_google_client_id_here
FLOWER_OAUTH2_SECRET=your_google_client_secret_here
FLOWER_OAUTH2_REDIRECT_URI=http://localhost:5555/login
FLOWER_AUTH_REGEX=.*@yourcompany\.com

# Custom Authentication
FLOWER_ALLOWED_USERS=user1,user2,admin
FLOWER_PASSWORD_ADMIN=your_admin_password_here
FLOWER_ADMIN_USERS=admin,superuser

Security Notes:
- Never commit .env file with real credentials
- Use strong, unique passwords
- Rotate credentials regularly
- Enable HTTPS in production
- Implement rate limiting
- Monitor authentication attempts
"""
