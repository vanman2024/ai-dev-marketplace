"""
Django settings with Celery configuration

Add these settings to your existing Django settings.py file
"""

import os
from pathlib import Path

# Build paths inside the project
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'your_django_secret_key_here')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv('DEBUG', 'False') == 'True'

ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')


# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Celery result backend (optional)
    'django_celery_results',

    # Celery beat scheduler (optional, for periodic tasks)
    'django_celery_beat',

    # Your apps
    # 'myapp',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'myproject.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'myproject.wsgi.application'


# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'your_database_name_here'),
        'USER': os.getenv('DB_USER', 'your_database_user_here'),
        'PASSWORD': os.getenv('DB_PASSWORD', 'your_database_password_here'),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
        # Close database connections after each request
        # Important for Celery workers
        'CONN_MAX_AGE': 0,
    }
}


# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True


# Static files (CSS, JavaScript, Images)
STATIC_URL = 'static/'


# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


# ════════════════════════════════════════════════════════════════
# Celery Configuration
# ════════════════════════════════════════════════════════════════

# Celery broker URL (Redis, RabbitMQ, etc.)
CELERY_BROKER_URL = os.getenv(
    'CELERY_BROKER_URL',
    'redis://your_redis_url_here'
)

# Celery result backend (where task results are stored)
CELERY_RESULT_BACKEND = os.getenv(
    'CELERY_RESULT_BACKEND',
    'redis://your_redis_url_here'
)

# Alternative: Store results in Django database
# Requires: pip install django-celery-results
# CELERY_RESULT_BACKEND = 'django-db'
# CELERY_CACHE_BACKEND = 'django-cache'

# Task serialization format
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_ACCEPT_CONTENT = ['json']

# Timezone configuration (should match Django TIME_ZONE)
CELERY_TIMEZONE = TIME_ZONE
CELERY_ENABLE_UTC = True

# Retry configuration
CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True
CELERY_BROKER_CONNECTION_RETRY = True
CELERY_BROKER_CONNECTION_MAX_RETRIES = 10

# Task time limits (in seconds)
CELERY_TASK_TIME_LIMIT = 30 * 60  # 30 minutes hard limit
CELERY_TASK_SOFT_TIME_LIMIT = 25 * 60  # 25 minutes soft limit

# Task result expiration (seconds)
CELERY_RESULT_EXPIRES = 60 * 60 * 24  # 24 hours

# Worker configuration
CELERY_WORKER_PREFETCH_MULTIPLIER = 4
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000  # Restart worker after 1000 tasks

# Task routing (optional)
CELERY_TASK_ROUTES = {
    'myapp.tasks.send_email': {'queue': 'emails'},
    'myapp.tasks.process_data': {'queue': 'processing'},
    'myapp.tasks.generate_report': {'queue': 'reports'},
}

# Task prioritization (optional)
CELERY_TASK_DEFAULT_PRIORITY = 5
CELERY_TASK_QUEUE_MAX_PRIORITY = 10

# Beat schedule for periodic tasks (optional)
# Requires: pip install django-celery-beat
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    'send-daily-report': {
        'task': 'myapp.tasks.send_daily_report',
        'schedule': crontab(hour=9, minute=0),  # 9 AM every day
    },
    'cleanup-old-sessions': {
        'task': 'myapp.tasks.cleanup_sessions',
        'schedule': crontab(hour=2, minute=0),  # 2 AM every day
    },
    'process-pending-orders': {
        'task': 'myapp.tasks.process_orders',
        'schedule': 300.0,  # Every 5 minutes
    },
}

# Beat scheduler backend (store schedule in database)
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'


# ════════════════════════════════════════════════════════════════
# Logging Configuration (for Celery)
# ════════════════════════════════════════════════════════════════

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
        'file': {
            'class': 'logging.FileHandler',
            'filename': 'celery.log',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'celery': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
        },
        'myapp.tasks': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
        },
    },
}


# ════════════════════════════════════════════════════════════════
# Email Configuration (if using email tasks)
# ════════════════════════════════════════════════════════════════

EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.getenv('EMAIL_HOST', 'smtp.example.com')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', '587'))
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER', 'your_email_username_here')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD', 'your_email_password_here')
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL', 'noreply@example.com')
