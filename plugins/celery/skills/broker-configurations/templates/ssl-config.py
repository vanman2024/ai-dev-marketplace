"""
SSL/TLS Configuration for Celery Brokers

Production-ready SSL configuration for Redis and RabbitMQ brokers.
Includes certificate validation, mutual TLS, and security best practices.

SECURITY: This file uses environment variables for certificate paths.
Never hardcode certificates or private keys in code.
"""

import os
import ssl
from celery import Celery

# Environment variables for SSL configuration
SSL_ENABLED = os.getenv('BROKER_SSL_ENABLED', 'false').lower() == 'true'
SSL_CERT_FILE = os.getenv('BROKER_SSL_CERT')  # Client certificate
SSL_KEY_FILE = os.getenv('BROKER_SSL_KEY')  # Client private key
SSL_CA_FILE = os.getenv('BROKER_SSL_CA')  # CA certificate
SSL_VERIFY_MODE = os.getenv('BROKER_SSL_VERIFY_MODE', 'CERT_REQUIRED')

# Broker type and connection details
BROKER_TYPE = os.getenv('BROKER_TYPE', 'redis')  # redis, rabbitmq
BROKER_HOST = os.getenv('BROKER_HOST', 'localhost')
BROKER_PORT = int(os.getenv('BROKER_PORT', 6379))
BROKER_PASSWORD = os.getenv('BROKER_PASSWORD')


def get_ssl_verify_mode(mode_string):
    """Convert string to ssl.CERT_* constant."""
    modes = {
        'CERT_NONE': ssl.CERT_NONE,
        'CERT_OPTIONAL': ssl.CERT_OPTIONAL,
        'CERT_REQUIRED': ssl.CERT_REQUIRED,
    }
    return modes.get(mode_string, ssl.CERT_REQUIRED)


def configure_redis_ssl():
    """Configure Redis broker with SSL/TLS."""
    # Build Redis URL with SSL (rediss://)
    if BROKER_PASSWORD:
        broker_url = f'rediss://:{BROKER_PASSWORD}@{BROKER_HOST}:{BROKER_PORT}/0'
    else:
        broker_url = f'rediss://{BROKER_HOST}:{BROKER_PORT}/0'

    app = Celery('myapp', broker=broker_url, backend=broker_url)

    # Redis SSL configuration
    ssl_config = {
        'ssl_cert_reqs': get_ssl_verify_mode(SSL_VERIFY_MODE),
    }

    # Add CA certificate for validation
    if SSL_CA_FILE:
        ssl_config['ssl_ca_certs'] = SSL_CA_FILE

    # Add client certificate for mutual TLS
    if SSL_CERT_FILE:
        ssl_config['ssl_certfile'] = SSL_CERT_FILE

    if SSL_KEY_FILE:
        ssl_config['ssl_keyfile'] = SSL_KEY_FILE

    # Apply SSL configuration to broker
    app.conf.broker_use_ssl = ssl_config

    # Apply SSL configuration to result backend
    app.conf.result_backend_transport_options = {
        'ssl_cert_reqs': ssl_config['ssl_cert_reqs'],
        'ssl_ca_certs': ssl_config.get('ssl_ca_certs'),
        'ssl_certfile': ssl_config.get('ssl_certfile'),
        'ssl_keyfile': ssl_config.get('ssl_keyfile'),
    }

    return app


def configure_rabbitmq_ssl():
    """Configure RabbitMQ broker with SSL/TLS."""
    # Build RabbitMQ URL with SSL (amqps://)
    username = os.getenv('RABBITMQ_USER', 'guest')
    vhost = os.getenv('RABBITMQ_VHOST', '/')

    broker_url = f'amqps://{username}:{BROKER_PASSWORD}@{BROKER_HOST}:{BROKER_PORT}/{vhost}'

    app = Celery('myapp', broker=broker_url)

    # RabbitMQ SSL configuration
    ssl_config = {
        'ssl_cert_reqs': get_ssl_verify_mode(SSL_VERIFY_MODE),
    }

    # Add CA certificate for validation
    if SSL_CA_FILE:
        ssl_config['ssl_ca_certs'] = SSL_CA_FILE

    # Add client certificate for mutual TLS
    if SSL_CERT_FILE:
        ssl_config['ssl_certfile'] = SSL_CERT_FILE

    if SSL_KEY_FILE:
        ssl_config['ssl_keyfile'] = SSL_KEY_FILE

    # Apply SSL configuration
    app.conf.broker_use_ssl = ssl_config

    # Additional RabbitMQ transport options
    app.conf.broker_transport_options = {
        'confirm_publish': True,
        'max_retries': 3,
    }

    return app


def configure_app():
    """Configure Celery app based on broker type and SSL settings."""
    if not SSL_ENABLED:
        # Non-SSL configuration
        if BROKER_TYPE == 'redis':
            broker_url = f'redis://{BROKER_HOST}:{BROKER_PORT}/0'
        else:  # rabbitmq
            username = os.getenv('RABBITMQ_USER', 'guest')
            vhost = os.getenv('RABBITMQ_VHOST', '/')
            broker_url = f'amqp://{username}:{BROKER_PASSWORD}@{BROKER_HOST}:{BROKER_PORT}/{vhost}'

        return Celery('myapp', broker=broker_url)

    # SSL-enabled configuration
    if BROKER_TYPE == 'redis':
        app = configure_redis_ssl()
    else:  # rabbitmq
        app = configure_rabbitmq_ssl()

    # Common configuration for all brokers
    app.conf.update(
        task_serializer='json',
        accept_content=['json'],
        result_serializer='json',
        timezone='UTC',
        enable_utc=True,

        # Worker settings
        worker_prefetch_multiplier=4,
        worker_max_tasks_per_child=1000,

        # Task execution
        task_acks_late=True,
        task_reject_on_worker_lost=True,

        # Time limits
        task_time_limit=3600,
        task_soft_time_limit=3000,
    )

    return app


# Initialize app
app = configure_app()


def validate_ssl_config():
    """Validate SSL configuration files exist and are readable."""
    errors = []

    if not SSL_ENABLED:
        return True, "SSL is disabled"

    # Check required files
    if SSL_CERT_FILE and not os.path.isfile(SSL_CERT_FILE):
        errors.append(f"SSL certificate not found: {SSL_CERT_FILE}")

    if SSL_KEY_FILE and not os.path.isfile(SSL_KEY_FILE):
        errors.append(f"SSL key not found: {SSL_KEY_FILE}")

    if SSL_CA_FILE and not os.path.isfile(SSL_CA_FILE):
        errors.append(f"CA certificate not found: {SSL_CA_FILE}")

    # Check file permissions (private key should be restrictive)
    if SSL_KEY_FILE and os.path.isfile(SSL_KEY_FILE):
        mode = os.stat(SSL_KEY_FILE).st_mode & 0o777
        if mode & 0o077:  # Check if group/others have any permissions
            errors.append(f"SSL key has insecure permissions: {oct(mode)}")

    if errors:
        return False, "\n".join(errors)

    return True, "SSL configuration is valid"


if __name__ == '__main__':
    # Validate SSL configuration
    valid, message = validate_ssl_config()

    if not valid:
        print(f"❌ SSL Configuration Error:\n{message}")
        exit(1)

    print(f"✅ {message}")

    # Test connection
    try:
        app.connection().ensure_connection(max_retries=3)
        print(f"✅ Successfully connected to {BROKER_TYPE} broker with SSL")
        print(f"Host: {BROKER_HOST}:{BROKER_PORT}")
        print(f"SSL Verify Mode: {SSL_VERIFY_MODE}")
        if SSL_CERT_FILE:
            print("✅ Client certificate authentication enabled")
    except Exception as e:
        print(f"❌ Failed to connect: {e}")
