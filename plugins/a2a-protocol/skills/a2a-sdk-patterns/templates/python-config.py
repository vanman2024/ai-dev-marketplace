# A2A Protocol Python Configuration Example
# IMPORTANT: Never hardcode API keys - always use environment variables

import os
from a2a_protocol import A2AClient

# Load environment variables
API_KEY = os.getenv("A2A_API_KEY")
BASE_URL = os.getenv("A2A_BASE_URL", "https://api.a2a.example.com")
TIMEOUT = int(os.getenv("A2A_TIMEOUT", "30"))
RETRY_ATTEMPTS = int(os.getenv("A2A_RETRY_ATTEMPTS", "3"))
LOG_LEVEL = os.getenv("A2A_LOG_LEVEL", "info")

# Validate required environment variables
if not API_KEY:
    raise ValueError("A2A_API_KEY environment variable is required")

# Initialize client
client = A2AClient(
    api_key=API_KEY,
    base_url=BASE_URL,
    timeout=TIMEOUT,
    retry_attempts=RETRY_ATTEMPTS,
    log_level=LOG_LEVEL
)

# Example: Multi-environment configuration
class Config:
    """Configuration for different environments"""

    def __init__(self, env="production"):
        self.env = env
        self._load_config()

    def _load_config(self):
        if self.env == "development":
            self.api_key = os.getenv("A2A_DEV_API_KEY")
            self.base_url = os.getenv("A2A_DEV_BASE_URL")
        elif self.env == "staging":
            self.api_key = os.getenv("A2A_STAGING_API_KEY")
            self.base_url = os.getenv("A2A_STAGING_BASE_URL")
        else:  # production
            self.api_key = os.getenv("A2A_PROD_API_KEY")
            self.base_url = os.getenv("A2A_PROD_BASE_URL")

        if not self.api_key:
            raise ValueError(f"API key not set for {self.env} environment")

    def create_client(self):
        return A2AClient(
            api_key=self.api_key,
            base_url=self.base_url
        )

# Usage:
# config = Config(env="development")
# client = config.create_client()
