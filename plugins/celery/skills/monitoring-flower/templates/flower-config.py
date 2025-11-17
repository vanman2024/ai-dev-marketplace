"""
Flower Configuration Template

Complete Flower configuration with all available options.
Customize based on your deployment requirements.

Usage:
    1. Copy this file as 'flowerconfig.py' in your project root
    2. Update configuration values
    3. Set environment variables for secrets
    4. Run: celery -A myapp flower --conf=flowerconfig.py

Security:
    - Never hardcode credentials
    - Use environment variables for secrets
    - Enable authentication in production
    - Use HTTPS for production deployments
"""

import os

# ===========================
# Broker Configuration
# ===========================

# Celery broker URL - MUST match your Celery app configuration
# Examples:
#   Redis: redis://localhost:6379/0
#   RabbitMQ: amqp://guest:guest@localhost:5672//
broker_url = os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0")

# Broker API for management operations (RabbitMQ only)
# broker_api = os.getenv("RABBITMQ_MANAGEMENT_URL", "http://guest:guest@localhost:15672/api/")

# ===========================
# Result Backend Configuration
# ===========================

# Optional: Celery result backend URL
# result_backend = os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/0")

# ===========================
# Network Configuration
# ===========================

# Port to run Flower on
port = int(os.getenv("FLOWER_PORT", "5555"))

# Address to bind to (0.0.0.0 for all interfaces, localhost for local only)
address = os.getenv("FLOWER_ADDRESS", "0.0.0.0")

# URL prefix for reverse proxy deployments
# Example: If accessing via https://example.com/flower/
# url_prefix = "/flower"
url_prefix = os.getenv("FLOWER_URL_PREFIX", "")

# ===========================
# Database Persistence
# ===========================

# Enable persistent mode (stores task history in database)
persistent = os.getenv("FLOWER_PERSISTENT", "True").lower() == "true"

# Database path for SQLite (or PostgreSQL URL)
# SQLite: flower.db
# PostgreSQL: postgresql://user:password@localhost/flower
db = os.getenv("FLOWER_DB", "flower.db")

# ===========================
# Task History Configuration
# ===========================

# Maximum number of tasks to keep in memory
# Higher values use more memory but provide more history
max_tasks = int(os.getenv("FLOWER_MAX_TASKS", "10000"))

# Purge offline workers after this many seconds
# purge_offline_workers = 60

# ===========================
# Authentication Configuration
# ===========================

# Basic authentication (format: username:password,user2:pass2)
# Example: "admin:admin_password_here,viewer:viewer_password_here"
basic_auth = os.getenv("FLOWER_BASIC_AUTH")

# OAuth2 authentication (Google example)
# Required environment variables:
#   FLOWER_OAUTH2_KEY - Google OAuth client ID
#   FLOWER_OAUTH2_SECRET - Google OAuth client secret
#   FLOWER_OAUTH2_REDIRECT_URI - Redirect URI (e.g., http://localhost:5555/login)

# Email regex for OAuth access control
# auth = os.getenv("FLOWER_AUTH_REGEX", r".*@example\.com")

# OAuth2 provider settings
# oauth2_key = os.getenv("FLOWER_OAUTH2_KEY")
# oauth2_secret = os.getenv("FLOWER_OAUTH2_SECRET")
# oauth2_redirect_uri = os.getenv("FLOWER_OAUTH2_REDIRECT_URI")

# ===========================
# UI Configuration
# ===========================

# Enable/disable task columns in UI
# inspect = True
# inspect_timeout = 1000

# Natural time display (e.g., "2 hours ago" instead of timestamp)
# natural_time = True

# Task runtime display format
# tasks_columns = "name,uuid,state,args,kwargs,result,received,started,runtime,worker"

# ===========================
# Performance Tuning
# ===========================

# Max workers to display (high values may impact performance)
max_workers = int(os.getenv("FLOWER_MAX_WORKERS", "5000"))

# Task update interval in milliseconds
# task_update_interval = 1000

# Worker update interval in milliseconds
# worker_update_interval = 5000

# ===========================
# Logging Configuration
# ===========================

# Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
logging = os.getenv("FLOWER_LOGGING", "INFO")

# ===========================
# SSL/TLS Configuration
# ===========================

# Enable SSL (for direct HTTPS access, not needed behind reverse proxy)
# ssl = True
# certfile = "/path/to/cert.pem"
# keyfile = "/path/to/key.pem"

# ===========================
# CORS Configuration
# ===========================

# Enable CORS for API access
# cors = True
# cors_origins = ["http://localhost:3000", "https://example.com"]

# ===========================
# Example Environment Variables
# ===========================

# Required environment variables (set in .env file):
#
# CELERY_BROKER_URL=redis://localhost:6379/0
# FLOWER_BASIC_AUTH=admin:your_password_here
# FLOWER_PORT=5555
# FLOWER_PERSISTENT=True
# FLOWER_DB=flower.db
# FLOWER_MAX_TASKS=10000
#
# Optional OAuth variables:
# FLOWER_OAUTH2_KEY=your_google_client_id_here
# FLOWER_OAUTH2_SECRET=your_google_client_secret_here
# FLOWER_OAUTH2_REDIRECT_URI=http://localhost:5555/login
# FLOWER_AUTH_REGEX=.*@yourcompany\.com

# ===========================
# Validation
# ===========================

if not broker_url:
    raise ValueError("CELERY_BROKER_URL environment variable is required")

if persistent and not db:
    raise ValueError("FLOWER_DB must be set when persistent mode is enabled")

# ===========================
# Configuration Summary
# ===========================

print(f"""
Flower Configuration Loaded:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Broker:       {broker_url.split('@')[-1] if '@' in broker_url else broker_url}
  Port:         {port}
  Address:      {address}
  Persistent:   {persistent}
  Database:     {db if persistent else 'In-memory'}
  Max Tasks:    {max_tasks}
  Max Workers:  {max_workers}
  Auth:         {'Enabled' if basic_auth else 'Disabled'}
  URL Prefix:   {url_prefix or 'None'}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")
